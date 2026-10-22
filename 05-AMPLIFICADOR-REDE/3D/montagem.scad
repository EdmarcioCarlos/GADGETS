// 05 - AMPLIFICADOR DE REDE · MONTAGEM (só para os desenhos da prévia; não é para imprimir)
// x = largura, y = 0 na frente (y = Y encosta no poste), z = 0 embaixo
include <pecas.scad>
$fn = 40;
EXTRAS = true;           // false = só as peças impressas (usado para as cotas)
SEM_TAMPA = false;
CORTE = false;           // true = corta no meio (tira a metade da frente) para ver a placa
ANTENA = true;           // false = placa com a antena dela, furo fechado com o tampão
PECA = "nenhuma";

COR = "todas";
module pinta(c) {
    if (COR == "todas") color(c == 0 ? cor_preto() : cor_coyote()) children();
    else if (COR == (c == 0 ? "preto" : "coyote")) children();
}
module cortar() { if (CORTE) intersection() { children(); translate([-50, C3_Y - 0.5, -200]) cube([X + 100, 300, 500]); } else children(); }

pinta(0) render() cortar() caixa();
for (s = [-1, 1]) pinta(0) cortar() translate([s > 0 ? X/2 + C3[0]/2 + 0.4 - 3.4 : X/2 - C3[0]/2 - 0.4, C3_Y + C3[2] - 0.05, P + C3[1] + 0.2])
    rotate([90, 0, 0]) calco();                                                              // calços em cima da placa
if (!SEM_TAMPA) {
    pinta(1) render() cortar() translate([0, Y, Z + E]) rotate([180, 0, 0]) tampa();
    if (!ANTENA) pinta(1) cortar() translate([ANT[0], ANT[1], Z + E + 1.6]) rotate([180, 0, 0]) tampao_antena();
}
if (EXTRAS) cortar() {
    color("#1d3f73") translate([X/2 - C3[0]/2, C3_Y, P]) cube([C3[0], C3[2], C3[1]]);                 // ESP32-C3 SuperMini
    color("#b8bec2") translate([X/2 - 4.5, C3_Y + C3[2], P]) cube([9, 3.2, 7.5]);                      // USB-C
    color("#111") translate([X/2 - 3, C3_Y + C3[2], P + 10]) cube([6, 1, 6]);                          // chip
    color("#2b2b2b") translate([X/2 - 6, USB_Y - 3.5, -45]) cube([12, 7, 46]);                       // cabo do powerbank
    for (x = LEDS_X) {
        color("#2ea043") translate([x, 1, LEDS_Z]) rotate([90, 0, 0]) cylinder(h = 4.5, d = 3);         // LEDs
        color("#2ea043", 0.6) translate([x, -3.5, LEDS_Z]) sphere(d = 3);
    }
    if (ANTENA && !SEM_TAMPA) {
        color("#9aa4aa") translate([ANT[0], ANT[1], Z - 6]) cylinder(h = 16, d = 6.4);                   // RP-SMA de painel
        color("#9aa4aa") translate([ANT[0], ANT[1], Z + E]) cylinder(h = 2.5, d = 9, $fn = 6);          // porca
        color("#1a1a1a") translate([ANT[0], ANT[1], Z + E + 4]) { cylinder(h = 14, d = 9); translate([0, 0, 14]) cylinder(h = 92, d1 = 10, d2 = 8); }   // antena 3 dBi
        color("#c9a227") translate([X/2 + 5, C3_Y + 2, P + 20]) cylinder(h = Z - P - 26, d = 1.4);     // cabinho IPEX
    }
}
