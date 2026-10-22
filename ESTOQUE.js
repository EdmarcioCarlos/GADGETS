// =====================================================================
//  ESTOQUE DE PEÇAS - BLACK BIRD GADGETS
// =====================================================================
//  Como usar:
//   - Troque só os NÚMEROS (quantas unidades você tem de cada peça).
//   - Kit que você comprou: coloque o número de unidades que vieram
//     (ex.: kit 5 ESP32-C3 = 5; kit 100 botões = 100).
//   - Depois de salvar, recarregue o PAINEL-ESTOQUE.html (F5).
//   - Ou só me diga no chat: "chegou o kit de ESP32-C3" ou
//     "gastei 2 LEDs" e eu atualizo este arquivo para você.
//   - Peças impressas ficam no fim (p3d_...): some 1 a cada peça
//     que sair da impressora (ou diga "imprimi a tampa do 03").
//
//  MONTADOS: projetos que você já terminou.
// =====================================================================

var MONTADOS = [];   // exemplo: ["01", "02"]

var ESTOQUE = {
  // --- placas ---
  arduino_uno:        0,  // Arduino Uno R3 (vem no kit iniciante)
  esp32c3:            1,  // ESP32-C3 SuperMini
  esp32_devkit:       0,  // ESP32 DevKit V1 30 pinos
  rpi4_kit:           0,  // Kit Raspberry Pi 4 (placa + case + cartão + cabo + fonte)

  // --- telas ---
  lcd16x2_i2c:        0,  // Display LCD 16x2 com módulo I2C
  oled096:            1,  // OLED 0,96" 128x64 I2C
  oled091:            0,  // OLED 0,91" 128x32 I2C
  monitor_156:        0,  // Monitor portátil 15,6" Full HD (cyberdeck 12)

  // --- sensores e módulos ---
  mpu6050:            1,  // MPU6050 GY-521 (acelerômetro/giroscópio)
  par_ir:             0,  // Par LED infravermelho + fototransistor
  cc1101:             0,  // Módulo CC1101 433 MHz com antena
  laser_jc02:         0,  // Módulo laser telêmetro JC02-1 (importado)
  rele_1canal:        0,  // Módulo relé 1 canal 5 V
  uln2003:            0,  // Módulo ULN2003
  lm393:              0,  // CI comparador LM393 DIP-8
  l9110s:             0,  // Módulo ponte H L9110S (liga motor para frente e ré)
  n20_motor:          0,  // Motor N20 6 V com redução (100 rpm)

  // --- energia ---
  tp4056:             3,  // Carregador TP4056 USB-C
  lipo_250:           0,  // LiPo 3,7 V 250 mAh (502030)
  lipo_600:           1,  // LiPo 3,7 V 600 mAh (503040)
  lipo_1000:          0,  // LiPo 3,7 V 1000 mAh (603450)
  bat18650:           0,  // Bateria 18650
  suporte18650:       0,  // Suporte para 1 bateria 18650
  modulo_18650_boost: 0,  // Módulo 18650 com carregador e saída 5 V
  suporte_6aa:        0,  // Suporte 6 pilhas AA com chave
  pilha_aa:           2,  // Pilhas AA
  powerbank:          0,  // Power bank 20.000 mAh 65 W com 2 USB-C

  // --- botões e chaves ---
  botao_6x6:          10,  // Botão tátil 6x6
  botao_arcade:       0,  // Botão arcade 30 mm (sem LED)
  botao_arcade_led:   0,  // Botão arcade 30 mm com LED 5 V
  botao_trava_8x8:    0,  // Chave/botão com trava 8x8
  chave_ss12:         10,  // Chave deslizante SS12D00
  chave_mts102:       0,  // Chave alavanca MTS-102
  teclado4x4:         0,  // Teclado matricial de membrana 4x4
  mini_teclado:       0,  // Mini teclado sem fio com touchpad

  // --- som, vibração e luz ---
  buzzer_ativo:       0,  // Buzzer ativo 5 V
  sirene_piezo:       0,  // Sirene piezo 12 V 110 dB
  motor_vibra:        0,  // Motor vibracall 1027 3 V
  led_3mm:            200,  // LEDs 3 mm (qualquer cor) - padrão de LED de todos os projetos

  // --- componentes pequenos ---
  bc547:              0,  // Transistor BC547
  diodo_1n4148:       0,  // Diodo 1N4148
  kit_resistores:     1,  // Kit de resistores sortidos (1 = tenho o kit)
  trimpot:            0,  // Trimpot 10 kΩ
  jumpers:            0,  // Kit de jumpers (1 = tenho o kit)

  // --- fios, fixação e caixas ---
  borne_banana_par:   0,  // Par borne fêmea + pino banana 4 mm
  cabinho_cores:      1,  // Cabinho flexível em 4 cores (1 = tenho)
  cabo_4vias:         1,  // Cabo manga 4 vias (1 = tenho o rolo)
  fita_kapton:        1,  // Fita kapton 10 mm (1 = tenho o rolo): isola uma placa da outra
  velcro:             0,  // Fita de velcro 25 mm (1 = tenho o rolo)
  parafusos_m3:       1,  // Kit parafusos Allen M3 + porcas (8 a 30 mm) - padrão de TODOS os projetos
  parafusos_m2:       0,  // Kit parafusos M2 (só para plaquinhas: OLED 0,96", PIR)
  esp32cam:           0,  // ESP32-CAM + base programadora ESP32-CAM-MB
  ov2640_ir:          0,  // Câmera OV2640 sem filtro IR (850 nm, "night vision")
  tft13_st7789:       0,  // Tela IPS 1,3" 240x240 ST7789 (7 pinos)
  lente_cardboard:    0,  // Lente biconvexa 25 mm / foco 45 mm (par, tipo Google Cardboard)
  led_ir_5mm:         0,  // LED infravermelho 5 mm 850 nm (quantidade de LEDs)
  led_ir_3w:          0,  // LED IR 3 W 850 nm em estrela (lanterna IR do 14)
  lente_led_5g:       0,  // Lente colimadora 20 mm 5° (lanterna IR do 14)
  driver_7135:        0,  // Driver de lanterna 17 mm AMC7135 (lanterna IR do 14)
  irlz44n:            0,  // MOSFET IRLZ44N
  extensao_usb:       0,  // Extensão USB de painel
  espuma:             0,  // Placa de espuma para a maleta impressa (1 = tenho)
  laser_verde:        0,  // Módulo laser verde 520 nm Ø12 (ANPEQ 06)
  pilha_16340:        0,  // Pilha 16340 recarregável 3,7 V
  suporte_16340:      0,  // Suporte de pilha 16340 / CR123A
  jack_p2_painel:     0,  // Jack P2 3,5 mm fêmea de painel (entrada do acionador remoto)
  mcp23017:           0,  // Módulo MCP23017 (painel do cyberdeck 11)
  tm1637:             0,  // Display TM1637 4 dígitos
  ws2812_fita:        0,  // Fita WS2812 60 LEDs/m (1 = tenho o rolo)
  microchave_kw11:    0,  // Microchave KW11 (manete do cyberdeck)
  cabo_usbc_3a:       0,  // Cabo USB-A → USB-C 3 A (energia do Pi pelo relé)
  led_1w:             0,  // LED 1 W branco frio em estrela 20 mm (estrobo da granada 08)
  mt3608:             0,  // Módulo elevador MT3608 (3,7 V -> 12 V da sirene)
  reed_switch:        0,  // Reed switch 2 x 14 mm (sensor do pino da granada)
  ima_4x2:            0,  // Ímã de neodímio 4 x 2 mm
  lipo_802540:        0,  // LiPo 1000 mAh 802540 (8 x 25 x 40)
  botao_painel_7mm:   0,  // Botão de painel 7 mm (pulso, com porca)
  chave_kcd11:        0,  // Chave gangorra mini KCD11 (encaixe 10 x 15)
  led_uv_5mm:         0,  // LED ultravioleta 5 mm 395 nm (traçante 09)
  bb_tracer:          0,  // Pote de BB traçante fluorescente (1 = tenho)
  lipo_402030:        0,  // LiPo 200 mAh 402030 (4 x 20 x 30), cabe no cartucho do traçante
  sensor_vibracao:    0,  // Sensor de vibração SW-18010P (acorda o traçante)
  placa_powerbank:    0,  // Placa de power bank 18650 com tela e 2 USB (powerbank 02)
  xt30_par:           0,  // Conector XT30, par macho + fêmea (cartucho do powerbank 02)
  esp32c3_plus:       0,  // ESP32-C3 SuperMini Plus com conector de antena IPEX (amplificador 05)
  antena_24g:         0,  // Antena 2,4 GHz 3 dBi + cabinho IPEX -> RP-SMA (amplificador 05)
  hlk_pm01:           0,  // Fonte HLK-PM01 127/220 V -> 5 V (acionador 09)
  rele_hl:            0,  // Módulo relé 1 canal 5 V com jumper H/L (acionador 09)
  piezo_27:           0,  // Disco piezo 27 mm (alvo 09)
  prensa_pg7:         0,  // Prensa-cabo PG7
  conector_alavanca:  0,  // Conector de alavanca 3 vias (tipo Wago)
  porta_fusivel:      0,  // Porta-fusível de linha 5x20 + fusível 2 A
  cabo_forca:         0,  // Cabo de força 3 x 1,0 mm² com plugue
  fita_fotolum:       0,  // Fita fotoluminescente 10 mm (1 = tenho o rolo)
  placa_ilhada:       0,  // Placa ilhada 5 x 7 cm
  capacitor_100nf:    0,  // Capacitor cerâmico 100 nF

  // =================================================================
  //  PEÇAS IMPRESSAS EM 3D (quantas você já imprimiu de cada)
  //  nome: p3d_<projeto>_<peça>, igual ao arquivo em <pasta>\3D\stl
  // =================================================================
  // 01 bomba
  p3d_01_caixa: 0, p3d_01_painel: 0, p3d_01_moldura_lcd: 0, p3d_01_alca: 0, p3d_01_passa_fios: 0,
  // 02 powerbank dos tablets (por powerbank)
  p3d_02_caixa: 0, p3d_02_tampa: 0, p3d_02_cartucho: 0, p3d_02_botao_aperto: 0, p3d_02_calco: 0,
  // 03 anti-cant
  p3d_03_caixa: 0, p3d_03_tampa: 0, p3d_03_mandibula: 0, p3d_03_pod: 0,
  // 04 cronógrafo
  p3d_04_tunel: 0, p3d_04_visor: 0, p3d_04_tampa_inferior: 0, p3d_04_adaptador_boca: 0,
  // 05 amplificador de rede (por rádio)
  p3d_05_caixa: 0, p3d_05_tampa: 0, p3d_05_calco: 0, p3d_05_tampao_antena: 0,
  // 06 ANPEQ
  p3d_06_caixa: 0, p3d_06_tampa: 0, p3d_06_berco: 0, p3d_06_trava_pivo: 0, p3d_06_botao_torre: 0, p3d_06_mandibula: 0, p3d_06_protecao_bb: 0,
  // 07 speedloader
  p3d_07_corpo: 0, p3d_07_tampa_inferior: 0, p3d_07_reservatorio: 0, p3d_07_tampa_reservatorio: 0,
  p3d_07_roda: 0, p3d_07_trava_roda: 0, p3d_07_trava_motor: 0, p3d_07_bico_m4: 0, p3d_07_capa_botao: 0,
  // 08 granada de som e luz
  p3d_08_corpo: 0, p3d_08_base: 0, p3d_08_topo: 0, p3d_08_pino: 0, p3d_08_chassi: 0,
  p3d_08_suporte_led: 0, p3d_08_presilha: 0, p3d_08_presilha_lipo: 0,
  // 09 alvo acionador de lâmpada (por conjunto)
  p3d_09_caixa_alvo: 0, p3d_09_tampa_alvo: 0, p3d_09_alvo: 0, p3d_09_trava_piezo: 0,
  p3d_09_caixa_acionador: 0, p3d_09_tampa_acionador: 0, p3d_09_capa_botao: 0,
  // 10 traçante (cartucho dentro do silenciador)
  p3d_10_chassi: 0, p3d_10_frente: 0, p3d_10_presilha_c3: 0, p3d_10_presilha_lipo: 0, p3d_10_presilha_tp: 0,
  // 11 scanner
  p3d_11_corpo: 0, p3d_11_tampa_frente: 0, p3d_11_clipe_molle: 0,
  // 12 telêmetro
  p3d_12_corpo: 0, p3d_12_tampa: 0, p3d_12_grade: 0, p3d_12_berco_laser: 0, p3d_12_capa_botao: 0, p3d_12_tampa_anel: 0,
  // 13 cyberdeck
  p3d_13_base_fe: 0, p3d_13_base_fd: 0, p3d_13_base_te: 0, p3d_13_base_td: 0,
  p3d_13_tampa_fe: 0, p3d_13_tampa_fd: 0, p3d_13_tampa_te: 0, p3d_13_tampa_td: 0,
  p3d_13_painel_fe: 0, p3d_13_painel_fd: 0, p3d_13_painel_te: 0, p3d_13_painel_td: 0,
  p3d_13_cantoneira_tela: 0, p3d_13_capa_missil_base: 0, p3d_13_capa_missil_tampa: 0, p3d_13_suporte_tm1637: 0, p3d_13_manete_base: 0, p3d_13_manete_alavanca: 0, p3d_13_trilho_neon: 0,
  p3d_13_dobradica_base: 0, p3d_13_dobradica_tampa: 0, p3d_13_trava_lingueta: 0, p3d_13_trava_batente: 0,
  p3d_13_alca: 0, p3d_13_emenda: 0, p3d_13_coluna: 0,
  // 14 visão noturna
  p3d_14_casco: 0, p3d_14_tampa: 0, p3d_14_capuz_lente: 0, p3d_14_suporte_tela: 0,
  p3d_14_base_flip: 0, p3d_14_base_fixa: 0, p3d_14_mandibula: 0, p3d_14_capa_botao: 0, p3d_14_pino_trava: 0,
  p3d_14_ir_caixa: 0, p3d_14_ir_tampa: 0, p3d_14_tnut_mlok: 0
};
