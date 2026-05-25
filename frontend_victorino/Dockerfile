# =====================================================================
# Dockerfile multi-etapa para servir el frontend Flutter Web en Railway.
# - Etapa 1 (build): compila la app con Flutter Web e inyecta API_BASE_URL.
# - Etapa 2 (runtime): sirve los assets estaticos con nginx.
#
# Construir localmente:
#   docker build --build-arg API_BASE_URL=http://localhost:8080/api/v1 -t victorino-frontend .
#   docker run -p 8080:8080 -e PORT=8080 victorino-frontend
#
# En Railway, configurar Build Arg:
#   API_BASE_URL=https://victorino-backend-production.up.railway.app/api/v1
# =====================================================================

# ---------------------------------------------------------------------
# Etapa 1: build de Flutter Web
# ---------------------------------------------------------------------
FROM ghcr.io/cirruslabs/flutter:3.41.2 AS build

WORKDIR /app

# Copia primero solo los manifiestos para cachear pub get cuando no cambian deps.
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

# Copia el resto del proyecto y compila.
COPY . .

# La URL del backend se inyecta en tiempo de compilacion via --dart-define.
# El default `http://localhost:8080/api/v1` es el que usa el docker-compose
# local (entrega del TFG al tribunal). En el build de Railway se pasa la
# URL publica con `--build-arg API_BASE_URL=https://...`.
ARG API_BASE_URL=http://localhost:8080/api/v1
RUN flutter build web --release \
    --dart-define=API_BASE_URL=${API_BASE_URL}

# ---------------------------------------------------------------------
# Etapa 2: nginx alpine sirviendo los assets compilados
# ---------------------------------------------------------------------
FROM nginx:alpine

# Copia el build de Flutter Web al directorio que sirve nginx.
COPY --from=build /app/build/web /usr/share/nginx/html

# Plantilla de nginx que escucha en el puerto que Railway inyecte via $PORT.
# El "try_files" hace fallback a index.html para que las rutas de GoRouter
# (cliente-side routing) sigan funcionando al refrescar el navegador.
RUN rm -f /etc/nginx/conf.d/default.conf
COPY <<'EOF' /etc/nginx/templates/default.conf.template
server {
    listen       ${PORT};
    listen       [::]:${PORT};
    server_name  _;

    root   /usr/share/nginx/html;
    index  index.html;

    # ETag automatico para que las revalidaciones (304 Not Modified) funcionen
    # bien con los archivos de Flutter que comparten nombre entre deploys.
    etag on;

    location / {
        try_files $uri $uri/ /index.html;
    }

    # ─── Archivos de Flutter con nombre FIJO entre deploys ────────────────────
    # main.dart.js (~4 MB), flutter_bootstrap.js, etc. mantienen el mismo
    # nombre cada vez que se hace `flutter build web`, pero su contenido
    # CAMBIA con cada despliegue. Si los marcamos como "immutable" el
    # navegador se queda con la version antigua hasta 30 dias.
    #
    # Solucion: "no-cache, must-revalidate". El navegador conserva la caché
    # pero envia un If-None-Match con el ETag al servidor antes de usarla.
    # - Si el archivo no cambio: nginx responde 304 Not Modified (~100 bytes)
    #   y el navegador usa la cache. Practicamente igual de rapido que
    #   "immutable" (un round-trip diminuto).
    # - Si el archivo cambio: nginx envia la version nueva.
    location ~* ^/(main\.dart\.js|flutter_bootstrap\.js|flutter\.js|flutter_service_worker\.js|manifest\.json|version\.json)$ {
        expires off;
        add_header Cache-Control "public, no-cache, must-revalidate";
    }

    # ─── Assets versionados o estables (fuentes, imagenes embebidas) ─────────
    # Los archivos bajo /assets/ son los recursos compilados por Flutter:
    # FontManifest.json, AssetManifest.bin.json, fuentes Material/Cupertino/
    # FontAwesome, imagenes en assets/imagenes/ y assets/logos_app/, etc.
    # Cambian solo cuando se modifican los assets fuente, no en cada deploy
    # rutinario → cachear 30 dias como immutable es seguro y muy rapido.
    location ~* ^/assets/ {
        expires 30d;
        add_header Cache-Control "public, immutable";
    }

    # ─── Iconos PWA (manifest.json los referencia) ───────────────────────────
    location ~* ^/icons/ {
        expires 7d;
        add_header Cache-Control "public, max-age=604800";
    }

    # ─── favicon ─────────────────────────────────────────────────────────────
    location = /favicon.png {
        expires 7d;
        add_header Cache-Control "public, max-age=604800";
    }

    # ─── index.html ──────────────────────────────────────────────────────────
    # Nunca cachear el punto de entrada: ası el navegador siempre carga el
    # bootstrap mas reciente y a partir de ahi revalida los JS de Flutter.
    location = /index.html {
        add_header Cache-Control "no-store, no-cache, must-revalidate";
    }
}
EOF

# Variable por defecto del puerto si Railway no inyecta PORT (p.ej. en local).
ENV PORT=8080
EXPOSE 8080

# envsubst sustituye ${PORT} en la plantilla y arranca nginx en foreground.
CMD ["/bin/sh", "-c", "envsubst '$PORT' < /etc/nginx/templates/default.conf.template > /etc/nginx/conf.d/default.conf && nginx -g 'daemon off;'"]
