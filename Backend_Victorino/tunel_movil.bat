@echo off
title VictorinoStyle - Tunel para moviles
chcp 65001 >nul
cd /d "%~dp0"

echo.
echo =====================================================
echo   VICTORINO STYLE - Tunel para acceso desde moviles
echo =====================================================
echo.

:: ── Verificar que el backend está corriendo ──
netstat -ano 2>nul | findstr ":8080 " | findstr "LISTENING" >nul
if %errorlevel% neq 0 (
    echo [ERROR] El backend NO esta arrancado.
    echo         Abre arrancar_backend.bat primero y luego este archivo.
    echo.
    pause
    exit /b 1
)
echo [OK] Backend corriendo en puerto 8080
echo.
echo -------------------------------------------------------
echo  Creando tunel publico... (sin cuenta, sin instalacion)
echo -------------------------------------------------------
echo.
echo  Espera unos segundos hasta que aparezca la URL...
echo.
echo  Cuando veas la URL (https://XXXX.lhr.life):
echo.
echo    1. Copia esa URL
echo    2. En la app del movil: Login ^> icono engranaje (esquina superior)
echo    3. Pega la URL + /api/v1
echo       Ejemplo: https://abc123.lhr.life/api/v1
echo    4. Pulsa "Probar conexion" y luego "Guardar URL"
echo.
echo  IMPORTANTE: Esta ventana debe permanecer ABIERTA
echo              mientras usen la app desde el movil.
echo              Si la cierras, se pierde la conexion.
echo.
echo -------------------------------------------------------
echo.

:: Lanzar el tunel con localhost.run (sin cuenta, gratis)
ssh -o StrictHostKeyChecking=no -R 80:localhost:8080 nokey@localhost.run

echo.
echo [!] El tunel se ha cerrado.
echo     Para volver a usarlo, ejecuta este archivo de nuevo.
echo.
pause

