// 10 - TRAÇANTE DENTRO DO SILENCIADOR · MONTAGEM (só para os desenhos da prévia; não é para imprimir)
// x ao longo do cano (x = 0 no fundo do cartucho, + para a frente); furo da BB em y = z = 0
include <pecas.scad>
$fn = 48;
EXTRAS = true;           // false = só as peças impressas (usado para as cotas)
SILENCIADOR = false;     // true = mostra o tubo do silenciador cortado ao meio, com o cartucho dentro
PECA = "nenhuma";        // desliga as saídas do pecas.scad

module tudo() {
    color(cor_preto()) render() chassi();     // render(): sem ele a prévia do OpenSCAD mistura as cores das peças ocas
    color(cor_coyote()) translate([L, 0, 0]) rotate([0, -90, 0]) rotate([0, 0, -90]) frente();
    color(cor_preto()) translate([21.75, 0, PLAT_Z + 2 + 1.6 + 4.5]) rotate([180, 0, 0]) presilha(27.5, 2.5);
    color(cor_preto()) translate([58.25, 0, PLAT_Z + 2 + 4]) presilha(34.5, 0);
    color(cor_preto()) translate([95.5, 0, PLAT_Z + 2 + 1.6]) presilha_tp();
    if (EXTRAS) {
        color("#202020") translate([10.5, -9, PLAT_Z + 2]) cube([22.5, 18, 1.6]);                  // ESP32-C3 SuperMini
        color("#c9a227") translate([43.5, -10, PLAT_Z + 2]) cube([30, 20, 4]);                     // LiPo 402030
        color("#7a1f1f") translate([98, -8.5, PLAT_Z + 2]) cube([28, 17, 1.6]);                    // TP4056 USB-C
        color("#b8bec2") translate([118.6, -4.5, PLAT_Z + 3.6]) cube([7.8, 9, 3.2]);              // conector USB-C
        color("#2f6b3a") translate([84, -8, -PLAT_Z - 3.6]) cube([26, 16, 1.6]);                   // plaquinha de sinal (embaixo)
        color("#151515") translate([88, -6.5, -PLAT_Z - 8]) cube([10, 4.5, 4.4]);                  // IRLZ44N deitado
        color("#151515") translate([100, 1, -PLAT_Z - 7]) cube([9.5, 6.5, 3.4]);                   // LM393
        color("#2858b0") translate([100, -6.5, -PLAT_Z - 8]) cube([6, 6, 4.4]);                    // trimpot
        color("#b8bec2") translate([90, 2.5, -PLAT_Z - 6.5]) rotate([0, 90, 0]) cylinder(h = 7, d = 4);   // sensor de vibração
        for (s = [-1, 1]) color(s > 0 ? "#d9d9d9" : "#2a2a2a") radial_y(s, IR_X, FURO/2 + 0.3, BOSS_R + 1, 5);   // LED IR / fototransistor
        for (x = UV_X, s = [-1, 1]) color("#8a5cff") radial_y(s, x, FURO/2 + 0.3, BOSS_R + 1, 5);              // LEDs UV 395 nm
        color("#3fae49") translate([L - 6, 0, LED_Z]) rotate([0, 90, 0]) cylinder(h = 6, d = 3);                  // LED de estado
        color("#9cff6a") translate([30, 0, 0]) sphere(d = 6);                                                   // BB traçante passando
        if (SILENCIADOR) color("#3a3f44") difference() {                                                       // tubo do silenciador (cortado)
            translate([-12, 0, 0]) rotate([0, 90, 0]) cylinder(h = SIL_LI + 24, d = SIL_DI + 4);
            translate([-13, 0, 0]) rotate([0, 90, 0]) cylinder(h = SIL_LI + 26, d = SIL_DI);
            translate([-20, 0, -50]) cube([SIL_LI + 40, 50, 100]);
        }
    }
}
tudo();
