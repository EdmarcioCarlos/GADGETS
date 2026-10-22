// =====================================================================
//  12 - TELÊMETRO COM ZONA DE ENGAJAMENTO · peças 3D
//  Escolha a peça em PECA, F6 (render) e F7 (exportar STL). Medidas em mm.
//  X = comprimento (0 = frente/capuz, 76 = traseira/tela)
//  Y = largura (0 = lado DIREITO do rifle, 44 = lado ESQUERDO)
//  ESTILO TÁTICO FACETADO · cores: corpo, grade e berço em PRETO ·
//  tampa, tampa do anel e capa do botão em COYOTE
// =====================================================================
use <../../_BIBLIOTECA-3D/bb_lib.scad>
$fn = 48;

PECA = "corpo";   // corpo | tampa | grade | berco_laser | capa_botao | tampa_anel

L = 76; W = 44; H = 18;        // corpo (a tampa de 4 mm completa 22; a moldura da boca sai 2 mm para a frente)
CAPUZ = 6;                     // capuz anti-BB na frente
P = 3;
PINOS = [[11, 40.5], [63, 40.5], [63, 3.5]];       // os de trás ficam longe da tela (x 63)

// ---------- tampa do anel da Geissele (CONFIRA com paquímetro na sua réplica) ----------
TUBO_D = 30;              // diâmetro do tubo da luneta
ANEL_LARG = 18;           // largura do anel (ao longo do tubo)
PARAF_LAT = 41;           // distância entre os parafusos de um lado e do outro (atravessado)
PARAF_LONG = 10;          // distância entre os 2 parafusos do mesmo lado (ao longo do tubo)
PARAF_D = 4.3;            // furo do parafuso original (M4 = 4.3)
ALT_BASE = 24;            // altura da base do telêmetro acima do eixo da luneta

// ---------- estilo tático: cantos de trás chanfrados; a frente (capuz) fica reta e ganha a moldura protetora ----------
C = 3;                         // chanfro dos cantos de trás
E_TAMPA = 4;                   // 3 mm úteis + 1 mm para as gravações decorativas
module forma_tel(x0 = 0) { polygon([[x0, 0], [L - C, 0], [L, C], [L, W - C], [L - C, W], [x0, W]]); }
module protetor_boca() {       // moldura facetada saliente 2 mm em volta da boca do capuz (a BB bate nela antes da grade)
    difference() {
        rotate([90, 0, 90]) mirror([0, 0, 1]) hull() { linear_extrude(0.01) oct2d(W, H, 2); linear_extrude(2) offset(delta = -1.5) oct2d(W, H, 2); }
        translate([-3, P, P]) cube([4, W - 2*P, H - 2*P]);
    }
}

// ===================== CORPO (preto) =====================
module corpo() {
    difference() {
        union() {
            intersection() {
                union() {
                    difference() {
                        linear_extrude(H) forma_tel();
                        translate([0, 0, P]) linear_extrude(H) offset(delta = -P) forma_tel(CAPUZ);   // caixa
                        translate([-1, P, P]) cube([CAPUZ + 1, W - 2*P, H - 2*P]);                   // capuz
                    }
                    for (c = PINOS) translate([c[0], c[1], 0]) pino(H, 7, 2.6);
                    apoio_tela(L - P, W/2, 10.5);                                         // apoios da OLED (sem cola)
                }
                translate([0, 0, -0.01]) linear_extrude(H + 0.02) forma_tel();       // pinos não vazam no chanfro
            }
            protetor_boca();
            for (xx = [20, 36]) translate([xx, W - 0.01, 10.5]) rotate([-90, 0, 0]) moldura_oct(14, 2);   // molduras: liga/desliga e MARCAR
            translate([9, 0.01, 4]) rotate([90, 0, 0]) hex_relevo(18, 11, 1);                           // painel hexagonal (lado direito)
        }
        // janelas das lentes do laser (parede da frente), com a divisória no meio
        translate([CAPUZ - 1, 4, 4]) cube([P + 2, 11, 11]);
        translate([CAPUZ - 1, 16.6, 4]) cube([P + 2, 11.4, 11]);
        // tela OLED 0,91" na traseira + rebaixo do policarbonato
        translate([L - P - 1, W/2 - 11.5, 10.5 - 3.2]) cube([P + 2, 23, 6.4]);
        translate([L - 1.2, W/2 - 14.5, 10.5 - 6.2]) cube([2, 29, 12.4]);
        // lado esquerdo (Y = 44): botão liga/desliga 8x8 e USB-C
        translate([20 - 4.3, W - P - 1, 10.5 - 4.3]) cube([8.6, P + 4, 8.6]);
        translate([58.5 - 4.75, W - P - 1, 13 - 1.9]) cube([9.5, P + 2, 3.8]);
        // furo de romper para um botão extra no futuro: fica fechado por 0,6 mm (na moldura); pode ignorar
        translate([36, W - P - 1, 10.5]) rotate([-90, 0, 0]) cylinder(h = P + 1 + 2 - 0.6, d = 9.6);
        // lado direito (Y = 0): parafuso de deriva do laser
        translate([32, -1, 9]) rotate([-90, 0, 0]) cylinder(h = P + 2, d = 3.4);
        // fundo: 2 parafusos M3 até a tampa do anel (cabeça por dentro)
        for (xx = [30, 52]) translate([xx, W/2, 0]) { furo(3.4); translate([0, 0, P - 1.6]) cylinder(h = 2, d = 6.5); }
    }
}

// ===================== TAMPA (coyote) =====================
module tampa_uso() {        // na posição de uso: aba embaixo (z 0..2.5), placa em cima (z 2.5..6.5)
    difference() {
        union() {
            translate([0, 0, 2.5]) placa_chanfrada(E_TAMPA, 1.2) forma_tel();
            translate([CAPUZ + P + 0.3, P + 0.3, 0]) difference() {
                cube([L - CAPUZ - 2*P - 0.6, W - 2*P - 0.6, 2.51]);
                translate([1.6, 1.6, -0.1]) cube([L - CAPUZ - 2*P - 3.8, W - 2*P - 3.8, 3]);
            }
        }
        for (c = PINOS) translate([c[0], c[1], 0]) { translate([0, 0, -1]) cylinder(h = 3.5, d = 7.6); furo(3.4); translate([0, 0, 5.3]) cylinder(h = 2, d = 6); }
        translate([32, 21, 0]) furo(3.4);                                   // parafuso de elevação do laser
        for (xx = [45, 67]) translate([xx, W/2, 3.5]) cylinder(h = 4, d = 2.6);   // furos cegos de reserva para um acessório em cima da tampa (M3)
        translate([56, W/2, -1]) cylinder(h = 1 + 6.5 - 0.6, d = 4);              // passagem de cabo de reserva: furo de romper (0,6 mm por cima)
        // visual (gravado 0,8 mm no 1 mm extra): nervuras em V apontando para o cano + nome
        nervuras_topo(20, 21, 6.5, 3, 4, 16, 0.8, 180);
        // MARCA DO PROJETO (única): nome em cima das nervuras, emblema embaixo
        logo_topo(21, 36.3, 6.5, 3.4, prof = 0.8);
        emblema_topo(21, 7.5, 6.5, 0.5, 0.8);
        // a metade de trás fica lisa (espaço livre para um acessório no futuro)
    }
}
module tampa_tel() { translate([0, W, 6.5]) rotate([180, 0, 0]) tampa_uso(); }   // impressa com a face de cima na mesa

// ===================== GRADE ANTI-BB (favos) =====================
module grade() {            // 37,4 x 11,4 x 5: encaixa na boca do capuz (PETG preto fosco)
    GX = W - 2*P - 0.6; GY = H - 2*P - 0.6;
    union() {
        favos(GX, GY, 5, 3.2, 0.8);
        difference() { cube([GX, GY, 5]); translate([1, 1, -1]) cube([GX - 2, GY - 2, 7]); }   // moldura
        translate([15.5 - P - 0.3 - 0.8, 0, 0]) cube([1.6, GY, 5]);                              // divisória entre as lentes
    }
}

// ===================== BERÇO DO LASER =====================
module berco_laser() {
    difference() {
        rbox(31.5, 29, 6, 1.5);
        translate([2, 2, 2]) cube([27.7, 25.4, 10]);      // laser 27,5 x 25
        translate([-1, 4, 2]) cube([4, 21, 10]);          // frente aberta (lentes)
        translate([24, 14.5, -1]) cylinder(h = 5, d = 6); // apoio da mola
    }
}

// ===================== CAPA DO BOTÃO 8x8 =====================
module capa_botao_8() {
    difference() {
        union() { prisma_oct(10.4, 10.4, 1, 2); translate([1.2, 1.2, 0]) prisma_oct(8, 8, 6, 1.6); }
        translate([5.2 - 1.85, 5.2 - 1.85, -0.01]) cube([3.7, 3.7, 3.5]);
    }
}

// ===================== TAMPA DO ANEL DIANTEIRO DA GEISSELE =====================
module tampa_anel() {       // na posição de uso: eixo do tubo em X, z = 0 no centro do tubo
    R = TUBO_D/2; E = 4.5;
    difference() {
        union() {
            intersection() {          // meia-lua do anel
                rotate([0, 90, 0]) translate([0, 0, -ANEL_LARG/2]) cylinder(h = ANEL_LARG, r = R + E, $fn = 96);
                translate([-ANEL_LARG/2, -50, 0]) cube([ANEL_LARG, 100, 50]);
            }
            translate([-ANEL_LARG/2, -PARAF_LAT/2 - 6, 0]) prisma_oct(ANEL_LARG, PARAF_LAT + 12, 5, 3);   // orelhas
            translate([-ANEL_LARG/2, -10, R + E - 2]) cube([ANEL_LARG, 20, ALT_BASE - R - E + 2]);   // pedestal
            translate([-ANEL_LARG/2, -W/2, ALT_BASE]) prisma_oct(44, W, 4, 3);                      // base do telêmetro (avança para a frente)
            translate([19, 0, ALT_BASE - 4]) cylinder(h = 4.01, d = 9);                              // reforço do parafuso da frente
        }
        rotate([0, 90, 0]) translate([0, 0, -50]) cylinder(h = 100, r = R + 0.1, $fn = 96);
        for (sx = [-1, 1], sy = [-1, 1]) translate([sx * PARAF_LONG/2, sy * PARAF_LAT/2, 0]) {
            furo(PARAF_D); translate([0, 0, 5]) cylinder(h = 30, d = 8.5);      // acesso da chave por cima (antes de montar o telêmetro)
        }
        for (xx = [-3, 19]) translate([xx, 0, ALT_BASE - 8]) cylinder(h = 13, d = 2.6);   // parafusos do telêmetro (22 mm entre eles)
    }
}

if (PECA == "corpo") corpo();
if (PECA == "tampa") tampa_tel();
if (PECA == "grade") grade();
if (PECA == "berco_laser") berco_laser();
if (PECA == "capa_botao") capa_botao_8();
if (PECA == "tampa_anel") translate([0, 0, ALT_BASE + 4]) rotate([180, 0, 0]) tampa_anel();   // impressa de cabeça para baixo
