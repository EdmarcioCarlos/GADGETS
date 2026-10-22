// 03 - ANTI-CANT · MONTAGEM (só para os desenhos da prévia; não é para imprimir)
// PARTE = "unidade" (caixa no trilho) ou "pod" (anel de LEDs no tubo da luneta)
use <pecas.scad>
use <../../_BIBLIOTECA-3D/bb_lib.scad>
$fn = 48;
EXTRAS = true;           // false = só as peças impressas (usado para as cotas)
PARTE = "unidade";
SEM_TAMPA = false;
X = 50; Y = 30; H = 19; E_TAMPA = 4;

module trilho(comp = 64) {
    color("#5a5f63") translate([-7, Y/2, 0]) rotate([90, 0, 90]) linear_extrude(comp)
        polygon([[-10.6, 0], [10.6, 0], [10.6, -2.8], [7.8, -5.6], [7.8, -9.4], [-7.8, -9.4], [-7.8, -5.6], [-10.6, -2.8]]);
}
if (PARTE == "unidade") {
    if (EXTRAS) trilho();
    pinta(0) caixa_ac();
    if (!SEM_TAMPA) pinta(1) translate([0, Y, H + E_TAMPA]) rotate([180, 0, 0]) tampa_ac();
    if (SEM_TAMPA && EXTRAS) {                                                     // interior (referência)
        color("#c9a227") translate([5, 5, 3]) cube([40, 20, 5]);                   // bateria (embaixo)
        color("#1d3f73") translate([5, 7, 8]) cube([20.5, 16, 1.6]);               // MPU6050
        color("#202020") translate([26, 6, 8]) cube([18, 22.5 - 4.5, 1.6]);        // ESP32-C3
        color("#7a1f1f") translate([27, 8, 11]) cube([17, 14, 1.6]);               // TP4056 (por cima)
    }
    pinta(1) translate([X/2 - 10, Y/2, 0]) mandibula();
    if (EXTRAS) pinta(1) translate([12, -2, 10]) rotate([90, 0, 0]) cylinder(h = 1.5, d = 6.6);   // botão ZERAR
}
if (PARTE == "pod") {
    pinta(0) pod();
    if (EXTRAS) color("#7d8388") translate([0, 0, -6]) cylinder(h = 20, d = 30);          // tubo da luneta (30 mm)
    if (EXTRAS) for (yy = [-7, 0, 7]) color(yy == 0 ? "#3fbf5f" : "#d23a2c") translate([-15.2 - 3 - 5, yy, 8]) cylinder(h = 1.5, d = 3);   // LEDs
}

// --- filtro de cor (usado pela prévia geral no AEG: exporta só as peças pretas ou só as coyote) ---
COR = "todas";   // "todas" | "preto" | "coyote"
module pinta(c) {
    if (COR == "todas") color(c == 0 ? cor_preto() : cor_coyote()) children();
    else if (COR == (c == 0 ? "preto" : "coyote")) children();
}