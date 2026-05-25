# =============================================================================
#  Genera GUIA_BUILDS.docx — Victorino Style
#  Ejecutar: py generar_word.py
# =============================================================================

from docx import Document
from docx.shared import Pt, RGBColor, Cm, Inches
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_TABLE_ALIGNMENT, WD_ALIGN_VERTICAL
from docx.oxml.ns import qn
from docx.oxml import OxmlElement
import os

OUTPUT = os.path.join(os.path.dirname(__file__), "GUIA_BUILDS.docx")

doc = Document()

# ── Estilos de página ─────────────────────────────────────────────────────────
section = doc.sections[0]
section.page_width  = Cm(21)
section.page_height = Cm(29.7)
section.left_margin   = Cm(2.5)
section.right_margin  = Cm(2.5)
section.top_margin    = Cm(2.5)
section.bottom_margin = Cm(2.5)

# ── Paleta de colores ─────────────────────────────────────────────────────────
NEGRO      = RGBColor(0x0A, 0x0A, 0x0F)
DORADO     = RGBColor(0xC8, 0xA0, 0x40)
GRIS_CLARO = RGBColor(0xF5, 0xF5, 0xF5)
GRIS_CABEC = RGBColor(0x2D, 0x2D, 0x2D)
BLANCO     = RGBColor(0xFF, 0xFF, 0xFF)
ROJO       = RGBColor(0xC0, 0x20, 0x20)
VERDE      = RGBColor(0x1A, 0x7A, 0x3C)
AZUL       = RGBColor(0x1F, 0x4E, 0x79)

# ── Helpers ───────────────────────────────────────────────────────────────────

def set_cell_bg(cell, hex_color: str):
    """Pone color de fondo a una celda de tabla."""
    tc   = cell._tc
    tcPr = tc.get_or_add_tcPr()
    shd  = OxmlElement('w:shd')
    shd.set(qn('w:val'),   'clear')
    shd.set(qn('w:color'), 'auto')
    shd.set(qn('w:fill'),  hex_color)
    tcPr.append(shd)


def add_heading(text: str, level: int, color: RGBColor = NEGRO):
    p = doc.add_heading(text, level=level)
    p.alignment = WD_ALIGN_PARAGRAPH.LEFT
    for run in p.runs:
        run.font.color.rgb = color
    return p


def add_para(text: str = "", bold: bool = False, italic: bool = False,
             color: RGBColor = NEGRO, size: int = 11,
             align=WD_ALIGN_PARAGRAPH.LEFT):
    p = doc.add_paragraph()
    p.alignment = align
    run = p.add_run(text)
    run.bold   = bold
    run.italic = italic
    run.font.size  = Pt(size)
    run.font.color.rgb = color
    return p


def add_bullet(text: str, color: RGBColor = NEGRO, icon: str = "•"):
    p = doc.add_paragraph(style='List Bullet')
    run = p.add_run(f"{icon}  {text}")
    run.font.color.rgb = color
    run.font.size = Pt(11)
    return p


def add_code_block(lines: list[str]):
    """Bloque de código con fondo gris oscuro y fuente Courier."""
    for line in lines:
        p = doc.add_paragraph()
        p.paragraph_format.left_indent  = Cm(0.8)
        p.paragraph_format.right_indent = Cm(0.8)
        p.paragraph_format.space_before = Pt(0)
        p.paragraph_format.space_after  = Pt(0)
        run = p.add_run(line if line else " ")
        run.font.name = "Courier New"
        run.font.size = Pt(9)
        run.font.color.rgb = RGBColor(0xD4, 0xD4, 0xD4)
        # fondo del párrafo
        pPr  = p._p.get_or_add_pPr()
        shd  = OxmlElement('w:shd')
        shd.set(qn('w:val'),   'clear')
        shd.set(qn('w:color'), 'auto')
        shd.set(qn('w:fill'),  '1E1E2E')
        pPr.append(shd)


def add_note(text: str, kind: str = "info"):
    """Caja de nota coloreada."""
    colors = {"info": "1F4E79", "warn": "7B3F00", "ok": "1A4731", "err": "5C0000"}
    icons  = {"info": "ℹ️", "warn": "⚠️", "ok": "✅", "err": "🔴"}
    p = doc.add_paragraph()
    p.paragraph_format.left_indent  = Cm(0.5)
    p.paragraph_format.right_indent = Cm(0.5)
    run = p.add_run(f"  {icons.get(kind,'ℹ️')}  {text}")
    run.font.size = Pt(10)
    run.font.color.rgb = BLANCO
    pPr = p._p.get_or_add_pPr()
    shd = OxmlElement('w:shd')
    shd.set(qn('w:val'),   'clear')
    shd.set(qn('w:color'), 'auto')
    shd.set(qn('w:fill'),  colors.get(kind, '1F4E79'))
    pPr.append(shd)


def add_photo_placeholder(caption: str = "[ Insertar foto aquí ]"):
    """Espacio visual para insertar una fotografía después."""
    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p.paragraph_format.space_before = Pt(6)
    p.paragraph_format.space_after  = Pt(6)
    run = p.add_run(f"\n{'─' * 55}\n{caption}\n{'─' * 55}\n")
    run.font.name  = "Courier New"
    run.font.size  = Pt(10)
    run.font.color.rgb = RGBColor(0xAA, 0xAA, 0xAA)
    run.font.italic = True
    pPr = p._p.get_or_add_pPr()
    shd = OxmlElement('w:shd')
    shd.set(qn('w:val'),   'clear')
    shd.set(qn('w:color'), 'auto')
    shd.set(qn('w:fill'),  'F0F0F0')
    pPr.append(shd)
    doc.add_paragraph()


def simple_table(headers: list[str], rows: list[list[str]],
                 header_bg: str = "0A0A0F", stripe_bg: str = "F5F5F5"):
    table = doc.add_table(rows=1 + len(rows), cols=len(headers))
    table.style = 'Table Grid'
    table.alignment = WD_TABLE_ALIGNMENT.CENTER
    # cabecera
    for i, h in enumerate(headers):
        cell = table.rows[0].cells[i]
        cell.text = h
        set_cell_bg(cell, header_bg)
        for run in cell.paragraphs[0].runs:
            run.bold = True
            run.font.color.rgb = BLANCO
            run.font.size = Pt(10)
        cell.paragraphs[0].alignment = WD_ALIGN_PARAGRAPH.CENTER
    # filas
    for r_idx, row in enumerate(rows):
        bg = stripe_bg if r_idx % 2 == 1 else "FFFFFF"
        for c_idx, val in enumerate(row):
            cell = table.rows[r_idx + 1].cells[c_idx]
            cell.text = val
            set_cell_bg(cell, bg)
            for run in cell.paragraphs[0].runs:
                run.font.size = Pt(10)
    doc.add_paragraph()
    return table


def page_break():
    doc.add_page_break()


# =============================================================================
#  PORTADA
# =============================================================================
doc.add_paragraph()
doc.add_paragraph()
doc.add_paragraph()

p = doc.add_paragraph()
p.alignment = WD_ALIGN_PARAGRAPH.CENTER
run = p.add_run("VICTORINO STYLE")
run.bold = True
run.font.size = Pt(36)
run.font.color.rgb = DORADO

add_para("✂  Barbería & Estilo  ✂", bold=True, size=14,
         color=GRIS_CABEC, align=WD_ALIGN_PARAGRAPH.CENTER)

doc.add_paragraph()
add_photo_placeholder("[ Logo de la app / Captura de pantalla principal ]")

doc.add_paragraph()
p = doc.add_paragraph()
p.alignment = WD_ALIGN_PARAGRAPH.CENTER
run = p.add_run("Guía de Generación de Ejecutables")
run.bold = True
run.font.size = Pt(22)
run.font.color.rgb = NEGRO

add_para("Windows · Linux · Android (APK / AAB)", size=13,
         color=GRIS_CABEC, align=WD_ALIGN_PARAGRAPH.CENTER)

doc.add_paragraph()
simple_table(
    headers=["Campo", "Valor"],
    rows=[
        ["Proyecto",        "frontend_victorino"],
        ["Versión app",     "1.0.0+1"],
        ["Flutter SDK",     "^3.11.0  /  Dart ^3.11.0"],
        ["Fecha revisión",  "Mayo 2026"],
        ["Autor",           "Victorino Style Dev"],
    ]
)

page_break()

# =============================================================================
#  1. RESUMEN DEL PROYECTO
# =============================================================================
add_heading("1.  Resumen del Proyecto", 1, DORADO)

add_para(
    "Victorino Style es una aplicación Flutter multi-plataforma para gestión de "
    "citas de barbería. El proyecto está preparado para compilar nativamente en "
    "Android, Windows, Linux y Web desde una única base de código Dart.",
    size=11
)
doc.add_paragraph()

add_photo_placeholder("[ Captura de la app en Android — pantalla principal ]")

add_heading("1.1  Archivos clave de configuración de builds", 2)

simple_table(
    headers=["Archivo / Carpeta", "Propósito"],
    rows=[
        ["pubspec.yaml",               "Dependencias, versión 1.0.0+1, config de iconos"],
        ["lib/main.dart",              "Entrada. Inicializa Firebase (solo Android/iOS), Riverpod"],
        ["android/app/build.gradle.kts","applicationId, minSdk, targetSdk, firma, Java 17"],
        ["android/google-services.json","Configuración de Firebase para Android"],
        ["windows/CMakeLists.txt",     "Proyecto CMake C++17 → frontend_victorino.exe"],
        ["linux/CMakeLists.txt",       "Proyecto CMake GTK3 → binario frontend_victorino"],
        ["victorino_setup.iss",        "Script Inno Setup 6 → instalador VictorinoStyle_Setup.exe"],
        ["Dockerfile",                 "Build multi-etapa Flutter Web + nginx (Railway/Docker)"],
        ["flutter_launcher_icons.yaml","Config iconos para todas las plataformas"],
        ["flutter_native_splash.yaml", "Config del splash screen nativo"],
    ]
)

add_heading("1.2  Dependencias principales de producción", 2)

simple_table(
    headers=["Paquete", "Versión", "Uso"],
    rows=[
        ["firebase_core",              "^4.7.0",  "Base Firebase (solo Android/iOS)"],
        ["firebase_messaging",         "^16.2.0", "Notificaciones push FCM"],
        ["flutter_local_notifications","^21.0.0", "Notificaciones locales"],
        ["flutter_riverpod",           "^3.3.1",  "Gestión de estado global"],
        ["go_router",                  "^17.2.2", "Navegación y rutas"],
        ["dio",                        "^5.9.2",  "Cliente HTTP al backend"],
        ["flutter_secure_storage",     "^10.0.0", "Almacenamiento seguro (JWT)"],
        ["intl",                       "^0.20.2", "Formateo de fechas en español"],
        ["flutter_launcher_icons",     "^0.14.3", "Generador de iconos (dev)"],
        ["flutter_native_splash",      "^2.4.7",  "Generador de splash (dev)"],
    ]
)

page_break()

# =============================================================================
#  2. REQUISITOS PREVIOS GLOBALES
# =============================================================================
add_heading("2.  Requisitos Previos Globales", 1, DORADO)

add_heading("2.1  Flutter SDK", 2)
add_note("Se necesita Flutter 3.x con Dart ^3.11.0 instalado y en el PATH del sistema.", "info")
doc.add_paragraph()

add_para("Verificar instalación completa:", bold=True)
add_code_block([
    "flutter --version",
    "flutter doctor -v",
    "",
    "# Si hay actualizaciones pendientes:",
    "flutter upgrade",
])

doc.add_paragraph()
add_photo_placeholder("[ Captura de pantalla: salida de 'flutter doctor -v' en terminal ]")

add_heading("2.2  Preparar el proyecto", 2)
add_para("Siempre ejecutar esto al clonar o cambiar de rama:", bold=True)
add_code_block([
    'cd "C:\\Users\\barqu\\Desktop\\Victorino Styleee\\frontend_victorino"',
    "flutter pub get",
])

page_break()

# =============================================================================
#  3. APK PARA ANDROID
# =============================================================================
add_heading("3.  APK para Android", 1, DORADO)

add_heading("3.1  Requisitos", 2)
simple_table(
    headers=["Herramienta", "Versión mínima", "Dónde obtenerla"],
    rows=[
        ["Android SDK",    "API 23 (Android 6.0)", "Android Studio SDK Manager"],
        ["Java JDK",       "17",                   "Configurado en build.gradle.kts"],
        ["Android Studio", "Cualquiera reciente",  "developer.android.com/studio"],
    ]
)

add_code_block([
    "# Aceptar licencias del SDK si es la primera vez:",
    "flutter doctor --android-licenses",
])

add_heading("3.2  Estructura Android del proyecto", 2)
add_code_block([
    "android/",
    "├── build.gradle.kts          ← Repositorios Google + Maven",
    "├── settings.gradle.kts",
    "├── gradle.properties",
    "└── app/",
    "    ├── build.gradle.kts      ← applicationId, minSdk, targetSdk, firma",
    "    └── google-services.json  ← Firebase (NO subir a repos públicos)",
])

add_heading("3.3  APK de Depuración (Debug)", 2)
add_code_block([
    "flutter build apk --debug",
    "",
    "# Salida:",
    "# build/app/outputs/flutter-apk/app-debug.apk",
])
doc.add_paragraph()
add_photo_placeholder("[ Captura: terminal mostrando 'flutter build apk --debug' completado ]")

add_heading("3.4  APK de Producción (Release) ⚠️", 2)
add_note(
    "El proyecto usa la firma debug en release. Funciona para pruebas pero "
    "Google Play rechazará la APK sin un keystore propio. Ver sección 11.",
    "warn"
)
doc.add_paragraph()
add_code_block([
    "flutter build apk --release",
    "",
    "# Salida:",
    "# build/app/outputs/flutter-apk/app-release.apk",
])

add_heading("3.5  APK dividida por ABI (recomendada — más pequeña)", 2)
add_code_block([
    "flutter build apk --release --split-per-abi",
    "",
    "# Genera tres APKs optimizadas en:",
    "# build/app/outputs/flutter-apk/",
    "#   app-arm64-v8a-release.apk    ← La mayoría de Android modernos",
    "#   app-armeabi-v7a-release.apk  ← ARM 32-bit",
    "#   app-x86_64-release.apk       ← Emuladores y tablets x86",
])

add_heading("3.6  App Bundle (.aab) — Para Google Play Store", 2)
add_note(
    "El .aab es el formato preferido por Google Play. Permite distribución "
    "optimizada según el dispositivo del usuario.",
    "ok"
)
doc.add_paragraph()
add_code_block([
    "flutter build appbundle --release",
    "",
    "# Salida:",
    "# build/app/outputs/bundle/release/app-release.aab",
])
doc.add_paragraph()
add_photo_placeholder("[ Captura: archivo app-release.apk o .aab generado en el explorador de archivos ]")

add_heading("3.7  Instalar directamente en dispositivo conectado", 2)
add_code_block([
    "# Listar dispositivos conectados",
    "flutter devices",
    "",
    "# Instalar en dispositivo vía Flutter",
    "flutter install",
    "",
    "# O directamente con adb",
    "adb install build/app/outputs/flutter-apk/app-release.apk",
])

page_break()

# =============================================================================
#  4. EJECUTABLE PARA WINDOWS
# =============================================================================
add_heading("4.  Ejecutable para Windows", 1, DORADO)

add_heading("4.1  Requisitos", 2)
simple_table(
    headers=["Herramienta", "Descripción"],
    rows=[
        ["Windows 10 o superior",  "Sistema operativo objetivo (MinVersion=10.0 en Inno Setup)"],
        ["Visual Studio 2022",     "Con workload 'Desarrollo de escritorio con C++'"],
        ["CMake 3.14+",            "Incluido con Visual Studio o desde cmake.org"],
    ]
)
add_code_block([
    "# Habilitar escritorio Windows en Flutter:",
    "flutter config --enable-windows-desktop",
    "flutter doctor",
])

add_heading("4.2  Estructura Windows del proyecto", 2)
add_code_block([
    "windows/",
    "├── CMakeLists.txt         ← Config CMake (C++17, UNICODE, BINARY_NAME)",
    "├── flutter/               ← Engine Flutter para Windows",
    "└── runner/",
    "    ├── CMakeLists.txt     ← Runner Win32",
    "    └── resources/",
    "        └── app_icon.ico   ← Ícono de la app en Windows",
])

add_heading("4.3  Compilar el ejecutable de Windows", 2)
add_code_block([
    "flutter build windows --release",
])
doc.add_paragraph()
add_note(
    "La carpeta Release completa es necesaria para distribuir. "
    "El .exe solo no funciona sin los .dll y la carpeta data/.",
    "warn"
)
doc.add_paragraph()

add_heading("Árbol de salida (carpeta distribuible):", 3)
add_code_block([
    "build\\windows\\x64\\runner\\Release\\",
    "├── frontend_victorino.exe   ← Ejecutable principal",
    "├── flutter_windows.dll      ← Engine de Flutter",
    "├── msvcp140.dll             ← Runtime Visual C++",
    "├── vcruntime140.dll",
    "└── data\\",
    "    └── flutter_assets\\     ← Assets de la app",
])
doc.add_paragraph()
add_photo_placeholder("[ Captura: carpeta Release\\  mostrando frontend_victorino.exe y los .dll ]")

add_heading("4.4  Probar en modo debug", 2)
add_code_block([
    "flutter run -d windows",
])

page_break()

# =============================================================================
#  5. INSTALADOR WINDOWS (.exe) con Inno Setup
# =============================================================================
add_heading("5.  Instalador Windows (.exe) con Inno Setup", 1, DORADO)

add_para(
    "El proyecto incluye el script victorino_setup.iss en la raíz. "
    "Genera un instalador profesional VictorinoStyle_Setup_1.0.0.exe que instala "
    "la app en C:\\Program Files\\Victorino Style\\.",
    size=11
)
doc.add_paragraph()

add_heading("5.1  Requisitos", 2)
simple_table(
    headers=["Herramienta", "Dónde obtenerla"],
    rows=[
        ["Inno Setup 6",                   "https://jrsoftware.org/isinfo.php"],
        ["Build Windows Release generado", "Sección 4.3 de esta guía"],
    ]
)

add_heading("5.2  Detalles del script victorino_setup.iss", 2)
simple_table(
    headers=["Parámetro", "Valor"],
    rows=[
        ["AppName",               "Victorino Style"],
        ["AppVersion",            "1.0.0"],
        ["Ejecutable fuente",     "frontend_victorino.exe"],
        ["Carpeta fuente",        "build\\windows\\x64\\runner\\Release\\"],
        ["Carpeta salida",        "instalador_windows\\"],
        ["Nombre del instalador", "VictorinoStyle_Setup_1.0.0.exe"],
        ["Compresión",            "lzma2/ultra64 (máxima)"],
        ["SO mínimo",             "Windows 10"],
        ["Idioma",                "Español"],
        ["Privilegios",           "Administrador (instala en Program Files)"],
    ]
)

add_heading("Funcionalidades del instalador:", 3)
for feat in [
    "Acceso directo en el Menú Inicio",
    "Opción de crear icono en el Escritorio",
    "Opción de lanzar la app al terminar la instalación",
    "Desinstalador completo incluido",
]:
    add_bullet(feat, VERDE, "✅")

add_heading("5.3  Pasos para generar el instalador", 2)

add_para("Paso 1 — Compilar el build de Windows release:", bold=True)
add_code_block(["flutter build windows --release"])
doc.add_paragraph()

add_para("Paso 2A — Usando la interfaz gráfica de Inno Setup:", bold=True)
steps = [
    "Abrir Inno Setup Compiler",
    "File → Open → seleccionar victorino_setup.iss",
    "Pulsar Ctrl + F9  o  Build → Compile",
    "El instalador se genera en instalador_windows\\",
]
for i, s in enumerate(steps, 1):
    add_bullet(f"{i}. {s}", NEGRO)

doc.add_paragraph()
add_para("Paso 2B — Desde línea de comandos (PowerShell):", bold=True)
add_code_block([
    '& "C:\\Program Files (x86)\\Inno Setup 6\\ISCC.exe" victorino_setup.iss',
    "",
    "# Instalador generado en:",
    "# instalador_windows\\VictorinoStyle_Setup_1.0.0.exe",
])
doc.add_paragraph()
add_photo_placeholder("[ Captura: Inno Setup Compiler compilando victorino_setup.iss ]")
add_photo_placeholder("[ Captura: archivo VictorinoStyle_Setup_1.0.0.exe en la carpeta instalador_windows\\ ]")
add_photo_placeholder("[ Captura: pantalla del instalador durante la instalación en Windows ]")

page_break()

# =============================================================================
#  6. EJECUTABLE PARA LINUX
# =============================================================================
add_heading("6.  Ejecutable para Linux", 1, DORADO)

add_note(
    "El build de Linux debe realizarse en una máquina Linux o WSL2 "
    "(Windows Subsystem for Linux). No se puede compilar para Linux desde Windows nativo.",
    "warn"
)
doc.add_paragraph()

add_heading("6.1  Requisitos — Ubuntu/Debian", 2)
add_code_block([
    "# Instalar dependencias del sistema",
    "sudo apt-get update",
    "sudo apt-get install -y \\",
    "  clang cmake git ninja-build pkg-config \\",
    "  libgtk-3-dev liblzma-dev libstdc++-12-dev",
    "",
    "# Habilitar Linux en Flutter",
    "flutter config --enable-linux-desktop",
    "flutter doctor",
])

add_heading("6.2  Estructura Linux del proyecto", 2)
add_code_block([
    "linux/",
    "├── CMakeLists.txt     ← Config CMake (GTK3, C++14, APPLICATION_ID)",
    "├── flutter/           ← Engine Flutter para Linux",
    "└── runner/",
    "    └── CMakeLists.txt",
])

add_para("Detalles técnicos importantes:", bold=True)
simple_table(
    headers=["Configuración", "Valor"],
    rows=[
        ["Binary name",    "frontend_victorino"],
        ["Application ID", "com.example.frontend_victorino"],
        ["GTK",            "gtk+-3.0 (requerido)"],
        ["C++ standard",   "C++14"],
        ["RPATH",          "$ORIGIN/lib  (librerías relativas al ejecutable)"],
    ]
)

add_heading("6.3  Compilar el ejecutable de Linux", 2)
add_code_block([
    "# Ejecutar en Linux / WSL2",
    "cd /ruta/al/proyecto/frontend_victorino",
    "flutter pub get",
    "flutter build linux --release",
])

add_heading("Árbol de salida (bundle redistribuible):", 3)
add_code_block([
    "build/linux/x64/release/bundle/",
    "├── frontend_victorino      ← Ejecutable principal (ELF 64-bit)",
    "├── data/",
    "│   ├── flutter_assets/     ← Assets de la app",
    "│   └── icudtl.dat          ← Datos ICU (internacionalización)",
    "└── lib/",
    "    ├── libflutter_linux_gtk.so",
    "    └── *.so                ← Librerías de plugins",
])
doc.add_paragraph()
add_photo_placeholder("[ Captura: terminal Linux mostrando 'flutter build linux --release' completado ]")
add_photo_placeholder("[ Captura: app funcionando en escritorio Linux ]")

add_heading("6.4  Opciones de empaquetado para distribución", 2)

add_para("Opción A — Comprimir el bundle (más simple):", bold=True)
add_code_block([
    "cd build/linux/x64/release/",
    "tar -czvf victorino-style-linux-1.0.0.tar.gz bundle/",
])
doc.add_paragraph()

add_para("Opción B — Paquete Debian (.deb) con fpm:", bold=True)
add_code_block([
    "sudo gem install fpm",
    "fpm -s dir -t deb -n victorino-style -v 1.0.0 \\",
    "  --prefix /opt/victorino-style \\",
    "  build/linux/x64/release/bundle/=.",
])

page_break()

# =============================================================================
#  7. BUILD WEB + DOCKER
# =============================================================================
add_heading("7.  Build Web (bonus) + Docker", 1, DORADO)

add_heading("7.1  Build Web local", 2)
add_code_block([
    "flutter build web --release \\",
    "  --dart-define=API_BASE_URL=https://tu-backend.railway.app/api/v1",
    "",
    "# Salida: build/web/",
])

add_heading("7.2  Docker — Railway / servidor propio", 2)
add_para(
    "El Dockerfile usa una imagen multi-etapa: la etapa build usa "
    "ghcr.io/cirruslabs/flutter:3.41.2 para compilar el web, y la etapa "
    "runtime usa nginx:alpine para servir los assets estáticos.",
    size=11
)
add_code_block([
    "# Build local",
    "docker build \\",
    "  --build-arg API_BASE_URL=http://localhost:8080/api/v1 \\",
    "  -t victorino-frontend .",
    "",
    "# Ejecutar localmente",
    "docker run -p 8080:8080 -e PORT=8080 victorino-frontend",
])
add_note(
    "Para Railway: configurar el Build Arg API_BASE_URL en el dashboard de Railway.",
    "info"
)

page_break()

# =============================================================================
#  8. ICONOS Y SPLASH SCREEN
# =============================================================================
add_heading("8.  Iconos y Splash Screen", 1, DORADO)

add_heading("8.1  Regenerar iconos (flutter_launcher_icons)", 2)
add_para(
    "El logo fuente es assets/logos_app/logo_app1.3.png. "
    "Genera iconos para: Android (adaptive icon sobre fondo #0A0A0F), "
    "iOS, Web (favicon + PWA), Windows (256px .ico) y macOS.",
    size=11
)
add_code_block([
    "flutter pub get",
    "dart run flutter_launcher_icons",
])
doc.add_paragraph()
add_photo_placeholder("[ Captura: ícono de la app generado en Android / Windows ]")

add_heading("8.2  Regenerar Splash Screen (flutter_native_splash)", 2)
add_code_block([
    "# Crear / actualizar el splash",
    "dart run flutter_native_splash:create",
    "",
    "# Eliminar el splash nativo",
    "dart run flutter_native_splash:remove",
])
add_photo_placeholder("[ Captura: splash screen de la app al arrancar en Android ]")

page_break()

# =============================================================================
#  9. VARIABLES DE ENTORNO Y BACKEND
# =============================================================================
add_heading("9.  Variables de Entorno y Configuración del Backend", 1, DORADO)

add_para(
    "La URL del backend Spring Boot se gestiona de dos formas según la plataforma:",
    size=11
)
simple_table(
    headers=["Plataforma", "Mecanismo"],
    rows=[
        ["Android / iOS / Escritorio", "Se guarda en flutter_secure_storage y se lee al arrancar (main.dart)"],
        ["Web (Docker)",               "Se inyecta en compilación via --dart-define=API_BASE_URL=..."],
    ]
)
add_para("Compilar con URL fija en cualquier plataforma:", bold=True)
add_code_block([
    "flutter build apk --release \\",
    "  --dart-define=API_BASE_URL=https://mi-backend.com/api/v1",
    "",
    "flutter build windows --release \\",
    "  --dart-define=API_BASE_URL=https://mi-backend.com/api/v1",
])

page_break()

# =============================================================================
#  10. ÁRBOL DE SALIDA
# =============================================================================
add_heading("10.  Árbol de Salida de cada Build", 1, DORADO)

add_code_block([
    "build/",
    "├── app/",
    "│   └── outputs/",
    "│       ├── flutter-apk/",
    "│       │   ├── app-debug.apk",
    "│       │   ├── app-release.apk",
    "│       │   ├── app-arm64-v8a-release.apk       ← Android modernos",
    "│       │   ├── app-armeabi-v7a-release.apk",
    "│       │   └── app-x86_64-release.apk",
    "│       └── bundle/",
    "│           └── release/",
    "│               └── app-release.aab              ← Para Google Play",
    "│",
    "├── windows/",
    "│   └── x64/runner/Release/                      ← Carpeta distribuible Windows",
    "│       ├── frontend_victorino.exe",
    "│       ├── flutter_windows.dll",
    "│       └── data/...",
    "│",
    "├── linux/",
    "│   └── x64/release/bundle/                      ← Carpeta distribuible Linux",
    "│       ├── frontend_victorino",
    "│       ├── lib/",
    "│       └── data/...",
    "│",
    "└── web/                                         ← Archivos estáticos web",
    "",
    "instalador_windows/",
    "└── VictorinoStyle_Setup_1.0.0.exe               ← Instalador Windows (Inno Setup)",
])

page_break()

# =============================================================================
#  11. PROBLEMAS COMUNES
# =============================================================================
add_heading("11.  Problemas Comunes y Soluciones", 1, DORADO)

# ── 11.1
add_heading("11.1  APK rechazada en Google Play (firma)", 2)
add_note("Problema: release usa signingConfig debug. Google Play no acepta APKs sin keystore propio.", "err")
doc.add_paragraph()
add_para("Solución — Crear y configurar un keystore:", bold=True)
add_code_block([
    "# 1. Crear el keystore",
    "keytool -genkey -v \\",
    "  -keystore victorino-release.jks \\",
    "  -keyalg RSA -keysize 2048 -validity 10000 \\",
    "  -alias victorino",
    "",
    "# 2. Crear android/key.properties  (NO subir a Git)",
    "storePassword=TU_PASSWORD",
    "keyPassword=TU_PASSWORD",
    "keyAlias=victorino",
    "storeFile=../victorino-release.jks",
])

# ── 11.2
add_heading("11.2  Firebase falla en Desktop o Web", 2)
add_note("Problema: UnsupportedError al inicializar Firebase en Windows/Linux.", "err")
doc.add_paragraph()
add_para("Solución — Ya está manejado en main.dart:", bold=True)
add_code_block([
    "// Firebase solo se inicializa en Android/iOS",
    "bool get _soportaFirebase =>",
    "    !kIsWeb && (Platform.isAndroid || Platform.isIOS);",
])
add_note("Firebase se omite automáticamente en escritorio y web. No requiere acción.", "ok")

# ── 11.3
add_heading("11.3  flutter build windows falla con CMake", 2)
add_note("Problema: Visual Studio no tiene el workload correcto.", "err")
doc.add_paragraph()
add_code_block([
    "flutter doctor -v",
    "# Debe aparecer:",
    "# [✓] Visual Studio - develop Windows apps (Visual Studio 2022 17.x)",
])
add_para("Instalar el workload 'Desarrollo de escritorio con C++' en el Visual Studio Installer.", italic=True)

# ── 11.4
add_heading("11.4  flutter build linux falla sin GTK", 2)
add_note("Problema: Could not find package 'gtk+-3.0'", "err")
doc.add_paragraph()
add_code_block(["sudo apt-get install libgtk-3-dev"])

# ── 11.5
add_heading("11.5  Assets vacíos generan error al compilar", 2)
add_note(
    "Problema: Flutter lanza error si alguna carpeta de assets declarada en pubspec.yaml está vacía.",
    "err"
)
doc.add_paragraph()
add_para(
    "Verificar que assets/, assets/logos_app/ y assets/imagenes/ tengan al menos 1 archivo. "
    "El logo logo_app1.3.png debe existir para que flutter_launcher_icons funcione.",
    italic=True
)

# ── 11.6
add_heading("11.6  Inno Setup no encuentra los archivos de Release", 2)
add_note("Problema: Source: 'build\\windows\\x64\\runner\\Release\\*' no existe.", "err")
doc.add_paragraph()
add_para("Solución — Ejecutar flutter build windows --release ANTES de compilar el .iss.", bold=True)

page_break()

# =============================================================================
#  12. FLUJO RÁPIDO DE REFERENCIA
# =============================================================================
add_heading("12.  🚀 Flujo Rápido de Referencia", 1, DORADO)

add_note("Copia estos comandos directamente en tu terminal para cada plataforma.", "info")
doc.add_paragraph()

add_heading("Android APK Release", 2)
add_code_block([
    "flutter pub get",
    "flutter build apk --release --split-per-abi",
    "# → build/app/outputs/flutter-apk/app-arm64-v8a-release.apk",
])
doc.add_paragraph()

add_heading("Windows Ejecutable", 2)
add_code_block([
    "flutter pub get",
    "flutter build windows --release",
    "# → build\\windows\\x64\\runner\\Release\\frontend_victorino.exe",
])
doc.add_paragraph()

add_heading("Instalador Windows (.exe)", 2)
add_code_block([
    'flutter build windows --release',
    '& "C:\\Program Files (x86)\\Inno Setup 6\\ISCC.exe" victorino_setup.iss',
    "# → instalador_windows\\VictorinoStyle_Setup_1.0.0.exe",
])
doc.add_paragraph()

add_heading("Linux Bundle (desde Linux/WSL2)", 2)
add_code_block([
    "flutter pub get",
    "flutter build linux --release",
    "# → build/linux/x64/release/bundle/",
])
doc.add_paragraph()

add_heading("Regenerar Iconos y Splash", 2)
add_code_block([
    "dart run flutter_launcher_icons",
    "dart run flutter_native_splash:create",
])

doc.add_paragraph()
doc.add_paragraph()
p = doc.add_paragraph()
p.alignment = WD_ALIGN_PARAGRAPH.CENTER
run = p.add_run("✂  Victorino Style — Guía generada automáticamente  ✂")
run.font.color.rgb = GRIS_CABEC
run.font.italic = True
run.font.size = Pt(10)

# =============================================================================
#  GUARDAR
# =============================================================================
doc.save(OUTPUT)
print(f"\n✅  Documento generado correctamente:\n   {OUTPUT}\n")

