/*
  ==========================================================
   CRONÓGRAFO COM ANÁLISE DE CONSISTÊNCIA - BLACK BIRD | PROJETO 04
  ==========================================================
   Placa: ESP32-C3 SuperMini (Ferramentas > Placa > "ESP32C3 Dev Module",
          USB CDC On Boot = Enabled)

   O que faz:
   - 2 barreiras infravermelhas a 100 mm. A BB corta a 1ª e depois a 2ª:
     velocidade = 0,100 m / tempo entre as duas.
   - Mostra m/s, fps e joules (com o peso de BB escolhido).
   - Guarda a série (até 50 tiros): média, desvio padrão (DP), mínimo,
     máximo e variação extrema (ES = máximo - mínimo).
   - Botão PESO: troca o peso da BB (fica salvo).
   - Clique curto em ZERAR: alterna entre último tiro, estatística e
     cada tiro da série. Segurar ZERAR 2 s: começa uma série nova.
   - Se só a 1ª barreira disparar, ou a velocidade sair de 30-200 m/s,
     mostra ERRO e não conta na série.

   Bibliotecas: "Adafruit SSD1306" e "Adafruit GFX Library".

   AJUSTE DOS SENSORES: com o túnel vazio, gire o trimpot de cada
   barreira até o pino de saída ficar em HIGH; passando um palito pelo
   furo ele deve ir a LOW. O monitor serial (115200) mostra os dois.
  ==========================================================
*/

#include <Wire.h>
#include <Preferences.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>
#include "esp_timer.h"

// ================= CONFIGURAÇÃO =================
const uint8_t PINO_BARREIRA1 = 3;   // LM393 OUT1 (barreira da boca)
const uint8_t PINO_BARREIRA2 = 4;   // LM393 OUT2
const uint8_t PINO_PESO      = 5;   // botão -> GND
const uint8_t PINO_ZERAR     = 6;   // botão -> GND
const uint8_t PINO_BATERIA   = 1;   // divisor 100k/100k da bateria
const uint8_t PINO_SDA = 8, PINO_SCL = 9;

const float DISTANCIA_M = 0.100;    // distância entre as barreiras (meça a sua!)
const float V_MIN = 30, V_MAX = 200;   // fora disso = erro
const uint32_t ESPERA_MAX_US = 20000;  // 1ª barreira sem a 2ª por 20 ms = erro

// borda quando a BB corta o feixe (LM393: saída cai para LOW)
#define BORDA_BB FALLING               // se não medir nada, troque por RISING

const float PESOS[] = {0.20, 0.25, 0.28, 0.30, 0.32, 0.36, 0.40, 0.45};
const uint8_t N_PESOS = sizeof(PESOS) / sizeof(PESOS[0]);
const uint8_t MAX_TIROS = 50;

// ================= PROGRAMA =================
Adafruit_SSD1306 tela(128, 64, &Wire, -1);
Preferences prefs;

volatile int64_t t1 = 0, t2 = 0;
volatile bool armado = false, pronto = false;

float tiros[MAX_TIROS];
uint8_t nTiros = 0;
uint16_t numeroTiro = 0;            // conta todos os tiros (para o título)
float ultimaV = 0;
bool ultimoErro = false;
uint8_t idxPeso = 1;                // 0,25 g
int8_t vista = 0;                   // 0 = último, 1 = estatística, 2.. = tiro 1, 2, 3...
uint32_t tMostraPeso = 0;

void IRAM_ATTR aoBarreira1() {
  if (armado) return;
  t1 = esp_timer_get_time(); armado = true;
}
void IRAM_ATTR aoBarreira2() {
  if (!armado || pronto) return;
  t2 = esp_timer_get_time(); pronto = true;
}

float pesoKg() { return PESOS[idxPeso] / 1000.0; }

int bateriaPct() {
  uint32_t mv = analogReadMilliVolts(PINO_BATERIA) * 2;
  if (mv < 1000) return -1;
  return constrain(map(mv, 3300, 4150, 0, 100), 0, 100);
}

void estatistica(float &med, float &dp, float &mn, float &mx) {
  med = dp = mn = mx = 0;
  if (!nTiros) return;
  mn = mx = tiros[0];
  for (uint8_t i = 0; i < nTiros; i++) { med += tiros[i]; mn = min(mn, tiros[i]); mx = max(mx, tiros[i]); }
  med /= nTiros;
  if (nTiros > 1) { for (uint8_t i = 0; i < nTiros; i++) dp += sq(tiros[i] - med); dp = sqrt(dp / (nTiros - 1)); }
}

void desenhar() {
  char b[24];
  tela.clearDisplay();
  tela.setTextColor(SSD1306_WHITE);
  tela.setTextSize(1);

  if (millis() - tMostraPeso < 2000) {                   // tela do peso
    tela.setCursor(0, 2); tela.print("PESO DA BB");
    tela.setTextSize(2); tela.setCursor(0, 26); snprintf(b, sizeof(b), "%.2f g", PESOS[idxPeso]); tela.print(b);
    tela.setTextSize(1); tela.setCursor(0, 54); tela.print("PESO = proximo");
  } else if (vista == 0) {                                // último tiro
    snprintf(b, sizeof(b), "TIRO %u  %.2fg", numeroTiro, PESOS[idxPeso]);
    tela.setCursor(0, 2); tela.print(b);
    int bat = bateriaPct();
    if (bat >= 0) { tela.setCursor(104, 2); tela.print(bat); tela.print('%'); }
    if (ultimoErro) { tela.setTextSize(2); tela.setCursor(0, 22); tela.print("ERRO"); tela.setTextSize(1); tela.setCursor(0, 48); tela.print("nao contou na serie"); }
    else if (numeroTiro == 0) { tela.setCursor(0, 30); tela.print("PRONTO - ATIRE"); }
    else {
      tela.setTextSize(3); tela.setCursor(0, 18); snprintf(b, sizeof(b), "%.1f", ultimaV); tela.print(b);
      tela.setTextSize(1); tela.setCursor(98, 32); tela.print("m/s");
      tela.setCursor(0, 46); snprintf(b, sizeof(b), "%.0f fps", ultimaV * 3.28084); tela.print(b);
      tela.setCursor(0, 56); snprintf(b, sizeof(b), "%.2f J", 0.5 * pesoKg() * ultimaV * ultimaV); tela.print(b);
    }
  } else if (vista == 1) {                                // estatística
    float med, dp, mn, mx; estatistica(med, dp, mn, mx);
    snprintf(b, sizeof(b), "SERIE  n=%u", nTiros); tela.setCursor(0, 2); tela.print(b);
    snprintf(b, sizeof(b), "MED %.1f m/s", med);      tela.setCursor(0, 16); tela.print(b);
    snprintf(b, sizeof(b), "DP  %.1f", dp);           tela.setCursor(0, 28); tela.print(b);
    snprintf(b, sizeof(b), "MIN %.1f MAX %.1f", mn, mx); tela.setCursor(0, 40); tela.print(b);
    snprintf(b, sizeof(b), "ES  %.1f", mx - mn);      tela.setCursor(0, 52); tela.print(b);
  } else {                                                // tiro a tiro
    uint8_t i = vista - 2;
    snprintf(b, sizeof(b), "SERIE  tiro %u/%u", i + 1, nTiros); tela.setCursor(0, 2); tela.print(b);
    tela.setTextSize(3); tela.setCursor(0, 22); snprintf(b, sizeof(b), "%.1f", tiros[i]); tela.print(b);
    tela.setTextSize(1); tela.setCursor(98, 36); tela.print("m/s");
    tela.setCursor(0, 54); snprintf(b, sizeof(b), "%.0f fps  %.2f J", tiros[i] * 3.28084, 0.5 * pesoKg() * tiros[i] * tiros[i]); tela.print(b);
  }
  tela.display();
}

void novoTiro(float v) {
  numeroTiro++;
  ultimoErro = (v < V_MIN || v > V_MAX);
  if (!ultimoErro) {
    ultimaV = v;
    if (nTiros < MAX_TIROS) tiros[nTiros++] = v;
    else { memmove(tiros, tiros + 1, (MAX_TIROS - 1) * sizeof(float)); tiros[MAX_TIROS - 1] = v; }
  }
  vista = 0;
  Serial.printf("tiro %u: %.1f m/s %s\n", numeroTiro, v, ultimoErro ? "(ERRO)" : "");
}

void setup() {
  Serial.begin(115200);
  pinMode(PINO_BARREIRA1, INPUT_PULLUP);
  pinMode(PINO_BARREIRA2, INPUT_PULLUP);
  pinMode(PINO_PESO, INPUT_PULLUP);
  pinMode(PINO_ZERAR, INPUT_PULLUP);
  attachInterrupt(digitalPinToInterrupt(PINO_BARREIRA1), aoBarreira1, BORDA_BB);
  attachInterrupt(digitalPinToInterrupt(PINO_BARREIRA2), aoBarreira2, BORDA_BB);

  prefs.begin("crono", false);
  idxPeso = prefs.getUChar("peso", 1) % N_PESOS;

  Wire.begin(PINO_SDA, PINO_SCL);
  tela.begin(SSD1306_SWITCHCAPVCC, 0x3C);
  tela.clearDisplay(); tela.setTextColor(SSD1306_WHITE);
  tela.setTextSize(2); tela.setCursor(0, 10); tela.print("BLACK BIRD");
  tela.setTextSize(1); tela.setCursor(0, 40); tela.print("CRONOGRAFO");
  tela.display();
  delay(1000);
  desenhar();
}

void loop() {
  static bool pesoAntes = false, zerarAntes = false, zerou = false;
  static uint32_t tZerar = 0, tDesenho = 0, tSerial = 0;
  uint32_t agora = millis();

  // ---- disparo ----
  if (pronto) {
    noInterrupts(); int64_t dt = t2 - t1; armado = pronto = false; interrupts();
    novoTiro(dt > 0 ? DISTANCIA_M / (dt / 1e6) : 0);
    desenhar();
    delay(150);                                       // ignora reflexo/rebote da mesma BB
  } else if (armado && esp_timer_get_time() - t1 > ESPERA_MAX_US) {
    armado = false;
    numeroTiro++; ultimoErro = true; vista = 0;      // só a 1ª barreira disparou
    Serial.println("ERRO: so a 1a barreira");
    desenhar();
  }

  // ---- botão PESO ----
  bool p = digitalRead(PINO_PESO) == LOW;
  if (p && !pesoAntes) {
    if (agora - tMostraPeso < 2000) idxPeso = (idxPeso + 1) % N_PESOS;   // já está na tela do peso: troca
    prefs.putUChar("peso", idxPeso);
    tMostraPeso = agora;
    desenhar();
  }
  pesoAntes = p;

  // ---- botão ZERAR ----
  bool z = digitalRead(PINO_ZERAR) == LOW;
  if (z && !zerarAntes) { tZerar = agora; zerou = false; }
  if (z && !zerou && agora - tZerar > 2000) {
    nTiros = 0; numeroTiro = 0; ultimoErro = false; vista = 0; zerou = true;
    tela.clearDisplay(); tela.setTextSize(2); tela.setCursor(0, 20); tela.print("SERIE NOVA"); tela.display();
    delay(700);
    desenhar();
  }
  if (!z && zerarAntes && !zerou && agora - tZerar > 40) {
    vista++;
    if (vista > 1 + nTiros) vista = 0;
    desenhar();
  }
  zerarAntes = z;

  // ---- tela e ajuda no monitor serial ----
  if (agora - tDesenho > 1000) { tDesenho = agora; desenhar(); }
  if (agora - tSerial > 2000) {
    tSerial = agora;
    Serial.printf("barreira1=%d barreira2=%d (HIGH=1 livre)\n", digitalRead(PINO_BARREIRA1), digitalRead(PINO_BARREIRA2));
  }
  delay(2);
}
