// =====================================================================
//  10 - TRAÇANTE DENTRO DO SILENCIADOR · peças 3D
//  Escolha a peça em PECA, F6 (render) e F7 (exportar STL). Medidas em mm.
//  ESTILO TÁTICO FACETADO · cores: chassi e presilhas em PRETO · frente (com a marca) em COYOTE
//
//  COMO FUNCIONA: o cartucho entra no tubo do SEU silenciador, no lugar da espuma. A BB passa pelo
//  tubo central de 10 mm: corta um feixe infravermelho (x = 6) e a placa acende por 2 ms os 6 LEDs
//  UV de 395 nm (x = 50, 60 e 70, dos dois lados). A BB traçante (fosforescente) carrega e sai
//  brilhando. Para carregar: tire a tampa da frente do silenciador e ligue o USB-C na frente do cartucho.
//  Eixos: x ao longo do cano (x = 0 no fundo do cartucho, + para a frente); furo da BB em y = z = 0.
//  Impressão do chassi: em pé, apoiado no disco de trás (o anel da frente tem cone de 45°).
// =====================================================================
use <../../_BIBLIOTECA-3D/bb_lib.scad>
$fn = 64;

PECA = "chassi";   // chassi | frente | presilha_c3 | presilha_lipo | presilha_tp

// ---- MEÇA O SEU SILENCIADOR (tire as tampas e a espuma) e mude aqui ----
SIL_DI = 32;              // diâmetro de DENTRO do tubo
SIL_LI = 150;             // comprimento livre por dentro (sem as tampas)
// -------------------------------------------------------------------------
L = 130;                  // comprimento do cartucho com a frente (5 a 20 mm menor que SIL_LI)
R_D = SIL_DI / 2 - 0.3;   // raio dos discos (folga de 0,3 no tubo)
FURO = 10;                // furo da BB
TUBO_R = 6.6;             // raio externo do tubo central
PLAT_Z = 6;               // plataforma de cima: z 6 a 8 (as placas deitam em z = 8)
IR_X = 6;                 // barreira infravermelha (LED em +y, fototransistor em -y)
UV_X = [50, 60, 70];      // LEDs UV 5 mm, um de cada lado (+y e -y) em cada x
BOSS_R = 13.6;            // face do ressalto do LED (a ponta do LED fica rente ao furo)
X_ANEL = 113;             // anel da frente: cone de 113 a 122, cilindro de 122 a 126
X_FRENTE = L - 4;         // a frente coyote vai de 126 a 130
FRENTE_PY = 11; FRENTE_PZ = -3;   // 2 parafusos M3 x 10 da frente
USB_Z = PLAT_Z + 2 + 1.6 + 1.6;   // centro do USB-C do TP4056
LED_Z = -11;              // LED de estado 3 mm na frente

module cil_x(r, x0, x1) { translate([x0, 0, 0]) rotate([0, 90, 0]) cylinder(h = x1 - x0, r = r); }
module radial_y(s, x, r0, r1, d) { translate([x, 0, 0]) rotate([s > 0 ? -90 : 90, 0, 0]) translate([0, 0, r0]) cylinder(h = r1 - r0, d = d); }
module pino_m2(h) { difference() { cylinder(h = h, d = 4.5); translate([0, 0, 0.6]) cylinder(h = h, d = 1.7); } }   // pino para M2 (furo 1,7)

// ---------- CHASSI (preto) ----------
module chassi() {
    difference() {
        union() {
            cil_x(R_D, 0, 4);                                                        // disco de trás
            cil_x(TUBO_R, 0, X_ANEL + 1);                                            // tubo central
            translate([4, -9, PLAT_Z]) cube([X_ANEL - 4 + 1, 18, 2]);                // plataforma de cima (C3, LiPo, TP4056)
            translate([76, -9, -PLAT_Z - 2]) cube([X_ANEL - 76 + 1, 18, 2]);         // plataforma de baixo (plaquinha de sinal)
            for (s = [-1, 1]) translate([4, s > 0 ? R_D - 3.5 : -R_D + 1.5, -1]) cube([X_ANEL - 4 + 1, 2, 2]);   // trilhos laterais
            for (x = [4, 30, 82, X_ANEL - 1]) translate([x, -R_D + 2, -1]) cube([2, 2 * R_D - 4, 2]);         // travessas trilho-tubo
            intersection() {                                                         // anel da frente: cone de 45° + cilindro
                union() {
                    translate([X_ANEL, 0, 0]) rotate([0, 90, 0]) cylinder(h = R_D - TUBO_R, r1 = TUBO_R, r2 = R_D);
                    cil_x(R_D, X_ANEL + R_D - TUBO_R - 0.01, X_FRENTE);
                }
                cil_x(R_D, 0, X_FRENTE);
            }
            for (s = [-1, 1]) radial_y(s, IR_X, TUBO_R - 1, BOSS_R, 8);              // barreira IR
            for (x = UV_X, s = [-1, 1]) radial_y(s, x, TUBO_R - 1, BOSS_R, 8);       // ressaltos dos LEDs UV
            // pinos M2 das presilhas: C3 (x 8 e 35,5), LiPo (x 41 e 75,5), TP4056 (x 95,5)
            for (x = [8, 35.5]) translate([x, 0, PLAT_Z + 2 - 0.01]) pino_m2(1.6);
            for (x = [41, 75.5]) translate([x, 0, PLAT_Z + 2 - 0.01]) pino_m2(4);
            translate([95.5, 0, PLAT_Z + 2 - 0.01]) pino_m2(1.6);
            for (x = [87, 107]) translate([x, 0, -PLAT_Z - 2 + 0.01]) mirror([0, 0, 1]) pino_m2(2);   // plaquinha de sinal (embaixo)
        }
        cil_x(FURO / 2, -1, L + 1);                                                  // furo da BB
        translate([-0.01, 0, 0]) rotate([0, 90, 0]) cylinder(h = 2, d1 = FURO + 4, d2 = FURO);        // chanfro de entrada
        for (s = [-1, 1]) radial_y(s, IR_X, 3, BOSS_R + 1, 5.1);                     // LED IR / fototransistor 5 mm
        for (x = UV_X, s = [-1, 1]) radial_y(s, x, 3, BOSS_R + 1, 5.1);              // LEDs UV 5 mm
        translate([X_ANEL - 1, -9.2, PLAT_Z + 1.8]) cube([X_FRENTE - X_ANEL + 2, 18.4, 6.2]);              // passagem do TP4056 no anel
        translate([X_ANEL - 1, -8.5, -PLAT_Z - 9]) cube([12, 17, 6.6]);                                    // passagem dos fios de baixo
        for (s = [-1, 1]) translate([X_FRENTE - 7, s * FRENTE_PY, FRENTE_PZ]) rotate([0, 90, 0]) cylinder(h = 8, d = 2.6);   // pinos da frente
        translate([X_ANEL, 0, LED_Z]) rotate([0, 90, 0]) cylinder(h = 20, d = 3.2);                      // LED de estado
    }
}

// ---------- FRENTE (coyote) · MARCA DO PROJETO (única) ----------
// impressa de cara na mesa: z = 0 é a face da frente; x local = y do cartucho, y local = z do cartucho
module frente() {
    difference() {
        union() {
            cylinder(h = 0.8, r1 = R_D - 0.8, r2 = R_D);                                                 // borda chanfrada
            translate([0, 0, 0.79]) cylinder(h = 3.21, r = R_D);
        }
        translate([0, 0, -1]) cylinder(h = 6, d = FURO + 1);                                             // saída da BB
        translate([0, 0, -0.01]) cylinder(h = 1, d1 = FURO + 2, d2 = FURO + 1);
        translate([-5, USB_Z - 2.2, -1]) cube([10, 4.4, 6]);                                             // USB-C
        translate([0, LED_Z, -1]) cylinder(h = 6, d = 3.2);                                              // LED de estado
        for (s = [-1, 1]) translate([s * FRENTE_PY, FRENTE_PZ, 0]) { furo(3.4); translate([0, 0, -0.01]) cylinder(h = 1.6, d = 6.2); }
        for (k = [0 : 7]) rotate([0, 0, 22.5 + k * 45]) translate([R_D - 1.2, -1, -0.01]) cube([2, 2, 0.6]);   // 8 marcas facetadas na borda
        // MARCA DO PROJETO (única): emblema + nome gravados na face da frente
        emblema_baixo(-10.5, 3.6, 0.3, 0.6, 0);
        translate([0, -7.8, 0]) mirror([1, 0, 0]) translate([0, 0, -0.01]) linear_extrude(0.61)
            text("BLACK BIRD", size = 2.2, halign = "center", valign = "center", font = "Liberation Sans:style=Bold");
    }
}

// ---------- PRESILHAS (preto): seguram as placas sem cola, parafusos M2 x 6 ----------
module presilha(vao, alivio) {                // ao longo de x, impressa com a face lisa na mesa
    Lp = vao + 9;
    difference() {
        translate([-Lp/2, -3, 0]) prisma_oct(Lp, 6, 2 + alivio, 1);
        if (alivio > 0) translate([-(vao/2 - 2.5), -4, 2]) cube([vao - 5, 8, alivio + 1]);
        for (s = [-1, 1]) translate([s * (vao/2 + 2.25), 0, 0]) furo(2.2);
    }
}
module presilha_tp() {                        // 1 parafuso: a ponta segura a borda de trás do TP4056 (a frente fica presa no anel)
    difference() {
        translate([-3, -4, 0]) prisma_oct(10, 8, 2, 1);                       // a ponta de +x deita sobre a borda do TP4056
        furo(2.2);
    }
}

if (PECA == "chassi") rotate([0, -90, 0]) chassi();                     // em pé, disco de trás na mesa
if (PECA == "frente") frente();
if (PECA == "presilha_c3") presilha(27.5, 2.5);                         // C3 22,5 mm entre os pinos 8 e 35,5
if (PECA == "presilha_lipo") presilha(34.5, 0);                         // LiPo 402030 entre os pinos 41 e 75,5
if (PECA == "presilha_tp") presilha_tp();
