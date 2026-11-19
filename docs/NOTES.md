# Notas de pesquisa: Pokémon Black/White co-op

Formato do playbook Co-op Anything: observações, deduções, hipóteses e desconhecidos em listas separadas.

## Identidade do jogo

- Jogo: Pokémon Black (Nintendo DS, 2010). Código esperado `IRBO` (EUA/Europa, inglês).
- Emulador: DeSmuME (escolha do dono).
- SHA-256 da ROM: desconhecido. A ROM não estava acessível nesta sessão.

## Observações (verificadas)

- Não há mod co-op para Pokémon Gen 5 no DIRECTORY.md do Co-op Anything (busca em 2026-11-19).
- O playbook recomenda, para DS: a emulação de wireless local quando o jogo tem modo local. Pokémon Black não tem modo co-op no mapa, então o caminho é memory-sync (Route B).
- Exemplo próximo: PK-GBA Multiplayer (Gen 3, mGBA Lua), status não verificado.

## Deduções

- O cabeçalho do cartucho fica copiado em `0x027FFE00` na RAM do ARM9. O código do jogo fica em `0x027FFE0C`. O mod usa este valor para escolher a tabela de endereços.
- Coordenadas em quadrados mudam em 1 por passo. Por isso o `ramscan` usa os filtros +1 e -1.

## Hipóteses (não verificadas)

- A posição do jogador pode ficar em memória dinâmica (heap). Se isto for verdade, o endereço muda entre execuções e o mod precisa de um ponteiro.
- O DeSmuME desenha a tela de cima em y 0..191 (ou -192..-1, dependendo da versão). Por isso existe `top_screen_y`.

## Desconhecidos

- Endereços de `map`, `x`, `y`, `dir` em Pokémon Black.
- Posição exata do jogador na tela e escala por quadrado (a câmera do Gen 5 tem perspectiva).

## Próximas fases

1. Encontrar e verificar os endereços (dono, com `ramscan.lua`).
2. Calibrar `center_x`, `center_y`, `tile_px` com os dois jogadores lado a lado.
3. Mostrar o parceiro como NPC real: escrever a posição em um slot de NPC do mapa atual.
4. Compartilhar progresso: flags de evento, insígnias, itens importantes (host decide).
5. Bot de teste: dois DeSmuME com entrada por script, verificar posições por RAM.
