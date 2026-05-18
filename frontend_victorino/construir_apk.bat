@echo off
title VictorinoStyle - Construir APK
color 0A

echo.
echo  =====================================================
echo    VICTORINO STYLE - Construyendo APK para Android
echo  =====================================================
echo.
echo  Backend IP:  192.168.1.37
echo  Puerto:      8080
echo  API URL:     http://192.168.1.37:8080/api/v1
echo.
echo  IMPORTANTE: Asegurate de que el backend este corriendo
echo  antes de instalar el APK en el dispositivo.
echo  Si cambias de red WiFi, la IP puede variar.
echo  =====================================================
echo.

cd /d "C:\Users\barqu\AndroidStudioProjects\VictorinoStyleDefinitivo\frontend_victorino"

echo  [1/3] Limpiando proyecto...
call flutter clean
if %errorlevel% neq 0 (
    echo  ERROR: flutter clean fallo.
    pause
    exit /b 1
)

echo.
echo  [2/3] Descargando dependencias...
call flutter pub get
if %errorlevel% neq 0 (
    echo  ERROR: flutter pub get fallo.
    pause
    exit /b 1
)

echo.
echo  [3/3] Compilando APK release con IP de red local...
call flutter build apk --release ^
  --dart-define=API_BASE_URL=http://192.168.1.37:8080/api/v1
if %errorlevel% neq 0 (
    echo  ERROR: La compilacion del APK fallo.
    pause
    exit /b 1
)

echo.
echo  =====================================================
echo  APK generado correctamente!
echo.
echo  Ruta del APK:
echo  build\app\outputs\flutter-apk\app-release.apk
echo.
echo  Puedes:
echo    - Copiar el APK a tu movil via USB.
echo    - Compartirlo por WhatsApp / Drive / correo.
echo    - Instalar con:  adb install -r build\app\outputs\flutter-apk\app-release.apk
echo  =====================================================
echo.

REM Copiar APK a la carpeta raiz del proyecto para facil acceso
copy /Y "build\app\outputs\flutter-apk\app-release.apk" "..\VictorinoStyle.apk" >nul 2>&1
if %errorlevel% equ 0 (
    echo  Copia rapida: VictorinoStyle.apk creado en:
    echo  C:\Users\barqu\AndroidStudioProjects\VictorinoStyleDefinitivo\VictorinoStyle.apk
    echo.
)

pause

