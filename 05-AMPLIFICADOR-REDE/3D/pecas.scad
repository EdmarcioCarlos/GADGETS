// =====================================================================
//  05 - AMPLIFICADOR DE REDE (rádio dos tablets) · peças 3D
//  Escolha a peça em PECA, F6 (render) e F7 (exportar STL). Medidas em mm.
//  ESTILO TÁTICO FACETADO · cores: caixa em PRETO · tampa (com a marca) em COYOTE
//
//  COMO FUNCIONA: caixinha em pé, presa no poste/árvore ACIMA do tablet (quanto mais alto,
//  mais longe o rádio alcança) com 2 fitas de velcro de 25 mm nos túneis de trás.
//  Dentro: ESP32-C3 em pé, com o USB-C virado para BAIXO (cabo do powerbank 02, chuva não entra).
//  Em cima: antena 2,4 GHz de rosca (RP-SMA) na tampa. Sem antena externa: tampão no furo.
//  Na frente: LED TABLET e LED REDE (3 mm).
//  Eixos: x = largura, y = 0 na FRENTE (y = Y encosta no poste), z = 0 embaixo.
// =====================================================================
use <../../_BIBLIOTECA-3D/bb_lib.scad>
$fn = 48;

PECA = "caixa";   // caixa | tampa | tampao_antena | calco

X = 36; Y = 26; Z = 64;           // caixa por fora (a tampa de 4 mm completa 68)
P = 3; C = 4; E = 4;
CANTOS = [[6.2, 6.2], [X - 6.2, Y - 6.2]];            // 2 parafusos M3 x 10 na diagonal
PINOS = [[X - 6.2, 6.2], [6.2, Y - 6.2]];             // nos outros 2 cantos, só pinos de encaixe

// ESP32-C3 SuperMini (ou a versão "Plus" com conector de antena IPEX) · CONFIRA a sua
C3 = [18, 22.5, 1.6];             // largura (x) · altura em pé (z) · espessura
C3_Y = 12.4;                      // face de trás da placa (os componentes e o USB-C ficam para a frente)
USB = [12.5, 8];                  // abertura embaixo para o plugue USB-C (x · y)
USB_Y = 15.6;                     // centro do USB-C (em y)
ANT = [X/2, 19];                  // furo da antena RP-SMA (posição na caixa, perto de trás)
ANT_D = 6.6;                      // rosca 1/4" da RP-SMA de painel
LEDS_X = [X/2 - 6, X/2 + 6]; LEDS_Z = 46;

// ---------------- FIXAÇÃO NO POSTE (igual no powerbank 02) ----------------
TUNEL = [27.5, 4];
module fixacao_poste(x, y, zs) {
    for (zc = zs) translate([0, y - 0.01, zc - TUNEL[0]/2 - 3]) difference() {
        union() {
            translate([3, 0, 0]) cube([x - 6, TUNEL[1] + 3, TUNEL[0] + 6]);
            for (s = [-1, 1]) translate([x/2 + s * x * 0.2, TUNEL[1] + 3 - 0.01, 0])
                linear_extrude(TUNEL[0] + 6) polygon([[-3, 0], [3, 0], [1, 3], [-1, 3]]);
        }
        translate([-1, 0, 3]) cube([x + 2, TUNEL[1], TUNEL[0]]);
    }
}

// ===================== CAIXA (preto) =====================
module caixa() {
    difference() {
        union() {
            caixa_tatica(X, Y, Z, P, P, C) {
                for (c = concat(CANTOS, PINOS)) translate([c[0], c[1], 0]) pino(Z, 7, 2.6);
                for (s = [-1, 1]) translate([s > 0 ? X/2 + C3[0]/2 - 1.5 : X/2 - C3[0]/2 - 3, C3_Y - 1.5, 0])   // guias da placa
                    cube([4.5, C3[2] + 3, Z - 0.5]);                                         // até em cima: o calço desce pelo mesmo rasgo
            }
            fixacao_poste(X, Y, [Z/2]);                                                       // 1 fita no meio
            for (x = LEDS_X) translate([x, 0.01, LEDS_Z]) rotate([90, 0, 0]) moldura_oct(9, 1.5);
            // rótulos em relevo embaixo dos LEDs
            for (i = [0, 1]) translate([LEDS_X[i], 0.01, LEDS_Z - 8]) rotate([90, 0, 0]) linear_extrude(0.6)
                text(i == 0 ? "TAB" : "REDE", size = 3, halign = "center", valign = "center", font = "Liberation Sans:style=Bold");
            translate([6, 0.01, 6]) rotate([90, 0, 0]) hex_relevo(X - 12, 28, 1);       // painel hexagonal na frente
        }
        for (s = [-1, 1]) translate([s > 0 ? X/2 + C3[0]/2 - 1.5 - 0.01 : X/2 - C3[0]/2 - 0.4, C3_Y - 0.2, P])   // rasgos das guias
            cube([1.9 + 0.01, C3[2] + 0.4, Z]);
        translate([X/2 - USB[0]/2, USB_Y - USB[1]/2, -1]) cube([USB[0], USB[1], P + 2]);     // USB-C por baixo
        for (x = LEDS_X) translate([x, -3, LEDS_Z]) rotate([-90, 0, 0]) cylinder(h = P + 6, d = 3.2);   // LEDs 3 mm
    }
}

// ===================== TAMPA (coyote) · MARCA DO PROJETO (única) =====================
module tampa() {      // impressa com a face de fora na mesa (z = 0); ao montar, o lado y = Y daqui fica na FRENTE
    difference() {
        union() {
            tampa_tatica(X, Y, E, P, 2.5, C, 1.2);
            for (c = PINOS) translate([c[0], Y - c[1], E - 0.01]) cylinder(h = 4, d = 2.2);
        }
        for (c = CANTOS) translate([c[0], Y - c[1], 0]) furo(3.4);
        translate([ANT[0], Y - ANT[1], 0]) furo(ANT_D);
        // MARCA DO PROJETO (única): emblema + nome, perto da frente
        emblema_baixo(X/2, Y - 6, 0.62, 0.6, 180);
        translate([X/2, Y - 12, 0]) rotate([0, 0, 180]) logo_baixo(0, 0, 2.6, prof = 0.6);
    }
}

// ===================== CALÇO DA PLACA (preto, 2x) =====================
// desce pelo rasgo de cada guia, em cima da placa: a tampa aperta e a placa não sobe quando você liga o cabo
CALCO_L = Z - P - C3[1] - 0.4;
module calco() { cube([3.4, CALCO_L, C3[2] - 0.1]); }   // impresso deitado

// ===================== TAMPÃO DA ANTENA (coyote) =====================
module tampao_antena() {   // fecha o furo quando a placa usa a antena dela (sem antena externa)
    octogono(11, 1.6);
    cylinder(h = 1.6 + E - 0.2, d = ANT_D - 0.3);
    translate([0, 0, 1.6 + E - 0.2]) cylinder(h = 1.2, d1 = ANT_D + 0.4, d2 = ANT_D - 0.6);   // aba que trava por dentro
}

if (PECA == "caixa") caixa();
if (PECA == "tampa") tampa();
if (PECA == "tampao_antena") tampao_antena();
if (PECA == "calco") calco();
