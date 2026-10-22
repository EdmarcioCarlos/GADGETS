// 06 - ANPEQ · MONTAGEM (só para os desenhos da prévia; não é para imprimir)
// x para a frente (cano), y = 0 no lado direito, z = 0 em cima do trilho
include <pecas.scad>
$fn = 40;
EXTRAS = true;           // false = só as peças impressas (usado para as cotas)
CORTE = false;           // true = corta no eixo do laser (tira o lado esquerdo) para ver o pivô, as torres e a mola
PECA = "nenhuma";        // desliga as saídas do pecas.scad

COR = "todas";           // filtro usado pela prévia geral no AEG: "todas" | "preto" | "coyote"
module pinta(c) {
    if (COR == "todas") color(c == 0 ? cor_preto() : cor_coyote()) children();
    else if (COR == (c == 0 ? "preto" : "coyote")) children();
}
module cortar() { if (CORTE) intersection() { children(); translate([-50, -50, -50]) cube([300, 50 + AY + 0.4, 200]); } else children(); }

module tudo() {
    pinta(0) render() cortar() caixa();       // render(): sem ele a prévia do OpenSCAD mistura as cores das peças ocas
    pinta(1) render() cortar() translate([0, Y, H + E]) rotate([180, 0, 0]) tampa();
    pinta(0) render() cortar() berco();
    pinta(0) render() cortar() trava_pivo();
    pinta(1) render() cortar() protecao_bb();                                  // proteção anti-BB na frente
    pinta(1) cortar() translate([TORRE_X, AY, H + E]) botao_torre();          // torre de cima (elevação)
    pinta(1) cortar() do_lado() botao_torre();                                 // torre do lado direito (deriva)
    for (gx = GARRAS_X) pinta(1) cortar() translate([gx - 10, Y/2, 0]) mandibula();
    if (EXTRAS) cortar() {
        color("#3d8f3d") translate([TUBO_X0 + 2, AY, AZ]) rotate([0, 90, 0]) cylinder(h = LASER_L - 2, d = 12);     // módulo laser verde
        color("#b8ffb0") translate([TUBO_X1 - 0.5, AY, AZ]) rotate([0, 90, 0]) cylinder(h = 0.6, d = 6);           // lente
        color("#c9a227") translate([6, AY - 8.5, 6.5 + 3]) rotate([0, 90, 0]) translate([-0, 8.5, 0]) cylinder(h = 34, d = 17);   // pilha 16340
        color("#1d1d1d") translate([5, AY - 10, 6.5]) difference() { cube([40, 20, 13]); translate([2, 1.5, 2]) cube([36, 17, 12]); }   // suporte da pilha
        color("#7a1f1f") translate([3.2, AY - 8.5, 3]) cube([28, 17, 1.6]);                                          // TP4056 USB-C
        color("#b8bec2") translate([2.8, AY - 4.5, 4.6]) cube([7.5, 9, 3.2]);                                        // USB-C
        color("#b8bec2") translate([3, 8.5, 20]) rotate([0, 90, 0]) cylinder(h = 12, d = 8);                         // jack P2 3,5 mm
        color("#151515") translate([3, Y - 12.5, 16]) cube([12, 8, 8]);                                              // chave CONTÍNUO
        color("#9aa4aa") translate([-5, Y - 8.5, 20]) rotate([0, 90, 0]) cylinder(h = 8, d = 2.5);                  // alavanca
        // parafusos das torres (cabeça no berço + contraporca no canal sextavado)
        color("#9aa4aa") translate([TORRE_X, AY, AZ + BERCO_D/2]) { cylinder(h = 3, d = 5.5); cylinder(h = 15, d = 3); translate([0, 0, 3]) cylinder(h = 2.4, d = 6.2, $fn = 6); }
        color("#9aa4aa") translate([TORRE_X, AY - BERCO_D/2, AZ]) rotate([90, 0, 0]) { cylinder(h = 3, d = 5.5); cylinder(h = 18, d = 3); translate([0, 0, 3]) cylinder(h = 2.4, d = 6.2, $fn = 6); }
        // mola diagonal
        color("#c0c0c0") translate([TORRE_X, AY, AZ]) rotate([45, 0, 0]) translate([0, 0, -15.2]) cylinder(h = 7.7, d = 5);
        // BBs dos cliques
        color("#f2efe6") translate([TORRE_X - 9, AY, H + E - 4 - 2]) sphere(d = 6);
        color("#f2efe6") translate([TORRE_X - 9, 4 + 2, AZ]) sphere(d = 6);
        // trilho Picatinny (referência)
        if (!CORTE) color("#4a4f54") translate([-10, AY - TRILHO_L/2, -9.4]) cube([X + 20, TRILHO_L, 9.4]);
    }
}
tudo();
