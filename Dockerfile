# Landing DGE | EDUTEC — sitio 100% estatico, no requiere build step.
# Se sirve con nginx sobre Alpine (imagen final ~77 MB: 74.5 de base + 1.8 del sitio).
FROM nginx:1.27-alpine

# Configuracion propia: gzip, cache, cabeceras de seguridad y /health.
COPY nginx/default.conf /etc/nginx/conf.d/default.conf

# Solo el contenido publico del sitio (se dejan afuera README, guias y scripts).
COPY index.html /usr/share/nginx/html/index.html
COPY css/       /usr/share/nginx/html/css/
COPY js/        /usr/share/nginx/html/js/
COPY img/       /usr/share/nginx/html/img/

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget -q --spider http://127.0.0.1/health || exit 1

CMD ["nginx", "-g", "daemon off;"]
