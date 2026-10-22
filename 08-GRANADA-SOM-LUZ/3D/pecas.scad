// =====================================================================
//  08 - GRANADA DE SOM E LUZ (reutilizável) · peças 3D
//  Escolha a peça em PECA, F6 (render) e F7 (exportar STL). Medidas em mm.
//  ESTILO TÁTICO FACETADO · cores: corpo, base, chassi, suportes de LED e presilhas em PRETO
//                                  topo (com a marca) e pino em COYOTE
//
//  COMO FUNCIONA: o pino tem um ímã na ponta. Com o pino no lugar, o ímã fecha o sensor magnético (reed).
//  Puxou o pino: a placa acorda, conta 3 s (ou 5 s, ou 0 s no modo mina) e dispara o estrobo branco
//  (4 LEDs de 1 W atrás das janelas de favo) junto com a sirene piezo de 110 dB (sai pela grade de baixo
//  e pelas grelhas laterais). Recoloque o pino para desarmar e recarregar o ciclo.
//  Eixos: corpo octogonal em pé, centro em x = y = 0, z = 0 no pé do corpo. Faces retas em 0/90/180/270°.
//
//  DENTRO, de baixo para cima: sirene no berço da base · chassi (piso + placa em pé) apoiado na sirene,
//  apertado pelo topo · placas presas no chassi com presilhas parafusadas (M3, sem cola) ·
//  4 LEDs de 1 W em suportes parafusados atrás das janelas.
// =====================================================================
use <../../_BIBLIOTECA-3D/bb_lib.scad>
$fn = 48;

PECA = "corpo";   // corpo | base | topo | pino | chassi | suporte_led | presilha | presilha_lipo

F = 58;                    // octógono: de face a face (por fora)
H = 100;                   // altura do corpo
P = 3;                     // parede
PINOS_R = 25.5;            // raio dos pinos dos parafusos: nos vértices 22,5° / 112,5° / 202,5° / 292,5°
SIRENE_D = 42; SIRENE_H = 26;                  // sirene piezo 12 V 110 dB Ø42 x 26 (CONFIRA a sua)
GRELHA_Z0 = 4; GRELHA_Z1 = 24;                 // grelhas da sirene (4 faces diagonais)
JANELA_Z = 56; JANELA_H = 20; JANELA_L = 16;   // janelas do estrobo (4 faces retas)
JC = JANELA_Z + JANELA_H / 2;                  // centro das janelas (z = 66)
DECK_Z = SIRENE_H + 0.5;                       // piso do chassi apoiado em cima da sirene
DECK_E = 3;
SLED_Y = -10; SLED_E = 3; SLED_L = 36;         // placa em pé do chassi: y de -10 a -7, x ±18
USB_Z = DECK_Z + DECK_E + 3.2;                 // centro do USB-C do TP4056 deitado no piso
BOTAO_Z = 42;                                  // botão de MODO (painel 7 mm) na face +y
CHAVE_Z = 44.5;                                // chave gangorra KCD11 (10 x 15) na face diagonal de 135°
PINO_R = 12; PINO_FURO = 7.8; PINO_L = 20;     // pino: fora do centro; guia de 20 mm para baixo do topo
IMA_D = 4.2; IMA_H = 2.2;                      // ímã de neodímio 4 x 2 dentro da ponta do pino
E_TOPO = 12;                                   // altura do topo facetado
GAP_PLACA = 18.4;                              // presilha das placas de 17-18 mm (C3, MT3608, TP4056)
GAP_LIPO = 25.6; H_LIPO = 8;                   // presilha da LiPo 802540 (8 x 25 x 40)

module oct_oco(f, h, p) { difference() { octogono(f, h); translate([0, 0, -1]) octogono(f - 2*p, h + 2); } }
module nos_cantos() { for (a = [22.5, 112.5, 202.5, 292.5]) rotate([0, 0, a]) translate([PINOS_R, 0, 0]) children(); }
module nas_faces(angs) { for (a = angs) rotate([0, 0, a]) translate([F/2, 0, 0]) children(); }   // local: x = 0 na face de fora
module aba(z0) {                                                            // aba que entra no corpo, recortada nos pinos
    translate([0, 0, z0]) difference() {
        octogono(F - 2*P - 0.4, 3);
        translate([0, 0, -1]) octogono(F - 2*P - 3.6, 5);
        nos_cantos() translate([0, 0, -1]) cylinder(h = 5, d = 7.8);
    }
}

// ---------- CORPO (preto) ----------
module corpo() {
    difference() {
        union() {
            oct_oco(F, H, P);
            intersection() {                                                    // pinos dos parafusos (em cima e embaixo)
                octogono(F - 0.2, H);
                union() { nos_cantos() { pino(8, 7, 2.6); translate([0, 0, H]) mirror([0, 0, 1]) pino(8, 7, 2.6); } }
            }
            // molduras das janelas (facetadas, salientes 1,5 mm)
            nas_faces([0, 90, 180, 270]) translate([-0.01, 0, JC]) rotate([0, 90, 0])
                linear_extrude(1.5, scale = 0.9) square([JANELA_H + 6, JANELA_L + 6], center = true);
            // moldura do botão de modo (protege de aperto sem querer)
            nas_faces([90]) translate([-0.01, 0, BOTAO_Z]) rotate([0, 90, 0]) moldura_oct(13, 2);
        }
        // janelas do estrobo
        nas_faces([0, 90, 180, 270]) translate([-P - 2, -JANELA_L/2, JANELA_Z]) cube([P + 5, JANELA_L, JANELA_H]);
        // grelhas da sirene (faces diagonais)
        for (a = [45, 135, 225, 315]) rotate([0, 0, a]) for (k = [-2 : 2])
            translate([F/2 - P - 1, k * 4 - 1, GRELHA_Z0]) cube([P + 2.5, 2, GRELHA_Z1 - GRELHA_Z0]);
        // USB-C do TP4056 (face -y): rasgo + rebaixo de 1,5 mm por fora para o plugue entrar
        nas_faces([270]) {
            translate([-P - 1, -5, USB_Z - 2.2]) cube([P + 2, 10, 4.4]);
            translate([-1.5, -7, USB_Z - 3.5]) cube([2, 14, 7]);
        }
        // botão de modo (painel 7 mm, porca por dentro)
        nas_faces([90]) translate([-P - 1, 0, BOTAO_Z]) rotate([0, 90, 0]) cylinder(h = P + 4, d = 7.2);
        // chave liga/desliga KCD11 (encaixe de pressão): rasgo 10,2 x 15,2 e parede afinada para 2 mm por dentro
        rotate([0, 0, 135]) translate([F/2, 0, CHAVE_Z]) {
            translate([-P - 1, -5.1, -7.6]) cube([P + 2, 10.2, 15.2]);
            translate([-P - 1, -7, -9.5]) cube([2, 14, 19]);
        }
    }
    // favos nas janelas (protegem os LEDs de BB e de pancada)
    nas_faces([0, 90, 180, 270]) translate([-P + 0.01, -JANELA_L/2, JANELA_Z]) rotate([90, 0, 90]) favos(JANELA_L, JANELA_H, P - 0.5, 4.2, 1);
    // pinos dos suportes de LED (em cima e embaixo de cada janela, para dentro)
    nas_faces([0, 90, 180, 270]) for (s = [-1, 1]) translate([-P + 0.01, 0, JC + s * 15]) rotate([0, -90, 0]) pino(4, 6, 2.6);
}

// ---------- BASE (preto): berço e grade da sirene ----------
module base() {                               // impressa de cara na mesa; z = 0 é a face de fora
    difference() {
        union() {
            octogono(F, 4);
            aba(3.99);
            translate([0, 0, 3.99]) difference() {                              // berço da sirene
                cylinder(h = 6, d = SIRENE_D + 3);
                translate([0, 0, -1]) cylinder(h = 8, d = SIRENE_D + 0.6);
                nos_cantos() translate([0, 0, -1]) cylinder(h = 8, d = 7.8);
            }
        }
        translate([-17, -17, -1]) intersection() { translate([17, 17, 0]) cylinder(h = 6, d = 34); difference() { cube([34, 34, 6]); favos(34, 34, 6, 4.2, 1.2); } }   // grade do som
        nos_cantos() { furo(3.4); translate([0, 0, -0.01]) cylinder(h = 2.4, d = 6.2); }
    }
}

// ---------- TOPO (coyote) · MARCA DO PROJETO (única) ----------
module topo() {                               // na posição de uso: z = 0 encosta no corpo
    difference() {
        union() {
            hull() { octogono(F, 3); translate([0, 0, E_TOPO - 0.01]) octogono(F - 14, 0.01); }
            translate([0, 0, -3]) difference() { aba(0); }
            translate([PINO_R, 0, -PINO_L + 6]) cylinder(h = PINO_L - 6 + 0.01, d = PINO_FURO + 4);                                     // guia do pino
            translate([PINO_R + 2, -2.8, -PINO_L + 6]) cube([PINO_FURO/2 + 0.6 + 2.6 + 1.5 - 2, 5.6, PINO_L - 6 + 0.01]);            // bloco do reed
        }
        translate([PINO_R, 0, -PINO_L - 1]) cylinder(h = PINO_L + E_TOPO + 2, d = PINO_FURO);                                          // furo do pino
        translate([PINO_R + PINO_FURO/2 + 0.6, -1.3, -PINO_L + 5]) cube([2.6, 2.6, PINO_L - 4]);                                      // reed ao lado da guia (fios saem por baixo)
        nos_cantos() { furo(3.4, 40); translate([0, 0, 1]) cylinder(h = 20, d = 6.2); }
        // MARCA DO PROJETO (única): emblema + nome, no lado oposto ao pino
        emblema_topo(-3, 0, E_TOPO, 0.45, 0.6, 90);
        translate([-12, 0, E_TOPO - 0.6]) rotate([0, 0, 90]) linear_extrude(1) text("BLACK BIRD", size = 3, halign = "center", valign = "center", font = "Liberation Sans:style=Bold");
    }
}

// ---------- PINO (coyote): argola + haste com ímã preso dentro da ponta ----------
PINO_HL = 5.6; PINO_HA = 5.0;                 // seção da haste (cabe no furo de 7,8 na diagonal)
module pino_argola() {                        // impresso deitado. PAUSA na altura 4,6 mm para colocar o ímã 4 x 2
    difference() { cylinder(h = PINO_HA, d = 30); translate([0, 0, -1]) cylinder(h = 7, d = 20); }
    translate([14, -PINO_HL/2, 0]) difference() {
        cube([PINO_L + 4, PINO_HL, PINO_HA]);
        translate([PINO_L + 4 - IMA_H - 0.8, PINO_HL/2 - IMA_D/2, 0.4]) cube([IMA_H, IMA_D, IMA_D]);   // bolso fechado do ímã
    }
}

// ---------- CHASSI (preto): piso apoiado na sirene + placa em pé onde vão as placas ----------
// na posição de uso: z = 0 é a face de baixo do piso (fica em z = DECK_Z no corpo)
SLED_H = H - 0.2 - DECK_Z;                    // a placa em pé encosta por baixo do topo
module chassi() {
    difference() {
        union() {
            octogono(F - 2*P - 0.8, DECK_E);
            translate([-SLED_L/2, SLED_Y, 0]) cube([SLED_L, SLED_E, SLED_H]);
            // pinos das presilhas, lado -y: C3 (z 48) e MT3608 (z 69 e 91)
            for (zz = [48, 69, 91] - [DECK_Z, DECK_Z, DECK_Z]) for (s = [-1, 1])
                translate([s * (GAP_PLACA/2 + 3.5), SLED_Y + 0.01, zz]) rotate([90, 0, 0]) pino(1.6, 7, 2.6);
            // pinos das presilhas da LiPo, lado +y (z 47 e 67)
            for (zz = [47, 67] - [DECK_Z, DECK_Z]) for (s = [-1, 1])
                translate([s * (GAP_LIPO/2 + 3.5), SLED_Y + SLED_E - 0.01, zz]) rotate([-90, 0, 0]) pino(H_LIPO, 7, 2.6);
            // pinos da plaquinha dos MOSFETs, lado +y (perfurada 20 x 18, furos de 3 mm)
            for (p = [[-15, 83], [-1, 95]]) translate([p[0], SLED_Y + SLED_E - 0.01, p[1] - DECK_Z]) rotate([-90, 0, 0]) pino(4, 6, 2.6);
            // pinos da presilha do TP4056, no piso
            for (s = [-1, 1]) translate([s * (GAP_PLACA/2 + 3.5), -16, DECK_E - 0.01]) pino(1.6, 7, 2.6);
        }
        translate([-10, SLED_Y - 1, DECK_E - 0.01]) cube([20, SLED_E + 2, 6]);       // arco: o TP4056 passa por baixo da placa em pé
        for (s = [-1, 1]) translate([s * 16, 12, -1]) cylinder(h = 6, d = 8);         // passagem dos fios da sirene
        translate([PINO_R, 0, -1]) cylinder(h = 6, d = 9);                            // fios do reed / folga
    }
}

// ---------- SUPORTE DE LED (preto, 4x): segura a estrela de 20 mm contra a janela ----------
module suporte_led() {                        // impresso deitado; o bolso da estrela fica para cima (lado da janela)
    difference() {
        translate([-11, -18, 0]) prisma_oct(22, 36, 3, 4);
        translate([0, 0, 3 - 1.6]) cylinder(h = 2, d = 20.4, $fn = 64);              // bolso da estrela
        for (s = [-1, 1]) translate([s * 10, 0, 1.6]) cube([4, 6, 3], center = true); // saída dos fios das solda
        for (s = [-1, 1]) translate([0, s * 15, 0]) { furo(3.4); translate([0, 0, -0.01]) cylinder(h = 1.2, d = 6.2); }
    }
}

// ---------- PRESILHAS (preto): seguram as placas sem cola, 2 parafusos M3 x 8 ----------
module presilha(gap = GAP_PLACA, alivio = 4) { // impressa de cabeça para baixo (face lisa na mesa)
    L = gap + 14;
    difference() {
        translate([-L/2, -3.5, 0]) prisma_oct(L, 7, 3 + alivio, 1.5);
        translate([-(gap/2 - 3), -5, 3]) cube([gap - 6, 10, alivio + 1]);           // alívio: só as pontas encostam na placa
        for (s = [-1, 1]) translate([s * (gap/2 + 3.5), 0, 0]) furo(3.4);
    }
}

if (PECA == "corpo") corpo();
if (PECA == "base") base();
if (PECA == "topo") rotate([180, 0, 0]) translate([0, 0, -E_TOPO]) topo();      // face de cima na mesa
if (PECA == "pino") pino_argola();
if (PECA == "chassi") chassi();
if (PECA == "suporte_led") suporte_led();
if (PECA == "presilha") presilha();
if (PECA == "presilha_lipo") presilha(GAP_LIPO, 0);
