// =====================================================================
//  14 - VISÃO NOTURNA · MONTAGEM (peças na posição de uso, com cor) · para os desenhos da prévia
//  EXTRAS = trilho, luneta e componentes · SEM_TAMPA = mostra o interior · VIRADO = unidade virada para o lado
// =====================================================================
include <pecas.scad>
PECA = "nenhuma";
$fn = 32;
EXTRAS = true;
SEM_TAMPA = false;
VIRADO = false;
FIXA = false;            // true = base FIXA (2 parafusos atravessados, não vira) · false = base BASCULANTE
PARTE = "visao";         // "visao" (unidade + base) ou "lanterna" (lanterna IR do M-LOK)

function cor_preto() = [0.17, 0.17, 0.17];
function cor_coyote() = [0.54, 0.42, 0.27];

module unidade() {
    pinta(0) casco();
    if (!SEM_TAMPA) pinta(1) translate([0, Y_DIR + E_TAMPA, 0]) rotate([90, 0, 0]) tampa();
    pinta(1) translate([0, 0, EIXO]) rotate([0, -90, 0]) rotate([0, 0, 90]) capuz_lente();
    pinta(0) suporte_tela();
    for (x = BOTOES_X) pinta(1) translate([x, BOTOES_Y, ZT - P - 2 + 0.6]) capa_botao(9, 0, 4);
    if (EXTRAS) {
        color([0.75, 0.88, 0.95], 0.6) translate([0.6, 0, EIXO]) rotate([0, 90, 0]) cylinder(h = 4, d = LENTE_D);          // lente 25 mm
        color("#1a1a1a") translate([FOCO, -TELA_PCB[0]/2, TELA_Z0 + 2]) cube([1.6, TELA_PCB[0], TELA_PCB[1]]);             // tela
        color("#2a4d8f") translate([FOCO - 1.5, -12, EIXO - 11]) cube([1.5, 24, 24]);                                       // vidro da tela
        color("#c9a227") translate([LIPO_X, -LIPO[1]/2 - 1, ZB + P]) cube(LIPO);                                            // LiPo 1000 mAh
        color("#1d3f73") translate([ESP_X, -13.5, ZB + P]) cube([1.6, 27, 40.5]);                                            // ESP32-CAM em pé
        color("#111") translate([ESP_X + 1.6, -4, CAM_Z - 4]) cube([6, 8, 8]);                                              // câmera OV2640
        color("#7a1f1f") translate([8, Y_ESQ + P + 1, 38]) cube([26, 1.6, 30]);                                             // carga + 5 V
        for (y = LEDS_Y) color("#552222") translate([L - 8.6, y, LEDS_Z]) rotate([0, 90, 0]) cylinder(h = 8.6, d = 5);    // LEDs IR
        color("#2e7d32") translate([20, -10, ZT - P - 7]) cube([24, 20, 1.6]);                                             // placa dos botões
    }
}
if (PARTE == "lanterna") lanterna_uso();
else {
if (EXTRAS) {
    color("#5a5f63") translate([-30, 0, 0]) rotate([90, 0, 90]) linear_extrude(160)                                       // trilho Picatinny
        polygon([[-10.6, 0], [10.6, 0], [10.6, -2.8], [7.8, -5.6], [7.8, -9.4], [-7.8, -9.4], [-7.8, -5.6], [-10.6, -2.8]]);
    color("#4a4f53", 0.5) translate([-70, 0, EIXO]) rotate([0, 90, 0]) cylinder(h = 62, d = 30);                         // objetiva da luneta
}
if (FIXA) pinta(0) base_fixa(); else pinta(0) base_flip();
pinta(1) translate([GARRA_X, 0, 0]) mandibula();
PONTA_PINO = DOB_X[2] + FURO_TRAVA - 0.2;
if (!FIXA) {
    // trava: pino (coyote) travado na orelha + botão (parafuso M3 x 12) saindo pela esquerda; BB na articulação da frente
    pinta(1) translate([PONTA_PINO - PINO_L, DOB_Y, DOB_Z - BB_R]) rotate([0, 90, 0]) pino_trava();
    if (EXTRAS) color("#9aa4aa") translate([PONTA_PINO - PINO_L + 1.8, DOB_Y, DOB_Z - BB_R]) rotate([90, 0, 0]) {
        cylinder(h = 12, d = 3); translate([0, 0, 9.5]) cylinder(h = 3, d = 5.5);
    }
    if (EXTRAS) color("#eeeeee") translate([DOB_X[4] + 3, DOB_Y, DOB_Z - BB_R]) sphere(d = 6);
} else if (EXTRAS) for (z = [DOB_Z, DOB_Z - BB_R]) color("#9aa4aa") translate([DOB_X[0], DOB_Y, z]) rotate([0, 90, 0]) {   // 2 parafusos M3 x 50
    cylinder(h = 50, d = 3); translate([0, 0, -3]) cylinder(h = 3, d = 5.5);
}
if (VIRADO && !FIXA) translate([0, DOB_Y, DOB_Z]) rotate([90, 0, 0]) translate([0, -DOB_Y, -DOB_Z]) unidade();
else unidade();
}

// --- filtro de cor (usado pela prévia geral no AEG: exporta só as peças pretas ou só as coyote) ---
COR = "todas";   // "todas" | "preto" | "coyote"
module pinta(c) {
    if (COR == "todas") color(c == 0 ? cor_preto() : cor_coyote()) children();
    else if (COR == (c == 0 ? "preto" : "coyote")) children();
}