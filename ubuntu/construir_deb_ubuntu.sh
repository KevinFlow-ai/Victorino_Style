#!/bin/bash
# =====================================================================
#  VictorinoStyle — Compilar para Linux y generar paquete .deb
#  Ejecuta este script DENTRO de la carpeta frontend_victorino en Ubuntu
#  Uso: chmod +x construir_deb_ubuntu.sh && ./construir_deb_ubuntu.sh
# =====================================================================

set -e  # Parar si cualquier comando falla

APP_NAME="victorino-style"
APP_NOMBRE_DISPLAY="VictorinoStyle"
VERSION="1.0.0"
ARCH="amd64"
BINARIO="frontend_victorino"
PROYECTO_DIR="$(cd "$(dirname "$0")" && pwd)"
DEB_DIR="/tmp/${APP_NAME}_${VERSION}_${ARCH}"
FLUTTER_DIR="$HOME/flutter"
FLUTTER_BIN="$FLUTTER_DIR/bin/flutter"

echo ""
echo "██╗   ██╗██╗ ██████╗████████╗ ██████╗ ██████╗ ██╗███╗   ██╗ ██████╗"
echo "██║   ██║██║██╔════╝╚══██╔══╝██╔═══██╗██╔══██╗██║████╗  ██║██╔═══██╗"
echo "██║   ██║██║██║        ██║   ██║   ██║██████╔╝██║██╔██╗ ██║██║   ██║"
echo "╚██╗ ██╔╝██║██║        ██║   ██║   ██║██╔══██╗██║██║╚██╗██║██║   ██║"
echo " ╚████╔╝ ██║╚██████╗   ██║   ╚██████╔╝██║  ██║██║██║ ╚████║╚██████╔╝"
echo "  ╚═══╝  ╚═╝ ╚═════╝   ╚═╝    ╚═════╝ ╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝ ╚═════╝"
echo ""
echo "  Generador de paquete .deb para Ubuntu/Debian"
echo "  Versión: $VERSION | Arquitectura: $ARCH"
echo "=================================================================="
echo ""

# ------------------------------------------------------------------
# 1. INSTALAR DEPENDENCIAS DEL SISTEMA
# ------------------------------------------------------------------
echo "[1/6] Instalando dependencias del sistema..."
sudo apt-get update -qq
sudo apt-get install -y \
    curl git unzip xz-utils zip \
    clang cmake ninja-build pkg-config \
    libgtk-3-dev liblzma-dev \
    libstdc++-12-dev \
    dpkg-dev \
    2>/dev/null | grep -E "(Setting up|already)" || true

echo "  ✔ Dependencias instaladas"

# ------------------------------------------------------------------
# 2. INSTALAR FLUTTER SDK (si no está instalado)
# ------------------------------------------------------------------
echo ""
echo "[2/6] Verificando Flutter SDK..."

if [ ! -f "$FLUTTER_BIN" ]; then
    echo "  Flutter no encontrado. Descargando Flutter SDK estable..."
    cd "$HOME"

    # Obtener la última versión estable
    FLUTTER_VERSION=$(curl -s https://storage.googleapis.com/flutter_infra_release/releases/releases_linux.json \
        | python3 -c "import sys,json; data=json.load(sys.stdin); \
          stable=[r for r in data['releases'] if r['channel']=='stable']; \
          print(stable[0]['version'])" 2>/dev/null || echo "3.32.0")

    echo "  Descargando Flutter $FLUTTER_VERSION..."
    curl -fsSL "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz" \
        -o /tmp/flutter.tar.xz

    tar xf /tmp/flutter.tar.xz -C "$HOME"
    rm /tmp/flutter.tar.xz

    # Añadir Flutter al PATH de forma permanente
    echo 'export PATH="$PATH:$HOME/flutter/bin"' >> "$HOME/.bashrc"
    export PATH="$PATH:$HOME/flutter/bin"

    echo "  ✔ Flutter SDK instalado en $FLUTTER_DIR"
else
    export PATH="$PATH:$FLUTTER_DIR/bin"
    FLUTTER_VERSION=$($FLUTTER_BIN --version 2>/dev/null | grep "Flutter" | awk '{print $2}')
    echo "  ✔ Flutter ya instalado: $FLUTTER_VERSION"
fi

# Aceptar licencias de Android SDK (no necesario para Linux, pero evita prompts)
$FLUTTER_BIN config --no-analytics 2>/dev/null || true

# ------------------------------------------------------------------
# 3. OBTENER DEPENDENCIAS DEL PROYECTO
# ------------------------------------------------------------------
echo ""
echo "[3/6] Obteniendo dependencias del proyecto Flutter..."
cd "$PROYECTO_DIR"

$FLUTTER_BIN pub get
echo "  ✔ Dependencias obtenidas"

# ------------------------------------------------------------------
# 4. COMPILAR RELEASE PARA LINUX
# ------------------------------------------------------------------
echo ""
echo "[4/6] Compilando release para Linux (esto puede tardar varios minutos)..."
cd "$PROYECTO_DIR"

$FLUTTER_BIN build linux --release

BUILD_BUNDLE="$PROYECTO_DIR/build/linux/x64/release/bundle"

if [ ! -d "$BUILD_BUNDLE" ]; then
    echo "  ✖ ERROR: No se encontró el bundle en $BUILD_BUNDLE"
    echo "    Intenta buscar en: $(find $PROYECTO_DIR/build/linux -name 'bundle' -type d 2>/dev/null | head -3)"
    exit 1
fi

echo "  ✔ Compilación completada: $BUILD_BUNDLE"

# ------------------------------------------------------------------
# 5. CONSTRUIR ESTRUCTURA DEL PAQUETE .DEB
# ------------------------------------------------------------------
echo ""
echo "[5/6] Construyendo estructura del paquete .deb..."

# Limpiar estructura anterior
rm -rf "$DEB_DIR"
mkdir -p "$DEB_DIR/DEBIAN"
mkdir -p "$DEB_DIR/opt/$APP_NAME"
mkdir -p "$DEB_DIR/usr/share/applications"
mkdir -p "$DEB_DIR/usr/share/pixmaps"
mkdir -p "$DEB_DIR/usr/local/bin"

# --- Copiar el bundle compilado ---
cp -r "$BUILD_BUNDLE/." "$DEB_DIR/opt/$APP_NAME/"

# --- Copiar icono de la app ---
ICONO_ORIGEN="$PROYECTO_DIR/assets/logos_app/logo_app.png"
if [ -f "$ICONO_ORIGEN" ]; then
    cp "$ICONO_ORIGEN" "$DEB_DIR/usr/share/pixmaps/$APP_NAME.png"
    echo "  ✔ Icono copiado"
else
    # Crear icono placeholder si no existe
    echo "  ⚠ Icono no encontrado en $ICONO_ORIGEN, continuando sin icono personalizado"
fi

# --- Crear lanzador .desktop ---
cat > "$DEB_DIR/usr/share/applications/$APP_NAME.desktop" << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=$APP_NOMBRE_DISPLAY
Comment=Gestión de citas y barbería VictorinoStyle
Exec=/opt/$APP_NAME/$BINARIO
Icon=$APP_NAME
Categories=Utility;Office;
StartupWMClass=$APP_NOMBRE_DISPLAY
Terminal=false
EOF

# --- Crear symlink en /usr/local/bin ---
ln -sf "/opt/$APP_NAME/$BINARIO" "$DEB_DIR/usr/local/bin/$APP_NAME"

# --- Crear script postinst (actualizar base de datos de escritorio) ---
cat > "$DEB_DIR/DEBIAN/postinst" << 'EOF'
#!/bin/bash
update-desktop-database /usr/share/applications/ 2>/dev/null || true
EOF
chmod 755 "$DEB_DIR/DEBIAN/postinst"

# --- Crear script postrm (limpiar al desinstalar) ---
cat > "$DEB_DIR/DEBIAN/postrm" << 'EOF'
#!/bin/bash
update-desktop-database /usr/share/applications/ 2>/dev/null || true
EOF
chmod 755 "$DEB_DIR/DEBIAN/postrm"

# --- Calcular tamaño instalado ---
INSTALLED_SIZE=$(du -sk "$DEB_DIR/opt" | cut -f1)

# --- Crear archivo control (metadatos del paquete) ---
cat > "$DEB_DIR/DEBIAN/control" << EOF
Package: $APP_NAME
Version: $VERSION
Section: utils
Priority: optional
Architecture: $ARCH
Installed-Size: $INSTALLED_SIZE
Maintainer: VictorinoStyle TFG <peluqueria.victorinostyle@gmail.com>
Description: VictorinoStyle - Gestión de barbería
 Aplicación de escritorio para la gestión de citas,
 empleados, servicios y configuración de la barbería
 VictorinoStyle. Desarrollado con Flutter.
 .
 TFG 2DAM 2025/2026
Depends: libgtk-3-0, libblkid1, liblzma5
Homepage: https://github.com/victorino-style
EOF

echo "  ✔ Estructura del paquete creada"

# Fijar permisos correctos
find "$DEB_DIR" -type d -exec chmod 755 {} \;
find "$DEB_DIR" -type f -exec chmod 644 {} \;
chmod 755 "$DEB_DIR/opt/$APP_NAME/$BINARIO"
chmod 755 "$DEB_DIR/DEBIAN/postinst"
chmod 755 "$DEB_DIR/DEBIAN/postrm"
chmod 644 "$DEB_DIR/DEBIAN/control"

# ------------------------------------------------------------------
# 6. GENERAR EL ARCHIVO .DEB
# ------------------------------------------------------------------
echo ""
echo "[6/6] Generando el paquete .deb..."

DEB_SALIDA="$PROYECTO_DIR/${APP_NAME}_${VERSION}_${ARCH}.deb"
dpkg-deb --build --root-owner-group "$DEB_DIR" "$DEB_SALIDA"

if [ -f "$DEB_SALIDA" ]; then
    TAMANO=$(du -sh "$DEB_SALIDA" | cut -f1)
    echo ""
    echo "=================================================================="
    echo "  ✔  PAQUETE .DEB GENERADO CORRECTAMENTE"
    echo "=================================================================="
    echo "  Archivo:  $DEB_SALIDA"
    echo "  Tamaño:   $TAMANO"
    echo ""
    echo "  Para instalar en Ubuntu:"
    echo "    sudo dpkg -i ${APP_NAME}_${VERSION}_${ARCH}.deb"
    echo ""
    echo "  Para desinstalar:"
    echo "    sudo dpkg -r $APP_NAME"
    echo ""
    echo "  Para verificar el paquete:"
    echo "    dpkg -I ${APP_NAME}_${VERSION}_${ARCH}.deb"
    echo "=================================================================="
else
    echo "  ✖ ERROR: No se pudo generar el .deb"
    exit 1
fi

# Limpiar carpeta temporal
rm -rf "$DEB_DIR"
echo ""
echo "  Carpeta temporal eliminada."
echo ""

