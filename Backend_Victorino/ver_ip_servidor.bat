@echo off
title VictorinoStyle - Ver IPs del servidor
chcp 65001 >nul
cd /d "%~dp0"

:: Si se ejecuta haciendo doble clic (no desde terminal), reabrir con /k para que no se cierre
if "%REOPEN%"=="" (
    set REOPEN=1
    start "VictorinoStyle - Ver IPs del servidor" cmd /k ""%~f0""
    exit /b
)

echo.
echo =====================================================
echo   VICTORINO STYLE - IPs del servidor backend
echo =====================================================
echo.

:: ── Verificar que el backend está corriendo ──
netstat -ano 2>nul | findstr ":8080 " | findstr "LISTENING" >nul
if %errorlevel%==0 (
    echo [OK] Backend corriendo en el puerto 8080
) else (
    echo [AVISO] El backend NO esta arrancado.
    echo         Abre arrancar_backend.bat primero.
    echo.
)

echo.
echo ══════════════════════════════════════════════════
echo   OPCION 1 - Misma WiFi (todos en el mismo router)
echo ══════════════════════════════════════════════════
echo.
echo   URL a usar en la app:
echo.

:: Obtener IPs WiFi y Ethernet
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /i "IPv4"') do (
    set "IP=%%a"
    setlocal enabledelayedexpansion
    set "IP=!IP: =!"
    echo   http://!IP!:8080/api/v1
    endlocal
)

echo.
echo   Como abrir Ajustes del servidor en la app:
echo   ^> Pantalla de Login ^> icono engranaje (esquina superior)
echo.

echo.
echo ══════════════════════════════════════════════════
echo   OPCION 2 - Redes distintas / datos moviles
echo     (usa ngrok para crear un tunel publico)
echo ══════════════════════════════════════════════════
echo.
echo   Requisito: crear cuenta gratis en https://ngrok.com
echo              y ejecutar: ngrok config add-authtoken TU_TOKEN
echo.

:: Comprobar si ngrok está disponible
where ngrok >nul 2>&1
if %errorlevel% neq 0 (
    echo   [INFO] ngrok no encontrado.
    echo          Instala con: winget install ngrok.ngrok
    goto :fin_ngrok
)

echo   [OK] ngrok instalado. Comprobando authtoken...

:: Comprobar si el authtoken está configurado
:: El config suele estar en %USERPROFILE%\AppData\Local\ngrok\ngrok.yml o ngrok2
set "NGROK_CFG_1=%USERPROFILE%\AppData\Local\ngrok\ngrok.yml"
set "NGROK_CFG_2=%HOMEPATH%\.ngrok2\ngrok.yml"
set "TOKEN_OK=0"

if exist "%NGROK_CFG_1%" (
    findstr /i "authtoken" "%NGROK_CFG_1%" >nul 2>&1
    if not errorlevel 1 set "TOKEN_OK=1"
)
if exist "%NGROK_CFG_2%" (
    findstr /i "authtoken" "%NGROK_CFG_2%" >nul 2>&1
    if not errorlevel 1 set "TOKEN_OK=1"
)

if "%TOKEN_OK%"=="0" (
    echo.
    echo   [AVISO] ngrok NO tiene authtoken configurado.
    echo          Sin el token ngrok no funcionara.
    echo.
    echo   Pasos para configurarlo GRATIS:
    echo   1. Crea cuenta en: https://dashboard.ngrok.com/signup
    echo   2. Copia tu token en: https://dashboard.ngrok.com/get-started/your-authtoken
    echo   3. Abre PowerShell y ejecuta:
    echo.
    echo      ngrok config add-authtoken TU_TOKEN_AQUI
    echo.
    echo   4. Vuelve a ejecutar este archivo.
    goto :fin_ngrok
)

echo   [OK] Authtoken encontrado. Iniciando tunel en puerto 8080...
echo.
echo   Una vez aparezca la URL en la ventana de ngrok,
echo   pon en la app:  https://XXXX.ngrok-free.app/api/v1
echo.
echo   Pulsa cualquier tecla para lanzar ngrok...
pause >nul
start "ngrok - VictorinoStyle" cmd /k "ngrok http 8080"

:fin_ngrok

echo.
echo ══════════════════════════════════════════════════
echo   OPCION 3 - Hotspot movil (punto de acceso)
echo ══════════════════════════════════════════════════
echo.
echo   1. Activa el hotspot en tu movil
echo   2. Conecta el PC al hotspot del movil
echo   3. Conecta el movil al hotspot tambien
echo   4. Usa ipconfig para ver la nueva IP del PC
echo   5. Pon esa IP en la app
echo.

echo ════════════════════════════════════════
echo   NOTA: Abre el puerto 8080 en el firewall
echo   si los dispositivos no pueden conectar:
echo ════════════════════════════════════════
echo.
echo   Ejecuta esto en PowerShell como Administrador:
echo.
echo   netsh advfirewall firewall add rule name="VictorinoStyle" dir=in action=allow protocol=TCP localport=8080
echo.

echo.
echo =====================================================
echo   Escribe EXIT y pulsa Enter para cerrar.
echo =====================================================
echo.
