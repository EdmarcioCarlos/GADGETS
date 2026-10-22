// =====================================================================
//  06 - ANPEQ (LASER VERDE COM AJUSTE) · peças 3D
//  Escolha a peça em PECA, F6 (render) e F7 (exportar STL). Medidas em mm.
//  ESTILO TÁTICO FACETADO · cores: caixa, berço, trava do pivô e anéis em PRETO
//                                  tampa (com a marca), 2 botões das torres e 2 mandíbulas em COYOTE
//
//  COMO FUNCIONA: o módulo laser verde (Ø 12) vai num BERÇO que gira numa bola (pivô) atrás.
//  Na frente, 2 parafusos M3 empurram o berço: um de CIMA (elevação) e um do lado DIREITO (deriva).
//  Uma mola na diagonal de baixo/esquerda segura o berço contra os parafusos.
//  Cada TORRE: você gira o botão; ele gira uma porca presa dentro dele; o parafuso não gira
//  (uma contraporca dele corre num canal sextavado) e por isso anda 0,5 mm por volta.
//  Clique: uma BB de 6 mm com mola encosta nas 20 ranhuras de baixo do botão = 20 cliques por volta.
//  1 clique = 0,025 mm no berço, a 44 mm do pivô = 0,57 mrad ≈ 2,8 cm a 50 m.
//  Eixos: x para a frente (cano), y = 0 no lado DIREITO, z = 0 em cima do trilho.
// =====================================================================
use <../../_BIBLIOTECA-3D/bb_lib.scad>
$fn = 48;

PECA = "caixa";   // caixa | tampa | berco | trava_pivo | botao_torre | mandibula

X = 110; Y = 46; H = 33;  // caixa por fora (a tampa de 4 mm completa 37)
P = 3; C = 4; E = 4;
CANTOS = [[5, 5], [X - 5, 5], [5, Y - 5], [X - 5, Y - 5]];
TRILHO_L = 21.2; GARRA_H = 6.4;      // Picatinny (igual ao anti-cant)
GARRAS_X = [30, 80];                 // 2 garras (cada uma com mandíbula e parafuso M3 atravessado)

// laser e berço
LASER_D = 12.2; LASER_L = 45;        // módulo laser verde Ø 12 x 45 (CONFIRA o seu)
AY = Y / 2; AZ = 14;                 // eixo do laser
BERCO_D = 15;
PIV_X = 52; BOLA_D = 10;             // pivô (bola) atrás do berço
TUBO_X0 = 60; TUBO_X1 = TUBO_X0 + LASER_L;
TORRE_X = 96;                        // onde os 2 parafusos empurram o berço (44 mm à frente do pivô)
PROF = 12.5;                         // profundidade da torre por dentro (da face de fora até o fim do canal)

// ---------------- TORRE (coordenadas da torre: face de fora em z = 0, para fora = +z) ----------------
module torre_massa() {               // material que a torre precisa por dentro (soma na tampa ou na parede)
    hull() {
        translate([0, 0, -PROF]) cylinder(h = PROF - 0.01, d = 12);
        translate([-9, 0, -PROF + 3.5]) cylinder(h = PROF - 3.51, d = 9);
    }
    translate([0, 0, -4]) cylinder(h = 4 - 0.01, d = 28);                    // aro em volta do encaixe do botão
}
module torre_furos() {
    translate([0, 0, -1.8 - 0.01]) cylinder(h = 2, d = 15.8);                    // passagem do botão (aba de 1,8 mm segura ele)
    translate([0, 0, -4 - 0.01]) cylinder(h = 2.21, d = 24.6);                   // alojamento da aba do botão
    translate([0, 0, -6.8]) cylinder(h = 2.81, d = 10.8);                        // folga da haste (gira)
    translate([0, 0, -PROF - 1]) cylinder(h = PROF - 6.8 + 1.01, d = 5.8 / cos(30), $fn = 6);   // canal sextavado da contraporca
    translate([-9, 0, -4 - 9]) cylinder(h = 9.01, d = 6.3);                       // BB de 6 mm + mola (clique)
}
module em_cima(m) { translate([TORRE_X, AY, 0]) mirror([0, 0, 1]) children(); }   // na tampa (coordenadas da tampa)
module do_lado() { multmatrix([[1, 0, 0, TORRE_X], [0, 0, -1, 0], [0, 1, 0, AZ], [0, 0, 0, 1]]) children(); }   // na parede direita

// ===================== CAIXA (preto) =====================
module garra(lado) {
    mirror([0, lado > 0 ? 1 : 0, 0]) rotate([90, 0, 90]) linear_extrude(20)
        polygon([[-TRILHO_L/2 - 4, 0], [-TRILHO_L/2 + 0.2, 0], [-TRILHO_L/2 + 3, -2.8],
                 [-TRILHO_L/2 + 3, -GARRA_H], [-TRILHO_L/2 - 4, -GARRA_H]]);
}
module caixa() {
    difference() {
        union() {
            caixa_tatica(X, Y, H, P, P, C) {
                for (c = CANTOS) translate([c[0], c[1], 0]) pino(H, 7, 2.6);                         // pinos da tampa
                do_lado() torre_massa();                                                              // torre da deriva (por dentro)
                translate([46, AY - 6, 0]) cube([6, 12, 26]);                                         // bloco de trás do pivô
                for (s = [-1, 1]) translate([4, AY + s * 10.75 - 0.75, 0]) cube([41, 1.5, 6.5]);     // apoios do suporte da pilha
                // mola diagonal (baixo/esquerda) que empurra o berço para cima/direita
                translate([TORRE_X, AY, AZ]) rotate([45, 0, 0]) translate([0, 0, -18]) cylinder(h = 7.5, d = 9);
            }
            for (gx = GARRAS_X) translate([gx - 10, Y/2, 0]) garra(-1);
            translate([X - 0.01, AY, AZ]) rotate([0, 90, 0]) difference() { rotate([0, 0, 22.5]) cylinder(h = 6, d = 26 / cos(22.5), $fn = 8); translate([0, 0, -1]) cylinder(h = 8, d = 17); }   // capuz do laser
            for (p = [[8.5, 20], [Y - 8.5, 20]]) translate([0.01, p[0], p[1]]) rotate([0, -90, 0]) moldura_oct(11, 2);     // molduras do jack e da chave
            for (p = PROT_FUROS) translate([X - 9, p[0], p[1]]) rotate([0, 90, 0]) cylinder(h = 9, d = 7);                   // pinos da proteção anti-BB
        }
        do_lado() torre_furos();
        for (gx = GARRAS_X) translate([gx, -10, -2.6]) rotate([-90, 0, 0]) cylinder(h = Y + 20, d = 3.4);   // parafusos das garras
        translate([X - P - 1, AY, AZ]) rotate([0, 90, 0]) cylinder(h = P + 10, d = 17);                 // janela do laser
        for (p = PROT_FUROS) translate([X - 8, p[0], p[1]]) rotate([0, 90, 0]) cylinder(h = 9, d = 2.6);                 // furos da proteção anti-BB
        // pivô: meia esfera no bloco de trás + passagem dos fios
        translate([PIV_X, AY, AZ]) sphere(d = BOLA_D + 0.3);
        translate([40, AY, AZ]) rotate([0, 90, 0]) cylinder(h = 14, d = 4.5);
        for (z = [5.5, 23]) translate([PIV_X - 8, AY, z]) rotate([0, 90, 0]) cylinder(h = 9, d = 2.6);   // parafusos da trava do pivô
        // mola
        translate([TORRE_X, AY, AZ]) rotate([45, 0, 0]) translate([0, 0, -15.6]) cylinder(h = 5.2, d = 5.6);
        // traseira: USB-C do TP4056, jack P2 do acionador (direita) e chave CONTÍNUO (esquerda)
        translate([-1, AY - 5, 6.2 - 2.2]) cube([P + 2, 10, 4.4]);
        translate([-3, 8.5, 20]) rotate([0, 90, 0]) cylinder(h = P + 4, d = 6.3);
        translate([-3, Y - 8.5, 20]) rotate([0, 90, 0]) cylinder(h = P + 4, d = 6.3);
    }
    // texto em relevo ao lado da torre da deriva: girar no horário leva o ponto para a esquerda
    translate([TORRE_X - 25, 0.01, AZ - 9]) rotate([90, 0, 0]) linear_extrude(0.6) text("HOR. = ESQ", size = 2.6, halign = "center", font = "Liberation Sans:style=Bold");
}

// ===================== TAMPA (coyote) · MARCA DO PROJETO (única) =====================
module tampa() {      // impressa com a face de fora na mesa (z = 0)
    difference() {
        union() {
            tampa_tatica(X, Y, E, P, 2.5, C, 1.2);
            intersection() {
                em_cima() torre_massa();
                translate([0, 0, 0]) linear_extrude(PROF + 1) offset(delta = -(P + 0.4)) oct2d(X, Y, C);
            }
            for (x = [15, 35]) translate([x, AY, E - 0.01]) cylinder(h = H - 26.5 - 0.3 + 0.01, d = 6);   // seguram o suporte da pilha
        }
        em_cima() torre_furos();
        for (c = CANTOS) translate([c[0], c[1], 0]) { furo(3.4); translate([0, 0, -0.01]) cylinder(h = 1.8, d = 6.2); translate([0, 0, E]) cylinder(h = 4, d = 7.6); }
        // MARCA DO PROJETO (única): emblema + nome; nervuras apontando para a frente
        emblema_baixo(30, AY, 0.75, 0.6, 0);
        logo_baixo(58, AY, 4, prof = 0.6);
        nervuras_baixo(80, AY, 3, 4, 16, 0.6, 180);
        translate([TORRE_X, AY - 17.5, 0]) mirror([0, 0, 1]) mirror([1, 0, 0]) translate([0, 0, -0.6]) linear_extrude(0.62)
            text("HOR. = BAIXO", size = 2.6, halign = "center", valign = "center", font = "Liberation Sans:style=Bold");
    }
}

// ===================== BOTÃO DA TORRE (coyote, 2x) =====================
module botao_torre() {   // coordenadas da torre (face de fora em z = 0)
    difference() {
        union() {
            translate([0, 0, -1.8]) hull() {                                                            // tampa facetada que você gira
                rotate([0, 0, 22.5]) cylinder(h = 6, d = 15 / cos(22.5), $fn = 8);
                rotate([0, 0, 22.5]) cylinder(h = 6.8, d = 13 / cos(22.5), $fn = 8);
            }
            translate([0, 0, -4]) cylinder(h = 2.21, d = 24);                                            // aba (fica presa por dentro)
            translate([0, 0, -6.6]) cylinder(h = 2.61, d = 10);                                          // haste com a porca
        }
        translate([0, 0, -10]) cylinder(h = 20, d = 3.4);                                                 // passa o parafuso
        translate([0, 0, -6.61]) cylinder(h = 2.6, d = 6.6, $fn = 6);                                     // porca M3 (gira junto com o botão)
        for (i = [0 : 19]) rotate([0, 0, i * 18]) translate([6.5, 0, -4]) rotate([0, 90, 0]) cylinder(h = 6, d = 2.2, $fn = 4);   // 20 ranhuras do clique
        for (i = [0 : 19]) rotate([0, 0, i * 18]) translate([i % 5 == 0 ? 3.6 : 4.8, -0.3, 5 - 0.6]) cube([2.6, 0.6, 1]);       // 20 marcas (1 por clique)
    }
}

// ===================== BERÇO DO LASER (preto) =====================
module berco() {          // na posição de uso
    difference() {
        union() {
            translate([TUBO_X0, AY, AZ]) rotate([0, 90, 0]) cylinder(h = LASER_L, d = BERCO_D);
            translate([PIV_X, AY, AZ]) rotate([0, 90, 0]) cylinder(h = TUBO_X0 - PIV_X + 0.01, d = 6);     // pescoço
            translate([PIV_X, AY, AZ]) sphere(d = BOLA_D);                                                   // bola do pivô
        }
        translate([TUBO_X0 + 2, AY, AZ]) rotate([0, 90, 0]) difference() {                                 // furo do laser com 3 frisos de aperto
            cylinder(h = LASER_L, d = LASER_D);
            for (a = [0, 120, 240]) rotate([0, 0, a]) translate([LASER_D/2, 0, 0]) cylinder(h = LASER_L, d = 0.8, $fn = 8);
        }
        translate([PIV_X - 6, AY, AZ]) rotate([0, 90, 0]) cylinder(h = 20, d = 3.5);                         // fios do laser
    }
}

// ===================== TRAVA DO PIVÔ (preto) =====================
module trava_pivo() {     // na posição de uso: segura a bola contra o bloco de trás (2 M3 x 12)
    difference() {
        translate([PIV_X, AY - 6, 3]) cube([6, 12, 23]);
        translate([PIV_X, AY, AZ]) sphere(d = BOLA_D + 0.3);
        translate([PIV_X - 1, AY, AZ]) rotate([0, 90, 0]) cylinder(h = 8, d = 7.6);                         // pescoço (folga para inclinar)
        for (z = [5.5, 23]) translate([PIV_X - 1, AY, z]) rotate([0, 90, 0]) { cylinder(h = 8, d = 3.4); translate([0, 0, 4.6]) cylinder(h = 4, d = 6.2); }
    }
}

// ===================== MANDÍBULA MÓVEL (coyote, 2x) =====================
module mandibula() {
    difference() {
        union() { garra(1); translate([0, TRILHO_L/2 + 4, -GARRA_H]) cube([20, 5, GARRA_H]); }
        translate([10, -30, -2.6]) rotate([-90, 0, 0]) cylinder(h = 60, d = 3.4);
        translate([10, TRILHO_L/2 + 6.5, -2.6]) rotate([-90, 0, 0]) cylinder(h = 3, d = 6.6, $fn = 6);
    }
}

// ===================== PROTEÇÃO ANTI-BB (coyote) =====================
// encaixa por cima do capuz do laser e vai presa por 2 M3 x 12 na frente da caixa. Grade de favos de 4,2 mm
// (a BB de 6 mm não passa) com furo de 4 mm no centro, no eixo do laser. Atrás da grade: rebaixo para um disco
// de policarbonato de 1 mm (Ø 20, opcional) que segura poeira e estilhaço.
PROT_FUROS = [[9, 22], [Y - 9, 6]];             // [y, z] dos 2 parafusos (fora do capuz, longe dos pinos da tampa)
module protecao_bb() {   // na posição de uso
    difference() {
        union() {
            translate([X, AY, AZ]) rotate([0, 90, 0]) rotate([0, 0, 22.5]) cylinder(h = 8, d = 30 / cos(22.5), $fn = 8);   // luva
            hull() for (p = PROT_FUROS) translate([X, p[0], p[1]]) rotate([0, 90, 0]) cylinder(h = 5, d = 8);           // orelhas dos parafusos
            translate([X + 8 - 0.01, AY, AZ]) rotate([0, 90, 0]) rotate([0, 0, 22.5]) cylinder(h = 3, d1 = 30 / cos(22.5), d2 = 26 / cos(22.5), $fn = 8);   // frente chanfrada
        }
        translate([X - 0.01, AY, AZ]) rotate([0, 90, 0]) rotate([0, 0, 22.5]) cylinder(h = 6.3, d = 26.6 / cos(22.5), $fn = 8);   // entra no capuz
        translate([X + 6.2, AY, AZ]) rotate([0, 90, 0]) cylinder(h = 1.3, d = 20.4);                                             // disco de policarbonato
        // grade de favos na frente (só dentro do Ø 17 do capuz)
        translate([X + 7.4, AY, AZ]) rotate([0, 90, 0]) intersection() {
            translate([0, 0, -0.1]) cylinder(h = 3.8, d = 17);
            translate([-9, -9, -0.1]) difference() { cube([18, 18, 3.8]); favos(18, 18, 3.8, 4.2, 1.1); }
        }
        translate([X + 6, AY, AZ]) rotate([0, 90, 0]) cylinder(h = 6, d = 4);                                                     // passagem do laser
        for (p = PROT_FUROS) translate([X - 1, p[0], p[1]]) rotate([0, 90, 0]) { cylinder(h = 12, d = 3.4); translate([0, 0, 4]) cylinder(h = 10, d = 6.2); }
    }
}

if (PECA == "caixa") caixa();
if (PECA == "tampa") tampa();
if (PECA == "berco") translate([0, 0, TUBO_X1]) rotate([0, 90, 0]) translate([0, -AY, -AZ]) berco();      // em pé, frente na mesa
if (PECA == "trava_pivo") translate([0, 0, 6]) rotate([0, 90, 0]) translate([-PIV_X - 6, 0, 0]) trava_pivo();
if (PECA == "botao_torre") translate([0, 0, 5]) rotate([180, 0, 0]) botao_torre();                          // tampa do botão na mesa
if (PECA == "mandibula") translate([0, 0, GARRA_H]) mandibula();
if (PECA == "protecao_bb") translate([0, 0, X + 11]) rotate([0, 90, 0]) translate([0, -AY, -AZ]) protecao_bb();   // frente na mesa
