// =====================================================================
//  11 - SCANNER DE RÁDIO UHF · peças 3D
//  Escolha a peça em PECA, F6 (render) e F7 (exportar STL). Medidas em mm.
//  X = largura (62), Y = altura (112, antena em cima), Z = profundidade.
//  ESTILO TÁTICO FACETADO · cores: corpo e clipe em PRETO · tampa da frente em COYOTE
// =====================================================================
use <../../_BIBLIOTECA-3D/bb_lib.scad>
$fn = 48;

PECA = "corpo";   // corpo | tampa_frente | clipe_molle

X = 62; Y = 112; H = 31;     // corpo (o fundo é a parede de trás); a tampa de 3 mm completa 34
P = 3;
CANTOS = [[6, 6], [X - 6, 6], [6, Y - 6], [X - 6, Y - 6]];
C = 6;                       // chanfro dos cantos (estilo tático facetado)
OLED_C = [31, 88.5];         // centro do módulo OLED na tampa
BOTAO_C = [31, 62];

// ===================== CORPO =====================
module corpo() {                // preto
    difference() {
        union() {
            caixa_tatica(X, Y, H, P, P, C) for (c = CANTOS) translate([c[0], c[1], 0]) pino(H, 7, 2.6);
            // painéis hexagonais na lateral esquerda (x = 0), acima e abaixo do nome
            for (y0 = [8, 80]) translate([0.01, y0 + 24, 6]) rotate([90, 0, -90]) hex_relevo(24, 19, 1);
        }
        translate([46, Y + 1, 15]) rotate([90, 0, 0]) cylinder(h = P + 2, d = 6.6);      // SMA da antena (topo)
        translate([X - P - 1, 14.25 - 4.75, 15 - 1.9]) cube([P + 2, 9.5, 3.8]);         // USB-C (lateral direita)
        translate([X - P - 1, 32 - 4.25, 15 - 1.8]) cube([P + 2, 8.5, 3.6]);            // chave
        for (yy = [45, 60]) translate([31, yy, 0]) furo(3.4);                           // clipe MOLLE
    }
}

// ===================== TAMPA DA FRENTE (coyote) =====================
module tampa_frente() {         // impressa com a face externa na mesa (z = 0); 4 mm = 3 úteis + 1 das gravações
    difference() {
        tampa_tatica(X, Y, 4, P, 3, C, 1.2);
        for (c = CANTOS) translate([c[0], c[1], 0]) { furo(3.4); translate([0, 0, -0.01]) cylinder(h = 1.8, d1 = 6.5, d2 = 3.4); }
        for (c = CANTOS) translate([c[0], c[1], 3.9]) cylinder(h = 4, d = 9);           // folga dos pinos
        nervuras_baixo(31, 37, 3, 4, 18, 0.8, 90);                                     // nervuras em V apontando para a antena
        // MARCA DO PROJETO (única): emblema + nome embaixo da frente
        emblema_baixo(31, 25, 0.8, 0.8);
        // tela: janela + rebaixo do policarbonato (face externa = z 0)
        translate([X - OLED_C[0], OLED_C[1], 0]) furo_rect(22.4, 11.4);
        translate([X - OLED_C[0], OLED_C[1], 0.1]) cube([28.4, 17.4, 2.2], center = true);   // rebaixo 1,2 mm
        translate([X - BOTAO_C[0], BOTAO_C[1], 0]) furo(10.2);
        logo_baixo(31, 13, 5.5);
    }
}

// ===================== CLIPE MOLLE / CINTO =====================
module clipe_molle() {          // perfil em Y-Z, extrudado 25 mm em X; prende em fita de 25 mm
    difference() {
        rotate([90, 0, 90]) linear_extrude(25) polygon([
            [0, 0], [70, 0], [70, 3], [40, 3], [40, 9], [70, 9], [70, 12], [0, 12],
            [0, 9], [6, 9], [6, 3], [0, 3]]);
        for (yy = [15, 30]) translate([12.5, yy, -1]) cylinder(h = 9, d = 2.6);
    }
}

if (PECA == "corpo") corpo();
if (PECA == "tampa_frente") tampa_frente();
if (PECA == "clipe_molle") clipe_molle();
