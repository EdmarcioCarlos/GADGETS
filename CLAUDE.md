# Diretrizes da pasta GADGETS (projetos Arduino/ESP32 de airsoft — BLACK BIRD)

Sempre responder em português do Brasil. O usuário está começando em eletrônica: explicações simples.

## Organização

- Cada projeto tem uma pasta `NN-NOME-DO-PROJETO`. **NN = posição do projeto no `IDEIAS.txt`**,
  que está em ordem de dificuldade (01 = mais fácil). Ao criar, excluir ou reordenar um projeto,
  renumerar as pastas e atualizar todas as referências: `IDEIAS.txt`, etiqueta "PROJETO NN" no topo
  de cada `PREVIA.html`, cabeçalho dos `.ino`/README, links da `PREVIA-GERAL-LUNETA.html`,
  menções cruzadas ("fica para 06", "kit do 04") e `PAINEL-ESTOQUE.html` (lista `PROJ`).
- Toda pasta de projeto **sempre** tem uma `PREVIA.html` com:
  1. visão geral (tiles com medidas, autonomia e custo);
  2. como funciona;
  3. desenhos com medidas reais em mm (botões "Ampliado / Tamanho real / Calibrar tela");
  4. componentes;
  5. ligação elétrica (diagrama + tabela De/Para);
  6. montagem passo a passo;
  7. **tabela de custo com links de compra** (Mercado Livre e lojas BR, preços pesquisados, mês/ano);
  8. pontos de atenção.
- **Sempre que um projeto for alterado, a PREVIA.html dele é atualizada junto** (pedido do usuário em 2026-10-16):
  tiles, como funciona, desenhos gerados dos modelos, imagem das peças, componentes, ligação, montagem, custo e atenção.
- Todo projeto tem **código** (`.ino` numa subpasta com o mesmo nome do arquivo). Expansões usam uma
  opção no código do projeto base (ex.: uma constante `const bool COM_X = false;` no .ino do projeto base),
  explicada num `CODIGO-LEIA-ME.txt`. Exceção: projeto só mecânico não tem código nem seção de ligação elétrica
  (a prévia diz isso). Aparelhos que conversam por rádio usam a mesma `struct Msg`
  ESP-NOW (magico 0xBB, canal 1, modo LR) e o mesmo pareamento (código do squad).
- **Padrão de LED: 3 mm** em todos os projetos (furo 3,2 mm).
- **Placas do usuário (desenhar igual nos diagramas de ligação):**
  - TP4056 USB-C com proteção: USB-C numa ponta; na outra ponta os 4 pontos de solda, nesta ordem:
    **OUT+, B+, B−, OUT−** (o B fica ao lado do OUT, tudo na mesma borda). A bateria vai nos 2 do meio.
  - ESP32-C3 SuperMini: atrás só aparece o **número** do pino ("5" = GPIO5) e **"3.3"** = 3V3. Nos textos para
    o usuário, escrever "pino 5 (GPIO5)" quando for a primeira vez.
- **Padrão de parafuso (pedido do usuário: comprar em pacotes grandes, só mudando o tamanho):**
  - **M3 cabeça Allen (DIN 912) + porca M3** em tudo que é estrutural (tampas, garras, caixas, dobradiças).
    Comprimentos: 8, 10, 12, 16, 25, 30, 50 mm. No plástico: pino Ø7 com furo 2,6 (rosca direto no PETG),
    furo de passagem 3,4, alojamento de porca sextavado 6,6. Nada de M4.
  - **M2** (pacote pequeno) só para plaquinhas com furo pequeno (OLED 0,96″, PIR): pino Ø4,5 com furo 1,7.
  - **Nunca cola quente** para prender peça ou placa (o usuário quer desmontar). Placa sem furo (OLED 0,91″)
    vai em apoios impressos (`apoio_tela`) e a tampa segura; motor vai com trava impressa parafusada.

## Peças 3D

- Todo projeto com peças impressas tem a subpasta `3D/` com `pecas.scad` (usa `../../_BIBLIOTECA-3D/bb_lib.scad`),
  `stl/` (uma peça por arquivo, já na posição de impressão) e `LEIA-ME.txt` (peças, quantidades, suporte,
  ferragens, configuração de impressão).
- Impressora: Creality K1C, mesa **220 × 220 × 250**. Peça maior é dividida (ex.: maleta em quartos com nervuras M3).
- **Marca: UM lugar só por projeto** (pedido do usuário em 2026-10-13: nome em todas as peças ficava repetitivo).
  Emblema (`emblema_*`) + nome "BLACK BIRD" juntos, numa peça bem visível e com espessura de sobra
  (de preferência a tampa coyote). Nenhuma outra peça leva "BLACK BIRD" nem "BB". Rótulos funcionais
  (S1/S2, RFID, seta CANO) podem ficar. Comentar no `pecas.scad` com `// MARCA DO PROJETO (única)`.
- **Resistente a BB a mais de 10 m**: paredes ≥ 3 mm, PETG, 5 perímetros, 5 camadas topo/fundo, 40% giroide;
  telas atrás de janela de policarbonato. Toda caixa tem tampa; conferir encaixe (garras, travas, tampas).
- **Estilo visual: TÁTICO FACETADO — diretriz obrigatória para TODOS os projetos, inclusive os novos**
  (escolhido em 2026-10-13; já aplicado em todos). Usar os módulos da `bb_lib.scad`, nunca caixa arredondada:
  - caixas: `caixa_tatica` (cantos chanfrados, parede igual em todo o contorno; pinos internos como children);
    sólidos: `prisma_oct`/`oct2d`; peças redondas grandes: `octogono`;
  - tampas: `tampa_tatica` (impressa de cara na mesa) ou `placa_chanfrada` (tampa com aba para baixo), **4 mm**
    (3 úteis + 1 para as gravações);
  - botões/conectores numa parede: `moldura_oct` saliente 2 mm em volta (protege e evita aperto sem querer);
  - faces grandes livres: `hex_relevo` (acrescentado por fora); tampas: `nervuras_*` em V apontando para a
    frente/cano + `emblema_*` (pássaro BLACK BIRD) + nome;
  - cores: **preto** (corpo) + **coyote** (tampas, mandíbula, botões e peças de destaque), cada peça de uma cor
    só; exceções com motivo (capa míssil vermelha = alerta). Escrever as cores
    no cabeçalho do `pecas.scad` e no `LEIA-ME.txt`;
  - segurança: visual só com material acrescentado; parede ≥ 3 mm também nos cantos (cavidade = `offset` da
    forma externa); gravação decorativa ≤ 0,8 mm só onde sobram ≥ 3 mm; furos de parafuso a ≥ 1,5 mm do chanfro.
  - Tudo que vai na luneta (03, 12) precisa combinar entre si.
  - Cada `PREVIA.html` tem a seção "Peças 3D" com a imagem colorida `3D/img/pecas.png` (gerar de novo ao mudar peças).
  - **Os desenhos do aparelho nas prévias são gerados dos modelos**, nunca desenhados à mão: cada `3D/` tem
    `montagem.scad` (peças na posição de uso, com cor; itens de referência como trilho, tubo, telas e componentes
    dentro de `if (EXTRAS)`), e o desenho é um `<svg class="vistas3d">` com vistas ortogonais (`3D/img/*.png`) em
    escala real e cotas medidas sem os EXTRAS. Ao mudar uma peça, gerar de novo as vistas e trocar o svg na prévia.
  - Prévia dos estilos considerados: `03-NIVEL-ANTI-CANT/3D/estilos/ESTILOS.html`.
  - **Prévia geral no AEG** (`PREVIA-AEG/`): réplica do Rossi MK16 URG-I 13,5″ (450 fps, silenciador, magazine M4 comum)
    com os gadgets do rifle importados de `PREVIA-AEG/3D/stl/NN_*_preto|coyote.stl`, exportados das `montagem.scad`
    de cada projeto com `EXTRAS=false` e `COR="preto"`/`"coyote"` (módulo `pinta()`). Ao mudar um gadget que vai no
    rifle (03, 06, 12, 14; o traçante 10 fica dentro do silenciador e não aparece), exportar de novo o par de STL e refazer as vistas. Conferir interferências
    (ex.: o laser do telêmetro passa 32 mm acima do eixo da luneta: nada pode ficar na frente dele).
- Gerar STL pelo OpenSCAD (`C:\Program Files\OpenSCAD\openscad.exe`) e conferir que não há aviso de manifold.
- Cada peça impressa tem uma linha `p3d_NN_peca` no `ESTOQUE.js` e a quantidade em `P3D` no `PAINEL-ESTOQUE.html`.

## Compras: foco em kits e reaproveitamento

- Sempre o **mais barato possível**, pesquisando no Mercado Livre e em lojas nacionais (WebSearch;
  o ML bloqueia fetch direto). Importado só quando não existir no Brasil.
- **Só produtos NOVOS**, nunca usados: preços pesquisados só em anúncios novos. Links do Mercado
  Livre sempre como busca com o filtro "Novo" (`https://lista.mercadolivre.com.br/<termo>_ITEM*CONDITION_2230284`)
  ou página de catálogo (`/p/MLB…`); nunca link de anúncio avulso (`produto.mercadolivre…`), porque não dá para
  garantir que é novo.
- **Preferir kits/conjuntos** a peças avulsas. Na tabela, marcar com "**Conjunto:**" e ter a coluna
  **"Fica para"**, dizendo em quais outros projetos as sobras do kit são usadas.
- Mostrar dois totais: **comprando os kits inteiros** e **só as peças usadas / reaproveitando kits**
  de projetos anteriores (na ordem da lista).
- Peças impressas em 3D não entram no custo (o usuário tem impressora 3D; preferir peças impressas).
- Ao adicionar uma peça nova a um projeto, incluir no `ESTOQUE.js` e no catálogo `CAT` do `PAINEL-ESTOQUE.html`.

## Estoque

- `ESTOQUE.js` é a fonte única do que o usuário tem (números por peça + lista `MONTADOS`).
- Quando o usuário disser o que chegou, o que gastou ou o que montou, atualizar o `ESTOQUE.js`
  e responder quais projetos passaram a poder ser montados e o que falta para o próximo da lista.
- `PAINEL-ESTOQUE.html` lê o `ESTOQUE.js` sozinho (não precisa regerar).

## Segurança ao editar

- Nunca gravar um arquivo se a leitura falhou ou veio vazia. Para mudanças em vários arquivos,
  preferir a ferramenta Edit (uma troca por vez) em vez de scripts de substituição em massa.
- PowerShell não diferencia maiúsculas em variáveis (`$F` = `$f`): em scripts, usar nomes longos e únicos
  (um laço `foreach($f ...)` já sobrescreveu um `$F` e enfiou o caminho do arquivo nos links).
- Pasta travada para renomear = o usuário está com um arquivo dela aberto; pedir para fechar.
