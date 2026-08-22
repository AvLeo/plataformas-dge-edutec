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
bajo un subpath (ver 5b). Con un subdominio no hace falta definirla.

### 4. Desplegar

Botón **Deploy**. El primer build tarda ~1 minuto (baja la imagen de nginx y
copia los archivos). Los siguientes son casi instantáneos por la cache de capas.

### 5. Publicar el dominio (subdominio — recomendado)

Lo más simple y robusto es darle un subdominio propio, por ejemplo
`plataformas.edutecmza.com`.

**Primero el DNS.** En el panel del dominio, creá un registro:

| Tipo | Nombre | Valor |
|---|---|---|
| `A` | `plataformas` | IP del servidor de Dokploy |

Esperá a que resuelva antes de seguir (`nslookup plataformas.edutecmza.com`).
Si todavía no resuelve, Let's Encrypt no puede emitir el certificado.

**Después, en Dokploy: Domains → Add Domain.**

| Campo | Valor |
|---|---|
| **Host** | `plataformas.edutecmza.com` |
| **Path** | `/` |
| **Strip Path** | desactivado |
| **Internal Path** | vacío |
| **Container Port** | `80` |
| **HTTPS** | activado |
| **Certificate** | `Let's Encrypt` |

**Y en la pestaña Environment: `BASE_PATH` tiene que estar vacío o no existir.**
Si quedó definido de una prueba con subpath, el sitio responde 403 en la raíz
del subdominio. Es el error más fácil de cometer al pasar de subpath a
subdominio.

Notas sobre los campos:

- **Host** es solo el hostname: sin `https://`, sin barra final y sin path.
- **Container Port** es el puerto *dentro* del contenedor, no el del servidor
  ni el 443. Si no es `80`, Traefik responde 502.
- **Strip Path** quita el prefijo antes de reenviar al contenedor, e **Internal
  Path** hace lo contrario (se lo antepone). Con un subdominio no se usa
  ninguno de los dos.

Para una prueba rápida sin tocar DNS, Dokploy ofrece un host `traefik.me` que
resuelve solo a la IP del servidor.

### 5b. Alternativa: subpath (`edutecmza.com/plataformas-dge`)

> **Ojo si el dominio ya tiene otra app.** Si esa app publica un router en
> `edutecmza.com` con `Path /`, puede quedarse con el tráfico antes que la
> regla más específica del subpath, y vas a ver el 404 de la *otra* app.
> Resolverlo implica tocar prioridades de router en Traefik. **Si podés,
> usá un subdominio.**

Campos del dominio: igual que arriba pero con **Host** `edutecmza.com`,
**Path** `/plataformas-dge` y **Strip Path desactivado**.

Además hay que declarar la variable de entorno en **Environment**:

```
BASE_PATH=/plataformas-dge
```

Con barra inicial y **sin** barra final.

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
| `/` (sin `BASE_PATH`) | 200, CSS e imágenes OK |
| `/plataformas-dge/` | 200, CSS e imágenes OK |
| `/plataformas-dge` | 301 → `/plataformas-dge/`, luego 200 |

### 5c. Si el dominio está detrás de Cloudflare

Se detecta mirando las cabeceras de la respuesta: si aparecen `server: cloudflare`
y `cf-ray`, el tráfico pasa por Cloudflare antes de llegar al servidor.

**Mientras configurás, poné el registro en "DNS only" (nube gris).** Quita una
capa del medio, deja que Let's Encrypt valide directo contra el servidor y evita
el problema clásico del SSL mode **Flexible** (Cloudflare habla HTTP al origin,
Traefik redirige a HTTPS y se arma un loop de redirects). Una vez que el sitio
carga bien por HTTPS, se puede volver a activar el proxy con SSL/TLS mode en
**Full (strict)**.

**Con la nube naranja activada, el candado del navegador es el de Cloudflare**,
no el de Let's Encrypt. Que el certificado se vea OK no prueba que Traefik haya
emitido el suyo ni que el ruteo funcione: se puede tener certificado válido y
404 al mismo tiempo.

Para probar el origin salteando Cloudflare:

```bash
curl -skI --resolve tu.dominio.com:443:IP_DEL_SERVIDOR https://tu.dominio.com/
```

Si por ahí responde 200 pero por Cloudflare da 404, el registro DNS está
apuntando a otro origin (o no existe y está resolviendo por un wildcard `*`).

### 5d. De quién es el 404

Distinguirlos ahorra tiempo, porque cada uno se arregla en un lugar distinto:

| Respuesta | Quién contesta | Dónde mirar |
|---|---|---|
| `text/plain`, 19 bytes, `404 page not found` | **Traefik**: ningún router matchea el Host o el Path | Dokploy: que el servicio esté corriendo y el dominio bien cargado |
| HTML con `server: nginx` | **El contenedor**: la ruta no existe puertas adentro | `BASE_PATH`, o la ruta pedida |
| Página HTML con marca de Cloudflare | **Cloudflare**: no llegó al origin | DNS del registro |

Ojo: con la nube naranja, Cloudflare reescribe la cabecera `server`. Un 404 de
Traefik proxeado llega con `server: cloudflare` pero conserva el cuerpo de
19 bytes en `text/plain` — el tamaño es la pista, no el `server`.

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
| La página carga sin estilos ni imágenes | En subpath: falta `BASE_PATH`, o **Strip Path** quedó activado. Ver 5b. |
| 403 en la raíz del (sub)dominio | Quedó `BASE_PATH` definido de una prueba con subpath. Borralo de **Environment** y redesplegá. |
| Cae en el 404 de otra app del mismo dominio | Otro router de Traefik se quedó con el host. Usá un subdominio (ver 5). |
| 404 de 19 bytes en `text/plain` | Es de Traefik: no hay router para ese host. Ver 5d. |
| Certificado OK pero 404 | Si hay Cloudflare, el candado es suyo y no dice nada del origin. Ver 5c. |
| Loop de redirects (`ERR_TOO_MANY_REDIRECTS`) | SSL mode de Cloudflare en *Flexible*. Pasalo a *Full (strict)*. Ver 5c. |
| El contenedor reinicia en loop | Ver **Logs** en Dokploy; `nginx -t` corre en el arranque. |

## Actualizar la versión de nginx

Está fijada en el `Dockerfile` (`FROM nginx:1.27-alpine`) para que los builds
sean reproducibles. Para subirla, cambiá esa línea y redesplegá.
