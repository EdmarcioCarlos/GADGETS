#!/usr/bin/env python3
"""
CYBERDECK BLACK BIRD - serviço do painel (roda sozinho ao ligar o Pi, pelo systemd)

- Avisa o painel (ESP32-C3) que o Pi terminou de ligar: manda "PRONTO".
- Quando o painel pede "DESLIGAR" (MASTER ARM desligado ou BAT desligada),
  responde "DESLIGANDO" e desliga o Pi com segurança. O painel espera e só
  então corta a energia.
- Repassa os botões do painel para os jogos (UDP 127.0.0.1:5005) e manda
  para o painel os comandos dos jogos (UDP 127.0.0.1:5006): LED, BEEP, NEON, DISP.

Ligação: GPIO14 (TX do Pi) -> GPIO20 do C3 · GPIO15 (RX do Pi) <- GPIO21 do C3 · GND junto.
"""
import socket
import subprocess
import threading
import time

import serial  # pip: pyserial

PORTA_SERIAL = "/dev/serial0"
EVENTOS = ("127.0.0.1", 5005)      # o serviço envia os eventos para cá (os jogos escutam)
COMANDOS = ("127.0.0.1", 5006)     # os jogos mandam comandos para cá


def principal():
    ser = serial.Serial(PORTA_SERIAL, 115200, timeout=0.2)
    udp_out = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    udp_in = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    udp_in.bind(COMANDOS)
    trava = threading.Lock()

    def enviar(linha):
        with trava:
            ser.write((linha.strip() + "\n").encode("ascii", "ignore"))

    def repassar_comandos():                       # jogos -> painel
        while True:
            dados, _ = udp_in.recvfrom(256)
            enviar(dados.decode("utf-8", "ignore"))

    threading.Thread(target=repassar_comandos, daemon=True).start()

    time.sleep(1)
    enviar("PRONTO")                               # o display do painel mostra " on "
    enviar("DISP on  ")

    while True:                                    # painel -> Pi
        linha = ser.readline().decode("ascii", "ignore").strip()
        if not linha:
            continue
        if linha == "DESLIGAR":
            enviar("DESLIGANDO")
            subprocess.call(["sync"])
            subprocess.call(["systemctl", "poweroff"])
            return
        udp_out.sendto(linha.encode(), EVENTOS)    # "BTN APU 1", "EVT ABORT"...


if __name__ == "__main__":
    while True:                                    # se a serial cair, tenta de novo
        try:
            principal()
            break
        except serial.SerialException:
            time.sleep(3)
