// 09 - ALVO ACIONADOR · MONTAGEM (só para os desenhos da prévia; não é para imprimir)
// x = largura, y = 0 na frente (y = Y encosta no poste/parede), z = 0 embaixo
include <pecas.scad>
$fn = 40;
EXTRAS = true;           // false = só as peças impressas (usado para as cotas)
SEM_TAMPA = false;
ACESO = false;           // true = refletor aceso (cena do campo)
PARTE = "alvo";          // "alvo" | "acionador" | "campo"
PECA = "nenhuma";

COR = "todas";
module pinta(c) {
    if (COR == "todas") color(c == 0 ? cor_preto() : cor_coyote()) children();
    else if (COR == (c == 0 ? "preto" : "coyote")) children();
}
module no_alvo() { translate([ALVO_X0 + ALVO, -ALVO_E, ALVO_Z0]) rotate([90, 0, 180]) children(); }   // frente do alvo para fora

module unidade_alvo() {
    pinta(0) render() caixa_alvo();
    pinta(1) render() no_alvo() alvo();
    pinta(0) translate([ALVO_C[0], 12, ALVO_C[1]]) rotate([90, 0, 0]) trava_piezo();
    if (!SEM_TAMPA) pinta(1) render() translate([0, YA, ZA + E]) rotate([180, 0, 0]) tampa_alvo();
    if (EXTRAS) {
        color("#c9a227") translate([ALVO_C[0], 0.6, ALVO_C[1]]) rotate([90, 0, 0]) cylinder(h = 0.6, d = 27);        // disco piezo
        color("#e8e0c8") translate([ALVO_C[0], 7, ALVO_C[1]]) rotate([90, 0, 0]) cylinder(h = 6.4, d = 24);          // espuma
        color("#151515") translate([SUP_X0, (YA - SUP_A[1]) / 2, SUP_Z0]) difference() { cube([SUP_A[0], SUP_A[1], 12]); translate([3, 1.2, 1.2]) cube([SUP_A[0] - 6, SUP_A[1] - 2.4, 12]); }
        color("#2c64b5") translate([SUP_X0 + 6, YA/2, SUP_Z0 + 10]) rotate([0, 90, 0]) cylinder(h = 65, d = 18.4);   // 18650
        color("#2e7d32") translate([XA/2 - 30, YA - P - 4 - 1.6, PLACA_A_Z0]) cube([PLACA_A[0], 1.6, PLACA_A[1]]);    // placa ilhada
        color("#1d3f73") translate([XA/2 - 14, YA - P - 4 - 1.6 - 3, 30]) cube([18, 3, 22.5]);                        // ESP32-C3
        color("#7a1f1f") translate([TP_X - TP[0]/2, TP_Y, P]) cube([TP[0], TP[2], TP[1]]);                            // TP4056
        color("#b8bec2") translate([TP_X - 4.5, TP_Y + TP[2], P]) cube([9, 3.2, 7.5]);                                // USB-C
        for (z = CHAVES_A) color("#9aa4aa") translate([XA, 17, z]) rotate([0, 90, 0]) cylinder(h = 10, d = 2.5);
        color("#ff5040") translate([LED_A[0], 1, LED_A[1]]) rotate([90, 0, 0]) cylinder(h = 4.5, d = 3);
    }
}

module unidade_acionador() {
    pinta(0) render() caixa_acionador();
    if (!SEM_TAMPA) pinta(1) render() translate([0, YB, ZB + E]) rotate([180, 0, 0]) tampa_acionador();
    pinta(1) translate([BOTAO_B[0], -2.5, BOTAO_B[1]]) rotate([-90, 0, 0]) capa_botao(9, 0, 4);
    if (EXTRAS) {
        color("#1d5a2e") translate([RELE_C[0] - RELE[0]/2, YB - P - 6 - 1.6, RELE_Z0]) cube([RELE[0], 1.6, RELE[1]]);  // módulo relé
        color("#2357a8") translate([RELE_C[0] - 8, YB - P - 6 - 1.6 - 15, RELE_Z0 + 14]) cube([16, 15, 19]);          // relé azul
        color("#1f6aa5") translate([RELE_C[0] - 8, YB - P - 6 - 1.6 - 10, RELE_Z0 + 38]) cube([16, 10, 10]);          // bornes
        color("#14243a") translate([HLK_C[0] - HLK[0]/2, YB - P - 6 - 1.6, HLK_Z0]) cube([HLK[0], 1.6, HLK[1]]);       // placa da fonte
        color("#111") translate([HLK_C[0] - 17, YB - P - 6 - 1.6 - 15, HLK_Z0 + 2]) cube([34, 15, 20]);                // HLK-PM01
        color("#2e7d32") translate([11, YB - P - 5 - 1.6, PLACA_B_Z0]) cube([PLACA_B[0], 1.6, PLACA_B[1]]);           // placa ilhada
        color("#1d3f73") translate([19, YB - P - 5 - 1.6 - 3, PLACA_B_Z0 + 14]) cube([18, 3, 22.5]);                   // ESP32-C3
        color("#2ea043") translate([LED_B[0], 1, LED_B[1]]) rotate([90, 0, 0]) cylinder(h = 4.5, d = 3);
        for (p = PRENSA) {
            color("#222") translate([p[0], p[1], -14]) cylinder(h = 14, d = 15, $fn = 6);                               // prensa-cabo PG7
            color("#3a3a3a") translate([p[0], p[1], -40]) cylinder(h = 27, d = 7);                                    // cabo
        }
        for (i = [0, 1]) color("#f0f0f0") translate([54 + i * 18, 8, 50]) cube([13, 18, 9]);                           // conectores de alavanca
        color("#e8e8e8", 0.7) translate([60, 6, 42]) rotate([0, 90, 0]) cylinder(h = 22, d = 7);                         // porta-fusível
    }
}

if (PARTE == "alvo") unidade_alvo();
else if (PARTE == "acionador") unidade_acionador();
else {
    // cena: alvo num poste, a ~15 m de um refletor na parede, que tem o acionador embaixo
    color("#6b5a45") translate([XA/2, YA + 13 + 40, -1600]) cylinder(h = 1800, d = 80);                     // poste do alvo
    color("#4b5a3a") translate([-2500, -3500, -1602]) cube([6000, 6000, 2]);                                 // chão
    unidade_alvo();
    translate([900, 2600, 0]) rotate([0, 0, 0]) {
        color("#8c8a84") translate([-400, 45, -1600]) cube([1000, 120, 2400]);                              // parede
        translate([0, 0, 0]) unidade_acionador();
        color("#333") translate([XB/2 - 60, -40, 700]) cube([120, 50, 90]);                                  // refletor de LED
        color(ACESO ? "#fffbe0" : "#cfd3d6") translate([XB/2 - 52, -41, 708]) cube([104, 1, 74]);
        color("#3a3a3a") translate([XB/2 + 30, -5, 120]) cube([6, 6, 580]);                                  // cabo até o refletor
        if (ACESO) color("#fff6b0", 0.18) hull() {
            translate([XB/2, -40, 745]) sphere(d = 60);
            translate([XB/2, -1600, -1600]) cylinder(h = 1, d = 3000);
        }
    }
}
