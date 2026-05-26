# 🏗️ Guía de Generación de Ejecutables — Victorino Style Frontend

> **Proyecto:** `frontend_victorino` — Flutter `3.x` / Dart SDK `^3.11.0`  
> **Versión de la app:** `1.0.0+1`  
> **Última revisión:** Mayo 2026

---

## 📑 Tabla de Contenidos

1. [Resumen del Proyecto](#1-resumen-del-proyecto)
2. [Requisitos Previos Globales](#2-requisitos-previos-globales)
3. [APK para Android](#3-apk-para-android)
4. [Ejecutable para Windows](#4-ejecutable-para-windows)
5. [Instalador Windows (.exe) con Inno Setup](#5-instalador-windows-exe-con-inno-setup)
6. [Ejecutable para Linux](#6-ejecutable-para-linux)
7. [Build Web (bonus) + Docker](#7-build-web-bonus--docker)
8. [Iconos y Splash Screen](#8-iconos-y-splash-screen)
9. [Variables de Entorno y Configuración del Backend](#9-variables-de-entorno-y-configuración-del-backend)
10. [Árbol de Salida de cada Build](#10-árbol-de-salida-de-cada-build)
11. [Problemas Comunes y Soluciones](#11-problemas-comunes-y-soluciones)

---

## 1. Resumen del Proyecto

Victorino Style es una app Flutter multi-plataforma para gestión de citas de barbería. Su arquitectura relevante para builds es:

| Fichero / Carpeta | Propósito |
|---|---|
| `pubspec.yaml` | Dependencias, versión `1.0.0+1`, Flutter SDK `^3.11.0` |
| `lib/main.dart` | Punto de entrada. Inicializa Firebase (solo en Android/iOS), Riverpod y la app |
| `android/` | Proyecto Gradle con `build.gradle.kts`, Firebase via `google-services.json` |
| `windows/CMakeLists.txt` | Proyecto CMake + mingw. Produce `frontend_victorino.exe` |
| `linux/CMakeLists.txt` | Proyecto CMake + GTK3. Produce el binario `frontend_victorino` |
| `victorino_setup.iss` | Script **Inno Setup 6** para empaquetar Windows en un instalador `.exe` |
| `Dockerfile` | Build multi-etapa Flutter Web + nginx (para Railway o Docker local) |
| `flutter_launcher_icons.yaml` | Config de íconos para todas las plataformas |
| `flutter_native_splash.yaml` | Config del splash screen nativo |

### Dependencias clave para producción

- **Firebase:** `firebase_core ^4.7.0`, `firebase_messaging ^16.2.0` *(solo Android/iOS, desactivado en escritorio/web por código)*
- **Estado:** `flutter_riverpod ^3.3.1`
- **Navegación:** `go_router ^17.2.2`
- **HTTP:** `dio ^5.9.2`, `http ^1.6.0`
- **Almacenamiento seguro:** `flutter_secure_storage ^10.0.0`
- **Notificaciones locales:** `flutter_local_notifications ^21.0.0`

---

## 2. Requisitos Previos Globales

### 2.1 Flutter SDK

```bash
# Verificar instalación y plataformas habilitadas
flutter --version
flutter doctor -v
```

> Se necesita Flutter **3.x** con Dart **^3.11.0**. Si hay actualizaciones pendientes:
> ```bash
> flutter upgrade
> ```

### 2.2 Dependencias del Proyecto

Siempre ejecuta esto al clonar o cambiar de rama:

```bash
cd "C:\Users\barqu\Desktop\Victorino Styleee\frontend_victorino"
flutter pub get
```

---

## 3. APK para Android

### 3.1 Requisitos

| Herramienta | Versión mínima |
|---|---|
| Android SDK | API 23 (Android 6.0) — `minSdk = flutter.minSdkVersion` |
| Java JDK | 17 (configurado en `build.gradle.kts`) |
| Android Studio o SDK Tools | Cualquiera reciente |

Confirma con:
```bash
flutter doctor --android-licenses   # aceptar licencias si es necesario
```

### 3.2 Estructura Android del Proyecto

```
android/
├── build.gradle.kts          ← Repositorios: google() + mavenCentral()
├── settings.gradle.kts
├── gradle.properties
└── app/
    ├── build.gradle.kts      ← applicationId, minSdk, targetSdk, versionCode
    └── google-services.json  ← Firebase (¡no subir a repositorios públicos!)
```

Configuración importante en `android/app/build.gradle.kts`:
```kotlin
namespace = "com.example.frontend_victorino"
compileSdk = flutter.compileSdkVersion
minSdk = flutter.minSdkVersion        // 23
targetSdk = flutter.targetSdkVersion
versionCode = flutter.versionCode     // 1
versionName = flutter.versionName     // "1.0.0"

// Desugaring activo (necesario para flutter_local_notifications)
isCoreLibraryDesugaringEnabled = true
sourceCompatibility = JavaVersion.VERSION_17
targetCompatibility = JavaVersion.VERSION_17
```

### 3.3 APK de Depuración (Debug)

```bash
flutter build apk --debug
```
📂 **Salida:** `build/app/outputs/flutter-apk/app-debug.apk`

### 3.4 APK de Producción (Release) — ⚠️ LEER ANTES

```bash
flutter build apk --release
```
📂 **Salida:** `build/app/outputs/flutter-apk/app-release.apk`

> **⚠️ IMPORTANTE — Firma de release:**  
> El proyecto actualmente usa `signingConfig = signingConfigs.getByName("debug")` en el bloque `release`. Esto es funcional para pruebas, pero **la APK no será aceptada en Google Play** sin una firma propia (keystore). Ver sección [11. Problemas Comunes](#11-problemas-comunes-y-soluciones).

### 3.5 APK Dividida por ABI (más pequeña, recomendada)

```bash
flutter build apk --release --split-per-abi
```

Genera tres APKs optimizadas:
- `app-armeabi-v7a-release.apk` → Dispositivos ARM 32-bit
- `app-arm64-v8a-release.apk`  → Dispositivos ARM 64-bit (mayoría de Android modernos)
- `app-x86_64-release.apk`     → Emuladores y tablets x86

📂 **Salida:** `build/app/outputs/flutter-apk/`

### 3.6 App Bundle (AAB) — Para Google Play Store

```bash
flutter build appbundle --release
```
📂 **Salida:** `build/app/outputs/bundle/release/app-release.aab`

> El `.aab` es el formato preferido por Google Play. Permite distribución optimizada según el dispositivo.

### 3.7 Instalar directamente en dispositivo conectado

```bash
# Listar dispositivos
flutter devices

# Instalar APK debug en dispositivo conectado
flutter install
# o directamente con adb:
adb install build/app/outputs/flutter-apk/app-release.apk
```

---

## 4. Ejecutable para Windows

### 4.1 Requisitos

| Herramienta | Descripción |
|---|---|
| Windows 10 o superior | Objetivo mínimo del build (`MinVersion=10.0` en Inno Setup) |
| Visual Studio 2022 | Con workload **"Desarrollo de escritorio con C++"** |
| CMake 3.14+ | Incluido con Visual Studio o instalable desde cmake.org |

Confirma que Windows está habilitado en Flutter:
```bash
flutter config --enable-windows-desktop
flutter doctor
```

### 4.2 Estructura Windows del Proyecto

```
windows/
├── CMakeLists.txt         ← Config principal CMake (C++17, UNICODE, BINARY_NAME)
├── flutter/               ← Reglas de build del engine Flutter para Windows
└── runner/
    ├── CMakeLists.txt     ← Runner Win32
    └── resources/
        └── app_icon.ico   ← Ícono de la app en Windows
```

El binario final se llama `frontend_victorino.exe` (definido en `CMakeLists.txt` como `BINARY_NAME`).

### 4.3 Build de Windows

```bash
# Desde la raíz del proyecto
flutter build windows --release
```

📂 **Salida completa (carpeta distribuible):**
```
build\windows\x64\runner\Release\
├── frontend_victorino.exe   ← Ejecutable principal
├── flutter_windows.dll      ← Engine de Flutter
├── msvcp140.dll             ← Runtime de Visual C++
├── vcruntime140.dll
└── data\
    └── flutter_assets\      ← Assets de la app (imágenes, fuentes, etc.)
```

> **⚠️ La carpeta `Release\` completa es necesaria para distribuir.** El `.exe` solo no funciona sin los archivos `.dll` y la carpeta `data/`.

### 4.4 Ejecutar en modo debug (desarrollo)

```bash
flutter run -d windows
```

---

## 5. Instalador Windows (.exe) con Inno Setup

El proyecto incluye el script `victorino_setup.iss` en la raíz. Genera `VictorinoStyle_Setup_1.0.0.exe` que instala la app en `C:\Program Files\Victorino Style\`.

### 5.1 Requisitos

- **Inno Setup 6:** Descargar desde [https://jrsoftware.org/isinfo.php](https://jrsoftware.org/isinfo.php)
- Haber generado el build de Windows release **primero** (sección 4.3)

### 5.2 Detalles del Script `victorino_setup.iss`

| Parámetro | Valor |
|---|---|
| AppName | `Victorino Style` |
| AppVersion | `1.0.0` |
| Ejecutable fuente | `frontend_victorino.exe` |
| Carpeta fuente | `build\windows\x64\runner\Release\` |
| Carpeta salida del instalador | `instalador_windows\` |
| Nombre del instalador | `VictorinoStyle_Setup_1.0.0.exe` |
| Compresión | `lzma2/ultra64` (máxima) |
| SO mínimo | Windows 10 |
| Idioma | Español |
| Privilegios | Administrador (instala en Program Files) |

Funcionalidades del instalador:
- ✅ Acceso directo en el Menú Inicio
- ✅ Opción de crear icono en el Escritorio
- ✅ Opción de lanzar la app al terminar la instalación
- ✅ Desinstalador completo incluido

### 5.3 Pasos para generar el instalador

**Paso 1 — Compilar el build de Windows:**
```bash
flutter build windows --release
```

**Paso 2 — Compilar el instalador (opción A: GUI):**
1. Abre **Inno Setup Compiler**
2. `File → Open` → selecciona `victorino_setup.iss`
3. Pulsa `Ctrl + F9` o `Build → Compile`

**Paso 3 — Compilar el instalador (opción B: línea de comandos):**
```bash
# Desde la raíz del proyecto (PowerShell)
& "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" victorino_setup.iss
```

📂 **Instalador generado en:** `instalador_windows\VictorinoStyle_Setup_1.0.0.exe`

> El instalador ya compilado se encuentra en `instalador_windows\VictorinoStyle_Setup_1.0.0.exe`.

---

## 6. Ejecutable para Linux

### 6.1 Requisitos (en Linux o WSL2)

> ⚠️ **El build de Linux debe realizarse en una máquina Linux o WSL2 (Windows Subsystem for Linux).** No se puede compilar para Linux desde Windows nativo.

```bash
# Ubuntu/Debian — instalar dependencias del sistema
sudo apt-get update
sudo apt-get install -y \
  clang cmake git \
  ninja-build pkg-config \
  libgtk-3-dev \
  liblzma-dev \
  libstdc++-12-dev

# Habilitar Linux en Flutter
flutter config --enable-linux-desktop
flutter doctor
```

### 6.2 Estructura Linux del Proyecto

```
linux/
├── CMakeLists.txt     ← Config CMake (GTK3, C++14, APPLICATION_ID)
├── flutter/           ← Rules del engine Flutter para Linux
└── runner/
    └── CMakeLists.txt
```

Detalles técnicos de `linux/CMakeLists.txt`:
- **Binary name:** `frontend_victorino`
- **Application ID:** `com.example.frontend_victorino`
- **GTK:** `pkg_check_modules(GTK REQUIRED IMPORTED_TARGET gtk+-3.0)`
- **C++ standard:** C++14
- **RPATH:** `$ORIGIN/lib` (librerías relativas al ejecutable)

### 6.3 Build de Linux

```bash
# En Linux / WSL2
cd /ruta/al/proyecto/frontend_victorino
flutter pub get
flutter build linux --release
```

📂 **Salida (bundle redistribuible):**
```
build/linux/x64/release/bundle/
├── frontend_victorino      ← Ejecutable principal (ELF 64-bit)
├── data/
│   ├── flutter_assets/     ← Assets de la app
│   └── icudtl.dat          ← Datos ICU (internacionalización)
└── lib/
    ├── libflutter_linux_gtk.so
    └── *.so                ← Librerías de plugins
```

> **La carpeta `bundle/` completa es necesaria para distribuir.** El binario solo no funciona sin las `.so` y la carpeta `data/`.

### 6.4 Empaquetar para distribución en Linux

**Opción A — AppImage** (portable, no requiere instalación):
```bash
# Instalar herramienta
sudo apt install libfuse2
wget https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage
chmod +x appimagetool-x86_64.AppImage

# Crear estructura AppDir y usar appimagetool
# (requiere configuración adicional del .desktop y AppRun)
```

**Opción B — Debian Package (`.deb`)**:
```bash
# Instalar herramienta
sudo apt install ruby ruby-dev
sudo gem install fpm

# Crear .deb desde el bundle
fpm -s dir -t deb \
  -n victorino-style \
  -v 1.0.0 \
  --prefix /opt/victorino-style \
  build/linux/x64/release/bundle/=.
```

**Opción C — Distribuir el bundle directamente** (más simple):
```bash
# Comprimir el bundle
cd build/linux/x64/release/
tar -czvf victorino-style-linux-1.0.0.tar.gz bundle/
```

### 6.5 Ejecutar en modo debug (Linux)

```bash
flutter run -d linux
```

---

## 7. Build Web (bonus) + Docker

Aunque no se pidió explícitamente, el proyecto incluye todo para Web.

### 7.1 Build Web local

```bash
flutter build web --release \
  --dart-define=API_BASE_URL=https://tu-backend.railway.app/api/v1
```

📂 **Salida:** `build/web/`

### 7.2 Docker (Railway / cualquier servidor)

El `Dockerfile` usa una imagen multi-etapa:
- **Etapa 1 (`build`):** Imagen `ghcr.io/cirruslabs/flutter:3.41.2` que compila el web
- **Etapa 2 (runtime):** `nginx:alpine` que sirve los assets estáticos

```bash
# Build local
docker build \
  --build-arg API_BASE_URL=http://localhost:8080/api/v1 \
  -t victorino-frontend .

# Ejecutar localmente
docker run -p 8080:8080 -e PORT=8080 victorino-frontend
```

Para Railway: configurar el Build Arg `API_BASE_URL` en el dashboard de Railway.

---

## 8. Iconos y Splash Screen

### 8.1 Regenerar Iconos (flutter_launcher_icons)

Configurado en `pubspec.yaml`. El logo fuente es `assets/logos_app/logo_app1.3.png`.

Genera iconos para: Android (adaptive icon), iOS, Web (favicon + PWA), Windows (256px .ico), macOS.

```bash
flutter pub get
dart run flutter_launcher_icons
```

Configuración en `pubspec.yaml`:
```yaml
flutter_launcher_icons:
  image_path: "assets/logos_app/logo_app1.3.png"
  android: "ic_launcher"
  adaptive_icon_background: "#0A0A0F"   # Fondo negro opaco
  adaptive_icon_foreground: "assets/logos_app/logo_app1.3.png"
  min_sdk_android: 23
  ios: true
  remove_alpha_ios: true
  background_color_ios: "#0A0A0F"
  web:
    generate: true
  windows:
    generate: true
    icon_size: 256
```

### 8.2 Regenerar Splash Screen (flutter_native_splash)

```bash
dart run flutter_native_splash:create
```

Para eliminar el splash nativo:
```bash
dart run flutter_native_splash:remove
```

---

## 9. Variables de Entorno y Configuración del Backend

La URL del backend se gestiona de dos formas:

| Plataforma | Mecanismo |
|---|---|
| **Android / iOS / Escritorio** | Se guarda en `flutter_secure_storage` y se lee al arrancar (`main.dart`) |
| **Web (Docker)** | Se inyecta en tiempo de compilación via `--dart-define=API_BASE_URL=...` |

Para compilar con una URL fija en cualquier plataforma:
```bash
flutter build apk --release \
  --dart-define=API_BASE_URL=https://mi-backend.com/api/v1

flutter build windows --release \
  --dart-define=API_BASE_URL=https://mi-backend.com/api/v1
```

---

## 10. Árbol de Salida de cada Build

```
build/
├── app/
│   └── outputs/
│       ├── flutter-apk/
│       │   ├── app-debug.apk
│       │   ├── app-release.apk
│       │   ├── app-arm64-v8a-release.apk
│       │   ├── app-armeabi-v7a-release.apk
│       │   └── app-x86_64-release.apk
│       └── bundle/
│           └── release/
│               └── app-release.aab         ← Para Google Play
│
├── windows/
│   └── x64/
│       └── runner/
│           └── Release/                     ← Carpeta distribuible Windows
│               ├── frontend_victorino.exe
│               ├── flutter_windows.dll
│               └── data/...
│
├── linux/
│   └── x64/
│       └── release/
│           └── bundle/                      ← Carpeta distribuible Linux
│               ├── frontend_victorino
│               ├── lib/
│               └── data/...
│
└── web/                                     ← Archivos estáticos para servidor

instalador_windows/
└── VictorinoStyle_Setup_1.0.0.exe           ← Instalador Windows (Inno Setup)
```

---

## 11. Problemas Comunes y Soluciones

### 🔴 APK rechazada en Google Play (firma)

**Problema:** `release` usa `signingConfig = signingConfigs.getByName("debug")`.  
**Solución:** Crear un keystore propio y configurarlo:

```bash
# 1. Crear keystore
keytool -genkey -v \
  -keystore victorino-release.jks \
  -keyalg RSA -keysize 2048 \
  -validity 10000 \
  -alias victorino

# 2. Crear android/key.properties (NO subir a Git)
storePassword=TU_PASSWORD
keyPassword=TU_PASSWORD
keyAlias=victorino
storeFile=../victorino-release.jks
```

Luego en `android/app/build.gradle.kts` reemplazar el bloque `buildTypes → release → signingConfig`.

---

### 🔴 Firebase falla en desktop/web

**Problema:** La app lanza `UnsupportedError` al inicializar Firebase en Windows/Linux.  
**Solución:** Ya está manejado en `main.dart`:
```dart
bool get _soportaFirebase =>
    !kIsWeb && (Platform.isAndroid || Platform.isIOS);
```
Firebase se omite automáticamente en escritorio y web.

---

### 🔴 `flutter build windows` falla con CMake

**Problema:** Visual Studio no tiene el workload correcto.  
**Solución:**
```bash
# Verificar con:
flutter doctor -v
# Debe aparecer: [✓] Visual Studio - develop Windows apps (Visual Studio 2022 17.x)
```
Instalar el workload **"Desarrollo de escritorio con C++"** en el Visual Studio Installer.

---

### 🔴 `flutter build linux` falla sin GTK

**Problema:** `Could not find package 'gtk+-3.0'`  
**Solución:**
```bash
sudo apt-get install libgtk-3-dev
```

---

### 🔴 Assets vacíos / Error al cargar imágenes

**Problema:** Flutter lanza error si alguna carpeta de assets declarada en `pubspec.yaml` está vacía.  
**Solución:** Verificar que `assets/`, `assets/logos_app/` y `assets/imagenes/` tengan al menos 1 archivo. El logo fuente `logo_app1.3.png` debe existir para que `flutter_launcher_icons` funcione.

---

### 🔴 `desugar_jdk_libs` no encontrado

**Problema:** Error de Gradle al compilar Android.  
**Solución:** Ya está configurado en `android/app/build.gradle.kts`:
```kotlin
dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
```
Asegúrate de ejecutar `flutter pub get` y que Gradle sincronice correctamente.

---

### 🔴 Inno Setup no encuentra los archivos de Release

**Problema:** `Source: "build\windows\x64\runner\Release\*"` no existe.  
**Solución:** Ejecutar `flutter build windows --release` **antes** de compilar el `.iss`.

---

## 🚀 Flujo Rápido de Referencia

```bash
# ─── Android APK Release ───────────────────────────────────────
flutter pub get
flutter build apk --release --split-per-abi
# → build/app/outputs/flutter-apk/app-arm64-v8a-release.apk

# ─── Windows .exe ──────────────────────────────────────────────
flutter pub get
flutter build windows --release
# → build\windows\x64\runner\Release\frontend_victorino.exe

# ─── Instalador Windows ────────────────────────────────────────
& "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" victorino_setup.iss
# → instalador_windows\VictorinoStyle_Setup_1.0.0.exe

# ─── Linux (desde Linux/WSL2) ──────────────────────────────────
flutter pub get
flutter build linux --release
# → build/linux/x64/release/bundle/

# ─── Regenerar Iconos ──────────────────────────────────────────
dart run flutter_launcher_icons

# ─── Regenerar Splash ──────────────────────────────────────────
dart run flutter_native_splash:create
```

---

*Guía generada con base en el análisis del proyecto `frontend_victorino` — Victorino Style.*

