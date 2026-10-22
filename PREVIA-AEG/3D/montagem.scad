// =====================================================================
//  PRÉVIA GERAL · Rossi Neptune Shadow MK16 URG-I 13.5" (AEG) com os equipamentos BLACK BIRD
//  Só para os desenhos da PREVIA-AEG.html (não é para imprimir).
//  Réplica simplificada nas medidas do fabricante: 890 mm (coronha aberta), cano interno 365 mm,
//  guarda-mão M-LOK 13,5" (343 mm) com trilho Picatinny. Silenciador: Ø38 × 180 mm (CONFIRA o seu).
//  Luneta Red Win 1-6×24 na Geissele Super Precision alta (eixo a 49 mm do trilho).
//  Os equipamentos vêm dos STL exportados de cada projeto (pasta stl/, preto e coyote separados).
//  Eixos: x para a frente (cano) · y para a direita · z para cima · z = 0 no topo do trilho do receptor.
// =====================================================================
$fn = 40;
EXTRAS = true;          // (não usado: a réplica sempre aparece)
VIRADO = false;         // visão noturna virada para o lado
MAG = "D";              // magazine mostrado (só ilustração: os 4 modelos têm a mesma parte de cima)

EIXO = 49;              // centro da luneta
CANO_Z = -24;           // eixo do cano
HG_X0 = 192; HG_X1 = 536;   // guarda-mão 13,5"
SIL_X0 = 562; SIL_L = 180; SIL_D = 38;

PRETO = [0.17, 0.17, 0.17]; COYOTE = [0.54, 0.42, 0.27];
METAL = [0.24, 0.25, 0.27]; METAL2 = [0.31, 0.32, 0.34];

module gadget(nome, tem_coyote = true) {   // importa o par preto + coyote de um equipamento
    color(PRETO) import(str("stl/", nome, "_preto.stl"));
    if (tem_coyote) color(COYOTE) import(str("stl/", nome, "_coyote.stl"));
}

// ---------------- réplica (proporções tiradas da foto de lado do fabricante, escala pelo guarda-mão 13,5") ----------------
// x = 0 na traseira do receptor de cima · z = 0 no topo do trilho
module trilho(x0, x1) {
    difference() {
        translate([x0, 0, 0]) rotate([90, 0, 90]) linear_extrude(x1 - x0)
            polygon([[-10.6, 0], [10.6, 0], [10.6, -2.8], [7.8, -5.6], [7.8, -9.4], [-7.8, -9.4], [-7.8, -5.6], [-10.6, -2.8]]);
        for (x = [x0 + 6 : 10 : x1 - 6]) translate([x - 2.6, -12, -3]) cube([5.23, 24, 4]);
    }
}
module perfil_x(x0, x1) { translate([x0, 0, 0]) rotate([90, 0, 90]) linear_extrude(x1 - x0) children(); }   // 2D (y, z) ao longo de x
module receptor_cima() {
    difference() {
        union() {
            perfil_x(0, 192) polygon([[-11, -9.4], [11, -9.4], [12, -12], [12, -38], [10.5, -44], [-10.5, -44], [-12, -38], [-12, -12]]);
            hull() { translate([88, 11, -24]) cube([10, 3.5, 8]); translate([92, 11, -22]) cube([5, 5, 4]); }   // defletor de cápsula
            translate([20, -16, -34]) rotate([-90, 0, 0]) cylinder(h = 4, d = 9);                                  // botão do ferrolho (esq.)
        }
        translate([98, 11, -37]) cube([62, 3, 13]);                                                                 // janela de ejeção
        for (x = [8, 182]) translate([x, -14, -38]) rotate([-90, 0, 0]) cylinder(h = 28, d = 4);                   // pinos
    }
    color(METAL2) translate([100, 11.6, -36]) cube([58, 1.2, 11]);                                                 // tampa da janela
    translate([-9, -20, -10]) cube([13, 40, 4]);                                                                    // alavanca de manejo (T)
    translate([-9, -6, -13]) cube([13, 12, 5]);
}
module receptor_baixo() {
    difference() {
        union() {
            perfil_x(-2, 113) polygon([[-12, -44], [12, -44], [12, -76], [9, -80], [-9, -80], [-12, -76]]);       // corpo
            hull() {                                                                                                // magwell
                perfil_x(113, 186) polygon([[-15, -44], [15, -44], [15, -92], [-15, -92]]);
                perfil_x(110, 189) polygon([[-16.8, -94], [16.8, -94], [16.8, -100], [-16.8, -100]]);
            }
            for (s = [-1, 1]) hull() { translate([186, s * 12.5 - 2, -46]) cube([4, 4, 30]); }                      // orelhas da frente
        }
        translate([116.8, -11.4, -120]) cube([66.4, 22.8, 80]);                                                      // boca do magwell
        translate([-20, -13, -86]) rotate([0, -10, 0]) cube([20, 26, 30]);                                          // chanfro de trás
    }
    // guarda-mato e gatilho
    difference() {
        hull() { translate([46, -6, -98]) cube([66, 12, 4]); translate([40, -6, -80]) cube([6, 12, 4]); }
        hull() { translate([50, -7, -93]) cube([58, 14, 1]); translate([46, -7, -82]) cube([4, 14, 1]); }
    }
    translate([78, -3, -94]) rotate([0, -12, 0]) cube([5, 6, 15]);                                                  // gatilho
    // empunhadura (tipo MOE, inclinada ~20° para trás)
    hull() {
        translate([18, -14, -86]) cube([38, 28, 8]);
        translate([-14, -15, -176]) rotate([0, -20, 0]) cube([40, 30, 8]);
    }
    hull() { translate([-12, -12, -178]) rotate([0, -20, 0]) cube([42, 24, 4]); }                                   // base da empunhadura
    // logo do tridente (Neptune Spear) no lado direito do magwell
    translate([150, 15, -72]) rotate([-90, 0, 0]) difference() { cylinder(h = 0.8, d = 20); translate([0, 0, -1]) cylinder(h = 3, d = 17); }
    translate([150, 15, -72]) rotate([-90, 0, 0]) for (a = [-1, 0, 1]) translate([a * 3, -1, 0]) cube([1.2, 8, 0.8], center = true);
}
module coronha() {
    color(METAL) translate([-122, 0, -30]) rotate([0, 90, 0]) cylinder(h = 120, d = 30);                         // tubo da coronha
    color(METAL2) translate([-12, 0, -30]) rotate([0, 90, 0]) cylinder(h = 10, d = 34);                           // castle nut
    color(PRETO) intersection() {                                                                                   // coronha tipo MOE (aberta)
        translate([0, 20, 0]) rotate([90, 0, 0]) linear_extrude(40) difference() {
            polygon([[-118, -13], [-292, -13], [-298, -18], [-298, -140], [-284, -144], [-262, -128], [-205, -84], [-140, -52], [-118, -48]]);
            polygon([[-282, -52], [-282, -118], [-212, -62], [-150, -50], [-150, -44], [-268, -44]]);              // vazado
            for (x = [-250, -220, -190]) translate([x, -26]) square([22, 6]);                                       // rasgos de bandoleira
        }
        hull() { translate([-300, -17, -150]) cube([190, 34, 150]); translate([-300, -19, -146]) cube([30, 38, 140]); }
    }
    color(PRETO) translate([-302, -20, -144]) cube([6, 40, 130]);                                                   // soleira de borracha
}
module receptor() {
    color(METAL) { receptor_cima(); receptor_baixo(); }
    coronha();
    color(METAL2) trilho(0, 192);
}
module guarda_mao() {
    color(METAL) difference() {
        perfil_x(HG_X0, HG_X1) polygon([[-12, -9.4], [12, -9.4], [19, -12], [19, -33], [12, -42], [-12, -42], [-19, -33], [-19, -12]]);
        for (x = [HG_X0 + 30 : 40 : HG_X1 - 34], s = [-1, 1]) translate([x, s * 19 - 3, -26]) cube([32, 6, 7]);    // M-LOK nos lados
        for (x = [HG_X0 + 30 : 40 : HG_X1 - 34], s = [-1, 1]) translate([x, s * 15.5, -38]) rotate([s * 45, 0, 0])
            translate([0, -3.5, -3]) cube([32, 7, 6]);                                                                   // M-LOK nos chanfros
        for (x = [HG_X0 + 30 : 40 : HG_X1 - 34]) translate([x, -3.5, -45]) cube([32, 7, 6]);                         // M-LOK embaixo
        perfil_x(HG_X0 - 1, HG_X1 + 1) polygon([[-9, -14], [9, -14], [9, -36], [-9, -36]]);                          // oco
    }
    color(METAL2) for (s = [-1, 1], z = [-17, -30]) translate([HG_X0 + 9, s * 19, z]) rotate([s * -90, 0, 0]) cylinder(h = 1.5, d = 6);   // parafusos da porca do cano
    color(METAL2) trilho(HG_X0, HG_X1);
    color(PRETO) translate([HG_X1 - 22, -9, 0]) cube([16, 18, 7]);                                                  // massa de mira dobrada
}module cano_silenciador() {
    color(METAL2) translate([HG_X1 - 10, 0, CANO_Z]) rotate([0, 90, 0]) cylinder(h = SIL_X0 - HG_X1 + 12, d = 15);
    color(PRETO) translate([SIL_X0, 0, CANO_Z]) rotate([0, 90, 0]) difference() {
        cylinder(h = SIL_L, d = SIL_D);
        for (z = [12 : 6 : 40]) translate([0, 0, z]) difference() { cylinder(h = 2, d = SIL_D + 1); cylinder(h = 2, d = SIL_D - 1.6); }
        translate([0, 0, -1]) cylinder(h = SIL_L + 2, d = 8);
    }
}
module luneta() {
    // Red Win 1-6x24 (forma aproximada) e Geissele Super Precision alta
    color(PRETO) translate([0, 0, EIXO]) rotate([0, 90, 0]) {
        translate([0, 0, -5]) cylinder(h = 50, d1 = 44, d2 = 42);                   // ocular
        translate([0, 0, 45]) cylinder(h = 17, d = 40);                             // anel de zoom
        translate([0, 0, 62]) cylinder(h = 148, d = 30);                            // tubo
        translate([0, 0, 210]) cylinder(h = 35, d1 = 30, d2 = 34);                  // objetiva (250 mm no total)
    }
    color(PRETO) translate([112, 0, EIXO]) {
        rotate([0, 0, 0]) cylinder(h = 30, d = 26);                                 // torre de elevação
        rotate([-90, 0, 0]) cylinder(h = 30, d = 26);                               // torre de vento
        translate([-15, -15, -15]) cube([30, 30, 30]);
    }
    color(PRETO) translate([52, -20, EIXO + 14]) rotate([0, 0, -30]) cube([5, 18, 6]);   // alavanca de zoom
    color(METAL) {
        for (x = [88, 160]) translate([x, 0, EIXO]) rotate([0, 90, 0]) translate([0, 0, -9]) cylinder(h = 18, d = 38);   // anéis
        hull() { translate([80, -12, 0]) cube([90, 24, 6]); translate([84, -8, EIXO - 22]) cube([82, 16, 6]); }    // base alta
    }
}

// lanterna IR 850 nm montada (projeto 14), no M-LOK do lado direito: ilumina até 80-100 m para a visão noturna
module lanterna_ir() { translate([400, 19, -26]) gadget("14_lanterna"); }
// magazine M4 comum (o usuário usa outro modelo: forma genérica de mid-cap, levemente curvo)
module magazine_m4() {
    color(PRETO) for (i = [0 : 9]) hull() for (k = [i, i + 1]) {
        z = -40 - k * 17; dx = -pow(k / 10, 2) * 14;                     // curva para a frente embaixo
        translate([122.5 + dx, -11.2, z - 0.01]) cube([60, 22.4, 0.02]);
    }
    color(PRETO) translate([118.5 - 14, -13.5, -40 - 170 - 6]) cube([68, 27, 6]);          // base
}

// ---------------- equipamentos (cada um nas medidas do próprio projeto) ----------------
module equipamentos() {
    translate([172, -15, 0]) gadget("03_unidade");                                         // 03 · guarda-mão, embaixo da objetiva
    multmatrix([[0, 0, 1, 70], [1, 0, 0, 0], [0, 1, 0, EIXO], [0, 0, 0, 1]]) gadget("03_pod", false);   // 03 · pod no tubo, 9 h
    translate([160 - 33, -22, EIXO + 28]) gadget("12_telemetro");                          // 12 · no anel da frente
    if (VIRADO) translate([253, -34, 17]) rotate([90, 0, 0]) translate([0, 34, -17]) gadget("14_visao");
    else translate([253, 0, 0]) gadget("14_visao");                                        // 14 · na frente da objetiva
    magazine_m4();                                                                         // magazine do usuário (M4 comum)
    lanterna_ir();
    translate([396, 23, 0]) mirror([0, 1, 0]) gadget("06_anpeq");                       // 06 · ANPEQ na ponta do trilho de cima (torre de deriva à direita)                                                                         // 14 · lanterna IR para 80 m
}

receptor();
guarda_mao();
cano_silenciador();
luneta();
equipamentos();
