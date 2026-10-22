/*
  ==========================================================
   NÍVEL ELETRÔNICO ANTI-CANT - BLACK BIRD | PROJETO 03
  ==========================================================
   Placa: ESP32-C3 SuperMini (Ferramentas > Placa > "ESP32C3 Dev Module",
          USB CDC On Boot = Enabled)

   O que faz:
   - Até 0,5° de inclinação: LED verde (meio) aceso.
   - Caído para a DIREITA: acende o LED de CIMA. Para a ESQUERDA: o de BAIXO.
     Entre 0,5° e 2° o vermelho pisca; acima de 2° fica fixo.
   - Segurar ZERAR por 2 s: grava a posição atual como "nivelado".
   - Clique curto no ZERAR: troca o brilho (3 níveis; o último é o noturno).
   - Parado por 2 min: apaga e dorme. Acorda sozinho quando o rifle se mexe.

   Não precisa de biblioteca extra (o MPU6050 é lido direto pelo I2C).

   PRIMEIRO USO:
   1) Grave, ligue e incline o rifle para a direita. Se acender o LED de
      BAIXO em vez do de CIMA, troque INVERTER para true.
   2) Se o ângulo quase não muda quando você gira o rifle, troque
      EIXO_DO_CANO de 'X' para 'Y' (depende de como o MPU ficou na caixa).
   3) Nivele o rifle na bancada e segure ZERAR por 2 s.
  ==========================================================
*/

#include <Wire.h>
#include <Preferences.h>
#include "esp_sleep.h"

// ================= CONFIGURAÇÃO =================
const uint8_t PINO_LED_CIMA  = 5;   // vermelho de cima
const uint8_t PINO_LED_MEIO  = 6;   // verde
const uint8_t PINO_LED_BAIXO = 7;   // vermelho de baixo
const uint8_t PINO_ZERAR     = 10;  // botão -> GND
const uint8_t PINO_INT       = 4;   // INT do MPU6050 (opcional)
const uint8_t PINO_SDA = 8, PINO_SCL = 9;

const bool  USAR_INT     = false;   // true se você ligou o INT do MPU6050 no GPIO4
const char  EIXO_DO_CANO = 'X';     // 'X' ou 'Y': eixo do MPU que aponta para o cano
const bool  INVERTER     = false;   // troca os LEDs de cima e de baixo

const float VERDE_GRAUS = 0.5;      // até aqui = nivelado
const float FIXO_GRAUS  = 2.0;      // acima disso o vermelho fica fixo
const uint32_t DORMIR_MS = 120000;  // 2 min parado
const uint8_t BRILHOS[3] = {255, 60, 6};   // normal, médio, noturno

// ================= PROGRAMA =================
const uint8_t MPU = 0x68;
Preferences prefs;
float zero = 0, angulo = 0, anguloRef = 0;
uint8_t brilho = 0;
uint32_t tMexeu = 0;
RTC_DATA_ATTR float anguloAoDormir = 0;   // guardado durante o sono

void mpuEscreve(uint8_t reg, uint8_t val) {
  Wire.beginTransmission(MPU); Wire.write(reg); Wire.write(val); Wire.endTransmission();
}

bool lerAcel(float &ax, float &ay, float &az) {
  Wire.beginTransmission(MPU); Wire.write(0x3B);
  if (Wire.endTransmission(false) != 0) return false;
  if (Wire.requestFrom(MPU, (uint8_t)6) != 6) return false;
  int16_t x = (Wire.read() << 8) | Wire.read();
  int16_t y = (Wire.read() << 8) | Wire.read();
  int16_t z = (Wire.read() << 8) | Wire.read();
  ax = x / 16384.0; ay = y / 16384.0; az = z / 16384.0;   // em g (escala ±2 g)
  return true;
}

// inclinação em volta do cano, em graus
float lerInclinacao() {
  float ax, ay, az;
  if (!lerAcel(ax, ay, az)) return angulo;
  float a = (EIXO_DO_CANO == 'X') ? atan2(ay, az) : atan2(-ax, az);
  a *= 57.2958;
  return INVERTER ? -a : a;
}

void mpuAcordar() {
  mpuEscreve(0x6B, 0x00);   // sai do modo de espera
  mpuEscreve(0x6C, 0x00);
  mpuEscreve(0x1A, 0x05);   // filtro passa-baixa ~10 Hz (lê mais estável)
  mpuEscreve(0x1C, 0x00);   // ±2 g
  mpuEscreve(0x38, 0x00);   // desliga a interrupção de movimento (só é usada no sono)
  Wire.beginTransmission(MPU); Wire.write(0x3A); Wire.endTransmission(false);
  Wire.requestFrom(MPU, (uint8_t)1); Wire.read();   // lê o status: solta o pino INT
  delay(60);
}

void leds(uint8_t cima, uint8_t meio, uint8_t baixo) {
  analogWrite(PINO_LED_CIMA, cima);
  analogWrite(PINO_LED_MEIO, meio);
  analogWrite(PINO_LED_BAIXO, baixo);
}

void piscarVerde(uint8_t vezes) {
  for (uint8_t i = 0; i < vezes; i++) { leds(0, BRILHOS[brilho], 0); delay(120); leds(0, 0, 0); delay(120); }
}

void dormir() {
  leds(0, 0, 0);
  anguloAoDormir = angulo;
  if (USAR_INT) {
    // detecção de movimento do MPU6050 acorda a placa pelo GPIO4
    mpuEscreve(0x1F, 10);     // limite de movimento (~20 mg)
    mpuEscreve(0x20, 1);      // duração
    mpuEscreve(0x37, 0x20);   // INT ativo em nível alto, fica preso até ler
    mpuEscreve(0x38, 0x40);   // liga a interrupção de movimento
    esp_deep_sleep_enable_gpio_wakeup(1ULL << PINO_INT, ESP_GPIO_WAKEUP_GPIO_HIGH);
  } else {
    // sem o fio INT: o MPU fica em modo econômico e a placa confere a cada 2 s
    mpuEscreve(0x6C, 0x47);   // acelerômetro a 5 Hz, giroscópio desligado
    mpuEscreve(0x6B, 0x20);   // modo ciclo (economia)
    esp_sleep_enable_timer_wakeup(2000000ULL);
  }
  esp_deep_sleep_start();
}

void setup() {
  pinMode(PINO_ZERAR, INPUT_PULLUP);
  pinMode(PINO_LED_CIMA, OUTPUT); pinMode(PINO_LED_MEIO, OUTPUT); pinMode(PINO_LED_BAIXO, OUTPUT);
  Wire.begin(PINO_SDA, PINO_SCL);
  Wire.setClock(400000);

  prefs.begin("anticant", false);
  zero = prefs.getFloat("zero", 0);
  brilho = prefs.getUChar("brilho", 0) % 3;

  bool acordouTimer = esp_sleep_get_wakeup_cause() == ESP_SLEEP_WAKEUP_TIMER;
  mpuAcordar();
  angulo = lerInclinacao() - zero;

  // acordou só para conferir: se o rifle não mexeu, volta a dormir sem acender nada
  if (acordouTimer && fabs(angulo - anguloAoDormir) < 1.0) dormir();

  if (esp_sleep_get_wakeup_cause() == ESP_SLEEP_WAKEUP_UNDEFINED) {   // ligou na chave
    leds(BRILHOS[brilho], 0, 0); delay(150); leds(0, BRILHOS[brilho], 0); delay(150); leds(0, 0, BRILHOS[brilho]); delay(150);
    leds(0, 0, 0);
  }
  anguloRef = angulo;
  tMexeu = millis();
}

void loop() {
  static uint32_t tApertou = 0;
  static bool apertado = false, zerou = false;
  uint32_t agora = millis();

  // leitura suavizada (50 vezes por segundo)
  angulo = angulo * 0.85 + (lerInclinacao() - zero) * 0.15;

  // mexeu? (mais de 0,3° desde a última referência)
  if (fabs(angulo - anguloRef) > 0.3) { anguloRef = angulo; tMexeu = agora; }

  // botão ZERAR: segurar 2 s = zera; clique curto = brilho
  bool b = digitalRead(PINO_ZERAR) == LOW;
  if (b && !apertado) { apertado = true; zerou = false; tApertou = agora; tMexeu = agora; }
  if (b && apertado && !zerou && agora - tApertou > 2000) {
    float soma = 0;
    for (int i = 0; i < 50; i++) { soma += lerInclinacao(); delay(10); }
    zero = soma / 50; prefs.putFloat("zero", zero);
    angulo = 0; anguloRef = 0; zerou = true;
    piscarVerde(3);
  }
  if (!b && apertado) {
    apertado = false;
    if (!zerou && agora - tApertou > 40) { brilho = (brilho + 1) % 3; prefs.putUChar("brilho", brilho); piscarVerde(1); }
  }

  // LEDs
  uint8_t B = BRILHOS[brilho];
  float a = fabs(angulo);
  bool pisca = (agora / 125) % 2;                 // 4 piscadas por segundo
  if (a <= VERDE_GRAUS) leds(0, B, 0);
  else {
    uint8_t v = (a > FIXO_GRAUS || pisca) ? B : 0;
    if (angulo > 0) leds(v, 0, 0); else leds(0, 0, v);
  }

  if (!apertado && agora - tMexeu > DORMIR_MS) dormir();
  delay(20);
}
