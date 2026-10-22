/*
  ==========================================================
   SPEEDLOADER ELÉTRICO - BLACK BIRD | PROJETO 07
  ==========================================================
   Placa: ESP32-C3 SuperMini, programada pela IDE do Arduino
          (Ferramentas > Placa > "ESP32C3 Dev Module", USB CDC On Boot = Enabled)

   O que faz:
   - Gatilho (botão arcade): carrega o carregador até a quantidade
     escolhida e para sozinho. Apertar de novo pausa/continua.
   - Botões - e +: escolhem a quantidade (30, 50, 120, 150, 300 ou
     CONTÍNUO, que carrega enquanto o gatilho estiver apertado).
   - Um sensor infravermelho no tubo conta cada BB que passa.
   - Força total no fim: quando o carregador está quase cheio, a mola
     dele empurra de volta; nos últimos 20% o motor vai a 100%.
   - BB parou de passar: primeiro AGITA a roda (vai e volta curto),
     depois dá ré para destravar e tenta de novo. Depois de 3
     tentativas para e avisa "CHEIO OU TRAVOU".
   - Ao ligar: a roda "chacoalha" algumas vezes para soltar BBs que
     ficaram presas no armazenamento. Ligue segurando "-" para chacoalhar
     enquanto segurar (anti-travamento estendido).
   - Partida rápida: com ele desligado (dormindo), segure o gatilho:
     ele acorda e já começa a carregar a última quantidade usada.
   - Contínuo: soltar e apertar de novo continua a mesma contagem;
     a contagem zera sozinha depois de 1 min parado.
   - Tela de carga: BBs, BB/s e tempo. Contador total de BBs carregadas
     aparece ao ligar (fica salvo).
   - Segurar - e + juntos: ré manual enquanto segurar.
   - Desliga a tela e dorme depois de 3 min parado; o gatilho acorda.

   Várias ideias vêm do Nano Speedloader (ProtoForge): chacoalhar ao ligar,
   partida pelo gatilho, contagem que zera após 1 min, contador total e
   força maior com o carregador quase cheio.

   Bibliotecas: "Adafruit SSD1306" e "Adafruit GFX Library".
  ==========================================================
*/

#include <Wire.h>
#include <Preferences.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>
#include "esp_sleep.h"

// ================= CONFIGURAÇÃO =================
// Pinos
const uint8_t PINO_MOTOR_A  = 6;    // L9110S A-1A
const uint8_t PINO_MOTOR_B  = 7;    // L9110S A-1B
const uint8_t PINO_IR_SAIDA = 3;    // saída do LM393 (sensor do tubo)
const uint8_t PINO_IR_LED   = 10;   // LED infravermelho (via resistor de 100 Ω)
const uint8_t PINO_GATILHO  = 4;    // botão arcade -> GND
const uint8_t PINO_MENOS    = 5;    // botão 6x6 -> GND
const uint8_t PINO_MAIS     = 0;    // botão 6x6 -> GND
const uint8_t PINO_BATERIA  = 1;    // divisor 100k/100k da bateria (opcional)
const uint8_t PINO_SDA = 8, PINO_SCL = 9;

// Motor
const bool     INVERTER_MOTOR = false; // a roda gira e as BBs não descem? troque para true
const uint8_t  VELOCIDADE   = 200;  // 0-255 durante a carga (abaixe se as BBs pularem)
const uint8_t  FORCA_FINAL  = 255;  // nos últimos 20% da quantidade (mola do carregador)
const uint16_t TRAVA_MS     = 900;  // sem BB por esse tempo com o motor girando = travou
const uint16_t AGITA_MS     = 120;  // cada meia-volta da agitação
const uint16_t RE_MS        = 300;  // tempo de ré para destravar
const uint8_t  TENTATIVAS   = 3;    // tentativas antes de desistir

// Sensor: nível da saída do LM393 quando a BB corta o feixe.
// Se a contagem não funcionar, troque LOW por HIGH.
const uint8_t IR_NIVEL_BB = LOW;
const uint16_t IR_INTERVALO_MIN_MS = 15;   // ignora repiques menores que isso

// Quantidades (0 = contínuo)
const uint16_t QUANTIDADES[] = {30, 50, 120, 150, 300, 0};
const uint8_t  N_QTD = sizeof(QUANTIDADES) / sizeof(QUANTIDADES[0]);

const uint32_t ZERA_CONTAGEM_MS = 60000;    // contagem zera depois de 1 min parado
const uint32_t DORMIR_MS = 180000;          // 3 min parado

// ================= PROGRAMA =================
Adafruit_SSD1306 tela(128, 32, &Wire, -1);
Preferences prefs;

volatile uint32_t contagem = 0;
volatile uint32_t ultimaBB = 0;

uint8_t idxQtd = 2;                 // começa em 120 (mid-cap M4)
enum Estado { PRONTO, CARREGANDO, PAUSADO, AGITANDO, RE, CHEIO, MANUAL_RE };
Estado estado = PRONTO;
uint8_t tentativas = 0;
uint32_t tFase = 0, tUltimaAtividade = 0, tDesenho = 0;
uint32_t tInicioCarga = 0, msCarregando = 0, tFimCarga = 0;
uint32_t totalGeral = 0;            // BBs carregadas na vida do aparelho (salvo)
uint32_t contagemSalva = 0;         // parte da contagem que já entrou no total

// ---------------- sensor (interrupção) ----------------
void IRAM_ATTR aoMudarIR() {
  if (digitalRead(PINO_IR_SAIDA) != IR_NIVEL_BB) return;
  uint32_t agora = millis();
  if (agora - ultimaBB < IR_INTERVALO_MIN_MS) return;
  ultimaBB = agora;
  contagem++;
}

// ---------------- motor ----------------
uint16_t alvo() { return QUANTIDADES[idxQtd]; }

void motor(int velocidade) {          // + = carrega, - = ré, 0 = para
  if (INVERTER_MOTOR) velocidade = -velocidade;
  if (velocidade > 0)      { analogWrite(PINO_MOTOR_A, velocidade); digitalWrite(PINO_MOTOR_B, LOW); }
  else if (velocidade < 0) { digitalWrite(PINO_MOTOR_A, LOW); analogWrite(PINO_MOTOR_B, -velocidade); }
  else { analogWrite(PINO_MOTOR_A, 0); analogWrite(PINO_MOTOR_B, 0); digitalWrite(PINO_MOTOR_A, LOW); digitalWrite(PINO_MOTOR_B, LOW); }
}
uint8_t forcaAgora() {                // força total nos últimos 20% (mola do carregador empurra de volta)
  if (alvo() && contagem * 5 >= (uint32_t)alvo() * 4) return FORCA_FINAL;
  return VELOCIDADE;
}
void motorFrente() { motor(forcaAgora()); }
void motorParar()  { motor(0); }

void chacoalhar(uint8_t vezes) {      // vai e volta curto para soltar BBs emboladas
  for (uint8_t i = 0; i < vezes; i++) { motor(255); delay(AGITA_MS); motor(-255); delay(AGITA_MS); }
  motorParar();
}

// ---------------- botões (com filtro) ----------------
struct Botao { uint8_t pino; bool estavel, bruto; uint32_t tMudou, tApertou; };
Botao bGat = {PINO_GATILHO}, bMenos = {PINO_MENOS}, bMais = {PINO_MAIS};

// devolve 1 quando apertou, -1 quando soltou, 0 sem mudança
int lerBotao(Botao &b) {
  bool v = digitalRead(b.pino) == LOW;
  uint32_t agora = millis();
  if (v != b.bruto) { b.bruto = v; b.tMudou = agora; }
  if (agora - b.tMudou > 25 && v != b.estavel) {
    b.estavel = v;
    if (v) { b.tApertou = agora; return 1; }
    return -1;
  }
  return 0;
}

int bateriaPct() {
  uint32_t mv = analogReadMilliVolts(PINO_BATERIA) * 2;
  if (mv < 1000) return -1;                     // divisor não instalado
  return constrain(map(mv, 3300, 4150, 0, 100), 0, 100);
}

// soma no contador total o que foi carregado desde a última vez
void salvarTotal() {
  if (contagem > contagemSalva) { totalGeral += contagem - contagemSalva; contagemSalva = contagem; prefs.putUInt("total", totalGeral); }
}
void zerarContagem() { salvarTotal(); contagem = 0; contagemSalva = 0; msCarregando = 0; }

void comecar() {
  uint32_t agora = millis();
  if (alvo() == 0) { if (agora - tFimCarga > ZERA_CONTAGEM_MS) zerarContagem(); }   // contínuo: continua a contagem
  else if (estado == PRONTO || estado == CHEIO) zerarContagem();                      // quantidade: carregador novo
  tentativas = 0;
  ultimaBB = agora;
  tInicioCarga = agora;
  estado = CARREGANDO;
  prefs.putUChar("qtd", idxQtd);               // partida rápida usa a última quantidade
  motorFrente();
}
void parar(Estado novo) {
  motorParar();
  if (estado == CARREGANDO || estado == AGITANDO || estado == RE) { msCarregando += millis() - tInicioCarga; tFimCarga = millis(); }
  estado = novo;
  salvarTotal();
}

void desenhar() {
  char buf[24];
  tela.clearDisplay();
  tela.setTextColor(SSD1306_WHITE);
  bool carregando = (estado == CARREGANDO || estado == AGITANDO || estado == RE);
  uint32_t ms = msCarregando + (carregando ? millis() - tInicioCarga : 0);
  // linha de cima: quantidade
  tela.setTextSize(2);
  tela.setCursor(0, 0);
  if (alvo()) snprintf(buf, sizeof(buf), "%lu/%u", (unsigned long)contagem, alvo());
  else snprintf(buf, sizeof(buf), "%lu", (unsigned long)contagem);
  tela.print(buf);
  tela.setTextSize(1);
  // canto direito: bateria (parado) ou BB/s (carregando)
  if (carregando && ms > 500) { tela.setCursor(92, 0); tela.print(contagem * 1000.0 / ms, 1); tela.setCursor(104, 9); tela.print("/s"); }
  else { int b = bateriaPct(); if (b >= 0) { tela.setCursor(104, 0); tela.print(b); tela.print('%'); } }
  // linha de baixo: estado + tempo
  tela.setCursor(0, 22);
  switch (estado) {
    case PRONTO:     tela.print(alvo() ? "PRONTO - GATILHO" : "CONTINUO: SEGURE"); break;
    case CARREGANDO: tela.print("CARREGANDO"); break;
    case PAUSADO:    tela.print("PAUSADO"); break;
    case AGITANDO:   tela.print("AGITANDO"); break;
    case RE:         tela.print("DESTRAVANDO"); break;
    case CHEIO:      tela.print("CHEIO OU TRAVOU"); break;
    case MANUAL_RE:  tela.print("RE MANUAL"); break;
  }
  if (ms && estado != PRONTO) { snprintf(buf, sizeof(buf), "%.1fs", ms / 1000.0); tela.setCursor(128 - 6 * strlen(buf), 22); tela.print(buf); }
  tela.display();
}

void dormir() {
  motorParar();
  salvarTotal();
  digitalWrite(PINO_IR_LED, LOW);
  tela.ssd1306_command(SSD1306_DISPLAYOFF);
  esp_deep_sleep_enable_gpio_wakeup(1ULL << PINO_GATILHO, ESP_GPIO_WAKEUP_GPIO_LOW);
  esp_deep_sleep_start();
}

void setup() {
  pinMode(PINO_MOTOR_A, OUTPUT); pinMode(PINO_MOTOR_B, OUTPUT); motorParar();
  pinMode(PINO_IR_LED, OUTPUT);  digitalWrite(PINO_IR_LED, HIGH);
  pinMode(PINO_IR_SAIDA, INPUT_PULLUP);
  pinMode(PINO_GATILHO, INPUT_PULLUP); pinMode(PINO_MENOS, INPUT_PULLUP); pinMode(PINO_MAIS, INPUT_PULLUP);
  attachInterrupt(digitalPinToInterrupt(PINO_IR_SAIDA), aoMudarIR, CHANGE);

  prefs.begin("speedloader", false);
  idxQtd = prefs.getUChar("qtd", 2);
  if (idxQtd >= N_QTD) idxQtd = 2;
  totalGeral = prefs.getUInt("total", 0);

  Wire.begin(PINO_SDA, PINO_SCL);
  tela.begin(SSD1306_SWITCHCAPVCC, 0x3C);
  tela.setTextColor(SSD1306_WHITE);

  // PARTIDA RÁPIDA: acordou pelo gatilho e ele continua apertado -> já carrega
  bool acordouPeloGatilho = esp_sleep_get_wakeup_cause() == ESP_SLEEP_WAKEUP_GPIO;
  delay(30);
  if (acordouPeloGatilho && digitalRead(PINO_GATILHO) == LOW) {
    bGat.estavel = bGat.bruto = true;             // o "soltar" do gatilho será tratado normalmente
    tUltimaAtividade = millis();
    tFimCarga = 0;
    comecar();
    return;
  }

  // abertura: nome + contador total
  tela.clearDisplay(); tela.setTextSize(1);
  tela.setCursor(0, 0);  tela.print("BLACK BIRD SPEEDLOADER");
  tela.setCursor(0, 16); tela.print("TOTAL: "); tela.print(totalGeral); tela.print(" BBs");
  tela.display();

  // ANTI-TRAVAMENTO: chacoalha ao ligar; segurando "-" chacoalha enquanto segurar
  chacoalhar(3);
  while (digitalRead(PINO_MENOS) == LOW) {
    tela.clearDisplay(); tela.setCursor(0, 12); tela.print("SOLTANDO BBs PRESAS"); tela.display();
    chacoalhar(1);
  }
  delay(400);
  tUltimaAtividade = millis();
}

void loop() {
  uint32_t agora = millis();
  int g = lerBotao(bGat), m = lerBotao(bMenos), p = lerBotao(bMais);
  bool ativo = (estado == CARREGANDO || estado == AGITANDO || estado == RE || estado == MANUAL_RE);
  if (g || m || p || bGat.estavel || bMenos.estavel || bMais.estavel || ativo) tUltimaAtividade = agora;

  // ré manual: - e + juntos
  if (bMenos.estavel && bMais.estavel) {
    if (estado != MANUAL_RE && agora - max(bMenos.tApertou, bMais.tApertou) > 300) { parar(MANUAL_RE); motor(-VELOCIDADE); }
  } else if (estado == MANUAL_RE) {
    parar(PRONTO);
  }

  // escolha da quantidade (só parado)
  if (estado == PRONTO || estado == CHEIO || estado == PAUSADO) {
    if (m == -1 && !bMais.estavel)  { idxQtd = (idxQtd + N_QTD - 1) % N_QTD; prefs.putUChar("qtd", idxQtd); zerarContagem(); estado = PRONTO; }
    if (p == -1 && !bMenos.estavel) { idxQtd = (idxQtd + 1) % N_QTD;         prefs.putUChar("qtd", idxQtd); zerarContagem(); estado = PRONTO; }
  }

  // gatilho
  if (alvo() == 0) {                                   // modo contínuo: carrega enquanto segura
    if (g == 1 && estado != MANUAL_RE) comecar();
    if (g == -1 && (estado == CARREGANDO || estado == AGITANDO || estado == RE)) parar(PRONTO);
  } else if (g == 1) {
    if (estado == CARREGANDO || estado == AGITANDO || estado == RE) parar(PAUSADO);
    else if (estado != MANUAL_RE) {
      if (estado == PAUSADO) { tentativas = 0; ultimaBB = agora; tInicioCarga = agora; estado = CARREGANDO; motorFrente(); }   // continua
      else comecar();
    }
  }

  // BB passando de novo depois de agitar/ré: zera as tentativas
  static uint32_t contagemAnterior = 0;
  if (contagem != contagemAnterior) { contagemAnterior = contagem; tentativas = 0; }

  // carregando: confere quantidade e travamento
  if (estado == CARREGANDO) {
    motorFrente();                                    // aplica a força final quando chega nos 20%
    if (alvo() && contagem >= alvo()) parar(PRONTO);
    else if (agora - ultimaBB > TRAVA_MS) {
      if (++tentativas > TENTATIVAS) parar(CHEIO);
      else { estado = AGITANDO; tFase = agora; }
    }
  } else if (estado == AGITANDO) {                    // 1º agita (vai e volta), depois dá ré
    uint32_t t = agora - tFase;
    if (t < 4 * AGITA_MS) motor(((t / AGITA_MS) % 2) ? -255 : 255);
    else { motor(-forcaAgora()); estado = RE; tFase = agora; }
  } else if (estado == RE && agora - tFase > RE_MS) {
    ultimaBB = agora;                                 // dá um tempo novo depois da ré
    estado = CARREGANDO; motorFrente();
  }

  // contagem zera sozinha depois de 1 min parado
  if ((estado == PRONTO || estado == CHEIO || estado == PAUSADO) && contagem && tFimCarga && agora - tFimCarga > ZERA_CONTAGEM_MS) {
    zerarContagem(); estado = PRONTO; tFimCarga = 0;
  }

  if (agora - tDesenho > 100) { tDesenho = agora; desenhar(); }
  if (agora - tUltimaAtividade > DORMIR_MS) dormir();
}
