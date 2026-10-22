# Cyberdeck BLACK BIRD — militar + DedSec | Projeto 13

Computador de campo numa maleta impressa em 3D: **Raspberry Pi 4**, **monitor de 15,6″ Full HD** na tampa e mini teclado,
rodando os jogos em Python num **menu de missões** com abertura em glitch estilo DedSec.
O visual é de painel militar (preto + coyote, alavancas com capa, nomes em estêncil) com o
toque hacker do neon magenta/ciano.

Prévia visual com o **simulador da partida**, a arquitetura e os custos: [PREVIA.html](PREVIA.html)

## Ligar: sequência de partida de caça

| # | Controle | O que acontece |
|---|---|---|
| 1 | **BAT** (alavanca com capa) | a aviônica (ESP32-C3) acorda e faz o auto-teste — display `bAt` |
| 2 | **MASTER ARM** (alavanca com capa) | `Arn` |
| 3 | **APU** (amarelo) | APU gira até 100% em 3 s (`A100`) |
| 4 | **ENG 1** (azul) | motor 1 até 60% |
| 5 | **ENG 2** (verde) | motor 2 até 60% — `thr` |
| 6 | **MANETE** para MIL | `PUSH`, o START pisca |
| 7 | **START** (vermelho, segurar 1 s) | o relé liga o Pi — `boot` → ` on ` e o menu abre |

Fora de ordem = `Abrt` (alarme, neon vermelho): desligue o MASTER ARM e recomece.
A alavanca **NEON** liga/desliga a fita de LED a qualquer hora.

**Desligar (sequência inversa):** MANETE em IDLE → MASTER ARM desligado (o Pi desliga
sozinho, depois o relé corta a energia: `SH25` … `OFF`) → BAT desligada.

## Arquitetura

```
 [18650 + módulo 5 V] ──► [ESP32-C3 "aviônica"] ── I2C ──► [MCP23017] ◄── 7 controles do painel
                              │  │  │  │                        └──► ULN2003 ──► LEDs dos 4 arcade
                              │  │  │  └── TM1637 (display 4 dígitos)
                              │  │  └───── fita WS2812 (neon DedSec)
                              │  └──────── buzzer
                              └── relé ──┐            serial (GPIO20/21 ↔ GPIO14/15)
 [power bank 20.000 mAh 65 W] ─ 5 V (2x) ►┴──► [RASPBERRY PI 4] ──► monitor 15,6″ (mini HDMI) · mini teclado
                                          └──► energia do monitor (o mesmo relé)
```

## Arquivos

| Arquivo | Onde | O que faz |
|---|---|---|
| `PARTIDA/PARTIDA.ino` | ESP32-C3 | partida, desligar, display, neon, relé, ABORT, ponte painel ↔ Pi |
| `pi/painel_servico.py` | Pi (serviço) | avisa "PRONTO", desligamento seguro, repassa botões e comandos |
| `pi/painel.py` | Pi (biblioteca) | `eventos()`, `led()`, `beep()`, `neon()`, `display()` para os jogos |
| `pi/menu.py` | Pi | abertura glitch + "SELEÇÃO DE MISSÃO" com tudo em `pi/jogos/` |
| `pi/jogos/teste_painel.py` | Pi | teste de cada controle |
| `pi/instalar.sh` | Pi | instala pygame/pyserial, liga a serial, serviço e menu automático |
| `3D/` | impressora | maleta em quartos, painel novo, manete, trilhos neon, suporte do display |

Bibliotecas da ESP32-C3: *Adafruit MCP23017 Arduino Library*, *TM1637* (Avishay Orpaz), *Adafruit NeoPixel*.

## Fases

| # | Fase | Situação |
|---|---|---|
| 1 | Visão geral do cyberdeck (partida de caça, 2 placas, militar + DedSec) | ✅ feita |
| 2 | Aviônica na bancada (`PARTIDA.ino` com o painel na protoboard) | ✅ código pronto |
| 3 | Preparação do Pi (`instalar.sh`, serial, desligamento seguro) | ✅ código pronto |
| 4 | Testes de hardware (`teste_painel.py`) | ✅ código pronto |
| 5 | Menu de missões (`menu.py`) | ✅ código pronto |
| 6 | Os 5 jogos de hackeamento (ctOS adaptado + 4) usando `painel.py` | próxima |
| 7 | Impressão e montagem | pendente |
| 8 | Checklist de campo | pendente |

## Os jogos de hackeamento (fase 6)

Continuam planejados, agora como missões do menu: **Terminal ctOS** (o seu jogo atual,
`GRANADA GAMES/WATCH DOGS/PROGRAMA DATA CENTER/hack_datacenter.py`), **Senha com tempo**,
**Desarme em sequência**, **Dominação** e **Quebra de firewall**. Cada um vira um `.py` em
`pi/jogos/` com `# NOME:` e `# DESCRICAO:` no começo, usando o `painel.py` para os botões,
LEDs, neon e display. No ctOS, troca só a detecção do pendrive (no Pi ele aparece em
`/media/<usuário>/CHAVE_DE_ACESSO`) e o som (vira o buzzer do painel).

> Os códigos não foram testados neste PC (sem Arduino e sem pygame); os `.py` passaram na
> conferência de sintaxe.
