# Instalador do OmniRoute para Termux

Este script instala o OmniRoute diretamente no Termux, sem `proot-distro`.

## Instalação

No Termux:

```sh
curl -fsSL https://raw.githubusercontent.com/seu-usuario/seu-repositorio/main/install-omniroute-termux.sh -o install-omniroute-termux.sh
chmod +x install-omniroute-termux.sh
./install-omniroute-termux.sh
```

Se o arquivo estiver sendo transferido manualmente para o telefone, basta executar:

```sh
bash install-omniroute-termux.sh
```

## Comandos

```sh
omniroute-start
omniroute-status
omniroute-stop
```

O painel fica disponível em:

```text
http://127.0.0.1:20128
```

Para executar diretamente no terminal:

```sh
omniroute
```

O log do modo em segundo plano fica em `~/omniroute.log`.

## Observações

O script usa o `nodejs` atual do Termux, além de `python`, `build-essential`, `git` e `curl`. O guia oficial atual do OmniRoute requer Node.js 22 ou superior. O script também cria `~/.cache` e configura `XDG_CACHE_HOME`, evitando o erro conhecido de runtime Android em algumas versões.

Depois de abrir o painel, configure os provedores e as chaves de API. Não compartilhe essas chaves e não exponha a porta 20128 à internet sem autenticação e uma rede confiável.

Referência: [guia oficial do OmniRoute para Termux](https://github.com/diegosouzapw/OmniRoute/blob/release/v3.8.51/docs/guides/TERMUX_GUIDE.md).
