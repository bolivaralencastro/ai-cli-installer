#Requires -RunAsAdministrator

param(
    [switch]$Yes = $false,
    [switch]$Help = $false
)

# Mostrar ajuda se a flag --help for usada
if ($Help) {
    @"
Desinstalador de ferramentas de IA

Uso: powershell -ExecutionPolicy Bypass -File $PSCommandPath [OPÇÕES]

Opções:
    -Help          Mostra esta mensagem de ajuda
    -Yes           Responde sim automaticamente a todas as confirmações

Exemplos:
    .\$($MyInvocation.MyCommand.Name)                    # Desinstala com confirmação
    .\$($MyInvocation.MyCommand.Name) -Yes              # Desinstala sem confirmação
"@
    exit 0
}

# Funções para impressão de mensagens
function Print-Success {
    param([string]$Message)
    Write-Host "✓ $Message" -ForegroundColor Green
}

function Print-Warning {
    param([string]$Message)
    Write-Host "⚠ $Message" -ForegroundColor Yellow
}

function Print-Error {
    param([string]$Message)
    Write-Host "✗ $Message" -ForegroundColor Red
}

function Print-Info {
    param([string]$Message)
    Write-Host "ℹ $Message" -ForegroundColor Blue
}

function Print-Title {
    param([string]$Message)
    Write-Host "`n### $Message ###" -ForegroundColor Cyan
    Write-Host ""
}

# Função para confirmar execução
function Confirm-Execution {
    if ($Yes) {
        return $true
    }
    
    Print-Warning "Este script irá remover as CLIs de IA do seu sistema."
    $confirmation = Read-Host "Deseja continuar? (S/n)"
    return ($confirmation -eq 'S' -or $confirmation -eq 's')
}

# Verificar se o comando existe
function Command-Exists {
    param([string]$Command)
    try {
        Get-Command $Command -ErrorAction Stop
        return $true
    } catch {
        return $false
    }
}

# Função para desinstalar CLIs
function Uninstall-AITools {
    Print-Title "DESINSTALANDO FERRAMENTAS DE IA"
    
    # Verificar e desinstalar Google Gemini CLI
    if (Command-Exists "gemini") {
        Print-Info "Desinstalando Google Gemini CLI..."
        npm uninstall -g @google/gemini-cli
        Print-Success "Google Gemini CLI removido."
    } else {
        Print-Info "Google Gemini CLI não encontrado, pulando..."
    }
    
    # Verificar e desinstalar Qwen Code
    if (Command-Exists "qwen") {
        Print-Info "Desinstalando Qwen Code..."
        npm uninstall -g @qwen-code/qwen-code
        Print-Success "Qwen Code removido."
    } else {
        Print-Info "Qwen Code não encontrado, pulando..."
    }
    
    # Verificar e desinstalar OpenAI Codex CLI
    if (Command-Exists "codex") {
        Print-Info "Desinstalando OpenAI Codex CLI..."
        npm uninstall -g @openai/codex
        Print-Success "OpenAI Codex CLI removido."
    } else {
        Print-Info "OpenAI Codex CLI não encontrado, pulando..."
    }
    
    # Verificar e desinstalar Mistral Vibe
    if (Command-Exists "vibe") {
        Print-Info "Desinstalando Mistral Vibe..."
        python -m pip uninstall -y mistral-vibe
        Print-Success "Mistral Vibe removido."
    } else {
        Print-Info "Mistral Vibe não encontrado, pulando..."
    }
}

# Função principal
function Main {
    Print-Title "DESINSTALADOR DE FERRAMENTAS DE IA PARA WINDOWS"
    
    if (-not (Confirm-Execution)) {
        Print-Warning "Operação cancelada pelo usuário."
        exit 0
    }
    
    Uninstall-AITools
    
    Print-Title "DESINSTALAÇÃO CONCLUÍDA"
    Print-Success "As ferramentas de IA foram removidas com sucesso!"
    Print-Info "Pode ser necessário abrir um novo terminal para que as alterações tenham efeito."
}

# Definir modo estrito para maior robustez
Set-StrictMode -Version Latest

# Executar função principal
Main