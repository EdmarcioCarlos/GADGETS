/*
  ==========================================================
   CYBERDECK BLACK BIRD - PARTIDA DE CAÇA | PROJETO 13
  ==========================================================
   Placa: ESP32-C3 SuperMini (Ferramentas > Placa > "ESP32C3 Dev Module",
          USB CDC On Boot = Enabled)
   Bibliotecas (Gerenciador de Bibliotecas):
     "Adafruit MCP23017 Arduino Library", "TM1637" (Avishay Orpaz),
     "Adafruit NeoPixel"

   Esta placa fica SEMPRE com energia (bateria 18650 própria) e controla a
   energia do Raspberry Pi por um relé. O Pi só liga com a sequência certa:

     1. BAT ............ alavanca com capa: o painel acorda e faz o auto-teste
     2. MASTER ARM ..... alavanca com capa
     3. APU ............ botão amarelo: o APU "gira" até 100%
     4. ENG 1 .......... botão azul: motor 1 até 60%
     5. ENG 2 .......... botão verde: motor 2 até 60%
     6. MANETE ......... empurre para MIL (a microchave fecha)
     7. START .......... segure o botão vermelho 1 s: liga o Pi

   Fora de ordem = "Abrt": alarme e neon vermelho. Para recomeçar,
   desligue o MASTER ARM e comece do passo 2.
   A alavanca NEON liga/desliga a fita de LED a qualquer momento.

   DESLIGAR (sequência inversa): MANETE em IDLE → MASTER ARM desligado.
   A placa pede para o Pi desligar sozinho (sem corromper o cartão), espera
   e só então corta a energia. Por último, a BAT. Se desligar a BAT com o
   Pi ligado, ela faz o desligamento seguro do mesmo jeito.

   Com o Pi ligado, o painel vira controle dos jogos: cada botão/alavanca
   vai para o Pi pela serial ("BTN APU 1") e o Pi pode acender os LEDs,
   apitar, mudar o neon e escrever no display (ver pi/painel.py).
  ==========================================================
*/

#include <Wire.h>
#include <Adafruit_MCP23X17.h>
#include <TM1637Display.h>
#include <Adafruit_NeoPixel.h>
#include "esp_sleep.h"

// ================= PINOS (ESP32-C3) =================
const uint8_t PINO_BAT    = 2;    // alavanca BAT para o GND + 100k para o 3V3 (LOW = ligada); acorda a placa
const uint8_t PINO_BUZZER = 3;    // buzzer ativo pelo BC547
const uint8_t PINO_RELE   = 4;    // módulo relé: liga o 5 V do Raspberry Pi
const uint8_t PINO_NEON   = 5;    // fita WS2812
const uint8_t PINO_CLK = 6, PINO_DIO = 7;      // display TM1637
const uint8_t PINO_SDA = 8, PINO_SCL = 9;      // MCP23017
const uint8_t PINO_RX  = 20, PINO_TX = 21;     // serial com o Pi (TX do Pi no 20, RX do Pi no 21)

// MCP23017: entradas (para o GND, pull-up interno) e saídas para o ULN2003 (LEDs dos botões arcade)
enum { E_ARM = 0, E_NEON, E_APU, E_ENG1, E_ENG2, E_MANETE, E_START, N_ENTRADAS };
const char *NOME[N_ENTRADAS] = {"ARM", "NEON", "APU", "ENG1", "ENG2", "MANETE", "START"};
const uint8_t LED_APU = 8, LED_ENG1 = 9, LED_ENG2 = 10, LED_START = 11;   // GPB0..3

const uint8_t N_LEDS_NEON = 15;   // fita de 25 cm (60 LEDs/m)
const uint32_t ESPERA_DESLIGAR_MS = 25000;   // tempo para o Pi desligar sozinho
const uint32_t PASSO_MAX_MS = 60000;         // 1 min parado num passo = volta a esperar o ARM

// ================= OBJETOS E ESTADO =================
Adafruit_MCP23X17 mcp;
TM1637Display disp(PINO_CLK, PINO_DIO);
Adafruit_NeoPixel neon(N_LEDS_NEON, PINO_NEON, NEO_GRB + NEO_KHZ800);
HardwareSerial PiSerial(1);

enum Estado { TESTE, ESPERA_ARM, ESPERA_APU, APU_GIRANDO, ESPERA_ENG1, ENG1_GIRANDO, ESPERA_ENG2, ENG2_GIRANDO,
              ESPERA_MANETE, ESPERA_START, BOOT, LIGADO, DESLIGANDO, ABORTADO, DESLIGADO };
Estado estado = TESTE;
uint32_t tEstado = 0;
bool entradaAntes[N_ENTRADAS];
bool neonLigado = true;
uint8_t rpm = 0;                 // % mostrado no display durante a partida
String linhaPi;

// ---------- display: fonte de letras em 7 segmentos ----------
uint8_t seg(char c) {
  switch (c) {
    case '0': case 'O': return 0x3F; case '1': case 'I': return 0x06; case '2': return 0x5B; case '3': return 0x4F;
    case '4': return 0x66; case '5': case 'S': case 's': return 0x6D; case '6': return 0x7D; case '7': return 0x07;
    case '8': return 0x7F; case '9': return 0x6F; case 'A': case 'a': return 0x77; case 'b': case 'B': return 0x7C;
    case 'C': return 0x39; case 'c': return 0x58; case 'd': case 'D': return 0x5E; case 'E': case 'e': return 0x79;
    case 'F': case 'f': return 0x71; case 'G': case 'g': return 0x3D; case 'H': return 0x76; case 'h': return 0x74;
    case 'J': case 'j': return 0x1E; case 'L': case 'l': return 0x38; case 'n': case 'N': return 0x54;
    case 'o': return 0x5C; case 'P': case 'p': return 0x73; case 'r': case 'R': return 0x50; case 't': case 'T': return 0x78;
    case 'U': return 0x3E; case 'u': return 0x1C; case 'y': case 'Y': return 0x6E; case '-': return 0x40; case '_': return 0x08;
    default: return 0x00;
  }
}
void mostrar(const char *s) {
  uint8_t d[4] = {0, 0, 0, 0};
  for (uint8_t i = 0; i < 4 && s[i]; i++) d[i] = seg(s[i]);
  disp.setSegments(d);
}
void mostrarPct(const char *pref, uint8_t pct) {        // ex.: "A" + 75 -> "A 75"
  char b[6]; snprintf(b, sizeof(b), "%c%3d", pref[0], pct > 99 ? 99 : pct);
  mostrar(pct > 99 ? (String(pref[0]) + "100").c_str() : b);
}

// ---------- som, LEDs, neon ----------
void bip(uint16_t ms) { digitalWrite(PINO_BUZZER, HIGH); delay(ms); digitalWrite(PINO_BUZZER, LOW); }
void ledBotao(uint8_t pino, bool on) { mcp.digitalWrite(pino, on ? HIGH : LOW); }
void todosLeds(bool on) { for (uint8_t p = LED_APU; p <= LED_START; p++) ledBotao(p, on); }
void neonCor(uint8_t r, uint8_t g, uint8_t b) {
  for (uint8_t i = 0; i < N_LEDS_NEON; i++) neon.setPixelColor(i, neonLigado ? neon.Color(r, g, b) : 0);
  neon.show();
}
void neonEfeito() {                                   // animação conforme o estado (chamada a cada ~30 ms)
  if (!neonLigado) { neon.clear(); neon.show(); return; }
  uint32_t t = millis();
  switch (estado) {
    case ESPERA_ARM: { uint8_t v = 10 + 30 * (1 + sin(t / 600.0)) / 2; neonCor(0, v, v); break; }          // ciano respirando
    case ABORTADO: { bool on = (t / 120) % 2; neonCor(on ? 120 : 0, 0, 0); break; }                          // vermelho piscando
    case BOOT: {                                                                                              // glitch DedSec
      for (uint8_t i = 0; i < N_LEDS_NEON; i++) {
        uint8_t k = random(10);
        neon.setPixelColor(i, k < 4 ? neon.Color(255, 0, 200) : k < 8 ? neon.Color(0, 220, 255) : k < 9 ? neon.Color(255, 255, 255) : 0);
      }
      neon.show(); break;
    }
    case LIGADO: {                                                                                            // onda magenta ↔ ciano
      for (uint8_t i = 0; i < N_LEDS_NEON; i++) {
        float f = (1 + sin(i * 0.5 + t / 400.0)) / 2;
        neon.setPixelColor(i, neon.Color(180 * f, 200 * (1 - f), 220));
      }
      neon.show(); break;
    }
    case DESLIGANDO: { uint32_t dt = t - tEstado; uint8_t v = dt > ESPERA_DESLIGAR_MS ? 0 : 120 - 120 * dt / ESPERA_DESLIGAR_MS; neonCor(v, 0, v); break; }
    case DESLIGADO: neonCor(0, 0, 0); break;
    default: {                                                                                                // partida: barra que cresce com o "rpm"
      uint8_t n = (uint32_t)N_LEDS_NEON * rpm / 100;
      for (uint8_t i = 0; i < N_LEDS_NEON; i++) neon.setPixelColor(i, i < n ? neon.Color(255, 0, 180) : neon.Color(0, 8, 10));
      neon.show();
    }
  }
}

// ---------- entradas ----------
bool lerEntrada(uint8_t e) { return mcp.digitalRead(e) == LOW; }     // LOW = ligada/apertada
bool batLigada() { return digitalRead(PINO_BAT) == LOW; }

void irPara(Estado e) { estado = e; tEstado = millis(); }

void abortar() {
  irPara(ABORTADO); rpm = 0; todosLeds(false); mostrar("Abrt");
  for (uint8_t i = 0; i < 3; i++) { bip(120); delay(80); }
  PiSerial.println("EVT ABORT");
}

// ---------- Raspberry Pi ----------
void ligarPi(bool on) { digitalWrite(PINO_RELE, on ? HIGH : LOW); }
void comandoDoPi(String c) {                          // comandos que os jogos mandam (ver pi/painel.py)
  c.trim();
  if (c == "PRONTO") { if (estado == BOOT) { irPara(LIGADO); mostrar(" on "); bip(60); } }
  else if (c == "DESLIGANDO") { if (estado != DESLIGANDO) { irPara(DESLIGANDO); mostrar("SHdn"); } }
  else if (c.startsWith("LED ")) {                    // LED APU 1
    int sp = c.indexOf(' ', 4); String n = c.substring(4, sp); bool on = c.substring(sp + 1).toInt();
    if (n == "APU") ledBotao(LED_APU, on); else if (n == "ENG1") ledBotao(LED_ENG1, on);
    else if (n == "ENG2") ledBotao(LED_ENG2, on); else if (n == "START") ledBotao(LED_START, on);
  }
  else if (c.startsWith("BEEP ")) bip(constrain(c.substring(5).toInt(), 10, 1000));
  else if (c.startsWith("DISP ")) mostrar(c.substring(5).c_str());
  else if (c.startsWith("NEON ")) {                   // NEON 255 0 200
    int a = c.indexOf(' ', 5), b = c.indexOf(' ', a + 1);
    neonCor(c.substring(5, a).toInt(), c.substring(a + 1, b).toInt(), c.substring(b + 1).toInt());
  }
}
void lerSerialPi() {
  while (PiSerial.available()) {
    char ch = PiSerial.read();
    if (ch == '\n') { comandoDoPi(linhaPi); linhaPi = ""; }
    else if (linhaPi.length() < 60) linhaPi += ch;
  }
}

// ---------- dormir ----------
void dormir() {
  ligarPi(false); todosLeds(false); disp.clear(); neon.clear(); neon.show();
  esp_deep_sleep_enable_gpio_wakeup(1ULL << PINO_BAT, ESP_GPIO_WAKEUP_GPIO_LOW);   // acorda quando a BAT liga
  esp_deep_sleep_start();
}

// ---------- partida: um passo de "girar" (APU e motores) ----------
bool girar(uint8_t alvo, uint32_t duracaoMs, const char *letra, uint8_t ledPino) {
  uint32_t dt = millis() - tEstado;
  rpm = min<uint32_t>(alvo, (uint32_t)alvo * dt / duracaoMs);
  mostrarPct(letra, rpm);
  ledBotao(ledPino, (dt / 150) % 2);                  // pisca enquanto gira
  static uint32_t tBip = 0;
  if (millis() - tBip > 900 - 7 * rpm) { tBip = millis(); bip(15); }   // bipes cada vez mais rápidos
  if (dt >= duracaoMs) { ledBotao(ledPino, true); bip(80); return true; }
  return false;
}

void setup() {
  pinMode(PINO_BAT, INPUT);                           // pull-up de 100k externo (funciona dormindo)
  pinMode(PINO_BUZZER, OUTPUT); pinMode(PINO_RELE, OUTPUT);
  digitalWrite(PINO_BUZZER, LOW); ligarPi(false);
  Serial.begin(115200);
  PiSerial.begin(115200, SERIAL_8N1, PINO_RX, PINO_TX);
  Wire.begin(PINO_SDA, PINO_SCL);
  mcp.begin_I2C(0x20);
  for (uint8_t e = 0; e < N_ENTRADAS; e++) mcp.pinMode(e, INPUT_PULLUP);
  for (uint8_t p = LED_APU; p <= LED_START; p++) mcp.pinMode(p, OUTPUT);
  disp.setBrightness(5);
  neon.begin(); neon.setBrightness(90);
  randomSeed(esp_random());

  if (!batLigada()) dormir();                         // ligou sem a BAT: volta a dormir

  // auto-teste: todos os segmentos, LEDs e neon
  irPara(TESTE);
  uint8_t tudo[4] = {0xFF, 0xFF, 0xFF, 0xFF}; disp.setSegments(tudo);
  todosLeds(true); neonCor(0, 200, 255); bip(60); delay(150); bip(60);
  delay(900);
  todosLeds(false); mostrar("bAt ");
  for (uint8_t e = 0; e < N_ENTRADAS; e++) entradaAntes[e] = lerEntrada(e);
  neonLigado = entradaAntes[E_NEON];
  irPara(entradaAntes[E_ARM] ? ABORTADO : ESPERA_ARM);    // já estava armado ao ligar: exige desarmar
  if (estado == ABORTADO) mostrar("Arn-");
}

void loop() {
  uint32_t agora = millis();
  lerSerialPi();

  // ----- BAT desligada -----
  if (!batLigada()) {
    if (estado == LIGADO || estado == BOOT) { irPara(DESLIGANDO); mostrar("SHdn"); PiSerial.println("DESLIGAR"); }
    else if (estado != DESLIGANDO) { mostrar("OFF "); delay(600); dormir(); }
  }

  // ----- leitura das entradas: só as mudanças contam -----
  for (uint8_t e = 0; e < N_ENTRADAS; e++) {
    bool v = lerEntrada(e);
    if (v == entradaAntes[e]) continue;
    delay(15); if (lerEntrada(e) != v) continue;      // filtro de ruído
    entradaAntes[e] = v;

    if (e == E_NEON) { neonLigado = v; continue; }    // NEON vale sempre, não faz parte da ordem
    if (estado == LIGADO || estado == BOOT) {         // Pi ligado (ou iniciando): painel vira controle dos jogos
      PiSerial.printf("BTN %s %d\n", NOME[e], v);
      if (e == E_ARM && !v) {                         // MASTER ARM desligado = pedido de desligar
        if (entradaAntes[E_MANETE]) { mostrar("IdLE"); bip(200); }   // primeiro a manete em IDLE
        else { irPara(DESLIGANDO); mostrar("SHdn"); PiSerial.println("DESLIGAR"); }
      }
      if (e == E_MANETE && !v && !entradaAntes[E_ARM]) { irPara(DESLIGANDO); mostrar("SHdn"); PiSerial.println("DESLIGAR"); }
      continue;
    }
    if (estado == DESLIGANDO) continue;

    // MASTER ARM desligado durante a partida: volta ao começo (sem alarme)
    if (e == E_ARM && !v) { todosLeds(false); rpm = 0; irPara(ESPERA_ARM); mostrar("bAt "); continue; }
    if (estado == ABORTADO) continue;                 // só sai do abort desligando o ARM (acima)

    bool certo = false;
    switch (estado) {
      case ESPERA_ARM: case DESLIGADO: certo = (e == E_ARM && v);  if (certo) { irPara(ESPERA_APU); mostrar("Arn "); bip(40); } break;
      case ESPERA_APU:    certo = (e == E_APU && v);  if (certo) irPara(APU_GIRANDO); break;
      case ESPERA_ENG1:   certo = (e == E_ENG1 && v); if (certo) irPara(ENG1_GIRANDO); break;
      case ESPERA_ENG2:   certo = (e == E_ENG2 && v); if (certo) irPara(ENG2_GIRANDO); break;
      case ESPERA_MANETE: certo = (e == E_MANETE && v); if (certo) { irPara(ESPERA_START); mostrar("PUSH"); bip(40); } break;
      case ESPERA_START:
        if (e == E_MANETE && !v) { irPara(ESPERA_MANETE); mostrar("thr "); certo = true; }   // voltou a manete
        else certo = (e == E_START && v);             // o START é conferido abaixo (segurar 1 s)
        break;
      default: certo = !v;                            // soltar botão durante o giro não conta como erro
    }
    if (!certo && v) abortar();
  }

  // ----- passos que dependem do tempo -----
  switch (estado) {
    case APU_GIRANDO:  if (girar(100, 3000, "A", LED_APU))  { irPara(ESPERA_ENG1); mostrar("A100"); } break;
    case ENG1_GIRANDO: if (girar(60, 2500, "1", LED_ENG1))  { irPara(ESPERA_ENG2); mostrar("1 60"); } break;
    case ENG2_GIRANDO: if (girar(60, 2500, "2", LED_ENG2))  { irPara(ESPERA_MANETE); mostrar("thr "); rpm = 60; } break;
    case ESPERA_MANETE: rpm = 60; break;
    case ESPERA_START: {
      rpm = 100;
      ledBotao(LED_START, (agora / 250) % 2);          // START piscando
      static uint32_t tApertou = 0;
      if (entradaAntes[E_START]) {
        if (!tApertou) tApertou = agora;
        if (agora - tApertou > 1000) {                 // segurou 1 s: liga o Pi
          tApertou = 0; ledBotao(LED_START, true); bip(250);
          ligarPi(true); irPara(BOOT); mostrar("boot");
        }
      } else tApertou = 0;
      break;
    }
    case BOOT:
      if (agora - tEstado > 90000) { mostrar("Err "); }   // o Pi não respondeu em 90 s (confira o cartão/serial)
      break;
    case DESLIGANDO: {
      uint32_t falta = agora - tEstado > ESPERA_DESLIGAR_MS ? 0 : (ESPERA_DESLIGAR_MS - (agora - tEstado)) / 1000;
      char b[6]; snprintf(b, sizeof(b), "SH%2lu", (unsigned long)falta); mostrar(b);
      if (falta == 0) {
        ligarPi(false); todosLeds(false); rpm = 0; bip(300);
        irPara(DESLIGADO); mostrar("OFF ");
      }
      break;
    }
    default: break;
  }
  if (estado >= ESPERA_APU && estado <= ESPERA_START && agora - tEstado > PASSO_MAX_MS) { todosLeds(false); rpm = 0; irPara(ESPERA_ARM); mostrar("bAt "); }

  static uint32_t tNeon = 0;
  if (agora - tNeon > 30) { tNeon = agora; neonEfeito(); }
}
