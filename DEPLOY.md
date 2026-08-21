# Deploy en Dokploy

La landing es un sitio **100% estático** (HTML + CSS + JS, sin build ni
dependencias). Se despliega con el `Dockerfile` de este repo, que la sirve
con **nginx** sobre Alpine.

## Archivos que intervienen

| Archivo              | Para qué sirve                                              |
|----------------------|-------------------------------------------------------------|
| `Dockerfile`         | Copia el sitio dentro de una imagen nginx. Sin build step.   |
| `nginx/default.conf` | gzip, cache, cabeceras de seguridad y endpoint `/health`.    |
| `.dockerignore`      | Deja fuera `.git`, README, `process.ps1`, etc.               |
| `docker-compose.yml` | Solo si se despliega como servicio *Compose* en vez de *Application*. |

---

## Pasos en Dokploy (tipo Application — recomendado)

### 1. Crear el proyecto y el servicio

1. En el panel de Dokploy: **Projects → Create Project** (ej. `dge-edutec`).
2. Dentro del proyecto: **Create Service → Application**.
3. Nombre: `landing-plataformas`.

### 2. Conectar el repositorio

En la pestaña **Provider** del servicio:

- **GitHub** si ya vinculaste la app de GitHub en *Settings → Git*, o
- **Git** genérico pegando la URL del repo.

Después:

- **Repository:** `AvLeo/plataformas-dge-edutec`
- **Branch:** `main`

### 3. Configurar el build

En la pestaña **Build Type**:

- Tipo: **Dockerfile**
- **Dockerfile Path:** `Dockerfile`
- **Docker Context Path:** `.` (o vacío)

No hacen falta variables de entorno: el sitio no usa ninguna.

### 4. Desplegar

Botón **Deploy**. El primer build tarda ~1 minuto (baja la imagen de nginx y
copia los archivos). Los siguientes son casi instantáneos por la cache de capas.

### 5. Publicar el dominio

En la pestaña **Domains → Add Domain**:

- **Host:** el dominio que vayas a usar (ej. `plataformas.mendoza.edu.ar`)
- **Path:** `/`
- **Container Port:** `80`  ← importante, es el puerto que expone nginx
- **HTTPS:** activado
- **Certificate:** `Let's Encrypt`

> Antes de generar el certificado, el dominio tiene que apuntar por DNS
> (registro `A`) a la IP del servidor de Dokploy. Si no resuelve todavía,
> Let's Encrypt falla y hay que reintentar desde el mismo panel.

Para una prueba rápida sin dominio propio, Dokploy ofrece un host `traefik.me`
que resuelve solo a la IP del servidor.

### 6. Auto-deploy en cada push (opcional)

En la pestaña **Deployments** copiá la **Webhook URL** y pegala en GitHub:
**Settings → Webhooks → Add webhook**, con content type `application/json`
y el evento *push*. Desde ahí, cada push a `main` redespliega solo.

Si conectaste el repo con la app de GitHub, alcanza con activar
**Auto Deploy** en el servicio.

---

## Alternativa: tipo Compose

Si preferís el servicio de tipo **Compose**, este repo trae un
`docker-compose.yml` listo. En Dokploy: **Create Service → Compose**, apuntá al
repo y a `docker-compose.yml`; en **Domains** elegí el servicio `landing` con
puerto `80`.

## Alternativa: tipo Static

Dokploy también tiene un build type **Static** que sirve una carpeta con nginx
sin necesidad de Dockerfile (publish directory: `.`). Es más rápido de
configurar, pero perdés el control sobre gzip, cache y cabeceras que da
`nginx/default.conf`.

---

## Qué hace la configuración de nginx

- **gzip**: el CSS baja de 21 KB a ~4.9 KB.
- **Cache:** el HTML se sirve con `no-cache` (los cambios se ven al instante
  tras un deploy); CSS y JS 7 días; imágenes 30 días.
- **Cabeceras de seguridad:** `X-Content-Type-Options`, `X-Frame-Options`,
  `Referrer-Policy`, `Permissions-Policy`.
- **UTF-8 explícito** en HTML, CSS y JS (el sitio está en español).
- **`/health`**: devuelve `200 ok`. Lo usa el `HEALTHCHECK` del contenedor,
  y sirve para monitoreo externo.

## Probar localmente antes de subir

```bash
docker build -t edutec-landing .
docker run --rm -p 8080:80 edutec-landing
# abrir http://localhost:8080
```

## Diagnóstico

| Síntoma | Causa habitual |
|---|---|
| 502 Bad Gateway desde Traefik | El **Container Port** del dominio no es `80`. |
| El certificado no se emite | El DNS del dominio todavía no apunta al servidor. |
| Se ve la versión vieja tras un deploy | Cache del navegador: `Ctrl+F5`. El HTML se sirve `no-cache`, pero CSS/JS tienen 7 días. |
| El contenedor reinicia en loop | Ver **Logs** en Dokploy; `nginx -t` corre en el arranque. |

## Actualizar la versión de nginx

Está fijada en el `Dockerfile` (`FROM nginx:1.27-alpine`) para que los builds
sean reproducibles. Para subirla, cambiá esa línea y redesplegá.
