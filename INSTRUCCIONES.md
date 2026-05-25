# Victorino Style — Cómo ejecutar el proyecto en tu ordenador

> **TFG 2DAM curso 2025/2026 · Autor: Kevin (KevinFlow-ai)**
> **Aplicación de gestión de citas para una peluquería: backend Spring Boot 4 + frontend Flutter Web/Android + base de datos MySQL.**

Este documento es la **versión corta** para arrancar la app rápidamente. Para una guía exhaustiva con explicación de cada paso, capturas y FAQ, ver `documentacion/guia-distribucion-codigo.md`.

---

## ✨ ¿Qué vas a conseguir?

Levantar **toda la aplicación en tu ordenador** con un único comando, sin instalar Java, Maven, Flutter SDK ni MySQL Server. Solo necesitas **Docker Desktop** (gratis, ~5 minutos de instalación).

Tras seguir esta guía tendrás:
- **Frontend web** accesible en `http://localhost:8081`.
- **Backend (API REST)** en `http://localhost:8080/api/v1`.
- **Swagger** (documentación interactiva del API) en `http://localhost:8080/api/v1/swagger-ui.html`.
- **MySQL** con ~53 usuarios + ~1000 citas + 4 servicios pre-cargados.

---

## 🚀 Pasos (Windows / macOS / Linux)

### 1. Instalar Docker

- **Windows / macOS**: descargar **Docker Desktop** desde `https://www.docker.com/products/docker-desktop` → instalar → abrir y aceptar términos → esperar a que ponga "Engine running".
- **Linux** (Ubuntu/Debian): seguir las instrucciones oficiales para instalar `docker-ce` y `docker-compose-plugin`. Resumen rápido en la guía completa.

### 2. Descargar el código

Recibes el código por una de estas vías:
- **ZIP de Google Drive** (lo más habitual): descarga el archivo `victorino-style-tfg.zip` y extráelo en una carpeta corta (ej. `C:\victorino\` o `~/victorino/`).
- **Repositorio GitHub privado**: si Kevin te ha invitado como colaborador, `git clone` la rama `Produccion-Railway`.

### 3. Configurar credenciales

Copia la plantilla `.env.example` a `.env` y rellena los valores. Kevin entrega al tribunal un `.env` pre-rellenado en un correo aparte para que este paso sea simplemente reemplazar el archivo.

**Windows (PowerShell)**:
```powershell
Copy-Item .env.example .env
notepad .env
```

**macOS / Linux**:
```bash
cp .env.example .env
nano .env       # o el editor que prefieras
```

### 4. Arrancar todo

Desde la carpeta del proyecto (donde está `docker-compose.yml`):

```bash
docker compose up --build
```

**La primera vez tarda 20-30 minutos** porque Docker descarga las imágenes base (JDK 21, Flutter SDK, MySQL, nginx) y compila el código. Las veces siguientes son rápidas (~1 min). Mientras espera, puede explorar el código del proyecto con cualquier editor.

### 5. Probar la app

Abre tu navegador en:
```
http://localhost:8081
```

Verás la pantalla de login. Credenciales para probar:

| Rol | Correo | Contraseña |
|---|---|---|
| Administrador | `victorino@admin.com` | `Admin1234!` |
| Empleado | `maradona@victorinostyle.com` | `Empleado1234!` |
| Cliente demo | `andres.lozano@gmail.com` | `Cliente1234!` |

### 6. Detener / limpiar

```bash
# Pulsa Ctrl+C en la terminal donde corre docker compose, luego:
docker compose down              # conserva los datos
docker compose down -v           # borra todo (BD, fotos)
```

---

## 📱 ¿Y la app móvil Android?

El compose levanta la versión **web**. Para probar el **APK Android** hay dos opciones:

1. **APK ya generado**: descarga el `app-release.apk` del enlace de Drive separado e instálalo en cualquier móvil Android (ver `documentacion/guia-despliegue-railway.md`, sección 10).
2. **APK contra tu Docker local**: instala el APK, abre la pantalla "Ajustes del servidor" desde el login, y cambia la URL a la IP de tu PC en la WiFi (ej. `http://192.168.1.42:8080/api/v1`).

Más detalles en la guía completa.

---

## 🔍 ¿Solo quieres ver el código sin ejecutar?

Abre cualquier carpeta del ZIP con tu editor favorito (Notepad, VSCode, IntelliJ Community, GitHub web…). El código está en:

```
Backend_Victorino/src/main/java/    ← Backend Spring Boot
frontend_victorino/lib/             ← Frontend Flutter (Dart)
Backend_Victorino/src/main/resources/db/  ← Schema y seed SQL
documentacion/                      ← Guías y memoria
```

---

## ❓ Problemas comunes

| Síntoma | Solución |
|---|---|
| `Cannot connect to the Docker daemon` | Abre Docker Desktop y espera a "Engine running" |
| `port 8080 already in use` | Para el otro programa que usa ese puerto o cambia el mapeo en `docker-compose.yml` |
| Build tarda mucho la primera vez | Normal (20-30 min): descarga JDK 21 + Flutter SDK ~3 GB |
| `permission denied` en Linux | Añade tu usuario al grupo docker: `sudo usermod -aG docker $USER && newgrp docker` |
| Frontend no carga | Espera a que en los logs aparezca `Started BackendVictorinoApplication`. Luego refresca el navegador |

Más detalles, escenarios y soluciones en `documentacion/guia-distribucion-codigo.md` (FAQ completa).

---

## 📚 Documentación adicional

- **Guía de distribución (esta entrega)**: `documentacion/guia-distribucion-codigo.md` ← **léeme primero si tienes dudas**.
- **Guía de despliegue Railway** (cómo se desplegó en producción): `documentacion/guia-despliegue-railway.md`.
- **Memoria del TFG**: `documentacion/` (carpetas `administrador/`, `auth/`, `cliente/`, etc.).
