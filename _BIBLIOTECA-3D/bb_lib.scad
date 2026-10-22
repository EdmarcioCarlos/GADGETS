// =====================================================================
//  BLACK BIRD - biblioteca comum das peças 3D (OpenSCAD)
//  Usada por todos os arquivos NN-PROJETO/3D/pecas.scad
// =====================================================================
$fn = 48;
FONTE = "Liberation Sans:style=Bold";
PROF_LOGO = 0.6;          // profundidade da gravação "BLACK BIRD"
FOLGA = 0.3;              // folga de encaixe entre peças impressas
// RESISTÊNCIA A TIRO (BB a mais de 10 m, até ~2 J): paredes expostas >= 3 mm,
// painéis >= 4 mm, PETG, 5 perímetros, 5 camadas topo/fundo, 40% giroide.
PAREDE = 3.0;

// ---------- formas básicas ----------
module rrect(x, y, r) {                       // retângulo 2D com cantos arredondados
    rr = min(r, x/2 - 0.01, y/2 - 0.01);
    if (rr <= 0) square([x, y]);
    else translate([rr, rr]) offset(r = rr) square([x - 2*rr, y - 2*rr]);
}
module rbox(x, y, z, r = 3) { linear_extrude(z) rrect(x, y, r); }

// caixa aberta em cima: parede p, fundo f
module caixa(x, y, z, p = 3, f = 3, r = 3) {
    difference() {
        rbox(x, y, z, r);
        translate([p, p, f]) rbox(x - 2*p, y - 2*p, z, max(r - p, 0.5));
    }
}

// tampa plana com aba interna que encaixa na caixa (aba para baixo, impressa de cabeça para baixo)
module tampa(x, y, e = 3, p = 3, aba = 3, r = 3) {
    rbox(x, y, e, r);
    translate([p + FOLGA, p + FOLGA, e - 0.01])
        difference() {
            rbox(x - 2*(p + FOLGA), y - 2*(p + FOLGA), aba, max(r - p, 0.5));
            translate([1.6, 1.6, -0.1]) rbox(x - 2*(p + FOLGA) - 3.2, y - 2*(p + FOLGA) - 3.2, aba + 1, 0.5);
        }
}

// pino com furo para parafuso (M2: f=1.7 · M3: f=2.6 auto-atarraxante)
module pino(h, d = 7, f = 2.6) {
    difference() { cylinder(h = h, d = d); translate([0, 0, 1]) cylinder(h = h, d = f); }
}
module furo(d, h = 50) { translate([0, 0, -h/2]) cylinder(h = h, d = d); }
module furo_rect(x, y, h = 50) { translate([-x/2, -y/2, -h/2]) cube([x, y, h]); }

// ---------- gravação do nome (sempre "para dentro" da peça) ----------
module _txt(t, s, prof) {
    translate([0, 0, -prof]) linear_extrude(prof + 0.02)
        text(t, size = s, font = FONTE, halign = "center", valign = "center");
}
// use dentro de um difference(), com o centro do texto no ponto da face
module logo_topo(cx, cy, z, s = 5, t = "BLACK BIRD", prof = PROF_LOGO, ang = 0)
    { translate([cx, cy, z]) rotate([0, 0, ang]) _txt(t, s, prof); }
module logo_baixo(cx, cy, s = 5, t = "BLACK BIRD", prof = PROF_LOGO)
    { translate([cx, cy, 0]) mirror([0, 0, 1]) mirror([1, 0, 0]) _txt(t, s, prof); }
module logo_frente(cx, cz, s = 5, t = "BLACK BIRD", prof = PROF_LOGO)      // face y = 0
    { translate([cx, 0, cz]) rotate([90, 0, 0]) _txt(t, s, prof); }
module logo_tras(cx, Y, cz, s = 5, t = "BLACK BIRD", prof = PROF_LOGO)     // face y = Y
    { translate([cx, Y, cz]) rotate([90, 0, 180]) _txt(t, s, prof); }
module logo_dir(X, cy, cz, s = 5, t = "BLACK BIRD", prof = PROF_LOGO)      // face x = X
    { translate([X, cy, cz]) rotate([90, 0, 90]) _txt(t, s, prof); }
module logo_esq(cy, cz, s = 5, t = "BLACK BIRD", prof = PROF_LOGO)         // face x = 0
    { translate([0, cy, cz]) rotate([90, 0, -90]) _txt(t, s, prof); }

// rebaixo para janela de policarbonato 1 mm sobre uma tela (abre na face z = z0)
// vx, vy = área visível; a chapa tem 3 mm a mais de cada lado
module rebaixo_janela(cx, cy, z0, vx, vy, prof = 1.2) {
    translate([cx - vx/2 - 3, cy - vy/2 - 3, z0 - prof]) cube([vx + 6, vy + 6, prof + 1]);
}

// ---------- peças comuns ----------
// capa de botão 6x6: haste que encaixa no botão + cabeça com forma (0 círculo, 1 triângulo, 2 quadrado, 3 losango)
module capa_botao(diam = 9, forma = 0, haste = 4) {
    difference() {
        union() {
            cylinder(h = 2, d = diam + 3);                 // aba que segura por dentro da tampa
            translate([0, 0, 2]) cylinder(h = haste, d = diam);
        }
        translate([0, 0, -0.01]) cylinder(h = 1.6, d = 3.8);   // encaixe no pino do botão
    }
    translate([0, 0, 2 + haste - 0.01]) linear_extrude(1.0) {
        if (forma == 0) circle(d = diam * 0.5);
        if (forma == 1) circle(d = diam * 0.62, $fn = 3);
        if (forma == 2) square(diam * 0.42, center = true);
        if (forma == 3) rotate(45) square(diam * 0.42, center = true);
    }
}

// =====================================================================
//  ESTILO TÁTICO FACETADO (projetos 01, 02, 03, 06 e o conjunto da luneta)
//  Cores: corpo PRETO + tampas/detalhes COYOTE (cada peça de uma cor só).
//  Regra: a parede continua >= 3 mm em todo lugar (inclusive nos cantos
//  chanfrados); o visual vem de material ACRESCENTADO por fora; onde há
//  gravação decorativa a peça ganha a espessura que a gravação tira.
// =====================================================================
function cor_preto()  = "#262626";      // funções (o "use <>" não importa variáveis)
function cor_coyote() = "#8a6a45";

// contorno 2D com os 4 cantos chanfrados a 45° (c = tamanho do chanfro)
module oct2d(x, y, c) { polygon([[c, 0], [x - c, 0], [x, c], [x, y - c], [x - c, y], [c, y], [0, y - c], [0, c]]); }
module prisma_oct(x, y, z, c) { linear_extrude(z) oct2d(x, y, c); }
// octógono regular centrado, com faces alinhadas aos eixos (f = medida de face a face), altura h
module octogono(f, h) { rotate([0, 0, 22.5]) cylinder(h = h, r = f / 2 / cos(22.5), $fn = 8); }

// caixa aberta em cima, cantos chanfrados, parede p igual em todo o contorno.
// children(): pinos e reforços internos (são aparados pela forma externa, nunca vazam)
module caixa_tatica(x, y, z, p = 3, f = 3, c = 4) {
    intersection() {
        union() {
            difference() {
                prisma_oct(x, y, z, c);
                translate([0, 0, f]) linear_extrude(z) offset(delta = -p) oct2d(x, y, c);
            }
            children();
        }
        translate([0, 0, -0.01]) prisma_oct(x, y, z + 0.02, c);
    }
}

// tampa facetada: face de fora em z = 0 (vai na mesa), borda chanfrada ct, aba para cima
module tampa_tatica(x, y, e = 4, p = 3, aba = 3, c = 4, ct = 1.2) {
    hull() {
        translate([0, 0, ct]) linear_extrude(e - ct) oct2d(x, y, c);
        linear_extrude(e) offset(delta = -ct) oct2d(x, y, c);
    }
    translate([0, 0, e - 0.01]) linear_extrude(aba) difference() {
        offset(delta = -(p + FOLGA)) oct2d(x, y, c);
        offset(delta = -(p + FOLGA + 1.6)) oct2d(x, y, c);
    }
}

// placa com a borda de cima chanfrada (children = contorno 2D)
module placa_chanfrada(e, ct = 1.2) {
    hull() { linear_extrude(max(e - ct, 0.01)) children(); linear_extrude(e) offset(delta = -ct) children(); }
}

// emblema BLACK BIRD: pássaro geométrico (asas em V + cabeça); ~22 x 10 mm com s = 1
module emblema2d(s = 1) {
    scale(s) polygon([[-11, 4.5], [-5.5, 2.4], [-2.2, 3], [0, 1.2], [2.2, 3], [5.5, 2.4], [11, 4.5],
                      [6.5, -0.8], [2.4, -1.4], [0, -5.5], [-2.4, -1.4], [-6.5, -0.8]]);
}
module emblema_topo(cx, cy, z, s = 0.8, prof = 0.6, ang = 0)            // gravado na face de cima (z)
    { translate([cx, cy, z - prof]) rotate([0, 0, ang]) linear_extrude(prof + 0.02) emblema2d(s); }
module emblema_baixo(cx, cy, s = 0.8, prof = 0.6, ang = 0)              // gravado na face z = 0 (peça impressa de cara na mesa)
    { translate([cx, cy, 0]) mirror([0, 0, 1]) mirror([1, 0, 0]) rotate([0, 0, ang]) translate([0, 0, -prof]) linear_extrude(prof + 0.02) emblema2d(s); }

// nervuras em V (chevrons) 2D, apontando para +x; n nervuras, altura alt
module nervuras_v2d(n = 3, passo = 4, alt = 18) {
    for (i = [0 : n - 1]) translate([i * passo, 0])
        polygon([[0, -alt/2], [2.2, -alt/2], [5.2, 0], [2.2, alt/2], [0, alt/2], [3, 0]]);
}
module nervuras_topo(x0, cy, z, n = 3, passo = 4, alt = 18, prof = 0.8, ang = 0)   // gravadas na face de cima
    { translate([x0, cy, z - prof]) rotate([0, 0, ang]) linear_extrude(prof + 0.02) nervuras_v2d(n, passo, alt); }
module nervuras_baixo(x0, cy, n = 3, passo = 4, alt = 18, prof = 0.8, ang = 0)     // gravadas na face z = 0
    { translate([x0, cy, 0]) mirror([0, 0, 1]) translate([0, 0, -prof]) rotate([0, 0, ang]) linear_extrude(prof + 0.02) nervuras_v2d(n, passo, alt); }

// moldura octogonal saliente para botão/furo numa face (base em z = 0, cresce para +z)
// d = largura externa na base, alt = quanto sobressai (laterais a 45°, imprime em parede vertical)
module moldura_oct(d = 15, alt = 2) { rotate([0, 0, 22.5]) cylinder(h = alt, d1 = d, d2 = d - 2 * alt, $fn = 8); }

// apoios da tela OLED 0,91" (módulo 38 x 12 sem furos): 2 postes + prateleira; a tela desliza entre os
// postes e a parede e a tampa segura por cima (sem cola). Use dentro de caixa_tatica { } ou num union().
// normal = "x": parede interna no plano x = p (interior em x < p), tela ao longo de y (centro c), altura zc
// normal = "y": parede interna no plano y = p (interior em y > p), tela ao longo de x (centro c)
module apoio_tela(p, c, zc, comp = 38, alt = 12, folga = 3.2, normal = "x") {
    for (s = [-1, 1]) {
        if (normal == "x") {
            translate([p - folga - 2, c + s * (comp/2 - 3) - 1.5, zc - alt/2 - 1.5]) cube([2, 3, alt + 1.5]);
            translate([p - folga - 2, c + s * (comp/2 - 3) - 1.5, zc - alt/2 - 1.5]) cube([folga + 2.01, 3, 1.5]);
        } else {
            translate([c + s * (comp/2 - 3) - 1.5, p + folga, zc - alt/2 - 1.5]) cube([3, 2, alt + 1.5]);
            translate([c + s * (comp/2 - 3) - 1.5, p - 0.01, zc - alt/2 - 1.5]) cube([3, folga + 2.01, 1.5]);
        }
    }
}

// painel hexagonal em relevo (base 0,4 + favos até e), acrescentado por fora de uma parede
module hex_relevo(x, y, e = 1, celula = 2.6) { union() { cube([x, y, 0.4]); favos(x, y, e, celula, 0.9); } }

// grade de favos hexagonais (para kill flash / proteção)
module favos(x, y, e, celula = 3.2, parede = 0.8) {
    passo = celula + parede;
    intersection() {
        cube([x, y, e]);
        difference() {
            cube([x, y, e]);
            for (i = [-1 : x / passo + 1], j = [-1 : y / (passo * 0.866) + 1])
                translate([i * passo + (j % 2) * passo / 2, j * passo * 0.866, -1])
                    cylinder(h = e + 2, d = celula / 0.866, $fn = 6);
        }
    }
}
