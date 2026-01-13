#Requires -RunAsAdministrator

param(
    [switch]$Yes = $false,
    [switch]$OnlyClis = $false,
    [switch]$SkipNode = $false,
    [switch]$SkipPython = $false,
    [switch]$DryRun = $false,
    [switch]$Help = $false
)

# Configurar encoding para UTF-8 para exibir emojis corretamente
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Mostrar ajuda se a flag --help for usada
if ($Help) {
    Write-Host "Instalador de ferramentas de IA"
    Write-Host ""
    Write-Host "Uso: powershell -ExecutionPolicy Bypass -File install.ps1 [OPCOES]"
    Write-Host ""
    Write-Host "Opcoes:"
    Write-Host "    -Help          Mostra esta mensagem de ajuda"
    Write-Host "    -Yes           Responde sim automaticamente"
    Write-Host "    -OnlyClis      Instala apenas as CLIs"
    Write-Host "    -DryRun        Modo de teste"
    exit 0
}

# Funções para impressão de mensagens
function Print-Success {
    param([string]$Message)
    $icon = [char]0x2713
    Write-Host "$icon $Message" -ForegroundColor Green
}

function Print-Warning {
    param([string]$Message)
    $icon = [char]0x26A0
    Write-Host "$icon $Message" -ForegroundColor Yellow
}

function Print-Error {
    param([string]$Message)
    $icon = [char]0x2717
    Write-Host "$icon $Message" -ForegroundColor Red
}

function Print-Info {
    param([string]$Message)
    $icon = [char]0x2139
    Write-Host "$icon $Message" -ForegroundColor Blue
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

    Print-Warning "Este script ira instalar ferramentas de IA globalmente no seu sistema."
    $confirmation = Read-Host "Deseja continuar? (S/n)"
    return ($confirmation -eq 'S' -or $confirmation -eq 's')
}

# Função para diagnóstico inicial
function Show-Diagnostic {
    Print-Title "DIAGNOSTICO INICIAL"

    $osInfo = [System.Environment]::OSVersion
    Print-Info "Sistema operacional detectado: Windows"

    if (Command-Exists "node") {
        $nodeVersion = $(node --version)
        Print-Info "Node.js: instalado ($nodeVersion)"
    }
    else {
        Print-Info "Node.js: ausente"
    }

    if (Command-Exists "npm") {
        Print-Info "npm: disponivel"
    }
    else {
        Print-Info "npm: nao disponivel"
    }

    if (Command-Exists "python") {
        $pythonVersion = $(python --version)
        Print-Info "Python: instalado ($pythonVersion)"
    }
    else {
        Print-Info "Python: ausente"
    }

    if (Command-Exists "pip") {
        Print-Info "pip: disponivel"
    }
    else {
        Print-Info "pip: nao disponivel"
    }

    Print-Title "O QUE SERA INSTALADO"
    if ($OnlyClis) {
        Print-Info "Apenas CLIs de IA (modo -OnlyClis)"
    }
    else {
        if (!$SkipNode -and !(Command-Exists "node")) {
            Print-Info "Node.js (porque esta ausente e -SkipNode nao foi usado)"
        }
        elseif ($SkipNode) {
            Print-Info "Node.js (sera pulado por -SkipNode)"
        }
        else {
            Print-Info "Node.js (ja esta instalado)"
        }

        if (!$SkipPython -and !(Command-Exists "python")) {
            Print-Info "Python (porque esta ausente e -SkipPython nao foi usado)"
        }
        elseif ($SkipPython) {
            Print-Info "Python (sera pulado por -SkipPython)"
        }
        else {
            Print-Info "Python (ja esta instalado)"
        }
    }

    Print-Info "Google Gemini CLI"
    Print-Info "Qwen Code"
    Print-Info "OpenAI Codex CLI"
    Print-Info "Mistral Vibe"

    if ($DryRun) {
        Print-Warning "Modo -DryRun ativado. Nenhuma instalacao sera realizada."
    }
}

# Verificar se o comando existe
function Command-Exists {
    param([string]$Command)
    try {
        Get-Command $Command -ErrorAction Stop
        return $true
    }
    catch {
        return $false
    }
}

# Instalar Node.js e Python via winget
function Install-Prerequisites {
    # Verificar se Node.js já está instalado
    if ($SkipNode) {
        Print-Info "Pulando instalacao do Node.js (-SkipNode)."
    }
    elseif (Command-Exists "node") {
        Print-Success "Node.js ja esta instalado."
    }
    else {
        Print-Info "Instalando Node.js via winget..."
        winget install OpenJS.NodeJS.LTS -h
        if (Command-Exists "node") {
            Print-Success "Node.js instalado com sucesso."
        }
        else {
            Print-Error "Falha ao instalar Node.js."
            exit 1
        }
    }

    # Verificar se Python já está instalado
    if ($SkipPython) {
        Print-Info "Pulando instalacao do Python (-SkipPython)."
    }
    elseif (Command-Exists "python") {
        Print-Success "Python ja esta instalado."
    }
    else {
        Print-Info "Instalando Python via winget..."
        winget install Python.Python.3 -h
        if (Command-Exists "python") {
            Print-Success "Python instalado com sucesso."
        }
        else {
            Print-Error "Falha ao instalar Python."
            exit 1
        }
    }
}

# Instalar CLIs de IA
function Install-AITools {
    Print-Title "INSTALANDO FERRAMENTAS DE IA"

    Print-Info "Instalando Google Gemini CLI..."
    if (!$DryRun) {
        npm install -g @google/gemini-cli
    }
    else {
        Print-Info "(dry-run) npm install -g @google/gemini-cli"
    }
    Print-Success "Google Gemini CLI instalado."

    Print-Info "Instalando Qwen Code..."
    if (!$DryRun) {
        npm install -g @qwen-code/qwen-code
    }
    else {
        Print-Info "(dry-run) npm install -g @qwen-code/qwen-code"
    }
    Print-Success "Qwen Code instalado."

    Print-Info "Instalando OpenAI Codex CLI..."
    if (!$DryRun) {
        npm install -g @openai/codex
    }
    else {
        Print-Info "(dry-run) npm install -g @openai/codex"
    }
    Print-Success "OpenAI Codex CLI instalado."

    Print-Info "Instalando Mistral Vibe..."
    if (!$DryRun) {
        python -m pip install mistral-vibe
    }
    else {
        Print-Info "(dry-run) python -m pip install mistral-vibe"
    }
    Print-Success "Mistral Vibe instalado."
}

# Função principal
function Main {
    Print-Title "INSTALADOR DE FERRAMENTAS DE IA PARA WINDOWS"

    # Aplicar --only-clis se necessário
    if ($OnlyClis) {
        $SkipNode = $true
        $SkipPython = $true
    }

    Show-Diagnostic

    if ($DryRun) {
        Print-Info "Encerrando (modo -DryRun)."
        exit 0
    }

    if (-not (Confirm-Execution)) {
        Print-Warning "Operacao cancelada pelo usuario."
        exit 0
    }

    Install-Prerequisites

    Install-AITools

    Print-Title "INSTALACAO CONCLUIDA"
    Print-Success "Todas as ferramentas de IA foram instaladas com sucesso!"
    Print-Warning "Pode ser necessario reiniciar o terminal para que as alteracoes tenham efeito."
    Print-Info "Para comecar a usa-las, abra um novo terminal e execute:"
    Print-Info "gemini, qwen, codex ou vibe"
}

# Definir modo estrito para maior robustez
Set-StrictMode -Version Latest

# Executar função principal
Main
