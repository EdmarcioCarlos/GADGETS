#!/usr/bin/env python3
"""
CYBERDECK BLACK BIRD - menu de missões (abre sozinho depois da partida)

Visual: painel militar (verde/âmbar, grade, colchetes) + glitch DedSec (magenta/ciano,
linhas tremendo, blocos de ruído). Lista sozinho os jogos da pasta jogos/: cada
arquivo .py pode ter no começo as linhas
    # NOME: Terminal ctOS
    # DESCRICAO: Triangulação das torres e invasão do Data Center
Navegar: ↑/↓ ou ENG 1/ENG 2 no painel · abrir: ENTER ou START · ESC volta.
Rodar no PC para testar: python menu.py --janela
"""
import os
import random
import subprocess
import sys
import time

import pygame

from painel import Painel

PASTA = os.path.dirname(os.path.abspath(__file__))
JOGOS = os.path.join(PASTA, "jogos")
L, A = 1280, 720      # desenhado em 1280 x 720 e ampliado sozinho para o monitor de 15,6" (Full HD)

VERDE = (90, 255, 140); AMBAR = (255, 190, 60); CIANO = (0, 230, 255); MAGENTA = (255, 40, 200)
FUNDO = (6, 9, 10); GRADE = (14, 30, 22); BRANCO = (235, 240, 240)

# caveira glitch própria (12 x 12), desenhada em blocos
CAVEIRA = ["   ######   ", "  ########  ", " ########## ", " ##  ##  ## ", " #   ##   # ", " ##  ##  ## ",
           " ########## ", "  ###  ###  ", "   ######   ", "   # ## #   ", "   ######   ", "    ####    "]


def ler_jogos():
    lista = []
    if os.path.isdir(JOGOS):
        for arq in sorted(os.listdir(JOGOS)):
            if not arq.endswith(".py"):
                continue
            nome, desc = arq[:-3].replace("_", " ").upper(), ""
            with open(os.path.join(JOGOS, arq), encoding="utf-8", errors="ignore") as f:
                for _ in range(15):
                    lin = f.readline()
                    if lin.startswith("# NOME:"):
                        nome = lin.split(":", 1)[1].strip()
                    if lin.startswith("# DESCRICAO:"):
                        desc = lin.split(":", 1)[1].strip()
            lista.append((nome, desc, arq))
    return lista


def texto_glitch(tela, fonte, txt, x, y, forca=3):
    """Texto com separação de cores (ciano/magenta) e tremida, estilo DedSec."""
    for cor, dx in ((MAGENTA, -forca), (CIANO, forca)):
        tela.blit(fonte.render(txt, True, cor), (x + dx + random.randint(-1, 1), y))
    tela.blit(fonte.render(txt, True, BRANCO), (x, y))


def ruido(tela, intensidade):
    for _ in range(intensidade):                     # faixas deslocadas e blocos de ruído
        yy = random.randint(0, A - 8); hh = random.randint(2, 10)
        faixa = tela.subsurface((0, yy, L, hh)).copy()
        tela.blit(faixa, (random.randint(-25, 25), yy))
    for _ in range(intensidade // 2):
        pygame.draw.rect(tela, random.choice((MAGENTA, CIANO, BRANCO)),
                         (random.randint(0, L), random.randint(0, A), random.randint(8, 70), random.randint(2, 6)))


def caveira(tela, x, y, tam, cor):
    for i, lin in enumerate(CAVEIRA):
        for j, c in enumerate(lin):
            if c == "#":
                pygame.draw.rect(tela, cor, (x + j * tam, y + i * tam, tam - 1, tam - 1))


def grade(tela):
    tela.fill(FUNDO)
    for x in range(0, L, 32):
        pygame.draw.line(tela, GRADE, (x, 0), (x, A))
    for y in range(0, A, 32):
        pygame.draw.line(tela, GRADE, (0, y), (L, y))
    for yy in range(0, A, 3):                        # linhas de varredura
        pygame.draw.line(tela, (0, 0, 0), (0, yy), (L, yy))


def abertura(tela, fontes, painel):
    """3 s de glitch: caveira + BLACK BIRD // DEDSEC OPS + 'sistemas online'."""
    painel.neon(255, 0, 200)
    t0 = time.time()
    relogio = pygame.time.Clock()
    while time.time() - t0 < 3.2:
        for ev in pygame.event.get():
            if ev.type == pygame.KEYDOWN:
                return
        k = time.time() - t0
        grade(tela)
        caveira(tela, L // 2 - 84, 90, 14, random.choice((MAGENTA, CIANO, BRANCO)))
        texto_glitch(tela, fontes["g"], "BLACK BIRD", L // 2 - 190, 290, 4 if k < 2.5 else 1)
        texto_glitch(tela, fontes["m"], "// DEDSEC OPS · CYBERDECK BB-11", L // 2 - 250, 370, 2)
        linhas = ["> painel de partida ......... OK", "> link serial ............... OK", "> módulos de missão ......... OK"]
        for i, lin in enumerate(linhas[: int(k / 0.8) + 1]):
            tela.blit(fontes["p"].render(lin, True, VERDE), (L // 2 - 200, 430 + i * 26))
        ruido(tela, 14 if k < 2.6 else 2)
        pygame.display.flip()
        relogio.tick(30)
    painel.neon(0, 200, 255)


def desenhar_menu(tela, fontes, jogos, sel, t):
    grade(tela)
    # moldura militar com colchetes nos cantos
    for (x, y, dx, dy) in ((14, 14, 1, 1), (L - 14, 14, -1, 1), (14, A - 14, 1, -1), (L - 14, A - 14, -1, -1)):
        pygame.draw.line(tela, AMBAR, (x, y), (x + 40 * dx, y), 3)
        pygame.draw.line(tela, AMBAR, (x, y), (x, y + 40 * dy), 3)
    texto_glitch(tela, fontes["m"], "SELEÇÃO DE MISSÃO", 40, 30, 2 if random.random() < 0.15 else 0)
    tela.blit(fontes["p"].render("BB-11 // DEDSEC OPS  ·  " + time.strftime("%H:%M:%S"), True, AMBAR), (L - 430, 38))
    caveira(tela, L - 120, 120, 6, MAGENTA if int(t * 2) % 2 else CIANO)
    if not jogos:
        tela.blit(fontes["p"].render("nenhum jogo em jogos/  (copie os .py para lá)", True, AMBAR), (60, 140))
    for i, (nome, desc, _) in enumerate(jogos):
        y = 110 + i * 62
        if i == sel:
            pygame.draw.rect(tela, (0, 60, 40), (40, y - 6, L - 220, 54))
            pygame.draw.rect(tela, VERDE, (40, y - 6, L - 220, 54), 2)
            tela.blit(fontes["m"].render(">", True, MAGENTA), (50, y))
        tela.blit(fontes["m"].render(f"{i + 1:02d}  {nome}", True, VERDE if i == sel else (120, 170, 130)), (80, y))
        tela.blit(fontes["p"].render(desc, True, (140, 160, 150)), (128, y + 30))
    rod = "↑/↓ ou ENG 1/ENG 2: escolher   ·   ENTER ou START: iniciar   ·   desligar: MANETE em IDLE → MASTER ARM"
    tela.blit(fontes["p"].render(rod, True, (110, 130, 120)), (40, A - 44))
    if random.random() < 0.05:
        ruido(tela, 4)


def rodar_jogo(arq, painel):
    painel.display("GO  ")
    painel.fechar()                                  # o jogo abre o próprio Painel
    pygame.display.quit()
    subprocess.call([sys.executable, os.path.join(JOGOS, arq)], cwd=JOGOS)


def main():
    janela = "--janela" in sys.argv
    pygame.init()
    tela = pygame.display.set_mode((L, A), 0 if janela else pygame.FULLSCREEN | pygame.SCALED)
    pygame.mouse.set_visible(False)
    fontes = {"g": pygame.font.SysFont("dejavusansmono", 64, bold=True),
              "m": pygame.font.SysFont("dejavusansmono", 30, bold=True),
              "p": pygame.font.SysFont("dejavusansmono", 18)}
    painel = Painel()
    abertura(tela, fontes, painel)
    jogos, sel = ler_jogos(), 0
    relogio = pygame.time.Clock()
    painel.display("SEL ")
    while True:
        cmd = None
        for ev in pygame.event.get():
            if ev.type == pygame.QUIT or (ev.type == pygame.KEYDOWN and ev.key == pygame.K_ESCAPE and janela):
                return
            if ev.type == pygame.KEYDOWN:
                cmd = {pygame.K_UP: "cima", pygame.K_DOWN: "baixo", pygame.K_RETURN: "ok"}.get(ev.key, cmd)
        for nome, ligado in painel.eventos():
            if ligado:
                cmd = {"ENG1": "cima", "ENG2": "baixo", "START": "ok"}.get(nome, cmd)
        if jogos and cmd == "cima":
            sel = (sel - 1) % len(jogos); painel.beep(20)
        if jogos and cmd == "baixo":
            sel = (sel + 1) % len(jogos); painel.beep(20)
        if jogos and cmd == "ok":
            painel.beep(120)
            rodar_jogo(jogos[sel][2], painel)
            pygame.display.init()
            tela = pygame.display.set_mode((L, A), 0 if janela else pygame.FULLSCREEN | pygame.SCALED)
            pygame.mouse.set_visible(False)
            painel = Painel(); painel.display("SEL "); painel.neon(0, 200, 255)
            jogos = ler_jogos()
        desenhar_menu(tela, fontes, jogos, sel, time.time())
        pygame.display.flip()
        relogio.tick(30)


if __name__ == "__main__":
    main()
