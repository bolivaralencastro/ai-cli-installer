# Instalador de Ferramentas de IA

Este repositório contém scripts para instalar globalmente ferramentas de inteligência artificial no seu sistema. Os scripts configuram automaticamente o ambiente necessário (Node.js e Python) e instalam as seguintes ferramentas:

- **Google Gemini CLI**: Interface de linha de comando para o Google Gemini
- **Qwen Code**: Assistente de IA para desenvolvimento de código
- **OpenAI Codex CLI**: Interface de linha de comando para o OpenAI Codex
- **Mistral Vibe**: Ferramenta de IA da Mistral

## Instalação

Execute o comando correspondente ao seu sistema operacional:

### macOS / Linux / WSL

```bash
curl -fsSL https://github.com/bolivaralencastro/ai-cli-installer/releases/download/v3.0.0/install.sh | bash -s -- --yes
```

### Windows PowerShell

```powershell
iwr -useb https://github.com/bolivaralencastro/ai-cli-installer/releases/download/v3.0.0/install.ps1 | iex
```

## O que este script faz

O instalador executa as seguintes etapas:

1. Detecta automaticamente o sistema operacional
2. Verifica se Node.js e Python já estão instalados
3. Instala Node.js e Python automaticamente se ausentes
4. Instala globalmente as CLIs de IA listadas acima
5. Exibe instruções para recarregar o ambiente

## Opções Avançadas

O script suporta várias opções para controle avançado:

### Flags Disponíveis

- `--help`: Mostra a ajuda com todas as opções
- `--yes`: Responde automaticamente sim a todas as confirmações
- `--only-clis`: Instala apenas as CLIs (ignora Node.js e Python)
- `--skip-node`: Pula a instalação do Node.js
- `--skip-python`: Pula a instalação do Python
- `--dry-run`: Mostra o que seria feito sem executar nada
- `--upgrade`: Atualiza CLIs de IA já instaladas
- `--log`: Cria log da instalação em ~/.ai-cli-installer.log

### Exemplos de Uso

macOS / Linux / WSL:

Instalacao padrao (sem interacao):
```bash
curl -fsSL https://github.com/bolivaralencastro/ai-cli-installer/releases/download/v3.0.0/install.sh | bash -s -- --yes
```

Instalacao automatica sem confirmacao (equivalente ao padrao):
```bash
curl -fsSL https://github.com/bolivaralencastro/ai-cli-installer/releases/download/v3.0.0/install.sh | bash -s -- --yes
```

Instalacao apenas das CLIs (sem Node.js/Python):
```bash
curl -fsSL https://github.com/bolivaralencastro/ai-cli-installer/releases/download/v3.0.0/install.sh | bash -s -- --only-clis
```

Simular instalacao (modo dry-run):
```bash
curl -fsSL https://github.com/bolivaralencastro/ai-cli-installer/releases/download/v3.0.0/install.sh | bash -s -- --dry-run
```

Atualizar CLIs existentes:
```bash
curl -fsSL https://github.com/bolivaralencastro/ai-cli-installer/releases/download/v3.0.0/install.sh | bash -s -- --upgrade
```

Registrar instalacao em log:
```bash
curl -fsSL https://github.com/bolivaralencastro/ai-cli-installer/releases/download/v3.0.0/install.sh | bash -s -- --log
```

Windows PowerShell:

Instalacao padrao (sem interacao):
```powershell
iwr -useb https://github.com/bolivaralencastro/ai-cli-installer/releases/download/v3.0.0/install.ps1 | iex
```

Instalacao automatica sem confirmacao (equivalente ao padrao):
```powershell
iwr -useb https://github.com/bolivaralencastro/ai-cli-installer/releases/download/v3.0.0/install.ps1 | iex
```

Instalacao apenas das CLIs (sem Node.js/Python):
```powershell
iwr -useb https://github.com/bolivaralencastro/ai-cli-installer/releases/download/v3.0.0/install.ps1 | iex -ArgumentList '-OnlyClis'
```

Simular instalacao (modo dry-run):
```powershell
iwr -useb https://github.com/bolivaralencastro/ai-cli-installer/releases/download/v3.0.0/install.ps1 | iex -ArgumentList '-DryRun'
```

Atualizar CLIs existentes:
```powershell
iwr -useb https://github.com/bolivaralencastro/ai-cli-installer/releases/download/v3.0.0/install.ps1 | iex -ArgumentList '-Upgrade'
```

Registrar instalacao em log:
```powershell
iwr -useb https://github.com/bolivaralencastro/ai-cli-installer/releases/download/v3.0.0/install.ps1 | iex -ArgumentList '-Log'
```

Para confirmação interativa, baixe o script e execute localmente (o prompt não funciona via pipe).

## Suporte a Múltiplas Distros Linux

O script detecta automaticamente o gerenciador de pacotes do seu sistema e instala as dependências necessárias:

- Debian/Ubuntu/WSL: `apt`
- Fedora/RHEL: `dnf`
- CentOS: `yum`
- Arch: `pacman`
- openSUSE: `zypper`

Se o seu sistema não for suportado, você será orientado a instalar Node.js e Python manualmente.

## Scripts de Desinstalação

Para remover apenas as CLIs de IA instaladas (sem remover Node.js ou Python), utilize os scripts de desinstalação:

### macOS / Linux / WSL

```bash
curl -fsSL https://github.com/bolivaralencastro/ai-cli-installer/releases/download/v3.0.0/uninstall.sh | bash
```

### Windows PowerShell

```powershell
iwr -useb https://github.com/bolivaralencastro/ai-cli-installer/releases/download/v3.0.0/uninstall.ps1 | iex
```

## Segurança e Supply Chain

O fluxo de 1 comando (`curl | bash` ou `iwr | iex`) é prático, mas exige confiança total na origem do script. Para reduzir riscos de supply chain, usamos links para releases específicos (imutáveis) em vez da branch `main`, o que evita mudanças inesperadas após a publicação.

As CLIs são instaladas via `npm` e `pip` usando pacotes oficiais, porém essas instalações seguem os registries públicos (npm/PyPI). Em caso de comprometimento no registry, o risco existe. Por isso, recomendamos que usuários mais cautelosos baixem o script localmente e verifiquem o checksum antes de executar.

## Modo seguro alternativo (recomendado)

Uma opção mais segura é baixar o script, validar o checksum e executar localmente:

## Integridade e Segurança

Para verificar a integridade do script de instalação, você pode comparar o checksum SHA-256:

```bash
shasum -a 256 scripts/install.sh
```

Compare o resultado com o valor armazenado em `scripts/install.sh.sha256`.

Para uma verificação mais segura, você pode baixar o script localmente, validar o checksum e então executá-lo:

```bash
# Baixar os arquivos do release
curl -fsSL https://github.com/bolivaralencastro/ai-cli-installer/releases/download/v3.0.0/install.sh -o install.sh
curl -fsSL https://github.com/bolivaralencastro/ai-cli-installer/releases/download/v3.0.0/install.sh.sha256 -o install.sh.sha256

# Verificar o checksum
shasum -a 256 install.sh | grep -F -f install.sh.sha256

# Se a verificação for bem-sucedida, executar o script
bash install.sh
```

## Segurança

Por segurança, recomendamos revisar os scripts antes de executá-los:

- [Script de instalação para Unix](https://github.com/bolivaralencastro/ai-cli-installer/blob/v3.0.0/scripts/install.sh)
- [Script de instalação para Windows](https://github.com/bolivaralencastro/ai-cli-installer/blob/v3.0.0/scripts/install.ps1)

## Teste Rápido

Após a instalação, você pode testar as ferramentas executando os seguintes comandos:

```bash
gemini
qwen
codex
vibe
```

## Testes Locais (Modo Seguro)

Para validar o fluxo do script sem alterar o sistema, utilize o modo `--dry-run` e a ajuda:

```bash
bash scripts/install.sh --help
bash scripts/install.sh --dry-run
bash scripts/install.sh --dry-run --only-clis
bash scripts/install.sh --dry-run --skip-node
bash scripts/install.sh --dry-run --skip-python
bash scripts/install.sh --dry-run --upgrade
bash scripts/uninstall.sh --help
```
