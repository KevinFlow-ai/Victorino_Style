@echo off
title VictorinoStyle - Backend
echo =====================================================
echo   VICTORINO STYLE - Arrancando servidor backend...
echo =====================================================
echo.
:: Ir a la carpeta del backend (donde esta este .bat)
cd /d "%~dp0"
:: Verificar que el JAR existe
if not exist "target\Backend_Victorino-0.0.1-SNAPSHOT.jar" (
    echo [ERROR] No se encuentra el archivo JAR.
    echo         Compila el proyecto primero con: mvnw.cmd package -DskipTests
    echo.
    pause
    exit /b 1
)
:: Verificar que Java esta instalado
java -version >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Java no encontrado. Instala JDK 21 o superior.
    echo.
    pause
    exit /b 1
)
:: Liberar el puerto 8080 si esta ocupado por Java
for /f "tokens=5" %%p in ('netstat -ano 2^>nul ^| findstr ":8080 " ^| findstr "LISTENING"') do (
    set "PID_OCUPADO=%%p"
)
if defined PID_OCUPADO (
    echo [AVISO] Puerto 8080 ocupado por PID %PID_OCUPADO%. Cerrando proceso anterior...
    taskkill /PID %PID_OCUPADO% /F >nul 2>&1
    if %errorlevel%==0 (
        echo [OK] Proceso anterior cerrado. Esperando 3 segundos...
    ) else (
        echo [AVISO] No se pudo cerrar el proceso %PID_OCUPADO%. Puede que no sea Java.
        echo         Cierra manualmente el proceso y vuelve a ejecutar este archivo.
        pause
        exit /b 1
    )
    timeout /t 3 /nobreak >nul
)
echo Arrancando con Java:
java -version
echo.
echo Backend disponible en: http://localhost:8080/api/v1
echo.
:: Arrancar el .jar
java -jar target\Backend_Victorino-0.0.1-SNAPSHOT.jar
:: Si el servidor se cierra, mostrar mensaje y esperar tecla
echo.
echo [!] El servidor se ha detenido.
pause