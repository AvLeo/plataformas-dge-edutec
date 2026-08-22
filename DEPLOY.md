# Deploy en Dokploy

La landing es un sitio **100% estático** (HTML + CSS + JS, sin build ni
dependencias). Se despliega con el `Dockerfile` de este repo, que la sirve
con **nginx** sobre Alpine.

## Archivos que intervienen

| Archivo              | Para qué sirve                                              |
|----------------------|-------------------------------------------------------------|
| `Dockerfile`         | Copia el sitio dentro de una imagen nginx. Sin build step.   |
| `nginx/default.conf.template` | gzip, cache, cabeceras de seguridad, `/health` y el prefijo `BASE_PATH`. |
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

La única variable de entorno es **`BASE_PATH`**, y solo si publicás el sitio
bajo un subpath (ver 5b). En la raíz del dominio no hace falta definirla.

### 4. Desplegar

Botón **Deploy**. El primer build tarda ~1 minuto (baja la imagen de nginx y
copia los archivos). Los siguientes son casi instantáneos por la cache de capas.

### 5. Publicar el dominio

En la pestaña **Domains → Add Domain**. Los campos y qué poner en cada uno:

| Campo | En la raíz del dominio | Bajo un subpath |
|---|---|---|
| **Host** | `edutecmza.com` | `edutecmza.com` |
| **Path** | `/` | `/plataformas-dge` |
| **Strip Path** | desactivado | **desactivado** |
| **Internal Path** | vacío | vacío |
| **Container Port** | `80` | `80` |
| **HTTPS** | activado | activado |
| **Certificate** | `Let's Encrypt` | `Let's Encrypt` |

**Host** es solo el hostname: sin `https://`, sin barra final y sin path.

**Container Port** es el puerto *dentro* del contenedor, no el del servidor ni
el 443. Si no es `80`, Traefik responde 502.

**Strip Path** quita el prefijo antes de reenviar al contenedor, e **Internal
Path** hace lo contrario (se lo antepone). Acá no se usa ninguno de los dos:
del prefijo se encarga nginx mediante `BASE_PATH` (ver abajo).

> Antes de generar el certificado, el dominio tiene que apuntar por DNS
> (registro `A`) a la IP del servidor de Dokploy. Si no resuelve todavía,
> Let's Encrypt falla y hay que reintentar desde el mismo panel.

Para una prueba rápida sin dominio propio, Dokploy ofrece un host `traefik.me`
que resuelve solo a la IP del servidor.

### 5b. Publicar bajo un subpath (ej. `edutecmza.com/plataformas-dge`)

Además del **Path** de la tabla de arriba, hay que declarar la variable de
entorno en la pestaña **Environment** del servicio:

```
BASE_PATH=/plataformas-dge
```

Con barra inicial y **sin** barra final. Dejala vacía (o no la definas) para
servir en la raíz del dominio.

#### Por qué hace falta, y por qué Strip Path va desactivado

`index.html` usa rutas **relativas** (`css/style.css`, `img/…`), que el
navegador resuelve contra la URL de la página. Si el sitio se sirve en
`/plataformas-dge` **sin barra final**, el navegador toma como base la raíz del
dominio y va a buscar `edutecmza.com/css/style.css`, que no existe: la página
carga pero sin estilos ni imágenes.

La solución es que nginx vea la ruta pública completa y emita él mismo el
redirect `301 /plataformas-dge → /plataformas-dge/`. Por eso **Strip Path
queda desactivado**: si Traefik borrara el prefijo, nginx no podría armar ese
redirect. El redirect usa `absolute_redirect off`, así el `Location` sale
relativo y no degrada de HTTPS a HTTP al pasar por Traefik.

Verificado sobre el contenedor real, en los dos modos:

| URL | Resultado |
|---|---|
| `/` (BASE_PATH vacío) | 200, CSS e imágenes OK |
| `/plataformas-dge/` | 200, CSS e imágenes OK |
| `/plataformas-dge` | 301 → `/plataformas-dge/`, luego 200 |

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
configurar, pero perdés lo que aporta `nginx/default.conf.template`: gzip,
cache, cabeceras de seguridad y —lo importante acá— el manejo de `BASE_PATH`
con su redirect a la barra final. **No lo uses si vas a publicar bajo un
subpath.**

---

## Qué hace la configuración de nginx

- **gzip**: el CSS baja de 21 KB a ~4.9 KB.
- **Cache:** por tipo de contenido, no por ruta (así funciona igual en la raíz
  y bajo un subpath). HTML `no-cache` (los cambios se ven al instante tras un
  deploy); CSS y JS 7 días; imágenes 30 días.
- **Cabeceras de seguridad:** `X-Content-Type-Options`, `X-Frame-Options`,
  `Referrer-Policy`, `Permissions-Policy`.
- **UTF-8 explícito** en HTML, CSS y JS (el sitio está en español).
- **`/health`**: devuelve `200 ok`. Lo usa el `HEALTHCHECK` del contenedor
  (por `127.0.0.1`), así que queda siempre en la raíz, sin importar `BASE_PATH`.

## Probar localmente antes de subir

```bash
docker build -t edutec-landing .

# en la raiz
docker run --rm -p 8080:80 edutec-landing
# -> http://localhost:8080

# bajo subpath
docker run --rm -p 8080:80 -e BASE_PATH=/plataformas-dge edutec-landing
# -> http://localhost:8080/plataformas-dge/
```

## Diagnóstico

| Síntoma | Causa habitual |
|---|---|
| 502 Bad Gateway desde Traefik | El **Container Port** del dominio no es `80`. |
| El certificado no se emite | El DNS del dominio todavía no apunta al servidor. |
| Se ve la versión vieja tras un deploy | Cache del navegador: `Ctrl+F5`. El HTML se sirve `no-cache`, pero CSS/JS tienen 7 días. |
| La página carga sin estilos ni imágenes | Falta `BASE_PATH`, o **Strip Path** quedó activado. Ver 5b. |
| El contenedor reinicia en loop | Ver **Logs** en Dokploy; `nginx -t` corre en el arranque. |

## Actualizar la versión de nginx

Está fijada en el `Dockerfile` (`FROM nginx:1.27-alpine`) para que los builds
sean reproducibles. Para subirla, cambiá esa línea y redesplegá.
