// =====================================================================
//  04 - CRONÓGRAFO · peças 3D
//  Escolha a peça em PECA, F6 (render) e F7 (exportar STL). Medidas em mm.
//  ESTILO TÁTICO FACETADO · cores: túnel, tampa de baixo e adaptador em PRETO
//  (preto também ajuda os sensores IR) · visor em COYOTE
// =====================================================================
use <../../_BIBLIOTECA-3D/bb_lib.scad>
$fn = 64;

PECA = "tunel";   // tunel | visor | tampa_inferior | adaptador_boca

// ---------- medidas ----------
L = 160; W = 44; H = 66;         // túnel
FURO = 25;                       // diâmetro do túnel da BB
FZ = 45.5;                       // altura do centro do túnel
BX = [30, 130];                  // barreiras (100 mm entre elas)
BAIA_Z = 27;                     // teto da baia da eletrônica
QUEBRA_CHAMA_D = 24;             // CONFIRA: diâmetro externo do quebra-chamas da sua arma
C = 6;                           // chanfro dos cantos (estilo tático facetado)
ADAPT_FUROS = 14;                // parafusos do adaptador de boca: ±14 mm do centro (fora do chanfro)

module teardrop(d, l) {          // furo horizontal que imprime sem suporte
    rotate([0, 90, 0]) linear_extrude(l) hull() { circle(d = d); translate([-d/2 * 0.75, 0]) rotate(45) square(d/2 * 0.75 * 1.1, center = true); }
}

// ===================== TÚNEL =====================
module tunel() {
    difference() {
        union() {
            prisma_oct(L, W, H, C);
            translate([10, 0.01, 4]) rotate([90, 0, 0]) hex_relevo(40, 18, 1);      // painel hexagonal (lado direito)
        }
        translate([-1, W/2, FZ]) rotate([180, 0, 0]) translate([0, 0, 0]) teardrop_x(FURO, L + 2);
        // baia da eletrônica (aberta embaixo, fechada pela tampa); cantos chanfrados para a parede ficar >= 3 mm
        translate([4, 3, -1]) prisma_oct(L - 8, W - 6, BAIA_Z + 1, 3.5);
        // visual no topo (8 mm de material acima do túnel): nervuras em V apontando para a boca + emblema
        nervuras_topo(104, W/2, H, 3, 5, 22, 0.8, 180);
        // barreiras: LED em cima, fototransistor embaixo (5 mm por fora, 3 mm na boca)
        for (bx = BX) {
            translate([bx, W/2, FZ + FURO/2 + 2.5]) cylinder(h = 20, d = 5.05);
            translate([bx, W/2, FZ]) cylinder(h = 20, d = 3);
            translate([bx, W/2, BAIA_Z - 1]) cylinder(h = FZ - FURO/2 - 2 - BAIA_Z + 1, d = 5.05);
            translate([bx, W/2, BAIA_Z]) cylinder(h = FZ - BAIA_Z, d = 3);
        }
        // canal do cabo da tela (do visor até a baia, por dentro da parede)
        translate([12, 6, BAIA_Z - 1]) cylinder(h = H, d = 4);
        // furos do visor (M3) e do adaptador de boca (M3, na face da frente)
        for (yy = [4.5, W - 4.5]) translate([30.5, yy, H - 8]) cylinder(h = 9, d = 2.6);
        for (yy = [W/2 - ADAPT_FUROS, W/2 + ADAPT_FUROS]) translate([-1, yy, 40]) rotate([0, 90, 0]) cylinder(h = 11, d = 2.6);
        // lateral direita: chave e USB-C
        translate([140 - 4.25, W - 3 - 1, 13]) cube([8.5, 5, 3.8]);
        translate([118 - 4.75, W - 3 - 1, 6]) cube([9.5, 5, 3.8]);
        // nome nas duas laterais
        // MARCA DO PROJETO (única): emblema + nome na lateral, na altura do túnel (parede de 9,5 mm)
        translate([45, 0, FZ]) rotate([90, 0, 0]) translate([0, 0, -0.6]) linear_extrude(0.62) emblema2d(0.9);
        logo_frente(98, FZ, 7);
    }
    // pinos da tampa inferior
    for (c = [[9, 8], [L - 9, 8], [9, W - 8], [L - 9, W - 8]])
        translate([c[0], c[1], 0]) difference() { cylinder(h = BAIA_Z, d = 7); translate([0,0,-1]) cylinder(h = 12, d = 2.6); }
}
module teardrop_x(d, l) {        // túnel ao longo de X com ponta para cima
    rotate([0, 90, 0]) linear_extrude(l) hull() { circle(d = d); translate([d/2 * 0.62, 0]) square(d * 0.42, center = true); }
}

// ===================== VISOR DA TELA =====================
module perfil_visor() { polygon([[0, 0], [26, 0], [26, 28], [15, 28], [0, 2]]); }
module visor() {
    difference() {
        union() {
            rotate([90, 0, 0]) translate([0, 0, -W]) linear_extrude(W) perfil_visor();
            for (yy = [0, W - 9]) translate([26, yy, 0]) cube([9, 9, 4]);      // orelhas de fixação
        }
        // oco por dentro (aberto embaixo)
        translate([0, 3, -0.01]) rotate([90, 0, 0]) translate([0, 0, -(W - 6)]) linear_extrude(W - 6)
            offset(delta = -3) perfil_visor();
        translate([3, 3, -1]) cube([20, W - 6, 4.5]);
        // janela da tela na face inclinada (60°) + rebaixo para o policarbonato
        translate([7.5, W/2, 15]) rotate([0, -60, 0]) {
            cube([12, 22, 12], center = true);
            cube([18, 28, 2.4], center = true);
        }
        // botões PESO e ZERAR no topo
        for (yy = [9, W - 9]) translate([20.5, yy, 20]) cylinder(h = 10, d = 7.2);
        for (yy = [4.5, W - 4.5]) translate([30.5, yy, -1]) cylinder(h = 6, d = 3.4);
    }
}

// ===================== TAMPA INFERIOR =====================
module tampa_inferior() {       // face de fora em z = 0 (na mesa), borda chanfrada
    difference() {
        hull() { translate([0, 0, 1]) prisma_oct(L, W, 2, C); linear_extrude(3) offset(delta = -1) oct2d(L, W, C); }
        for (c = [[9, 8], [L - 9, 8], [9, W - 8], [L - 9, W - 8]]) translate([c[0], c[1], 0]) { furo(3.4); translate([0, 0, -0.01]) cylinder(h = 1.8, d1 = 6.5, d2 = 3.4); }
    }
}

// ===================== ADAPTADOR DE BOCA =====================
module adaptador_boca() {        // placa encosta na frente do túnel; o quebra-chamas entra no colar
    di = QUEBRA_CHAMA_D + 0.4;
    difference() {
        union() {
            translate([-W/2, -24, 0]) prisma_oct(W, 30, 4, C);
            translate([0, 0, 0]) cylinder(h = 28, d = di + 6);
        }
        translate([0, 0, -1]) cylinder(h = 6, d = FURO);
        translate([0, 0, 3]) cylinder(h = 30, d = di);
        for (xx = [-ADAPT_FUROS, ADAPT_FUROS]) translate([xx, 40 - FZ, 0]) furo(3.4);
    }
}

if (PECA == "tunel") tunel();
if (PECA == "visor") visor();
if (PECA == "tampa_inferior") tampa_inferior();
if (PECA == "adaptador_boca") adaptador_boca();
