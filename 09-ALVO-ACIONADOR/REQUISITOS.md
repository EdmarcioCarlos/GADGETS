# 09 · Alvo Acionador de Lâmpada — Requisitos

BLACK BIRD | GAMES · projeto 09 · intermediário · versão de 21/10/2026

## Para que serve

Alvos espalhados pelo campo para os **jogos noturnos**. O time precisa **acertar a placa** com a BB; quando acerta,
**um refletor/lâmpada da rede elétrica (127 V) perto dali acende** por um tempo e clareia a área. Depois disso o alvo
fica **5 minutos sem efeito** antes de poder acionar de novo.

Cada conjunto tem 2 aparelhos:

| Aparelho | Onde fica | Energia |
|---|---|---|
| **Alvo** | no campo, preso num poste ou árvore com velcro | 1 bateria 18650 (carrega por USB-C) |
| **Acionador** | perto do refletor (até ~30 m do alvo), na parede ou no poste | rede de **127 V** (cabo com plugue de tomada) |

## O que ele TEM que fazer

| # | Requisito | Como o projeto atende |
|---|---|---|
| R1 | Sentir a BB batendo na placa-alvo | Disco piezo de 27 mm atrás da placa, apertado por espuma |
| R2 | Acender a lâmpada do acionador quando o **seu** alvo é acertado | Aviso sem fio (ESP-NOW) + **pareamento**: cada acionador só obedece aos alvos pareados com ele (até 4) |
| R3 | Lâmpada acesa por um tempo **X ajustável** | 2 chaves no alvo: 30 s, 1 min, 2 min ou 3 min |
| R4 | **5 min de espera** depois de cada acionamento (vale para o alvo) | O alvo dorme 5 min sem ouvir o piezo (`ESPERA_MIN` no código) |
| R5 | Achar o alvo no escuro | LED vermelho fraco pisca a cada 4 s quando está pronto + faixa de fita fotoluminescente em volta da placa |
| R6 | Aguentar a noite inteira (e vários jogos) | O alvo dorme (deep sleep): a bateria dura semanas; o acionador fica na tomada |
| R7 | Aguentar tiro de BB e chuva fraca | PETG, paredes de 3 mm, entradas de cabo e de carga viradas para baixo |
| R8 | Ser **seguro com 127 V** | Ver "Segurança" abaixo |
| R9 | Funcionar com o refletor externo que o campo já tem | O refletor liga na saída do acionador (fase pelo relé, neutro e terra direto) |

## Segurança (rede de 127 V)

- O acionador é uma **caixa fechada**: a tampa vai com **4 parafusos** (precisa de chave) e tem o aviso gravado.
- **Divisória** separa a parte de 127 V (fonte, relé, conectores, fusível) da parte de baixa tensão (ESP32, LED, botão).
- **Fusível de 2 A** na fase da entrada.
- Fios da rede só em **conectores de alavanca** (tipo Wago) e nos bornes do relé e da fonte: nada de emenda com fita.
- Cabos entram e saem por **prensa-cabos PG7** no fundo (seguram o cabo se alguém puxar e barram a água).
- **Terra** do refletor ligado direto no terra da tomada (se o refletor tiver o fio verde/amarelo).
- **Regras de uso:** só abra o acionador **fora da tomada**. Grave o código pelo USB **só com a caixa fora da tomada**.
  Se não tiver segurança para ligar os fios da rede, peça para um eletricista ligar a primeira vez (é rápido:
  5 fios em conectores).

## O que ele NÃO faz (de propósito)

- Não avisa a organização nem os tablets (só acende a lâmpada). Dá para acrescentar depois: o aviso do alvo já usa a
  mesma mensagem dos outros aparelhos BLACK BIRD.
- Não comanda lâmpada de interruptor de parede (isso exigiria abrir a instalação do prédio).
- Não conta pontos.

## Lista de compras

Por **conjunto** (1 alvo + 1 acionador). Preços de out/2026, estimados: ≈ R$ 217–369 o 1º conjunto (comprando os kits) e ≈ R$ 118–181 cada um a mais; 6 conjuntos ≈ R$ 807–1.274 (detalhes na prévia, seção 07).

### Alvo
- 1 ESP32-C3 SuperMini (kit de 5)
- 1 bateria 18650 + 1 suporte de 1 × 18650
- 1 TP4056 USB-C (kit de 10)
- 1 disco piezo 27 mm (kit de 10) + 1 disco de espuma EVA de 10 mm
- 3 chaves alavanca MTS-102 (LIGA, T1, T2) (kit de 10)
- 1 LED vermelho 3 mm + resistor 330 Ω
- Piezo: 1 diodo 1N4148, 1 resistor 1 MΩ, 1 capacitor 100 nF, 1 resistor 10 kΩ
- Bateria: 2 resistores 1 MΩ (divisor)
- 1 placa ilhada (cortada em 5 × 6 cm)
- ≈ 35 cm de fita fotoluminescente 10 mm
- ≈ 1,2 m de velcro 25 mm (2 fitas)
- 4 M3 × 12 + 4 porcas (placa-alvo) · 2 M3 × 10 (trava do piezo) · 2 M3 × 8 (suporte da bateria) · 4 M3 × 10 (tampa) · 2 M2 × 6 (placa ilhada)

### Acionador
- 1 ESP32-C3 SuperMini
- 1 fonte **HLK-PM01** 5 V 3 W (de preferência já montada numa plaquinha com bornes)
- 1 módulo **relé 1 canal 5 V com jumper H/L** (10 A 250 V)
- 1 porta-fusível de linha (5 × 20 mm) + fusível **2 A**
- 2 conectores de alavanca de 3 vias (neutro e terra)
- 2 prensa-cabos **PG7**
- 1 cabo de força 3 × 1,0 mm² com plugue de tomada (≈ 1,5 m) — a ENTRADA
- O cabo do seu refletor — a SAÍDA
- 1 LED verde 3 mm + resistor 330 Ω · 1 botão 6 × 6 (+ capa impressa)
- 1 placa ilhada pequena
- 4 M3 × 10 (tampa) · 6 M3 × 8 (relé e fonte) · 2 M2 × 6 (placa) · 2 parafusos de 4 mm + buchas (parede)

### Ferramentas
Ferro de solda, alicate de corte e de desencapar, chave Allen 2,5 mm, multímetro, computador com o Arduino IDE.

## Antes de levar para o campo (testes)

1. **Acionador na bancada, SEM a rede:** alimente pelo USB do PC. O LED pisca 2× (sem alvo pareado). Clique no
   botão: o relé estala por 3 s.
2. **Alvo na bancada:** ligue a chave LIGA: 3 piscadas. Bata com o dedo/caneta na placa: o relé do acionador estala.
3. **Pareamento:** segure o botão do acionador 3 s (LED pisca rápido) e bata no alvo. Pronto.
4. **Espera:** bata de novo no alvo: nada acontece por 5 min (o LED do alvo fica apagado).
5. **Rede, com a caixa fechada:** ligue o refletor na saída, feche a tampa e só então ponha na tomada. Clique no botão
   (teste de 3 s).
6. **No campo:** atire de 10, 20 e 30 m e veja se a BB sempre aciona. Se não acionar de longe, o piezo está pouco
   apertado (espuma mais grossa) ou troque o capacitor de 100 nF por um de 47 nF (mais sensível). Se acionar sozinho com vento ou batida no
   poste, faça o contrário: capacitor de 220 nF (menos sensível).
