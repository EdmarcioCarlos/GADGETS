"""
CYBERDECK BLACK BIRD - biblioteca do painel para os jogos

    from painel import Painel
    p = Painel()
    for nome, ligado in p.eventos():      # sem travar: devolve o que chegou desde a última vez
        if nome == "START" and ligado: ...
    p.led("APU", True); p.beep(100); p.neon(255, 0, 200); p.display("HACK")

Nomes dos controles: ARM, APU, ENG1, ENG2, MANETE, START (NEON é só da fita de LED).
Se o serviço do painel não estiver rodando (testando no PC), tudo continua funcionando:
os comandos são ignorados e o teclado faz o papel dos botões:
    A = APU · 1 = ENG1 · 2 = ENG2 · M = MANETE · ENTER = START
"""
import socket

EVENTOS = ("127.0.0.1", 5005)
COMANDOS = ("127.0.0.1", 5006)

TECLAS_SIMULADAS = {"a": "APU", "1": "ENG1", "2": "ENG2", "m": "MANETE", "return": "START"}


class Painel:
    def __init__(self):
        self._out = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        self._in = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        self._in.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        try:
            self._in.bind(EVENTOS)
        except OSError:
            pass
        self._in.setblocking(False)

    # ---------- entradas ----------
    def eventos(self):
        """Lista de (nome, ligado) que chegaram do painel desde a última chamada."""
        saida = []
        while True:
            try:
                dados, _ = self._in.recvfrom(256)
            except (BlockingIOError, OSError):
                break
            partes = dados.decode("ascii", "ignore").split()
            if len(partes) == 3 and partes[0] == "BTN":
                saida.append((partes[1], partes[2] == "1"))
            elif partes[:2] == ["EVT", "ABORT"]:
                saida.append(("ABORT", True))
        return saida

    def tecla_pygame(self, evento):
        """Converte uma tecla do pygame em (nome, ligado) para testar sem o painel; senão None."""
        import pygame
        if evento.type in (pygame.KEYDOWN, pygame.KEYUP):
            nome = TECLAS_SIMULADAS.get(pygame.key.name(evento.key))
            if nome:
                return nome, evento.type == pygame.KEYDOWN
        return None

    def fechar(self):
        """Solta a porta dos eventos (o menu chama antes de abrir um jogo, que cria o seu Painel)."""
        self._in.close()
        self._out.close()

    # ---------- saídas ----------
    def _enviar(self, texto):
        try:
            self._out.sendto(texto.encode("ascii", "ignore"), COMANDOS)
        except OSError:
            pass

    def led(self, nome, ligado):        # APU, ENG1, ENG2, START
        self._enviar(f"LED {nome} {1 if ligado else 0}")

    def beep(self, ms=80):
        self._enviar(f"BEEP {int(ms)}")

    def neon(self, r, g, b):
        self._enviar(f"NEON {int(r)} {int(g)} {int(b)}")

    def display(self, texto):           # 4 caracteres (letras limitadas: A b C d E F G H I J L n o P r S t U y -)
        self._enviar("DISP " + texto[:4].ljust(4))
