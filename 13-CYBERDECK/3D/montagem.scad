// 13 - CYBERDECK · MONTAGEM (só para os desenhos da prévia; não é para imprimir)
// PARTE = "aberta" (tampa aberta com a tela) ou "fechada" · INTERIOR = true tira o painel para mostrar o que vai dentro
include <pecas.scad>
$fn = 24;
EXTRAS = true;           // false = só as peças impressas (usado para as cotas)
PARTE = "aberta";
INTERIOR = false;
TAMPA_ANG = -105;        // abertura da tampa (graus)
PECA = "nenhuma";        // desliga as saídas do pecas.scad

module tampa_fechada() { translate([0, EY, BASE_H + TAMPA_H]) rotate([180, 0, 0]) children(); }
module tampa_aberta() { translate([0, EY, BASE_H]) rotate([TAMPA_ANG, 0, 0]) translate([0, -EY, -BASE_H]) tampa_fechada() children(); }

// ---------- monitor portátil 15,6" com o menu de missões (na tampa, coordenadas da tampa) ----------
VX0 = MON_X0 + 6.5; VY0 = MON_Y0 + 18; VW = 344; VH = 194;      // área de imagem (a "testa" mais larga fica embaixo)
module tela_na_tampa() {
    for (c = [[MON_X0, MON_Y0, 0], [MON_X0 + MON_W, MON_Y0, 90], [MON_X0 + MON_W, MON_Y0 + MON_H, 180], [MON_X0, MON_Y0 + MON_H, 270]])
        color(cor_preto()) translate([c[0], c[1], MON_Z + MON_T]) rotate([0, 0, c[2]]) cantoneira_tela();
    if (EXTRAS) {
        color("#1b1f24") translate([MON_X0, MON_Y0, MON_Z]) cube([MON_W, MON_H, MON_T]);           // monitor
        color("#05080a") translate([VX0, VY0, MON_Z + MON_T - 0.4]) cube([VW, VH, 0.5]);             // área de imagem
        // menu de missões (cores do DedSec + verde militar), desenhado na tela
        z = MON_Z + MON_T + 0.11;
        color("#ff3df2") translate([VX0 + 14, VY0 + VH - 22, z]) cube([130, 12, 0.3]);               // título com glitch
        color("#22e8ff") translate([VX0 + 150, VY0 + VH - 22, z]) cube([60, 12, 0.3]);
        color("#e2b04a") translate([VX0 + 230, VY0 + VH - 20, z]) cube([100, 8, 0.3]);
        for (i = [0 : 5]) color(i == 0 ? "#5aff8c" : "#2b6b43") translate([VX0 + 20, VY0 + VH - 52 - i * 26, z]) cube([i == 0 ? 230 : 190, 16, 0.3]);   // missões
        for (k = [0 : 11]) for (j = [0 : 11]) if (CAVEIRA_PX[k][j] == "#") color("#ff3df2") translate([VX0 + 270 + j * 5, VY0 + 120 - k * 5, z]) cube([4.4, 4.4, 0.3]);
        color("#5aff8c") translate([VX0 + 20, VY0 + 8, z]) cube([300, 3, 0.3]);                      // rodapé
    }
}
CAVEIRA_PX = ["   ######   ", "  ########  ", " ########## ", " ##  ##  ## ", " #   ##   # ", " ##  ##  ## ",
              " ########## ", "  ###  ###  ", "   ######   ", "   # ## #   ", "   ######   ", "    ####    "];

// ---------- mini teclado sem fio com touchpad (no rebaixo do painel) ----------
module mini_teclado() {
    translate([27, 141, PZ + PE - 2]) {
        color("#20242a") hull() { translate([4, 4, 0]) cylinder(h = 12, r = 4); translate([141, 4, 0]) cylinder(h = 12, r = 4); translate([4, 88, 0]) cylinder(h = 12, r = 4); translate([141, 88, 0]) cylinder(h = 12, r = 4); }
        for (r = [0 : 4], c = [0 : 9]) color("#3a3f46") translate([6 + c * 9.3, 8 + r * 15.5, 12]) cube([8, 13.5, 1.5]);   // teclas
        color("#3a3f46") translate([24, 8, 12]) cube([45, 13.5, 1.5]);                                                  // espaço
        color("#11151a") translate([102, 22, 12]) cube([38, 50, 0.6]);                                                  // touchpad
        for (b = [0, 1]) color("#3a3f46") translate([102 + b * 20, 8, 12]) cube([18, 10, 1.2]);                        // cliques
    }
}

// ---------- o que vai dentro da base (aparece com INTERIOR = true) ----------
module componentes() {
    color("#30363d") translate([20, 236, P]) cube([150, 70, 28]);                                // power bank 20.000 mAh
    color("#e8e8e8") translate([22, 238, P + 28]) linear_extrude(0.4) text("POWER BANK", size = 8);
    color("#c0392b") translate([288, 240, P]) cube([88, 60, 22]);                                 // Raspberry Pi 4 no case
    color("#1d6b3a") translate([292, 244, P + 22]) cube([80, 52, 1.5]);
    color("#2a2f35") translate([228, 48, P]) cube([77, 21, 20]);                                  // suporte da 18650
    color("#c9a227") translate([234, 58.5, P + 12]) rotate([0, 90, 0]) cylinder(h = 65, d = 18);
    color("#7a1f1f") translate([312, 48, P]) cube([30, 25, 1.6]);                                 // módulo 18650 5 V
    color("#202020") translate([340, 100, P + 8]) cube([22.5, 18, 1.6]);                          // ESP32-C3
    color("#1d3f73") translate([340, 124, P + 8]) cube([40, 22, 1.6]);                            // MCP23017
    color("#2b6a8f") translate([300, 150, P + 8]) cube([35, 32, 1.6]);                            // ULN2003
    color("#1d4d8f") translate([205, 248, P]) cube([50, 26, 19]);                                 // relé
    color("#2a2f35") for (x = [140, 300]) translate([x, 100, P]) cube([2, 80, 6]);                // canaletas dos fios (referência)
}

color(cor_preto()) render() base_inteira();
if (PARTE == "aberta") {
    if (!INTERIOR) {
        color(cor_coyote()) render() painel_inteiro();
        color(cor_coyote()) manete_alavanca();
    }
    color(cor_preto()) manete_base();
    color(cor_preto()) trilho_neon_uso();
    if (EXTRAS) {
        if (!INTERIOR) {
            for (b = [[235, "#d4a017"], [280, "#2e6fd1"], [325, "#2f9e44"], [370, "#c0392b"]]) color(b[1]) translate([b[0], 207, 82]) cylinder(h = 8, d = 24);   // arcade
            for (x = [250, 302, 354]) color("#a3241c") translate([x - 11, 92 - 23, 82]) cube([22, 46, 17]);                       // capas míssil
            mini_teclado();
            color("#0b0f14") translate([165 - 21.5, 281 - 8.5, 81.5]) cube([43, 17, 0.5]);                                       // display TM1637
            color("#ff2a2a") translate([150, 278, 82.2]) linear_extrude(0.3) text(" on", size = 7, font = "Liberation Mono:style=Bold");
            for (x = [30, 48, 66]) color(x == 30 ? "#3fbf5f" : x == 48 ? "#e2b04a" : "#d23a2c") translate([x, 279, 82]) cylinder(h = 2, d = 3);
        }
        color("#ff3df2") for (r = GLITCH) if (r[0] < 260) translate([r[0], r[1], 79]) cube([r[2], 3, 3]);                  // neon magenta
        color("#22e8ff") for (r = GLITCH) if (r[0] >= 260) translate([r[0], r[1], 79]) cube([r[2], 3, 3]);                 // neon ciano
        if (INTERIOR) componentes();
    }
    tampa_aberta() { color(cor_coyote()) render() tampa_inteira(); tela_na_tampa(); }
}
if (PARTE == "fechada") tampa_fechada() color(cor_coyote()) render() tampa_inteira();
