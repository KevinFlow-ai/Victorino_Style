# =====================================================================
# Landing page de Victorino Style — servida con nginx alpine.
# Página estática, sin build step (HTML + Tailwind CDN + JS vanilla).
#
# Construir localmente:
#   docker build -t victorino-landing .
#   docker run -p 8080:8080 -e PORT=8080 victorino-landing
#
# En Railway: Root Directory = landing_victorino, builder = Dockerfile.
# Genera un dominio público y listo.
# =====================================================================

FROM nginx:alpine

# Copia los archivos estáticos al directorio que sirve nginx.
COPY index.html /usr/share/nginx/html/index.html
COPY assets/   /usr/share/nginx/html/assets/
COPY css/      /usr/share/nginx/html/css/
COPY js/       /usr/share/nginx/html/js/

# Plantilla de configuración. Railway inyecta $PORT y envsubst lo sustituye.
RUN rm -f /etc/nginx/conf.d/default.conf
COPY nginx.conf /etc/nginx/templates/default.conf.template

# Puerto por defecto si no se inyecta PORT (uso local).
ENV PORT=8080
EXPOSE 8080

CMD ["/bin/sh", "-c", "envsubst '$PORT' < /etc/nginx/templates/default.conf.template > /etc/nginx/conf.d/default.conf && nginx -g 'daemon off;'"]
