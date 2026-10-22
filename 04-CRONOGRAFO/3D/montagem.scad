// 04 - CRONÓGRAFO · MONTAGEM (só para os desenhos da prévia; não é para imprimir)
use <pecas.scad>
use <../../_BIBLIOTECA-3D/bb_lib.scad>
$fn = 64;
L = 160; W = 44; H = 66; FZ = 45.5;
EXTRAS = true;           // false = só as peças impressas (usado para as cotas)

CORTE = false;                     // true = corta ao meio (y < 22) para ver o túnel, as barreiras e a baia
module tudo() {
color(cor_preto()) tunel();
color(cor_coyote()) translate([0, 0, H]) visor();
color(cor_preto()) translate([0, 0, -3]) tampa_inferior();
// adaptador de boca: colar para a frente (-x), centrado no túnel
color(cor_preto()) multmatrix([[0, 0, -1, 0], [1, 0, 0, W/2], [0, 1, 0, FZ], [0, 0, 0, 1]]) adaptador_boca();
if (EXTRAS) {                                                                       // componentes (referência)
    for (bx = [30, 130]) {
        color("#3d6fd6") translate([bx, W/2, FZ + 12.5 + 2.5]) cylinder(h = 9, d = 5);   // LED infravermelho (em cima)
        color("#111111") translate([bx, W/2, 27 - 1]) cylinder(h = 9, d = 5);             // fototransistor (embaixo)
    }
    color("#c9a227") translate([40, 4, 2]) cube([77, 21, 20]);                          // suporte 18650
    color("#202020") translate([10, 6, 4]) cube([22.5, 18, 1.6]);                       // ESP32-C3
    color("#2b6a8f") translate([122, 6, 4]) cube([24, 16, 1.6]);                        // LM393 + trimpots
    color("#7a1f1f") translate([10, 26, 4]) cube([28, 13, 1.6]);                        // TP4056
}
}
if (CORTE) intersection() { tudo(); translate([-50, -1, -50]) cube([300, W/2 + 1, 200]); } else tudo();
