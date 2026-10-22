// 08 - GRANADA DE SOM E LUZ · MONTAGEM (só para os desenhos da prévia; não é para imprimir)
// z = 0 no pé do corpo; a base fica embaixo (z -4 a 0) e o topo em cima (z 100 a 112)
include <pecas.scad>
$fn = 48;
EXTRAS = true;           // false = só as peças impressas (usado para as cotas)
CORTE = "nenhum";        // "nenhum" | "frente" (tira a parede -y: C3 e MT3608) | "tras" (tira a parede +y: LiPo e MOSFETs)
PECA = "nenhuma";        // desliga as saídas do pecas.scad

module tudo() {
    color(cor_preto()) translate([0, 0, -4]) base();
    color(cor_preto()) corpo();
    color(cor_coyote()) translate([0, 0, H]) topo();
    color(cor_coyote()) translate([PINO_R - PINO_HA/2, 0, H + E_TOPO + 15]) rotate([0, 90, 0]) pino_argola();
    color(cor_preto()) translate([0, 0, DECK_Z]) chassi();
    nas_faces([0, 90, 180, 270]) color(cor_preto()) translate([-P - 7, 0, JC]) rotate([0, 90, 0]) rotate([0, 0, 90]) suporte_led();
    // presilhas: C3 (z 48) e MT3608 (z 69 e 91) no lado -y; LiPo (z 47 e 67) no lado +y; TP4056 no piso
    for (zz = [48, 69, 91]) color(cor_preto()) translate([0, SLED_Y - 1.6 - 7, zz]) rotate([-90, 0, 0]) presilha();
    for (zz = [47, 67]) color(cor_preto()) translate([0, SLED_Y + SLED_E + H_LIPO + 3, zz]) rotate([90, 0, 0]) presilha(GAP_LIPO, 0);
    color(cor_preto()) translate([0, -16, DECK_Z + DECK_E + 1.6 + 7]) rotate([180, 0, 0]) presilha();
    if (EXTRAS) {                                                                                   // componentes (referência)
        color("#3a3f44") cylinder(h = SIRENE_H, d = SIRENE_D);                                        // sirene piezo 12 V
        color("#202020") translate([-9, SLED_Y - 1.6, 37]) cube([18, 1.6, 22.5]);                     // ESP32-C3 SuperMini
        color("#2b6a8f") translate([-8.5, SLED_Y - 1.6, 62]) cube([17, 1.6, 36]);                     // MT3608 (12 V da sirene)
        color("#7a1f1f") translate([-8.5, -F/2 + P + 0.6, DECK_Z + DECK_E]) cube([17, 28, 1.6]);       // TP4056 USB-C
        color("#b8bec2") translate([-4.5, -F/2 + P + 0.2, DECK_Z + DECK_E + 1.6]) cube([9, 7.5, 3.2]); // conector USB-C
        color("#c9a227") translate([-12.5, SLED_Y + SLED_E, 37]) cube([25, H_LIPO, 40]);              // LiPo 802540 1000 mAh
        color("#2f6b3a") translate([-18, SLED_Y + SLED_E + 4, 80]) cube([20, 1.6, 18]);               // plaquinha dos 2 MOSFETs
        for (xx = [-14, -4]) color("#151515") translate([xx, SLED_Y + SLED_E + 5.6, 84]) cube([10, 4.5, 9]);   // IRLZ44N
        color("#cfe8f0") translate([PINO_R + PINO_FURO/2 + 1.9, 0, H - 14]) cylinder(h = 14, d = 2.2); // reed
        nas_faces([0, 90, 180, 270]) translate([-P - 5.6, 0, JC]) {                                   // LEDs de 1 W
            color("#d9d9d9") rotate([0, 90, 0]) cylinder(h = 1.6, d = 20);
            color("#fff6c8") translate([1.6, 0, 0]) sphere(d = 5.5);
        }
        nas_faces([90]) { color("#151515") translate([-P - 9, 0, BOTAO_Z]) rotate([0, 90, 0]) cylinder(h = 9, d = 7); // botão de MODO
                          color("#8a1f1f") translate([1.5, 0, BOTAO_Z]) rotate([0, 90, 0]) cylinder(h = 2.5, d = 5); }
        rotate([0, 0, 135]) translate([F/2, 0, CHAVE_Z]) { color("#151515") translate([-11, -5, -7.5]) cube([11, 10, 15]);   // chave KCD11
                                                           color("#151515") translate([0, -6, -8.5]) cube([1.5, 12, 17]); }
    }
}
module corte() {
    if (CORTE == "frente") intersection() { tudo(); translate([-100, -18.8, -100]) cube([200, 200, 400]); }
    else if (CORTE == "tras") intersection() { tudo(); translate([-100, -200 + 4.4, -100]) cube([200, 200, 400]); }
    else tudo();
}
corte();
