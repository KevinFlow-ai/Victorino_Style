@echo off
title VictorinoStyle - Iniciando sistema...
chcp 65001 >nul
cd /d "%~dp0"

echo.
echo ╔══════════════════════════════════════════════════════╗
echo ║         VICTORINO STYLE - INICIO DEL SISTEMA        ║
echo ╚══════════════════════════════════════════════════════╝
echo.

:: ── Verificar que el JAR existe ──
if not exist "target\Backend_Victorino-0.0.1-SNAPSHOT.jar" (
    echo [ERROR] No se encuentra el JAR del backend.
    echo         Compila el proyecto primero con: mvnw.cmd package -DskipTests
    echo.
    pause
    exit /b 1
)

:: ── Verificar que Java esta instalado ──
java -version >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Java no encontrado. Instala JDK 21 o superior.
    echo.
    pause
    exit /b 1
)

:: ── Liberar puerto 8080 si estaba ocupado ──
for /f "tokens=5" %%p in ('netstat -ano 2^>nul ^| findstr ":8080 " ^| findstr "LISTENING"') do (
    set "PID_OCUPADO=%%p"
)
if defined PID_OCUPADO (
    echo [AVISO] Puerto 8080 ocupado. Cerrando proceso anterior (PID %PID_OCUPADO%)...
    taskkill /PID %PID_OCUPADO% /F >nul 2>&1
    timeout /t 3 /nobreak >nul
)

:: ── Paso 1: Abrir el backend en ventana separada ──
echo  [1/2] Abriendo Backend...
start "VictorinoStyle - BACKEND (no cerrar)" cmd /k "cd /d "%~dp0" && java -jar target\Backend_Victorino-0.0.1-SNAPSHOT.jar"

echo.
echo  Esperando a que el backend arranque...
echo  (puede tardar entre 10 y 30 segundos)
echo.

:: ── Esperar hasta que el puerto 8080 responda ──
:ESPERAR
timeout /t 2 /nobreak >nul
netstat -ano 2>nul | findstr ":8080 " | findstr "LISTENING" >nul
if %errorlevel% neq 0 (
    set /p "dummy=  . <NUL"
    goto ESPERAR
)

echo.
echo  [OK] Backend listo en http://localhost:8080/api/v1
echo.

:: ── Paso 2: Abrir el tunel en ventana separada ──
echo  [2/2] Abriendo Tunel para moviles...
echo.
start "VictorinoStyle - TUNEL MOVIL (no cerrar)" cmd /k "cd /d "%~dp0" && chcp 65001 >nul && echo. && echo ======================================================= && echo   TUNEL ACTIVO - Espera la URL https://XXXX.lhr.life && echo ======================================================= && echo. && echo  Cuando veas la URL: && echo    1. Copiala && echo    2. En la app del movil: icono engranaje (arriba) && echo    3. Pega la URL + /api/v1 && echo       Ejemplo: https://abc123.lhr.life/api/v1 && echo    4. Pulsa Probar conexion y luego Guardar URL && echo. && echo  IMPORTANTE: NO cierres esta ventana mientras usen la app. && echo. && ssh -o StrictHostKeyChecking=no -R 80:localhost:8080 nokey@localhost.run && echo. && echo [!] El tunel se cerro. Ejecuta INICIAR_TODO.bat para reiniciarlo. && pause"

echo ╔══════════════════════════════════════════════════════╗
echo ║              SISTEMA INICIADO                        ║
echo ║                                                      ║
echo ║  Se han abierto 2 ventanas:                          ║
echo ║                                                      ║
echo ║  [BACKEND]  - NO la cierres                         ║
echo ║  [TUNEL]    - Busca la URL https://XXXX.lhr.life     ║
echo ║                                                      ║
echo ║  La URL del tunel es la que compartes con            ║
echo ║  clientes y empleados (en Ajustes del servidor).     ║
echo ║                                                      ║
echo ║  Recuerda añadir /api/v1 al final de la URL.         ║
echo ╚══════════════════════════════════════════════════════╝
echo.
echo  Esta ventana puedes cerrarla.
echo.
pause

