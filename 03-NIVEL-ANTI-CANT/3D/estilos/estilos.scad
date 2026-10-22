// =====================================================================
//  03 - NÍVEL ANTI-CANT · PRÉVIA DE ESTILOS (só para ver, não é para imprimir)
//  ESTILO = "A" tático facetado · "B" arredondado liso · "C" rugged (misto)
//  Cores: preto + coyote. Cada peça tem UMA cor só (sem troca de filamento).
//  Mesmas medidas internas do pecas.scad: paredes de 3 mm continuam iguais;
//  o visual vem de material ACRESCENTADO por fora.
// =====================================================================
use <../../../_BIBLIOTECA-3D/bb_lib.scad>
$fn = 40;

ESTILO = "A";
PRETO  = "#262626";
COYOTE = "#8a6a45";
TRILHO = "#55595d";

X = 50; Y = 30; H = 19; P = 3;
TRILHO_L = 21.2; GARRA_H = 6.4;

// ---------- formas ----------
module cbox(x, y, z, c) {          // caixa com cantos e topo chanfrados (45°)
    hull() {
        translate([c, 0, 0]) cube([x - 2*c, y, z - c]);
        translate([0, c, 0]) cube([x, y - 2*c, z - c]);
        translate([c, c, 0]) cube([x - 2*c, y - 2*c, z]);
    }
}
module chanfro_base(x, y, z, c) {  // só cantos verticais chanfrados (sem chanfro em cima)
    hull() { translate([c, 0, 0]) cube([x - 2*c, y, z]); translate([0, c, 0]) cube([x, y - 2*c, z]); }
}
module rround(x, y, z, r, rt) {    // cantos com raio r e borda de cima boleada rt
    hull() for (cx = [r, x - r], cy = [r, y - r]) translate([cx, cy, 0]) {
        cylinder(h = z - rt, r = r);
        translate([0, 0, z - rt]) scale([1, 1, rt / r]) sphere(r = r);
    }
}
module emblema(s = 1) {            // pássaro geométrico BLACK BIRD (asas em V + cabeça)
    scale(s) polygon([[-11, 4.5], [-5.5, 2.4], [-2.2, 3], [0, 1.2], [2.2, 3], [5.5, 2.4], [11, 4.5],
                      [6.5, -0.8], [2.4, -1.4], [0, -5.5], [-2.4, -1.4], [-6.5, -0.8]]);
}
module emblema_topo(cx, cy, z, s = 0.8, prof = 0.6) {
    translate([cx, cy, z - prof]) linear_extrude(prof + 0.02) emblema(s);
}
module hex_painel(x, y, e = 1) {   // relevo hexagonal (acrescentado por fora)
    difference() { cube([x, y, e]); translate([0, 0, 0.4]) favos(x, y, 2, 2.6, 0.9); }
}

// ---------- trilho e garras (iguais nos 3 estilos) ----------
module trilho() {
    color(TRILHO) translate([-25, Y/2, -GARRA_H]) rotate([90, 0, 90]) linear_extrude(100)
        polygon([[-TRILHO_L/2, 0], [TRILHO_L/2, 0], [TRILHO_L/2, -2.8], [TRILHO_L/2 - 2.8, -5.6],
                 [-TRILHO_L/2 + 2.8, -5.6], [-TRILHO_L/2, -2.8]]);
    color("#3b3f43") translate([-25, Y/2 - 7.8, -GARRA_H - 5.6 - 4]) cube([100, 15.6, 4]);
}
module garra(lado) {
    mirror([0, lado > 0 ? 1 : 0, 0]) rotate([90, 0, 90]) linear_extrude(20)
        polygon([[-TRILHO_L/2 - 4, 0], [-TRILHO_L/2 + 0.2, 0], [-TRILHO_L/2 + 3, -2.8],
                 [-TRILHO_L/2 + 3, -GARRA_H], [-TRILHO_L/2 - 4, -GARRA_H]]);
}
module garras() {
    color(PRETO) translate([X/2 - 10, Y/2, 0]) garra(-1);
    color(ESTILO == "B" ? PRETO : COYOTE) translate([X/2 - 10, Y/2, 0]) garra(1);   // mandíbula
    color("#9aa0a4") translate([X/2, -3, -2.6]) rotate([-90, 0, 0]) cylinder(h = Y + 6, d = 4);   // parafuso M4
    color("#9aa0a4") translate([X/2, -3, -2.6]) rotate([-90, 0, 0]) cylinder(h = 3, d = 7, $fn = 6);
}

// ---------- furos comuns da lateral (ZERAR e chave) ----------
module furos_lateral() {
    translate([12, -2, 10]) rotate([-90, 0, 0]) cylinder(h = P + 4, d = 7.4);
    translate([36.25 - 4.5, -2, 8.2]) cube([9, P + 4, 4]);
}
module botao_zerar() { color(COYOTE) translate([12, 0.6, 10]) rotate([90, 0, 0]) cylinder(h = 2.4, d = 6.6); }

// ===================== ESTILO A: TÁTICO FACETADO =====================
module estilo_A() {
    color(PRETO) difference() {
        union() {
            chanfro_base(X, Y, H, 4);
            // moldura chanfrada que protege o botão ZERAR (saliente 2 mm)
            translate([12, 0, 10]) rotate([90, 0, 0]) cylinder(h = 2, d1 = 15, d2 = 11, $fn = 8);
            // painel hexagonal em relevo na lateral direita
            translate([8, Y - 0.01, 4]) rotate([90, 0, 0]) mirror([0, 0, 1]) hex_painel(34, 11, 1);
        }
        furos_lateral();
        translate([12, -2.5, 10]) rotate([-90, 0, 0]) cylinder(h = 6, d = 7.4);
        logo_frente(X/2 + 6, 4.5, 3.2, "BB");
    }
    // tampa coyote facetada com nervuras em V
    color(COYOTE) translate([0, 0, H]) difference() {
        union() {
            cbox(X, Y, 4, 2.5);
            for (i = [0:2]) translate([8 + i * 4, Y/2, 3.99]) linear_extrude(1.2) polygon([[0, -9], [2.2, -9], [5.2, 0], [2.2, 9], [0, 9], [3, 0]]);
        }
        emblema_topo(35, Y/2, 4, 0.8, 0.8);
    }
    botao_zerar();
}

// ===================== ESTILO B: ARREDONDADO LISO =====================
module estilo_B() {
    color(PRETO) difference() {
        union() {
            rround(X, Y, H, 6, 0.01 + 0.5);
            translate([12, 0, 10]) rotate([90, 0, 0]) cylinder(h = 1.6, d1 = 13, d2 = 11);   // anel liso do botão
        }
        furos_lateral();
        translate([12, -2, 10]) rotate([-90, 0, 0]) cylinder(h = 6, d = 7.4);
        logo_frente(X/2 + 6, 4.5, 3.2, "BB");
    }
    color(COYOTE) translate([0, 0, H]) difference() {
        rround(X, Y, 4, 6, 3);
        emblema_topo(X/2, Y/2 + 3, 4, 0.8, 0.8);
        translate([X/2, Y/2 - 7, 4 - 0.6]) linear_extrude(1) text("BLACK BIRD", size = 3, font = "Liberation Sans:style=Bold", halign = "center", valign = "center");
    }
    botao_zerar();
}

// ===================== ESTILO C: RUGGED (MISTO) =====================
module estilo_C() {
    color(PRETO) difference() {
        chanfro_base(X, Y, H, 2.5);
        furos_lateral();
        logo_frente(X/2 + 6, 4.5, 3.2, "BB");
    }
    // tampa coyote com cantoneiras que descem e abraçam os 4 cantos (protegem das pancadas)
    color(COYOTE) translate([0, 0, H]) difference() {
        union() {
            translate([-1.5, -1.5, 0]) rround(X + 3, Y + 3, 4, 4, 2);
            for (cx = [0, 1], cy = [0, 1]) translate([cx * (X + 3) - 1.5, cy * (Y + 3) - 1.5, -11])
                mirror([cx, 0, 0]) mirror([0, cy, 0]) difference() {
                    rround(11, 11, 11.01, 4, 0.01);
                    translate([1.5, 1.5, -1]) cube([20, 20, 20]);
                }
        }
        emblema_topo(X/2, Y/2 + 3, 4, 0.8, 0.8);
        translate([X/2, Y/2 - 7, 4 - 0.6]) linear_extrude(1) text("BLACK BIRD", size = 2.8, font = "Liberation Sans:style=Bold", halign = "center", valign = "center");
    }
    // anel arredondado coyote no botão
    color(COYOTE) translate([12, 0.01, 10]) rotate([90, 0, 0]) difference() { cylinder(h = 1.8, d = 13); translate([0, 0, -1]) cylinder(h = 4, d = 7.6); }
    botao_zerar();
}

trilho();
garras();
if (ESTILO == "A") estilo_A();
if (ESTILO == "B") estilo_B();
if (ESTILO == "C") estilo_C();
