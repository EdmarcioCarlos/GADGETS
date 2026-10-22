// 01 - BOMBA · MONTAGEM (só para os desenhos da prévia; não é para imprimir)
use <pecas.scad>
use <../../_BIBLIOTECA-3D/bb_lib.scad>
$fn = 40;
EXTRAS = true;           // false = só as peças impressas (usado para as cotas)
X = 210; Y = 150; H = 82; E_PAINEL = 4;
BORNES_X = [110, 130, 150, 170];

color(cor_preto()) caixa_bomba();
SEM_PAINEL = false;
if (!SEM_PAINEL) color(cor_coyote()) translate([0, 0, H - 3]) painel_uso();
if (SEM_PAINEL && EXTRAS) {                                                             // interior (referência)
    color("#1d5aa6") translate([9, 85.6, 9]) cube([68.6, 53.4, 1.6]);                  // Arduino Uno
    color("#c9a227") translate([210 - 3 - 21.6 + 2.4, 18, 3]) cube([19, 84, 72]);      // suporte 6xAA em pé
    color("#33383c") translate([80, 4, 15]) cube([50, 22, 32]);                        // sirene piezo
    color("#2b6a8f") translate([90, 90, 3]) cube([26, 17, 18]);                        // relé
}
if (!SEM_PAINEL) color(cor_preto()) translate([55 - 40, 119 - 18, H + E_PAINEL]) moldura_lcd();
color(cor_preto()) translate([0, 15, 63]) rotate([0, 0, 90]) alca();
if (!SEM_PAINEL) for (bx = BORNES_X) color(cor_preto()) translate([bx, 22, H + E_PAINEL + 1.5]) rotate([180, 0, 0]) passa_fios();
// componentes (só para referência visual)
if (EXTRAS && !SEM_PAINEL) color("#2c5d9c") translate([55 - 32, 119 - 8, H + E_PAINEL - 0.6]) cube([64, 16, 0.8]);                       // LCD
if (EXTRAS && !SEM_PAINEL) color("#33383c") translate([20.6, 16.6, H + E_PAINEL - 0.3]) cube([67.8, 75.8, 0.8]);                         // teclado
if (EXTRAS && !SEM_PAINEL) color("#b3261e") translate([170, 119, H + E_PAINEL]) cylinder(h = 6, d = 24);                                // botão arcade
if (EXTRAS && !SEM_PAINEL) for (i = [0:3]) color(i % 2 ? "#1a1a1a" : "#b3261e") translate([BORNES_X[i], 59, H + E_PAINEL]) cylinder(h = 8, d = 9);   // bornes
if (EXTRAS && !SEM_PAINEL) color("#e5533f") translate([125, 120, H + E_PAINEL]) cylinder(h = 2, d = 3);                                 // LED
