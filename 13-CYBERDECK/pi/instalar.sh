#!/bin/bash
# CYBERDECK BLACK BIRD - instalação no Raspberry Pi OS (com área de trabalho)
# Copie a pasta "pi" para /home/<usuario>/cyberdeck e rode:  bash instalar.sh
set -e
DIR="$(cd "$(dirname "$0")" && pwd)"
USUARIO="$(whoami)"

echo ">> pacotes (pygame e pyserial)"
sudo apt update
sudo apt install -y python3-pygame python3-serial

echo ">> serial dos pinos 14/15 para o painel (sem console nela)"
sudo raspi-config nonint do_serial_hw 0      # liga a porta serial
sudo raspi-config nonint do_serial_cons 1    # tira o console da serial

echo ">> serviço do painel (avisa PRONTO e desliga com segurança)"
sudo tee /etc/systemd/system/painel.service > /dev/null <<EOF
[Unit]
Description=Painel de partida do Cyberdeck BLACK BIRD
After=multi-user.target

[Service]
ExecStart=/usr/bin/python3 $DIR/painel_servico.py
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl daemon-reload
sudo systemctl enable painel.service

echo ">> menu abrindo sozinho na área de trabalho"
mkdir -p ~/.config/autostart
cat > ~/.config/autostart/cyberdeck-menu.desktop <<EOF
[Desktop Entry]
Type=Application
Name=Cyberdeck Menu
Exec=/usr/bin/python3 $DIR/menu.py
EOF

echo ">> pronto. Reinicie (sudo reboot). Para sair do menu e usar o desktop: ALT+F4."
