# Claude Code + OmniRoute no Termux

Este pacote instala o **Claude Code** e o **OmniRoute** em aparelhos Android com Termux. O script usa o pacote npm do Claude Code porque o instalador nativo oficial não é compatível com o ABI Android do Termux. O OmniRoute é executado como servidor headless, sem Electron, bandeja do sistema ou integração desktop.

## Instalação

Instale o Termux pelo [F-Droid](https://f-droid.org/packages/com.termux/) ou pelos releases oficiais do projeto. Depois, copie `install-claude-omniroute-termux.sh` para o aparelho e execute:

```sh
chmod +x install-claude-omniroute-termux.sh
./install-claude-omniroute-termux.sh
```

O script instala `nodejs`, `npm`, `python`, `build-essential`, `git` e `curl`. O OmniRoute atual requer Node.js 22 ou superior; por isso, o script usa `nodejs`, e não `nodejs-lts`.

## Uso

Depois da instalação, autentique o Claude Code executando:

```sh
claude
```

Inicie o OmniRoute em segundo plano com:

```sh
omniroute-start
```

Abra o painel em <http://localhost:20128>. O arquivo de log fica em `~/omniroute.log`. Para verificar ou parar o servidor, use:

```sh
omniroute-status
omniroute-stop
```

## Inicialização ao ligar o aparelho

Para iniciar o OmniRoute automaticamente, instale o complemento **Termux:Boot** e execute:

```sh
mkdir -p ~/.termux/boot
cat > ~/.termux/boot/omniroute.sh <<'EOF'
#!/data/data/com.termux/files/usr/bin/sh
omniroute-start
EOF
chmod +x ~/.termux/boot/omniroute.sh
```

Também é necessário desativar a otimização de bateria do Android para o Termux. Caso contrário, o sistema poderá encerrar o processo em segundo plano.

## Observações de segurança

O OmniRoute pode acessar vários provedores de IA configurados pelo usuário. Configure as chaves somente no painel local e não compartilhe seus tokens. Não exponha a porta `20128` à internet sem autenticação, HTTPS e uma rede confiável.

## Limitações conhecidas

O modo Electron não funciona no Termux. O painel web e a API compatível com OpenAI funcionam localmente e, se a rede permitir, em outros dispositivos da mesma rede Wi-Fi. Em aparelhos com pouca memória, reduza a concorrência de requisições. Se ocorrer um erro de compilação do SQLite, execute `pkg install nodejs python build-essential` e repita a instalação.

## Fontes

A instalação foi baseada na documentação atual do [Claude Code][1] e no [guia oficial de Termux do OmniRoute][2]. A adaptação do wrapper `claude` considera a incompatibilidade do instalador nativo com Android descrita no [guia comunitário de Claude Code para Termux][3].

[1]: https://code.claude.com/docs/en/setup "Claude Code setup"
[2]: https://github.com/diegosouzapw/OmniRoute/blob/release/v3.8.51/docs/guides/TERMUX_GUIDE.md "OmniRoute Termux Headless Setup"
[3]: https://github.com/Ishabdullah/claude-code-termux "Claude Code CLI for Termux"
