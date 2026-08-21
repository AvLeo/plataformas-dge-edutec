# Landing Page DGE | EDUTEC

Este proyecto es la página de inicio (Landing Page) institucional para las plataformas digitales de la Dirección General de Escuelas (DGE) y el programa EDUTEC del Gobierno de Mendoza. Está diseñado para ser utilizado como página de inicio predeterminada en dispositivos administrados (ej. vía Intune), ofreciendo acceso rápido y centralizado a diversas plataformas educativas.

## Estructura del Proyecto

El proyecto está construido 100% con tecnologías estáticas, sin dependencias externas, listo para ser alojado en cualquier servidor web estándar o GitHub Pages.

```text
/
├── index.html       # Archivo principal y estructura de la página
├── css/
│   └── style.css    # Hojas de estilo y diseño interactivo
├── js/
│   └── app.js       # Lógica del frontend (Cursor, Modales)
├── img/             # Carpeta de imágenes, logos y SVGs
└── README.md        # Documentación del proyecto
```

## Tecnologías Utilizadas

- **HTML5:** Estructura semántica.
- **CSS3:** Estilos, animaciones, variables nativas, efecto visual "Glassmorphism" e iconos embebidos.
- **Vanilla JavaScript (JS):** Interactividad fluida (modal interactivo, y cursores presonalizados estilo spotlight) a 60fps sin librerías externas.

---

## 🐳 Cómo desplegar en Dokploy

El repo incluye `Dockerfile`, `nginx/default.conf.template` y `docker-compose.yml` para
desplegar la landing en un servidor propio con [Dokploy](https://dokploy.com/).

Resumen: **Create Service → Application**, conectar este repo, build type
**Dockerfile**, y en **Domains** publicar el dominio con **Container Port `80`**.

Para servirlo bajo un subpath (ej. `edutecmza.com/plataformas-dge`), definí la
variable de entorno `BASE_PATH=/plataformas-dge` y dejá **Strip Path**
desactivado.

👉 Pasos detallados, opciones alternativas y diagnóstico en **[DEPLOY.md](DEPLOY.md)**.

Prueba local:

```bash
docker build -t edutec-landing .
docker run --rm -p 8080:80 edutec-landing   # http://localhost:8080
docker run --rm -p 8080:80 -e BASE_PATH=/plataformas-dge edutec-landing
```

---

## 🚀 Cómo subir este proyecto a GitHub Pages

GitHub Pages te permite alojar sitios web estáticos de forma gratuita directamente desde un repositorio de GitHub.

1.  **Crea un nuevo repositorio en GitHub:**
    *   Ve a [github.com](https://github.com) e inicia sesión.
    *   Haz clic en el botón **New** (Nuevo) para crear un repositorio.
    *   Dale un nombre (ej. `landing-edutec`).
    *   Asegúrate de **no** inicializar el repositorio con un README si planeas subir esta carpeta entera.

2.  **Sube los archivos del proyecto:**
    *   En la página principal de tu repositorio vacío, haz clic en **"uploading an existing file"** (subir archivos existentes).
    *   Arrastra y suelta todos los archivos descomprimidos (`index.html`, las carpetas `css`, `js`, `img`, y este `README.md`).
    *   Escribe un mensaje de commit (ej. "Versión inicial") y haz clic en **Commit changes**.

3.  **Activa GitHub Pages:**
    *   Ve a la pestaña **Settings** (Configuración) de tu repositorio.
    *   En el menú lateral izquierdo, haz clic en **Pages**.
    *   En la sección "Build and deployment", bajo "Source", elige **Deploy from a branch**.
    *   Bajo "Branch", selecciona la rama principal (`main` o `master`) y la carpeta `/ (root)`.
    *   Haz clic en **Save** (Guardar).
    *   En un par de minutos, GitHub generará tu sitio y mostrará en la parte superior el enlace público (ej. `https://tu-usuario.github.io/landing-edutec/`).

---

## 🛠️ Cómo modificar y mantener el proyecto

### 1. Modificar Enlaces (Links) de las Plataformas

Para cambiar la URL de destino al hacer clic en una tarjeta, debes editar el archivo `index.html`.

Busca la etiqueta `<a>` de la plataforma deseada.

**Ejemplo - Cambiar el enlace de "Cumbre":**
```html
<!-- Antes -->
<a href="https://cumbre.mendoza.edu.ar/" class="card card-cumbre" target="_blank" rel="noopener noreferrer">

<!-- Después (Sustituyendo el content del atributo href) -->
<a href="https://NUEVA-URL-DE-CUMBRE.com/" class="card card-cumbre" target="_blank" rel="noopener noreferrer">
```

### 2. Modificar Ayuda y Contraseña (Gestión de Usuario)

Si necesitas actualizar el correo de la Mesa de Ayuda o el enlace de recuperación de contraseña que aparece dentro del modal de Aulas EDUTEC, busca el siguiente fragmento al final del archivo `index.html`:

```html
<!-- Enlace de contraseña -->
<a href="https://mdaescdigital.page.gd/rest_pass2.html?i=1" ... >¿OLVIDASTE TU CONTRASEÑA?</a>

<!-- Correo de mesa de ayuda -->
<strong>ayudaaulasedutec@mendoza.edu.ar</strong>
```
Solo reemplaza la URL del atributo `href` o el texto del correo electrónico y guarda los cambios.

### 3. Cómo agregar nuevas plataformas

Si la DGE incorpora una nueva herramienta y necesitas agregar una tarjeta, sigue estos pasos:

#### Modificar `index.html`:
Ubica el contenedor `<div class="cards-grid">` de la sección apropiada (ya sea "Acceso Principal" o "Plataformas Educativas Integradas"). Copia el código de una tarjeta existente y modifícalo con los datos de la nueva plataforma:

```html
<!-- Tarjeta nueva -->
<a href="https://url-de-nueva-plataforma.com/" class="card card-nueva-plataforma" target="_blank" rel="noopener noreferrer">
    <div class="card-badge">Tipo (ej: Robótica)</div>
    <!-- Asegúrate de subir la imagen dentro de la carpeta /img/ -->
    <img src="img/logo-nueva-plataforma.png" alt="Nombre Nueva Plataforma" class="card-logo" onerror="this.src=''; this.alt='Nombre Nueva Plataforma';">
    <h3>Nombre Nueva</h3>
    <p>Breve descripción de la funcionalidad de la plataforma que se muestre a los usuarios.</p>
    <div class="card-link">Acceder</div>
</a>
```

#### Modificar `css/style.css`:
Al final del archivo CSS, puedes asignarle a la tarjeta su color distintivo para el efecto decorativo "geométrico" que aparece detrás de ella. Localiza las reglas `.card-*::after` y añade la tuya:

```css
/* Color decorativo dinámico para la nueva tarjeta sobre hover */
.card-nueva-plataforma::after {
    background-color: #00A366; /* Reemplazar por el código de color hexadecimal oficial de la plataforma */
}
```
