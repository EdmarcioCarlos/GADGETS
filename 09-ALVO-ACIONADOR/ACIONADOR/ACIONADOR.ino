/*
  ==========================================================
   ALVO ACIONADOR - BLACK BIRD · PROJETO 09 · o ACIONADOR (na rede, 127 V)
  ==========================================================
   Placa: ESP32-C3 SuperMini (Ferramentas > Placa > "ESP32C3 Dev Module",
          USB CDC On Boot = Enabled). Pacote "esp32" da Espressif 3.x.
   Sem biblioteca extra. Grave o MESMO código em todos os acionadores.

   ATENÇÃO: grave o código com a caixa FORA da tomada, só pelo USB do PC.
   Nunca ligue o USB do PC com a caixa na tomada.

   O que faz:
   - Fica ouvindo os alvos (ESP-NOW). Quando o SEU alvo é acertado, liga o
     relé (o refletor acende) pelo tempo que o alvo mandou (30 s a 3 min).
   - Se outro acerto chegar com a lâmpada acesa, conta o tempo de novo.
   - Botão PAREAR/TESTE (frente):
       clique ............ teste: acende o refletor por 3 s
       segure 3 s ........ PAREAR: o LED pisca rápido; acerte o alvo que vai
                           comandar esta lâmpada (até 4 alvos por lâmpada)
       segure 10 s ....... apaga todos os alvos pareados
   - LED verde (frente):
       aceso ............. refletor ligado
       pisca devagar ..... pronto, com alvo pareado
       pisca 2x seguidas . pronto, SEM alvo pareado (obedece a qualquer alvo)
       pisca rápido ...... modo PAREAR

   Pinos (na SuperMini aparece só o número):
     5 = sinal do relé (IN) · 6 = LED verde · 10 = botão (para o GND)
  ==========================================================
*/

#include <WiFi.h>
#include <esp_now.h>
#include <esp_wifi.h>
#include <Preferences.h>

#if ESP_ARDUINO_VERSION_MAJOR < 3
#error "Atualize o pacote esp32 para a versao 3.x (Ferramentas > Placa > Gerenciador de Placas > esp32)"
#endif

// ================= CONFIGURAÇÃO =================
const uint8_t  PINO_RELE      = 5;
const uint8_t  PINO_LED       = 6;
const uint8_t  PINO_BOTAO     = 10;
const bool     RELE_ATIVO_ALTO = true;   // módulo com jumper H/L: deixe em "H". Se o relé ficar ligado ao contrário, mude para false
const uint16_t TEMPO_MAX_S    = 600;     // segurança: nunca fica ligado mais de 10 min seguidos
const uint8_t  CANAL          = 1;       // igual no alvo
const bool     LONGO_ALCANCE  = true;    // igual no alvo
const uint8_t  MAX_ALVOS      = 4;

// ============ MENSAGEM (igual em todos os aparelhos BLACK BIRD) ============
enum Tipo : uint8_t { ALVO_ACERTO = 50 };
struct __attribute__((packed)) Msg {
  uint8_t  magico; uint8_t tipo; uint8_t origem; uint8_t destino;
  uint16_t equipe; uint16_t seq; int16_t azimute; uint16_t distancia; uint8_t extra;
};

// ================= RELÉ =================
uint32_t desligarEm = 0;          // millis() em que o refletor apaga (0 = apagado)
void rele(bool ligado) { digitalWrite(PINO_RELE, (ligado == RELE_ATIVO_ALTO) ? HIGH : LOW); }
void acender(uint32_t segundos) {
  if (segundos > TEMPO_MAX_S) segundos = TEMPO_MAX_S;
  if (segundos < 1) segundos = 1;
  uint32_t fim = millis() + segundos * 1000UL;
  if (!desligarEm || (int32_t)(fim - desligarEm) > 0) desligarEm = fim;   // conta o tempo de novo (o maior)
  rele(true);
}

// ================= ALVOS PAREADOS =================
Preferences prefs;
uint8_t alvos[MAX_ALVOS][6]; uint8_t nAlvos = 0;
void salvarAlvos() { prefs.putBytes("alvos", alvos, sizeof(alvos)); prefs.putUChar("n", nAlvos); }
void carregarAlvos() { nAlvos = prefs.getUChar("n", 0); if (nAlvos > MAX_ALVOS) nAlvos = 0; if (nAlvos) prefs.getBytes("alvos", alvos, sizeof(alvos)); }
bool pareado(const uint8_t *mac) { for (uint8_t i = 0; i < nAlvos; i++) if (!memcmp(alvos[i], mac, 6)) return true; return false; }

// ================= RECEBER =================
// O callback roda fora do loop: só guarda o pedido; o loop é que liga o relé.
struct Pedido { uint8_t mac[6]; uint16_t seq; uint16_t segundos; uint8_t bateria; };
volatile bool temPedido = false;
Pedido pedido;
void aoReceber(const esp_now_recv_info_t *info, const uint8_t *d, int n) {
  if (n != sizeof(Msg) || temPedido) return;
  Msg m; memcpy(&m, d, sizeof(m));
  if (m.magico != 0xBB || m.tipo != ALVO_ACERTO) return;
  memcpy(pedido.mac, info->src_addr, 6); pedido.seq = m.seq; pedido.segundos = m.distancia; pedido.bateria = m.extra;
  temPedido = true;
}

// ================= BOTÃO E LED =================
bool pareando = false; uint32_t pareandoAte = 0;
uint32_t apertouEm = 0; bool apertado = false;
void lerBotao() {
  bool agora = digitalRead(PINO_BOTAO) == LOW;
  if (agora && !apertado) { apertado = true; apertouEm = millis(); }
  if (!agora && apertado) {
    apertado = false;
    uint32_t t = millis() - apertouEm;
    if (t >= 10000) { nAlvos = 0; salvarAlvos(); Serial.println("Pareamentos apagados."); }
    else if (t >= 3000) { pareando = true; pareandoAte = millis() + 30000; Serial.println("PAREAR: acerte o alvo (30 s)."); }
    else if (t >= 50) { acender(3); Serial.println("Teste: 3 s."); }
  }
}
void led() {
  uint32_t t = millis(); bool aceso;
  if (pareando) aceso = (t / 100) % 2;
  else if (desligarEm) aceso = true;
  else if (nAlvos) aceso = t % 2000 < 100;
  else aceso = (t % 2000 < 100) || (t % 2000 > 250 && t % 2000 < 350);
  digitalWrite(PINO_LED, aceso ? HIGH : LOW);
}

// ================= PROGRAMA =================
uint8_t ultimoMac[6]; uint16_t ultimoSeq = 0xFFFF;

void setup() {
  pinMode(PINO_RELE, OUTPUT); rele(false);           // primeiro de tudo: refletor apagado
  pinMode(PINO_LED, OUTPUT); pinMode(PINO_BOTAO, INPUT_PULLUP);
  Serial.begin(115200);
  prefs.begin("acionador", false);
  carregarAlvos();
  WiFi.mode(WIFI_STA);
  esp_wifi_set_channel(CANAL, WIFI_SECOND_CHAN_NONE);
  if (LONGO_ALCANCE) esp_wifi_set_protocol(WIFI_IF_STA, WIFI_PROTOCOL_LR);
  esp_now_init();
  esp_now_register_recv_cb(aoReceber);
  Serial.printf("Acionador pronto. %u alvo(s) pareado(s).\n", nAlvos);
}

void loop() {
  lerBotao();
  if (pareando && millis() > pareandoAte) pareando = false;

  if (temPedido) {
    Pedido p; memcpy(&p, (const void *)&pedido, sizeof(p)); temPedido = false;
    bool repetido = !memcmp(p.mac, ultimoMac, 6) && p.seq == ultimoSeq;   // o alvo manda o mesmo aviso 6 vezes
    if (!repetido) {
      memcpy(ultimoMac, p.mac, 6); ultimoSeq = p.seq;
      if (pareando) {
        if (!pareado(p.mac)) {
          if (nAlvos < MAX_ALVOS) { memcpy(alvos[nAlvos++], p.mac, 6); salvarAlvos(); }
          else Serial.println("Já tem 4 alvos: segure 10 s para apagar.");
        }
        pareando = false;
        acender(2);
        Serial.printf("Alvo %02X:%02X pareado.\n", p.mac[4], p.mac[5]);
      } else if (nAlvos == 0 || pareado(p.mac)) {
        acender(p.segundos);
        Serial.printf("Acerto do alvo %02X:%02X -> aceso por %u s (bateria do alvo %u%%).\n", p.mac[4], p.mac[5], p.segundos, p.bateria);
      }
    }
  }

  if (desligarEm && (int32_t)(millis() - desligarEm) >= 0) { desligarEm = 0; rele(false); }
  led();
  delay(5);
}
