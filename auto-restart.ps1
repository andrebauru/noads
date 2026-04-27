# ============================================================================
# AUTO-RESTART SCRIPT - Reinicia serviço se cair
# ============================================================================
# Uso: powershell -ExecutionPolicy Bypass -File auto-restart.ps1
# 
# Este script monitora a API e reinicia se ela cair

param(
    [string]$WorkDir = "d:\Programacao\ads",
    [int]$Port = 8001,
    [int]$CheckIntervalSeconds = 10,
    [int]$MaxRestarts = 5
)

# Cores
$colors = @{
    Green   = 10
    Yellow  = 14
    Red     = 12
    Blue    = 9
}

function Write-ColorOutput {
    param($Message, $Color)
    Write-Host $Message -ForegroundColor ([System.ConsoleColor]$Color)
}

# ============================================================================
# HEADER
# ============================================================================

Clear-Host
Write-ColorOutput @"
╔════════════════════════════════════════════════════════════════════════╗
║          🔄 AUTO-RESTART MONITOR - NOADS v3.0                         ║
║          Monitora e reinicia automaticamente se cair                   ║
╚════════════════════════════════════════════════════════════════════════╝
"@ $colors.Blue

Write-ColorOutput "📍 CONFIGURAÇÃO:" $colors.Yellow
Write-ColorOutput "   Diretório: $WorkDir" $colors.Yellow
Write-ColorOutput "   Porta: $Port" $colors.Yellow
Write-ColorOutput "   Intervalo verificação: ${CheckIntervalSeconds}s" $colors.Yellow
Write-ColorOutput "   Max tentativas restart: $MaxRestarts" $colors.Yellow
Write-ColorOutput ""

# ============================================================================
# FUNCTION: Verificar API
# ============================================================================

function Test-API {
    try {
        $response = Invoke-WebRequest -Uri "http://127.0.0.1:$Port/extract.php" `
            -TimeoutSec 3 -ErrorAction Stop
        return $true
    }
    catch {
        return $false
    }
}

# ============================================================================
# FUNCTION: Iniciar Serviços
# ============================================================================

function Start-Services {
    Write-ColorOutput "[$(Get-Date -Format 'HH:mm:ss')] 🚀 INICIANDO SERVIÇOS..." $colors.Blue
    
    # Mata processos antigos
    Get-Process python -ErrorAction SilentlyContinue | Stop-Process -Force
    Get-Process php -ErrorAction SilentlyContinue | Stop-Process -Force
    
    Start-Sleep -Seconds 2
    
    # Inicia Python API
    Write-ColorOutput "[$(Get-Date -Format 'HH:mm:ss')] → Iniciando Python API (porta $Port)..." $colors.Yellow
    Push-Location $WorkDir
    $pythonProcess = Start-Process python -ArgumentList "simple_api.py" -PassThru -NoNewWindow
    Pop-Location
    
    Write-ColorOutput "[$(Get-Date -Format 'HH:mm:ss')] ✅ Python iniciado (PID: $($pythonProcess.Id))" $colors.Green
    
    return $pythonProcess.Id
}

# ============================================================================
# FUNCTION: Verificar Saúde
# ============================================================================

function Check-Health {
    param($Restarts)
    
    $isHealthy = Test-API
    
    if ($isHealthy) {
        Write-ColorOutput "[$(Get-Date -Format 'HH:mm:ss')] ✅ API respondendo" $colors.Green
    }
    else {
        Write-ColorOutput "[$(Get-Date -Format 'HH:mm:ss')] ❌ API NÃO RESPONDEU!" $colors.Red
    }
    
    return $isHealthy
}

# ============================================================================
# MAIN LOOP
# ============================================================================

$restartCount = 0
$pythonPID = $null

# Iniciar serviços
$pythonPID = Start-Services

Write-ColorOutput ""
Write-ColorOutput "⏳ Aguardando API estabilizar..." $colors.Yellow
Start-Sleep -Seconds 5

Write-ColorOutput ""
Write-ColorOutput "🔄 MONITORAMENTO INICIADO - Pressione CTRL+C para parar" $colors.Green
Write-ColorOutput ""

while ($true) {
    try {
        # Verificar saúde
        $isHealthy = Check-Health $restartCount
        
        if (-not $isHealthy) {
            $restartCount++
            
            if ($restartCount -gt $MaxRestarts) {
                Write-ColorOutput ""
                Write-ColorOutput "❌ LIMITE DE RESTARTS ATINGIDO ($MaxRestarts)" $colors.Red
                Write-ColorOutput "    Interromper monitoramento manualmente" $colors.Red
                break
            }
            
            Write-ColorOutput ""
            Write-ColorOutput "⚠️  API CAIU! Restart #$restartCount/$MaxRestarts" $colors.Yellow
            Write-ColorOutput ""
            
            # Reiniciar
            $pythonPID = Start-Services
            
            Write-ColorOutput ""
            Write-ColorOutput "⏳ Aguardando estabilização (15s)..." $colors.Yellow
            Start-Sleep -Seconds 15
        }
        else {
            $restartCount = 0
        }
        
        # Aguardar próximo check
        Start-Sleep -Seconds $CheckIntervalSeconds
    }
    catch {
        Write-ColorOutput "[$(Get-Date -Format 'HH:mm:ss')] ⚠️  ERRO: $_" $colors.Red
    }
}

Write-ColorOutput ""
Write-ColorOutput "⏹️  Monitoramento interrompido" $colors.Yellow
