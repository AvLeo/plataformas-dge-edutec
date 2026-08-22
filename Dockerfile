# Landing DGE | EDUTEC — sitio 100% estatico, no requiere build step.
# Se sirve con nginx sobre Alpine (imagen final ~77 MB: 74.5 de base + 1.8 del sitio).
FROM nginx:1.27-alpine

# Ruta bajo la que se publica el sitio. Vacio = raiz del dominio.
# Para servir en https://dominio/plataformas-dge -> BASE_PATH=/plataformas-dge
# (sin barra final). Se define como variable de entorno en Dokploy.
ENV BASE_PATH=""

# Que envsubst sustituya SOLO esta variable y no toque las de nginx
# ($uri, $args, $sent_http_content_type...).
ENV NGINX_ENVSUBST_FILTER="BASE_PATH"

# El entrypoint de la imagen procesa /etc/nginx/templates/*.template
# con envsubst y escribe el resultado en /etc/nginx/conf.d/.
COPY nginx/default.conf.template /etc/nginx/templates/default.conf.template

# Directorio vacio que usa el `root` del server (ver default.conf.template).
RUN mkdir -p /usr/share/nginx/empty

# Solo el contenido publico del sitio (se dejan afuera README, guias y scripts).
COPY index.html /usr/share/nginx/html/index.html
COPY css/       /usr/share/nginx/html/css/
COPY js/        /usr/share/nginx/html/js/
COPY img/       /usr/share/nginx/html/img/

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget -q --spider http://127.0.0.1/health || exit 1

CMD ["nginx", "-g", "daemon off;"]
