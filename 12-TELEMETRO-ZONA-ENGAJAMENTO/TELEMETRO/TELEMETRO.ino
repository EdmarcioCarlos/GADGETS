/*
  ==========================================================
   TELÊMETRO COM ZONA DE ENGAJAMENTO - BLACK BIRD | PROJETO 12
  ==========================================================
   Placa: ESP32-C3 SuperMini (Ferramentas > Placa > "ESP32C3 Dev Module",
          USB CDC On Boot = Enabled)

   O que faz:
   - Liga e mede sozinho, sem parar (não tem botão de medir).
   - Mostra a mediana das 3 últimas leituras e a MARCA do retículo BDC
     da sua tabela de hold (MARCA 0 = ferradura, 1, 2, 3...).
   - Abaixo da distância mínima: "MUITO PERTO" piscando.
   - Sem retorno: "SEM LEITURA" (mantém a última distância por 2 s).
   - Bateria abaixo de 15%: ícone piscando.
   - Ao ligar, abre por 30 s a rede Wi-Fi "BLACKBIRD-TEL" (senha
     blackbird). No celular, entre em http://192.168.4.1 para ajustar a
     distância mínima, a tabela de hold e o brilho.

   Bibliotecas: "Adafruit SSD1306" e "Adafruit GFX Library".

   >>> IMPORTANTE - PROTOCOLO DO LASER <<<
   Cada fabricante usa comandos diferentes. Este código vem pronto para
   o tipo mais comum (comando de texto "D", resposta "D: 12.345m,0079").
   Quando o laser chegar:
   1) Deixe MODO_TESTE = true, grave e abra o monitor serial (115200).
      Tudo o que o laser responder aparece lá.
   2) Confira o manual do vendedor (baud e comando de medir) e ajuste
      LASER_BAUD e CMD_MEDIR. Se a resposta for diferente, me mande o
      que apareceu no monitor que eu adapto a função lerLaser().
  ==========================================================
*/

#include <Wire.h>
#include <WiFi.h>
#include <WebServer.h>
#include <Preferences.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>

// ================= CONFIGURAÇÃO =================
const uint8_t PINO_LASER_RX  = 20;  // recebe do TX do laser (fio amarelo)
const uint8_t PINO_LASER_TX  = 21;  // vai no RX do laser (fio preto)
const uint8_t PINO_LASER_ON  = 10;  // Power ON do laser (fio vermelho)
const uint8_t PINO_BATERIA   = 3;   // divisor 100k/100k (opcional)
const uint8_t PINO_SDA = 8, PINO_SCL = 9;

const uint32_t LASER_BAUD = 9600;   // CONFIRA no manual
const char*    CMD_MEDIR  = "D";    // CONFIRA no manual (comando de 1 medição)
const bool     MODO_TESTE = false;  // true = mostra no monitor serial tudo que o laser envia

const uint16_t INTERVALO_MS = 400;  // ~2,5 medições por segundo
const uint32_t SEGURA_MS    = 2000; // mantém a última leitura válida por 2 s
const uint32_t WIFI_MS      = 30000;

// valores de fábrica (mude pelo celular)
const uint8_t N_MARCAS = 6;
uint16_t distMinima = 20;                                  // m
uint16_t holdAte[N_MARCAS] = {40, 55, 70, 85, 100, 999};   // MARCA i vale até holdAte[i] metros
uint8_t  brilho = 2;                                       // 0 baixo, 1 médio, 2 alto

// ================= PROGRAMA =================
Adafruit_SSD1306 tela(128, 32, &Wire, -1);
Preferences prefs;
WebServer web(80);
bool wifiLigado = false;

float leituras[3] = {0, 0, 0};
uint8_t nLeituras = 0, posLeitura = 0;
float distancia = -1;            // mediana atual (-1 = nada ainda)
uint32_t tUltimaValida = 0;

// ---------- laser ----------
void pedirMedida() {
  while (Serial1.available()) Serial1.read();
  Serial1.print(CMD_MEDIR);
}

// devolve a distância em metros, -1 se ainda não chegou nada, -2 se veio erro
float lerLaser() {
  static char buf[48];
  static uint8_t n = 0;
  while (Serial1.available()) {
    char c = Serial1.read();
    if (MODO_TESTE) { Serial.write(c); }
    if (c == '\n' || c == '\r' || n >= sizeof(buf) - 1) {
      buf[n] = 0;
      bool tinha = n > 0;
      n = 0;
      if (!tinha) continue;
      // procura "<número>m", ex.: "D: 12.345m,0079"
      char *m = strchr(buf, 'm');
      if (!m) return -2;
      char *ini = m;
      while (ini > buf && (isdigit(ini[-1]) || ini[-1] == '.')) ini--;
      if (ini == m) return -2;
      float d = atof(ini);
      return (d > 0.1 && d < 2000) ? d : -2;
    }
    buf[n++] = c;
  }
  return -1;
}

float mediana3() {
  if (nLeituras < 3) return leituras[(posLeitura + 2) % 3];
  float a = leituras[0], b = leituras[1], c = leituras[2];
  return max(min(a, b), min(max(a, b), c));
}

// ---------- tela ----------
int bateriaPct() {
  uint32_t mv = analogReadMilliVolts(PINO_BATERIA) * 2;
  if (mv < 1000) return -1;
  return constrain(map(mv, 3300, 4150, 0, 100), 0, 100);
}

uint8_t marca(float d) {
  for (uint8_t i = 0; i < N_MARCAS; i++) if (d <= holdAte[i]) return i;
  return N_MARCAS - 1;
}

void aplicarBrilho() {
  const uint8_t C[3] = {1, 60, 255};
  tela.ssd1306_command(SSD1306_SETCONTRAST);
  tela.ssd1306_command(C[brilho % 3]);
}

void desenhar() {
  uint32_t agora = millis();
  bool pisca = (agora / 300) % 2;
  char b[20];
  tela.clearDisplay();
  tela.setTextColor(SSD1306_WHITE);

  bool valida = distancia > 0 && agora - tUltimaValida < SEGURA_MS;
  if (!valida) {
    tela.setTextSize(1); tela.setCursor(0, 12); tela.print(distancia < 0 && tUltimaValida == 0 ? "MEDINDO..." : "SEM LEITURA");
  } else if (distancia < distMinima) {
    tela.setTextSize(2);
    if (pisca) { tela.setCursor(0, 0); tela.print("MUITO"); tela.setCursor(0, 16); tela.print("PERTO"); }
    tela.setTextSize(1); tela.setCursor(74, 12); snprintf(b, sizeof(b), "%.0f m", distancia); tela.print(b);
  } else {
    tela.setTextSize(3); tela.setCursor(0, 4); snprintf(b, sizeof(b), "%.0f", distancia); tela.print(b);
    tela.setTextSize(1); tela.setCursor(strlen(b) * 18 + 2, 18); tela.print("m");
    tela.setCursor(80, 6); tela.print("MARCA");
    tela.setTextSize(2); tela.setCursor(92, 16); tela.print(marca(distancia));
  }

  // bateria: canto de cima, à direita
  int bat = bateriaPct();
  if (bat >= 0 && (bat >= 15 || pisca)) {
    tela.drawRect(112, 0, 14, 7, SSD1306_WHITE); tela.fillRect(126, 2, 2, 3, SSD1306_WHITE);
    tela.fillRect(114, 2, map(bat, 0, 100, 0, 10), 3, SSD1306_WHITE);
  }
  if (wifiLigado) { tela.setTextSize(1); tela.setCursor(112, 24); tela.print("WF"); }
  tela.display();
}

// ---------- página de configuração ----------
void salvar() {
  prefs.putUShort("min", distMinima);
  prefs.putBytes("hold", holdAte, sizeof(holdAte));
  prefs.putUChar("brilho", brilho);
}

void paginaInicial() {
  String h = F("<!doctype html><meta name=viewport content='width=device-width'><title>Telêmetro</title>"
               "<style>body{font-family:sans-serif;background:#111;color:#ddd;padding:12px}input{width:70px;font-size:18px}"
               "button{font-size:18px;padding:8px 18px}</style><h2>BLACK BIRD - Telêmetro</h2><form method=post action=/s>");
  h += "<p>Distância mínima (m): <input name=min type=number value=" + String(distMinima) + "></p><p>Tabela de hold (até quantos metros vale cada marca):</p>";
  for (uint8_t i = 0; i < N_MARCAS; i++) h += "<p>MARCA " + String(i) + " até <input name=h" + String(i) + " type=number value=" + String(holdAte[i]) + "> m</p>";
  h += "<p>Brilho (0, 1 ou 2): <input name=b type=number min=0 max=2 value=" + String(brilho) + "></p><button>Salvar</button></form>";
  web.send(200, "text/html; charset=utf-8", h);
}

void paginaSalvar() {
  if (web.hasArg("min")) distMinima = web.arg("min").toInt();
  for (uint8_t i = 0; i < N_MARCAS; i++) if (web.hasArg("h" + String(i))) holdAte[i] = web.arg("h" + String(i)).toInt();
  if (web.hasArg("b")) brilho = constrain(web.arg("b").toInt(), 0, 2);
  salvar(); aplicarBrilho();
  web.send(200, "text/html; charset=utf-8", "<meta name=viewport content='width=device-width'><h2>Salvo!</h2><a href=/>voltar</a>");
}

void setup() {
  Serial.begin(115200);
  pinMode(PINO_LASER_ON, OUTPUT);
  digitalWrite(PINO_LASER_ON, HIGH);                      // liga o laser
  Serial1.begin(LASER_BAUD, SERIAL_8N1, PINO_LASER_RX, PINO_LASER_TX);

  prefs.begin("telemetro", false);
  distMinima = prefs.getUShort("min", distMinima);
  if (prefs.getBytesLength("hold") == sizeof(holdAte)) prefs.getBytes("hold", holdAte, sizeof(holdAte));
  brilho = prefs.getUChar("brilho", brilho);

  Wire.begin(PINO_SDA, PINO_SCL);
  tela.begin(SSD1306_SWITCHCAPVCC, 0x3C);
  aplicarBrilho();
  tela.cp437(true);                                       // símbolo de grau certo
  tela.clearDisplay(); tela.setTextColor(SSD1306_WHITE); tela.setTextSize(2);
  tela.setCursor(0, 8); tela.print("BLACK BIRD"); tela.display();

  WiFi.mode(WIFI_AP);
  WiFi.softAP("BLACKBIRD-TEL", "blackbird");
  web.on("/", HTTP_GET, paginaInicial);
  web.on("/s", HTTP_POST, paginaSalvar);
  web.begin();
  wifiLigado = true;
  delay(1500);
}

void loop() {
  static uint32_t tPedido = 0, tDesenho = 0;
  uint32_t agora = millis();

  // Wi-Fi só nos primeiros 30 s (ou enquanto o celular estiver conectado)
  if (wifiLigado) {
    web.handleClient();
    if (agora > WIFI_MS && WiFi.softAPgetStationNum() == 0) {
      web.stop();
      WiFi.softAPdisconnect(true); WiFi.mode(WIFI_OFF);
      wifiLigado = false;
    }
  }

  if (agora - tPedido > INTERVALO_MS) { tPedido = agora; pedirMedida(); }

  float d = lerLaser();
  if (d > 0) {
    leituras[posLeitura] = d; posLeitura = (posLeitura + 1) % 3;
    if (nLeituras < 3) nLeituras++;
    distancia = mediana3();
    tUltimaValida = agora;
  }

  if (agora - tDesenho > 100) { tDesenho = agora; desenhar(); }
}
