/*
  ==========================================================
   TRAÇANTE DENTRO DO SILENCIADOR - BLACK BIRD | PROJETO 10
  ==========================================================
   Placa: ESP32-C3 SuperMini (Ferramentas > Placa > "ESP32C3 Dev Module",
          USB CDC On Boot = Enabled). Sem biblioteca extra.

   Como funciona:
   - A BB passa pelo tubo do cartucho e corta o feixe infravermelho
     (LED IR + fototransistor + comparador LM393, igual ao cronógrafo 03).
   - Na hora, a placa acende os 6 LEDs UV por PULSO_US (2 ms). A BB
     traçante (fosforescente) carrega com o UV e sai brilhando.
   - Sem tiro por DORMIR_MS (5 min): desliga o feixe e dorme (gasta
     quase nada). O SENSOR DE VIBRAÇÃO acorda a placa no próximo tiro.
     O tiro que acorda não acende (a placa leva ~0,2 s para acordar):
     depois de um tempo parado, dê 1 tiro "de acordar".
   - LED de estado (na frente do cartucho, aparece com a tampa do
     silenciador tirada): ao acordar pisca a bateria (1 a 3 vezes);
     pisca curto a cada BB detectada (bom para testar e regular o
     trimpot do LM393); bateria fraca = 1 piscada longa a cada 5 s.

   Ligações (detalhe na PREVIA.html):
   - GPIO3 : saída do LM393 (barreira IR)
   - GPIO10: LED IR da barreira (150 Ω)
   - GPIO4 : gate do MOSFET dos LEDs UV (100 Ω no gate, 10 kΩ para o GND)
   - GPIO2 : sensor de vibração para o GND + 100 kΩ para o 3V3
   - GPIO5 : LED de estado 3 mm (330 Ω)
   - GPIO1 : bateria pelo divisor 100k/100k
  ==========================================================
*/

#include <Preferences.h>
#include "esp_sleep.h"

// ================= CONFIGURAÇÃO =================
const uint8_t PINO_BARREIRA = 3;
const uint8_t PINO_IR       = 10;
const uint8_t PINO_UV       = 4;
const uint8_t PINO_VIBRA    = 2;
const uint8_t PINO_LED      = 5;
const uint8_t PINO_BAT      = 1;

const int      BB_BORDA    = FALLING;   // se não detectar nada, troque para RISING
const uint32_t PULSO_US    = 2000;      // tempo do UV aceso por BB (1 a 3 ms)
const uint32_t TRAVA_US    = 15000;     // ignora o sensor por 15 ms depois de cada BB (rajada até ~60 BB/s)
const uint32_t DORMIR_MS   = 5UL * 60 * 1000;
const float    BAT_FRACA_V = 3.5;

// ================= ESTADO =================
volatile uint32_t tUV = 0, tUltimaBB = 0;
volatile bool uvLigado = false, novaBB = false;
RTC_DATA_ATTR uint32_t totalBBs = 0;     // conta enquanto a bateria estiver ligada
Preferences prefs;

void IRAM_ATTR aoPassarBB() {
  uint32_t agora = micros();
  if (agora - tUltimaBB < TRAVA_US) return;
  tUltimaBB = agora;
  digitalWrite(PINO_UV, HIGH);           // acende já, dentro da interrupção (a BB anda 14 cm por ms)
  tUV = agora; uvLigado = true; novaBB = true;
}

float bateriaV() {
  uint32_t mv = 0;
  for (uint8_t i = 0; i < 8; i++) mv += analogReadMilliVolts(PINO_BAT);
  return mv / 8.0 * 2 / 1000.0;
}

void piscar(uint8_t n, uint16_t liga, uint16_t desliga) {
  for (uint8_t i = 0; i < n; i++) { digitalWrite(PINO_LED, HIGH); delay(liga); digitalWrite(PINO_LED, LOW); delay(desliga); }
}

void dormir() {
  detachInterrupt(digitalPinToInterrupt(PINO_BARREIRA));
  digitalWrite(PINO_UV, LOW);
  digitalWrite(PINO_IR, LOW);
  digitalWrite(PINO_LED, LOW);
  prefs.putUInt("total", totalBBs);
  esp_deep_sleep_enable_gpio_wakeup(1ULL << PINO_VIBRA, ESP_GPIO_WAKEUP_GPIO_LOW);
  esp_deep_sleep_start();
}

void setup() {
  pinMode(PINO_UV, OUTPUT);  digitalWrite(PINO_UV, LOW);
  pinMode(PINO_IR, OUTPUT);  digitalWrite(PINO_IR, HIGH);     // liga o feixe
  pinMode(PINO_LED, OUTPUT); digitalWrite(PINO_LED, LOW);
  pinMode(PINO_VIBRA, INPUT);                                 // pull-up de 100k externo (funciona dormindo)
  pinMode(PINO_BARREIRA, INPUT_PULLUP);
  Serial.begin(115200);

  prefs.begin("tracante", false);
  if (totalBBs == 0) totalBBs = prefs.getUInt("total", 0);

  float v = bateriaV();
  piscar(v > 3.95 ? 3 : v > 3.7 ? 2 : 1, 120, 180);          // nível da bateria ao acordar
  delay(50);                                                  // o feixe e o LM393 estabilizam
  attachInterrupt(digitalPinToInterrupt(PINO_BARREIRA), aoPassarBB, BB_BORDA);
}

void loop() {
  static uint32_t tAviso = 0, tUltimaMs = 0, tLedApaga = 0;
  uint32_t agoraUs = micros(), agoraMs = millis();

  if (uvLigado && agoraUs - tUV >= PULSO_US) { digitalWrite(PINO_UV, LOW); uvLigado = false; }

  if (novaBB) {
    novaBB = false;
    totalBBs++;
    tUltimaMs = agoraMs;
    digitalWrite(PINO_LED, HIGH); tLedApaga = agoraMs + 30;                 // piscada curta por BB
    Serial.printf("BB %lu\n", (unsigned long)totalBBs);
  }

  if (tLedApaga && (int32_t)(agoraMs - tLedApaga) >= 0) { digitalWrite(PINO_LED, LOW); tLedApaga = 0; }

  if (agoraMs - tAviso > 5000) {                              // bateria fraca: piscada longa a cada 5 s (sem travar o loop)
    tAviso = agoraMs;
    float v = bateriaV();
    if (v > 1.0 && v < BAT_FRACA_V) { digitalWrite(PINO_LED, HIGH); tLedApaga = agoraMs + 250; }
  }

  if (agoraMs - tUltimaMs > DORMIR_MS && !uvLigado) dormir();
}
