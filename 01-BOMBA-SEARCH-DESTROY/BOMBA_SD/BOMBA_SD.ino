/*
  ==========================================================
   BOMBA SEARCH & DESTROY - BLACK BIRD | PROJETO 01
  ==========================================================
   Placa: Arduino Uno R3 (do kit iniciante)

   3 modos de jogo:
     A) CODIGO  - ataque arma digitando a senha de armar;
                  defesa desarma digitando a senha de desarmar.
     B) SEGURAR - segura o botao grande X s para armar e Y s
                  para desarmar (estilo CS). Soltou, perdeu.
     C) FIOS    - segura o botao para armar; a defesa precisa
                  puxar o fio certo entre 4. Fio errado = penalidade.

   Codigo errado / fio errado: tira tempo da bomba (penalidade)
   e conta 1 erro. Chegou no limite de erros, explode.

   Bibliotecas (Ferramentas > Gerenciar bibliotecas):
     - "LiquidCrystal I2C" de Frank de Brabander
     - "Keypad" de Mark Stanley e Alexander Brevig

   Teclas no menu:
     A/B/C = escolhe o modo   D = configuracoes   # = inicia
   Durante a configuracao:
     numeros = digita   * = apaga   # = confirma (vazio mantem)
     A = gera senha aleatoria (so nas telas de senha)
  ==========================================================
*/

#include <Wire.h>
#include <LiquidCrystal_I2C.h>
#include <Keypad.h>
#include <EEPROM.h>

// ---------------- PINOS ----------------
const byte PIN_BUZZER = 10;   // buzzer ativo do kit (+ no pino, - no GND)
const byte PIN_RELE   = 11;   // IN do modulo rele -> liga a sirene
const byte PIN_BOTAO  = 12;   // botao arcade 30 mm (outro terminal no GND)
const byte PIN_LED    = 13;   // LED vermelho (com resistor) -> GND
const byte PIN_FIO[4] = {A0, A1, A2, A3};  // bornes banana dos 4 fios

// A maioria dos modulos rele de 1 canal liga com nivel BAIXO.
// Se a sirene ficar ligada direto ao ligar a bomba, troque para false.
const bool RELE_ATIVO_EM_LOW = true;

// ---------------- AJUSTES DE SOM ----------------
const byte SIRENE_EXPLOSAO_SEG = 15;  // quanto tempo a sirene toca na explosao
const byte SIRENE_ULTIMOS_SEG  = 30;  // nos ultimos X s, cada bip tambem da um toque curto na sirene (0 = desliga)

// Nome de cada fio (cor do cabo que vai no borne A0, A1, A2, A3)
const char* COR_FIO[4] = {"VERMELHO", "AZUL", "AMARELO", "VERDE"};

// ---------------- TECLADO E TELA ----------------
char teclas[4][4] = {
  {'1', '2', '3', 'A'},
  {'4', '5', '6', 'B'},
  {'7', '8', '9', 'C'},
  {'*', '0', '#', 'D'}
};
byte pinosLinhas[4]  = {9, 8, 7, 6};   // pinos 1-4 do teclado
byte pinosColunas[4] = {5, 4, 3, 2};   // pinos 5-8 do teclado
Keypad teclado = Keypad(makeKeymap(teclas), pinosLinhas, pinosColunas, 4, 4);

// Endereco comum do LCD I2C e 0x27. Se a tela ficar em branco, tente 0x3F.
LiquidCrystal_I2C lcd(0x27, 16, 2);

// ---------------- CONFIGURACAO (salva na EEPROM) ----------------
const byte CFG_VERSAO = 1;
const char* NOME_MODO[3] = {"CODIGO", "SEGURAR", "FIOS"};

struct Config {
  byte versao;
  byte modo;              // 0 codigo, 1 segurar, 2 fios
  uint16_t bombaSeg;      // tempo ate explodir depois de armada
  byte rodadaMin;         // tempo para o ataque armar (0 = sem limite)
  byte armarSeg;          // segurar o botao para armar
  byte desarmarSeg;       // segurar o botao para desarmar
  char senhaArmar[9];     // 4 a 8 digitos
  char senhaDesarmar[9];
  byte fioCerto;          // 0 = sorteia a cada rodada, 1-4 = fixo
  byte penalidadeSeg;     // tempo tirado a cada erro
  byte maxErros;          // erros para explodir (0 = sem limite)
};
Config cfg;

void configPadrao() {
  cfg.versao = CFG_VERSAO;
  cfg.modo = 0;
  cfg.bombaSeg = 300;
  cfg.rodadaMin = 0;
  cfg.armarSeg = 5;
  cfg.desarmarSeg = 10;
  strcpy(cfg.senhaArmar, "1234");
  strcpy(cfg.senhaDesarmar, "4321");
  cfg.fioCerto = 0;
  cfg.penalidadeSeg = 60;
  cfg.maxErros = 3;
}

// ---------------- ESTADO DO JOGO ----------------
enum Estado { PRONTO, ARMANDO, ARMADA, DESARMANDO, EXPLODIU, DESARMADA, TEMPO_ESGOTADO };
Estado estado;

unsigned long tFim;          // momento (millis) em que a bomba explode
unsigned long tRodadaFim;    // fim do tempo para armar
unsigned long tSegurarIni;   // inicio do aperto do botao
unsigned long tProxBip;
unsigned long tFimJogo;      // quando a rodada terminou (tela final)
long restanteFinal;          // tempo que sobrou ao desarmar
char digitado[9];
byte nDig;
byte erros;
byte fioSorteado;            // 0-3

// mensagem temporaria na linha de baixo
char msgTxt[17];
unsigned long msgAte = 0;

// ---------------- SOM E LED (sem travar o programa) ----------------
unsigned long tBuzzerOff = 0, tReleOff = 0;
bool ledFixo = false;

void rele(bool ligado) {
  digitalWrite(PIN_RELE, (ligado ^ RELE_ATIVO_EM_LOW) ? HIGH : LOW);
}

void bip(unsigned int ms) {
  digitalWrite(PIN_BUZZER, HIGH);
  digitalWrite(PIN_LED, HIGH);
  tBuzzerOff = millis() + ms;
}

void sirene(unsigned long ms) {
  rele(true);
  tReleOff = millis() + ms;
}

void atualizaSom() {
  unsigned long agora = millis();
  if (tBuzzerOff && (long)(agora - tBuzzerOff) >= 0) {
    digitalWrite(PIN_BUZZER, LOW);
    if (!ledFixo) digitalWrite(PIN_LED, LOW);
    tBuzzerOff = 0;
  }
  if (tReleOff && (long)(agora - tReleOff) >= 0) {
    rele(false);
    tReleOff = 0;
  }
}

void silencio() {
  digitalWrite(PIN_BUZZER, LOW);
  rele(false);
  tBuzzerOff = tReleOff = 0;
  ledFixo = false;
  digitalWrite(PIN_LED, LOW);
}

// ---------------- BOTAO E FIOS (com filtro de ruido) ----------------
bool botaoApertado = false, botaoBruto = false;
unsigned long tBotaoMudou = 0;

bool fioLigado[4], fioBruto[4], fioPuxou[4];
unsigned long tFioMudou[4];

void lerEntradas() {
  unsigned long agora = millis();
  bool b = digitalRead(PIN_BOTAO) == LOW;
  if (b != botaoBruto) { botaoBruto = b; tBotaoMudou = agora; }
  if (agora - tBotaoMudou > 30) botaoApertado = botaoBruto;

  for (byte i = 0; i < 4; i++) {
    bool f = digitalRead(PIN_FIO[i]) == LOW;   // LOW = fio encaixado (fecha com o GND)
    if (f != fioBruto[i]) { fioBruto[i] = f; tFioMudou[i] = agora; }
    if (agora - tFioMudou[i] > 50 && fioLigado[i] != fioBruto[i]) {
      if (fioLigado[i] && !fioBruto[i]) fioPuxou[i] = true;  // acabou de ser puxado
      fioLigado[i] = fioBruto[i];
    }
  }
}

bool todosFiosLigados() {
  for (byte i = 0; i < 4; i++) if (!fioLigado[i]) return false;
  return true;
}

// ---------------- TELA ----------------
void linha(byte r, const char* t) {
  lcd.setCursor(0, r);
  byte i = 0;
  for (; t[i] && i < 16; i++) lcd.print(t[i]);
  for (; i < 16; i++) lcd.print(' ');
}

void mostraMsg(const char* t, unsigned int ms = 1500) {
  strncpy(msgTxt, t, 16);
  msgTxt[16] = 0;
  msgAte = millis() + ms;
}

// "mm:ss", arredondando para cima
void fmtTempo(char* out, long ms) {
  if (ms < 0) ms = 0;
  long s = (ms + 999) / 1000;
  sprintf(out, "%02d:%02d", (int)(s / 60), (int)(s % 60));
}

void barra(char* out, unsigned long feito, unsigned long total) {
  byte n = (feito >= total) ? 16 : (byte)(feito * 16 / total);
  for (byte i = 0; i < 16; i++) out[i] = (i < n) ? (char)255 : '-';
  out[16] = 0;
}

long restante() {
  return (long)(tFim - millis());
}

// ---------------- MENU E CONFIGURACAO (pode travar, o jogo esta parado) ----------------
long pedirNumero(const char* titulo, long atual, long minimo, long maximo) {
  char buf[7] = "";
  byte n = 0;
  while (true) {
    lcd.clear();
    linha(0, titulo);
    lcd.setCursor(0, 1);
    if (n == 0) { lcd.print("atual: "); lcd.print(atual); }
    else lcd.print(buf);
    char k = teclado.waitForKey();
    if (k >= '0' && k <= '9' && n < 6) { buf[n++] = k; buf[n] = 0; }
    else if (k == '*' && n > 0) buf[--n] = 0;
    else if (k == '#') {
      if (n == 0) return atual;
      long v = atol(buf);
      if (v >= minimo && v <= maximo) return v;
      lcd.clear();
      linha(0, "FORA DO LIMITE");
      lcd.setCursor(0, 1);
      lcd.print(minimo); lcd.print(" a "); lcd.print(maximo);
      delay(1500);
      n = 0; buf[0] = 0;
    }
  }
}

void pedirSenha(const char* titulo, char* destino) {
  char buf[9] = "";
  byte n = 0;
  while (true) {
    lcd.clear();
    linha(0, titulo);
    lcd.setCursor(0, 1);
    if (n == 0) { lcd.print("atual: "); lcd.print(destino); }
    else lcd.print(buf);
    char k = teclado.waitForKey();
    if (k >= '0' && k <= '9' && n < 8) { buf[n++] = k; buf[n] = 0; }
    else if (k == '*' && n > 0) buf[--n] = 0;
    else if (k == 'A') {              // senha aleatoria de 4 digitos
      randomSeed(micros());
      for (n = 0; n < 4; n++) buf[n] = '0' + random(10);
      buf[n] = 0;
    }
    else if (k == '#') {
      if (n == 0) return;
      if (n >= 4) { strcpy(destino, buf); return; }
      lcd.clear();
      linha(0, "MINIMO 4 DIGITOS");
      delay(1500);
    }
  }
}

void configurar() {
  cfg.bombaSeg      = pedirNumero("Bomba (segundos)", cfg.bombaSeg, 10, 5999);
  cfg.rodadaMin     = pedirNumero("Armar ate(min)0=", cfg.rodadaMin, 0, 99);
  cfg.armarSeg      = pedirNumero("Segurar armar(s)", cfg.armarSeg, 1, 60);
  cfg.desarmarSeg   = pedirNumero("Segurar desarm s", cfg.desarmarSeg, 1, 60);
  pedirSenha("Senha ARMAR  A=?", cfg.senhaArmar);
  pedirSenha("Senha DESARM A=?", cfg.senhaDesarmar);
  cfg.fioCerto      = pedirNumero("Fio certo 0=sort", cfg.fioCerto, 0, 4);
  cfg.penalidadeSeg = pedirNumero("Penalidade (s)", cfg.penalidadeSeg, 0, 250);
  cfg.maxErros      = pedirNumero("Erros p/ explod.", cfg.maxErros, 0, 9);
  EEPROM.put(0, cfg);
  lcd.clear();
  linha(0, "CONFIG SALVA");
  delay(1000);
}

void menu() {
  silencio();
  while (true) {
    lcd.clear();
    linha(0, "MODO A/B/C D=CFG");
    char l2[17];
    snprintf(l2, 17, ">%-9s #=OK", NOME_MODO[cfg.modo]);
    linha(1, l2);
    char k = teclado.waitForKey();
    if (k >= 'A' && k <= 'C') {
      cfg.modo = k - 'A';
      EEPROM.put(0, cfg);
      bip(30);
    }
    else if (k == 'D') configurar();
    else if (k == '#') break;
  }
  iniciarRodada();
}

// ---------------- RODADA ----------------
void limparDigitado() { nDig = 0; digitado[0] = 0; }

void iniciarRodada() {
  silencio();
  randomSeed(micros());
  limparDigitado();
  erros = 0;
  for (byte i = 0; i < 4; i++) fioPuxou[i] = false;
  estado = PRONTO;
  tRodadaFim = millis() + (unsigned long)cfg.rodadaMin * 60000UL;
  lcd.clear();
  bip(150);
}

void armar() {
  estado = ARMADA;
  tFim = millis() + (unsigned long)cfg.bombaSeg * 1000UL;
  tProxBip = millis();
  limparDigitado();
  erros = 0;
  fioSorteado = cfg.fioCerto ? cfg.fioCerto - 1 : random(4);
  for (byte i = 0; i < 4; i++) fioPuxou[i] = false;
  sirene(400);                // toque curto: todo mundo ouve que foi plantada
  mostraMsg("BOMBA ARMADA!", 2000);
}

void explodir() {
  estado = EXPLODIU;
  tFimJogo = millis();
  ledFixo = true;
  digitalWrite(PIN_LED, HIGH);
  bip(3000);
  sirene((unsigned long)SIRENE_EXPLOSAO_SEG * 1000UL);
}

void desarmar() {
  restanteFinal = restante();
  estado = DESARMADA;
  tFimJogo = millis();
  silencio();
  // 3 toques curtos na sirene = desarmada
  for (byte i = 0; i < 3; i++) {
    rele(true);  delay(80);
    rele(false); delay(150);
  }
  bip(800);
}

void erro(const char* texto) {
  erros++;
  bip(600);
  if (cfg.maxErros && erros >= cfg.maxErros) { explodir(); return; }
  long pen = (long)cfg.penalidadeSeg * 1000L;
  if (restante() <= pen) { explodir(); return; }
  tFim -= pen;
  char m[17];
  snprintf(m, 17, "%s -%ds", texto, cfg.penalidadeSeg);
  mostraMsg(m, 2000);
}

// bip da contagem: acelera no final
void bipsContagem() {
  long r = restante();
  if ((long)(millis() - tProxBip) < 0) return;
  unsigned int intervalo = r > 30000 ? 1000 : (r > 10000 ? 500 : 250);
  tProxBip = millis() + intervalo;
  bip(40);
  if (SIRENE_ULTIMOS_SEG && r <= (long)SIRENE_ULTIMOS_SEG * 1000L) sirene(40);
}

// recebe digitos; devolve true quando apertam # (senha em "digitado")
bool lerSenha(char k) {
  if (k >= '0' && k <= '9' && nDig < 8) { digitado[nDig++] = k; digitado[nDig] = 0; bip(20); }
  else if (k == '*' && nDig > 0) { digitado[--nDig] = 0; }
  else if (k == '#' && nDig > 0) return true;
  return false;
}

// ---------------- CADA ESTADO ----------------
void tickPronto(char k) {
  if (cfg.rodadaMin && (long)(millis() - tRodadaFim) >= 0) {
    estado = TEMPO_ESGOTADO;
    tFimJogo = millis();
    sirene(1500);
    return;
  }
  if (k == '*' && nDig == 0) { menu(); return; }

  if (cfg.modo == 0) {
    if (lerSenha(k)) {
      if (strcmp(digitado, cfg.senhaArmar) == 0) armar();
      else { bip(500); mostraMsg("SENHA ERRADA"); limparDigitado(); }
    }
  } else if (botaoApertado) {
    if (cfg.modo == 2 && !todosFiosLigados()) { mostraMsg("LIGUE OS 4 FIOS"); return; }
    estado = ARMANDO;
    tSegurarIni = millis();
    tProxBip = millis();
  }
}

void tickArmando() {
  if (!botaoApertado) { estado = PRONTO; mostraMsg("ARMACAO CANCEL."); return; }
  if (millis() - tSegurarIni >= (unsigned long)cfg.armarSeg * 1000UL) { armar(); return; }
  if ((long)(millis() - tProxBip) >= 0) { tProxBip = millis() + 500; bip(20); }
}

void tickArmada(char k) {
  if (restante() <= 0) { explodir(); return; }
  bipsContagem();

  if (cfg.modo == 0) {
    if (lerSenha(k)) {
      if (strcmp(digitado, cfg.senhaDesarmar) == 0) { desarmar(); return; }
      limparDigitado();
      erro("SENHA ERRADA");
    }
  } else if (cfg.modo == 1) {
    if (botaoApertado) { estado = DESARMANDO; tSegurarIni = millis(); }
  } else {
    for (byte i = 0; i < 4; i++) {
      if (!fioPuxou[i]) continue;
      fioPuxou[i] = false;
      if (i == fioSorteado) { desarmar(); return; }
      erro("FIO ERRADO");
      if (estado != ARMADA) return;
    }
  }
}

void tickDesarmando() {
  if (restante() <= 0) { explodir(); return; }
  bipsContagem();
  if (!botaoApertado) { estado = ARMADA; mostraMsg("DESARME CANCEL."); return; }
  if (millis() - tSegurarIni >= (unsigned long)cfg.desarmarSeg * 1000UL) desarmar();
}

void tickFim(char k) {
  if (k == '#') iniciarRodada();
  else if (k == '*') menu();
}

// ---------------- DESENHO DA TELA ----------------
void desenhar() {
  char l1[17], l2[17], t[6];
  unsigned long agora = millis();
  bool alterna = ((agora - tFimJogo) / 2500) % 2;   // telas finais trocam a cada 2,5 s

  switch (estado) {
    case PRONTO:
    case ARMANDO:
      if (cfg.rodadaMin) {
        fmtTempo(t, (long)(tRodadaFim - agora));
        snprintf(l1, 17, "ARMAR ATE  %s", t);
      } else snprintf(l1, 17, "PRONTA %s", NOME_MODO[cfg.modo]);
      if (estado == ARMANDO) barra(l2, agora - tSegurarIni, (unsigned long)cfg.armarSeg * 1000UL);
      else if (cfg.modo == 0) snprintf(l2, 17, "Senha: %s", digitado);
      else if (cfg.modo == 2 && !todosFiosLigados()) strcpy(l2, "LIGUE OS 4 FIOS");
      else strcpy(l2, "SEGURE P/ ARMAR");
      break;

    case ARMADA:
    case DESARMANDO:
      fmtTempo(t, restante());
      snprintf(l1, 17, "ARMADA E%d %s", erros, t);
      if (estado == DESARMANDO) barra(l2, agora - tSegurarIni, (unsigned long)cfg.desarmarSeg * 1000UL);
      else if (cfg.modo == 0) snprintf(l2, 17, "Senha: %s", digitado);
      else if (cfg.modo == 1) strcpy(l2, "SEGURE P/DESARM.");
      else strcpy(l2, "PUXE O FIO CERTO");
      break;

    case EXPLODIU:
      strcpy(l1, "*** EXPLODIU ***");
      strcpy(l2, alterna ? "#=NOVA  *=MENU" : "ATAQUE VENCEU");
      break;

    case DESARMADA:
      fmtTempo(t, restanteFinal);
      snprintf(l1, 17, "DESARMADA  %s", t);
      strcpy(l2, alterna ? "#=NOVA  *=MENU" : "DEFESA VENCEU");
      break;

    case TEMPO_ESGOTADO:
      strcpy(l1, "TEMPO ESGOTADO");
      strcpy(l2, alterna ? "#=NOVA  *=MENU" : "DEFESA VENCEU");
      break;
  }

  if ((long)(msgAte - agora) > 0) strcpy(l2, msgTxt);
  linha(0, l1);
  linha(1, l2);
}

// ---------------- SETUP E LOOP ----------------
void setup() {
  rele(false);                       // garante a sirene desligada antes de virar saida
  pinMode(PIN_RELE, OUTPUT);
  rele(false);
  pinMode(PIN_BUZZER, OUTPUT);
  pinMode(PIN_LED, OUTPUT);
  pinMode(PIN_BOTAO, INPUT_PULLUP);
  for (byte i = 0; i < 4; i++) {
    pinMode(PIN_FIO[i], INPUT_PULLUP);
    fioLigado[i] = fioBruto[i] = digitalRead(PIN_FIO[i]) == LOW;
    fioPuxou[i] = false;
  }

  EEPROM.get(0, cfg);
  if (cfg.versao != CFG_VERSAO) { configPadrao(); EEPROM.put(0, cfg); }

  lcd.init();
  lcd.backlight();
  linha(0, "  BLACK  BIRD");
  linha(1, " SEARCH&DESTROY");
  bip(100);
  delay(1500);
  menu();
}

void loop() {
  static unsigned long tDesenho = 0;
  lerEntradas();
  atualizaSom();
  char k = teclado.getKey();

  switch (estado) {
    case PRONTO:     tickPronto(k);   break;
    case ARMANDO:    tickArmando();   break;
    case ARMADA:     tickArmada(k);   break;
    case DESARMANDO: tickDesarmando(); break;
    default:         tickFim(k);      break;
  }

  if (millis() - tDesenho >= 150) {
    tDesenho = millis();
    desenhar();
  }
}
