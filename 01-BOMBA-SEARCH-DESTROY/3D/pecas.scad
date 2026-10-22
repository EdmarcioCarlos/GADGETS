// =====================================================================
//  01 - BOMBA SEARCH & DESTROY · peças 3D
//  Escolha a peça em PECA e aperte F6 (render) e F7 (exportar STL).
//  Medidas em mm. Confira com paquímetro as peças marcadas "CONFIRA".
//  ESTILO TÁTICO FACETADO · cores: caixa, alça, moldura do LCD e passa-fios
//  em PRETO · painel em COYOTE
// =====================================================================
use <../../_BIBLIOTECA-3D/bb_lib.scad>
$fn = 48;

PECA = "caixa";   // caixa | painel | moldura_lcd | alca | passa_fios

// ---------- medidas gerais ----------
X = 210; Y = 150;          // caixa por fora
H = 82;                    // altura da caixa (o painel de 3 mm completa 85)
P = 3;                     // parede (resistente a BB a mais de 10 m)
C = 8;                     // chanfro dos cantos (estilo tático facetado)
E_PAINEL = 4;              // painel

// ---------- peças compradas (CONFIRA) ----------
UNO_X0 = 9;  UNO_Y0 = 85.6;               // canto do Uno (USB virado para a parede esquerda)
UNO_FUROS = [[13.97,2.54],[15.24,50.8],[66.04,7.62],[66.04,35.56]];
ARCADE_D = 30;       // furo do botão arcade
BANANA_D = 6.5;      // furo do borne banana
LED_D = 3.2;         // LED de 3 mm (padrão de todos os projetos)

// coordenadas do painel vistas de cima (X da esquerda p/ direita, Y da frente p/ trás)
BORNES_X = [110, 130, 150, 170];
CANTOS = [[8,8],[X-8,8],[8,Y-8],[X-8,Y-8]];

// ===================== CAIXA =====================
module caixa_bomba() {
    difference() {
        union() {
            caixa_tatica(X, Y, H, P, P, C) {
                for (c = CANTOS) translate([c[0], c[1], 0]) pino(H, 9, 2.6);       // pinos dos parafusos do painel
                // guias do suporte de pilhas (em pé na parede direita; 6 mm para trás, longe do canto chanfrado)
                translate([X - P - 21.6, 16, 0]) cube([2.4, 88, 30]);
                translate([X - P - 21.6, 10, 0]) cube([21.6, 2, 30]);
                translate([X - P - 21.6, 108, 0]) cube([21.6, 2, 30]);
            }
            for (f = UNO_FUROS) translate([UNO_X0 + f[0], UNO_Y0 + f[1], 0]) pino(P + 6, 6, 2.6);  // espaçadores do Uno
            // painéis hexagonais em relevo na frente, um de cada lado da grade da sirene
            for (x0 = [14, 130]) translate([x0, 0.01, 10]) rotate([90, 0, 0]) hex_relevo(66, 42, 1, 5);
        }
        // janela da chave do suporte de pilhas (parede direita)
        translate([X - P - 1, 46, 33]) cube([P + 2, 28, 14]);
        // USB do Uno (parede esquerda)
        translate([-1, UNO_Y0 + 30.5, 9]) cube([P + 2, 14.5, 14]);
        // grade da sirene (parede da frente)
        for (i = [-3:3], j = [-3:3]) if (i*i + j*j <= 10)
            translate([105 + i*6, -1, 30 + j*6]) rotate([-90, 0, 0]) cylinder(h = P + 2, d = 4);
        // furos da alça (parede esquerda)
        for (yy = [21, 79]) translate([-1, yy, 70]) rotate([0, 90, 0]) cylinder(h = P + 2, d = 3.4);
        // nome + emblema
    }
}

// ===================== PAINEL (tampa) =====================
module painel_uso() {           // na posição de uso: face de cima em z = 3 + E_PAINEL
    difference() {
        union() {
            translate([0, 0, 3]) placa_chanfrada(E_PAINEL, 1.2) oct2d(X, Y, C);
            // aba que encaixa por dentro das paredes
            linear_extrude(3.01) difference() {
                offset(delta = -(P + 0.3)) oct2d(X, Y, C);
                offset(delta = -(P + 0.3 + 1.6)) oct2d(X, Y, C);
            }
        }
        // cantos da aba livres para os pinos
        for (c = CANTOS) translate([c[0], c[1], -1]) cylinder(h = 3.5, d = 10.5);
        // furos dos parafusos (com rebaixo para a cabeça)
        for (c = CANTOS) translate([c[0], c[1], 0]) { furo(3.4); translate([0,0,3 + E_PAINEL - 1.6]) cylinder(h = 2, d1 = 3.4, d2 = 6.5); }
        // LCD: janela + 4 furos
        translate([55, 119, 0]) furo_rect(64.5, 16);
        rebaixo_janela(55, 119, 3 + E_PAINEL, 64.5, 16);   // policarbonato 1 mm protege o LCD
        for (xx = [17.5, 92.5], yy = [103.5, 134.5]) translate([xx, yy, 0]) furo(3.2);
        // fenda do rabicho do teclado
        translate([54.5, 13.5, 0]) furo_rect(20, 3);
        // contorno do teclado (guia para colar, 0,4 mm)
        translate([0, 0, 3 + E_PAINEL - 0.4]) difference() {
            translate([20, 16, 0]) cube([69, 77, 1]);
            translate([20.6, 16.6, -0.1]) cube([67.8, 75.8, 1.2]);
        }
        translate([125, 120, 0]) furo(LED_D);                          // LED
        translate([170, 119, 0]) furo(ARCADE_D);                       // botão arcade
        for (bx = BORNES_X) translate([bx, 59, 0]) furo(BANANA_D);     // bornes
        for (bx = BORNES_X) translate([bx, 22, 0]) furo(8);            // passa-fios
        logo_topo(170, 84, 3 + E_PAINEL, 7);
        emblema_topo(170, 95.5, 3 + E_PAINEL, 1.0, 0.8);          // MARCA DO PROJETO (única): emblema + nome no painel
    }
}

// ===================== MOLDURA DO LCD =====================
module moldura_lcd() {
    difference() {
        prisma_oct(80, 36, 2, 1.5);
        translate([40, 18, 0]) furo_rect(66, 18);
        for (xx = [2.5, 77.5], yy = [2.5, 33.5]) translate([xx, yy, 0]) { furo(3.2); translate([0,0,1]) cylinder(h = 1.1, d1 = 3.2, d2 = 6); }
    }
}

// ===================== ALÇA (parede esquerda) =====================
module alca() {          // impressa deitada; os 2 pés encostam na parede
    difference() {
        linear_extrude(14) offset(delta = 2, chamfer = true) offset(delta = -2) union() {   // cantos chanfrados
            square([12, 24]);
            translate([58, 0]) square([12, 24]);
            translate([0, 14]) square([70, 10]);
        }
        for (xx = [6, 64]) translate([xx, -1, 7]) rotate([-90, 0, 0]) cylinder(h = 13, d = 2.6);
    }
}

// ===================== PASSA-FIOS =====================
module passa_fios() {
    difference() {
        union() { rotate([0, 0, 22.5]) cylinder(h = 1.5, d = 12, $fn = 8); cylinder(h = 1.5 + E_PAINEL, d = 7.8); }
        furo(4.2);
    }
}

// ===================== escolha =====================
if (PECA == "caixa") caixa_bomba();
if (PECA == "painel") translate([0, Y, 3 + E_PAINEL]) rotate([180, 0, 0]) painel_uso();   // impresso com a face de cima na mesa
if (PECA == "moldura_lcd") moldura_lcd();
if (PECA == "alca") alca();
if (PECA == "passa_fios") passa_fios();
