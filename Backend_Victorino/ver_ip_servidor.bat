@echo off
title VictorinoStyle - Ver IPs del servidor
chcp 65001 >nul
cd /d "%~dp0"

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
if %errorlevel%==0 (
    echo   [OK] ngrok instalado. Iniciando tunel en puerto 8080...
    echo        (se abrira una nueva ventana con la URL publica)
    echo.
    echo   Una vez aparezca la URL en la ventana de ngrok,
    echo   pon en la app:  https://XXXX.ngrok-free.app/api/v1
    echo.
    echo   Pulsa cualquier tecla para lanzar ngrok...
    pause >nul
    start "ngrok - VictorinoStyle" cmd /k "ngrok http 8080"
) else (
    echo   [INFO] ngrok no encontrado.
    echo          Instala con: winget install ngrok.ngrok
)

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

pause

