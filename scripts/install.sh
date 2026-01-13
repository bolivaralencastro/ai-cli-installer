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

# Funções de formatação e cores
print_success() { echo -e "\033[0;32m✓ $1\033[0m"; }
print_warning() { echo -e "\033[1;33m⚠ $1\033[0m"; }
print_error() { echo -e "\033[0;31m✗ $1\033[0m"; }
print_info() { echo -e "\033[0;34mℹ $1\033[0m"; }
print_title() { echo -e "\n\033[1;36m### $1 ###\033[0m"; }

# Variáveis para flags
YES_FLAG=false
ONLY_CLIS_FLAG=false
SKIP_NODE_FLAG=false
SKIP_PYTHON_FLAG=false
DRY_RUN_FLAG=false
UPGRADE_FLAG=false
LOG_FLAG=false

# Variáveis de Estado
PYTHON_CMD=""
CLI_STATUS=""
CLI_VERSION_OUTPUT=""
OS=""
PACKAGE_MANAGER=""

# Estado das Ferramentas
GEMINI_STATE="missing"
QWEN_STATE="missing"
CODEX_STATE="missing"
VIBE_STATE="missing"

# Ações Planejadas
NODE_ACTION="none"
PYTHON_ACTION="none"
GEMINI_ACTION="none"
QWEN_ACTION="none"
CODEX_ACTION="none"
VIBE_ACTION="none"

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
    $0 --upgrade            # Atualiza CLIs existentes
EOF
}

# Verificar se o comando existe
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Verificar status da CLI (instalada, ausente ou quebrada) e extrair versão
check_cli_status() {
    local cmd="$1"
    local version_arg="${2:---version}"
    CLI_STATUS="missing"
    CLI_VERSION_OUTPUT=""

    if command_exists "$cmd"; then
        local output
        # Redireciona stderr para stdout para capturar erro se houver
        if output=$("$cmd" $version_arg 2>&1); then
            CLI_STATUS="installed"
            # Tenta extrair padrao X.Y.Z
            if [[ "$output" =~ ([0-9]+\.[0-9]+\.[0-9]+) ]]; then
                CLI_VERSION_OUTPUT="v${BASH_REMATCH[1]}"
            else
                # Fallback, usa a primeira linha ou "unknown"
                CLI_VERSION_OUTPUT=$(echo "$output" | head -n 1)
            fi
        else
            CLI_STATUS="broken"
            CLI_VERSION_OUTPUT="Erro na execução"
        fi
    fi
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

require_python_cmd() {
    select_python_cmd
    if [[ -z "$PYTHON_CMD" ]]; then
        print_error "Nenhum comando Python encontrado."
        exit 1
    fi
}

detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
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

diagnostic_system() {
    print_title "DIAGNÓSTICO DO SISTEMA"
    echo "✔ OS: $OS"
    
    if command_exists node; then
        local nv=$(node --version)
        echo "✔ Node.js: $nv (Detectado)"
        NODE_STATE="installed"
    else
        echo "• Node.js: Ausente"
        NODE_STATE="missing"
    fi

    select_python_cmd
    if [[ -n "$PYTHON_CMD" ]]; then
        local pv=$("${PYTHON_CMD}" --version 2>&1 | head -n 1)
        echo "✔ Python: $pv (Detectado)"
        PYTHON_STATE="installed"
    else
        echo "• Python: Ausente"
        PYTHON_STATE="missing"
    fi

    echo ""
    echo "### STATUS DAS FERRAMENTAS CI ###"

    # Gemini
    check_cli_status "gemini"
    GEMINI_STATE="$CLI_STATUS"
    GEMINI_VER="$CLI_VERSION_OUTPUT"
    print_tool_status "gemini" "$GEMINI_STATE" "$GEMINI_VER"

    # Qwen
    check_cli_status "qwen"
    QWEN_STATE="$CLI_STATUS"
    QWEN_VER="$CLI_VERSION_OUTPUT"
    print_tool_status "qwen" "$QWEN_STATE" "$QWEN_VER"

    # Codex
    check_cli_status "codex"
    CODEX_STATE="$CLI_STATUS"
    CODEX_VER="$CLI_VERSION_OUTPUT"
    print_tool_status "codex" "$CODEX_STATE" "$CODEX_VER"

    # Vibe
    check_cli_status "vibe"
    VIBE_STATE="$CLI_STATUS"
    VIBE_VER="$CLI_VERSION_OUTPUT"
    print_tool_status "vibe" "$VIBE_STATE" "$VIBE_VER"
}

print_tool_status() {
    local name="$1"
    local status="$2"
    local ver="$3"
    
    case "$status" in
        "installed")
            echo -e "\033[0;32m✔ $name:\t $ver (Instalado)\033[0m"
            ;;
        "missing")
            echo -e "• $name:\t Ausente"
            ;;
        "broken")
            echo -e "\033[0;31m✖ $name:\t QUEBRADO (Binário existe, mas falha ao executar)\033[0m"
            ;;
    esac
}

plan_actions() {
    print_title "PLANO DE EXECUÇÃO"
    local count=0

    # Node
    if [[ "$ONLY_CLIS_FLAG" == "false" ]]; then
        if [[ "$NODE_STATE" == "missing" ]] && [[ "$SKIP_NODE_FLAG" == "false" ]]; then
            NODE_ACTION="install"
            ((count++))
        fi
    fi

    # Python
    if [[ "$ONLY_CLIS_FLAG" == "false" ]]; then
        if [[ "$PYTHON_STATE" == "missing" ]] && [[ "$SKIP_PYTHON_FLAG" == "false" ]]; then
            PYTHON_ACTION="install"
            ((count++))
        fi
    fi

    # Tools Logic
    # Se broken -> repair (reinstall)
    # Se missing -> install
    # Se installed -> upgrade (se flag) ou skip

    # Gemini
    if [[ "$GEMINI_STATE" == "missing" ]]; then
        GEMINI_ACTION="install"
        ((count++))
    elif [[ "$GEMINI_STATE" == "broken" ]]; then
        GEMINI_ACTION="repair"
        ((count++))
    elif [[ "$GEMINI_STATE" == "installed" ]] && [[ "$UPGRADE_FLAG" == "true" ]]; then
        GEMINI_ACTION="update"
        ((count++))
    fi

    # Qwen
    if [[ "$QWEN_STATE" == "missing" ]]; then
        QWEN_ACTION="install"
        ((count++))
    elif [[ "$QWEN_STATE" == "broken" ]]; then
        QWEN_ACTION="repair"
        ((count++))
    elif [[ "$QWEN_STATE" == "installed" ]] && [[ "$UPGRADE_FLAG" == "true" ]]; then
        QWEN_ACTION="update"
        ((count++))
    fi

    # Codex
    if [[ "$CODEX_STATE" == "missing" ]]; then
        CODEX_ACTION="install"
        ((count++))
    elif [[ "$CODEX_STATE" == "broken" ]]; then
        CODEX_ACTION="repair"
        ((count++))
    elif [[ "$CODEX_STATE" == "installed" ]] && [[ "$UPGRADE_FLAG" == "true" ]]; then
        CODEX_ACTION="update"
        ((count++))
    fi

    # Vibe
    if [[ "$VIBE_STATE" == "missing" ]]; then
        VIBE_ACTION="install"
        ((count++))
    elif [[ "$VIBE_STATE" == "broken" ]]; then
        VIBE_ACTION="repair"
        ((count++))
    elif [[ "$VIBE_STATE" == "installed" ]] && [[ "$UPGRADE_FLAG" == "true" ]]; then
        VIBE_ACTION="update"
        ((count++))
    fi

    if [[ "$count" -eq 0 ]]; then
        echo "Todas as ferramentas já estão instaladas."
        echo "Nenhuma ação necessária."
        if [[ "$UPGRADE_FLAG" != "true" ]]; then
            echo ""
            print_info "Dica: Para atualizar, veja a seção 'Atualizar' no README em:"
            echo -e "\033[4;34mhttps://github.com/bolivaralencastro/ai-cli-installer#atualizar-clis-existentes\033[0m"
        fi
        exit 0
    fi

    echo "Serão realizadas as seguintes ações:"
    [[ "$NODE_ACTION" == "install" ]] && echo "  + Instalar Node.js e npm"
    [[ "$PYTHON_ACTION" == "install" ]] && echo "  + Instalar Python"
    
    print_action_plan "Google Gemini" "$GEMINI_ACTION"
    print_action_plan "Qwen Code" "$QWEN_ACTION"
    print_action_plan "OpenAI Codex" "$CODEX_ACTION"
    print_action_plan "Mistral Vibe" "$VIBE_ACTION"

    echo ""
}

print_action_plan() {
    local name="$1"
    local action="$2"
    case "$action" in
        "install") echo "  + Instalar $name" ;;
        "update")  echo "  ↑ Atualizar $name" ;;
        "repair")  echo "  ! REPARAR $name (Reinstalação forçada)" ;;
        "none")    ;; # Não mostrar nada
    esac
}

confirm_execution() {
    if [[ "$YES_FLAG" == "true" ]] || [[ "$DRY_RUN_FLAG" == "true" ]]; then
        return 0
    fi
    echo -n "[?] Deseja prosseguir? (S/n): "
    read -r REPLY
    echo ""
    [[ "$REPLY" =~ ^[SsYy]?$ ]] # Default yes se enter
}

# Wrapper para executar comandos silenciosamente, mostrando erro se falhar
run_quietly() {
    local desc="$1"
    local cmd="$2"
    
    echo -n "$desc... "
    if [[ "$DRY_RUN_FLAG" == "true" ]]; then
        echo "✔ (Simulado)"
        log_message "(dry-run) $cmd"
        return 0
    fi

    # Arquivo temporário para stderr
    local err_file
    err_file=$(mktemp)

    if eval "$cmd" >/dev/null 2>"$err_file"; then
        echo -e "\033[0;32m✔ Concluído\033[0m"
        log_message "Sucesso: $cmd"
        rm "$err_file"
    else
        echo -e "\033[0;31m✖ Falhou\033[0m"
        log_message "Erro: $cmd"
        cat "$err_file" >> ~/.ai-cli-installer.log
        echo "--- Detalhes do erro ---"
        tail -n 10 "$err_file"
        rm "$err_file"
        return 1
    fi
}

check_npm_permissions() {
    # Se npm existe e não é do brew (ou estamos linux), avisar sobre sudo
    if command_exists npm; then
        local npm_path=$(command -v npm)
        if [[ "$npm_path" != *"/homebrew/"* ]] && [[ "$npm_path" != *"/Cellar/"* ]] && [[ "$OS" != "windows" ]]; then
            # Teste rápido de escrita
            if ! touch "$(npm root -g)/.test_write" 2>/dev/null; then
                 print_warning "Node.js detectado em local protegido ($npm_path)."
                 echo "Provavelmente será necessário senha de administrador (sudo) para instalar pacotes globais."
                 echo "Caso falhe, tente rodar o script com 'sudo'."
                 # Apenas um aviso, deixamos o npm falhar ou pedir senha se configurado
            else
                rm "$(npm root -g)/.test_write"
            fi
        fi
    fi
}

execute_all() {
    print_title "EXECUTANDO"

    # Preparar package manager para node/python se necessário
    if [[ "$NODE_ACTION" == "install" ]] || [[ "$PYTHON_ACTION" == "install" ]]; then
        # Detect PM
        detect_package_manager_logic
        setup_package_manager
    fi

    if [[ "$NODE_ACTION" == "install" ]]; then
        install_nodejs
    fi
    if [[ "$PYTHON_ACTION" == "install" ]]; then
        install_python
    fi

    # Ferramentas IA
    check_npm_permissions
    
    if [[ "$GEMINI_ACTION" != "none" ]]; then
        run_quietly "Instalando/Atualizando Google Gemini" "npm install -g @google/gemini-cli"
    fi

    if [[ "$QWEN_ACTION" != "none" ]]; then
        run_quietly "Instalando/Atualizando Qwen Code" "npm install -g @qwen-code/qwen-code"
    fi

    if [[ "$CODEX_ACTION" != "none" ]]; then
        run_quietly "Instalando/Atualizando OpenAI Codex" "npm install -g @openai/codex"
    fi

    if [[ "$VIBE_ACTION" != "none" ]]; then
        require_python_cmd
        local pip_cmd="${PYTHON_CMD} -m pip install"
        [[ "$VIBE_ACTION" == "update" ]] && pip_cmd="$pip_cmd --upgrade"
        pip_cmd="$pip_cmd mistral-vibe"
        run_quietly "Instalando/Atualizando Mistral Vibe" "$pip_cmd"
    fi
}

# Funções auxiliares (copy-paste da logica antiga mas adaptada)
detect_package_manager_logic() {
    if command_exists apt-get; then PACKAGE_MANAGER="apt"
    elif command_exists dnf; then PACKAGE_MANAGER="dnf"
    elif command_exists yum; then PACKAGE_MANAGER="yum"
    elif command_exists pacman; then PACKAGE_MANAGER="pacman"
    elif command_exists zypper; then PACKAGE_MANAGER="zypper"
    else PACKAGE_MANAGER="none"; fi
}

setup_package_manager() {
    case "$OS" in
        macos)
            if ! command_exists brew; then
                run_quietly "Instalando Homebrew" '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
                if [[ -f /opt/homebrew/bin/brew ]]; then eval "$(/opt/homebrew/bin/brew shellenv)"; fi
                if [[ -f /usr/local/bin/brew ]]; then eval "$(/usr/local/bin/brew shellenv)"; fi
            fi
            ;;
        linux|wsl)
            if [[ "$PACKAGE_MANAGER" == "none" ]]; then
                print_error "Gerenciador de pacotes não suportado."
                exit 1
            fi
            # Updates
            case "$PACKAGE_MANAGER" in
                apt) run_quietly "Atualizando apt" "sudo apt-get update" ;;
                pacman) run_quietly "Atualizando pacman" "sudo pacman -Sy" ;;
                # outros geralmente nao precisam de refresh explicito aqui ou ja incluso
            esac
            ;;
    esac
}

install_nodejs() {
    case "$OS" in
        macos)
            # Versão check
            if command_exists sw_vers; then
                local mv=$(sw_vers -productVersion | cut -d. -f1)
                if [[ "$mv" -lt 13 ]]; then
                    print_warning "ATENÇÃO: macOS antigo detectado."
                    echo "O Homebrew não fornece mais binários pré-compilados para sua versão."
                    echo "A instalação demoraria muito e poderia falhar."
                    echo
                    echo "Por favor, instale o Node.js manualmente em: https://nodejs.org/"
                    echo "Depois, execute este script novamente com a flag --skip-node"
                    exit 1
                fi
            fi
            run_quietly "Instalando Node.js (brew)" "brew install node"
            ;;
        linux|wsl)
            case "$PACKAGE_MANAGER" in
                apt) run_quietly "Instalando Node.js (apt)" "sudo apt-get install -y nodejs npm" ;;
                dnf) run_quietly "Instalando Node.js (dnf)" "sudo dnf install -y nodejs npm" ;;
                yum) run_quietly "Instalando Node.js (yum)" "sudo yum install -y nodejs npm" ;;
                pacman) run_quietly "Instalando Node.js (pacman)" "sudo pacman -S --noconfirm nodejs npm" ;;
                zypper) run_quietly "Instalando Node.js (zypper)" "sudo zypper install -y nodejs npm" ;;
            esac
            ;;
    esac
}

install_python() {
    case "$OS" in
        macos) run_quietly "Instalando Python (brew)" "brew install python3" ;;
        linux|wsl)
            case "$PACKAGE_MANAGER" in
                apt) run_quietly "Instalando Python (apt)" "sudo apt-get install -y python3 python3-pip" ;;
                dnf) run_quietly "Instalando Python (dnf)" "sudo dnf install -y python3 python3-pip" ;;
                yum) run_quietly "Instalando Python (yum)" "sudo yum install -y python3 python3-pip" ;;
                pacman) run_quietly "Instalando Python (pacman)" "sudo pacman -S --noconfirm python python-pip" ;;
                zypper) run_quietly "Instalando Python (zypper)" "sudo zypper install -y python3 python3-pip" ;;
            esac
            ;;
    esac
}

final_validation() {
    print_title "VALIDAÇÃO FINAL"
    local all_ok=true

    # Re-check status silently
    check_cli_status "gemini"
    local g_st="$CLI_STATUS"
    local g_v="$CLI_VERSION_OUTPUT"
    
    check_cli_status "qwen"
    local q_st="$CLI_STATUS"
    local q_v="$CLI_VERSION_OUTPUT"

    check_cli_status "codex"
    local c_st="$CLI_STATUS"
    local c_v="$CLI_VERSION_OUTPUT"

    check_cli_status "vibe"
    local v_st="$CLI_STATUS"
    local v_v="$CLI_VERSION_OUTPUT"

    if [[ "$g_st" == "installed" ]] && [[ "$q_st" == "installed" ]] && [[ "$c_st" == "installed" ]] && [[ "$v_st" == "installed" ]]; then
        echo -e "\033[0;32m✔ Todas as ferramentas estão operacionais:\033[0m"
        echo "  - gemini ($g_v)"
        echo "  - qwen ($q_v)"
        echo "  - codex ($c_v)"
        echo "  - vibe ($v_v)"
    else
        echo -e "\033[0;33m⚠ Algumas ferramentas podem ter falhado:\033[0m"
        [[ "$g_st" != "installed" ]] && echo "  - gemini: $g_st"
        [[ "$q_st" != "installed" ]] && echo "  - qwen: $q_st"
        [[ "$c_st" != "installed" ]] && echo "  - codex: $c_st"
        [[ "$v_st" != "installed" ]] && echo "  - vibe: $v_st"
    fi

    echo ""
    if [[ "$UPGRADE_FLAG" != "true" ]]; then
        print_info "Para atualizar as ferramentas no futuro, consulte as instruções em:"
        echo -e "\033[4;34mhttps://github.com/bolivaralencastro/ai-cli-installer#atualizar-clis-existentes\033[0m"
    fi
}

main() {
    # Parse Args
    while [[ $# -gt 0 ]]; do
        case $1 in
            --help) show_help; exit 0 ;;
            --yes) YES_FLAG=true; shift ;;
            --only-clis) ONLY_CLIS_FLAG=true; SKIP_NODE_FLAG=true; SKIP_PYTHON_FLAG=true; shift ;;
            --skip-node) SKIP_NODE_FLAG=true; shift ;;
            --skip-python) SKIP_PYTHON_FLAG=true; shift ;;
            --dry-run) DRY_RUN_FLAG=true; shift ;;
            --upgrade) UPGRADE_FLAG=true; shift ;;
            --log) LOG_FLAG=true; shift ;;
            *) print_error "Argumento desconhecido: $1"; exit 1 ;;
        esac
    done

    detect_os
    diagnostic_system
    plan_actions
    
    if ! confirm_execution; then
        print_warning "Operação cancelada."
        exit 0
    fi
    
    execute_all
    final_validation
}

trap 'print_error "Erro inesperado na linha $LINENO. Verifique logs."; npm cache clean --force 2>/dev/null || true; exit 1' ERR

main "$@"
