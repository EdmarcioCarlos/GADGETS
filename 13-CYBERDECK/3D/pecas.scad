// =====================================================================
//  13 - CYBERDECK BLACK BIRD (militar + DedSec) · peças 3D (maleta inteira impressa)
//  Raspberry Pi 4 + tela 7" + mini teclado. Liga com SEQUÊNCIA DE PARTIDA DE CAÇA no painel:
//  BAT → MASTER ARM → APU → ENG 1 → ENG 2 → MANETE em MIL → START (um ESP32-C3 confere e liga o Pi).
//  Toque DedSec: barra de "glitch" vazada no painel com fita de LED RGB (WS2812) por baixo.
//  Mesa de 220 x 220 mm: corpo e tampa em 4 partes de até 205 x 155,
//  unidas por nervuras internas com parafusos M3 + porca.
//  Escolha a peça em PECA, F6 (render) e F7 (exportar STL). Medidas em mm.
//  X = largura (0 = esquerda), Y = profundidade (0 = frente, travas; 310 = trás, dobradiças)
//  ESTILO TÁTICO FACETADO · cores: base, moldura da tela, dobradiças, travas, alça,
//  emendas, colunas e bases das capas míssil em PRETO · tampa e painel em COYOTE ·
//  capas míssil basculantes em VERMELHO (cor de alerta, única exceção)
// =====================================================================
use <../../_BIBLIOTECA-3D/bb_lib.scad>
$fn = 40;

PECA = "base_fe";   // base_fe | base_fd | base_te | base_td  (f = frente, t = trás, e = esquerda, d = direita)
                    // tampa_fe | tampa_fd | tampa_te | tampa_td
                    // painel_fe | painel_fd | painel_te | painel_td
                    // cantoneira_tela | capa_missil_base | capa_missil_tampa | suporte_tm1637
                    // manete_base | manete_alavanca | trilho_neon
                    // dobradica_base | dobradica_tampa | trava_lingueta | trava_batente
                    // alca | emenda | coluna

// ---------- medidas gerais ----------
EX = 410; EY = 310;         // por fora
P = 4;                      // parede (maleta inteira: 4 mm)
R = 10;                     // canto (peças antigas)
CH = 15;                    // chanfro dos cantos da maleta (estilo tático facetado)
BASE_H = 90; TAMPA_H = 45;
SX = 205; SY = 155;         // linhas de divisão (mesa 220)
LEDGE_Z = 74;               // apoio do painel (painel de 4 mm: z 78..82)
PZ = 78;                    // fundo do painel
PE = 4;                     // espessura do painel
// monitor portátil 15,6" Full HD (USB-C + mini HDMI) na tampa: CONFIRA as medidas do seu
MON_W = 357; MON_H = 223; MON_T = 9;                       // largura, altura, espessura
MON_X0 = (EX - MON_W) / 2; MON_Y0 = (EY - MON_H) / 2;      // centrado na tampa
MON_Z = P + 8;                                             // as costas apoiam nas nervuras de 8 mm do fundo da tampa
MON_PINOS = [[MON_X0 - 7, MON_Y0 - 7, 0], [MON_X0 + MON_W + 7, MON_Y0 - 7, 90],
             [MON_X0 + MON_W + 7, MON_Y0 + MON_H + 7, 180], [MON_X0 - 7, MON_Y0 + MON_H + 7, 270]];   // [x, y, giro da cantoneira]
FUROS_EMENDA = [30, 80, 130, 180, 230, 280];      // ao longo de Y (divisão em X = 205)
FUROS_EMENDA_X = [30, 80, 130, 180, 240, 290, 340, 380];   // ao longo de X (divisão em Y = 155)
DOBRADICAS_X = [80, 330];
TRAVAS_X = [100, 310];
ALCA_X = [165, 245];

// ===================== NERVURAS DE UNIÃO =====================
module nervuras(altura) {
    // no fundo
    difference() {
        union() {
            translate([SX - 6, P, P - 0.01]) cube([12, EY - 2*P, 8]);
            translate([P, SY - 6, P - 0.01]) cube([EX - 2*P, 12, 8]);
        }
        for (y = FUROS_EMENDA) translate([SX - 15, y, P + 4]) rotate([0, 90, 0]) cylinder(h = 30, d = 3.4);
        for (x = FUROS_EMENDA_X) translate([x, SY - 15, P + 4]) rotate([-90, 0, 0]) cylinder(h = 30, d = 3.4);
    }
    // nas paredes
    hw = altura - P - 4;
    for (yy = [P, EY - P - 6]) difference() {
        translate([SX - 6, yy, P - 0.01]) cube([12, 6, hw]);
        for (z = [20, hw * 0.55, hw - 6]) translate([SX - 15, yy + 3, P + z]) rotate([0, 90, 0]) cylinder(h = 30, d = 3.4);
    }
    for (xx = [P, EX - P - 6]) difference() {
        translate([xx, SY - 6, P - 0.01]) cube([6, 12, hw]);
        for (z = [20, hw * 0.55, hw - 6]) translate([xx + 3, SY - 15, P + z]) rotate([-90, 0, 0]) cylinder(h = 30, d = 3.4);
    }
}

// ===================== CORPO (BASE) INTEIRO =====================
PAINEL_PARAF = [[7, 80], [7, 230], [EX - 7, 80], [EX - 7, 230], [105, 7], [305, 7], [105, EY - 7], [305, EY - 7]];
module base_inteira() {
    difference() {
        union() {
            caixa_tatica(EX, EY, BASE_H, P, P, CH);
            nervuras(BASE_H);
            // apoio do painel (anel por dentro das paredes, acompanha os cantos chanfrados)
            translate([0, 0, LEDGE_Z]) linear_extrude(PZ - LEDGE_Z) difference() {
                offset(delta = -P + 0.01) oct2d(EX, EY, CH);
                offset(delta = -(P + 6)) oct2d(EX, EY, CH);
            }
        }
        for (c = PAINEL_PARAF) translate([c[0], c[1], LEDGE_Z - 6]) cylinder(h = 7, d = 2.6);
        // dobradiças (parede de trás) · travas e alça (parede da frente)
        for (x = DOBRADICAS_X, dx = [-15, 15]) translate([x + dx, EY + 1, 77]) rotate([90, 0, 0]) cylinder(h = P + 2, d = 3.4);
        for (x = TRAVAS_X) translate([x, -1, 78]) rotate([-90, 0, 0]) cylinder(h = P + 2, d = 3.4);
        for (x = ALCA_X) translate([x, -1, 50]) rotate([-90, 0, 0]) cylinder(h = P + 2, d = 3.4);
        // nome: frente e trás, um em cada quarto
    }
}

// ===================== TAMPA INTEIRA (impressa aberta para cima) =====================
module tampa_inteira() {
    difference() {
        union() {
            caixa_tatica(EX, EY, TAMPA_H, P, P, CH);
            nervuras(TAMPA_H);
            for (c = MON_PINOS) translate([c[0], c[1], 0]) pino(MON_Z + MON_T, 9, 2.6);   // pinos das 4 cantoneiras do monitor
        }
        for (x = DOBRADICAS_X, dx = [-15, 15]) translate([x + dx, EY + 1, TAMPA_H - 13]) rotate([90, 0, 0]) cylinder(h = P + 2, d = 3.4);
        for (x = TRAVAS_X) translate([x, -1, TAMPA_H - 12]) rotate([-90, 0, 0]) cylinder(h = P + 2, d = 3.4);
        // MARCA DO PROJETO (única): nome grande + emblema na face de cima da maleta fechada
        logo_baixo(EX/2, EY/2, 30);
        emblema_baixo(EX/2, EY/2 + 52, 3, 0.6);          // emblema acima do nome
        nervuras_baixo(70, EY/2, 3, 6, 40, 0.6, 180);    // nervuras em V dos dois lados do nome
        nervuras_baixo(EX - 70, EY/2, 3, 6, 40, 0.6, 0);
    }
}

// ===================== PAINEL INTEIRO (posição de uso) =====================
module painel_inteiro() {
    difference() {
        translate([0, 0, PZ]) linear_extrude(PE) offset(delta = -(P + 0.5)) oct2d(EX, EY, CH);
        // parafusos no apoio e nas colunas (rebaixados)
        for (c = concat(PAINEL_PARAF, [[130, SY], [280, SY]])) translate([c[0], c[1], PZ]) { furo(3.4); translate([0, 0, PE - 1.6]) cylinder(h = 2, d1 = 3.4, d2 = 6.5); }
        // emendas por baixo (parafuso M3 de cabeça chata + porca)
        for (y = [60, 250], x = [SX - 10, SX + 10]) translate([x, y, PZ]) { furo(3.4); translate([0, 0, PE - 1.6]) cylinder(h = 2, d1 = 3.4, d2 = 6.5); }
        for (x = [60, 350], y = [SY - 10, SY + 10]) translate([x, y, PZ]) { furo(3.4); translate([0, 0, PE - 1.6]) cylinder(h = 2, d1 = 3.4, d2 = 6.5); }
        // LEDs de status
        for (x = [30, 48, 66]) translate([x, 279, PZ]) furo(3.2);      // LEDs de 3 mm
        // buzzer
        for (x = [100, 106, 112], y = [278, 284]) translate([x, y, PZ]) furo(3);
        // display TM1637 (mensagens da partida), preso por baixo no suporte_tm1637
        translate([165, 281, PZ]) furo_rect(43, 17);
        // ventilação do Raspberry Pi
        for (k = [0:11]) translate([282 + k * 8.5, 281, PZ]) furo_rect(4, 16);
        // rebaixo do mini teclado + entalhe para o dedo
        translate([20, 132, PZ + PE - 2]) cube([160, 110, 3]);
        translate([100, 132, PZ + 1]) cylinder(h = 4, r = 12);
        // 4 botões arcade (da esquerda: APU amarelo, ENG 1 azul, ENG 2 verde, START vermelho)
        for (x = [235, 280, 325, 370]) translate([x, 207, PZ]) furo(30);
        // manete (alavanca de potência): rasgo + 4 parafusos da manete_base por baixo
        translate([MANETE_X, MANETE_Y, PZ]) furo_rect(8.5, 62);
        for (dx = [-14, 14], dy = [-36, 36]) translate([MANETE_X + dx, MANETE_Y + dy, PZ]) { furo(3.4); translate([0, 0, PE - 1.6]) cylinder(h = 2, d1 = 3.4, d2 = 6.5); }
        // barra de glitch DedSec: rasgos de tamanhos diferentes; a fita WS2812 acende por baixo
        for (r = GLITCH) translate([r[0], r[1], PZ - 1]) cube([r[2], 3, PE + 2]);
        for (x = TRILHO_NEON_X, dx = [8, 112]) translate([x + dx, 15, PZ]) { furo(3.4); translate([0, 0, PE - 1.6]) cylinder(h = 2, d1 = 3.4, d2 = 6.5); }
        // display TM1637: 2 parafusos do suporte
        for (dx = [-26.5, 26.5]) translate([165 + dx, 281, PZ]) { furo(3.4); translate([0, 0, PE - 1.6]) cylinder(h = 2, d1 = 3.4, d2 = 6.5); }
        // nomes dos comandos (estêncil militar, gravados 0,6 mm)
        for (l = ROTULOS) translate([l[0], l[1], PZ + PE]) _txt(l[2], l[3], 0.6);
        // 3 chaves míssil (furo da chave + 2 furos da base da capa)
        for (x = [250, 302, 354]) { translate([x, 92, PZ]) furo(6.4); for (dy = [-16, 16]) translate([x, 92 + dy, PZ]) furo(2.6); }
        // extensões USB-A (pendrive) e USB-C (carga)
        translate([36, 62, PZ]) furo_rect(22, 12); for (dx = [-15, 15]) translate([36 + dx, 62, PZ]) furo(3.4);
        translate([72, 62, PZ]) furo_rect(13, 7);  for (dx = [-12.5, 12.5]) translate([72 + dx, 62, PZ]) furo(3.4);
        // RFID (futuro): só o contorno; o leitor RC522 lê através de 4 mm de plástico
        translate([100, 47, PZ + PE - 0.6]) difference() { cube([40, 40, 1]); translate([0.8, 0.8, -0.1]) cube([38.4, 38.4, 1.2]); }
        logo_topo(120, 67, PZ + PE, 4, "RFID");
    }
}

// ---------- painel de partida ----------
MANETE_X = 215; MANETE_Y = 152;              // centro do rasgo da manete (IDLE perto de você, MIL para trás)
TRILHO_NEON_X = [152, 278];                  // 2 trilhos de 120 mm por baixo da barra de glitch
GLITCH = [[156, 18, 22], [182, 18, 8], [194, 18, 31], [230, 18, 12], [246, 18, 40], [290, 18, 9], [303, 18, 26], [334, 18, 14], [352, 18, 36],
          [160, 22.5, 9], [173, 22.5, 41], [218, 22.5, 18], [240, 22.5, 7], [251, 22.5, 28], [283, 22.5, 45], [332, 22.5, 11], [347, 22.5, 24], [375, 22.5, 16],
          [158, 27, 30], [192, 27, 12], [208, 27, 26], [238, 27, 9], [251, 27, 37], [292, 27, 17], [313, 27, 8], [325, 27, 33], [362, 27, 28]];
ROTULOS = [[250, 62, "BAT", 5], [302, 62, "MASTER ARM", 4.2], [354, 62, "NEON", 5],
           [235, 231, "APU", 5], [280, 231, "ENG 1", 5], [325, 231, "ENG 2", 5], [370, 231, "START", 5],
           [MANETE_X - 16, 128, "IDLE", 3.6], [MANETE_X - 16, 176, "MIL", 3.6],
           [276, 37, "// SISTEMA DE PARTIDA", 3.2]];

// ===================== DIVISÃO EM QUARTOS =====================
module quarto(i, j, zmax = 200) {          // i: 0 esquerda / 1 direita · j: 0 frente / 1 trás
    x0 = i == 0 ? -1 : SX; x1 = i == 0 ? SX : EX + 1;
    y0 = j == 0 ? -1 : SY; y1 = j == 0 ? SY : EY + 1;
    translate([-max(x0, 0), -max(y0, 0), 0])
        intersection() { children(); translate([x0, y0, -1]) cube([x1 - x0, y1 - y0, zmax]); }
}

// ===================== PEÇAS AVULSAS =====================
// cantoneira (4x) que prende o canto do monitor de 15,6" contra a tampa: L de 52 mm, cobre 6 mm da borda do monitor.
// Coordenadas: canto do monitor em (0, 0), monitor em x > 0 e y > 0; parafuso M3 no pino em (-7, -7).
module cantoneira_tela() {
    difference() {
        union() {
            placa_chanfrada(4, 1.2) polygon([[-14, -14], [40, -14], [40, 6], [6, 6], [6, 40], [-14, 40]]);
            translate([-14, -14, 3.99]) linear_extrude(1) polygon([[0, 0], [10, 0], [0, 10]]);   // marca triangular no canto (estilo militar)
        }
        translate([-7, -7, 0]) { furo(3.4); translate([0, 0, 2.4]) cylinder(h = 1.62, d1 = 3.4, d2 = 6.5); }
    }
}

module capa_missil_base() {    // vai por cima da chave MTS-102 (presa pela porca da chave + 2 parafusos)
    difference() {
        union() {
            rbox(26, 46, 3, 2);
            for (x = [1, 19]) translate([x, 0, 0]) hull() { cube([6, 6, 3]); translate([0, 3, 6]) rotate([0, 90, 0]) cylinder(h = 6, r = 3); }
        }
        translate([13, 26, 0]) furo(6.4);
        for (dy = [-16, 16]) translate([13, 26 + dy, 0]) { furo(3.4); translate([0, 0, 1.4]) cylinder(h = 1.62, d1 = 3.4, d2 = 6.5); }
        translate([-1, 3, 6]) rotate([0, 90, 0]) cylinder(h = 30, d = 1.9);     // pino de filamento 1,75
    }
}
module capa_missil_tampa() {   // capa vermelha basculante (imprima em PETG vermelho)
    difference() {
        union() {
            translate([2, 6, 3]) difference() { rbox(22, 40, 14, 3); translate([2, 2, -1]) rbox(18, 36, 13, 1.5); }
            translate([7.4, 0, 3]) hull() { translate([0, 3, 3]) rotate([0, 90, 0]) cylinder(h = 11.2, r = 3); translate([0, 6, 0]) cube([11.2, 1, 6]); }
        }
        translate([-1, 3, 6]) rotate([0, 90, 0]) cylinder(h = 30, d = 1.9);
    }
}

module suporte_tm1637() {       // por baixo do painel: os dígitos do display TM1637 (42 x 24) ficam no furo de 43 x 17
    difference() {
        prisma_oct(62, 36, 3, 3);
        translate([10, 6, -1]) cube([42.4, 24.4, 5]);                                  // a placa do display passa aqui
        for (x = [4.5, 57.5]) translate([x, 18, 0]) furo(2.6);                         // 2 M3 vindos do painel
    }
    for (x = [10 + 2.2, 10 + 40.2], y = [6 + 2.2, 6 + 22.2]) translate([x, y, 3 - 0.01]) pino(4, 4.5, 1.7);   // pinos M2 da placa
}

// ---------- manete (alavanca de potência) ----------
// manete_base: canal preso por baixo do painel (4 M3), com o eixo (M3 x 30) e a microchave KW11 no fim de MIL
MB_L = 80; MB_W = 18; MB_H = 34;
module manete_base() {          // na posição de uso, centrado no rasgo; o topo encosta embaixo do painel (z = PZ)
    translate([MANETE_X, MANETE_Y, PZ]) difference() {
        union() {
            translate([-MB_W/2, -MB_L/2, -MB_H]) prisma_oct(MB_W, MB_L, MB_H, 2);
            translate([-20, -40, -3]) prisma_oct(40, 80, 3, 4);                         // aba com os 4 parafusos
        }
        translate([-4.6, -MB_L/2 + 3, -MB_H + 3]) cube([9.2, MB_L - 6, MB_H]);          // canal da alavanca
        for (dx = [-14, 14], dy = [-36, 36]) translate([dx, dy, 0]) cylinder(h = 8, d = 2.6, center = true);
        translate([-20, 0, -24]) rotate([0, 90, 0]) cylinder(h = 40, d = 3.4);          // eixo (parafuso M3 x 30 + porca)
        translate([MB_W/2 - 1.5, 0, -24]) rotate([0, 90, 0]) cylinder(h = 3, d = 6.6, $fn = 6);
        // microchave KW11 (20 x 10 x 6) na parede do fim de MIL: 2 furos M2 a 9,5 mm
        for (dz = [-4.75, 4.75]) translate([-20, MB_L/2 - 12, -14 + dz]) rotate([0, 90, 0]) cylinder(h = 40, d = 2);
        translate([-MB_W/2 - 1, MB_L/2 - 22, -20]) cube([3, 20, 12]);                    // janela dos fios
    }
}
module manete_alavanca() {      // na posição IDLE (inclinada 22° para você); pivô 24 mm abaixo do painel
    translate([MANETE_X, MANETE_Y, PZ - 24]) rotate([22, 0, 0]) difference() {
        union() {
            hull() { rotate([0, 90, 0]) cylinder(h = 8, d = 12, center = true); translate([-3, -3, 24]) cube([6, 6, 1]); }   // braço
            translate([-3, -3, 24]) cube([6, 6, 14]);
            translate([-11, -9, 36]) hull() { prisma_oct(22, 18, 1, 4); translate([2, 2, 12]) prisma_oct(18, 14, 1, 3); }   // pegada facetada (baixa: não bate no monitor com a maleta fechada)
        }
        rotate([0, 90, 0]) cylinder(h = 20, d = 3.4, center = true);
        for (k = [0 : 3]) translate([-12, -10, 39 + k * 2.6]) cube([24, 1, 1.2]);        // ranhuras da pegada
    }
}

// ---------- trilho da fita neon (2x): segura a fita WS2812 de 10 mm virada para cima, embaixo dos rasgos ----------
module trilho_neon() {          // 120 x 26 x 5, impresso deitado; canal da fita no meio (y 7,6-18,4), parafusos na borda (y 4)
    difference() {
        prisma_oct(120, 26, 5, 2);
        translate([2, 7.6, 2]) cube([116, 10.8, 4]);
        for (x = [8, 112]) translate([x, 4, -1]) cylinder(h = 7, d = 2.6);
    }
}
module trilho_neon_uso() { for (x = TRILHO_NEON_X) translate([x, 11, PZ - 5]) trilho_neon(); }   // embaixo do painel, fita virada para cima

module dobradica(tipo) {        // tipo 0 = base (2 nós), 1 = tampa (1 nó); pino = parafuso M3 x 50
    difference() {
        union() {
            cube([50, 26, 4]);
            translate([0, 24, 0]) cube([50, 7, 5]);
            if (tipo == 0) for (x = [0, 38]) translate([x, 31, 5]) rotate([0, 90, 0]) cylinder(h = 12, r = 5);
            if (tipo == 1) translate([12.4, 31, 5]) rotate([0, 90, 0]) cylinder(h = 25.2, r = 5);
            if (tipo == 0) for (x = [0, 38]) translate([x, 24, 0]) cube([12, 7, 5]);
        }
        if (tipo == 0) translate([12, 24, -1]) cube([26, 13, 12]);                 // folga do nó do meio
        if (tipo == 1) { translate([-1, 24, -1]) cube([13.2, 13, 12]); translate([37.8, 24, -1]) cube([13.2, 13, 12]); }
        translate([-1, 31, 5]) rotate([0, 90, 0]) cylinder(h = 52, d = 3.4);
        for (x = [10, 40]) translate([x, 13, 0]) { furo(3.4); translate([0, 0, 2.4]) cylinder(h = 1.62, d1 = 3.4, d2 = 6.5); }
    }
}

module trava_lingueta() {       // gira no parafuso da frente da base e prende no batente da tampa
    difference() {
        union() { prisma_oct(50, 14, 5, 3); translate([44, 0, 0]) cube([6, 14, 9]); }
        translate([7, 7, 0]) furo(3.4);
    }
}
module trava_batente() {
    difference() {
        prisma_oct(20, 12, 8, 2);
        translate([10, 6, -1]) cylinder(h = 7, d = 2.6);
    }
}

module alca() {                 // 140 de comprimento; 2 parafusos M3 por dentro da parede da frente (80 mm entre eles)
    difference() {
        linear_extrude(20) offset(delta = 2, chamfer = true) offset(delta = -2) union() {   // cantos chanfrados
            translate([23, 0]) square([14, 26]);
            translate([103, 0]) square([14, 26]);
            translate([10, 16]) hull() { square([120, 12]); translate([10, 6]) circle(r = 6); translate([110, 6]) circle(r = 6); }
        }
        for (x = [30, 110]) translate([x, -1, 10]) rotate([-90, 0, 0]) cylinder(h = 16, d = 2.6);
    }
}

module emenda() {
    difference() { prisma_oct(40, 20, 3, 3); for (x = [10, 30]) translate([x, 10, 0]) furo(3.4); logo_topo(20, 10, 3, 2.6, "BB"); }
}

module coluna() {               // apoio do painel no meio (cola no topo da nervura do fundo)
    difference() {
        union() { cylinder(h = 3, d = 30); cylinder(h = PZ - P - 8 - 3 + 3, d = 16); }
        translate([0, 0, PZ - P - 8 - 10]) cylinder(h = 12, d = 2.6);
    }
}

// ===================== ESCOLHA =====================
if (PECA == "base_fe") quarto(0, 0) base_inteira();
if (PECA == "base_fd") quarto(1, 0) base_inteira();
if (PECA == "base_te") quarto(0, 1) base_inteira();
if (PECA == "base_td") quarto(1, 1) base_inteira();
if (PECA == "tampa_fe") quarto(0, 0) tampa_inteira();
if (PECA == "tampa_fd") quarto(1, 0) tampa_inteira();
if (PECA == "tampa_te") quarto(0, 1) tampa_inteira();
if (PECA == "tampa_td") quarto(1, 1) tampa_inteira();
if (PECA == "painel_fe") translate([0, 0, -PZ]) quarto(0, 0) painel_inteiro();
if (PECA == "painel_fd") translate([0, 0, -PZ]) quarto(1, 0) painel_inteiro();
if (PECA == "painel_te") translate([0, 0, -PZ]) quarto(0, 1) painel_inteiro();
if (PECA == "painel_td") translate([0, 0, -PZ]) quarto(1, 1) painel_inteiro();
if (PECA == "cantoneira_tela") cantoneira_tela();
if (PECA == "capa_missil_base") capa_missil_base();
if (PECA == "capa_missil_tampa") capa_missil_tampa();
if (PECA == "suporte_tm1637") suporte_tm1637();
if (PECA == "manete_base") rotate([180, 0, 0]) translate([-MANETE_X, -MANETE_Y, -PZ]) manete_base();          // aba na mesa
if (PECA == "manete_alavanca") translate([0, 0, 6]) rotate([-22, 0, 0]) translate([-MANETE_X, -MANETE_Y, -(PZ - 24)]) manete_alavanca();   // em pé, eixo na mesa
if (PECA == "trilho_neon") trilho_neon();
if (PECA == "dobradica_base") dobradica(0);
if (PECA == "dobradica_tampa") dobradica(1);
if (PECA == "trava_lingueta") trava_lingueta();
if (PECA == "trava_batente") trava_batente();
if (PECA == "alca") alca();
if (PECA == "emenda") emenda();
if (PECA == "coluna") coluna();
