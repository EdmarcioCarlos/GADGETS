// =====================================================================
//  BLACK BIRD | DMR · PROJETO 14 · VISÃO NOTURNA CLIP-ON (1x, na frente da luneta)
//  Placa: ESP32-CAM (AI-Thinker) com câmera OV2640 SEM filtro infravermelho.
//  Tela: 1,3" IPS 240x240 ST7789 (7 pinos, sem CS) · Iluminador: 4 LEDs IR 5 mm 850 nm (MOSFET).
//
//  Arduino IDE: placa "AI Thinker ESP32-CAM", PSRAM "Enabled".
//  Biblioteca: LovyanGFX (Gerenciador de Bibliotecas). A configuração da tela já está aqui embaixo,
//  não precisa editar arquivo nenhum da biblioteca.
//  Gravar: encaixe a ESP32-CAM na base ESP32-CAM-MB e ligue no USB.
//
//  A câmera filma em tons de cinza; o código corta o meio da imagem do tamanho certo para dar 1x
//  (sem zoom) através da lente de 45 mm, aumenta o contraste e pinta de verde (ou branco/vermelho).
//
//  BOTÕES (em cima):
//   IR   clique: iluminador IR  desligado → baixo → médio → alto
//   TELA clique: brilho (5 níveis) · segurar 1 s: cor (verde · branco · vermelho)
//   Os 2 juntos por 3 s: AJUSTE (zerar). Ver CODIGO-LEIA-ME.txt
//  ATENÇÃO: não segure o botão IR enquanto liga (ele fica no GPIO 12, que a placa lê ao ligar).
// =====================================================================
#include "esp_camera.h"
#include <LovyanGFX.hpp>
#include <Preferences.h>

// ---------------- pinos ----------------
#define PINO_IR     1     // GPIO1 (TX): gate do MOSFET dos LEDs IR (por isso o Serial fica desligado)
#define PINO_FLASH  4     // LED branco da placa: fica SEMPRE apagado (denunciaria a posição)
#define BOTAO_IR    12
#define BOTAO_TELA  3     // GPIO3 (RX)
// tela ST7789: SCL 14 · SDA 13 · DC 2 · RES e BLK no 3V3

// câmera AI-Thinker
#define PWDN_GPIO_NUM 32
#define RESET_GPIO_NUM -1
#define XCLK_GPIO_NUM 0
#define SIOD_GPIO_NUM 26
#define SIOC_GPIO_NUM 27
#define Y9_GPIO_NUM 35
#define Y8_GPIO_NUM 34
#define Y7_GPIO_NUM 39
#define Y6_GPIO_NUM 36
#define Y5_GPIO_NUM 21
#define Y4_GPIO_NUM 19
#define Y3_GPIO_NUM 18
#define Y2_GPIO_NUM 5
#define VSYNC_GPIO_NUM 25
#define HREF_GPIO_NUM 23
#define PCLK_GPIO_NUM 22

// ---------------- ajustes ----------------
const int CAM_W = 480, CAM_H = 320;   // HVGA em tons de cinza
const int CORTE_PADRAO = 260;         // quantos pixels da câmera viram os 240 da tela (1x com lente de 66° e foco 45 mm)
const int CORTE_MIN = 160, CORTE_MAX = 320;
const uint8_t IR_NIVEIS[] = {0, 90, 170, 255};     // desligado, baixo, médio, alto
const float BRILHO[] = {0.12, 0.25, 0.45, 0.70, 1.0};

class LGFX : public lgfx::LGFX_Device {
  lgfx::Panel_ST7789 _panel;
  lgfx::Bus_SPI _bus;
public:
  LGFX() {
    { auto cfg = _bus.config();
      cfg.spi_host = SPI2_HOST;
      cfg.spi_mode = 3;                  // tela de 7 pinos (sem CS) precisa do modo 3
      cfg.freq_write = 40000000;
      cfg.freq_read = 16000000;
      cfg.spi_3wire = true;
      cfg.use_lock = true;
      cfg.dma_channel = SPI_DMA_CH_AUTO;
      cfg.pin_sclk = 14; cfg.pin_mosi = 13; cfg.pin_miso = -1; cfg.pin_dc = 2;
      _bus.config(cfg); _panel.setBus(&_bus); }
    { auto cfg = _panel.config();
      cfg.pin_cs = -1; cfg.pin_rst = -1; cfg.pin_busy = -1;
      cfg.panel_width = 240; cfg.panel_height = 240;
      cfg.offset_x = 0; cfg.offset_y = 0; cfg.offset_rotation = 0;
      cfg.readable = false; cfg.invert = true; cfg.rgb_order = false;
      cfg.dlen_16bit = false; cfg.bus_shared = false;
      _panel.config(cfg); }
    setPanel(&_panel);
  }
};

LGFX lcd;
Preferences prefs;

int nivelIR = 0, nivelBrilho = 2, cor = 0;          // cor: 0 verde, 1 branco, 2 vermelho
int corte = CORTE_PADRAO, desvioX = 0, desvioY = 0;  // ajuste de 1x e de "zero"
bool modoAjuste = false; int passoAjuste = 0;        // 0 = tamanho, 1 = horizontal, 2 = vertical
uint32_t mensagemAte = 0; char mensagem[24] = "";
lgfx::rgb565_t paleta[256];
static lgfx::rgb565_t linhas[240 * 16];

void avisar(const char* t) { strncpy(mensagem, t, sizeof(mensagem) - 1); mensagemAte = millis() + 1500; }

void aplicarIR() {
#if ESP_ARDUINO_VERSION_MAJOR >= 3
  ledcWrite(PINO_IR, IR_NIVEIS[nivelIR]);
#else
  ledcWrite(2, IR_NIVEIS[nivelIR]);
#endif
}

void salvar() {
  prefs.putInt("ir", nivelIR); prefs.putInt("br", nivelBrilho); prefs.putInt("cor", cor);
  prefs.putInt("corte", corte); prefs.putInt("dx", desvioX); prefs.putInt("dy", desvioY);
}

// monta a paleta (contraste automático: estica do mais escuro ao mais claro da cena)
void montarPaleta(uint8_t minimo, uint8_t maximo) {
  int faixa = max(24, maximo - minimo);
  float b = BRILHO[nivelBrilho];
  for (int v = 0; v < 256; v++) {
    float n = constrain((v - minimo) / (float)faixa, 0.0f, 1.0f);
    n = sqrtf(n) * b;                                   // clareia as sombras (gama) e aplica o brilho
    uint8_t k = (uint8_t)(n * 255);
    if (cor == 0) paleta[v].set(k / 5, k, k / 4);       // verde (fósforo P43)
    else if (cor == 1) paleta[v].set(k, k, (k * 9) / 10); // branco (fósforo branco)
    else paleta[v].set(k, 0, 0);                        // vermelho (preserva a visão noturna do olho)
  }
}

bool iniciarCamera() {
  camera_config_t c = {};
  c.ledc_channel = LEDC_CHANNEL_0; c.ledc_timer = LEDC_TIMER_0;
  c.pin_d0 = Y2_GPIO_NUM; c.pin_d1 = Y3_GPIO_NUM; c.pin_d2 = Y4_GPIO_NUM; c.pin_d3 = Y5_GPIO_NUM;
  c.pin_d4 = Y6_GPIO_NUM; c.pin_d5 = Y7_GPIO_NUM; c.pin_d6 = Y8_GPIO_NUM; c.pin_d7 = Y9_GPIO_NUM;
  c.pin_xclk = XCLK_GPIO_NUM; c.pin_pclk = PCLK_GPIO_NUM; c.pin_vsync = VSYNC_GPIO_NUM; c.pin_href = HREF_GPIO_NUM;
  c.pin_sccb_sda = SIOD_GPIO_NUM; c.pin_sccb_scl = SIOC_GPIO_NUM;
  c.pin_pwdn = PWDN_GPIO_NUM; c.pin_reset = RESET_GPIO_NUM;
  c.xclk_freq_hz = 20000000;
  c.pixel_format = PIXFORMAT_GRAYSCALE;
  c.frame_size = FRAMESIZE_HVGA;          // 480 x 320
  c.jpeg_quality = 12;
  c.fb_count = 2;
  c.fb_location = CAMERA_FB_IN_PSRAM;
  c.grab_mode = CAMERA_GRAB_LATEST;
  if (esp_camera_init(&c) != ESP_OK) return false;
  sensor_t* s = esp_camera_sensor_get();
  s->set_gain_ctrl(s, 1);                 // ganho automático
  s->set_gainceiling(s, GAINCEILING_128X);// deixa o ganho subir bastante no escuro
  s->set_exposure_ctrl(s, 1);
  s->set_aec2(s, 1);                      // exposição noturna (mais longa)
  s->set_ae_level(s, 2);
  s->set_bpc(s, 1); s->set_wpc(s, 1);     // corrige pixels mortos/brancos
  s->set_lenc(s, 1);
  return true;
}

// ---------------- botões (clique e segurar) ----------------
struct Botao { int pino; bool antes; uint32_t desde; bool longoFeito; };
Botao bIR = {BOTAO_IR, false, 0, false}, bTela = {BOTAO_TELA, false, 0, false};
uint32_t juntosDesde = 0;

// devolve 1 = clique, 2 = segurou 1 s
int lerBotao(Botao& b) {
  bool agora = digitalRead(b.pino) == LOW; int r = 0;
  if (agora && !b.antes) { b.desde = millis(); b.longoFeito = false; }
  if (agora && !b.longoFeito && millis() - b.desde > 1000) { b.longoFeito = true; r = 2; }
  if (!agora && b.antes && !b.longoFeito && millis() - b.desde > 30) r = 1;
  b.antes = agora; return r;
}

void tratarBotoes() {
  bool doisJuntos = digitalRead(BOTAO_IR) == LOW && digitalRead(BOTAO_TELA) == LOW;
  if (doisJuntos) {
    if (!juntosDesde) juntosDesde = millis();
    if (millis() - juntosDesde > 3000) {
      modoAjuste = !modoAjuste; passoAjuste = 0; juntosDesde = millis() + 100000;  // espera soltar
      if (!modoAjuste) { salvar(); avisar("AJUSTE SALVO"); } else avisar("AJUSTE: TAMANHO");
      bIR.longoFeito = bTela.longoFeito = true;
    }
    lerBotao(bIR); lerBotao(bTela); return;
  }
  juntosDesde = 0;
  int i = lerBotao(bIR), t = lerBotao(bTela);
  if (modoAjuste) {                       // IR = menos · TELA = mais · segurar TELA = próximo passo
    int d = (i == 1) ? -1 : (t == 1) ? 1 : 0;
    if (t == 2) { passoAjuste = (passoAjuste + 1) % 3; avisar(passoAjuste == 0 ? "AJUSTE: TAMANHO" : passoAjuste == 1 ? "AJUSTE: LADO" : "AJUSTE: ALTURA"); }
    if (d) {
      if (passoAjuste == 0) corte = constrain(corte - d * 4, CORTE_MIN, CORTE_MAX);   // menos corte = imagem maior
      else if (passoAjuste == 1) desvioX = constrain(desvioX + d * 2, -60, 60);
      else desvioY = constrain(desvioY + d * 2, -40, 40);
    }
    return;
  }
  if (i == 1) { nivelIR = (nivelIR + 1) % 4; aplicarIR(); salvar();
                avisar(nivelIR == 0 ? "IR DESLIGADO" : nivelIR == 1 ? "IR BAIXO" : nivelIR == 2 ? "IR MEDIO" : "IR ALTO"); }
  if (t == 1) { nivelBrilho = (nivelBrilho + 1) % 5; salvar(); avisar("BRILHO"); }
  if (t == 2) { cor = (cor + 1) % 3; salvar(); avisar(cor == 0 ? "VERDE" : cor == 1 ? "BRANCO" : "VERMELHO"); }
}

void setup() {
  pinMode(PINO_FLASH, OUTPUT); digitalWrite(PINO_FLASH, LOW);
  pinMode(BOTAO_IR, INPUT_PULLUP); pinMode(BOTAO_TELA, INPUT_PULLUP);
#if ESP_ARDUINO_VERSION_MAJOR >= 3
  ledcAttachChannel(PINO_IR, 20000, 8, 2);
#else
  ledcSetup(2, 20000, 8); ledcAttachPin(PINO_IR, 2);
#endif
  prefs.begin("visao", false);
  nivelIR = prefs.getInt("ir", 0); nivelBrilho = prefs.getInt("br", 2); cor = prefs.getInt("cor", 0);
  corte = prefs.getInt("corte", CORTE_PADRAO); desvioX = prefs.getInt("dx", 0); desvioY = prefs.getInt("dy", 0);
  aplicarIR();

  lcd.init(); lcd.setRotation(0); lcd.fillScreen(TFT_BLACK);
  lcd.setTextColor(lcd.color565(0, 120, 30)); lcd.setTextSize(2);
  if (!iniciarCamera()) { lcd.drawString("CAMERA?", 70, 110); while (true) delay(1000); }
  montarPaleta(0, 255);
}

void loop() {
  tratarBotoes();
  camera_fb_t* fb = esp_camera_fb_get();
  if (!fb) return;
  int x0 = constrain((int)(fb->width - corte) / 2 + desvioX, 0, (int)fb->width - corte);
  int y0 = constrain((int)(fb->height - corte) / 2 + desvioY, 0, (int)fb->height - corte);
  if (corte > (int)fb->height) { y0 = 0; }

  // contraste automático: amostra o pedaço que vai para a tela
  uint8_t mn = 255, mx = 0;
  for (int y = 0; y < corte && y0 + y < (int)fb->height; y += 8) {
    const uint8_t* lin = fb->buf + (y0 + y) * fb->width + x0;
    for (int x = 0; x < corte; x += 8) { uint8_t v = lin[x]; if (v < mn) mn = v; if (v > mx) mx = v; }
  }
  montarPaleta(mn, mx);

  // copia o pedaço do meio para a tela (240 x 240), 16 linhas por vez
  for (int bloco = 0; bloco < 240; bloco += 16) {
    for (int y = 0; y < 16; y++) {
      int sy = min(y0 + ((bloco + y) * corte) / 240, (int)fb->height - 1);
      const uint8_t* lin = fb->buf + sy * fb->width + x0;
      lgfx::rgb565_t* dst = linhas + y * 240;
      for (int x = 0; x < 240; x++) dst[x] = paleta[lin[(x * corte) / 240]];
    }
    lcd.pushImage(0, bloco, 240, 16, linhas);
  }
  esp_camera_fb_return(fb);

  // avisos rápidos e cruz de ajuste (a luneta tem o retículo dela; a cruz só aparece no AJUSTE)
  if (modoAjuste) {
    uint16_t c = lcd.color565(255, 60, 0);
    lcd.drawFastHLine(0, 120, 240, c); lcd.drawFastVLine(120, 0, 240, c);
  }
  if (millis() < mensagemAte) { lcd.setTextColor(lcd.color565(0, 160, 40), TFT_BLACK); lcd.drawString(mensagem, 6, 6); }
}
