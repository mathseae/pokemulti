# PokeMulti

Mod co-op para **Pokémon Black/White** no emulador **DeSmuME**.
Cada jogador controla o seu próprio personagem, na sua própria janela do DeSmuME.
O mod mostra a posição do parceiro na tela de cima.

Método: "memory-sync" (Route B do [Co-op Anything](https://github.com/cranebeaker/coop-anything/blob/main/playbook/console-emulators.md)).
Um script Lua lê a posição do jogador na RAM. O script troca esta posição com a outra janela.

ATENÇÃO: Este repositório não contém a ROM. Cada jogador usa a sua própria ROM.
As duas ROMs precisam ser da mesma versão (mesmo código de jogo, por exemplo `IRBO`).

## Estado atual

| Função | Estado |
|---|---|
| Ver o parceiro no mesmo mapa (marcador) | Feito. Testado só com DeSmuME simulado. |
| Aviso "parceiro em outro mapa" / "offline" | Feito. Testado só com DeSmuME simulado. |
| Jogar em 2 janelas no mesmo PC | Feito (arquivos na pasta `link`). |
| Jogar em 2 PCs (LAN ou internet) | Feito (`relay/relay.py`). Testado com sockets locais. |
| Endereços de RAM de Pokémon Black | **Desconhecidos.** Use o `ramscan.lua` uma vez. |
| Sprite real do parceiro no mapa (NPC) | Não feito. Próxima fase. |
| Progresso compartilhado (insígnias, flags) | Não feito. |

## O que você precisa

- DeSmuME 0.9.11 ou mais novo, versão Windows (tem o menu **Tools > Lua Scripting**).
- A sua ROM de Pokémon Black.
- Python 3.8 ou mais novo (só para jogar em 2 PCs).

## Passo 1: encontrar os endereços de RAM (uma vez)

Faça este passo uma vez por versão do jogo. Siga [docs/encontrar-enderecos.md](docs/encontrar-enderecos.md).
O resultado fica no arquivo `lua/addresses_local.lua`.

## Passo 2: jogar no mesmo PC

1. Abra o DeSmuME duas vezes.
2. Na janela 1, abra a ROM e carregue o seu save.
3. Na janela 2, abra a ROM e carregue o save do jogador 2.
4. Na janela 1, abra **Tools > Lua Scripting > New Lua Script Window**.
5. Clique **Browse** e escolha `lua/pokemulti_p1.lua`.
6. Clique **Run**.
7. Na janela 2, faça os passos 4 a 6 com `lua/pokemulti_p2.lua`.
8. Ande até o mesmo mapa. Um quadrado rosa mostra o parceiro.

CUIDADO: O DeSmuME só lê o teclado da janela ativa. Use um controle por janela, ou alterne entre as janelas.

## Passo 3 (opcional): jogar em 2 PCs

1. Cada PC faz o Passo 2 com uma janela só. O PC 1 usa `pokemulti_p1.lua`. O PC 2 usa `pokemulti_p2.lua`.
2. No PC 1, abra um terminal na pasta do mod.
3. No PC 1, execute: `python relay/relay.py host --me 1`
4. No PC 2, execute: `python relay/relay.py join --me 2 --address <IP do PC 1>`

ATENÇÃO: Na internet, o PC 1 precisa liberar a porta TCP 47811 no roteador. Uma VPN de LAN (por exemplo, Tailscale ou ZeroTier) também funciona.

## Configuração

Edite `lua/config.lua`:

- `names`: o nome de cada jogador.
- `toggle_key`: a tecla que mostra ou esconde o marcador (padrão `P`).
- `top_screen_y`: use `0` ou `-192`. O texto inicial precisa aparecer na tela de cima.
- `marker.center_x`, `marker.center_y`: a posição do seu personagem na tela.
- `marker.flip_y`: use `true` se o marcador anda na direção vertical errada.

## Testes

Os testes usam um DeSmuME simulado. Eles não precisam da ROM.

```
python -I tests/run_tests.py
```

O resultado correto termina com `ALL OK`. Precisa de `lua5.1` no PATH.

## Estrutura

| Caminho | Conteúdo |
|---|---|
| `lua/pokemulti.lua` | Script principal (não carregue direto). |
| `lua/pokemulti_p1.lua`, `lua/pokemulti_p2.lua` | Scripts para carregar no DeSmuME. |
| `lua/ramscan.lua` | Busca dos endereços de RAM. |
| `lua/config.lua` | Configuração. |
| `lua/coop/` | Módulos: protocolo, link, marcador, busca, endereços. |
| `relay/relay.py` | Ponte TCP entre 2 PCs. |
| `tests/` | Testes. |
| `docs/NOTES.md` | Notas de pesquisa e próximos passos. |
