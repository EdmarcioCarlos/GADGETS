/*
  ==========================================================
   GRANADA DE SOM E LUZ - BLACK BIRD | PROJETO 08
  ==========================================================
   Placa: ESP32-C3 SuperMini (Ferramentas > Placa > "ESP32C3 Dev Module",
          USB CDC On Boot = Enabled). Sem biblioteca extra.

   Como funciona:
   - Com o pino no lugar, o ímã da ponta fecha o reed: a granada fica
     ARMADA e dormindo (gasta quase nada).
   - Puxou o pino: acorda, conta o tempo do modo e dispara:
     sirene de 110 dB + estrobo dos 4 LEDs de 1 W por DURACAO_MS.
   - Recolocou o pino durante a contagem: cancela (não dispara).
   - Depois de disparar, ela espera o pino voltar para armar de novo.
   - Ligar a chave com o pino FORA não dispara nada (segurança): ela
     só arma quando o pino for colocado.

   Botão MODO (com o pino no lugar):
   - toque curto: troca o modo e mostra com piscadas do estrobo
       1 piscada = 3 s  ·  2 piscadas = 5 s  ·  3 piscadas = MINA (0 s,
       para usar com fio de tropeço amarrado na argola)
   - segurar 2 s: mostra a bateria (1 a 4 piscadas longas)

   Ligações (detalhe na PREVIA.html):
   - GPIO2: reed para o GND + resistor 100k para o 3V3
   - GPIO3: botão MODO para o GND + resistor 100k para o 3V3
   - GPIO4: gate do MOSFET da sirene (liga o GND do MT3608)
   - GPIO5: gate do MOSFET do estrobo (GND dos 4 LEDs)
   - GPIO1: bateria pelo divisor 100k/100k
  ==========================================================
*/

#include <Preferences.h>
#include "esp_sleep.h"

// ================= CONFIGURAÇÃO =================
const uint8_t PINO_REED   = 2;   // LOW = pino no lugar, HIGH = pino puxado
const uint8_t PINO_BOTAO  = 3;   // LOW = apertado
const uint8_t PINO_SIRENE = 4;
const uint8_t PINO_LUZ    = 5;
const uint8_t PINO_BAT    = 1;
const uint8_t PINO_LED    = 8;   // LED azul da placa (acende em LOW)

const uint16_t ATRASOS_MS[3] = {3000, 5000, 0};   // modos: 3 s, 5 s, MINA
const uint32_t DURACAO_MS   = 6000;               // quanto tempo dura o "estouro"
const uint32_t SIRENE_CHEIA = 2500;               // sirene contínua no começo; depois pulsa
const uint16_t ESTROBO_LIGA = 25, ESTROBO_DESLIGA = 60;   // ms (≈ 12 piscadas por segundo)

// ================= ESTADO =================
RTC_DATA_ATTR bool armada = false;   // sobrevive ao deep sleep
Preferences prefs;
uint8_t modo = 0;

bool pinoNoLugar() { return digitalRead(PINO_REED) == LOW; }
bool botaoApertado() { return digitalRead(PINO_BOTAO) == LOW; }

void saidas(bool sirene, bool luz) {
  digitalWrite(PINO_SIRENE, sirene ? HIGH : LOW);
  digitalWrite(PINO_LUZ, luz ? HIGH : LOW);
}

void piscar(uint8_t n, uint16_t liga, uint16_t desliga) {
  for (uint8_t i = 0; i < n; i++) { saidas(false, true); delay(liga); saidas(false, false); delay(desliga); }
}

float bateriaV() {
  uint32_t mv = 0;
  for (uint8_t i = 0; i < 8; i++) mv += analogReadMilliVolts(PINO_BAT);
  return mv / 8.0 * 2 / 1000.0;    // divisor 100k/100k
}

void dormir() {
  saidas(false, false);
  digitalWrite(PINO_LED, HIGH);
  if (armada) {
    // armada: acorda se puxarem o pino (reed HIGH) ou se apertarem o botão (LOW)
    esp_deep_sleep_enable_gpio_wakeup(1ULL << PINO_REED, ESP_GPIO_WAKEUP_GPIO_HIGH);
    esp_deep_sleep_enable_gpio_wakeup(1ULL << PINO_BOTAO, ESP_GPIO_WAKEUP_GPIO_LOW);
  } else {
    // desarmada (pino fora): só acorda quando o pino voltar (reed LOW)
    esp_deep_sleep_enable_gpio_wakeup(1ULL << PINO_REED, ESP_GPIO_WAKEUP_GPIO_LOW);
  }
  esp_deep_sleep_start();
}

void estourar() {
  uint32_t t0 = millis();
  while (millis() - t0 < DURACAO_MS) {
    uint32_t t = millis() - t0;
    bool sirene = t < SIRENE_CHEIA || ((t / 250) % 2 == 0);
    saidas(sirene, true);  delay(ESTROBO_LIGA);
    saidas(sirene, false); delay(ESTROBO_DESLIGA);
  }
  saidas(false, false);
}

// conta o atraso; devolve false se o pino voltou (cancelado)
bool contar(uint16_t atrasoMs) {
  uint32_t t0 = millis();
  while (millis() - t0 < atrasoMs) {
    if (pinoNoLugar()) { delay(30); if (pinoNoLugar()) return false; }
    digitalWrite(PINO_LED, ((millis() - t0) / 250) % 2 ? HIGH : LOW);   // LED da placa pisca (só aparece aberta)
    delay(10);
  }
  return true;
}

void tratarBotao() {
  uint32_t t0 = millis();
  while (botaoApertado() && millis() - t0 < 2000) delay(10);
  if (millis() - t0 >= 2000) {                       // segurou: bateria
    float v = bateriaV();
    uint8_t nivel = v > 4.0 ? 4 : v > 3.8 ? 3 : v > 3.6 ? 2 : 1;
    delay(300); piscar(nivel, 400, 300);
    while (botaoApertado()) delay(10);
    return;
  }
  modo = (modo + 1) % 3;                             // toque curto: próximo modo
  prefs.putUChar("modo", modo);
  delay(200); piscar(modo + 1, 60, 250);
}

void setup() {
  pinMode(PINO_REED, INPUT);       // pull-up de 100k externo (funciona dormindo)
  pinMode(PINO_BOTAO, INPUT);      // pull-up de 100k externo
  pinMode(PINO_SIRENE, OUTPUT);
  pinMode(PINO_LUZ, OUTPUT);
  pinMode(PINO_LED, OUTPUT);
  saidas(false, false);
  digitalWrite(PINO_LED, HIGH);

  prefs.begin("granada", false);
  modo = prefs.getUChar("modo", 0) % 3;

  bool acordou = esp_sleep_get_wakeup_cause() == ESP_SLEEP_WAKEUP_GPIO;
  delay(20);                       // deixa o reed assentar

  if (!pinoNoLugar()) {
    if (acordou && armada) {       // puxaram o pino com ela armada
      delay(30);
      if (!pinoNoLugar()) {
        if (contar(ATRASOS_MS[modo])) { estourar(); armada = false; }
        // cancelada: o pino voltou, continua armada
      }
    } else {
      armada = false;              // ligou com o pino fora: não dispara, espera o pino
    }
  } else {
    if (!armada) { armada = true; piscar(1, 40, 100); }   // pino colocado: armou (1 piscada curta)
    else if (botaoApertado()) tratarBotao();
  }
  dormir();
}

void loop() {}   // nunca chega aqui: tudo acontece no setup e ela volta a dormir
