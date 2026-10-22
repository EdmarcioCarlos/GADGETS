// =====================================================================
//  07 - SPEEDLOADER ELÉTRICO · peças 3D
//  Escolha a peça em PECA, F6 (render) e F7 (exportar STL). Medidas em mm.
//  X = largura (90), Y = profundidade (70, 0 = frente com a tela), Z = altura.
//  Primeiro protótipo: imprima a RODA e o CORPO, teste com BBs e ajuste as folgas.
//  ESTILO TÁTICO FACETADO · cores: corpo, tampas, roda e travas em PRETO ·
//  reservatório, bico e capas dos botões em COYOTE
// =====================================================================
use <../../_BIBLIOTECA-3D/bb_lib.scad>
$fn = 56;

PECA = "corpo";   // corpo | tampa_inferior | reservatorio | tampa_reservatorio | roda | trava_roda (x2) | trava_motor | bico_m4 | capa_botao (x2)

X = 90; Y = 70; Z = 110; P = 3;
EIXO = [30, 35, 75];         // centro da roda (eixo ao longo de X)
RODA_R = 15; RODA_E = 6.6;   // roda de 8 bolsos
TUBO = [30, 35];             // tubo de saída (vertical, desce da roda até o bico)
TUBO_D = 6.4;                // furo do tubo (BB de 6 mm)
RES_C = [45, 35];            // centro do reservatório
RES_DI = 60;
IR_Z = 30;                   // altura do sensor que conta as BBs
CANTOS = [[6, 6], [X - 6, 6], [6, Y - 6], [X - 6, Y - 6]];
RES_PARAF = 38;              // parafusos M3 que prendem o reservatório (38 mm para cada lado do centro)
RES_F = 67.2;                // reservatório octogonal: medida de face a face
FENDA = 16;                  // fenda de entrada das BBs, ao longo da borda da roda
LABIO = 2.5;                 // espessura do lábio flexível anti-pinçamento
C = 6;                       // chanfro dos cantos (estilo tático facetado)

// ===================== CORPO =====================
module corpo() {
    difference() {
        union() {
            intersection() {                                                              // casca facetada (aberta embaixo) + pinos, aparados pela forma de fora
                union() {
                    difference() { prisma_oct(X, Y, Z, C); translate([0, 0, -1]) linear_extrude(Z - P + 1) offset(delta = -P) oct2d(X, Y, C); }
                    for (c = CANTOS) translate([c[0], c[1], 0]) pino(20, 8, 2.6);
                    for (s = [-1, 1]) translate([RES_C[0] + s * RES_PARAF, RES_C[1], Z - 12]) cylinder(h = 12, d = 9);   // pinos dos parafusos do reservatório
                }
                translate([0, 0, -0.01]) prisma_oct(X, Y, Z + 0.02, C);
            }
            translate([20, 22, 58]) cube([50, 26, Z - 58 - 0.01]);                        // bloco do mecanismo (até o topo)
            translate([TUBO[0], TUBO[1], -11]) cylinder(h = 71, d = 14);                  // coluna do tubo (sai 8 mm por baixo da tampa)
            apoio_tela(P, 45, 50, normal = "y");                                          // apoios da OLED (sem cola; o bloco segura por cima)
            // visual tático (acrescentado por fora)
            translate([X - 0.01, 35, 38]) rotate([0, 90, 0]) difference() { moldura_oct(46, 2); translate([0, 0, -1]) cylinder(h = 4, d = 37); }   // anel que protege o gatilho
            for (xx = [25, 65]) translate([xx, 0.01, 36]) rotate([90, 0, 0]) moldura_oct(15, 2);   // molduras dos botões − e +
            translate([14, Y - 0.01, 8]) rotate([90, 0, 0]) mirror([0, 0, 1]) hex_relevo(62, 26, 1, 4);   // painel hexagonal (traseira)
        }
        // entrada das BBs (o bico do reservatório encaixa aqui) + rebaixo de assento do reservatório (octogonal)
        translate([EIXO[0], EIXO[1], EIXO[2]]) cylinder(h = 50, d = 8.4);
        translate([RES_C[0], RES_C[1], Z - 1.5]) octogono(RES_F + 0.6, 2);
        for (s = [-1, 1]) translate([RES_C[0] + s * RES_PARAF, RES_C[1], Z - 10]) cylinder(h = 11, d = 2.6);
        // câmara da roda + saída (embaixo, para o tubo)
        translate([EIXO[0] - RODA_E/2 - 0.4, EIXO[1], EIXO[2]]) rotate([0, 90, 0]) cylinder(h = RODA_E + 0.8, r = RODA_R + 0.6);
        translate([EIXO[0] - RODA_E/2 - 0.4, EIXO[1] - RODA_R - 0.6, EIXO[2]]) cube([RODA_E + 0.8, 2*RODA_R + 1.2, 40]);   // abre a câmara por cima (montagem da roda)
        translate([TUBO[0], TUBO[1], -12]) cylinder(h = EIXO[2] + 12, d = TUBO_D);
        // motor N20: entra por baixo do bloco, desliza 10 mm para a esquerda e o eixo encaixa na roda (a trava_motor segura por baixo)
        translate([EIXO[0] + RODA_E/2 + 0.4, EIXO[1] - 5.2, EIXO[2] - 6.2]) cube([45, 10.4, 12.4]);
        translate([EIXO[0] + RODA_E/2 + 0.4, EIXO[1] - 5.2, 57]) cube([45, 10.4, EIXO[2] - 6.2 - 57 + 0.01]);
        translate([EIXO[0] - 9, EIXO[1], EIXO[2]]) rotate([0, 90, 0]) cylinder(h = 19, d = 4);
        for (yy = [EIXO[1] - 9.5, EIXO[1] + 9.5]) translate([52, yy, 57]) cylinder(h = 11, d = 2.6);   // parafusos M3 da trava do motor   // passagem do eixo (sobra para a ponta do eixo do lado esquerdo)
        // sensor IR atravessando o tubo (LED de um lado, fototransistor do outro)
        translate([TUBO[0], TUBO[1] - 12, IR_Z]) rotate([-90, 0, 0]) cylinder(h = 7.6, d = 5.2);
        translate([TUBO[0], TUBO[1] + 4.4, IR_Z]) rotate([-90, 0, 0]) cylinder(h = 8, d = 5.2);
        translate([TUBO[0], TUBO[1] - 5, IR_Z]) rotate([-90, 0, 0]) cylinder(h = 10, d = 3);
        // frente: tela OLED 0,91" + rebaixo + botões − e +
        translate([45 - 11.5, -1, 50 - 3.2]) cube([23, P + 2, 6.4]);
        translate([45 - 14.5, -0.01, 50 - 6.2]) cube([29, 1.2, 12.4]);
        for (xx = [25, 65]) translate([xx, -3, 36]) rotate([-90, 0, 0]) cylinder(h = P + 4, d = 9.6);   // capas de 9 mm (a aba fica por dentro)
        // lateral direita: gatilho (botão arcade 30 mm)
        translate([X - P - 1, 35, 38]) rotate([0, 90, 0]) cylinder(h = P + 2, d = 30);
        // lateral esquerda: chave e USB-C
        translate([-1, 35 - 4.25, 22 - 1.8]) cube([P + 2, 8.5, 3.6]);
        translate([-1, 35 - 4.75, 12 - 1.9]) cube([P + 2, 9.5, 3.8]);
    }
}

// ===================== TAMPA INFERIOR (preta) =====================
module tampa_inferior() {        // face de fora em z = 0 (na mesa), borda chanfrada
    difference() {
        hull() { translate([0, 0, 1]) prisma_oct(X, Y, 2, C); linear_extrude(3) offset(delta = -1) oct2d(X, Y, C); }
        translate([TUBO[0], TUBO[1], 0]) furo(14.4);
        for (c = CANTOS) translate([c[0], c[1], 0]) { furo(3.4); translate([0, 0, -0.01]) cylinder(h = 1.8, d1 = 6.5, d2 = 3.4); }
    }
}

// ===================== RESERVATÓRIO (≈ 1000 BBs) =====================
module reservatorio() {          // coyote · fundo cônico que leva as BBs até a entrada da roda (15 mm à esquerda do centro)
    BOCA = [EIXO[0] - RES_C[0], EIXO[1] - RES_C[1]];
    difference() {
        union() {
            octogono(RES_F, 125);                                       // tanque octogonal: 3,6 mm de parede no meio de cada face
            for (s = [-1, 1]) hull() { translate([s * 28, 0, 1.5]) cylinder(h = 4, d = 12); translate([s * RES_PARAF, 0, 1.5]) cylinder(h = 4, d = 9); }   // orelhas dos parafusos
        }
        for (s = [-1, 1]) translate([s * RES_PARAF, 0, 0]) { furo(3.4, 10); translate([0, 0, 3.9]) cylinder(h = 1.62, d1 = 3.4, d2 = 6.5); }
        translate([0, 0, 45]) cylinder(h = 81, d = RES_DI);
        // funil até a fenda de entrada (7 x 16 mm, alinhada com a borda da roda)
        hull() { translate([0, 0, 45]) cylinder(h = 0.01, d = RES_DI); translate([BOCA[0] - 3.5, BOCA[1] - FENDA/2, 3]) cube([7, FENDA, 0.01]); }
        translate([BOCA[0] - 3.5, BOCA[1] - FENDA/2, -1]) cube([7, FENDA, 5]);
        // MARCA DO PROJETO (única): emblema + nome numa face (3,6 mm de parede; gravação de 0,6)
        // (a face tem 27,8 mm de largura: o nome vai na vertical, lendo de baixo para cima)
        translate([0, -RES_F/2 + 0.6, 58]) rotate([90, 0, 0]) rotate([0, 0, 90]) linear_extrude(1) text("BLACK BIRD", size = 7, font = "Liberation Sans:style=Bold", halign = "center", valign = "center");
        translate([0, -RES_F/2, 105]) rotate([90, 0, 0]) translate([0, 0, -0.6]) linear_extrude(0.62) emblema2d(1.05);
    }
}
module tampa_reservatorio() {    // preta
    difference() {
        union() { octogono(70, 3); cylinder(h = 8, d = RES_DI - 0.4); }
        translate([0, 0, 3]) cylinder(h = 10, d = RES_DI - 6);
    }
}

// ===================== RODA DE 8 BOLSOS =====================
module roda() {
    difference() {
        cylinder(h = RODA_E, r = RODA_R);
        for (a = [0 : 45 : 359]) rotate([0, 0, a]) translate([RODA_R - 2.6, 0, -1]) cylinder(h = RODA_E + 2, d = 6.6);
        translate([0, 0, -1]) intersection() { cylinder(h = RODA_E + 2, d = 3.1); translate([-2, -1.25 - 0.05, 0]) cube([4, 2.5 + 0.1 + 0.6, RODA_E + 2]); }  // eixo D de 3 mm
    }
}

// ===================== TRAVA DA RODA =====================
module trava_roda() {            // metade da frente, na posição de uso. IMPRIMA 2: a de trás é igual, virada.
    // As 2 metades fecham o rasgo de montagem da roda e deixam no meio uma FENDA de 16 mm ao longo da
    // borda da roda: as BBs deitam em cima da roda e ela mesma as mexe (agitação, evita BB embolada).
    // Na ponta de cada metade há um LÁBIO FLEXÍVEL (anti-pinçamento, ideia do Nano Speedloader):
    // se uma BB ficar presa entre o bolso da roda e a parede, o lábio cede em vez de quebrar a BB ou a roda.
    y0 = EIXO[1] - RODA_R - 0.4; y1 = EIXO[1] - FENDA/2;
    difference() {
        translate([EIXO[0] - RODA_E/2 - 0.2, y0, EIXO[2] + 6]) cube([RODA_E + 0.4, y1 - y0, Z - 1.5 - EIXO[2] - 6]);
        translate([EIXO[0] - 10, EIXO[1], EIXO[2]]) rotate([0, 90, 0]) cylinder(h = 20, r = RODA_R + 0.6, $fn = 96);
        translate([EIXO[0] - 10, y1 - LABIO - 0.8, EIXO[2] + 6 - 1]) cube([20, 0.8, 23 - 6 + 1]);   // fenda que solta o lábio (lábio de 2,5 mm, preso só em cima)
    }
}

// ===================== TRAVA DO MOTOR =====================
module trava_motor() {           // PRETA · placa embaixo do bloco + ressalto que empurra o motor para cima (2 parafusos M3 x 10)
    difference() {
        union() {
            translate([34, EIXO[1] - 12, 0]) prisma_oct(35, 24, 3, 2);
            translate([36, EIXO[1] - 4.9, 2.99]) cube([30, 9.8, (EIXO[2] - 6.2 - 58) - 0.4 + 0.01]);   // chega a 0,4 mm do motor
        }
        for (yy = [-9.5, 9.5]) translate([52, EIXO[1] + yy, 0]) { furo(3.4); translate([0, 0, -0.01]) cylinder(h = 1.8, d1 = 6.5, d2 = 3.4); }
    }
}

// ===================== BICO PARA CARREGADOR M4 =====================
module bico_m4() {               // encaixa na coluna do tubo (8 mm) e entra nos lábios do carregador M4
    // Ponta com RETENÇÃO (ideia do Nano Speedloader): os últimos 2 mm estreitam para 5,7 mm e a ponta
    // é dividida em 4 dedos. Sem carregador, as BBs não caem por gravidade; com o motor empurrando,
    // os dedos abrem e a BB passa.
    difference() {
        union() { octogono(20, 10); translate([0, 0, 9.99]) cylinder(h = 14, d = 8); }
        translate([0, 0, -0.01]) cylinder(h = 8, d = 14.3);
        translate([0, 0, -1]) cylinder(h = 10 + 14 - 2 + 1, d = TUBO_D);
        translate([0, 0, 21.99]) cylinder(h = 2.1, d1 = TUBO_D, d2 = 5.7);   // estreitamento da ponta
        for (a = [0, 90]) rotate([0, 0, a]) translate([-5, -0.4, 18]) cube([10, 0.8, 7]);   // 4 dedos flexíveis
        translate([0, -12, 4]) rotate([-90, 0, 0]) cylinder(h = 8, d = 2.6);   // parafuso M3 de trava (opcional)
    }
}

if (PECA == "corpo") translate([0, Y, Z]) rotate([180, 0, 0]) corpo();       // impresso de cabeça para baixo (topo na mesa)
if (PECA == "tampa_inferior") tampa_inferior();
if (PECA == "reservatorio") reservatorio();
if (PECA == "tampa_reservatorio") tampa_reservatorio();
if (PECA == "roda") roda();
if (PECA == "trava_roda") translate([0, -(EIXO[1] - RODA_R - 0.4), EIXO[0] + RODA_E/2 + 0.2]) rotate([0, 90, 0]) translate([0, 0, -EIXO[2] - 6]) trava_roda();   // deitada (lado plano na mesa)
if (PECA == "bico_m4") bico_m4();
if (PECA == "trava_motor") translate([0, 0, 0]) trava_motor();
if (PECA == "capa_botao") capa_botao(9, 0);
