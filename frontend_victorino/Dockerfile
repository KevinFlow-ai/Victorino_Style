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
# Si no se pasa, cae al default definido en lib/core/api/api_endpoints.dart.
ARG API_BASE_URL
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

    location / {
        try_files $uri $uri/ /index.html;
    }

    # Cache largo para assets versionados de Flutter (con hash en el nombre).
    location ~* \.(?:js|css|woff2?|png|jpg|jpeg|gif|svg|webp|ico)$ {
        expires 30d;
        add_header Cache-Control "public, immutable";
    }

    # index.html nunca cacheado, para que los despliegues se vean al instante.
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
