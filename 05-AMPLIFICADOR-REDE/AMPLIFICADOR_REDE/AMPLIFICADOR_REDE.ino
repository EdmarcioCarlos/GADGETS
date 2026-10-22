/*
  ==========================================================
   AMPLIFICADOR DE REDE DOS TABLETS - BLACK BIRD · PROJETO 05
   (para o LA CATEDRAL BATTLEFIELD)
  ==========================================================
   Placa: ESP32-C3 SuperMini (Ferramentas > Placa > "ESP32C3 Dev Module",
          USB CDC On Boot = Enabled). Pacote "esp32" da Espressif 3.x.
   Grave ESTE MESMO código em todos os rádios (sem mudar nada).

   O que faz:
   - Cria uma rede Wi-Fi "LACATEDRAL-JOGO" (senha lacatedral). O tablet do
     ponto se conecta nela, sem internet e sem roteador.
   - Tudo o que o jogo do tablet manda (UDP porta 47800) o rádio repassa
     pelo ar, em ESP-NOW de LONGO ALCANCE, para os outros rádios; cada um
     entrega para o tablet dele. Os tablets acham que estão na mesma rede.
   - Rádio SEM tablet conectado vira REPETIDOR sozinho: repassa o que ouve
     (até SALTOS vezes). Use para cobrir um ponto do campo sem sinal.
   - LED TABLET aceso = tablet conectado. LED REDE: aceso = ouve outro rádio
     com sinal bom · pisca devagar = sinal fraco · apagado = ninguém.
   - Página de diagnóstico: celular na rede LACATEDRAL-JOGO, abra
     http://192.168.4.1 (rádios vizinhos, sinal, mensagens).

   O jogo do tablet precisa ser a versão que manda as mensagens em pedaços
   (LaCatedralBattlefield.apk de 18/10/2026 em diante).
   Sem biblioteca extra.
  ==========================================================
*/

#include <WiFi.h>
#include <WiFiUdp.h>
#include <WebServer.h>
#include <esp_now.h>
#include <esp_wifi.h>

#if ESP_ARDUINO_VERSION_MAJOR < 3
#error "Atualize o pacote esp32 para a versao 3.x (Ferramentas > Placa > Gerenciador de Placas > esp32)"
#endif

// ================= CONFIGURAÇÃO =================
const char*    REDE          = "LACATEDRAL-JOGO";   // igual em todos os rádios
const char*    SENHA         = "lacatedral";        // mínimo 8 letras
const uint8_t  CANAL         = 1;                    // igual em todos os rádios
const bool     LONGO_ALCANCE = true;                 // modo LR da Espressif (o mesmo do TESTE_ALCANCE)
const uint16_t PORTA_JOGO    = 47800;                // porta UDP do Battlefield
const uint8_t  SALTOS        = 2;                    // quantas vezes um repetidor pode repassar
const bool     SEMPRE_REPETIR = false;               // true = repete mesmo com tablet (campo comprido, rádios em fila)
const uint8_t  PINO_LED_TABLET = 3;                  // LED 3 mm + resistor 220 Ω até o GND
const uint8_t  PINO_LED_REDE   = 4;
const uint8_t  PINO_LED_PLACA  = 8;                  // LED azul da própria SuperMini (acende com LOW)

// ================= MENSAGENS DO RÁDIO =================
// Começam como a struct Msg dos aparelhos BLACK BIRD (magico 0xBB, tipo): os outros aparelhos ignoram.
enum Tipo : uint8_t { REDE_DADOS = 41, REDE_BALIZA = 42 };
const uint8_t DADOS_MAX = 236;                       // bytes do jogo em cada quadro de rádio
const uint16_t DATAGRAMA_MAX = 1472;                 // o tablet manda pedaços de até ~1130 bytes

struct __attribute__((packed)) Quadro {
  uint8_t  magico, tipo;
  uint16_t origem;       // rádio que recebeu do tablet
  uint16_t msg;          // número da mensagem desse rádio
  uint8_t  parte, total; // pedaço do datagrama
  uint8_t  saltos;       // quantas repetições ainda pode ter
  uint16_t tamanho;      // tamanho do datagrama inteiro
  uint8_t  dados[DADOS_MAX];
};
struct __attribute__((packed)) Baliza {
  uint8_t  magico, tipo;
  uint16_t origem;
  uint8_t  tablets;      // quantos tablets estão conectados nele
  uint8_t  repetidor;    // 1 = está repetindo
};
const uint8_t TODOS[6] = {0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF};
const size_t CAB = offsetof(Quadro, dados);

uint16_t meuId = 0, minhaMsg = 0;
WiFiUDP udp;
WebServer pagina(80);

// contadores (aparecem na página)
uint32_t nDoTablet = 0, nParaTablet = 0, nRepassadas = 0, nPerdidas = 0, nQuadrosTx = 0, nQuadrosRx = 0;

// ================= REPETIDAS =================
// Cada mensagem chega várias vezes (o tablet manda para 2 endereços; os repetidores repassam).
// Guarda as últimas e ignora as repetidas.
uint32_t vistas[64]; uint32_t vistasEm[64]; uint8_t posVistas = 0;
uint32_t fnv(const uint8_t *d, size_t n, uint32_t h = 2166136261u) { for (size_t i = 0; i < n; i++) { h ^= d[i]; h *= 16777619u; } return h; }
bool jaVi(uint32_t h) {
  uint32_t agora = millis();
  for (uint8_t i = 0; i < 64; i++) if (vistas[i] == h && agora - vistasEm[i] < 4000) return true;
  vistas[posVistas] = h; vistasEm[posVistas] = agora; posVistas = (posVistas + 1) % 64;
  return false;
}

// ================= FILA DE SAÍDA PELO RÁDIO =================
struct Saida { uint8_t q[sizeof(Quadro)]; uint8_t n; };
Saida fila[48]; uint8_t filaIni = 0, filaFim = 0;
uint32_t proximoTx = 0;
uint8_t tamFila() { return (filaFim + 48 - filaIni) % 48; }
void enfileirar(const void *q, uint8_t n) {
  if (tamFila() >= 47) { filaIni = (filaIni + 1) % 48; nPerdidas++; }   // cheia: joga fora a mais velha (o jogo manda o estado de novo em 1 s)
  memcpy(fila[filaFim].q, q, n); fila[filaFim].n = n; filaFim = (filaFim + 1) % 48;
}
void transmitir() {
  if (filaIni == filaFim || millis() < proximoTx) return;
  esp_err_t r = esp_now_send(TODOS, fila[filaIni].q, fila[filaIni].n);
  if (r == ESP_OK) { filaIni = (filaIni + 1) % 48; nQuadrosTx++; proximoTx = millis() + 12; }   // ~12 ms por quadro no modo longo alcance
  else proximoTx = millis() + 5;                                                                 // rádio ocupado: tenta já já
}

// Divide um datagrama em quadros e põe na fila
void mandarPeloRadio(uint16_t origem, uint16_t msg, uint8_t saltos, const uint8_t *d, uint16_t n) {
  uint8_t total = (n + DADOS_MAX - 1) / DADOS_MAX;
  Quadro q;
  for (uint8_t k = 0; k < total; k++) {
    uint16_t ini = k * DADOS_MAX, tam = n - ini;
    if (tam > DADOS_MAX) tam = DADOS_MAX;
    q.magico = 0xBB; q.tipo = REDE_DADOS; q.origem = origem; q.msg = msg;
    q.parte = k; q.total = total; q.saltos = saltos; q.tamanho = n;
    memcpy(q.dados, d + ini, tam);
    enfileirar(&q, CAB + tam);
  }
}

// ================= RECEBER PELO RÁDIO =================
// Quadros chegam no "callback" (fora do loop): só copia para uma fila curta.
struct Chegada { uint8_t q[sizeof(Quadro)]; uint8_t n; int8_t rssi; };
Chegada chegadas[24]; volatile uint8_t chIni = 0, chFim = 0;
void aoReceber(const esp_now_recv_info_t *info, const uint8_t *d, int n) {
  if (n < 4 || n > (int)sizeof(Quadro) || d[0] != 0xBB || (d[1] != REDE_DADOS && d[1] != REDE_BALIZA)) return;
  uint8_t p = (chFim + 1) % 24; if (p == chIni) return;
  memcpy(chegadas[chFim].q, d, n); chegadas[chFim].n = n;
  chegadas[chFim].rssi = info->rx_ctrl ? info->rx_ctrl->rssi : -100;
  chFim = p;
}

// Montagem dos datagramas que chegam em pedaços
struct Montagem { uint16_t origem, msg, tam; uint8_t total, saltos; uint8_t tem; uint32_t desde; uint8_t d[DATAGRAMA_MAX]; };
Montagem mont[4];

// Vizinhos (outros rádios que eu ouço)
struct Vizinho { uint16_t id; float rssi; uint32_t visto; uint8_t tablets, repetidor; };
Vizinho viz[12]; uint8_t nViz = 0;
Vizinho *vizinho(uint16_t id) {
  for (uint8_t i = 0; i < nViz; i++) if (viz[i].id == id) return &viz[i];
  if (nViz < 12) { viz[nViz] = {id, -100, 0, 0, 0}; return &viz[nViz++]; }
  uint8_t velho = 0; for (uint8_t i = 1; i < 12; i++) if (viz[i].visto < viz[velho].visto) velho = i;   // troca o mais antigo
  viz[velho] = {id, -100, 0, 0, 0}; return &viz[velho];
}

bool souRepetidor() { return SEMPRE_REPETIR || WiFi.softAPgetStationNum() == 0; }

void entregarAoTablet(const uint8_t *d, uint16_t n) {
  if (WiFi.softAPgetStationNum() == 0) return;
  if (jaVi(fnv(d, n))) return;
  udp.beginPacket(IPAddress(192, 168, 4, 255), PORTA_JOGO);
  udp.write(d, n);
  udp.endPacket();
  nParaTablet++;
}

void processarRadio() {
  while (chIni != chFim) {
    Chegada &c = chegadas[chIni];
    nQuadrosRx++;
    if (c.q[1] == REDE_BALIZA && c.n >= (int)sizeof(Baliza)) {
      Baliza b; memcpy(&b, c.q, sizeof(b));
      if (b.origem != meuId) {
        Vizinho *v = vizinho(b.origem);
        v->rssi = v->visto && millis() - v->visto < 5000 ? v->rssi * 0.7f + c.rssi * 0.3f : c.rssi;
        v->visto = millis(); v->tablets = b.tablets; v->repetidor = b.repetidor;
      }
    } else if (c.q[1] == REDE_DADOS && c.n > (int)CAB) {
      Quadro q; memcpy(&q, c.q, c.n);
      uint8_t tam = c.n - CAB;
      if (q.origem != meuId && q.total && q.parte < q.total && q.tamanho <= DATAGRAMA_MAX && q.parte * DADOS_MAX + tam <= q.tamanho) {
        // acha a montagem dessa mensagem; se não tem, usa uma vazia (ou a mais velha)
        int8_t s = -1, livre = 0;
        for (uint8_t i = 0; i < 4; i++) {
          if (mont[i].tem && mont[i].origem == q.origem && mont[i].msg == q.msg) s = i;
          if (!mont[i].tem) livre = i;
          else if (mont[livre].tem && mont[i].desde < mont[livre].desde) livre = i;
        }
        if (s < 0) { s = livre; mont[s].origem = q.origem; mont[s].msg = q.msg; mont[s].tam = q.tamanho; mont[s].total = q.total; mont[s].saltos = q.saltos; mont[s].tem = 0; mont[s].desde = millis(); }
        Montagem &m = mont[s];
        memcpy(m.d + q.parte * DADOS_MAX, q.dados, tam);
        m.tem |= (1 << q.parte);
        if (m.tem == (uint8_t)((1 << m.total) - 1)) {             // chegou tudo
          uint32_t chave = 0x9E3779B9u ^ ((uint32_t)m.origem << 16 | m.msg);
          if (!jaVi(chave)) {
            entregarAoTablet(m.d, m.tam);
            if (m.saltos > 0 && souRepetidor()) { mandarPeloRadio(m.origem, m.msg, m.saltos - 1, m.d, m.tam); nRepassadas++; }
          }
          m.tem = 0; m.origem = 0; m.desde = 0;
        }
      }
    }
    chIni = (chIni + 1) % 24;
  }
}

// ================= RECEBER DO TABLET =================
uint8_t buf[DATAGRAMA_MAX];
void processarTablet() {
  int n;
  while ((n = udp.parsePacket()) > 0) {
    IPAddress de = udp.remoteIP();
    int lidos = udp.read(buf, sizeof(buf));
    if (de == WiFi.softAPIP() || lidos <= 0 || n > (int)DATAGRAMA_MAX) continue;   // o meu próprio eco, ou grande demais
    if (jaVi(fnv(buf, lidos))) continue;                                             // o tablet manda para 2 endereços
    mandarPeloRadio(meuId, ++minhaMsg, SALTOS, buf, lidos);
    jaVi(0x9E3779B9u ^ ((uint32_t)meuId << 16 | minhaMsg));                           // não repassa a minha própria de volta
    nDoTablet++;
  }
}

// ================= BALIZA E LEDS =================
uint32_t proximaBaliza = 0;
void mandarBaliza() {
  if (millis() < proximaBaliza) return;
  proximaBaliza = millis() + 1000 + random(0, 200);
  Baliza b = {0xBB, REDE_BALIZA, meuId, (uint8_t)WiFi.softAPgetStationNum(), (uint8_t)souRepetidor()};
  enfileirar(&b, sizeof(b));
}
// 0 = ninguém · 1 = fraco · 2 = bom (melhor vizinho dos últimos 4 s)
uint8_t sinalRede() {
  float melhor = -200;
  for (uint8_t i = 0; i < nViz; i++) if (millis() - viz[i].visto < 4000 && viz[i].rssi > melhor) melhor = viz[i].rssi;
  if (melhor <= -200) return 0;
  return melhor > -85 ? 2 : 1;
}
void leds() {
  uint32_t t = millis(); uint8_t s = sinalRede();
  digitalWrite(PINO_LED_TABLET, WiFi.softAPgetStationNum() > 0 ? HIGH : (t % 2000 < 60 ? HIGH : LOW));   // sem tablet: piscadinha (está vivo)
  digitalWrite(PINO_LED_REDE, s == 2 ? HIGH : s == 1 ? ((t / 500) % 2 ? HIGH : LOW) : LOW);
  digitalWrite(PINO_LED_PLACA, s ? LOW : HIGH);
}

// ================= PÁGINA DE DIAGNÓSTICO =================
const char HTML[] PROGMEM = R"HTML(<!doctype html><html lang="pt-BR"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1"><title>Rádio de rede</title>
<style>body{margin:0;background:#11140f;color:#e6ead8;font-family:system-ui,sans-serif;padding:16px}
h1{font-size:15px;letter-spacing:.2em;color:#9aa38a;margin:0 0 10px}.g{display:flex;flex-wrap:wrap}
.g div{flex:1 1 40%;background:#1b2017;border-radius:10px;padding:10px;margin:0 8px 8px 0;text-align:center}
.g b{display:block;font-size:22px}.g small{color:#9aa38a}table{width:100%;border-collapse:collapse;font-size:14px}
td,th{padding:6px 4px;border-bottom:1px solid #2f3828;text-align:left}.ok{color:#7fc04a}.fr{color:#f2c230}.no{color:#e5484d}
p{color:#9aa38a;font-size:13px}</style></head><body><h1 id="t">RÁDIO DE REDE</h1>
<div class="g"><div><b id="tab">-</b><small>tablets ligados em mim</small></div><div><b id="modo">-</b><small>modo</small></div>
<div><b id="ent">-</b><small>do meu tablet → rádio</small></div><div><b id="sai">-</b><small>rádio → meu tablet</small></div></div>
<h1>RÁDIOS QUE EU OUÇO</h1><table><thead><tr><th>Rádio</th><th>Sinal</th><th>Tablets</th><th>Visto</th></tr></thead><tbody id="v"></tbody></table>
<p id="x"></p><p>Sinal: acima de -75 dBm ótimo · até -85 bom · até -95 fraco (perde mensagens). Rádio sem tablet vira repetidor sozinho.</p>
<script>var $=function(i){return document.getElementById(i)};
function q(r){return r>-75?'<span class="ok">ótimo</span>':r>-85?'<span class="ok">bom</span>':r>-95?'<span class="fr">fraco</span>':'<span class="no">ruim</span>'}
function a(){fetch('/dados').then(function(r){return r.json()}).then(function(d){$('t').textContent='RÁDIO '+d.id;$('tab').textContent=d.tab;
$('modo').textContent=d.rep?'REPETIDOR':'PONTO';$('ent').textContent=d.ent;$('sai').textContent=d.sai;
$('v').innerHTML=d.viz.map(function(v){return '<tr><td>'+v[0]+(v[3]?' (repetidor)':'')+'</td><td>'+v[1]+' dBm · '+q(v[1])+'</td><td>'+v[2]+'</td><td>há '+v[4]+' s</td></tr>'}).join('')||'<tr><td colspan="4" class="no">nenhum rádio ouvido</td></tr>';
$('x').textContent='repassadas '+d.rep2+' · quadros enviados '+d.tx+' · recebidos '+d.rx+' · perdidas na fila '+d.perd+' · ligado há '+d.up+' min';
}).catch(function(){$('t').textContent='SEM CONEXÃO COM O RÁDIO'})}setInterval(a,1000);a();</script></body></html>)HTML";

void paginaDados() {
  String j = "{\"id\":\"" + String(meuId, HEX) + "\",\"tab\":" + WiFi.softAPgetStationNum() + ",\"rep\":" + (souRepetidor() ? 1 : 0) +
             ",\"ent\":" + nDoTablet + ",\"sai\":" + nParaTablet + ",\"rep2\":" + nRepassadas + ",\"tx\":" + nQuadrosTx +
             ",\"rx\":" + nQuadrosRx + ",\"perd\":" + nPerdidas + ",\"up\":" + (millis() / 60000) + ",\"viz\":[";
  bool primeiro = true;
  for (uint8_t i = 0; i < nViz; i++) {
    uint32_t ha = (millis() - viz[i].visto) / 1000;
    if (!viz[i].visto || ha > 600) continue;
    if (!primeiro) j += ",";
    primeiro = false;
    j += "[\"" + String(viz[i].id, HEX) + "\"," + String((int)viz[i].rssi) + "," + viz[i].tablets + "," + viz[i].repetidor + "," + ha + "]";
  }
  j += "]}";
  pagina.send(200, "application/json", j);
}

// ================= PROGRAMA =================
void setup() {
  Serial.begin(115200);
  pinMode(PINO_LED_TABLET, OUTPUT); pinMode(PINO_LED_REDE, OUTPUT); pinMode(PINO_LED_PLACA, OUTPUT);
  digitalWrite(PINO_LED_PLACA, HIGH);

  WiFi.mode(WIFI_AP_STA);
  uint8_t mac[6]; WiFi.macAddress(mac);
  meuId = ((uint16_t)mac[4] << 8 | mac[5]); if (!meuId) meuId = 1;
  WiFi.softAP(REDE, SENHA, CANAL, 0, 4);                        // até 4 tablets/celulares em cada rádio
  WiFi.setSleep(false);
  // só a interface do rádio entre as placas fica em longo alcance; a rede dos tablets continua normal
  if (LONGO_ALCANCE) esp_wifi_set_protocol(WIFI_IF_STA, WIFI_PROTOCOL_LR);
  esp_wifi_set_max_tx_power(80);                                // potência máxima (20 dBm)
  esp_now_init();
  esp_now_register_recv_cb(aoReceber);
  esp_now_peer_info_t peer = {};
  memcpy(peer.peer_addr, TODOS, 6);
  peer.channel = 0; peer.ifidx = WIFI_IF_STA; peer.encrypt = false;   // 0 = canal atual (o da rede, CANAL)
  esp_now_add_peer(&peer);

  udp.begin(PORTA_JOGO);
  pagina.on("/", []() { pagina.send_P(200, "text/html", HTML); });
  pagina.on("/dados", paginaDados);
  pagina.begin();
  Serial.printf("Radio %04X pronto. Rede %s (senha %s), canal %u, pagina http://192.168.4.1\n", meuId, REDE, SENHA, CANAL);
}

void loop() {
  processarTablet();
  processarRadio();
  mandarBaliza();
  transmitir();
  leds();
  pagina.handleClient();
  static uint32_t ultimoLog = 0;
  if (millis() - ultimoLog > 5000) {
    ultimoLog = millis();
    Serial.printf("tablets %u · %s · vizinhos com sinal: %s · tablet->radio %lu · radio->tablet %lu · repassadas %lu · fila %u\n",
      WiFi.softAPgetStationNum(), souRepetidor() ? "REPETIDOR" : "PONTO", sinalRede() == 2 ? "bom" : sinalRede() ? "fraco" : "nenhum",
      (unsigned long)nDoTablet, (unsigned long)nParaTablet, (unsigned long)nRepassadas, tamFila());
  }
}
