#!/bin/bash

set -euo pipefail

# Função para registrar logs
log_message() {
    if [[ "$LOG_FLAG" == "true" ]]; then
        local message="$1"
        local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
        echo "[$timestamp] $message" >> ~/.ai-cli-installer.log
    fi
}

# Função para imprimir mensagens em verde
print_success() {
    echo -e "\033[0;32m✓ $1\033[0m"
}

# Função para imprimir mensagens em amarelo
print_warning() {
    echo -e "\033[1;33m⚠ $1\033[0m"
}

# Função para imprimir mensagens em vermelho
print_error() {
    echo -e "\033[0;31m✗ $1\033[0m"
}

# Função para imprimir mensagens em azul
print_info() {
    echo -e "\033[0;34mℹ $1\033[0m"
}

# Função para imprimir mensagem de título
print_title() {
    echo -e "\n\033[1;36m### $1 ###\033[0m\n"
}

# Variáveis para flags
YES_FLAG=false
ONLY_CLIS_FLAG=false
SKIP_NODE_FLAG=false
SKIP_PYTHON_FLAG=false
DRY_RUN_FLAG=false
UPGRADE_FLAG=false
LOG_FLAG=false
PYTHON_CMD=""
VIBE_ATTEMPTED=false

# Função para mostrar ajuda
show_help() {
    cat << EOF
Instalador de ferramentas de IA

Uso: $0 [OPÇÕES]

Opções:
    --help          Mostra esta mensagem de ajuda
    --yes           Responde sim automaticamente a todas as confirmações
    --only-clis     Instala apenas as CLIs (não instala Node.js/Python)
    --skip-node     Pula a instalação do Node.js
    --skip-python   Pula a instalação do Python
    --dry-run       Mostra o que seria feito sem executar nada
    --upgrade       Atualiza CLIs de IA já instaladas
    --log           Cria log da instalação em ~/.ai-cli-installer.log

Exemplos:
    $0                      # Instala tudo com confirmação
    $0 --yes                # Instala tudo sem confirmação
    $0 --only-clis          # Instala apenas CLIs
    $0 --skip-node          # Instala tudo exceto Node.js
    $0 --dry-run            # Simula a instalação
    $0 --upgrade            # Atualiza CLIs existentes
    $0 --log                # Registra instalação em log
EOF
}

# Função para confirmar execução
confirm_execution() {
    if [[ "$YES_FLAG" == "true" ]]; then
        return 0
    fi

    print_warning "Este script irá instalar ferramentas de IA globalmente no seu sistema."
    read -p "Deseja continuar? (y/N): " -n 1 -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]]
}

# Verificar se o comando existe
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Selecionar comando Python preferencial
select_python_cmd() {
    if command_exists python; then
        PYTHON_CMD="python"
    elif command_exists python3; then
        PYTHON_CMD="python3"
    else
        PYTHON_CMD=""
    fi
}

# Garantir que um comando Python esteja disponível
require_python_cmd() {
    select_python_cmd
    if [[ -z "$PYTHON_CMD" ]]; then
        print_error "Nenhum comando Python encontrado (python ou python3). Instale o Python para continuar."
        exit 1
    fi
}

# Detectar sistema operacional
detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Verificar se é WSL
        if grep -qi microsoft /proc/version; then
            OS="wsl"
        else
            OS="linux"
        fi
    else
        print_error "Sistema operacional não suportado: $OSTYPE"
        exit 1
    fi
}

# Detectar gerenciador de pacotes
detect_package_manager() {
    if command_exists apt-get; then
        PACKAGE_MANAGER="apt"
    elif command_exists dnf; then
        PACKAGE_MANAGER="dnf"
    elif command_exists yum; then
        PACKAGE_MANAGER="yum"
    elif command_exists pacman; then
        PACKAGE_MANAGER="pacman"
    elif command_exists zypper; then
        PACKAGE_MANAGER="zypper"
    else
        PACKAGE_MANAGER="none"
    fi
}

# Instalar Homebrew (macOS) ou verificar pacotes (Linux/WSL)
setup_package_manager() {
    case "$OS" in
        macos)
            if ! command_exists brew; then
                print_info "Instalando Homebrew..."
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

                # Avaliar o ambiente do Homebrew sem modificar arquivos de shell automaticamente
                if [[ -f /opt/homebrew/bin/brew ]]; then
                    eval "$(/opt/homebrew/bin/brew shellenv)"
                elif [[ -f /usr/local/bin/brew ]]; then
                    eval "$(/usr/local/bin/brew shellenv)"
                fi
            fi
            ;;
        linux|wsl)
            detect_package_manager
            if [[ "$PACKAGE_MANAGER" == "none" ]]; then
                print_error "Nenhum gerenciador de pacotes suportado encontrado (apt, dnf, yum, pacman, zypper)."
                print_error "Por favor, instale Node.js e Python manualmente."
                exit 1
            fi

            print_info "Gerenciador de pacotes detectado: $PACKAGE_MANAGER"
            case "$PACKAGE_MANAGER" in
                apt)
                    sudo apt-get update
                    ;;
                dnf)
                    sudo dnf check-update || true
                    ;;
                yum)
                    sudo yum check-update || true
                    ;;
                pacman)
                    sudo pacman -Sy
                    ;;
                zypper)
                    sudo zypper refresh
                    ;;
            esac
            ;;
    esac
}

# Instalar Node.js e npm
install_nodejs() {
    if command_exists node && command_exists npm; then
        print_success "Node.js e npm já estão instalados."
        return
    fi

    case "$OS" in
        macos)
            print_info "Instalando Node.js e npm via Homebrew..."
            brew install node
            ;;
        linux|wsl)
            case "$PACKAGE_MANAGER" in
                apt)
                    print_info "Instalando Node.js e npm via apt..."
                    sudo apt-get install -y nodejs npm
                    ;;
                dnf)
                    print_info "Instalando Node.js e npm via dnf..."
                    sudo dnf install -y nodejs npm
                    ;;
                yum)
                    print_info "Instalando Node.js e npm via yum..."
                    sudo yum install -y nodejs npm
                    ;;
                pacman)
                    print_info "Instalando Node.js e npm via pacman..."
                    sudo pacman -S --noconfirm nodejs npm
                    ;;
                zypper)
                    print_info "Instalando Node.js e npm via zypper..."
                    sudo zypper install -y nodejs npm
                    ;;
            esac
            ;;
    esac

    if command_exists node && command_exists npm; then
        print_success "Node.js e npm instalados com sucesso."
    else
        print_error "Falha ao instalar Node.js e npm."
        exit 1
    fi
}

# Instalar Python e pip
install_python() {
    if command_exists python3 && command_exists pip3; then
        print_success "Python 3 e pip já estão instalados."
        return
    fi

    if command_exists python && command_exists pip; then
        print_success "Python e pip já estão instalados."
        return
    fi

    case "$OS" in
        macos)
            print_info "Instalando Python 3 via Homebrew..."
            brew install python3
            ;;
        linux|wsl)
            case "$PACKAGE_MANAGER" in
                apt)
                    print_info "Instalando Python 3 e pip via apt..."
                    sudo apt-get install -y python3 python3-pip
                    ;;
                dnf)
                    print_info "Instalando Python 3 e pip via dnf..."
                    sudo dnf install -y python3 python3-pip
                    ;;
                yum)
                    print_info "Instalando Python 3 e pip via yum..."
                    sudo yum install -y python3 python3-pip
                    ;;
                pacman)
                    print_info "Instalando Python 3 e pip via pacman..."
                    sudo pacman -S --noconfirm python python-pip
                    ;;
                zypper)
                    print_info "Instalando Python 3 e pip via zypper..."
                    sudo zypper install -y python3 python3-pip
                    ;;
            esac
            ;;
    esac

    if command_exists python3 && command_exists pip3; then
        print_success "Python 3 e pip instalados com sucesso."
    elif command_exists python && command_exists pip; then
        print_success "Python e pip instalados com sucesso."
    else
        print_error "Falha ao instalar Python e pip."
        exit 1
    fi
}

# Instalar CLIs de IA
install_ai_tools() {
    log_message "Iniciando instalação/atualização de ferramentas de IA"

    print_title "INSTALANDO FERRAMENTAS DE IA"

    # Instalar/atualizar Google Gemini CLI
    if command_exists gemini && [[ "$UPGRADE_FLAG" == "true" ]]; then
        print_info "Atualizando Google Gemini CLI..."
        if [[ "$DRY_RUN_FLAG" != "true" ]]; then
            npm install -g @google/gemini-cli
            log_message "Google Gemini CLI atualizado"
        else
            print_info "(dry-run) npm install -g @google/gemini-cli"
            log_message "(dry-run) Google Gemini CLI atualizado"
        fi
        print_success "Google Gemini CLI atualizado."
    elif ! command_exists gemini; then
        print_info "Instalando Google Gemini CLI..."
        if [[ "$DRY_RUN_FLAG" != "true" ]]; then
            npm install -g @google/gemini-cli
            log_message "Google Gemini CLI instalado"
        else
            print_info "(dry-run) npm install -g @google/gemini-cli"
            log_message "(dry-run) Google Gemini CLI instalado"
        fi
        print_success "Google Gemini CLI instalado."
    else
        print_info "Google Gemini CLI já está instalado e --upgrade não foi especificado."
        log_message "Google Gemini CLI já está instalado e --upgrade não foi especificado"
    fi

    # Instalar/atualizar Qwen Code
    if command_exists qwen && [[ "$UPGRADE_FLAG" == "true" ]]; then
        print_info "Atualizando Qwen Code..."
        if [[ "$DRY_RUN_FLAG" != "true" ]]; then
            npm install -g @qwen-code/qwen-code
            log_message "Qwen Code atualizado"
        else
            print_info "(dry-run) npm install -g @qwen-code/qwen-code"
            log_message "(dry-run) Qwen Code atualizado"
        fi
        print_success "Qwen Code atualizado."
    elif ! command_exists qwen; then
        print_info "Instalando Qwen Code..."
        if [[ "$DRY_RUN_FLAG" != "true" ]]; then
            npm install -g @qwen-code/qwen-code
            log_message "Qwen Code instalado"
        else
            print_info "(dry-run) npm install -g @qwen-code/qwen-code"
            log_message "(dry-run) Qwen Code instalado"
        fi
        print_success "Qwen Code instalado."
    else
        print_info "Qwen Code já está instalado e --upgrade não foi especificado."
        log_message "Qwen Code já está instalado e --upgrade não foi especificado"
    fi

    # Instalar/atualizar OpenAI Codex CLI
    if command_exists codex && [[ "$UPGRADE_FLAG" == "true" ]]; then
        print_info "Atualizando OpenAI Codex CLI..."
        if [[ "$DRY_RUN_FLAG" != "true" ]]; then
            npm install -g @openai/codex
            log_message "OpenAI Codex CLI atualizado"
        else
            print_info "(dry-run) npm install -g @openai/codex"
            log_message "(dry-run) OpenAI Codex CLI atualizado"
        fi
        print_success "OpenAI Codex CLI atualizado."
    elif ! command_exists codex; then
        print_info "Instalando OpenAI Codex CLI..."
        if [[ "$DRY_RUN_FLAG" != "true" ]]; then
            npm install -g @openai/codex
            log_message "OpenAI Codex CLI instalado"
        else
            print_info "(dry-run) npm install -g @openai/codex"
            log_message "(dry-run) OpenAI Codex CLI instalado"
        fi
        print_success "OpenAI Codex CLI instalado."
    else
        print_info "OpenAI Codex CLI já está instalado e --upgrade não foi especificado."
        log_message "OpenAI Codex CLI já está instalado e --upgrade não foi especificado"
    fi

    # Instalar/atualizar Mistral Vibe
    if command_exists vibe && [[ "$UPGRADE_FLAG" == "true" ]]; then
        require_python_cmd
        VIBE_ATTEMPTED=true
        print_info "Atualizando Mistral Vibe..."
        if [[ "$DRY_RUN_FLAG" != "true" ]]; then
            "${PYTHON_CMD}" -m pip install --upgrade mistral-vibe
            log_message "Mistral Vibe atualizado"
        else
            print_info "(dry-run) ${PYTHON_CMD} -m pip install --upgrade mistral-vibe"
            log_message "(dry-run) Mistral Vibe atualizado"
        fi
        print_success "Mistral Vibe atualizado."
    elif ! command_exists vibe; then
        require_python_cmd
        VIBE_ATTEMPTED=true
        print_info "Instalando Mistral Vibe..."
        if [[ "$DRY_RUN_FLAG" != "true" ]]; then
            "${PYTHON_CMD}" -m pip install mistral-vibe
            log_message "Mistral Vibe instalado"
        else
            print_info "(dry-run) ${PYTHON_CMD} -m pip install mistral-vibe"
            log_message "(dry-run) Mistral Vibe instalado"
        fi
        print_success "Mistral Vibe instalado."
    else
        print_info "Mistral Vibe já está instalado e --upgrade não foi especificado."
        log_message "Mistral Vibe já está instalado e --upgrade não foi especificado"
    fi

    log_message "Instalação/atualização de ferramentas de IA concluída"
}

# Função para diagnóstico inicial
diagnostic() {
    log_message "Iniciando diagnóstico inicial"

    print_title "DIAGNÓSTICO INICIAL"

    print_info "Sistema operacional detectado: $OS"
    log_message "Sistema operacional detectado: $OS"

    if command_exists node; then
        NODE_VERSION=$(node --version)
        print_info "Node.js: instalado ($NODE_VERSION)"
        log_message "Node.js: instalado ($NODE_VERSION)"
    else
        print_info "Node.js: ausente"
        log_message "Node.js: ausente"
    fi

    if command_exists npm; then
        print_info "npm: disponível"
        log_message "npm: disponível"
    else
        print_info "npm: não disponível"
        log_message "npm: não disponível"
    fi

    select_python_cmd
    if [[ -n "$PYTHON_CMD" ]]; then
        PYTHON_VERSION=$("${PYTHON_CMD}" --version)
        print_info "Python: instalado (${PYTHON_CMD}, $PYTHON_VERSION)"
        log_message "Python: instalado (${PYTHON_CMD}, $PYTHON_VERSION)"
    else
        print_info "Python: ausente"
        log_message "Python: ausente"
    fi

    if command_exists pip3 || command_exists pip; then
        print_info "pip: disponível"
        log_message "pip: disponível"
    else
        print_info "pip: não disponível"
        log_message "pip: não disponível"
    fi

    # Verificar CLIs existentes
    if command_exists gemini; then
        print_info "gemini: instalado"
        log_message "gemini: instalado"
        if [[ "$UPGRADE_FLAG" == "true" ]]; then
            print_info "gemini: será atualizado (--upgrade)"
            log_message "gemini: será atualizado (--upgrade)"
        else
            print_info "gemini: será pulado (use --upgrade para atualizar)"
            log_message "gemini: será pulado (use --upgrade para atualizar)"
        fi
    else
        print_info "gemini: ausente"
        log_message "gemini: ausente"
        print_info "gemini: será instalado"
        log_message "gemini: será instalado"
    fi

    if command_exists qwen; then
        print_info "qwen: instalado"
        log_message "qwen: instalado"
        if [[ "$UPGRADE_FLAG" == "true" ]]; then
            print_info "qwen: será atualizado (--upgrade)"
            log_message "qwen: será atualizado (--upgrade)"
        else
            print_info "qwen: será pulado (use --upgrade para atualizar)"
            log_message "qwen: será pulado (use --upgrade para atualizar)"
        fi
    else
        print_info "qwen: ausente"
        log_message "qwen: ausente"
        print_info "qwen: será instalado"
        log_message "qwen: será instalado"
    fi

    if command_exists codex; then
        print_info "codex: instalado"
        log_message "codex: instalado"
        if [[ "$UPGRADE_FLAG" == "true" ]]; then
            print_info "codex: será atualizado (--upgrade)"
            log_message "codex: será atualizado (--upgrade)"
        else
            print_info "codex: será pulado (use --upgrade para atualizar)"
            log_message "codex: será pulado (use --upgrade para atualizar)"
        fi
    else
        print_info "codex: ausente"
        log_message "codex: ausente"
        print_info "codex: será instalado"
        log_message "codex: será instalado"
    fi

    if command_exists vibe; then
        print_info "vibe: instalado"
        log_message "vibe: instalado"
        if [[ "$UPGRADE_FLAG" == "true" ]]; then
            print_info "vibe: será atualizado (--upgrade)"
            log_message "vibe: será atualizado (--upgrade)"
        else
            print_info "vibe: será pulado (use --upgrade para atualizar)"
            log_message "vibe: será pulado (use --upgrade para atualizar)"
        fi
    else
        print_info "vibe: ausente"
        log_message "vibe: ausente"
        print_info "vibe: será instalado"
        log_message "vibe: será instalado"
    fi

    print_title "O QUE SERÁ INSTALADO"
    log_message "Iniciando análise do que será instalado"

    if [[ "$ONLY_CLIS_FLAG" == "true" ]]; then
        print_info "Apenas CLIs de IA (modo --only-clis)"
        log_message "Apenas CLIs de IA (modo --only-clis)"
    else
        if [[ "$SKIP_NODE_FLAG" == "false" ]] && ! command_exists node; then
            print_info "Node.js (porque está ausente e --skip-node não foi usado)"
            log_message "Node.js (porque está ausente e --skip-node não foi usado)"
        elif [[ "$SKIP_NODE_FLAG" == "true" ]]; then
            print_info "Node.js (será pulado por --skip-node)"
            log_message "Node.js (será pulado por --skip-node)"
        else
            print_info "Node.js (já está instalado)"
            log_message "Node.js (já está instalado)"
        fi

        if [[ "$SKIP_PYTHON_FLAG" == "false" ]] && ! (command_exists python3 || command_exists python); then
            print_info "Python (porque está ausente e --skip-python não foi usado)"
            log_message "Python (porque está ausente e --skip-python não foi usado)"
        elif [[ "$SKIP_PYTHON_FLAG" == "true" ]]; then
            print_info "Python (será pulado por --skip-python)"
            log_message "Python (será pulado por --skip-python)"
        else
            print_info "Python (já está instalado)"
            log_message "Python (já está instalado)"
        fi
    fi

    if command_exists gemini && [[ "$UPGRADE_FLAG" != "true" ]]; then
        print_info "Google Gemini CLI (já instalado, use --upgrade para atualizar)"
        log_message "Google Gemini CLI (já instalado, use --upgrade para atualizar)"
    else
        print_info "Google Gemini CLI"
        log_message "Google Gemini CLI"
    fi

    if command_exists qwen && [[ "$UPGRADE_FLAG" != "true" ]]; then
        print_info "Qwen Code (já instalado, use --upgrade para atualizar)"
        log_message "Qwen Code (já instalado, use --upgrade para atualizar)"
    else
        print_info "Qwen Code"
        log_message "Qwen Code"
    fi

    if command_exists codex && [[ "$UPGRADE_FLAG" != "true" ]]; then
        print_info "OpenAI Codex CLI (já instalado, use --upgrade para atualizar)"
        log_message "OpenAI Codex CLI (já instalado, use --upgrade para atualizar)"
    else
        print_info "OpenAI Codex CLI"
        log_message "OpenAI Codex CLI"
    fi

    if command_exists vibe && [[ "$UPGRADE_FLAG" != "true" ]]; then
        print_info "Mistral Vibe (já instalado, use --upgrade para atualizar)"
        log_message "Mistral Vibe (já instalado, use --upgrade para atualizar)"
    else
        print_info "Mistral Vibe"
        log_message "Mistral Vibe"
    fi

    if [[ "$DRY_RUN_FLAG" == "true" ]]; then
        print_warning "Modo --dry-run ativado. Nenhuma instalação será realizada."
        log_message "Modo --dry-run ativado. Nenhuma instalação será realizada."
        return
    fi

    log_message "Diagnóstico inicial concluído"
}

# Função principal
main() {
    print_title "INSTALADOR DE FERRAMENTAS DE IA"

    # Parse de argumentos
    while [[ $# -gt 0 ]]; do
        case $1 in
            --help)
                show_help
                exit 0
                ;;
            --yes)
                YES_FLAG=true
                shift
                ;;
            --only-clis)
                ONLY_CLIS_FLAG=true
                SKIP_NODE_FLAG=true
                SKIP_PYTHON_FLAG=true
                shift
                ;;
            --skip-node)
                SKIP_NODE_FLAG=true
                shift
                ;;
            --skip-python)
                SKIP_PYTHON_FLAG=true
                shift
                ;;
            --dry-run)
                DRY_RUN_FLAG=true
                shift
                ;;
            --upgrade)
                UPGRADE_FLAG=true
                shift
                ;;
            --log)
                LOG_FLAG=true
                shift
                ;;
            *)
                print_error "Argumento desconhecido: $1"
                exit 1
                ;;
        esac
    done

    detect_os
    diagnostic

    if [[ "$DRY_RUN_FLAG" == "true" ]]; then
        print_info "Encerrando (modo --dry-run)."
        exit 0
    fi

    if ! confirm_execution; then
        print_warning "Operação cancelada pelo usuário."
        exit 0
    fi

    setup_package_manager

    if [[ "$SKIP_NODE_FLAG" == "false" ]]; then
        install_nodejs
    else
        print_info "Pulando instalação do Node.js (--skip-node)."
    fi

    if [[ "$SKIP_PYTHON_FLAG" == "false" ]]; then
        install_python
    else
        print_info "Pulando instalação do Python (--skip-python)."
    fi

    install_ai_tools

    print_title "INSTALAÇÃO CONCLUÍDA"
    print_success "Todas as ferramentas de IA foram instaladas com sucesso!"
    print_info "Abra um novo terminal para garantir que o PATH esteja atualizado."
    if [[ "$OS" == "macos" ]] && [[ "$DRY_RUN_FLAG" != "true" ]] && [[ "$VIBE_ATTEMPTED" == "true" ]] && ! command_exists vibe; then
        SCRIPTS_DIR=$("${PYTHON_CMD}" -c 'import sysconfig; print(sysconfig.get_path("scripts"))' 2>/dev/null || true)
        print_warning "Se o comando 'vibe' não for encontrado, o diretório de scripts do Python pode não estar no PATH. Reabra o terminal."
        if [[ -n "$SCRIPTS_DIR" ]]; then
            print_info "Dica: verifique se este caminho está no PATH: $SCRIPTS_DIR"
        fi
    fi
}

# Captura de erros
trap 'print_error "Erro na linha $LINENO. Comando: $BASH_COMMAND"; exit 1' ERR

# Executar função principal com todos os argumentos
main "$@"
