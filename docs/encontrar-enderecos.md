# Encontrar os endereços de RAM

O mod precisa de 3 endereços: `map` (número do mapa), `x` e `y` (posição em quadrados do mapa).
Os endereços ainda são desconhecidos para Pokémon Black. Você encontra os endereços com o `ramscan.lua`.

O `ramscan.lua` funciona como a busca de "valor desconhecido" do Cheat Engine.
Ele lê toda a RAM (4 MB). Depois, ele remove os endereços que não seguem os seus movimentos.

CUIDADO: Cada busca pode congelar o emulador por 1 a 3 segundos. Isto é normal.

## Teclas do ramscan

| Tecla | Ação |
|---|---|
| 1 | Nova busca para o campo atual |
| 2 | O valor aumentou 1 |
| 3 | O valor diminuiu 1 |
| 4 | O valor não mudou |
| 5 | O valor mudou |
| 6 | Próximo campo (map, x, y, dir) |
| 7 | Aceitar o primeiro candidato do campo atual |
| 0 | Salvar em `lua/addresses_local.lua` |

## Procedimento para `x`

1. Carregue a ROM e o save. Fique em uma cidade, em um lugar aberto.
2. Carregue `lua/ramscan.lua` no **Lua Scripting**.
3. Pressione `6` até o campo mostrar `x`.
4. Pressione `1`.
5. Ande 1 passo para a direita.
6. Pressione `2`.
7. Ande 1 passo para a esquerda.
8. Pressione `3`.
9. Fique parado. Pressione `4`.
10. Repita os passos 5 a 9 até ficarem poucos candidatos (menos de 5).
11. Pressione `7`.

## Procedimento para `y`

1. Pressione `6` até o campo mostrar `y`.
2. Pressione `1`.
3. Ande 1 passo para baixo. Pressione `2`.
4. Ande 1 passo para cima. Pressione `3`.
5. Fique parado. Pressione `4`.
6. Repita os passos 3 a 5 até ficarem poucos candidatos.
7. Pressione `7`.

Se `y` diminui quando você anda para baixo, use os passos 3 e 4 ao contrário. Depois, use `flip_y = true` no `config.lua`.

## Procedimento para `map`

1. Pressione `6` até o campo mostrar `map`.
2. Pressione `1`.
3. Entre em uma casa. Pressione `5`.
4. Ande dentro da casa. Pressione `4`.
5. Saia da casa. Pressione `5`.
6. Ande fora. Pressione `4`.
7. Repita os passos 3 a 6 até ficarem poucos candidatos.
8. Pressione `7`.

## Salvar e verificar

1. Pressione `0`. O arquivo `lua/addresses_local.lua` fica salvo.
2. Feche o `ramscan.lua`.
3. Salve um save state. Feche o jogo. Abra o jogo de novo.
4. Carregue o `ramscan.lua`. Veja as linhas verdes `OK`.
5. Ande. Os valores verdes precisam mudar de forma correta.

ATENÇÃO: Se os valores verdes ficam errados depois de reabrir o jogo, o endereço muda a cada execução.
Neste caso, anote o problema em uma issue. O mod vai precisar de um ponteiro, não de um endereço fixo.

Compartilhe os endereços encontrados (o conteúdo de `addresses_local.lua`). Eles valem para todas as cópias da mesma versão.
