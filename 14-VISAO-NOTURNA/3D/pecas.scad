// =====================================================================
//  14 - VISÃO NOTURNA CLIP-ON (1x, na frente da luneta) · peças 3D · versão COMPACTA
//  Escolha a peça em PECA, F6 (render) e F7 (exportar STL). Medidas em mm.
//  ESTILO TÁTICO FACETADO · cores: casco, base e suporte da tela em PRETO
//                                  tampa lateral (com a marca), capuz da lente, mandíbula e botões em COYOTE
//
//  COMO FUNCIONA: a câmera (sem filtro infravermelho) filma a frente, iluminada por 4 LEDs IR de 850 nm
//  embutidos na frente (invisíveis a olho nu). A imagem aparece na tela de 1,3". A lente de 25 mm (foco 45 mm)
//  fica a 45 mm da tela e "joga a tela para o infinito": a luneta enxerga a imagem nítida, do mesmo tamanho
//  do mundo real (1x, SEM ZOOM), e o zoom continua sendo o da luneta. Igual a um magnificador de holo,
//  a unidade vira para o lado esquerdo numa dobradiça e trava com clique (2 BBs de 6 mm com molinha).
//  Compacta: LiPo chata embaixo, ESP32-CAM em pé na frente, nada em cima (o laser do telêmetro passa livre).
//
//  Eixos (posição de uso): x = 0 atrás (virado para a luneta), x cresce para a frente (cano)
//  y = 0 eixo da luneta, y+ à direita · z = 0 topo do trilho Picatinny, z+ para cima
//  >>> CONFIRA: EIXO = altura do centro da luneta acima do trilho (Geissele alta = 49 mm). <<<
// =====================================================================
use <../../_BIBLIOTECA-3D/bb_lib.scad>
$fn = 48;

PECA = "casco";   // casco | tampa | capuz_lente | suporte_tela | base_flip | base_fixa | mandibula | capa_botao | pino_trava | ir_caixa | ir_tampa | tnut_mlok

// ---------- medidas principais ----------
EIXO = 49;                 // centro da luneta acima do trilho (CONFIRA)
L = 76;                    // comprimento do casco
Y_ESQ = -23; Y_DIR = 19;   // casco de -23 a 19; a tampa lateral vai de 19 a 23
E_TAMPA = 4;
ZB = 27; ZT = 74;          // fundo e topo do casco
C = 5;                     // chanfro dos cantos (corte em octógono)
P = 3;                     // parede

// ---------- óptica ----------
LENTE_D = 25;              // lente biconvexa (tipo Google Cardboard) 25 mm, foco 45 mm
LENTE_ABERTURA = 22;
LENTE_PROF = 2.4;          // rebaixo da lente na face de trás (por fora)
FOCO = 50;                 // posição da tela (x): 45 mm de foco + metade da lente; ajuste fino nos rasgos
TELA_PCB = [27.2, 33];     // placa da tela (largura y, altura z) · CONFIRA no seu módulo
TELA_Z0 = 36;              // a placa da tela apoia aqui (logo acima da LiPo)
CAM_Z = 61.5;              // centro da lente da câmera (ESP32-CAM em pé atrás da frente) · CONFIRA
ESP_X = 63;                // face de trás da placa ESP32-CAM
LEDS_Y = [-13.5, -4.5, 4.5, 13.5]; LEDS_Z = 40;   // 4 LEDs IR 5 mm, 850 nm, embaixo da câmera

// ---------- energia ----------
LIPO = [50, 34, 5.5];      // LiPo 503450 1000 mAh (x, y, z) · CONFIRA
LIPO_X = 11;

// ---------- dobradiça e base ----------
DOB_Y = Y_ESQ - 11; DOB_Z = 17;   // eixo da dobradiça (paralelo ao cano), à esquerda e embaixo do casco
DOB_R = 11;
DOB_X = [10, 20, 20.6, 49.4, 50, 60];   // articulação da base | orelha do casco | articulação da base
BB_R = 7.2;                // pino de trava (e a BB da outra articulação) a 7,2 mm do eixo
// TRAVA DE PINO (articulação de trás): pino Ø5,7 com mola de caneta entra num furo da orelha em pé (0°) e virado (90°).
// Para soltar: puxe para trás a cabeça do parafuso M3 x 12 que sai pela lateral esquerda, gire e solte: trava sozinho.
PINO_D = 5.7; PINO_L = 6.5; PINO_CURSO = 3; FURO_TRAVA = 2.6;   // furo na orelha: Ø6 x 2,6
BATENTE = [22, 48];        // batente da base (x) onde a unidade apoia em pé: o peso fica nele, não na trava
BASE_X0 = 10; BASE_X1 = 60; BASE_Y0 = DOB_Y - DOB_R; BASE_Y1 = 14; BASE_E = 5;
TRILHO_L = 21.2; GARRA_H = 6.4; GARRA_X = 25;   // Picatinny (igual ao anti-cant)

// botões, chave e USB (em cima)
BOTOES_X = [26, 38]; BOTOES_Y = 2;
CHAVE_X = 12; CHAVE_Y = 8;
USB_X = 20.5; USB_Y = -17.5;
TAMPA_FUROS = [[8, ZB + C + 5], [68, ZB + C + 5], [8, ZT - C - 5], [68, ZT - C - 5]];   // (x, z) dos M3 x 10

// =====================================================================
module secao2d(enc = 0) { translate([Y_ESQ, ZB]) offset(delta = -enc) oct2d(Y_DIR - Y_ESQ, ZT - ZB, C); }
module ao_longo(x0, x1) { translate([x0, 0, 0]) rotate([90, 0, 90]) linear_extrude(x1 - x0) children(); }  // 2D (y,z) -> ao longo de x
module em_x(x, y, z) { translate([x, y, z]) rotate([0, 90, 0]) children(); }   // cilindro ao longo de +x

// ---------- CASCO (preto) ----------
module casco_interno() {                      // reforços por dentro (aparados pela forma de fora)
    for (z = [EIXO - 19, EIXO + 19]) em_x(P - 0.01, 0, z) cylinder(h = 7, d = 7);          // parafusos do capuz
    // LiPo: batente atrás; na frente um ressalto com aba segura a ponta; o batente do suporte da tela segura o meio
    translate([LIPO_X - 1.6, Y_ESQ + P - 0.01, ZB + P - 0.01]) cube([1.6, Y_DIR - Y_ESQ - 2*P, 3]);
    translate([ESP_X - 1.5, -15, ZB + P - 0.01]) cube([1.3, 30, LIPO[2] + 1.8]);
    translate([ESP_X - 3.6, -15, ZB + P + LIPO[2] + 0.3]) cube([2.2, 30, 1.5]);
    for (z = [44, 60]) translate([FOCO, Y_ESQ + P - 0.01, z]) rotate([-90, 0, 0]) pino(2.5, 7, 2.6);          // pé da tela
    // guias da placa de carga (em pé na parede esquerda, USB-C para cima)
    for (x = [7, 34]) translate([x, Y_ESQ + P - 0.01, 37]) difference() {
        cube([2, 4.5, 31]); translate([x == 7 ? 1 : -0.01, 1, -1]) cube([1.01, 1.9, 33]);
    }
    // apoio de baixo da ESP32-CAM (com rasgo para a placa)
    translate([ESP_X - 1.5, Y_ESQ + P - 0.01, ZB + P - 0.01]) difference() {
        cube([4.8, Y_DIR - Y_ESQ - 2*P + 0.02, 3]); translate([1.4, -1, 1]) cube([1.8, 60, 3]);
    }
    for (y = [-10, 10]) translate([32, y, ZT - P + 0.01]) mirror([0, 0, 1]) pino(5, 6, 2.6);   // placa dos botões
}
module casco_externo() {
    // orelha da dobradiça (gira entre as 2 articulações da base)
    hull() {
        em_x(DOB_X[2], DOB_Y, DOB_Z) cylinder(h = DOB_X[3] - DOB_X[2], r = DOB_R);
        translate([DOB_X[2], Y_ESQ, ZB + C]) cube([DOB_X[3] - DOB_X[2], 0.5, 16]);
    }
    // frente: moldura facetada da câmera e "viseira" dos LEDs
    translate([L - 0.01, 0, CAM_Z]) rotate([0, 90, 0]) rotate([0, 0, 22.5]) difference() {
        cylinder(h = 4, r = 11, $fn = 8); translate([0, 0, -1]) cylinder(h = 6, r = 8, $fn = 8);
    }
    translate([L - 0.01, 0, LEDS_Z]) hull() {
        translate([0, -19, -4.5]) cube([0.01, 38, 9]);
        translate([2.5, -17.5, -3.5]) cube([0.01, 35, 7]);
    }
    for (x = BOTOES_X) translate([x, BOTOES_Y, ZT - 0.01]) moldura_oct(15, 2);
    // painel hexagonal na lateral esquerda (acima da dobradiça)
    translate([5, Y_ESQ + 0.01, 53]) rotate([90, 0, 0]) hex_relevo(66, 14, 1);
}
module casco_furos() {
    em_x(-0.01, 0, EIXO) cylinder(h = LENTE_PROF, d = LENTE_D + 0.4);                      // lente: rebaixo por fora
    em_x(-1, 0, EIXO) cylinder(h = P + 2, d = LENTE_ABERTURA);
    for (z = [EIXO - 19, EIXO + 19]) em_x(-1, 0, z) cylinder(h = 12, d = 2.6);           // parafusos do capuz
    translate([P, Y_DIR - P - 2, ZB + C + P]) cube([L - 2*P, P + 5, ZT - ZB - 2*C - 2*P]);   // abertura lateral (tampa)
    // câmera: rasgo vertical na frente (±4 mm para acertar a altura da lente)
    translate([L - P - 1, 0, CAM_Z]) rotate([0, 90, 0]) hull() for (s = [-1, 1]) translate([s * 4, 0, 0]) cylinder(h = P + 8, d = 11);
    for (y = LEDS_Y) em_x(L - P - 1, y, LEDS_Z) cylinder(h = P + 6, d = 5.1);               // LEDs IR 5 mm
    translate([ESP_X, Y_ESQ + P + 1, ZT - P - 1.5]) cube([1.8, Y_DIR - Y_ESQ - 2*P - 2, 1.51]);   // ranhura de cima da ESP32-CAM
    for (x = BOTOES_X) translate([x, BOTOES_Y, ZT - P - 1]) cylinder(h = P + 4, d = 9.6);
    translate([CHAVE_X - 4.5, CHAVE_Y - 2, ZT - P - 1]) cube([9, 4, P + 2]);
    translate([USB_X - 5, USB_Y - 2.3, ZT - P - 1]) cube([10, 4.6, P + 2]);
    // dobradiça: furo do pino (M3 x 50) e as 2 covinhas da trava em cada face da orelha
    em_x(DOB_X[2] - 1, DOB_Y, DOB_Z) cylinder(h = DOB_X[3] - DOB_X[2] + 2, d = 3.4);
    em_x(DOB_X[2] - 1, DOB_Y, DOB_Z - BB_R) cylinder(h = DOB_X[3] - DOB_X[2] + 2, d = 3.4);   // 2º parafuso da base FIXA (não atrapalha a trava da basculante)
    for (pos = [[0, -BB_R], [-BB_R, 0]]) {       // em pé: embaixo do eixo · virado: ao lado
        em_x(DOB_X[2] - 0.01, DOB_Y + pos[0], DOB_Z + pos[1]) cylinder(h = FURO_TRAVA, d = 6);                 // furos do pino de trava
        em_x(DOB_X[3] - 1.39, DOB_Y + pos[0], DOB_Z + pos[1]) cylinder(h = 1.4, d1 = 1.8, d2 = 4.6);          // covinhas da BB
    }
}
module ressaltos() {                          // onde a tampa parafusa (ficam até a face da abertura)
    difference() {
        intersection() {
            ao_longo(0, L) secao2d();
            for (p = TAMPA_FUROS) translate([p[0] - 3.5, 10, p[1] < EIXO ? ZB + P - 0.01 : p[1] - 3.5])
                cube([7, Y_DIR - 10, p[1] < EIXO ? p[1] + 3.5 - ZB - P : ZT - P - p[1] + 3.51]);
        }
        for (p = TAMPA_FUROS) translate([p[0], 12, p[1]]) rotate([-90, 0, 0]) cylinder(h = 12, d = 2.6);
    }
}
module casco() {
    difference() {
        union() {
            difference() { ao_longo(0, L) secao2d(); ao_longo(P, L - P) secao2d(P); }
            intersection() { ao_longo(0, L) secao2d(); casco_interno(); }
            casco_externo();
        }
        casco_furos();
    }
    ressaltos();
}

// ---------- TAMPA LATERAL (coyote) · MARCA DO PROJETO (única) ----------
module tampa2d() { translate([0, ZB + C]) oct2d(L, ZT - ZB - 2*C, 3); }
module tampa() {                              // z da peça = espessura; x = x do casco; y da peça = z do casco
    difference() {
        hull() { translate([0, 0, 1.2]) linear_extrude(E_TAMPA - 1.2) tampa2d(); linear_extrude(E_TAMPA) offset(delta = -1.2) tampa2d(); }
        for (p = TAMPA_FUROS) translate([p[0], p[1], 0]) { furo(3.4); translate([0, 0, -0.01]) cylinder(h = 1.8, d = 6.2); }
        emblema_baixo(36, (ZB + ZT) / 2 + 6, 0.6, 0.7);
        logo_baixo(36, (ZB + ZT) / 2 - 5, 4, prof = 0.7);
        nervuras_baixo(54, (ZB + ZT) / 2, 3, 3.6, 20, 0.7, 0);
    }
}

// ---------- CAPUZ DA LENTE (coyote): segura a lente por fora e corta a luz de lado ----------
module capuz_lente() {                        // impresso com a aba na mesa
    difference() {
        union() {
            hull() for (z = [-19, 19]) translate([0, z, 0]) cylinder(h = 3, d = 9);
            cylinder(h = 3, d = 34);
            rotate([0, 0, 22.5]) cylinder(h = 8, r = 17.5 / cos(22.5), $fn = 8);
        }
        translate([0, 0, -1]) cylinder(h = 20, d = LENTE_ABERTURA);
        translate([0, 0, -0.01]) cylinder(h = 1.8, d = LENTE_D + 0.6);     // a lente sobra 1,6 mm para fora do casco
        translate([0, 0, 3]) rotate([0, 0, 22.5]) cylinder(h = 10, r = 14.5 / cos(22.5), $fn = 8);
        for (z = [-19, 19]) translate([0, z, 0]) { furo(3.4); translate([0, 0, 3 - 1.8]) cylinder(h = 2, d = 6.2); }
    }
}

// ---------- SUPORTE DA TELA (preto): a tela desliza de cima num trilho em U; o pé tem rasgos de foco ----------
module suporte_tela() {                       // na posição de uso (x = FOCO é a face da tela)
    w0 = Y_ESQ + P + 2.6; w1 = 15.5; z0 = TELA_Z0; z1 = ZT - P - 1;
    difference() {
        union() {
            translate([FOCO - 2.5, w0, z0]) cube([2.5, w1 - w0, z1 - z0]);                       // placa
            translate([FOCO - 8, Y_ESQ + P + 2.5, 40]) cube([16, 3, 26]);                        // pé (encosta nos pinos)
            for (s = [-1, 1]) translate([FOCO, s > 0 ? -TELA_PCB[0]/2 - 2 : TELA_PCB[0]/2 - 0.6, z0])
                cube([3.2, 2.6, z1 - z0]);                                                         // laterais do trilho
            translate([FOCO, -TELA_PCB[0]/2 - 2, z0]) cube([3.2, TELA_PCB[0] + 4, 2]);           // batente de baixo
        }
        translate([FOCO - 4, -12, EIXO - 13]) cube([6, 24, 28]);                                   // janela
        translate([FOCO - 1.6, -14, z0 + 2]) cube([1.61, 28, 31]);                                 // vidro da tela
        for (s = [-1, 1]) translate([FOCO - 0.01, s > 0 ? -TELA_PCB[0]/2 - 0.6 : TELA_PCB[0]/2 - 1.2, z0 + 1.99])
            cube([1.8, 1.8, z1]);                                                                  // ranhuras da placa
        for (z = [44, 60]) hull() for (dx = [-5, 5])                                               // rasgos de foco (±5 mm)
            translate([FOCO + dx, Y_ESQ, z]) rotate([-90, 0, 0]) cylinder(h = 12, d = 3.4);
    }
}

// ---------- PINO DE TRAVA (coyote) ----------
module pino_trava() {                         // impresso em pé; o parafuso M3 x 12 (botão) rosqueia no furo do lado
    difference() {
        union() { cylinder(h = PINO_L - 0.6, d = PINO_D); translate([0, 0, PINO_L - 0.6]) cylinder(h = 0.6, d1 = PINO_D, d2 = PINO_D - 1); }
        translate([0, 0, 1.8]) rotate([0, 90, 0]) cylinder(h = PINO_D + 2, d = 2.5, center = true);   // perto da ponta de trás: o botão não bate na orelha
    }
}

// ---------- BASE COM DOBRADIÇA (preto) ----------
module garra(lado) {                          // igual ao anti-cant: perfil 45° que agarra o trilho
    mirror([0, lado > 0 ? 1 : 0, 0])
    rotate([90, 0, 90]) linear_extrude(20)
        polygon([[-TRILHO_L/2 - 4, 0], [-TRILHO_L/2 + 0.2, 0], [-TRILHO_L/2 + 3, -2.8],
                 [-TRILHO_L/2 + 3, -GARRA_H], [-TRILHO_L/2 - 4, -GARRA_H]]);
}
// DOIS JEITOS DE FIXAR (imprima um dos dois; casco e resto iguais):
//   base_flip  = BASCULANTE: vira para a esquerda (trava de pino com mola), como magnificador de holo
//   base_fixa  = FIXA: sempre na frente da luneta; 2 parafusos M3 x 50 atravessam as 2 articulações e a orelha
//                (o do eixo e outro 7,2 mm abaixo, no lugar da trava): não gira nem tem folga
module base_flip() { base_dobradica(false); }

// ---------- BASE FIXA = ELEVADOR (preto) ----------
// Um bloco maciço (como um riser de luneta) do trilho até o fundo do casco. A orelha da dobradiça do casco entra
// num encaixe recortado no bloco e 2 parafusos M3 x 50 atravessam o bloco e a orelha: não gira e não tem folga.
module orelha_folga() {          // forma da orelha do casco + 0,4 mm de folga
    hull() {
        em_x(DOB_X[2] - 0.4, DOB_Y, DOB_Z) cylinder(h = DOB_X[3] - DOB_X[2] + 0.8, r = DOB_R + 0.4);
        translate([DOB_X[2] - 0.4, Y_ESQ - 0.4, ZB + C - 0.4]) cube([DOB_X[3] - DOB_X[2] + 0.8, 1, 17]);
    }
}
module base_fixa() {
    difference() {
        union() {
            // bloco do elevador: chanfrado em octógono, do trilho (z = 0) até o fundo do casco
            translate([BASE_X0, 0, 0]) rotate([90, 0, 90]) linear_extrude(BASE_X1 - BASE_X0)
                offset(delta = 0) polygon([[BASE_Y0 + 6, 0], [BASE_Y1 - 4, 0], [BASE_Y1, 4], [BASE_Y1, ZB - 0.2], [-14, ZB - 0.2],
                                           [Y_ESQ - 0.6, ZB - 0.2], [BASE_Y0, DOB_Z + 4], [BASE_Y0, 6]]);
            translate([GARRA_X, 0, 0]) garra(-1);
        }
        orelha_folga();                                                                          // encaixe da orelha
        translate([GARRA_X + 10, -40, -2.6]) rotate([-90, 0, 0]) cylinder(h = 80, d = 3.4);    // M3 x 30 da garra
        for (z = [DOB_Z, DOB_Z - BB_R]) {                                                         // 2 parafusos M3 x 50
            em_x(BASE_X0 - 1, DOB_Y, z) cylinder(h = BASE_X1 - BASE_X0 + 2, d = 3.4);
            em_x(BASE_X0 - 0.01, DOB_Y, z) cylinder(h = 3, d = 6.2);                             // cabeça (atrás)
            em_x(BASE_X1 - 3, DOB_Y, z) rotate([0, 0, 30]) cylinder(h = 3.01, d = 6.6, $fn = 6); // porca (na frente)
        }
        // alívio de peso: janela facetada atravessando o bloco (longe dos furos e da garra)
        translate([BASE_X0 + 8, -20, 6]) rotate([90, 0, 0]) translate([0, 0, -30]) prisma_oct(BASE_X1 - BASE_X0 - 16, 14, 2, 3);
    }
    // painel hexagonal na lateral direita do elevador (visual tático, material acrescentado)
    translate([BASE_X0 + 6, BASE_Y1 - 0.01, 8]) rotate([90, 0, 0]) mirror([0, 0, 1]) hex_relevo(BASE_X1 - BASE_X0 - 12, 14, 1);
}
module base_dobradica(fixa) {
    difference() {
        union() {
            translate([BASE_X0, BASE_Y0, 0]) prisma_oct(BASE_X1 - BASE_X0, BASE_Y1 - BASE_Y0, BASE_E, 4);
            translate([GARRA_X, 0, 0]) garra(-1);
            for (k = [0, 4]) hull() {                                                           // articulações
                em_x(DOB_X[k], DOB_Y, DOB_Z) cylinder(h = 10, r = DOB_R);
                translate([DOB_X[k], DOB_Y - DOB_R, 0]) cube([10, 2 * DOB_R, BASE_E]);
            }
            // batente: em pé, a unidade apoia aqui (o peso fica no batente, não na trava)
            hull() {
                translate([BATENTE[0], -6, BASE_E - 0.01]) cube([BATENTE[1] - BATENTE[0], 18, 1]);
                translate([BATENTE[0] + 2, -4, ZB - 0.2 - 1]) cube([BATENTE[1] - BATENTE[0] - 4, 14, 1]);
            }
        }
        translate([GARRA_X + 10, -40, -2.6]) rotate([-90, 0, 0]) cylinder(h = 80, d = 3.4);    // M3 x 30 da garra
        em_x(DOB_X[0] - 1, DOB_Y, DOB_Z) cylinder(h = DOB_X[5] - DOB_X[0] + 2, d = 3.4);       // pino M3 x 50
        em_x(DOB_X[0] - 0.01, DOB_Y, DOB_Z) cylinder(h = 3, d = 6.2);                          // cabeça
        em_x(DOB_X[5] - 3, DOB_Y, DOB_Z) rotate([0, 0, 30]) cylinder(h = 3.01, d = 6.6, $fn = 6);   // porca
        if (!fixa) {
            // trava de pino (articulação de trás): furo do pino + rasgo do botão (parafuso M3 x 12) para a esquerda
            em_x(DOB_X[0] + 0.8, DOB_Y, DOB_Z - BB_R) cylinder(h = DOB_X[1] - DOB_X[0] - 0.79, d = PINO_D + 0.3);
            ponta = DOB_X[2] + FURO_TRAVA - 0.2;                                                     // ponta do pino travado
            translate([ponta - PINO_L + 1.8 - PINO_CURSO - 1.7, DOB_Y - 14, DOB_Z - BB_R - 1.7]) cube([PINO_CURSO + 3.4, 14, 3.4]);   // rasgo do botão (anda 3 mm)
            // articulação da frente: BB de 6 mm + molinha de caneta (só tira a folga)
            em_x(DOB_X[4] - 0.01, DOB_Y, DOB_Z - BB_R) cylinder(h = 9, d = 6.3);
        } else {
            // 2º parafuso M3 x 50 atravessado (abaixo do eixo): trava a unidade em pé, sem folga
            em_x(DOB_X[0] - 1, DOB_Y, DOB_Z - BB_R) cylinder(h = DOB_X[5] - DOB_X[0] + 2, d = 3.4);
            em_x(DOB_X[0] - 0.01, DOB_Y, DOB_Z - BB_R) cylinder(h = 3, d = 6.2);
            em_x(DOB_X[5] - 3, DOB_Y, DOB_Z - BB_R) rotate([0, 0, 30]) cylinder(h = 3.01, d = 6.6, $fn = 6);
        }
    }
}

// ---------- MANDÍBULA MÓVEL (coyote) ----------
module mandibula() {
    difference() {
        union() { garra(1); translate([0, TRILHO_L/2 + 4, -GARRA_H]) cube([20, 5, GARRA_H]); }
        translate([10, -30, -2.6]) rotate([-90, 0, 0]) cylinder(h = 60, d = 3.4);
        translate([10, TRILHO_L/2 + 6.5, -2.6]) rotate([-90, 0, 0]) cylinder(h = 3, d = 6.6, $fn = 6);
    }
}

// ---------- saídas para impressão ----------
if (PECA == "casco") rotate([0, -90, 0]) casco();                                       // face de trás na mesa
if (PECA == "tampa") tampa();                                                           // face de fora na mesa
if (PECA == "capuz_lente") capuz_lente();
if (PECA == "suporte_tela") rotate([0, 90, 0]) translate([-FOCO - 3.2, 0, 0]) suporte_tela();   // trilhos na mesa
if (PECA == "base_flip") translate([0, 0, GARRA_H]) base_flip();
if (PECA == "base_fixa") translate([0, 0, GARRA_H]) base_fixa();
if (PECA == "mandibula") translate([0, 0, GARRA_H]) mandibula();
if (PECA == "capa_botao") capa_botao(9, 0, 4);
if (PECA == "pino_trava") pino_trava();

// =====================================================================
//  LANTERNA IR 850 nm (para ver a 80-100 m) · caixa tática estilo PEQ no M-LOK direito do guarda-mão
//  18650 no suporte padrão + carga USB-C (TP4056) + botão com trava 8x8 + driver 7135 + LED 3 W 850 nm
//  + lente colimadora de 20 mm e 5° (feixe estreito = alcance). Cores: caixa e porcas M-LOK PRETO · tampa COYOTE.
//  Eixos da lanterna: x para a frente · y = 0 na face que encosta no guarda-mão (y+ para fora) · z = 0 no meio
// =====================================================================
IR_L = 112; IR_W = 28; IR_H = 30; IR_PAREDE_MLOK = 5;   // caixa (a parede do M-LOK é mais grossa: cabeça do parafuso embutida)
IR_LENTE_H = 12;                                         // lente colimadora de 20 mm com o suporte dela (CONFIRA)
IR_ESTRELA_X = IR_L - 3 - IR_LENTE_H - 1.6;              // onde a estrela do LED encosta
IR_FUROS_MLOK = [33, 73];                                // 40 mm entre eles = passo do M-LOK
IR_TAMPA_FUROS = [[6.5, -10.5], [IR_ESTRELA_X - 1.5, -10.5]];
// encaixe do acionador remoto (plugue SF do acionador duplo, o cabo de lanterna): MEÇA o seu plugue e ajuste
SF_D = 6.2; SF_L = 10;                                   // diâmetro e comprimento da ponta que entra
SF_Y = 7.5; SF_Z = -6;                                   // atrás, ao lado do botão com trava (lado do guarda-mão)
module ir_caixa() {
    yc = (IR_PAREDE_MLOK + IR_W) / 2;                     // centro da cavidade (y)
    difference() {
        union() {
            ao_longo(0, IR_L) polygon([[0, -IR_H/2 + 5], [5, -IR_H/2], [IR_W, -IR_H/2], [IR_W, IR_H/2], [5, IR_H/2], [0, IR_H/2 - 5]]);   // chanfro do lado do guarda-mão; lado de fora reto (tampa rente)
            translate([IR_L - 0.01, yc, 0]) rotate([0, 90, 0]) rotate([0, 0, 22.5]) difference() {   // capuz da lente
                cylinder(h = 8, r = 13 / cos(22.5), $fn = 8); translate([0, 0, -1]) cylinder(h = 10, r = 9.6 / cos(22.5), $fn = 8);
            }
            translate([0, SF_Y, SF_Z]) rotate([0, 90, 0]) cylinder(h = SF_L + 3, d = SF_D + 3.6);               // encaixe do acionador (por dentro)
            translate([0.01, SF_Y, SF_Z]) rotate([0, -90, 0]) difference() { moldura_oct(SF_D + 3, 2); translate([0, 0, -1]) cylinder(h = 4, d = SF_D); }   // moldura que protege o plugue
        }
        translate([3, IR_PAREDE_MLOK, -IR_H/2 + 3]) cube([IR_L - 6, IR_W, IR_H - 6]);              // cavidade (aberta do lado de fora)
        em_x(IR_L - 4, yc, 0) cylinder(h = 6, d = 17);                                                // janela do LED
        translate([-1, yc - 5, 8.5]) cube([5, 10, 4.5]);                                             // USB-C da carga
        translate([-1, yc - 4.2, -7.2]) cube([5, 8.4, 8.4]);                                         // botão com trava 8x8
        translate([-3, SF_Y, SF_Z]) rotate([0, 90, 0]) cylinder(h = SF_L + 3, d = SF_D);                  // furo do plugue SF
        translate([SF_L - 0.01, SF_Y, SF_Z]) rotate([0, 90, 0]) cylinder(h = 5, d = 2.2);                  // fio da mola do contato do meio
        translate([3, SF_Y - 0.5, SF_Z]) cube([SF_L - 4, 1, SF_D/2 + 2]);                                  // fenda da lâmina de contato do corpo do plugue
        for (x = IR_FUROS_MLOK) translate([x, -1, 0]) rotate([-90, 0, 0]) {                         // parafusos do M-LOK
            cylinder(h = IR_PAREDE_MLOK + 2, d = 3.4); translate([0, 0, IR_PAREDE_MLOK + 1 - 3]) cylinder(h = 3.01, d = 6.2);
        }
        for (x = [IR_ESTRELA_X - 14 : 4 : IR_ESTRELA_X - 2]) translate([x, IR_PAREDE_MLOK + 4, IR_H/2 - 4]) cube([2, IR_W - 10, 5]);   // ventilação
    }
    // por dentro: parede da estrela (furo para os fios) + anel que centraliza a estrela de 20 mm
    difference() {
        translate([IR_ESTRELA_X - 3, IR_PAREDE_MLOK - 0.01, -IR_H/2 + 2.99]) cube([3, IR_W - IR_PAREDE_MLOK - 0.2, IR_H - 5.98]);
        em_x(IR_ESTRELA_X - 4, yc, 0) cylinder(h = 5, d = 15);
    }
    translate([IR_ESTRELA_X - 0.01, 0, 0]) em_x(0, yc, 0) difference() { cylinder(h = 1.6, d = 22); translate([0, 0, -1]) cylinder(h = 4, d = 20.4); }
    // ressaltos dos 2 parafusos da tampa (M3 x 10)
    for (p = IR_TAMPA_FUROS) translate([p[0], IR_PAREDE_MLOK - 0.01, p[1]]) rotate([-90, 0, 0]) pino(IR_W - IR_PAREDE_MLOK - 0.2, 6, 2.6);
}
module ir_tampa() {                           // coyote, impressa com a face de fora na mesa (nervuras em V para o cano)
    difference() {
        hull() { translate([0, -IR_H/2, 1]) cube([IR_L, IR_H, 2]); translate([1, -IR_H/2 + 1, 0]) cube([IR_L - 2, IR_H - 2, 3]); }
        for (p = IR_TAMPA_FUROS) translate([p[0], p[1], 0]) { furo(3.4); translate([0, 0, -0.01]) cylinder(h = 1.6, d = 6.2); }
        nervuras_baixo(IR_L - 50, 0, 4, 5, 20, 0.7, 180);
    }
}
module tnut_mlok() {                          // porca deslizante M-LOK impressa: entra no rasgo em pé e gira 90° (horário)
    difference() {
        linear_extrude(4) polygon([[-9, -3.3], [7, -3.3], [9, -1.3], [9, 3.3], [-7, 3.3], [-9, 1.3]]);
        translate([0, 0, -1]) cylinder(h = 6, d = 3.4);
        translate([0, 0, 1.6]) rotate([0, 0, 30]) cylinder(h = 3, d = 6.6, $fn = 6);           // porca M3 embutida
    }
}
module lanterna_uso() {                       // montada (para a prévia), na posição de uso do lado direito
    pinta(0) ir_caixa();
    pinta(1) translate([0, IR_W + 3, 0]) rotate([90, 0, 0]) ir_tampa();
    for (x = IR_FUROS_MLOK) pinta(0) translate([x, -2.5, 0]) rotate([90, 0, 0]) rotate([0, 0, 90]) tnut_mlok();
}

if (PECA == "ir_caixa") rotate([90, 0, 0]) ir_caixa();          // face do M-LOK na mesa
if (PECA == "ir_tampa") ir_tampa();
if (PECA == "tnut_mlok") tnut_mlok();