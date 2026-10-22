// 12 - TELÊMETRO · MONTAGEM (só para os desenhos da prévia; não é para imprimir)
// x = 0 frente (capuz), x = 76 traseira (tela); y = 0 lado direito do rifle
use <pecas.scad>
use <../../_BIBLIOTECA-3D/bb_lib.scad>
$fn = 48;
EXTRAS = true;           // false = só as peças impressas (usado para as cotas)
SEM_TAMPA = false;       // true = mostra o interior
L = 76; W = 44; H = 18; P = 3; ALT_BASE = 24;

pinta(0) corpo();
if (!SEM_TAMPA) pinta(1) translate([0, 0, H - 2.5]) tampa_uso();
pinta(0) translate([0.5, P + 0.3, P + 0.3]) multmatrix([[0, 0, 1, 0], [1, 0, 0, 0], [0, 1, 0, 0], [0, 0, 0, 1]]) grade();
pinta(1) translate([33, 22, -(ALT_BASE + 4)]) tampa_anel();
if (EXTRAS) color("#7d8388") translate([-25, 22, -(ALT_BASE + 4)]) rotate([0, 90, 0]) cylinder(h = 120, d = 30);   // tubo da luneta
if (EXTRAS) color("#0b0f14") translate([L - 0.4, W/2 - 11.5, 10.5 - 3.2]) cube([0.5, 23, 6.4]);                   // tela
if (EXTRAS && SEM_TAMPA) {                                                                                     // interior
    color("#8a8f94") translate([10, 4, 4]) cube([27.5, 25, 12.8]);                                          // laser JC02-1
    color("#c9a227") translate([39, 7, 3]) cube([20, 30, 5]);                                               // LiPo 600 mAh
    color("#202020") translate([39, 5, 8]) cube([18, 22.5, 1.6]);                                           // ESP32-C3
    color("#7a1f1f") translate([40, 28, 8]) cube([17, 12.5, 1.6]);                                          // TP4056
    color("#0b0f14") translate([L - 3 - 3.2, W/2 - 19, 4.5]) cube([3, 38, 12]);                             // OLED 0,91"
}

// --- filtro de cor (usado pela prévia geral no AEG: exporta só as peças pretas ou só as coyote) ---
COR = "todas";   // "todas" | "preto" | "coyote"
module pinta(c) {
    if (COR == "todas") color(c == 0 ? cor_preto() : cor_coyote()) children();
    else if (COR == (c == 0 ? "preto" : "coyote")) children();
}
