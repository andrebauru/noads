@echo off
REM ============================================================================
REM AUTO-RESTART - Script simples batch para Windows
REM ============================================================================
REM Duplo-clique para rodar
REM ou: auto-restart.bat

setlocal enabledelayedexpansion

echo.
echo ╔════════════════════════════════════════════════════════════════════════╗
echo ║          ♻️  AUTO-RESTART - NOADS v3.0                               ║
echo ║          Reinicia automaticamente se serviço cair                     ║
echo ╚════════════════════════════════════════════════════════════════════════╝
echo.

set "WORKDIR=d:\Programacao\ads"
set "WAIT=10"
set "RESTARTS=0"
set "MAX_RESTARTS=5"

color 0A

:LOOP
cls

echo ╔════════════════════════════════════════════════════════════════════════╗
echo ║          ♻️  AUTO-RESTART MONITOR                                    ║
echo ╚════════════════════════════════════════════════════════════════════════╝
echo.
echo 📍 Status: MONITORANDO
echo ⏰ Hora: %DATE% %TIME%
echo 🔢 Restarts: %RESTARTS%/%MAX_RESTARTS%
echo.

REM Verificar se Python está rodando
tasklist | find /i "python.exe" > nul
if errorlevel 1 (
    echo ❌ Python não está rodando!
    echo.
    goto RESTART
) else (
    echo ✅ Python está rodando
    goto WAIT
)

:RESTART
set /a RESTARTS=RESTARTS+1

if %RESTARTS% gtr %MAX_RESTARTS% (
    color 0C
    echo.
    echo ❌ LIMITE DE RESTARTS ATINGIDO!
    echo.
    pause
    exit /b 1
)

echo.
echo 🔄 Restart #%RESTARTS%/%MAX_RESTARTS%...
echo.

REM Matar processos antigos
taskkill /f /im python.exe >nul 2>&1
taskkill /f /im php.exe >nul 2>&1

timeout /t 2 /nobreak

REM Iniciar Python API
echo 🚀 Iniciando Python API...
cd /d %WORKDIR%
start /b python simple_api.py

echo ✅ Python iniciado
echo.
echo ⏳ Aguardando estabilização (15 segundos)...

timeout /t 15 /nobreak

goto LOOP

:WAIT
set "RESTARTS=0"
echo ⏳ Próxima verificação em %WAIT% segundos...
echo.
echo 💡 Pressione CTRL+C para parar
echo.

timeout /t %WAIT% /nobreak

goto LOOP
