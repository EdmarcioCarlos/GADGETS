// =====================================================================
//  02 - POWERBANK DOS TABLETS · peças 3D
//  Escolha a peça em PECA, F6 (render) e F7 (exportar STL). Medidas em mm.
//  ESTILO TÁTICO FACETADO · cores: caixa e cartucho em PRETO
//                                  tampa (com a marca) e 2 botões de aperto em COYOTE
//
//  COMO FUNCIONA: caixa em pé, presa no poste/árvore por 2 fitas de velcro de 25 mm
//  que passam nos 2 túneis de trás (as nervuras em V centralizam no poste).
//  Embaixo, na frente: a placa de power bank em pé, com as saídas USB viradas para BAIXO
//  (a chuva não entra); a tela de carga aparece pela grade da frente.
//  Atrás: o CARTUCHO com 3 baterias 18650 em paralelo entra por cima, como um carregador:
//  abre a tampa (2 botões de aperto), desliga o conector XT30, puxa pela alça e põe outro.
//  Eixos: x = largura, y = 0 na FRENTE (y = Y encosta no poste), z = 0 embaixo.
// =====================================================================
use <../../_BIBLIOTECA-3D/bb_lib.scad>
$fn = 48;

PECA = "caixa";   // caixa | tampa | cartucho | botao_aperto | calco

X = 96; Y = 50; Z = 102;          // caixa por fora (a tampa de 4 mm completa 106)
P = 3; C = 5; E = 4;
CANTOS = [[6.2, 6.2], [X - 6.2, 6.2], [6.2, Y - 6.2], [X - 6.2, Y - 6.2]];   // pinos entram 0,3 mm nas paredes
APERTO = [0, 3];                  // cantos com botão de aperto (os outros 2 só têm pino de encaixe)

// placa de power bank (2 USB-A + entrada de carga, TODAS na mesma borda) · CONFIRA a sua
PLACA = [57, 28, 1.6];            // comprimento (x) · altura em pé (z) · espessura
PLACA_Y = 12;                     // face da frente da placa (os componentes ficam entre a parede e ela)
GUIA_X = PLACA[0]/2 - 2;          // as guias seguram 2 mm de cada ponta da placa
PORTAS = [52, 9];                 // abertura embaixo para os plugues (x · y, a partir da parede da frente)
TELA = [26, 14]; TELA_Z = 20;     // janela da tela de carga (centro em x = X/2, altura TELA_Z)

// cartucho: 3 suportes de 1 bateria 18650 lado a lado
SUP = [77, 21.6, 20];             // suporte de 1 x 18650 (comprimento · largura com folga · altura) · CONFIRA
CART_PAREDE = [2.4, 1.2];         // paredes de fora · paredes entre os suportes
CART_W = 3 * SUP[1] + 2 * CART_PAREDE[0] + 2 * CART_PAREDE[1];   // 72
CART_L = SUP[0] + 4;              // 81
CART_BASE = 3.5;
ALCA = 14;                        // alça de puxar, em cima
FITA = [26.5, 1.4];               // rebaixo da fita de velcro que prende baterias e suportes (largura · fundo)
FITAS_Y = [22, 59];
ZONA_Y = [19, Y - P];             // espaço do cartucho (atrás da divisória)
DIV_Y = 17; DIV_Z = 40;           // divisória entre a placa e o cartucho

// ---------------- FIXAÇÃO NO POSTE (igual no rádio 05) ----------------
// 2 túneis horizontais atrás para fitas de 25 mm + nervuras em V que centralizam num poste redondo
TUNEL = [27.5, 4];                // altura da fita (z) · folga para a espessura (y)
module fixacao_poste(x, y, zs) {
    for (zc = zs) translate([0, y - 0.01, zc - TUNEL[0]/2 - 3]) difference() {
        union() {
            translate([3, 0, 0]) cube([x - 6, TUNEL[1] + 3, TUNEL[0] + 6]);
            for (s = [-1, 1]) translate([x/2 + s * x * 0.2, TUNEL[1] + 3 - 0.01, 0])            // nervuras em V
                linear_extrude(TUNEL[0] + 6) polygon([[-3, 0], [3, 0], [1, 3], [-1, 3]]);
        }
        translate([-1, 0, 3]) cube([x + 2, TUNEL[1], TUNEL[0]]);                                 // o túnel (atravessa de lado a lado)
    }
}

// ===================== CAIXA (preto) =====================
module caixa() {
    difference() {
        union() {
            caixa_tatica(X, Y, Z, P, P, C) {
                for (c = CANTOS) translate([c[0], c[1], 0]) pino(Z, 7, 2.6);                           // pinos da tampa
                for (s = [-1, 1]) translate([s > 0 ? X/2 + GUIA_X : X/2 - GUIA_X - 4.5, PLACA_Y - 1.5, 0])   // guias da placa
                    cube([4.5, PLACA[2] + 4, Z - 0.5]);                                                    // até em cima: o calço desce pelo mesmo rasgo
                translate([10.5, DIV_Y, 0]) cube([X - 21, 2, DIV_Z]);                                   // divisória placa | cartucho
                for (s = [0, 1]) translate([s ? X - 14 : 10.5, DIV_Y, 0]) cube([3.5, 2, Z - 3]);        // trilhos do cartucho (até em cima)
            }
            fixacao_poste(X, Y, [26, 76]);
            // pala em cima da janela da tela (chuva e BB de cima)
            translate([X/2, 0.01, P + TELA_Z + TELA[1]/2 + 1]) rotate([90, 0, 0]) linear_extrude(4, scale = [1, 0.4])
                translate([-(TELA[0] + 8)/2, -1.5]) square([TELA[0] + 8, 3]);
            // painel hexagonal na frente (em cima da placa) e nos 2 lados
            translate([12, 0.01, 46]) rotate([90, 0, 0]) hex_relevo(X - 24, Z - 54, 1);
            translate([X - 0.01, 12, 14]) rotate([90, 0, 90]) hex_relevo(Y - 24, Z - 28, 1);
            translate([0.01, Y - 12, 14]) rotate([90, 0, -90]) hex_relevo(Y - 24, Z - 28, 1);
        }
        // guias: rasgo onde a placa desce (entra 1,5 mm de cada lado)
        for (s = [-1, 1]) translate([s > 0 ? X/2 + GUIA_X - 0.01 : X/2 - PLACA[0]/2 - 0.4, PLACA_Y - 0.2, P])
            cube([PLACA[0]/2 + 0.4 - GUIA_X + 0.01, PLACA[2] + 0.4, Z]);
        // embaixo: abertura dos plugues USB (as saídas apontam para baixo)
        translate([X/2 - PORTAS[0]/2, P - 0.01, -1]) cube([PORTAS[0], PORTAS[1], P + 2]);
        // frente: janela da tela de carga com grade de favos (a BB de 6 mm não passa)
        translate([X/2 - TELA[0]/2, -1, P + TELA_Z - TELA[1]/2]) difference() {
            cube([TELA[0], P + 2, TELA[1]]);
            translate([0, P + 1, 0]) rotate([90, 0, 0]) favos(TELA[0], TELA[1], P - 1, 4.2, 1.1);
        }
    }
}

// ===================== TAMPA (coyote) · MARCA DO PROJETO (única) =====================
module tampa() {      // impressa com a face de fora na mesa (z = 0)
    difference() {
        union() {
            tampa_tatica(X, Y, E, P, 2.5, C, 1.2);
            for (i = [0 : 3]) if (search(i, APERTO) == []) translate([CANTOS[i][0], CANTOS[i][1], E - 0.01]) cylinder(h = 4, d = 2.2);   // pinos de encaixe
        }
        for (i = APERTO) translate([CANTOS[i][0], CANTOS[i][1], 0]) furo(3.4);
        // MARCA DO PROJETO (única): emblema + nome; nervuras apontando para a frente da caixa
        // (a tampa vira ao montar: o lado y = Y daqui fica na FRENTE da caixa)
        emblema_baixo(X - 22, Y/2, 1.0, 0.6, 180);
        translate([X - 58, Y/2 - 1, 0]) rotate([0, 0, 180]) logo_baixo(0, 0, 5, prof = 0.6);
        for (x = [20, X/2, X - 20]) nervuras_baixo(x, Y - 12.5, 2, 3.6, 10, 0.6, 90);
        translate([X/2, 7, 0]) rotate([0, 0, 180]) mirror([0, 0, 1]) mirror([1, 0, 0]) translate([0, 0, -0.6]) linear_extrude(0.62)
            text("3 x 18650 · TROQUE AS 3 JUNTAS", size = 2.6, halign = "center", valign = "center", font = "Liberation Sans:style=Bold");
    }
}

// ===================== BOTÃO DE APERTO (coyote, 2x) =====================
// cabeça do M3 x 16 Allen entra justa no sextavado de baixo: aperta e solta a tampa sem chave
module botao_aperto() {
    difference() {
        hull() {
            octogono(16, 6);
            translate([0, 0, 6]) octogono(13, 1.5);
        }
        translate([0, 0, -1]) cylinder(h = 3.4, d = 5.9, $fn = 6);      // cabeça Allen (Ø 5,5) entra apertada
        translate([0, 0, -1]) cylinder(h = 10, d = 3.4);
        for (a = [0 : 45 : 315]) rotate([0, 0, a]) translate([8.3, 0, 1]) cylinder(h = 7, d = 2.2, $fn = 8);   // ranhuras de pegada
    }
}

// ===================== CALÇO DA PLACA (preto, 2x) =====================
// desce pelo rasgo de cada guia, em cima da placa: a tampa aperta e a placa não sobe quando você liga o cabo
CALCO_L = Z - P - PLACA[1] - 0.4;
module calco() { cube([4, CALCO_L, PLACA[2] - 0.1]); }   // impresso deitado

// ===================== CARTUCHO (preto) =====================
// impresso deitado: x = largura, y = comprimento (vira a altura na caixa), z = 0 é o fundo (vai virado para a frente)
module cartucho() {
    difference() {
        union() {
            prisma_oct(CART_W, CART_L, CART_BASE, 3);
            for (pw = [[0, CART_PAREDE[0]], [CART_PAREDE[0] + SUP[1], CART_PAREDE[1]],                  // paredes: fora · entre · entre · fora
                       [CART_PAREDE[0] + 2 * SUP[1] + CART_PAREDE[1], CART_PAREDE[1]], [CART_W - CART_PAREDE[0], CART_PAREDE[0]]])
                translate([pw[0], 0, 0]) cube([pw[1], CART_L, CART_BASE + 9]);
            for (y = [0, CART_L - 2]) translate([0, y, 0]) cube([CART_W, 2, CART_BASE + 9]);   // pontas (os fios saem pelos rasgos)
            // alça de puxar
            translate([CART_W/2 - 17, CART_L - 0.01, 0]) difference() {
                hull() { cube([34, 1, CART_BASE + 2]); translate([4, ALCA - 1, 0]) cube([26, 1, CART_BASE + 2]); }
                translate([7, 3, -1]) hull() { cylinder(h = 10, d = 6); translate([20, 0, 0]) cylinder(h = 10, d = 6); }
            }
        }
        for (k = [0 : 2]) {                                                                  // rasgos dos fios nas 2 pontas
            cx = CART_PAREDE[0] + k * (SUP[1] + CART_PAREDE[1]) + SUP[1]/2;
            for (y = [-1, CART_L - 3]) translate([cx - 3, y, CART_BASE + 4]) cube([6, 4, 10]);
        }
        for (fy = FITAS_Y) {                                                                 // rebaixo da fita de velcro (embaixo e nos lados)
            translate([-1, fy - FITA[0]/2, -0.01]) cube([CART_W + 2, FITA[0], FITA[1]]);
            for (x = [-0.01, CART_W - FITA[1] + 0.01]) translate([x, fy - FITA[0]/2, -1]) cube([FITA[1], FITA[0], CART_BASE + 11]);
        }
    }
}

if (PECA == "caixa") caixa();
if (PECA == "tampa") tampa();
if (PECA == "botao_aperto") translate([0, 0, 7.5]) rotate([180, 0, 0]) botao_aperto();   // topo facetado na mesa
if (PECA == "cartucho") cartucho();
if (PECA == "calco") calco();
