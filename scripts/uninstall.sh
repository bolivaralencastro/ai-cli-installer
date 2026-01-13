#!/bin/bash

set -euo pipefail

# Variáveis para flags
YES_FLAG=false

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

# Função para confirmar execução
confirm_execution() {
    if [[ "$YES_FLAG" == "true" ]]; then
        return 0
    fi
    
    print_warning "Este script irá remover as CLIs de IA do seu sistema."
    read -p "Deseja continuar? (y/N): " -n 1 -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]]
}

# Função para mostrar ajuda
show_help() {
    cat << EOF
Desinstalador de ferramentas de IA

Uso: $0 [OPÇÕES]

Opções:
    --help          Mostra esta mensagem de ajuda
    --yes           Responde sim automaticamente a todas as confirmações

Exemplos:
    $0              # Desinstala com confirmação
    $0 --yes        # Desinstala sem confirmação
EOF
}

# Verificar se o comando existe
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Função para desinstalar CLIs
uninstall_ai_tools() {
    print_title "DESINSTALANDO FERRAMENTAS DE IA"

    # Verificar e desinstalar Google Gemini CLI
    if command_exists gemini; then
        if command_exists npm; then
            print_info "Desinstalando Google Gemini CLI..."
            npm uninstall -g @google/gemini-cli
            print_success "Google Gemini CLI removido."
        else
            print_error "npm não encontrado. Não é possível desinstalar Google Gemini CLI."
        fi
    else
        print_info "Google Gemini CLI não encontrado, pulando..."
    fi

    # Verificar e desinstalar Qwen Code
    if command_exists qwen; then
        if command_exists npm; then
            print_info "Desinstalando Qwen Code..."
            npm uninstall -g @qwen-code/qwen-code
            print_success "Qwen Code removido."
        else
            print_error "npm não encontrado. Não é possível desinstalar Qwen Code."
        fi
    else
        print_info "Qwen Code não encontrado, pulando..."
    fi

    # Verificar e desinstalar OpenAI Codex CLI
    if command_exists codex; then
        if command_exists npm; then
            print_info "Desinstalando OpenAI Codex CLI..."
            npm uninstall -g @openai/codex
            print_success "OpenAI Codex CLI removido."
        else
            print_error "npm não encontrado. Não é possível desinstalar OpenAI Codex CLI."
        fi
    else
        print_info "OpenAI Codex CLI não encontrado, pulando..."
    fi

    # Verificar e desinstalar Mistral Vibe
    if command_exists vibe; then
        if command_exists pip; then
            print_info "Desinstalando Mistral Vibe..."
            python -m pip uninstall -y mistral-vibe || python3 -m pip uninstall -y mistral-vibe
            print_success "Mistral Vibe removido."
        elif command_exists pip3; then
            print_info "Desinstalando Mistral Vibe..."
            python3 -m pip uninstall -y mistral-vibe || python -m pip uninstall -y mistral-vibe
            print_success "Mistral Vibe removido."
        else
            print_error "pip ou pip3 não encontrado. Não é possível desinstalar Mistral Vibe."
        fi
    else
        print_info "Mistral Vibe não encontrado, pulando..."
    fi
}

# Função principal
main() {
    print_title "DESINSTALADOR DE FERRAMENTAS DE IA"
    
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
            *)
                print_error "Argumento desconhecido: $1"
                exit 1
                ;;
        esac
    done
    
    if ! confirm_execution; then
        print_warning "Operação cancelada pelo usuário."
        exit 0
    fi
    
    uninstall_ai_tools
    
    print_title "DESINSTALAÇÃO CONCLUÍDA"
    print_success "As ferramentas de IA foram removidas com sucesso!"
    print_info "Pode ser necessário abrir um novo terminal para que as alterações tenham efeito."
}

# Executar função principal com todos os argumentos
main "$@"
