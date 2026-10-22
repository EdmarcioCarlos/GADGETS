# Scanner de Rádio UHF — BLACK BIRD | Projeto 11

Aparelho **somente de recepção** que varre a faixa UHF (400–464 MHz), mostra quais
frequências estão em uso por perto e vibra quando aparece um canal novo. Serve para
descobrir o canal do outro time e depois sintonizar nele num Baofeng ou num RTL-SDR.

> O CC1101 só **mede a força do sinal (RSSI)**. Ele acha o canal, mas não ouve voz.

Prévia visual com medidas, fiação e custos: [PREVIA.html](PREVIA.html)

---

## ⚠️ Aviso legal (leia antes)

- **Este projeto não transmite nada.** O firmware só coloca o CC1101 em modo de recepção.
  Não existe, e não deve ser adicionada, nenhuma função de transmissão.
- **Transmitir sem licença ou interferir em comunicações é proibido pela Anatel.**
  Bloqueador (jammer) é ilegal para particulares, inclusive em campo de airsoft.
- **Escutar o canal do outro time** pode ser proibido pela regra de alguns campos e
  eventos de airsoft, e escutar comunicações de terceiros fora do jogo pode ter
  restrições legais. Use só em jogos em que a organização permite, e combine isso
  antes da partida.

---

## Lista de peças

| Qtd | Peça | Observação |
|---|---|---|
| 1 | ESP32 DevKit V1 (30 pinos) | Placa principal, 3,3 V |
| 1 | Módulo CC1101 **433 MHz** com antena SMA | Cobre 387–464 MHz; ajustado para 433 MHz |
| 1 | OLED 0,96″ SSD1306 128×64 I2C (endereço 0x3C) | Tela |
| 1 | Motor de vibração tipo moeda 3 V (vibracall 1027) | Alerta silencioso |
| 1 | Transistor NPN BC547 | Liga o motor |
| 1 | Resistor 1 kΩ | Base do BC547 |
| 1 | Diodo 1N4148 | Roda livre do motor |
| 2 | Resistores 100 kΩ | Divisor para medir a bateria (opcional) |
| 1 | Botão tátil 6×6 | Páginas / zerar / modo |
| 1 | Módulo carregador 18650 com saída 5 V (boost) | Carrega pelo USB e entrega 5 V ao ESP32 |
| 1 | Bateria 18650 3,7 V | ~2600 mAh |
| — | Caixa impressa 3D (62 × 112 × 34 mm) + clipe MOLLE | Cabe num porta-rádio |

---

## Diagrama de ligação (texto)

```
 MÓDULO 18650 (boost)          ESP32 DevKit
   5V  ─────────────────────── VIN
   GND ─────────────────────── GND
   B+ (bateria) ── 100k ──┬─── GPIO34   (opcional: % da bateria)
                          └── 100k ── GND

 CC1101 433 MHz                ESP32
   VCC ─────────────────────── 3V3    (NUNCA 5 V)
   GND ─────────────────────── GND
   SCK ─────────────────────── GPIO18
   MISO (SO) ───────────────── GPIO19
   MOSI (SI) ───────────────── GPIO23
   CSN ─────────────────────── GPIO5
   GDO0 ────────────────────── GPIO2  (opcional)

 OLED SSD1306                  ESP32
   VCC ─────────────────────── 3V3
   GND ─────────────────────── GND
   SDA ─────────────────────── GPIO21
   SCL ─────────────────────── GPIO22

 MOTOR DE VIBRAÇÃO
   ESP32 3V3 ──┬──────────── motor (+)
               │
           1N4148 (faixa/catodo virada para o 3V3)
               │
   BC547 coletor ─┴───────── motor (−)
   BC547 base  ── 1k ─────── GPIO15
   BC547 emissor ─────────── GND

 BOTÃO
   GPIO4 ──── botão ──── GND   (usa o pull-up interno)
```

BC547 olhando a face reta, pernas para baixo: **C – B – E** (coletor, base, emissor).

### Fallback: Arduino Nano

| Função | Nano |
|---|---|
| CC1101 SCK / MISO / MOSI / CSN | D13 / D12 / D11 / D10 |
| CC1101 GDO0 | D2 |
| OLED SDA / SCL | A4 / A5 |
| Motor (base do BC547 via 1k) | D5 |
| Botão | D4 |

O Nano trabalha em **5 V** e o CC1101 **não aguenta 5 V** nos pinos:

- Alimente o CC1101 com um regulador de 3,3 V (ex.: módulo AMS1117-3.3), não no pino 3V3 do Nano.
- Coloque um divisor (1 kΩ em série + 2 kΩ para o GND) em **SCK, MOSI e CSN**. O MISO pode ir direto.
- No Nano o histórico guarda só 10 frequências (pouca memória) e não tem medição de bateria.

---

## Bibliotecas

Na Arduino IDE: *Ferramentas → Gerenciar bibliotecas* e instale:

1. **SmartRC-CC1101-Driver-Lib** (LSatan)
2. **Adafruit SSD1306** (Adafruit)
3. **Adafruit GFX Library** (Adafruit), que costuma ser instalada junto

## Upload

1. Instale o suporte ao ESP32: *Arquivo → Preferências → URLs adicionais* e adicione
   `https://espressif.github.io/arduino-esp32/package_esp32_index.json`. Depois, em
   *Ferramentas → Placa → Gerenciador de placas*, instale **esp32** (Espressif).
2. Abra `SCANER_RADIO/SCANER_RADIO.ino` (a pasta precisa ter o mesmo nome do arquivo).
3. *Ferramentas → Placa*: **ESP32 Dev Module**. Escolha a porta COM.
4. **Desligue a chave da bateria** e clique em *Carregar*. Se travar em "Connecting…",
   segure o botão **BOOT** da placa até começar a gravar.
5. Edite o bloco **CONFIGURAÇÃO** no topo do arquivo: a sua frequência
   (`MINHAS_FREQS_KHZ`), a faixa, o passo e o limiar.

---

## Como usar em campo

| Ação | Resultado |
|---|---|
| Ligar | A 1ª varredura só mede o ruído do local; a partir da 2ª começa a detectar |
| Vibração | Canal novo, ou um canal que estava parado há mais de 60 s e voltou. Quanto mais longa, mais forte o sinal (mais perto) |
| Clique curto | Próxima página: status → ranking 1 → ranking 2… (com a tela apagada, o clique só acende) |
| Segurar 2–5 s e soltar | Zera a partida (a tela avisa "SOLTE: ZERA PARTIDA") |
| Segurar 5 s+ e soltar | Alterna entre UHF completo e PMR446 rápido |

No ranking: `*` = transmitindo agora, `x12` = visto em 12 varreduras, `-62` = RSSI de
pico em dBm (quanto mais perto de 0, mais perto o rádio), e a idade da última detecção.

Depois de achar a frequência, sintonize nela no Baofeng ou no RTL-SDR **só para escutar**:
não aperte o PTT nessa frequência (transmitir no canal do outro time é interferência).

- **Modo UHF completo:** 2561 frequências, uma varredura a cada ~3 s. Pode perder
  um câmbio muito curto, mas pega quem fala mais.
- **Modo PMR446:** só os 16 canais PMR, varredura em ~0,05 s. É o que a maioria dos
  rádios de airsoft usa; pega até câmbio curto.

---

## Melhorias propostas

1. **Antena melhor:** a antena de mola que vem com o módulo é curta. Uma antena SMA
   de 433 MHz com ~17 cm (1/4 de onda) ou uma flexível de 5 dBi aumenta bastante o
   alcance de detecção. Não use antena de 2,4 GHz (Wi-Fi): é de outra faixa.
2. **Modo PMR446 rápido** (já incluído, segure o botão 5 s).
3. **Economia de bateria** (já incluído): Wi-Fi e Bluetooth desligados, CPU a 80 MHz,
   tela que apaga sozinha após 30 s e brilho baixo. Estimativa: 20 h ou mais com uma 18650.
4. **Lista de várias frequências próprias:** `MINHAS_FREQS_KHZ` aceita várias
   (squad, organização, canal de emergência).
5. **Direção do sinal:** com uma antena direcional pequena (Yagi de 433 MHz), girar o
   corpo e olhar o RSSI subir indica de que lado o rádio está.
6. **Registro em cartão SD:** gravar cada detecção com horário para analisar depois da partida.

---

## Problemas comuns

| Sintoma | O que fazer |
|---|---|
| "CC1101 NAO RESPONDE" | Confira SCK/MISO/MOSI/CSN e se o VCC está no 3V3 |
| Tela preta | Endereço do OLED (0x3C ou 0x3D) e os fios SDA/SCL |
| Vibra o tempo todo | Aumente `LIMIAR_DB` (ex.: 18 ou 20) ou afaste o scanner do seu próprio rádio |
| Nunca detecta nada | Teste com seu rádio transmitindo a 5 m, numa frequência que **não** está em `MINHAS_FREQS_KHZ` |
| Motor não vibra | Posição C-B-E do BC547 e o diodo (faixa para o 3V3) |
