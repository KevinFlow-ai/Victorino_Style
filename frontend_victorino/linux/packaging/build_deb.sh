#!/bin/bash
# =============================================================================
#  build_deb.sh — Genera victorino-style_1.0.0_amd64.deb
#  Uso (en Linux):  bash linux/packaging/build_deb.sh
# =============================================================================
set -e
ROOT=$(cd "$(dirname "$0")/../.." && pwd)
VERSION="1.0.0"
PKG="victorino-style"
ARCH="amd64"
BUNDLE="$ROOT/build/linux/x64/release/bundle"
DEB_STAGE="$ROOT/build/linux/deb/${PKG}_${VERSION}_${ARCH}"
OUT="$ROOT/${PKG}_${VERSION}_${ARCH}.deb"
# ── 1. Compilar ──────────────────────────────────────────────────────────────
echo "==> [1/5] flutter build linux --release"
cd "$ROOT"
flutter build linux --release
# ── 2. Estructura del paquete ─────────────────────────────────────────────────
echo "==> [2/5] Creando estructura del .deb"
rm -rf "$DEB_STAGE"
mkdir -p "$DEB_STAGE/DEBIAN"
mkdir -p "$DEB_STAGE/opt/victorino-style"
mkdir -p "$DEB_STAGE/usr/share/applications"
mkdir -p "$DEB_STAGE/usr/share/icons/hicolor"
# Copiar bundle completo (binario + librerías + flutter_assets)
# El icono de la ventana se carga desde data/flutter_assets/assets/logos_app/logo_app1.3.png
cp -r "$BUNDLE/." "$DEB_STAGE/opt/victorino-style/"
# ── 3. Iconos XDG (hicolor) ──────────────────────────────────────────────────
echo "==> [3/5] Instalando iconos XDG hicolor (9 tamanios)"
ICON_SRC="$ROOT/linux/packaging/icons"
for dir in "$ICON_SRC"/*/; do
  size=$(basename "$dir")
  dest="$DEB_STAGE/usr/share/icons/hicolor/$size/apps"
  mkdir -p "$dest"
  cp "$dir/apps/victorino_style.png" "$dest/"
done
# ── 4. .desktop + scripts DEBIAN ─────────────────────────────────────────────
echo "==> [4/5] Copiando metadatos del paquete"
cp "$ROOT/linux/packaging/victorino-style.desktop" \
   "$DEB_STAGE/usr/share/applications/"
cp "$ROOT/linux/packaging/debian/control"  "$DEB_STAGE/DEBIAN/control"
cp "$ROOT/linux/packaging/debian/postinst" "$DEB_STAGE/DEBIAN/postinst"
cp "$ROOT/linux/packaging/debian/postrm"   "$DEB_STAGE/DEBIAN/postrm"
# ── Permisos ──────────────────────────────────────────────────────────────────
find "$DEB_STAGE" -type d -exec chmod 755 {} \;
find "$DEB_STAGE" -type f -exec chmod 644 {} \;
chmod 755 "$DEB_STAGE/opt/victorino-style/frontend_victorino"
chmod 755 "$DEB_STAGE/DEBIAN/postinst"
chmod 755 "$DEB_STAGE/DEBIAN/postrm"
# ── 5. Generar .deb ───────────────────────────────────────────────────────────
echo "==> [5/5] Empaquetando con dpkg-deb"
dpkg-deb --build --root-owner-group "$DEB_STAGE" "$OUT"
echo ""
echo "LISTO: $OUT"
echo "Instalar con:  sudo dpkg -i $OUT && sudo apt-get install -f"