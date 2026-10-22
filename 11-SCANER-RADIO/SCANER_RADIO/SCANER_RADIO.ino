/*
  ==========================================================
   SCANNER DE RADIO UHF - BLACK BIRD | PROJETO 11
  ==========================================================
   SOMENTE RECEPCAO. Este programa so MEDE a forca do sinal
   (RSSI) em cada frequencia. Ele nao transmite nada, nao
   interfere em ninguem e nao demodula voz. Nao existe nenhuma
   funcao de transmissao neste codigo, e nao deve ser adicionada:
   transmitir sem licenca ou bloquear sinais e ilegal (Anatel).

   O que faz:
   - Varre 400-464 MHz em passos de 25 kHz (ou so os 16 canais
     PMR446, no modo rapido) e acha frequencias com sinal ~15 dB
     acima do ruido.
   - Guarda o historico da partida: ranking das frequencias mais
     vistas, RSSI de pico (proximidade) e ha quanto tempo apareceu.
   - Ignora as SUAS frequencias (lista abaixo).
   - Vibra quando aparece um canal novo ou que voltou depois de um
     tempo parado. Quanto mais forte o sinal, mais longa a vibracao.

   Botao:
     clique curto     -> proxima pagina (ou acorda a tela)
     segurar 2 a 5 s  -> ZERA a partida (solte quando a tela pedir)
     segurar 5 s+     -> troca o modo: UHF completo <-> PMR446 rapido

   Bibliotecas (Ferramentas > Gerenciar bibliotecas):
     - SmartRC-CC1101-Driver-Lib (LSatan)
     - Adafruit SSD1306 e Adafruit GFX Library (Adafruit)

   Placa: ESP32 Dev Module. Tambem compila para Arduino Nano
   (veja o README: o Nano precisa de divisores de tensao no CC1101).
  ==========================================================
*/

#include <SPI.h>
#include <Wire.h>
#include <ELECHOUSE_CC1101_SRC_DRV.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>
#if defined(ESP32)
  #include <WiFi.h>
#endif

// ==========================================================
//  CONFIGURACAO - mude aqui
// ==========================================================

// --- Faixa de varredura (modo UHF completo) ---
const uint32_t FAIXA_INICIO_KHZ = 400000;   // 400,000 MHz
const uint32_t FAIXA_FIM_KHZ    = 464000;   // 464,000 MHz
const uint16_t PASSO_KHZ        = 25;       // passo entre leituras

// --- Deteccao ---
const int8_t   LIMIAR_DB      = 15;    // dB acima do ruido medio para contar como "ativa"
const uint16_t RSSI_ESPERA_US = 1000;  // espera a recalibracao + RSSI estabilizar em cada frequencia
const uint16_t BANDA_RX_KHZ   = 58;    // banda de recepcao do CC1101 (58 e a menor)

// --- Minhas frequencias: NUNCA entram no ranking nem vibram ---
// Coloque a do seu squad e a da organizacao, separadas por virgula (em kHz).
const uint32_t MINHAS_FREQS_KHZ[] = { 455455 };   // 455,455 MHz
const uint16_t TOLERANCIA_MINHA_KHZ = 50;        // +/- em kHz

// --- Historico ---
const uint16_t AGRUPAR_KHZ  = 30;   // picos a menos disso viram a mesma frequencia
const uint16_t REATIVAR_SEG = 60;   // parada ha mais que isso e voltou = vibra de novo

// --- Vibracao (mais forte o sinal = mais longa) ---
const uint16_t VIBRA_MIN_MS = 80;
const uint16_t VIBRA_MAX_MS = 600;
const int8_t   RSSI_FRACO   = -100;   // dBm -> vibracao minima
const int8_t   RSSI_FORTE   = -40;    // dBm -> vibracao maxima

// --- Tela ---
const uint8_t  OLED_ENDERECO     = 0x3C;
const uint16_t TELA_APAGA_SEG    = 30;    // apaga a tela parada para economizar (0 = nunca)
const bool     ACORDA_NO_ALERTA  = true;  // canal novo acende a tela
const uint8_t  BRILHO_TELA       = 40;    // 0-255 (baixo = discreto e economiza)

// --- Modo inicial ---
const bool INICIAR_EM_PMR446 = false;

// --- Pinos ---
#if defined(ESP32)
  const uint8_t PINO_SCK = 18, PINO_MISO = 19, PINO_MOSI = 23, PINO_CSN = 5;
  const uint8_t PINO_GDO0 = 2;        // opcional, o RSSI nao precisa dele
  const uint8_t PINO_SDA = 21, PINO_SCL = 22;
  const uint8_t PINO_MOTOR = 15;      // base do BC547 (via 1k)
  const uint8_t PINO_BOTAO = 4;       // outro lado do botao no GND
  const bool    USAR_BATERIA = true;  // divisor 100k/100k da bateria no GPIO34
  const uint8_t PINO_BATERIA = 34;
  #define MAX_HIST 30
#else
  // Arduino Nano: SPI fixo D13 (SCK), D12 (MISO), D11 (MOSI), D10 (CSN); OLED em A4/A5
  const uint8_t PINO_GDO0 = 2;
  const uint8_t PINO_MOTOR = 5;
  const uint8_t PINO_BOTAO = 4;
  const bool    USAR_BATERIA = false;
  const uint8_t PINO_BATERIA = A0;
  #define MAX_HIST 10                 // o Nano tem pouca memoria
#endif

// ==========================================================
//  DAQUI PARA BAIXO E O PROGRAMA
// ==========================================================

Adafruit_SSD1306 tela(128, 64, &Wire, -1);

// Canais PMR446: 16 canais de 12,5 kHz a partir de 446,00625 MHz.
// Por dentro, as frequencias ficam em "decimos de kHz" (dkHz) para caber o 12,5.
const uint32_t PMR_INICIO_DKHZ = 4460063;   // 446.006,3 kHz (erro de 0,05 kHz, irrelevante)
const uint16_t PMR_PASSO_DKHZ  = 125;       // 12,5 kHz
const uint8_t  PMR_CANAIS      = 16;

bool modoPMR = INICIAR_EM_PMR446;

struct Registro {
  uint32_t freqKHz;      // frequencia (kHz) do pico mais forte
  uint16_t vezes;        // em quantas varreduras apareceu
  int8_t   pico;         // RSSI mais forte ja visto (dBm)
  int8_t   ultimo;       // RSSI da ultima vez
  uint32_t vistoMs;      // millis() da ultima vez
  uint16_t varredura;    // numero da varredura em que foi visto por ultimo
};
Registro hist[MAX_HIST];
uint8_t nHist = 0;

float    ruido = -100;          // ruido medio da varredura anterior (dBm)
bool     temRuido = false;      // a primeira varredura so mede o ruido
uint16_t numVarredura = 0;
uint32_t duracaoVarreduraMs = 0;
uint8_t  ativosAgora = 0;
uint32_t ultimoNovoKHz = 0;
int8_t   ultimoNovoRssi = 0;
uint32_t ultimoNovoMs = 0;

uint8_t  pagina = 0;
bool     telaLigada = true;
uint32_t ultimaAtividadeMs = 0;
bool     redesenhar = true;

// ---------------- MOTOR (sem travar) ----------------
uint32_t motorAte = 0;

void vibrar(uint16_t ms) {
  digitalWrite(PINO_MOTOR, HIGH);
  motorAte = millis() + ms;
  if (motorAte == 0) motorAte = 1;
}

void atualizaMotor() {
  if (motorAte && (int32_t)(millis() - motorAte) >= 0) {
    digitalWrite(PINO_MOTOR, LOW);
    motorAte = 0;
  }
}

// ---------------- TELA LIGA/DESLIGA ----------------
void ligaTela() {
  if (!telaLigada) { tela.ssd1306_command(SSD1306_DISPLAYON); telaLigada = true; }
  ultimaAtividadeMs = millis();
  redesenhar = true;
}

void verificaApagarTela() {
  if (TELA_APAGA_SEG && telaLigada && millis() - ultimaAtividadeMs > (uint32_t)TELA_APAGA_SEG * 1000UL) {
    tela.ssd1306_command(SSD1306_DISPLAYOFF);
    telaLigada = false;
  }
}

// ---------------- BOTAO ----------------
bool botaoEstavel = false, botaoBruto = false, ignorarSoltura = false;
uint32_t tBotaoMudou = 0, tApertou = 0;
uint8_t avisoSegurar = 0;   // 0 nada, 1 "solte: zera", 2 "solte: modo"

void zerarPartida() {
  nHist = 0;
  numVarredura = 0;
  ativosAgora = 0;
  ultimoNovoKHz = 0;
  pagina = 0;
  vibrar(150);
}

void alternarModo() {
  modoPMR = !modoPMR;
  temRuido = false;           // o ruido muda com a faixa: mede de novo
  pagina = 0;
  vibrar(150);
}

uint8_t totalPaginas();

void lerBotao() {
  uint32_t agora = millis();
  bool b = digitalRead(PINO_BOTAO) == LOW;
  if (b != botaoBruto) { botaoBruto = b; tBotaoMudou = agora; }
  if (agora - tBotaoMudou < 30 || b == botaoEstavel) {
    // segurando: avisa o que vai acontecer ao soltar
    if (botaoEstavel && !ignorarSoltura) {
      uint8_t a = (agora - tApertou >= 5000) ? 2 : (agora - tApertou >= 2000 ? 1 : 0);
      if (a != avisoSegurar) { avisoSegurar = a; redesenhar = true; }
    }
    return;
  }
  botaoEstavel = b;
  if (b) {                                   // apertou
    tApertou = agora;
    ignorarSoltura = !telaLigada;            // com a tela apagada, o 1o clique so acorda
    ligaTela();
  } else {                                   // soltou
    uint32_t dur = agora - tApertou;
    avisoSegurar = 0;
    if (!ignorarSoltura) {
      if (dur >= 5000)      alternarModo();
      else if (dur >= 2000) zerarPartida();
      else                  pagina = (pagina + 1) % totalPaginas();
    }
    ignorarSoltura = false;
    ligaTela();
  }
}

// ---------------- MINHAS FREQUENCIAS ----------------
bool ehMinha(uint32_t khz) {
  for (uint8_t i = 0; i < sizeof(MINHAS_FREQS_KHZ) / sizeof(MINHAS_FREQS_KHZ[0]); i++) {
    uint32_t m = MINHAS_FREQS_KHZ[i];
    uint32_t d = (khz > m) ? khz - m : m - khz;
    if (d <= TOLERANCIA_MINHA_KHZ) return true;
  }
  return false;
}

// ---------------- HISTORICO ----------------
void registrar(uint32_t khz, int8_t rssi) {
  if (ehMinha(khz)) return;
  uint32_t agora = millis();
  ativosAgora++;

  for (uint8_t i = 0; i < nHist; i++) {
    uint32_t d = (khz > hist[i].freqKHz) ? khz - hist[i].freqKHz : hist[i].freqKHz - khz;
    if (d > AGRUPAR_KHZ) continue;
    Registro &r = hist[i];
    if (r.varredura == numVarredura) {       // ja contou nesta varredura: so atualiza o pico
      if (rssi > r.ultimo) { r.ultimo = rssi; if (rssi > r.pico) { r.pico = rssi; r.freqKHz = khz; } }
      ativosAgora--;
      return;
    }
    bool reativou = (agora - r.vistoMs) > (uint32_t)REATIVAR_SEG * 1000UL;
    r.vezes++;
    r.ultimo = rssi;
    r.vistoMs = agora;
    r.varredura = numVarredura;
    if (rssi > r.pico) { r.pico = rssi; r.freqKHz = khz; }
    if (reativou) alerta(khz, rssi);
    return;
  }

  // frequencia nova: se o historico estiver cheio, troca a menos vista (e mais antiga)
  uint8_t pos = nHist;
  if (nHist >= MAX_HIST) {
    pos = 0;
    for (uint8_t i = 1; i < nHist; i++) {
      if (hist[i].vezes < hist[pos].vezes ||
          (hist[i].vezes == hist[pos].vezes && hist[i].vistoMs < hist[pos].vistoMs)) pos = i;
    }
  } else nHist++;
  hist[pos] = { khz, 1, rssi, rssi, agora, numVarredura };
  alerta(khz, rssi);
}

void alerta(uint32_t khz, int8_t rssi) {
  int16_t r = constrain(rssi, RSSI_FRACO, RSSI_FORTE);
  vibrar(map(r, RSSI_FRACO, RSSI_FORTE, VIBRA_MIN_MS, VIBRA_MAX_MS));
  ultimoNovoKHz = khz;
  ultimoNovoRssi = rssi;
  ultimoNovoMs = millis();
  if (ACORDA_NO_ALERTA) { pagina = 0; ligaTela(); }
  redesenhar = true;
}

// ---------------- LEITURA DO CC1101 (so recepcao) ----------------
int8_t lerRssi(uint32_t dkhz) {          // frequencia em decimos de kHz
  ELECHOUSE_cc1101.SpiStrobe(CC1101_SIDLE);
  ELECHOUSE_cc1101.setMHZ(dkhz / 10000.0);
  ELECHOUSE_cc1101.SpiStrobe(CC1101_SRX);  // entra em RECEPCAO (recalibra sozinho)
  delayMicroseconds(RSSI_ESPERA_US);
  return (int8_t)constrain(ELECHOUSE_cc1101.getRssi(), -128, 0);
}

uint16_t totalCanais() {
  return modoPMR ? PMR_CANAIS : (FAIXA_FIM_KHZ - FAIXA_INICIO_KHZ) / PASSO_KHZ + 1;
}

uint32_t canalParaDKHz(uint16_t i) {
  return modoPMR ? PMR_INICIO_DKHZ + (uint32_t)i * PMR_PASSO_DKHZ
                 : (FAIXA_INICIO_KHZ + (uint32_t)i * PASSO_KHZ) * 10UL;
}

// tarefas que nao podem parar durante a varredura
void manutencao() {
  lerBotao();
  atualizaMotor();
  verificaApagarTela();
  if (redesenhar && telaLigada) desenhar();
}

// Uma varredura completa. Usa uma janela de 5 leituras para achar
// so o PICO de cada sinal (um radio aparece em 2 ou 3 passos vizinhos).
void varrer() {
  uint32_t inicio = millis();
  uint16_t n = totalCanais();
  int8_t   jR[5];
  uint32_t jF[5];
  for (uint8_t k = 0; k < 5; k++) { jR[k] = -128; jF[k] = 0; }

  float limite = ruido + LIMIAR_DB;
  float corteRuido = ruido + LIMIAR_DB / 2.0;   // leituras abaixo disso entram na media do ruido
  long somaRuido = 0, somaTudo = 0;
  uint16_t nRuido = 0;

  numVarredura++;
  ativosAgora = 0;

  for (uint16_t i = 0; i < n + 2; i++) {        // +2 para avaliar os 2 ultimos canais
    int8_t r = -128;
    uint32_t f = 0;
    if (i < n) {
      f = canalParaDKHz(i);
      r = lerRssi(f);
      somaTudo += r;
      if (!temRuido || r < corteRuido) { somaRuido += r; nRuido++; }
    }
    for (uint8_t k = 0; k < 4; k++) { jR[k] = jR[k + 1]; jF[k] = jF[k + 1]; }
    jR[4] = r; jF[4] = f;

    // o do meio (jR[2]) e um pico?
    if (temRuido && jF[2] && jR[2] > limite &&
        jR[2] > jR[1] && jR[2] >= jR[0] && jR[2] >= jR[3] && jR[2] >= jR[4]) {
      registrar((jF[2] + 5) / 10, jR[2]);
    }
    manutencao();
  }

  ruido = nRuido ? (float)somaRuido / nRuido : (float)somaTudo / n;
  temRuido = true;
  duracaoVarreduraMs = millis() - inicio;
  redesenhar = true;
}

// ---------------- BATERIA ----------------
int bateriaPct() {
  if (!USAR_BATERIA) return -1;
#if defined(ESP32)
  uint32_t mv = analogReadMilliVolts(PINO_BATERIA) * 2;   // divisor 100k/100k
  return constrain(map(mv, 3300, 4150, 0, 100), 0, 100);
#else
  return -1;
#endif
}

// ---------------- DESENHO ----------------
const uint8_t POR_PAGINA = 6;

uint8_t totalPaginas() {
  return 1 + (nHist + POR_PAGINA - 1) / POR_PAGINA;
}

void escreveFreq(uint32_t khz) {
  tela.print(khz / 1000);
  tela.print('.');
  uint16_t r = khz % 1000;
  if (r < 100) tela.print('0');
  if (r < 10)  tela.print('0');
  tela.print(r);
}

void escreveIdade(uint32_t ms) {
  uint32_t s = (millis() - ms) / 1000;
  if (s < 60) { tela.print(s); tela.print('s'); }
  else if (s < 3600) { tela.print(s / 60); tela.print('m'); }
  else { tela.print(s / 3600); tela.print('h'); }
}

void desenhar() {
  redesenhar = false;
  tela.clearDisplay();
  tela.setTextSize(1);
  tela.setTextColor(SSD1306_WHITE);
  tela.setCursor(0, 0);

  if (avisoSegurar) {
    tela.setTextSize(2);
    tela.setCursor(0, 8);
    tela.println(F("SOLTE:"));
    tela.println(avisoSegurar == 1 ? F("ZERA") : F("TROCA"));
    tela.println(avisoSegurar == 1 ? F("PARTIDA") : F("MODO"));
    tela.display();
    return;
  }

  if (pagina == 0) {
    // ---- pagina de status ----
    tela.print(modoPMR ? F("PMR446 16CH") : F("UHF 400-464"));
    int b = bateriaPct();
    if (b >= 0) { tela.setCursor(98, 0); tela.print(b); tela.print('%'); }
    tela.setCursor(0, 10);
    tela.print(F("Ruido ")); tela.print((int)ruido); tela.print(F(" dBm"));
    tela.setCursor(0, 20);
    tela.print(F("Varr. ")); tela.print(duracaoVarreduraMs / 1000.0, 1); tela.print(F("s #")); tela.print(numVarredura);
    tela.setCursor(0, 30);
    tela.print(F("Ativas agora: ")); tela.print(ativosAgora);
    tela.setCursor(0, 42);
    if (ultimoNovoKHz) {
      tela.print(F("NOVO "));
      escreveFreq(ultimoNovoKHz);
      tela.setCursor(0, 52);
      tela.print(ultimoNovoRssi); tela.print(F("dBm  ha "));
      escreveIdade(ultimoNovoMs);
    } else if (!temRuido) {
      tela.print(F("medindo ruido..."));
    } else {
      tela.print(F("nenhum sinal ainda"));
    }
  } else {
    // ---- ranking: mais vistas primeiro ----
    uint8_t ordem[MAX_HIST];
    for (uint8_t i = 0; i < nHist; i++) ordem[i] = i;
    for (uint8_t i = 1; i < nHist; i++) {            // ordenacao simples
      uint8_t x = ordem[i]; int8_t j = i - 1;
      while (j >= 0 && hist[ordem[j]].vezes < hist[x].vezes) { ordem[j + 1] = ordem[j]; j--; }
      ordem[j + 1] = x;
    }
    tela.print(F("RANKING ")); tela.print(pagina); tela.print('/'); tela.print(totalPaginas() - 1);
    tela.setCursor(80, 0); tela.print(F("x  pico"));
    uint8_t ini = (pagina - 1) * POR_PAGINA;
    for (uint8_t k = 0; k < POR_PAGINA && ini + k < nHist; k++) {
      Registro &r = hist[ordem[ini + k]];
      tela.setCursor(0, 10 + k * 9);
      tela.print(r.varredura == numVarredura ? '*' : ' ');   // * = ativa agora
      escreveFreq(r.freqKHz);
      tela.setCursor(50, 10 + k * 9); tela.print('x'); tela.print(r.vezes);
      tela.setCursor(78, 10 + k * 9); tela.print(r.pico);
      tela.setCursor(104, 10 + k * 9); escreveIdade(r.vistoMs);
    }
  }
  tela.display();
}

// ---------------- SETUP E LOOP ----------------
void setup() {
  pinMode(PINO_MOTOR, OUTPUT);
  digitalWrite(PINO_MOTOR, LOW);
  pinMode(PINO_BOTAO, INPUT_PULLUP);

#if defined(ESP32)
  WiFi.mode(WIFI_OFF);          // economia: nada de Wi-Fi nem Bluetooth
  btStop();
  setCpuFrequencyMhz(80);
  Wire.begin(PINO_SDA, PINO_SCL);
#else
  Wire.begin();
#endif

  tela.begin(SSD1306_SWITCHCAPVCC, OLED_ENDERECO);
  tela.ssd1306_command(SSD1306_SETCONTRAST);
  tela.ssd1306_command(BRILHO_TELA);
  tela.clearDisplay();
  tela.setTextSize(1);
  tela.setTextColor(SSD1306_WHITE);
  tela.setCursor(0, 0);
  tela.println(F("BLACK BIRD"));
  tela.println(F("SCANNER UHF"));
  tela.println(F("somente recepcao"));
  tela.display();

#if defined(ESP32)
  ELECHOUSE_cc1101.setSpiPin(PINO_SCK, PINO_MISO, PINO_MOSI, PINO_CSN);
#endif
  ELECHOUSE_cc1101.setGDO0(PINO_GDO0);
  if (!ELECHOUSE_cc1101.getCC1101()) {
    tela.setCursor(0, 40);
    tela.println(F("CC1101 NAO RESPONDE"));
    tela.println(F("confira a fiacao"));
    tela.display();
    while (true) delay(1000);
  }
  ELECHOUSE_cc1101.Init();
  ELECHOUSE_cc1101.setRxBW(BANDA_RX_KHZ);
  ELECHOUSE_cc1101.setMHZ(433.92);
  ELECHOUSE_cc1101.SetRx();      // modo recepcao

  vibrar(100);
  delay(1200);
  ultimaAtividadeMs = millis();
}

void loop() {
  varrer();
}
