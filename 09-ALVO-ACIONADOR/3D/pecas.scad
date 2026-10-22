// =====================================================================
//  09 - ALVO ACIONADOR DE LÂMPADA · peças 3D
//  Escolha a peça em PECA, F6 (render) e F7 (exportar STL). Medidas em mm.
//  ESTILO TÁTICO FACETADO · cores: caixas e trava do piezo em PRETO
//                                  placa-alvo, tampa do alvo (com a marca), tampa do acionador e capa do botão em COYOTE
//
//  COMO FUNCIONA: o ALVO fica no campo (poste/árvore, 2 fitas de velcro). A BB bate na placa coyote, o disco piezo
//  atrás dela sente e a ESP32-C3 acorda e manda um aviso sem fio. O ACIONADOR fica perto do refletor, ligado na
//  rede de 127 V: recebe o aviso e liga o refletor pelo relé pelo tempo escolhido no alvo.
//  Eixos (as 2 caixas): x = largura, y = 0 na FRENTE (y = Y encosta no poste/parede), z = 0 embaixo.
// =====================================================================
use <../../_BIBLIOTECA-3D/bb_lib.scad>
$fn = 48;

PECA = "caixa_alvo";   // caixa_alvo | tampa_alvo | alvo | trava_piezo | caixa_acionador | tampa_acionador | capa_botao

P = 3; C = 5; E = 4;

// ---------------- FIXAÇÃO NO POSTE (igual no powerbank 02 e no rádio 05) ----------------
TUNEL = [27.5, 4];
module fixacao_poste(x, y, zs) {
    for (zc = zs) translate([0, y - 0.01, zc - TUNEL[0]/2 - 3]) difference() {
        union() {
            translate([3, 0, 0]) cube([x - 6, TUNEL[1] + 3, TUNEL[0] + 6]);
            for (s = [-1, 1]) translate([x/2 + s * x * 0.2, TUNEL[1] + 3 - 0.01, 0])
                linear_extrude(TUNEL[0] + 6) polygon([[-3, 0], [3, 0], [1, 3], [-1, 3]]);
        }
        translate([-1, 0, 3]) cube([x + 2, TUNEL[1], TUNEL[0]]);
    }
}
function cantos(x, y) = [[6.2, 6.2], [x - 6.2, 6.2], [6.2, y - 6.2], [x - 6.2, y - 6.2]];   // pinos entram 0,3 mm nas paredes

// =====================================================================
//  ALVO (fica no campo, com 1 bateria 18650)
// =====================================================================
XA = 96; YA = 34; ZA = 104;
CANTOS_A = cantos(XA, YA);
ALVO = 88; ALVO_X0 = (XA - ALVO) / 2; ALVO_Z0 = 6; ALVO_E = 4;
ALVO_C = [XA/2, ALVO_Z0 + ALVO/2];                                   // centro (x, z) = onde fica o piezo
ALVO_FUROS = [for (sx = [-1, 1], sz = [-1, 1]) [ALVO_C[0] + sx * 36, ALVO_C[1] + sz * 36]];
PIEZO_D = 28;                                                        // janela do disco piezo de 27 mm
PIEZO_BOSS = [ALVO_C[0] - 24, ALVO_C[0] + 24];
SUP_A = [77, 21, 20];                                                // suporte de 1 x 18650 (deitado em cima) · CONFIRA
SUP_X0 = (XA - SUP_A[0]) / 2; SUP_Z0 = 75;
SUP_FUROS_X = [SUP_X0 + 6, SUP_X0 + SUP_A[0] - 6];                   // furos do suporte (confira no seu)
TP = [17.5, 28, 1.6]; TP_X = 78; TP_Y = 19;                          // TP4056 USB-C em pé, USB-C para baixo
LED_A = [XA/2, 98.5];                                                // LED vermelho "pronto"
CHAVES_A = [38, 50, 62];                                             // LIGA · T1 · T2 (lado direito)
PLACA_A = [50, 60]; PLACA_A_Z0 = 8;                                  // placa ilhada cortada (x · z), na parede de trás

module caixa_alvo() {
    difference() {
        union() {
            caixa_tatica(XA, YA, ZA, P, P, C) {
                for (c = CANTOS_A) translate([c[0], c[1], 0]) pino(ZA, 7, 2.6);
                for (f = ALVO_FUROS) translate([f[0], 0, f[1]]) rotate([-90, 0, 0]) cylinder(h = 10, d = 9);   // porcas do alvo
                for (x = PIEZO_BOSS) translate([x, 0, ALVO_C[1]]) rotate([-90, 0, 0]) cylinder(h = 12, d = 8); // trava do piezo
                for (x = SUP_FUROS_X) translate([x - 4, 0, SUP_Z0 - 4]) cube([8, YA, 4]);                    // 2 barras que seguram o suporte
                for (s = [-1, 1]) translate([s > 0 ? TP_X + TP[0]/2 - 2 : TP_X - TP[0]/2 - 2.5, TP_Y - 1.5, 0])   // guias do TP4056
                    cube([4.5, TP[2] + 3, P + TP[1]]);
                for (x = [XA/2 - 30 + 4, XA/2 + 20 - 4]) translate([x, YA - P - 4 + 0.01, PLACA_A_Z0 + 30]) rotate([-90, 0, 0]) cylinder(h = 4, d = 5);   // placa ilhada (M2)
            }
            fixacao_poste(XA, YA, [26, 78]);
            for (z = CHAVES_A) translate([XA - 0.01, 17, z]) rotate([0, 90, 0]) moldura_oct(12, 1.5);
            for (i = [0 : 2]) translate([XA + 0.6, 24.5, CHAVES_A[i]]) rotate([90, 0, 90]) linear_extrude(0.6)
                text(["LIGA", "T1", "T2"][i], size = 3, halign = "left", valign = "center", font = "Liberation Sans:style=Bold");
            translate([LED_A[0], 0.01, LED_A[1]]) rotate([90, 0, 0]) moldura_oct(7, 1);
            translate([0.01, YA - 7, 12]) rotate([90, 0, -90]) hex_relevo(YA - 14, ZA - 24, 1);
        }
        for (f = ALVO_FUROS) translate([f[0], -1, f[1]]) rotate([-90, 0, 0]) {
            cylinder(h = 12, d = 3.4);
            translate([0, 0, 1 + P + 3]) cylinder(h = 4, d = 6.6, $fn = 6);                                  // porca M3 por dentro
        }
        translate([ALVO_C[0], -1, ALVO_C[1]]) rotate([-90, 0, 0]) cylinder(h = P + 2, d = PIEZO_D);
        for (x = PIEZO_BOSS) translate([x, 4, ALVO_C[1]]) rotate([-90, 0, 0]) cylinder(h = 10, d = 2.6);
        for (x = SUP_FUROS_X) translate([x, YA/2, SUP_Z0 - 5]) cylinder(h = 6, d = 2.6);
        for (s = [-1, 1]) translate([s > 0 ? TP_X + TP[0]/2 - 2 - 0.01 : TP_X - TP[0]/2 - 0.4, TP_Y - 0.2, P])
            cube([2.41, TP[2] + 0.4, TP[1] + 1]);
        translate([TP_X - 5, TP_Y - 1, -1]) cube([10, 7, P + 2]);                                             // USB-C de carga por baixo
        for (x = [XA/2 - 30 + 4, XA/2 + 20 - 4]) translate([x, YA - P - 5, PLACA_A_Z0 + 30]) rotate([-90, 0, 0]) cylinder(h = 6, d = 1.7);
        translate([LED_A[0], -3, LED_A[1]]) rotate([-90, 0, 0]) cylinder(h = P + 6, d = 3.2);
        for (z = CHAVES_A) translate([XA - P - 1, 17, z]) rotate([0, 90, 0]) cylinder(h = P + 4, d = 6.3);
    }
}

// tampa do alvo (coyote) · MARCA DO PROJETO (única)
module tampa_alvo() {      // impressa com a face de fora na mesa; ao montar, o lado y = YA daqui fica na FRENTE
    difference() {
        tampa_tatica(XA, YA, E, P, 2.5, C, 1.2);
        for (c = CANTOS_A) translate([c[0], c[1], 0]) furo(3.4);
        emblema_baixo(XA - 20, YA/2, 0.8, 0.6, 180);
        translate([XA/2 - 6, YA/2, 0]) rotate([0, 0, 180]) logo_baixo(0, 0, 4.2, prof = 0.6);
        for (x = [14]) nervuras_baixo(x, YA - 13, 2, 3.6, 8, 0.6, 90);
    }
}

// placa-alvo (coyote): impressa com a frente na mesa; anéis gravados e faixa para a fita fotoluminescente
module alvo() {
    c = ALVO / 2;
    difference() {
        prisma_oct(ALVO, ALVO, ALVO_E, 10);
        translate([c, c, -0.01]) for (f = [56, 38, 20]) difference() { octogono(f, 0.81); translate([0, 0, -1]) octogono(f - 2.4, 3); }
        translate([c, c, -0.01]) cylinder(h = 0.81, d = 8);
        translate([0, 0, -0.01]) linear_extrude(0.61) difference() { offset(delta = -2) oct2d(ALVO, ALVO, 10); offset(delta = -12) oct2d(ALVO, ALVO, 10); }
        for (sx = [-1, 1], sy = [-1, 1]) translate([c + sx * 36, c + sy * 36, 0]) furo(3.4);
    }
}

// trava do piezo (preto): o disco do meio aperta a espuma contra o piezo, e o piezo contra as costas do alvo
module trava_piezo() {
    difference() {
        union() {
            hull() for (x = [-24, 24]) translate([x, 0, 0]) cylinder(h = 3, d = 10);
            translate([0, 0, 2.99]) cylinder(h = 5, d = 24);
        }
        for (x = [-24, 24]) translate([x, 0, 0]) furo(3.4);
        translate([0, 0, -1]) cylinder(h = 12, d = 4);
    }
}

// =====================================================================
//  ACIONADOR (perto do refletor, ligado na rede de 127 V)
//  Lado DIREITO (x > DIVISA): 127 V (fonte HLK-PM01, relé, conectores de alavanca, fusível).
//  Lado ESQUERDO: só 5 V e 3,3 V (ESP32-C3, LED, botão). A divisória separa os dois.
// =====================================================================
XB = 96; YB = 45; ZB = 110;
CANTOS_B = cantos(XB, YB);
DIVISA = 46;                                                        // parede que separa 127 V da parte de baixa tensão
RELE = [26, 50]; RELE_FUROS = [20, 44]; RELE_Z0 = 48;                // módulo relé 1 canal 5 V, EM PÉ (furos M3) · CONFIRA
HLK = [38, 26]; HLK_FUROS = [32, 20]; HLK_Z0 = 12;                   // módulo HLK-PM01 com bornes (furos M3) · CONFIRA
PRENSA = [[62, 15], [80, 15]];                                       // 2 prensa-cabos PG7 no fundo: ENTRADA (rede) e SAÍDA (refletor)
PRENSA_D = 12.6;
LED_B = [24, 92]; BOTAO_B = [24, 76];                                // LED de estado e botão PAREAR/TESTE (frente, lado baixa tensão)
PLACA_B = [34, 50]; PLACA_B_Z0 = 30;                                 // placa ilhada com a ESP32-C3 (parede de trás, lado esquerdo)
function furos4(cx, cz, f) = [for (sx = [-1, 1], sz = [-1, 1]) [cx + sx * f[0]/2, cz + sz * f[1]/2]];
RELE_C = [DIVISA + 2 + (XB - P - DIVISA - 2)/2, RELE_Z0 + RELE[1]/2];
HLK_C = [RELE_C[0], HLK_Z0 + HLK[1]/2];

module caixa_acionador() {
    difference() {
        union() {
            caixa_tatica(XB, YB, ZB, P, P, C) {
                for (c = CANTOS_B) translate([c[0], c[1], 0]) pino(ZB, 7, 2.6);
                translate([DIVISA, 0, 0]) cube([2, YB, ZB - 30]);                                               // divisória 127 V | baixa tensão
                for (f = concat(furos4(RELE_C[0], RELE_C[1], RELE_FUROS), furos4(HLK_C[0], HLK_C[1], HLK_FUROS)))
                    translate([f[0], YB - P - 6 + 0.01, f[1]]) rotate([-90, 0, 0]) cylinder(h = 6, d = 7);         // pinos do relé e da fonte
                for (x = [14, 42]) translate([x, YB - P - 5 + 0.01, PLACA_B_Z0 + PLACA_B[1]/2]) rotate([-90, 0, 0]) cylinder(h = 5, d = 5);
            }
            fixacao_poste(XB, YB, [30, 82]);
            for (s = [0, 1]) translate([s ? XB - 0.01 : -11.99, YB - 5, ZB/2 - 10]) difference() {               // orelhas para parafusar na parede
                cube([12, 5, 20]);
                translate([s ? 6.5 : 5.5, -1, 10]) rotate([-90, 0, 0]) cylinder(h = 7, d = 4.6);
            }
            translate([LED_B[0], 0.01, LED_B[1]]) rotate([90, 0, 0]) moldura_oct(8, 1);
            translate([BOTAO_B[0], 0.01, BOTAO_B[1]]) rotate([90, 0, 0]) moldura_oct(14, 1.5);
            translate([DIVISA + 6, 0.01, 30]) rotate([90, 0, 0]) linear_extrude(0.8) {                          // aviso em relevo, lado 127 V
                text("127 V", size = 9, font = "Liberation Sans:style=Bold");
                translate([0, -12]) text("NÃO ABRA LIGADO", size = 3.4, font = "Liberation Sans:style=Bold");
            }
            translate([6, 0.01, 8]) rotate([90, 0, 0]) hex_relevo(DIVISA - 12, 54, 1);
        }
        for (f = concat(furos4(RELE_C[0], RELE_C[1], RELE_FUROS), furos4(HLK_C[0], HLK_C[1], HLK_FUROS)))
            translate([f[0], YB - P - 7, f[1]]) rotate([-90, 0, 0]) cylinder(h = 7, d = 2.6);
        for (x = [14, 42]) translate([x, YB - P - 6, PLACA_B_Z0 + PLACA_B[1]/2]) rotate([-90, 0, 0]) cylinder(h = 6, d = 1.7);
        for (p = PRENSA) translate([p[0], p[1], -1]) cylinder(h = P + 2, d = PRENSA_D);
        translate([LED_B[0], -3, LED_B[1]]) rotate([-90, 0, 0]) cylinder(h = P + 6, d = 3.2);
        translate([BOTAO_B[0], -3, BOTAO_B[1]]) rotate([-90, 0, 0]) cylinder(h = P + 6, d = 9.4);                  // capa do botão 6x6
        translate([DIVISA - 0.5, YB - P - 14, ZB - 30 - 6]) cube([3, 10, 7]);                                      // passagem dos fios de 5 V (no alto)
    }
}

// tampa do acionador (coyote): 4 parafusos M3 (precisa de chave: ninguém abre sem querer) e aviso gravado
module tampa_acionador() {
    difference() {
        tampa_tatica(XB, YB, E, P, 2.5, C, 1.2);
        for (c = CANTOS_B) translate([c[0], c[1], 0]) furo(3.4);
        for (i = [0 : 2]) translate([XB/2, YB/2 + 9 - i * 8, 0]) rotate([0, 0, 180]) mirror([0, 0, 1]) mirror([1, 0, 0])
            translate([0, 0, -0.6]) linear_extrude(0.62)
                text(["ANTES DE ABRIR", "TIRE DA TOMADA", "127 V - PERIGO"][i]   /* a tampa vira ao montar: assim lê de cima para baixo */, size = 4, halign = "center", valign = "center", font = "Liberation Sans:style=Bold");
    }
}

if (PECA == "caixa_alvo") caixa_alvo();
if (PECA == "tampa_alvo") tampa_alvo();
if (PECA == "alvo") alvo();
if (PECA == "trava_piezo") trava_piezo();
if (PECA == "caixa_acionador") caixa_acionador();
if (PECA == "tampa_acionador") tampa_acionador();
if (PECA == "capa_botao") capa_botao(9, 0, 4);
