/*
  ==========================================================
   ALVO ACIONADOR - BLACK BIRD · PROJETO 09 · o ALVO (no campo)
  ==========================================================
   Placa: ESP32-C3 SuperMini (Ferramentas > Placa > "ESP32C3 Dev Module",
          USB CDC On Boot = Enabled). Pacote "esp32" da Espressif 3.x.
   Sem biblioteca extra. Grave o MESMO código em todos os alvos.

   O que faz:
   - Dorme (deep sleep, gasta quase nada) esperando a BB. O disco piezo atrás
     da placa-alvo acorda a placa pelo pino 3.
   - Acertou: manda o aviso "ACENDE por X segundos" para o acionador da
     lâmpada (ESP-NOW, o mesmo rádio dos outros aparelhos BLACK BIRD) e
     depois fica ESPERA_MIN minutos sem efeito (dorme sem ouvir o piezo).
   - O tempo X é escolhido nas chaves T1 e T2 da lateral:
       T1 desl., T2 desl. = 30 s   ·  T1 lig., T2 desl. = 1 min
       T1 desl., T2 lig.  = 2 min  ·  T1 lig., T2 lig.  = 3 min
   - LED vermelho: piscadinha a cada 4 s = PRONTO (ajuda a achar o alvo no
     escuro) · apagado = em espera · 3 piscadas ao ligar · piscadas rápidas
     = bateria fraca (o alvo para de funcionar até trocar/carregar).

   Pinos (na SuperMini aparece só o número):
     3 = piezo (acorda)  ·  0 = chave T1  ·  1 = chave T2  ·  7 = LED vermelho
     4 = bateria (divisor 1 MΩ + 1 MΩ)
  ==========================================================
*/

#include <WiFi.h>
#include <esp_now.h>
#include <esp_wifi.h>
#include <esp_sleep.h>

#if ESP_ARDUINO_VERSION_MAJOR < 3
#error "Atualize o pacote esp32 para a versao 3.x (Ferramentas > Placa > Gerenciador de Placas > esp32)"
#endif

// ================= CONFIGURAÇÃO =================
const uint8_t  PINO_PIEZO   = 3;
const uint8_t  PINO_T1      = 0;
const uint8_t  PINO_T2      = 1;
const uint8_t  PINO_LED     = 7;
const uint8_t  PINO_BATERIA = 4;
const uint32_t ESPERA_MIN   = 5;        // minutos sem efeito depois de acionar
const uint32_t PISCA_S      = 4;        // de quantos em quantos segundos o LED "pronto" pisca (0 = não pisca)
const uint16_t TEMPOS_S[4]  = { 30, 60, 120, 180 };
const float    BATERIA_MIN  = 3.30;     // abaixo disso o alvo para (protege a bateria)
const uint8_t  CANAL        = 1;        // igual no acionador
const bool     LONGO_ALCANCE = true;    // igual no acionador
const uint8_t  REPETICOES   = 6;        // manda o aviso 6 vezes (se uma se perder, as outras chegam)

// ============ MENSAGEM (igual em todos os aparelhos BLACK BIRD) ============
enum Tipo : uint8_t { ALVO_ACERTO = 50 };
struct __attribute__((packed)) Msg {
  uint8_t  magico; uint8_t tipo; uint8_t origem; uint8_t destino;
  uint16_t equipe; uint16_t seq; int16_t azimute; uint16_t distancia; uint8_t extra;
};
// No alvo: distancia = segundos que a lâmpada fica acesa · extra = bateria (%) · seq = número do acerto
const uint8_t TODOS[6] = {0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF};

// ================= ESTADO (sobrevive ao deep sleep) =================
enum Estado : uint8_t { PRONTO = 0, ESPERA = 1, SEM_BATERIA = 2 };
RTC_DATA_ATTR uint8_t  estado = PRONTO;
RTC_DATA_ATTR uint16_t acertos = 0;
RTC_DATA_ATTR uint16_t piscadas = 0;

// ================= AUXILIARES =================
void piscar(uint8_t vezes, uint16_t aceso, uint16_t apagado) {
  for (uint8_t i = 0; i < vezes; i++) { digitalWrite(PINO_LED, HIGH); delay(aceso); digitalWrite(PINO_LED, LOW); if (i + 1 < vezes) delay(apagado); }
}

float lerBateria() {
  analogReadResolution(12);
  uint32_t mv = 0;
  for (uint8_t i = 0; i < 8; i++) mv += analogReadMilliVolts(PINO_BATERIA);
  return mv / 8.0f * 2.0f / 1000.0f;     // divisor 1M + 1M: a bateria é o dobro do que o pino lê
}
uint8_t porcento(float v) { int p = (int)((v - 3.3f) / (4.15f - 3.3f) * 100); return p < 0 ? 0 : p > 100 ? 100 : p; }

uint16_t tempoEscolhido() {
  pinMode(PINO_T1, INPUT_PULLUP); pinMode(PINO_T2, INPUT_PULLUP);
  delay(2);
  uint8_t i = (digitalRead(PINO_T1) == LOW ? 1 : 0) + (digitalRead(PINO_T2) == LOW ? 2 : 0);   // chave ligada = pino no GND
  pinMode(PINO_T1, INPUT); pinMode(PINO_T2, INPUT);   // sem pull-up enquanto dorme (não gasta bateria)
  return TEMPOS_S[i];
}

void mandarAcerto(uint16_t segundos, uint8_t bateria) {
  WiFi.mode(WIFI_STA);
  esp_wifi_set_channel(CANAL, WIFI_SECOND_CHAN_NONE);
  if (LONGO_ALCANCE) esp_wifi_set_protocol(WIFI_IF_STA, WIFI_PROTOCOL_LR);
  esp_wifi_set_max_tx_power(80);
  if (esp_now_init() != ESP_OK) return;
  esp_now_peer_info_t peer = {};
  memcpy(peer.peer_addr, TODOS, 6);
  peer.channel = CANAL; peer.ifidx = WIFI_IF_STA; peer.encrypt = false;
  esp_now_add_peer(&peer);
  uint8_t mac[6]; WiFi.macAddress(mac);
  Msg m = {};
  m.magico = 0xBB; m.tipo = ALVO_ACERTO; m.origem = mac[5]; m.destino = 0xFF;
  m.seq = ++acertos; m.distancia = segundos; m.extra = bateria;
  for (uint8_t i = 0; i < REPETICOES; i++) { esp_now_send(TODOS, (uint8_t *)&m, sizeof(m)); delay(40 + random(0, 30)); }
  esp_now_deinit();
  WiFi.mode(WIFI_OFF);
}

// ================= DORMIR =================
void dormirPronto() {
  // acorda quando o piezo der o pulso (pino 3 em HIGH) ou para piscar o LED
  esp_deep_sleep_enable_gpio_wakeup(1ULL << PINO_PIEZO, ESP_GPIO_WAKEUP_GPIO_HIGH);
  if (PISCA_S) esp_sleep_enable_timer_wakeup((uint64_t)PISCA_S * 1000000ULL);
  esp_deep_sleep_start();
}
void dormirEspera() {
  // não ouve o piezo: só acorda depois dos minutos de espera
  esp_sleep_enable_timer_wakeup((uint64_t)ESPERA_MIN * 60ULL * 1000000ULL);
  esp_deep_sleep_start();
}
void dormirParaSempre() { esp_deep_sleep_start(); }     // só volta desligando e ligando a chave LIGA

// ================= PROGRAMA =================
void setup() {
  pinMode(PINO_LED, OUTPUT); digitalWrite(PINO_LED, LOW);
  pinMode(PINO_PIEZO, INPUT);                 // o resistor de 1 MΩ da placa segura o pino em LOW
  esp_sleep_wakeup_cause_t motivo = esp_sleep_get_wakeup_cause();

  if (motivo != ESP_SLEEP_WAKEUP_GPIO && motivo != ESP_SLEEP_WAKEUP_TIMER) {
    // acabou de ligar (chave LIGA ou bateria nova)
    Serial.begin(115200); delay(300);
    estado = PRONTO; piscadas = 0;
    float v = lerBateria();
    Serial.printf("Alvo ligado. Bateria %.2f V. Tempo escolhido: %u s. Espera: %lu min.\n", v, tempoEscolhido(), (unsigned long)ESPERA_MIN);
    if (v < BATERIA_MIN) { estado = SEM_BATERIA; piscar(10, 40, 80); dormirParaSempre(); }
    piscar(3, 150, 150);
    delay(1500);                              // tempo para tirar a mão da placa
    dormirPronto();
  }

  if (estado == SEM_BATERIA) dormirParaSempre();

  if (motivo == ESP_SLEEP_WAKEUP_GPIO && estado == PRONTO) {
    // ACERTOU!
    digitalWrite(PINO_LED, HIGH);
    float v = lerBateria();
    if (v < BATERIA_MIN) { estado = SEM_BATERIA; piscar(10, 40, 80); dormirParaSempre(); }
    mandarAcerto(tempoEscolhido(), porcento(v));
    digitalWrite(PINO_LED, LOW);
    estado = ESPERA;
    dormirEspera();
  }

  if (motivo == ESP_SLEEP_WAKEUP_TIMER) {
    if (estado == ESPERA) { estado = PRONTO; piscar(2, 60, 120); }   // a espera acabou
    else {
      piscar(1, 15, 0);                                                // piscadinha de "pronto"
      if (++piscadas >= 150) {                                         // a cada ~10 min confere a bateria
        piscadas = 0;
        if (lerBateria() < BATERIA_MIN) { estado = SEM_BATERIA; piscar(10, 40, 80); dormirParaSempre(); }
      }
    }
  }
  dormirPronto();
}

void loop() {}   // nunca chega aqui: a placa sempre volta a dormir no setup
