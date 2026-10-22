// =====================================================================
//  03 - NÍVEL ANTI-CANT · peças 3D · ESTILO TÁTICO FACETADO
//  Escolha a peça em PECA, F6 (render) e F7 (exportar STL). Medidas em mm.
//  Cores: caixa, pod e garra fixa em PRETO · tampa e mandíbula em COYOTE.
// =====================================================================
use <../../_BIBLIOTECA-3D/bb_lib.scad>
$fn = 48;

PECA = "caixa";   // caixa | tampa | mandibula | pod

// ---------- medidas ----------
X = 50; Y = 30;          // caixa por fora (paredes de 3 mm, resistentes a BB a 10 m+)
H = 19;                  // corpo; a tampa de 4 mm completa 23
P = 3;
C = 4;                   // chanfro dos cantos (estilo tático)
E_TAMPA = 4;             // 3 mm úteis + 1 mm para as gravações decorativas
TUBO_D = 30;             // CONFIRA: tubo da luneta (30 mm; use 25.4 para 1")
CANTOS = [[5, 5], [X - 5, 5], [5, Y - 5], [X - 5, Y - 5]];

// Picatinny (padrão MIL-STD-1913)
TRILHO_L = 21.2;         // largura do topo do trilho
GARRA_H = 6.4;           // altura da garra abaixo da caixa

// ===================== CAIXA COM GARRA FIXA =====================
module garra(lado) {     // lado = -1 (fixa) ou +1 (móvel); perfil 45° que agarra o trilho
    mirror([0, lado > 0 ? 1 : 0, 0])
    rotate([90, 0, 90]) linear_extrude(20)
        polygon([[-TRILHO_L/2 - 4, 0], [-TRILHO_L/2 + 0.2, 0], [-TRILHO_L/2 + 3, -2.8],
                 [-TRILHO_L/2 + 3, -GARRA_H], [-TRILHO_L/2 - 4, -GARRA_H]]);
}
module caixa_ac() {
    difference() {
        union() {
            caixa_tatica(X, Y, H, P, P, C) for (c = CANTOS) translate([c[0], c[1], 0]) pino(H, 7, 2.6);   // pinos da tampa (M3)
            translate([X/2 - 10, Y/2, 0]) garra(-1);                              // garra fixa (lado esquerdo)
            translate([12, 0.01, 10]) rotate([90, 0, 0]) moldura_oct(15, 2);      // moldura que protege o ZERAR
            translate([8, Y - 0.01, 4]) rotate([90, 0, 0]) mirror([0, 0, 1]) hex_relevo(34, 11, 1);   // painel hexagonal (lado direito)
        }
        // parafuso M3 atravessado (passa na fenda do trilho)
        translate([X/2, -10, -2.6]) rotate([-90, 0, 0]) cylinder(h = Y + 20, d = 3.4);
        // lateral esquerda: botão ZERAR e chave liga/desliga
        translate([12, -3, 10]) rotate([-90, 0, 0]) cylinder(h = P + 4, d = 7.4);
        translate([36.25 - 4.5, -1, 8.2]) cube([9, P + 2, 4]);
        // traseira: USB-C e saída do cabo
        translate([X - P - 1, Y/2 - 4.9, 5]) cube([P + 2, 9.8, 4]);
        translate([X - P - 1, 8, 12]) rotate([0, 90, 0]) cylinder(h = P + 2, d = 3.2);
    }
}

// ===================== TAMPA (coyote) =====================
module tampa_ac() {      // impressa com a face de fora na mesa
    difference() {
        tampa_tatica(X, Y, E_TAMPA, P, 2.5, C, 1.2);
        for (c = CANTOS) translate([c[0], c[1], 0]) { furo(3.4); translate([0, 0, E_TAMPA]) cylinder(h = 4, d = 7.6); }
        nervuras_baixo(X - 9, Y/2, 3, 4, 14, 0.8, 180);                 // nervuras em V apontando para o cano
        logo_baixo(X/2 - 7, Y/2 - 6, 3.4, prof = 0.8);
        emblema_baixo(X/2 - 7, Y/2 + 5, 0.55, 0.8);
    }
}

// ===================== MANDÍBULA MÓVEL (coyote) =====================
module mandibula() {     // garra móvel: o parafuso M3 puxa ela contra o trilho
    difference() {
        union() {
            garra(1);
            translate([0, TRILHO_L/2 + 4, -GARRA_H]) cube([20, 5, GARRA_H]);   // reforço com a porca
        }
        translate([10, -30, -2.6]) rotate([-90, 0, 0]) cylinder(h = 60, d = 3.4);
        translate([10, TRILHO_L/2 + 6.5, -2.6]) rotate([-90, 0, 0]) cylinder(h = 3, d = 6.6, $fn = 6);   // porca M3
    }
}

// ===================== POD DE LEDS + ABRAÇADEIRA =====================
module pod() {          // impresso deitado: eixo do tubo em Z
    R = TUBO_D/2 + 0.2;
    difference() {
        union() {
            cylinder(h = 8, r = R + 3);
            translate([-R - 3 - 10, -11, 0]) prisma_oct(12, 22, 8, 2.5);        // coluna dos LEDs (9 h), entra 2 mm no anel
            // orelhas do aperto SEMPRE do lado oposto aos LEDs (3 h): o topo do tubo fica livre para o telêmetro
            translate([R + 1, -4, 0]) prisma_oct(9, 8, 8, 1.5);
        }
        translate([0, 0, -1]) cylinder(h = 10, r = R);
        translate([R - 1, -0.8, -1]) cube([12, 1.6, 10]);                // corte do aperto
        translate([R + 6, -10, 4]) rotate([-90, 0, 0]) cylinder(h = 20, d = 3.2);   // parafuso M3
        for (yy = [-7, 0, 7]) translate([-R - 3 - 5, yy, -1]) cylinder(h = 10, d = 3.1);   // LEDs 3 mm
        translate([-R - 3 - 5, -9, 4]) rotate([90, 0, 0]) cylinder(h = 6, d = 3.4);        // cabo
    }
}

if (PECA == "caixa") translate([0, 0, GARRA_H]) caixa_ac();
if (PECA == "tampa") tampa_ac();
if (PECA == "mandibula") translate([0, 0, GARRA_H]) mandibula();
if (PECA == "pod") pod();
