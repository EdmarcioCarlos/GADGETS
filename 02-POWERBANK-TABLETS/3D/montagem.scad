// 02 - POWERBANK · MONTAGEM (só para os desenhos da prévia; não é para imprimir)
// x = largura, y = 0 na frente (y = Y encosta no poste), z = 0 embaixo
include <pecas.scad>
$fn = 40;
EXTRAS = true;           // false = só as peças impressas (usado para as cotas)
SEM_TAMPA = false;
CORTE = false;           // true = corta no meio (tira o lado direito) para ver a placa e o cartucho
CARTUCHO_FORA = false;   // true = cartucho puxado para cima (troca)
PARTE = "powerbank";     // "powerbank" ou "poste" (tablet + powerbank + rádio no poste)
PECA = "nenhuma";        // desliga as saídas do pecas.scad

COR = "todas";
module pinta(c) {
    if (COR == "todas") color(c == 0 ? cor_preto() : cor_coyote()) children();
    else if (COR == (c == 0 ? "preto" : "coyote")) children();
}
module cortar() { if (CORTE) intersection() { children(); translate([-50, -50, -100]) cube([X/2 + 50, Y + 200, 400]); } else children(); }

CX0 = (X - CART_W) / 2;
SOBE = CARTUCHO_FORA ? 70 : 0;
module no_cartucho() { translate([CX0 + CART_W, ZONA_Y[0], P + SOBE]) rotate([90, 0, 180]) children(); }   // coordenadas do cartucho -> caixa

module powerbank() {
    pinta(0) render() cortar() caixa();
    if (!SEM_TAMPA) {
        pinta(1) render() cortar() translate([0, Y, Z + E]) rotate([180, 0, 0]) tampa();
        for (i = APERTO) pinta(1) cortar() translate([CANTOS[i][0], Y - CANTOS[i][1], Z + E]) botao_aperto();
    }
    pinta(0) render() cortar() no_cartucho() cartucho();
    for (s = [-1, 1]) pinta(0) cortar() translate([s > 0 ? X/2 + PLACA[0]/2 + 0.4 - 4 : X/2 - PLACA[0]/2 - 0.4, PLACA_Y + PLACA[2] - 0.05, P + PLACA[1] + 0.2])
        rotate([90, 0, 0]) calco();                                                          // calços em cima da placa
    if (EXTRAS) cortar() {
        // placa de power bank em pé, saídas para baixo
        color("#1f6f3a") translate([X/2 - PLACA[0]/2, PLACA_Y, P]) cube([PLACA[0], PLACA[2], PLACA[1]]);
        color("#1d3f73") translate([X/2 - 11, PLACA_Y - 2, P + TELA_Z - 5]) cube([22, 2, 10]);                       // tela de carga
        for (dx = [-17, -1]) color("#b8bec2") translate([X/2 + dx, PLACA_Y - 7, P]) cube([13.2, 7, 14]);             // 2 USB-A
        color("#b8bec2") translate([X/2 + 15, PLACA_Y - 3.2, P]) cube([9, 3.2, 7]);                                   // entrada USB-C
        // cabos USB saindo por baixo
        for (dx = [-10.4, 5.6]) color("#2b2b2b") translate([X/2 + dx, PLACA_Y - 3.5, -40]) { cube([12, 4.5, 42], center = false); }
        // suportes 18650 + baterias + fitas de velcro + XT30
        no_cartucho() {
            for (k = [0 : 2]) translate([CART_PAREDE[0] + k * (SUP[1] + CART_PAREDE[1]) + 0.3, 2, CART_BASE]) {
                color("#151515") difference() { cube([SUP[1] - 0.6, SUP[0], 12]); translate([1.2, 3, 1.2]) cube([SUP[1] - 3, SUP[0] - 6, 12]); }
                color("#2c64b5") translate([(SUP[1] - 0.6)/2, 6, 10]) rotate([-90, 0, 0]) cylinder(h = 65, d = 18.4);
            }
            for (fy = FITAS_Y) color("#3a3f2c") translate([-0.6, fy - 12.5, -0.4]) difference() {
                cube([CART_W + 1.2, 25, CART_BASE + 20 + 1.6]);
                translate([0.8, -1, 1]) cube([CART_W - 0.4, 27, CART_BASE + 19.4]);
            }
            color("#e8c21a") translate([CART_W - 16, CART_L + 2, CART_BASE]) cube([8, 16, 10]);                     // XT30
        }
    }
}

if (PARTE == "powerbank") powerbank();
else {
    // conjunto no poste: tablet 10" em pé, powerbank embaixo, rádio (projeto 05) em cima, fitas de velcro
    PY = Y + 13 + 40;                                                     // centro do poste (Ø 80)
    color("#6b5a45") translate([X/2, PY, -150]) cylinder(h = 620, d = 80);
    translate([0, 0, 0]) powerbank();
    for (z = [26, 76]) color("#3a3f2c") translate([X/2, PY, z - 12.5]) difference() { cylinder(h = 25, d = 84); translate([0, 0, -1]) cylinder(h = 27, d = 80); }
    // tablet (240 x 160 x 9) num suporte simples, em cima do powerbank
    color("#111") translate([X/2 - 120, Y - 2, 130]) cube([240, 9, 160]);
    color("#22324a") translate([X/2 - 112, Y - 2.2, 138]) cube([224, 0.4, 144]);
    for (z = [170, 250]) color("#3a3f2c") translate([X/2, PY, z]) difference() { cylinder(h = 25, d = 84); translate([0, 0, -1]) cylinder(h = 27, d = 80); }
    // rádio (05) em cima, com a antena
    color(cor_preto()) translate([X/2 - 18, Y - 26 + 8, 320]) cube([36, 26, 64]);
    color(cor_coyote()) translate([X/2 - 18, Y - 26 + 8, 384]) cube([36, 26, 4]);
    color("#1a1a1a") translate([X/2, Y - 26 + 8 + 17, 388]) cylinder(h = 110, d = 10);
}
