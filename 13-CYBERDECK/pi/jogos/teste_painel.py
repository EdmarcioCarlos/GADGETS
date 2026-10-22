# NOME: Teste do painel
# DESCRICAO: Aperte cada botão e alavanca: acende o LED, apita e mostra na tela (fase 4)
"""
Teste de hardware do painel de partida. Mostra o estado de cada controle,
acende o LED do botão apertado, apita e troca a cor do neon.
ESC (ou segurar START 3 s) volta ao menu.
"""
import os
import sys
import time

import pygame

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from painel import Painel  # noqa: E402

CONTROLES = ["ARM", "APU", "ENG1", "ENG2", "MANETE", "START"]
CORES_NEON = {"APU": (255, 180, 0), "ENG1": (0, 90, 255), "ENG2": (0, 255, 90), "START": (255, 0, 40)}


def main():
    pygame.init()
    tela = pygame.display.set_mode((1280, 720), (pygame.FULLSCREEN | pygame.SCALED) if "--janela" not in sys.argv else 0)
    fonte = pygame.font.SysFont("dejavusansmono", 34, bold=True)
    p = Painel()
    estado = {c: False for c in CONTROLES}
    t_start = None
    while True:
        for ev in pygame.event.get():
            if ev.type == pygame.QUIT or (ev.type == pygame.KEYDOWN and ev.key == pygame.K_ESCAPE):
                return
            simulado = p.tecla_pygame(ev)
            if simulado:
                estado[simulado[0]] = simulado[1]
        for nome, ligado in p.eventos():
            if nome in estado:
                estado[nome] = ligado
                if nome in CORES_NEON:
                    p.led(nome, ligado)
                    if ligado:
                        p.neon(*CORES_NEON[nome])
                if ligado:
                    p.beep(40)
                    p.display(nome[:4])
        if estado["START"]:
            t_start = t_start or time.time()
            if time.time() - t_start > 3:
                return
        else:
            t_start = None
        tela.fill((6, 9, 10))
        tela.blit(fonte.render("TESTE DO PAINEL", True, (255, 190, 60)), (40, 30))
        for i, c in enumerate(CONTROLES):
            cor = (90, 255, 140) if estado[c] else (60, 70, 65)
            pygame.draw.rect(tela, cor, (60, 110 + i * 70, 40, 40))
            tela.blit(fonte.render(f"{c:<7} {'LIGADO' if estado[c] else '—'}", True, cor), (120, 108 + i * 70))
        pygame.display.flip()
        pygame.time.Clock().tick(30)


if __name__ == "__main__":
    main()
