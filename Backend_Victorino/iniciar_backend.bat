@echo off
title VictorinoStyle - Backend
color 0A

echo.
echo  =====================================================
echo    VICTORINO STYLE - Iniciando Backend...
echo  =====================================================
echo.
echo  IP de red local: 192.168.1.37
echo  Puerto:          8080
echo  URL completa:    http://192.168.1.37:8080/api/v1
echo.
echo  IMPORTANTE: Mantén esta ventana abierta durante la demo
echo  Para parar el servidor cierra esta ventana o pulsa Ctrl+C
echo.
echo  =====================================================
echo.

cd /d "C:\Users\barqu\AndroidStudioProjects\VictorinoStyleDefinitivo\Backend_Victorino"

java -jar "C:\Users\barqu\AndroidStudioProjects\VictorinoStyleDefinitivo\Backend_Victorino\target\Backend_Victorino-0.0.1-SNAPSHOT.jar"

echo.
echo  El backend se ha detenido.
pause

