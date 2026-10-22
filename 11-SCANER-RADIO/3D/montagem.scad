// 11 - SCANNER · MONTAGEM (só para os desenhos da prévia; não é para imprimir)
// a frente (tela e botão) fica para cima (+z); a antena sai no topo (y = 112)
use <pecas.scad>
use <../../_BIBLIOTECA-3D/bb_lib.scad>
$fn = 48;
EXTRAS = true;           // false = só as peças impressas (usado para as cotas)
SEM_TAMPA = false;       // true = mostra o interior
X = 62; Y = 112; H = 31;

color(cor_preto()) corpo();
if (!SEM_TAMPA) color(cor_coyote()) translate([X, 0, H + 4]) rotate([0, 180, 0]) tampa_frente();
color(cor_preto()) translate([31 - 12.5, 45 - 15, 0]) mirror([0, 0, 1]) clipe_molle();     // clipe nas costas
if (EXTRAS && !SEM_TAMPA) color("#0b0f14") translate([31 - 11.2, 88.5 - 5.7, H + 4 - 1.3]) cube([22.4, 11.4, 0.5]);   // tela
if (EXTRAS && !SEM_TAMPA) color(cor_coyote()) translate([31, 62, H + 4]) cylinder(h = 2, d = 9.6);                        // botão
if (EXTRAS) color("#9aa0a4") translate([46, Y, 15]) rotate([-90, 0, 0]) cylinder(h = 60, d = 8);              // antena (início)
if (EXTRAS && SEM_TAMPA) {                                                                                 // interior
    color("#c9a227") translate([4, 5, 3]) cube([29, 98, 21]);                                           // módulo 18650 (suporte + carga + 5 V)
    color("#202020") translate([33, 22, 12]) cube([25.5, 55, 1.6]);                                     // ESP32 DevKit
    color("#1d3f73") translate([36, 86, 18]) cube([22, 22, 1.6]);                                       // CC1101
    color("#7d8388") translate([46, 12, 3]) cylinder(h = 3, d = 10);                                    // motor de vibração
}
