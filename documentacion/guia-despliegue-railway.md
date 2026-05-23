# Guía de despliegue a producción — Victorino Style

> **Autor**: Kevin (KevinFlow-ai)
> **Proyecto**: TFG 2DAM, curso 2025/2026
> **Fecha del despliegue**: mayo de 2026
> **Plataforma**: Railway
> **Backend público**: `https://victorinostyle-production.up.railway.app/api/v1`
> **Frontend público**: *(pendiente, se completará en la siguiente fase)*

---

## Índice

1. [Resumen ejecutivo](#1-resumen-ejecutivo)
2. [Conceptos previos](#2-conceptos-previos-explicados-en-cristiano)
3. [Arquitectura final desplegada](#3-arquitectura-final-desplegada)
4. [Stack tecnológico](#4-stack-tecnológico)
5. [Preparación del proyecto antes de desplegar](#5-preparación-del-proyecto-antes-de-desplegar)
6. [Paso a paso del despliegue en Railway](#6-paso-a-paso-del-despliegue-en-railway)
7. [Errores reales que aparecieron y cómo se resolvieron](#7-errores-reales-que-aparecieron-y-cómo-se-resolvieron)
8. [Verificación y pruebas](#8-verificación-y-pruebas)
9. [Frontend Flutter Web (pendiente)](#9-frontend-flutter-web-pendiente)
10. [APK Android](#10-apk-android)
11. [iOS (iPhone / iPad)](#11-ios-iphone--ipad)
12. [Windows (escritorio)](#12-windows-escritorio)
13. [Linux (escritorio)](#13-linux-escritorio)
14. [Preguntas frecuentes (FAQ para el tribunal)](#14-preguntas-frecuentes-faq-para-el-tribunal)
15. [Anexo A — Variables de entorno completas](#15-anexo-a--variables-de-entorno-completas)
16. [Anexo B — Comandos útiles](#16-anexo-b--comandos-útiles)
17. [Anexo C — Glosario de términos](#17-anexo-c--glosario-de-términos)

---

## 1. Resumen ejecutivo

Victorino Style nació como una aplicación que se ejecutaba **únicamente en mi máquina local**: el backend en `localhost:8080`, la base de datos MySQL en `localhost:3306` y el frontend Flutter accediendo a la IP local del ordenador. Esto funciona para desarrollo, pero **no sirve para que el tribunal, mis compañeros o un cliente real puedan probar la aplicación desde su propio dispositivo sin tener mi ordenador encendido**.

El objetivo del despliegue ha sido **convertir esa aplicación local en un servicio accesible 24/7 desde Internet**, de forma que cualquier persona en cualquier lugar pueda usarla:

- Desde un **navegador web** (la versión Flutter Web).
- Desde un **móvil Android** (instalando un APK que se conecta al backend en la nube).

Para conseguir esto se ha utilizado **Railway**, una plataforma en la nube (PaaS) que aloja:

1. El **backend** Spring Boot compilado y arrancado automáticamente desde mi repositorio de GitHub.
2. Una **base de datos MySQL** gestionada que sustituye al MySQL local de mi máquina.
3. Un **volumen persistente** donde se guardan las fotos subidas por los usuarios (sin perderse al redesplegar).
4. *(Pendiente)* Un segundo servicio para el **frontend Flutter Web** que servirá la aplicación a través de una URL pública.

Además, dos servicios externos se siguen utilizando tal cual estaban en local:

- **Firebase Cloud Messaging** para las notificaciones push al móvil.
- **Gmail SMTP** para el envío del código de recuperación de contraseña por correo.

Todo el proceso se ha hecho cuidando dos aspectos clave:

- **Seguridad**: ninguna contraseña, ninguna clave privada, ningún token aparece "a pelo" en el código del repositorio. Todos los secretos se inyectan como **variables de entorno** desde Railway, no desde el código.
- **Reproducibilidad**: si mañana hay que volver a desplegar todo desde cero (por desastre, por cambio de proveedor, o para crear un entorno de pruebas paralelo), basta con seguir esta guía y los archivos del repositorio. No depende de "cosas que solo Kevin sabe".

---

## 2. Conceptos previos (explicados en cristiano)

Antes de entrar en el cómo, conviene entender el qué y el porqué. Esta sección está pensada para que cualquier persona —sin conocimientos técnicos profundos— pueda seguir la guía y entender las decisiones tomadas.

### 2.1. ¿Qué significa "desplegar a producción"?

Hasta ahora, la aplicación corría en mi ordenador. Si yo apagaba el portátil, la aplicación dejaba de existir. **Desplegar a producción** significa coger esa misma aplicación y meterla en un servidor que vive en Internet, encendido permanentemente, accesible desde cualquier dispositivo del mundo a través de una URL pública.

Es exactamente la misma diferencia que hay entre tener un documento en tu portátil y subirlo a Google Drive: en el primer caso solo lo ves tú, en el segundo lo ve cualquiera con el enlace.

### 2.2. ¿Qué es Railway?

Railway es una **plataforma como servicio (PaaS, *Platform as a Service*)**. Eso quiere decir que tú le entregas el código fuente de tu aplicación y la plataforma se encarga del resto:

- Te da una máquina virtual en algún centro de datos.
- Instala las dependencias (en mi caso JDK 21, Maven, MySQL).
- Compila tu código.
- Arranca tu aplicación.
- Le pone delante un *reverse proxy* con HTTPS automático.
- Te da una URL pública.
- Si tu aplicación se cae, intenta reiniciarla automáticamente.

Compárese con la alternativa de **IaaS (*Infrastructure as a Service*)** como AWS EC2 o un VPS en DigitalOcean: ahí te dan una máquina vacía con Linux y tú tienes que instalar todo a mano (Java, MySQL, Nginx, certificados Let's Encrypt, systemd, etc.). Railway abstrae todo eso.

### 2.3. ¿Por qué Railway y no AWS, Heroku, Render u otra?

| Plataforma | Pros | Contras |
|---|---|---|
| **Railway** ✅ | Setup sencillísimo, MySQL integrado, plan gratuito generoso para TFG, deploys automáticos desde GitHub, UI muy clara | Plataforma joven (más riesgo a largo plazo) |
| AWS / GCP / Azure | El estándar profesional, escalan infinitamente | Curva de aprendizaje muy alta, configurar mil servicios, factura difícil de estimar |
| Heroku | Pionero del PaaS, muy maduro | Sin plan gratuito real desde 2022, más caro |
| Render | Similar a Railway | Algo menos pulido en su UI |
| Vercel / Netlify | Excelentes para frontend estático | No están pensados para backend Spring Boot |

Para un TFG donde importa **demostrar conocimiento del concepto del despliegue, no perderse en configuración de infraestructura**, Railway es la opción equilibrada: profesional pero abordable.

### 2.4. ¿Qué es un contenedor? ¿Qué es Docker?

Un **contenedor** es como una "caja" que empaqueta tu aplicación junto con todo lo que necesita para funcionar (sistema operativo mínimo, librerías, runtime, configuración). La idea: si funciona en mi contenedor, funcionará exactamente igual en cualquier otro sitio donde se ejecute ese contenedor.

**Docker** es la tecnología más usada para crear y ejecutar contenedores. Railway internamente usa contenedores Docker para arrancar tu aplicación, aunque te abstrae tanto que muchas veces ni te enteras.

En este proyecto, el **frontend** sí usa un `Dockerfile` propio (porque Flutter Web necesita un proceso de build especial). El **backend** no necesita Dockerfile porque Railway lo detecta y construye automáticamente con un sistema llamado *Nixpacks*.

### 2.5. ¿Qué es Nixpacks?

Es el sistema "mágico" que usa Railway por defecto. Tú le subes tu proyecto, Nixpacks mira los ficheros (`pom.xml` para Java, `package.json` para Node, etc.) y deduce cómo compilarlo y arrancarlo. Para el backend Spring Boot detecta el `pom.xml`, instala Maven y un JDK, lanza `./mvnw install` y luego ejecuta el JAR resultante.

### 2.6. ¿Qué es un volumen persistente y por qué importa?

Un contenedor es **efímero**: cuando se reinicia (porque hay un nuevo despliegue, porque la máquina se mueve, etc.), todo su sistema de archivos se pierde y se vuelve a partir de cero desde la imagen original. Eso es genial para la aplicación (siempre arranca limpia), pero **un problema gordísimo si tu app guarda archivos en disco** (como las fotos que suben los usuarios).

Un **volumen persistente** es un disco externo que vive fuera del contenedor y se monta en una ruta concreta. Si el contenedor se reinicia, el volumen sigue ahí intacto. En este proyecto se ha creado un volumen montado en `/app/uploads` para que las fotos de servicios, empleados y clientes no se pierdan.

### 2.7. ¿Qué es un reverse proxy y la "terminación TLS"?

Cuando tu navegador llama a `https://victorinostyle-production.up.railway.app`, esa petición **no llega directa al backend Spring Boot**. Railway tiene un **reverse proxy** (un servidor intermedio) que:

1. Recibe la petición HTTPS de tu navegador.
2. Descifra el contenido (a esto se le llama **terminación TLS**).
3. Le pasa la petición a tu backend Spring Boot, ya en HTTP plano dentro de la red interna de Railway.
4. Recibe la respuesta del backend.
5. La cifra de nuevo en HTTPS y la devuelve al navegador.

```
Navegador  ───HTTPS───►  Reverse Proxy Railway  ───HTTP───►  Backend Spring Boot
           ◄──HTTPS────                          ◄──HTTP────
```

Ventaja: tu backend no tiene que ocuparse de certificados SSL ni renovaciones. Inconveniente: el backend "ve" la petición como HTTP, no HTTPS, lo que dio un problema en Swagger UI que se resolvió con `server.forward-headers-strategy=framework` (ver sección de errores).

### 2.8. ¿Qué son las variables de entorno y por qué son tan importantes?

Una **variable de entorno** es un parámetro que se le pasa a la aplicación cuando arranca, sin estar escrito en el código. Por ejemplo:

```properties
spring.datasource.password=${SPRING_DATASOURCE_PASSWORD:1234}
```

Eso significa: "la contraseña de la base de datos es el valor de la variable de entorno `SPRING_DATASOURCE_PASSWORD`, y si no existe, usa `1234` como valor por defecto".

¿Por qué se hace así?

1. **Seguridad**: si la contraseña real estuviera en el código, cualquiera con acceso al repositorio podría verla. Como está en una variable, solo Railway la conoce.
2. **Portabilidad**: en local uso `1234`, en Railway uso una contraseña aleatoria fuerte. El mismo código sirve para ambos entornos sin tocar nada.
3. **Rotación**: si mañana se compromete la contraseña, la cambio en Railway sin tener que hacer un nuevo commit del código.

#### 2.8.1. Variables del backend Spring Boot

Estas son las variables que el backend lee al arrancar. Algunas tienen valor por defecto para que la app siga funcionando en local sin tener que configurar nada; otras son obligatorias en Railway. La sintaxis `${VAR:default}` en `application.properties` significa exactamente eso: usa `VAR` si existe, si no, usa `default`.

**Cómo se generaron / de dónde salen sus valores:**

| Variable | Cómo se obtuvo el valor | Qué hace |
|---|---|---|
| `PORT` | **Lo inyecta Railway automáticamente** al arrancar el contenedor (suele ser 8080 pero puede cambiar). El backend lo lee con `server.port=${PORT:8080}` | Puerto donde escucha Spring Boot. Crítico que el código respete `PORT` o Railway no podrá enrutar tráfico al servicio. |
| `SPRING_DATASOURCE_URL` | **Se construyó manualmente con una referencia**: `jdbc:mysql://${{MySQL.MYSQLHOST}}:${{MySQL.MYSQLPORT}}/${{MySQL.MYSQLDATABASE}}?useSSL=false&serverTimezone=Europe/Madrid&allowPublicKeyRetrieval=true`. Railway resuelve las referencias automáticamente en tiempo de arranque. | Cadena de conexión JDBC. Una sola string que contiene host, puerto, base de datos y parámetros de conexión. |
| `SPRING_DATASOURCE_USERNAME` | Referencia: `${{MySQL.MYSQLUSER}}` → resuelve al usuario MySQL (por defecto `root` en el plugin de Railway). | Usuario con el que el backend se autentica contra la BD. |
| `SPRING_DATASOURCE_PASSWORD` | Referencia: `${{MySQL.MYSQLPASSWORD}}` → resuelve a la contraseña aleatoria que Railway genera al provisionar el MySQL. **Nunca la veo a ojo**, solo Railway la conoce. | Contraseña MySQL del backend. |
| `VICTORINO_JWT_SECRET` | Se generó **una sola vez con `openssl rand -base64 64`** en mi máquina local. Es una cadena base64 de 88 caracteres. Se pegó tal cual en Railway. | Clave HMAC con la que el backend firma los JWT. Si esta clave se compromete, cualquiera podría falsificar tokens; por eso debe ser larga, aleatoria y única por entorno. |
| `SPRING_MAIL_USERNAME` | Dirección de la cuenta Gmail creada para el proyecto: `peluqueria.victorinostyle@gmail.com`. | Remitente de los correos de recuperación de contraseña. |
| `SPRING_MAIL_PASSWORD` | **No es la contraseña normal de Gmail**, es una *App Password* que Google genera específicamente para aplicaciones. Se obtuvo en *Cuenta de Google → Seguridad → 2FA activado → Contraseñas de aplicación → Crear*. Devuelve una cadena de 16 caracteres tipo `abcd efgh ijkl mnop`. | Permite a Spring Mail autenticarse contra el SMTP de Gmail sin usar la contraseña real (mejor práctica). |
| `VICTORINO_ADMIN_PRUEBA_ACTIVO` | `true`. Valor fijo para que el `AdminInitializer` (un `CommandLineRunner`) cree el admin al arrancar si no existe. | Conmutador para activar/desactivar la creación automática del admin demo. |
| `VICTORINO_ADMIN_PRUEBA_PASSWORD` | `Admin1234!`. Contraseña pactada para el TFG, conocida por el tribunal. | Contraseña en texto plano del admin demo. Internamente se hashea con BCrypt al crearlo. |
| `VICTORINO_UPLOADS_DIRECTORIO` | `/app/uploads`. Coincide con el *Mount Path* del volumen persistente. | Indica al backend dónde escribir/leer las fotos. En local apunta a `./uploads` (relativo), en Railway al volumen. |
| `VICTORINO_FIREBASE_PROJECT_ID` | `victorino-style`. Salió del propio Firebase Console al crear el proyecto. | Identificador del proyecto Firebase, usado por el SDK para enrutar correctamente las notificaciones. |
| `VICTORINO_FIREBASE_CREDENTIALS_JSON` | **El contenido entero del JSON del service account** generado en *Firebase Console → Configuración del proyecto → Cuentas de servicio → Generar nueva clave privada*. Es un JSON con `type`, `project_id`, `private_key_id`, `private_key`, `client_email`, etc. Se pegó tal cual en una variable multilínea de Railway. | Permite al backend autenticarse contra Firebase Cloud Messaging para enviar notificaciones push. |
| `VICTORINO_CORS_ORIGENES_EXTRA` | **Inicialmente vacío**, se rellenará con la URL pública del frontend una vez se despliegue. | Lista separada por coma de dominios permitidos por CORS (además de los locales de desarrollo). |
| `NIXPACKS_JDK_VERSION` | `21`. Valor fijo para forzar a Nixpacks a instalar JDK 21 en lugar del 17 que pone por defecto. | Variable interpretada por **el builder Nixpacks**, no por la aplicación. Le indica qué JDK instalar al construir el contenedor. |
| `JAVA_TOOL_OPTIONS` | `-Xmx400m -Xms256m -XX:+UseSerialGC -XX:MaxMetaspaceSize=128m`. Valor calculado a mano según los 512 MB de RAM del plan Hobby. | Flags que el JVM lee al arrancar. Limitan la memoria que reserva el proceso para evitar OOM en el contenedor. |

#### 2.8.2. Variables del frontend Flutter

Flutter compila el código a JavaScript (Web) o a un APK/AAB (Android). En ambos casos, **las variables se inyectan en tiempo de compilación**, no de ejecución. Es decir, cuando Flutter compila, el valor de la variable queda hardcodeado dentro del bundle final.

La sintaxis se llama `--dart-define`. El código Dart lee la variable con `String.fromEnvironment(...)`.

**Cómo se generaron / de dónde salen sus valores:**

| Variable | Cómo se obtuvo el valor | Qué hace |
|---|---|---|
| `API_BASE_URL` | Para el despliegue web/APK: `https://victorinostyle-production.up.railway.app/api/v1` (la URL pública del backend desplegado en Railway). En local: `http://10.0.2.2:8080/api/v1` (el `10.0.2.2` es la IP especial del emulador Android para acceder al `localhost` de la máquina host). | URL base a la que el cliente Flutter manda todas sus peticiones HTTP. Si se compila apuntando a producción, la app habla con el backend real; si se compila apuntando a local, habla con el backend en mi máquina. |

**Mecanismo de paso en cada plataforma:**

- **Build local**: `flutter build apk --release --dart-define=API_BASE_URL=https://...` o `flutter build web --release --dart-define=API_BASE_URL=https://...`.
- **Build en Railway (frontend web, próximamente)**: la variable se define en *Settings → Variables* del servicio frontend, y el `Dockerfile` la recibe como `ARG API_BASE_URL` y la pasa al `flutter build web` interno. Esto se llama un **Build Arg** de Docker, y es diferente a una variable de runtime.

Adicionalmente, hay una **vía de configuración en runtime** que permite al usuario cambiar la URL del backend desde una pantalla interna de "Ajustes del servidor" en el frontend, sin tener que recompilar. Es útil para que el tribunal pueda apuntar la misma app a entornos distintos (producción Railway, mi local, una demo, etc.) sin distribuir varios APK.

#### 2.8.3. Variables del servicio MySQL (cómo se autogeneran)

Al añadir el plugin **MySQL** en Railway, **se crean automáticamente** un conjunto de variables en el servicio. No las pongo yo, las pone Railway al provisionar la base. Esto es importante porque mi backend las referencia con `${{MySQL.X}}`.

| Variable autogenerada | Ejemplo de valor | Para qué la usa el backend |
|---|---|---|
| `MYSQLHOST` | `mysql.railway.internal` (dentro de la red privada) | Parte del `SPRING_DATASOURCE_URL` |
| `MYSQLPORT` | `3306` | Parte del `SPRING_DATASOURCE_URL` |
| `MYSQLUSER` | `root` | `SPRING_DATASOURCE_USERNAME` |
| `MYSQLPASSWORD` | aleatoria, ej. `xY7p9...` (32+ caracteres) | `SPRING_DATASOURCE_PASSWORD` |
| `MYSQLDATABASE` | `railway` (nombre por defecto que da Railway) | Parte del `SPRING_DATASOURCE_URL` |
| `MYSQL_URL` | URL completa: `mysql://root:xY7p9...@mysql.railway.internal:3306/railway` | Alternativa "todo en uno" si no quiero descomponerlo |
| `MYSQL_PUBLIC_URL` | URL externa con host:puerto público (solo si activo el *TCP Proxy*): `mysql://root:xY7p9...@monorail.proxy.rlwy.net:32400/railway` | Solo se usó **temporalmente** desde MySQL Workbench para cargar `schema_railway.sql` y `seed_railway.sql`. |

**Punto clave**: el backend **nunca usa la URL pública** del MySQL, siempre la interna. La pública solo se activó puntualmente para la carga inicial de datos y se puede desactivar después para reducir la superficie de ataque.

#### 2.8.4. Cómo se referencian variables entre servicios en Railway

Railway permite que un servicio lea variables de otro mediante una sintaxis especial: `${{NombreDelServicio.NombreVariable}}`. Cuando el backend arranca, Railway sustituye estas referencias por los valores reales del servicio referenciado.

Ejemplo concreto en mi proyecto:
```
SPRING_DATASOURCE_URL = jdbc:mysql://${{MySQL.MYSQLHOST}}:${{MySQL.MYSQLPORT}}/${{MySQL.MYSQLDATABASE}}?useSSL=false&serverTimezone=Europe/Madrid&allowPublicKeyRetrieval=true
```

En tiempo de arranque, Railway resuelve esto a:
```
jdbc:mysql://mysql.railway.internal:3306/railway?useSSL=false&serverTimezone=Europe/Madrid&allowPublicKeyRetrieval=true
```

**Ventaja**: si mañana Railway cambia el host interno del MySQL (porque mueve el servicio a otro nodo), el backend se entera solo. Yo no tengo que tocar nada.

#### 2.8.5. Cómo se añaden las variables en Railway (UI)

Hay dos formas:

- **Una a una**: Variables → **+ New Variable** → introducir nombre y valor → Add. Útil para variables sueltas o multilínea (como el JSON de Firebase).
- **Raw Editor**: Variables → **Raw Editor** → pegar varias en formato `CLAVE=valor` separadas por saltos de línea → Update Variables. Útil cuando son muchas a la vez. Es lo que usé para añadir todas las del backend de golpe.

### 2.9. ¿Qué es JWT?

**JWT (JSON Web Token)** es un estándar para emitir tokens de autenticación. Cuando el usuario hace login, el backend le devuelve un *access token* (JWT) y un *refresh token*. El cliente envía el access token en cada petición posterior (`Authorization: Bearer <token>`) y el backend lo valida para saber qué usuario es.

Características clave:
- **Stateless**: el backend no guarda sesiones en memoria, todo está autocontenido en el token.
- **Firmado con HS256**: el token lleva una firma digital generada con una clave secreta (`VICTORINO_JWT_SECRET`). Si alguien intenta modificar el token, la firma deja de cuadrar y el backend lo rechaza.
- **Expira en 15 minutos**: si te roban el access token, solo es válido 15 min. El refresh token (válido 7 días) se usa para pedir uno nuevo sin volver a meter contraseña.

### 2.10. ¿Qué es BCrypt?

Es el algoritmo que se usa para guardar las contraseñas en la base de datos. **Nunca se guarda la contraseña en texto plano**: se guarda un *hash* (una transformación irreversible) generado por BCrypt con un "cost factor" de 10. Cuando el usuario hace login, se compara el hash de su contraseña intentada con el hash guardado.

Ventajas frente a SHA-256 / MD5:
- **Lento a propósito**: tarda ~100ms en generar un hash, lo que dificulta los ataques por fuerza bruta.
- **Salt automático**: cada hash incluye un valor aleatorio único, así dos usuarios con la misma contraseña tienen hashes distintos.

---

## 3. Arquitectura final desplegada

### 3.1. Visión general

```mermaid
flowchart TB
    User[Usuario<br/>Navegador / Móvil]

    subgraph Railway["☁️ Railway (cloud platform)"]
        direction TB
        Proxy[🔐 Reverse Proxy<br/>HTTPS · TLS termination]

        subgraph Project["Proyecto: Victorino-Style"]
            Backend["🍃 Backend<br/>Spring Boot 4 + JDK 21<br/>victorinostyle-production.up.railway.app"]
            Frontend["🌐 Frontend (pendiente)<br/>Flutter Web + nginx"]
            MySQL[("🛢️ MySQL 8<br/>~53 usuarios<br/>~1000 citas")]
            Volume[("💾 Volumen<br/>/app/uploads")]
        end
    end

    Firebase["🔥 Firebase FCM<br/>Notificaciones push"]
    Gmail["📧 Gmail SMTP<br/>Recuperación contraseña"]

    User -->|HTTPS| Proxy
    Proxy --> Backend
    Proxy --> Frontend
    Frontend -->|API REST| Backend
    Backend <--> MySQL
    Backend <--> Volume
    Backend -->|Push token| Firebase
    Backend -->|Email| Gmail
    Firebase -->|Notificación| User
    Gmail -->|Correo| User
```

![alt text](image.png)

### 3.2. Cómo conviven los servicios

- **Backend** y **MySQL** viven dentro de la misma red privada de Railway. El backend se conecta al MySQL por nombre interno (`mysql.railway.internal`), sin pasar por Internet. Esto es **rápido** (latencia <1ms) y **seguro** (nadie de fuera puede llegar al MySQL salvo que abramos un *TCP Proxy* público, cosa que hicimos puntualmente para cargar los datos iniciales y se puede cerrar después).
- El **volumen** se monta en el sistema de archivos del backend en `/app/uploads`. Para el backend es indistinguible de una carpeta local, pero realmente vive en un disco aparte que sobrevive a los redespliegues.
- Las **variables de entorno** del backend incluyen referencias a las del MySQL (`${{MySQL.MYSQLHOST}}`). Railway las resuelve automáticamente en tiempo de arranque.

---

## 4. Stack tecnológico

| Componente | Tecnología | Versión | Por qué |
|---|---|---|---|
| Plataforma cloud | Railway | — | PaaS sencillo, plan Hobby asumible, integración GitHub |
| Lenguaje backend | Java | 21 (Temurin) | LTS más reciente, requerido por Spring Boot 4 |
| Framework backend | Spring Boot | 4.0.6 | Madurez, ecosistema, Spring Security |
| Gestor de dependencias | Maven | (vía mvnw) | Estándar Java, lock automático |
| Base de datos | MySQL | 8.0 | Relacional, ACID, lo que pedía el TFG |
| ORM | Hibernate (vía JPA) | — | Mapeo objeto-relacional, productividad |
| Autenticación | JWT (jjwt 0.13) | — | Stateless, escalable |
| Documentación API | Springdoc OpenAPI | 3.0.1 | Swagger UI gratis y autogenerado |
| Notificaciones push | Firebase Admin SDK | 9.8.0 | Soporta Android/iOS/Web con un solo SDK |
| Correo | Spring Mail + Gmail SMTP | — | Cero coste para volúmenes bajos |
| Compilación frontend | Flutter | 3.41.2 | Multi-plataforma desde un único código |
| Servidor frontend | nginx alpine | — | Ligero, sirve estáticos perfectamente |
| Empaquetado frontend | Docker | — | Reproducibilidad del build |

---

## 5. Preparación del proyecto antes de desplegar

Antes de tocar nada en Railway, hubo que dejar el repositorio "listo para producción". Esta es la lista de cambios:

### 5.1. Sacar los secretos del código (parametrización)

El archivo `application.properties` tenía valores **hardcodeados** que en un repositorio público serían una catástrofe de seguridad:

- Contraseña de MySQL (`1234`)
- Contraseña de aplicación de Gmail (`ysknifmendkfrwig`)
- Secret JWT en Base64
- Contraseña del admin de prueba (`Admin1234!`)

Se sustituyeron por **placeholders** que leen de variables de entorno con un valor por defecto para desarrollo local:

**Antes**:
```properties
spring.datasource.password=1234
```

**Después**:
```properties
spring.datasource.password=${SPRING_DATASOURCE_PASSWORD:1234}
```

De este modo:
- En **local**, si no se define la variable, sigue funcionando con `1234` como antes (no rompo mi entorno de desarrollo).
- En **Railway**, defino la variable `SPRING_DATASOURCE_PASSWORD` apuntando a la contraseña real de MySQL gestionado.

> 💡 **Diseño consciente**: El TFG mantiene los valores antiguos comprometidos en el historial de git como un precedente educativo de "qué *no* hacer". En un proyecto profesional, tras esta limpieza se habría rotado cada secreto (cambiar la contraseña de Gmail, regenerar el JWT secret, generar nueva clave de Firebase) para invalidar los valores antiguos. En el contexto de un TFG es asumible, pero se documenta explícitamente como buena práctica pendiente.

### 5.2. Limpieza de archivos sensibles del repositorio

- Se eliminó del repo el archivo `victorino-firebase-key.json` (clave privada de Firebase). Se añadió al `.gitignore` para que nunca más se suba accidentalmente.
- Se eliminó un archivo basura llamado `BORRAR LUEGO_CONFI BBDD` que contenía configuración antigua de otro proyecto.

### 5.3. Solución para las fotos: `UploadsSeederRunner`

Problema: cuando despliegue por primera vez en Railway, el volumen `/app/uploads` arrancará **completamente vacío**. Pero la base de datos cargada con `seed_railway.sql` tendrá referencias a imágenes (`/uploads/empleados/admin.png`, fotos iniciales de los servicios, etc.) que no existirán → los iconos saldrán rotos en la app.

Solución implementada:

1. Las 7 imágenes "semilla" se movieron de `Backend_Victorino/uploads/` a `Backend_Victorino/src/main/resources/uploads-seed/` (es decir, dentro del JAR compilado, en el classpath).
2. Se creó la clase `UploadsSeederRunner` (un `CommandLineRunner` de Spring) que se ejecuta automáticamente al arrancar el backend. Su lógica:
   - Recorre todos los archivos bajo `classpath:uploads-seed/**`.
   - Para cada uno, comprueba si existe en el destino (`/app/uploads/...`).
   - Si no existe, lo copia ahí.
   - Si existe, lo deja como está (es **idempotente**: ejecutarlo cien veces no rompe nada).

Resultado: la primera vez que arranca el backend en Railway, el volumen se rellena solo. Los redespliegues posteriores no sobrescriben las imágenes que los usuarios hayan subido en el tiempo entremedias.

```java
// Extracto simplificado de UploadsSeederRunner.java
for (Resource recurso : resolver.getResources("classpath*:uploads-seed/**/*")) {
    Path destino = destinoBase.resolve(rutaRelativa);
    if (!Files.exists(destino)) {
        Files.copy(recurso.getInputStream(), destino);
    }
}
```

### 5.4. Adaptar `FirebaseConfig` para aceptar JSON en variable de entorno

Originalmente, el backend cargaba las credenciales de Firebase desde un archivo en `resources/firebase/`. Eso ya no servía porque el archivo no está en el repo (se borró por seguridad) y Railway no tiene una forma cómoda de subir archivos al contenedor.

Solución: modificar `FirebaseConfig` para que acepte **dos modos**, con prioridad:

1. Si existe la variable `VICTORINO_FIREBASE_CREDENTIALS_JSON` con el JSON entero del *service account*, se usa ese directamente (modo cloud).
2. Si no, cae al modo antiguo de leer el archivo desde `classpath:` o `file:` (modo local).

Así en Railway basta con pegar el JSON entero como una variable, sin pelearse con archivos.

### 5.5. Adaptar el `CorsConfig` para producción

El archivo `CorsConfig.java` solo permitía orígenes locales (`localhost`, IPs WiFi, túneles ngrok). Se le añadió la lectura de la propiedad `victorino.cors.origenes-extra`, que toma una lista de URLs separadas por coma desde una variable de entorno. Así cuando creemos el frontend, basta con poner su URL pública en Railway y los CORS se abren.

### 5.6. Schemas separados para Railway

El `schema.sql` original empezaba con `DROP DATABASE IF EXISTS ... CREATE DATABASE ... USE ...`. Eso no funciona en el MySQL gestionado de Railway porque el usuario por defecto **no tiene permisos para crear bases de datos** (solo puede operar sobre la base ya creada llamada `railway`).

Solución: crear copias `schema_railway.sql` y `seed_railway.sql` sin las líneas de `DROP DATABASE` / `CREATE DATABASE` / `USE`. Estas versiones se ejecutan directamente sobre la base de datos `railway` que ya viene con el plugin MySQL de Railway.

El original `schema.sql` se mantiene para desarrollo local (donde sí tenemos permisos de root).

### 5.7. Dockerfile para el frontend Flutter Web

Flutter Web no es una de las plataformas que Nixpacks detecta automáticamente. Por eso se creó un `Dockerfile` multi-etapa en `frontend_victorino/`:

- **Etapa 1 (build)**: parte de la imagen oficial `ghcr.io/cirruslabs/flutter:3.41.2`, ejecuta `flutter pub get` y `flutter build web --release --dart-define=API_BASE_URL=$API_BASE_URL`.
- **Etapa 2 (runtime)**: parte de `nginx:alpine` (una imagen minúscula con solo nginx), copia los assets compilados y los sirve estáticamente.

La URL del backend se inyecta como **build argument** de Docker (`ARG API_BASE_URL`), de modo que queda hardcodeada en el bundle JavaScript final. No hace falta cambiar código para apuntar a una URL u otra.

### 5.8. Logos de la aplicación

Se configuró el paquete `flutter_launcher_icons` con el bloque correspondiente en `pubspec.yaml` para que el logo aparezca correctamente en todas las plataformas:

| Plataforma | Generado |
|---|---|
| Android | `mipmap-*/ic_launcher.png` + adaptive icon |
| iOS | `Assets.xcassets/AppIcon.appiconset/Icon-App-*.png` |
| Web | `favicon.png` + iconos PWA 192/512 |
| Windows | `app_icon.ico` |

Esto garantiza que, sea cual sea el dispositivo donde se instale la app (incluyendo Flutter Web como PWA en el escritorio), aparezca con la marca correcta.

---

## 6. Paso a paso del despliegue en Railway

Esta sección reconstruye, con todo el detalle, el orden real en que se hicieron las cosas. Está pensada para que cualquier persona pueda **reproducir el despliegue** sin tener que adivinar nada.

### 6.1. Cuenta y proyecto

#### 6.1.1. Crear cuenta en Railway

1. Acceder a `https://railway.app`.
2. Pulsar **Login** o **Start a New Project**.
3. Elegir "Login with GitHub" (la forma más natural, porque Railway luego necesitará acceso al repositorio para desplegar).
4. Autorizar a Railway en GitHub. Por seguridad, **NO darle acceso a todos los repositorios**: usar la opción "Only select repositories" y elegir únicamente `Victorino_Style`.
5. Tras el registro, Railway pide un correo de contacto y ofrece **5 € de crédito gratuito** (el primer mes corre por cuenta de la casa, suficiente para todo el período de desarrollo del TFG).

#### 6.1.2. Crear el proyecto

En el dashboard, pulsar **New Project**. Aparecen varias opciones:

- **Deploy from GitHub repo** ← usar esta.
- Deploy a template.
- Empty Project.

Elegir el repositorio `Victorino_Style`. Railway crea el proyecto y **arranca un primer despliegue automático que va a fallar** (porque toma la rama `main` y la raíz del repositorio en lugar de la rama `Produccion-Railway` y la carpeta `Backend_Victorino`). Esto es esperado y se corrige en el siguiente paso.

#### 6.1.3. Renombrar el proyecto

Por defecto Railway pone un nombre aleatorio tipo `serene-tree`. Ir a la esquina superior izquierda, pulsar el nombre del proyecto y cambiarlo a **`Victorino-Style`** para que quede claro. Save.

#### 6.1.4. Instalar la CLI de Railway

Aunque casi todo se hace por la web, la CLI es útil para vincular carpetas locales al proyecto y para abrir conexiones a la base de datos sin pasar por la UI.

Desde **PowerShell como administrador** en Windows:

```powershell
iwr -useb https://railway.com/install.ps1 | iex
```

```
Opción 2 — Con npm (si tienes Node.js instalado por Flutter Web o por otra cosa):
```

npm i -g @railway/cli

Si PowerShell se queja por política de ejecución:
```powershell
Set-ExecutionPolicy -Scope Process Bypass
iwr -useb https://railway.com/install.ps1 | iex
```

Tras la instalación, **cerrar y reabrir la terminal** (para que recargue el PATH) y comprobar:
```powershell
railway --version
```
Debe devolver algo tipo `railway 3.x.y`.

#### 6.1.5. Login en la CLI

```powershell
railway login
```
Abre el navegador, pide confirmación, y la terminal queda autenticada:
```
Logged in as cosoyeray@gmail.com
```
railway link
> Select a workspace kevinflow-ai's Projects

> Select a project Victorino-Style

> Select an environment production

> Select a service <esc to skip> MySQL

Project Victorino-Style linked successfully! 🎉

PS C:\Users\El Jefe\IdeaProjects\Victorino_Style\Backend_Victorino\src\main\resources\db> railway connect MySQL

mysql must be installed to continue
---

### 6.2. Servicio MySQL

#### 6.2.1. Añadir el plugin MySQL al proyecto

1. En el canvas del proyecto, pulsar **+ Create-add** (botón violeta arriba a la derecha) o **+ New**.
2. Elegir **Database** → **Add MySQL**.
3. Railway provisiona automáticamente en ~30 segundos:
   - Un contenedor con **MySQL 8.x**.
   - Un **volumen** llamado `mysql-volume` montado donde MySQL guarda sus datos. Es decir, **los datos persisten** aunque el contenedor se reinicie.
   - Una **base de datos vacía** llamada `railway` (es el nombre por defecto).
   - Un usuario `root` con una contraseña aleatoria de seguridad (32+ caracteres) que **solo Railway conoce**.

Aparece una cajita azul `MySQL` en el canvas con el icono del delfín y un punto verde "Online" cuando termina de levantar.

#### 6.2.2. Inspeccionar las variables autogeneradas

Pulsando la cajita `MySQL` → pestaña **Variables**, se ven:

| Variable | Visibilidad | Para qué sirve |
|---|---|---|
| `MYSQLHOST` | visible | Host interno: `mysql.railway.internal` |
| `MYSQLPORT` | visible | Puerto interno: `3306` |
| `MYSQLUSER` | visible | Usuario: `root` |
| `MYSQLPASSWORD` | **enmascarada** (hay un icono 👁 para revelarla puntualmente) | Contraseña aleatoria |
| `MYSQLDATABASE` | visible | Nombre de la BD: `railway` |
| `MYSQL_URL` | enmascarada | URL completa con credenciales: `mysql://root:...@mysql.railway.internal:3306/railway` |

> ⚠️ Estas variables **NO las pongo yo**: las pone Railway al provisionar el plugin. Mi trabajo es solo **referenciarlas desde el backend** mediante la sintaxis `${{MySQL.MYSQLHOST}}`, `${{MySQL.MYSQLUSER}}`, etc.

#### 6.2.3. Inspeccionar el volumen de datos

En **Settings** del servicio MySQL → **Volumes**, aparece automáticamente un volumen `mysql-volume` montado en `/var/lib/mysql` (la ruta estándar donde MySQL guarda los archivos de las bases de datos). **Esto es lo que garantiza que mis 1000 citas sobreviven a redespliegues**: aunque Railway tire el contenedor y monte uno nuevo, este volumen se vuelve a montar con los datos intactos.

#### 6.2.4. Punto importante: por defecto el MySQL **NO es accesible desde Internet**

Por seguridad, el MySQL solo es accesible **desde dentro de la red privada del proyecto Railway**: solo el backend (cuando esté desplegado en el mismo proyecto) podrá conectarse. Esto significa que **no se puede conectar Workbench todavía**. Para eso hace falta activar un *TCP Proxy* puntual, cosa que haremos en el sub-paso 6.4 cuando toque cargar los datos.

---

### 6.3. Servicio backend (Spring Boot)

#### 6.3.1. Conectar el repositorio

El primer despliegue automático ya creó una cajita de servicio (la que estaba fallando). Pulsar sobre ella y configurarla.

#### 6.3.2. Renombrar el servicio (opcional)

Por defecto el servicio toma el nombre del repositorio (`Victorino_Style`). Si se quiere, en *Settings → Service Name → `backend`*. En mi caso, lo dejé como `Victorino_Style` y para diferenciar visualmente sirve el dominio público generado: `victorinostyle-production.up.railway.app`.

#### 6.3.3. Configurar la **Source** (rama y carpeta)

Settings → sección **Source**:

| Campo | Valor | Por qué |
|---|---|---|
| **Source Repo** | `KevinFlow-ai/Victorino_Style` | Detectado automáticamente al conectar GitHub. |
| **Root Directory** | `Backend_Victorino` | **Sin barra inicial**. Railway interpreta esto como ruta relativa a la raíz del repo. Si pongo `/Backend_Victorino`, en algunas configuraciones lo interpreta como ruta absoluta del sistema → falla. |
| **Branch** | `Produccion-Railway` | La rama donde está todo el trabajo de producción. Railway hace **auto-deploy** cada vez que pusheo algo a esta rama. |
| **Wait for CI** | **Desactivado** | No tengo GitHub Actions configurado, así que no hay nada que esperar. En el futuro se activaría para que Railway solo despliegue si los tests pasan. |

#### 6.3.4. Configurar el **Build**

Settings → sección **Build**:

| Campo | Valor | Por qué |
|---|---|---|
| **Builder** | `Nixpacks` | Detecta automáticamente `pom.xml`, instala Maven y JDK, compila. |
| **Custom Build Command** | (vacío) | Nixpacks ya sabe ejecutar `./mvnw -DskipTests clean install`. No hace falta override. |
| **Watch Paths** | (vacío) | Por defecto cualquier cambio en la rama dispara redeploy. Si tuviera tests pesados aquí limitaría a `Backend_Victorino/**`. |

#### 6.3.5. Configurar el **Deploy**

Settings → sección **Deploy**:

| Campo | Valor | Por qué |
|---|---|---|
| **Custom Start Command** | `java -jar target/Backend_Victorino-0.0.1-SNAPSHOT.jar` | Le digo a Railway exactamente cómo arrancar el JAR generado por Maven. El nombre sale del `<artifactId>` y `<version>` del `pom.xml`. |
| **Healthcheck Path** | (vacío) | Por defecto Railway considera que el servicio está sano si responde a HTTP. Se podría apuntar a un endpoint `/actuator/health` si lo añadiera. |
| **Restart Policy** | `On Failure` (default) | Si el proceso muere, Railway lo reinicia automáticamente. |

#### 6.3.6. Crear el **Volume** para uploads

Settings → sección **Volumes** → **+ New Volume**:

| Campo | Valor |
|---|---|
| **Mount Path** | `/app/uploads` |
| **Name** | `victorino_style-volume` |
| **Size** | (por defecto, 5 GB del plan Hobby) |

Este volumen es el que persistirá las fotos. **Crítico**: el `Mount Path` debe coincidir EXACTAMENTE con la variable `VICTORINO_UPLOADS_DIRECTORIO` que se configura más abajo, porque es ahí donde el `UploadsSeederRunner` y `FileStorageService` escriben.

#### 6.3.7. Configurar las variables de entorno

Pestaña **Variables** del servicio backend.

**Forma rápida con Raw Editor**: pulsar **Raw Editor** (icono `< >` arriba a la derecha) y pegar:

```env
SPRING_DATASOURCE_URL=jdbc:mysql://${{MySQL.MYSQLHOST}}:${{MySQL.MYSQLPORT}}/${{MySQL.MYSQLDATABASE}}?useSSL=false&serverTimezone=Europe/Madrid&allowPublicKeyRetrieval=true
SPRING_DATASOURCE_USERNAME=${{MySQL.MYSQLUSER}}
SPRING_DATASOURCE_PASSWORD=${{MySQL.MYSQLPASSWORD}}
VICTORINO_JWT_SECRET=Y2FtYmlhbWVlbnByb2R1Y2Npb25fY2xhdmVfc2VjcmV0YV92aWN0b3Jpbm9fc3R5bGVfMjAyNg==
SPRING_MAIL_USERNAME=peluqueria.victorinostyle@gmail.com
SPRING_MAIL_PASSWORD=ysknifmendkfrwig
VICTORINO_ADMIN_PRUEBA_ACTIVO=true
VICTORINO_ADMIN_PRUEBA_PASSWORD=Admin1234!
VICTORINO_UPLOADS_DIRECTORIO=/app/uploads
VICTORINO_CORS_ORIGENES_EXTRA=
VICTORINO_FIREBASE_PROJECT_ID=victorino-style
NIXPACKS_JDK_VERSION=21
JAVA_TOOL_OPTIONS=-Xmx400m -Xms256m -XX:+UseSerialGC -XX:MaxMetaspaceSize=128m
```

**Update Variables**.

> Las `${{MySQL.XXX}}` son **referencias entre servicios** que Railway resuelve solo. No hay que sustituirlas a mano.

**La variable más delicada: `VICTORINO_FIREBASE_CREDENTIALS_JSON`** (multilínea, no encaja bien en el Raw Editor):

1. Abrir el archivo `Backend_Victorino/src/main/resources/firebase/victorino-firebase-key.json` con Notepad o IntelliJ.
2. Seleccionar TODO el contenido con `Ctrl+A` y copiar con `Ctrl+C`.
3. En Railway → Variables → **+ New Variable**:
   - **Name**: `VICTORINO_FIREBASE_CREDENTIALS_JSON`
   - **Value**: pegar el JSON entero (puede ser multilínea, Railway lo acepta).
4. **Add**.

#### 6.3.8. Generar el dominio público

Settings → sección **Networking** → **Generate Domain**. Railway asigna automáticamente:

```
victorinostyle-production.up.railway.app
```

(El nombre exacto depende del nombre del servicio. Si renombro el servicio, el dominio cambia.)

A partir de este momento, esa URL **expone públicamente el backend con HTTPS** (certificado Let's Encrypt automático).

Si Railway pregunta por **Public Port**, poner `8080` (es el que Spring Boot expone internamente; Railway lo redirige al 443/80 público).

#### 6.3.9. Lanzar el deploy

Tras configurar todo lo anterior, Railway encadena automáticamente un nuevo deploy. Si no lo hace solo, pulsar **Deploy** en la cajita del servicio.

Mirar el progreso en **Deployments → (el deploy en curso) → Build Logs**. Pasos esperados:

```
[1/6] Detectando proyecto... → Maven detectado
[2/6] Instalando JDK 21 (NIXPACKS_JDK_VERSION)
[3/6] Instalando Maven
[4/6] Ejecutando ./mvnw -DskipTests clean install
   ... (descarga dependencias, compila, empaqueta JAR)
   [INFO] BUILD SUCCESS
[5/6] Construyendo imagen Docker final
[6/6] Push de la imagen → ready
```

Y en **Deploy Logs**:

```
Starting Container
2026-05-22T18:19:37.604Z  INFO  [Backend_Victorino]: [FCM] Cargando credenciales desde variable inline (JSON).
2026-05-22T18:19:37.869Z  INFO  [Backend_Victorino]: [FCM] FirebaseApp inicializado correctamente.
2026-05-22T18:19:39....Z  INFO  Hibernate: create table administrador (...)
2026-05-22T18:19:39....Z  INFO  Hibernate: create table auditoria (...)
... (resto de tablas, porque Hibernate ddl-auto=update inicializa el esquema)
2026-05-22T18:19:40.694Z  INFO  Started BackendVictorinoApplication in 13.303 seconds
2026-05-22T18:19:40.700Z  INFO  [SEED uploads] Listo. Copiados: 7, ya existian: 0, base: /app/uploads
```

A partir de ese momento, **el backend está vivo**, escuchando en su dominio público, conectado a MySQL, con las fotos seed copiadas al volumen y Firebase listo para mandar push. **Pero la base de datos todavía no tiene los ~1000 datos del seed** (solo las tablas vacías que ha creado Hibernate inferencias de las @Entity).

---

### 6.4. Carga inicial de datos (schema + seed)

Esta es la parte más manual del despliegue. Lo más sencillo era usar MySQL Workbench (que ya tenía instalado) en lugar del cliente CLI `mysql`.

#### 6.4.1. Activar el *TCP Proxy* del MySQL

Por defecto, el MySQL solo es accesible desde dentro de Railway. Para conectarse desde Workbench (que corre en mi portátil) hay que abrir un proxy público:

1. En el canvas, pulsar la cajita **MySQL**.
2. Settings → **Networking** → **Public Networking**.
3. Pulsar **Generate Domain** (a veces aparece como **+ TCP Proxy** dependiendo de la UI). Railway crea un dominio público con un puerto aleatorio alto:
   ```
   monorail.proxy.rlwy.net:32400
   ```
   (El número del puerto cambia en cada proyecto).

Tras esto, Railway añade dos variables nuevas al servicio MySQL:
- `RAILWAY_TCP_PROXY_DOMAIN=monorail.proxy.rlwy.net`
- `RAILWAY_TCP_PROXY_PORT=32400`
- Y actualiza la variable `MYSQL_PUBLIC_URL` con la URL completa.

#### 6.4.2. Obtener credenciales para Workbench

Sigo en el servicio MySQL → **Variables**. Necesito:

| Campo de Workbench | Variable de Railway | Cómo obtenerlo |
|---|---|---|
| Hostname | `RAILWAY_TCP_PROXY_DOMAIN` (o lo que muestre Networking) | `monorail.proxy.rlwy.net` |
| Port | `RAILWAY_TCP_PROXY_PORT` | el número que mostró Networking, ej. `32400` |
| Username | `MYSQLUSER` | `root` |
| Password | `MYSQLPASSWORD` (pulsar el ojo 👁 para revelar) | la contraseña aleatoria de 32+ chars |
| Default Schema | `MYSQLDATABASE` | `railway` |

Apuntar todo en un bloc de notas temporal.

#### 6.4.3. Crear la conexión en MySQL Workbench

1. Abrir **MySQL Workbench**.
2. En la pantalla principal, junto a "MySQL Connections", pulsar el **`+`** (Setup New Connection).
3. Rellenar:
   - **Connection Name**: `Railway - Victorino Style`
   - **Hostname**: `monorail.proxy.rlwy.net` (sin el puerto)
   - **Port**: `32400` (el que dio Railway)
   - **Username**: `root`
   - **Default Schema**: `railway`
4. Pulsar **`Store in Vault...`** junto a Password y pegar la contraseña.
5. **`Test Connection`** → debe salir ✅ verde "Successfully made the MySQL connection".
6. **OK** para guardar.

> Si "Test Connection" falla, esperar 30 segundos tras crear el TCP Proxy a que Railway lo propague, y reintentar.

#### 6.4.4. Inspección inicial: ¿qué hay ya en la BD?

Doble clic en la conexión recién creada → se abre una pestaña de query. Ejecutar:

```sql
USE railway;
SHOW TABLES;
```

Resultado esperado: **15 tablas ya creadas** por Hibernate (`usuario`, `cliente`, `empleado`, `administrador`, `cliente_invitado`, `servicio`, `cita`, `peluqueria`, `horario_empleado`, `festivo`, `notificacion`, `auditoria`, `refresh_token`, `token_recuperacion`, `device_token_fcm`). Todas vacías.

> ⚠️ **Problema sutil**: las tablas que ha creado Hibernate son "buenas" pero **no idénticas** al `schema_railway.sql`. Por ejemplo:
> - La columna `plataforma_fcm` de `device_token_fcm` queda como `tinytext` en lugar del `ENUM('ANDROID','IOS','WEB')` correcto.
> - Faltan las constraints `CHECK` (como el XOR cliente/invitado en `cita`).
> - Faltan algunos índices personalizados.
>
> Por eso vamos a **borrarlas y recrearlas con la versión correcta** ejecutando `schema_railway.sql`, que empieza con `DROP TABLE IF EXISTS` antes de cada `CREATE TABLE`.

#### 6.4.5. Ejecutar `schema_railway.sql`

1. En Workbench: **File → Open SQL Script...**
2. Navegar a `C:\Users\El Jefe\IdeaProjects\Victorino_Style\Backend_Victorino\src\main\resources\db\schema_railway.sql` y abrir.
3. Workbench abre una pestaña nueva con el contenido del script.
4. **Importante**: asegurarse de que el "default schema" seleccionado en el panel izquierdo es `railway` (clic derecho → "Set as Default Schema").
5. Pulsar el botón ⚡ **"Execute (All or Selection)"** (atajo: `Ctrl+Shift+Enter`).

Workbench ejecuta las 15 sentencias `DROP TABLE IF EXISTS` seguidas de los 15 `CREATE TABLE` con todas las constraints, ENUM y CHECK. Aparecen 30+ líneas en el panel **Output** abajo, todas con tick verde:

```
DROP TABLE IF EXISTS usuario      0 row(s) affected
CREATE TABLE usuario              0 row(s) affected
DROP TABLE IF EXISTS cliente      0 row(s) affected
CREATE TABLE cliente              0 row(s) affected
...
```

Duración: ~5-10 segundos.

#### 6.4.6. Ejecutar `seed_railway.sql`

1. **File → Open SQL Script...** → abrir `seed_railway.sql` (misma carpeta).
2. ⚡ **Execute (All or Selection)**.

Este es **mucho más largo**: 1-3 minutos. Pasos que ejecuta:

- Define variables de sesión `@pwd`, `@pwd_emp`, `@pwd_cli_demo`, `@pwd_cli_20..@pwd_cli_59` con los hashes BCrypt.
- INSERT en `peluqueria` (1 fila).
- INSERT en `festivo` (15 filas con los festivos de Madrid 2026).
- INSERT en `usuario` + `empleado` + `administrador` (el admin Victorino + 2 empleados).
- INSERT en `horario_empleado` (3 filas, una por empleado).
- INSERT en `servicio` (4 filas).
- INSERT en `usuario` + `cliente` (50 clientes).
- **`DELIMITER //` + crea la stored procedure `generar_citas_demo` + `CALL generar_citas_demo()`**. Esta SP recorre día a día del 01/03/2026 al 20/06/2026 y genera ~1000 citas aleatorias respetando horarios, descansos y festivos. Además, por cada cita genera 2-4 notificaciones (confirmación al cliente, aviso al empleado, etc.).
- `DROP PROCEDURE generar_citas_demo` (limpieza).

Output esperado en Workbench:
```
INSERT INTO peluqueria                  1 row(s) affected
INSERT INTO festivo                    15 row(s) affected
INSERT INTO usuario                     1 row(s) affected   ← admin
INSERT INTO empleado                    1 row(s) affected
INSERT INTO administrador               1 row(s) affected
INSERT INTO horario_empleado            1 row(s) affected
... (los otros dos empleados)
INSERT INTO servicio                    4 row(s) affected
INSERT INTO usuario                    10 row(s) affected   ← clientes demo
INSERT INTO cliente                    10 row(s) affected
INSERT INTO usuario                    40 row(s) affected   ← clientes rasos
INSERT INTO cliente                    40 row(s) affected
CALL generar_citas_demo()               0 row(s) affected   ← lanza la SP
   (durante 1-3 minutos, ~1000 INSERT INTO cita + ~3000 INSERT INTO notificacion)
DROP PROCEDURE generar_citas_demo       0 row(s) affected
```

> ⚠️ **No cancelar mientras corre**. Si Workbench parece "colgado", está bien: la SP está iterando. Verás el contador de filas afectadas subir poco a poco.

#### 6.4.7. Verificar la carga

En una pestaña nueva (`Ctrl+T`):

```sql
USE railway;
SELECT COUNT(*) AS usuarios FROM usuario;
SELECT COUNT(*) AS citas FROM cita;
SELECT COUNT(*) AS servicios FROM servicio;
SELECT COUNT(*) AS notificaciones FROM notificacion;
SELECT correo_usuario, rol_usuario FROM usuario WHERE rol_usuario IN ('ADMINISTRADOR','EMPLEADO');
```

Valores esperados:

| Resultado | Esperado |
|---|---|
| usuarios | 53 (1 admin + 2 empleados + 10 clientes demo + 40 clientes rasos) |
| citas | ~1000-1300 (la cantidad exacta varía por el `RAND()` interno del procedimiento) |
| servicios | 4 |
| notificaciones | ~2000-4000 (cada cita genera 2-4 notificaciones) |
| Última query | 3 filas: `victorino@admin.com (ADMINISTRADOR)`, `maradona@victorinostyle.com (EMPLEADO)`, `jerson@victorinostyle.com (EMPLEADO)` |

Si los números cuadran, la BD está correctamente poblada.

#### 6.4.8. Reiniciar el backend

Aunque `ddl-auto=update` es no-destructivo, el pool de conexiones de Spring Boot puede tener referencias a las tablas viejas (las que Hibernate creó al principio y que el `DROP TABLE IF EXISTS` del schema reemplazó). Para un estado limpio, **reiniciar el backend**:

1. Railway → backend → pestaña **Deployments**.
2. En el deploy actual, pulsar el menú **`⋮`** (tres puntos) → **`Restart`**.

El backend se reinicia en ~10 segundos. En los logs aparecerá:
```
Started BackendVictorinoApplication in X seconds
[SEED uploads] Listo. Copiados: 0, ya existian: 7, base: /app/uploads
```
(Esta vez "Copiados: 0" porque las fotos ya estaban del primer arranque.)

#### 6.4.9. (Opcional) Cerrar el TCP Proxy

Una vez cargados los datos, **se puede cerrar el TCP Proxy** del MySQL para reducir la superficie de ataque. En el servicio MySQL → Settings → Networking → quitar el dominio público.

Yo lo dejé activo de momento por comodidad (para poder añadir o modificar datos manualmente desde Workbench durante la demo del TFG), pero en una producción real lo cerraría tras la carga inicial y solo lo abriría puntualmente para mantenimiento.

### 6.5. Resultado

```mermaid
sequenceDiagram
    actor Usuario as 👤 Usuario
    participant Browser as 🌐 Navegador
    participant Proxy as 🔐 Proxy Railway
    participant Backend as 🍃 Spring Boot
    participant MySQL as 🛢️ MySQL
    participant Volume as 💾 Volumen

    Usuario->>Browser: Abre Swagger UI
    Browser->>Proxy: GET /api/v1/swagger-ui.html (HTTPS)
    Proxy->>Backend: GET /api/v1/swagger-ui.html (HTTP)
    Backend->>Browser: HTML de Swagger
    Usuario->>Browser: POST /auth/login {correo, password}
    Browser->>Proxy: POST /auth/login (HTTPS)
    Proxy->>Backend: POST /auth/login (HTTP)
    Backend->>MySQL: SELECT * FROM usuario WHERE correo=?
    MySQL-->>Backend: Hash BCrypt
    Backend->>Backend: BCrypt.matches(password, hash)
    Backend->>Backend: Generar JWT firmado con HS256
    Backend->>MySQL: INSERT refresh_token (hash SHA-256)
    Backend-->>Browser: 200 {accessToken, refreshToken, rol, ...}
    Usuario->>Browser: GET /admin/dashboard
    Browser->>Backend: GET /admin/empleados (Bearer token)
    Backend->>Backend: Valida JWT
    Backend->>MySQL: SELECT FROM empleado
    Backend->>Volume: Resuelve /uploads/empleados/admin.png
    Backend-->>Browser: 200 + foto servida desde volumen
```
![alt text](image.png)

---

## 7. Errores reales que aparecieron y cómo se resolvieron

Esta sección es honesta sobre los problemas reales que aparecieron durante el despliegue. Conviene leerla porque demuestra **cómo se diagnostica un fallo en producción**, no solo cómo "todo salió a la primera".

### Error 1: El primer build fallaba sin saber por qué

![alt text](image-1.png)

**Síntoma**: justo después de conectar el repositorio, Railway intentó desplegar automáticamente y falló con un mensaje genérico.

**Causa**: Railway tomaba la rama por defecto del repo (`main`) y la carpeta raíz, pero el trabajo estaba en la rama `Produccion-Railway` y dentro de `Backend_Victorino/`.

**Solución**: en Settings → Source, cambiar Branch a `Produccion-Railway` y Root Directory a `Backend_Victorino`.

### Error 2: `error: release version 21 not supported`
![alt text](image-4.png)
**Síntoma**: tras configurar la rama y la carpeta, el build empezaba pero al compilar Maven fallaba con:

```
Failed to execute goal org.apache.maven.plugins:maven-compiler-plugin:3.14.1:compile
on project Backend_Victorino: Fatal error compiling: error: release version 21 not supported
```

**Causa**: el `pom.xml` exige `<java.version>21</java.version>` pero Nixpacks por defecto instala JDK 17.

**Primer intento fallido**: crear un archivo `system.properties` con `java.runtime.version=21`. Eso es **convención de Heroku, no de Railway**, así que Nixpacks lo ignoró.

**Solución correcta**: añadir una variable de entorno **`NIXPACKS_JDK_VERSION=21`** en Railway. Esta variable se la pasa Railway a Nixpacks para indicarle qué versión instalar.

> **Lección**: aunque las plataformas PaaS se parecen, las convenciones de configuración no son intercambiables.

### Error 3: Swagger UI devolvía "Failed to fetch" tras el login

**Síntoma**: ya con el backend funcionando, al abrir `https://victorinostyle-production.up.railway.app/api/v1/swagger-ui.html` e intentar hacer login desde la interfaz, el navegador mostraba:

```
Failed to fetch.
Possible Reasons: CORS, Network Failure, URL scheme must be "http" or "https" for CORS request.
```

**Causa**: Railway termina TLS en su proxy y pasa la petición al backend como HTTP plano. Spring Boot, al generar el documento OpenAPI, "veía" la petición como HTTP y ponía como URL del servidor `http://victorinostyle-production.up.railway.app`. Cuando Swagger UI (cargada vía HTTPS) intentaba llamar a `http://...`, el navegador bloqueaba la mezcla por **mixed content**.

**Solución**: añadir a `application.properties`:

```properties
server.forward-headers-strategy=framework
```

Con esto, Spring Boot **respeta el header `X-Forwarded-Proto: https`** que Railway pone, y reconstruye correctamente las URLs como `https://`.

### Error 4: Inconsistencia entre `password` y `contrasena`
![alt text](image-3.png)
**Síntoma**: al hacer login desde Swagger con `{"correo": "...", "contrasena": "..."}`, el backend devolvía 400 con `"field": "password", "message": "La contraseña es obligatoria"`.

**Causa**: el DTO `LoginRequest` tiene el campo `password` (en inglés) en lugar de `contrasena` (en español). Es una inconsistencia en el código original.

**Solución temporal (despliegue)**: enviar el JSON con `password` en lugar de `contrasena`. El cliente Flutter ya envía con el nombre correcto, así que no afecta a la app real, solo a las pruebas manuales con Swagger.

**Solución definitiva (futuro)**: renombrar el campo del record `LoginRequest` a `contrasena` y actualizar el `AuthService` y `AuthController` correspondientes. Tarea para un commit posterior.

### Error 5: Hibernate creó las tablas antes de poder cargar el schema.sql

**Síntoma**: tras arrancar el backend por primera vez, en la base de datos aparecieron las tablas, pero **versión simplificada**. Por ejemplo, la columna `plataforma_fcm` aparecía como `tinytext` en lugar del `ENUM('ANDROID','IOS','WEB')` correcto. Las constraints CHECK no estaban.

**Causa**: el `application.properties` tiene `spring.jpa.hibernate.ddl-auto=update`, que hace que Hibernate cree las tablas inferidas de las clases 
`@Entity` cada vez que arranca. Como el `schema_railway.sql` no se había cargado todavía, Hibernate lo hizo en su lugar y se "adelantó".

**Solución**: cargar `schema_railway.sql` desde MySQL Workbench (que tiene `DROP TABLE IF EXISTS` al principio de cada tabla, así que tira las creadas por Hibernate y las recrea con la definición correcta). Después, reiniciar el backend para que el pool de conexiones use el schema nuevo.

> **Alternativa más limpia (para futuro)**: cambiar `ddl-auto=update` a `ddl-auto=validate` (solo verifica el esquema, no lo modifica). Así se garantiza que el esquema oficial es siempre el del `.sql` y nunca uno generado por Hibernate.

### Error 6: Out of Memory esporádico
![alt text](image-2.png)
**Síntoma**: Railway mostraba un aviso con `Out of memory` y algunas peticiones a `/auth/login` devolvían 500 sin razón aparente.

**Causa**: el plan Hobby de Railway da **512 MB de RAM por servicio**. Spring Boot 4 con todas las dependencias (JPA, Hibernate, Firebase Admin, Springdoc, Spring Security) está al límite. El JVM, sin configurar, intenta usar más RAM de la disponible y el sistema lo mata.

**Solución**: añadir la variable de entorno

```
JAVA_TOOL_OPTIONS=-Xmx400m -Xms256m -XX:+UseSerialGC -XX:MaxMetaspaceSize=128m
```

Esto le dice al JVM:
- Heap máximo: 400 MB (deja 112 MB para metaspace, threads, etc.).
- Heap inicial: 256 MB.
- Garbage collector serial: el más simple, ideal para contenedores pequeños.
- Metaspace máximo: 128 MB.

Tras esto, el proceso se mantiene estable.

---

## 8. Verificación y pruebas

Tras todo el despliegue, las pruebas end-to-end realizadas:

| Prueba | Resultado |
|---|---|
| `GET /api/v1/swagger-ui.html` | 200, página de Swagger carga |
| `POST /api/v1/auth/login` con admin | 200 + JWT |
| `SELECT COUNT(*) FROM usuario` | 53 usuarios |
| `SELECT COUNT(*) FROM cita` | ~1000 citas |
| Foto `/uploads/empleados/admin.png` | Servida correctamente desde volumen |
| Log `[SEED uploads] Listo. Copiados: 7` | Confirmado en deploy logs |
| Log `[FCM] FirebaseApp inicializado correctamente` | Confirmado |

Resultado: **backend 100 % operativo en producción**.

---

## 9. Frontend Flutter Web (pendiente)

*Esta sección se completará cuando se despliegue el frontend. Resumen del plan:*

1. Crear segundo servicio en Railway desde el mismo repo, con Root Directory `frontend_victorino`.
2. Builder: Dockerfile (autodetecta el `Dockerfile` que ya está en el repo).
3. Build Arg: `API_BASE_URL=https://victorinostyle-production.up.railway.app/api/v1`.
4. Generar dominio público del frontend.
5. Actualizar `VICTORINO_CORS_ORIGENES_EXTRA` del backend con el dominio del frontend.
6. Verificar login end-to-end desde el navegador.

---

## 10. APK Android

Esta sección describe **cómo se generó el archivo `.apk` instalable en cualquier dispositivo Android**, las distintas formas de distribuirlo y cómo se instala en un móvil ajeno. El objetivo es que cualquier miembro del tribunal o cualquier compañero del ciclo pueda probar la aplicación en su propio teléfono **sin tener mi ordenador, sin compilar nada, y sin instalar ninguna IDE**.

### 10.1. Generación del APK

#### 10.1.1. Pre-requisitos

Para generar el APK hizo falta:

- **Flutter 3.41.2** instalado en mi máquina Windows (con el SDK de Android configurado).
- **Android SDK Build-Tools** (se descarga automáticamente la primera vez que Flutter genera un APK).
- El backend ya **desplegado en Railway** con su URL pública (`https://victorinostyle-production.up.railway.app/api/v1`), porque la URL se "hornea" dentro del APK en tiempo de compilación.
- El proyecto Flutter con los iconos generados, `google-services.json` en su sitio y el `AndroidManifest.xml` con los permisos correctos. 
**Todo eso ya estaba listo de pasos anteriores**, así que no hubo que tocar nada de código.

#### 10.1.2. Comando exacto utilizado

Desde PowerShell, en la carpeta del frontend:

```powershell
cd "C:\Users\El Jefe\IdeaProjects\Victorino_Style\frontend_victorino"
flutter clean
flutter pub get
flutter build apk --release --dart-define=API_BASE_URL=https://victorinostyle-production.up.railway.app/api/v1
```

**Desglose de cada comando**:

| Comando | Qué hace |
|---|---|
| `flutter clean` | Borra las carpetas `build/` y `.dart_tool/`. Garantiza un build limpio sin residuos de compilaciones anteriores. |
| `flutter pub get` | Descarga todas las dependencias listadas en `pubspec.yaml` (Firebase, dio, GoRouter, Riverpod, etc.). |
| `flutter build apk --release` | Compila el código Dart **a código nativo ARM** (no a JS como en Flutter Web). Modo `release` activa optimizaciones (tree-shaking, ofuscación, compresión). |
| `--dart-define=API_BASE_URL=...` | **Inyecta la URL del backend** dentro del bundle. El código Dart la lee con `String.fromEnvironment('API_BASE_URL')`. Es lo que hace que la app sepa a qué servidor llamar. |

#### 10.1.3. Resultado del build

Tras 5-15 minutos (dependiendo de si es la primera vez o ya está cacheado), Flutter mostró:

```
✓ Built build\app\outputs\flutter-apk\app-release.apk (XX.X MB).
```

Ubicación del archivo final:
```
C:\Users\El Jefe\IdeaProjects\Victorino_Style\frontend_victorino\build\app\outputs\flutter-apk\app-release.apk
```

**Tamaño del APK generado**: en torno a 40-80 MB. Flutter incluye su propio runtime nativo dentro del APK (Skia para el renderizado, motor Dart compilado, librerías ICU para internacionalización, etc.), por eso pesa más que una app nativa Java/Kotlin equivalente. Es el coste de tener multi-plataforma desde un único código.

#### 10.1.4. Verificación rápida

Antes de distribuir, **se instaló el APK en mi propio móvil Android** (Xiaomi) para confirmar que funciona end-to-end:

1. Copia del APK al móvil por cable USB.
2. Apertura desde el gestor de archivos del móvil.
3. Android pidió permiso para instalar desde "fuentes desconocidas" → concedido.
4. Instalación correcta. Icono "Victorino Style" en el cajón de apps con el logo configurado.
5. Apertura de la app → pantalla de login.
6. Login con `victorino@admin.com` / `Admin1234!` → entró correctamente al panel de administrador, mostrando datos reales del backend en Railway (las ~1000 citas, los 53 usuarios, los 4 servicios).

**Resultado: APK funcionando 100% end-to-end contra el backend en la nube**. La app del teléfono se comunica con la base de datos en Railway sin intermediarios locales.

### 10.2. Detalles técnicos del APK generado

Estos son los metadatos relevantes del APK final, por si surgen preguntas en la defensa:

| Propiedad | Valor | Notas |
|---|---|---|
| **applicationId** | `com.example.frontend_victorino` | Placeholder de Flutter. En un proyecto profesional se renombraría a `com.victorinostyle.app`, pero cambiarlo ahora rompería la vinculación con Firebase. Para el TFG se acepta. |
| **Nombre visible** | `Victorino Style` | Aparece en el cajón de apps. Definido en `AndroidManifest.xml` con `android:label`. |
| **Icono** | `mipmap/ic_launcher` + adaptive icon | Generado con `flutter_launcher_icons` a partir de `assets/logos_app/logo_app1.3.png` con fondo `#0A0A0F`. |
| **Version Name** | `1.0.0` | De `pubspec.yaml` (`version: 1.0.0+1`). Es lo que ve el usuario. |
| **Version Code** | `1` | El número interno (después del `+`). Android usa este para saber si una versión es más nueva. |
| **minSdk** | 23 (Android 6.0) | Mínimo según `flutter_launcher_icons` config. Cubre el ~99% de dispositivos activos en 2026. |
| **targetSdk** | el que pone Flutter por defecto (Android 14) | Indica que la app está probada para la última versión. |
| **Firma** | Debug keystore | Apto para distribución directa, no apto para Google Play. Ver punto siguiente. |
| **Permisos** | `INTERNET`, `POST_NOTIFICATIONS`, `WAKE_LOCK`, `RECEIVE_BOOT_COMPLETED` | Mínimos necesarios para conectarse al backend y recibir push. |
| **Backend URL** | `https://victorinostyle-production.up.railway.app/api/v1` (hardcodeada en el bundle vía `--dart-define`) | El usuario podría sobreescribirla en runtime desde la pantalla "Ajustes del servidor". |

#### 10.2.1. ¿Por qué el APK está firmado con la *debug keystore* y no con una *release keystore*?

En `android/app/build.gradle.kts` figura:

```kotlin
buildTypes {
    release {
        signingConfig = signingConfigs.getByName("debug")
    }
}
```

Es decir, **se firma con la keystore de depuración** de Flutter (un fichero generado automáticamente con credenciales conocidas). Implicaciones:

- ✅ **Funciona perfectamente** para distribución directa (Drive, GitHub Releases, WhatsApp). Cualquier Android puede instalarlo.
- ✅ **Cero configuración**: no hay que generar ni custodiar una keystore personal.
- ❌ **No se puede subir a Google Play Store** (Google exige una keystore propia que el desarrollador conserve).
- ❌ **No se pueden actualizar versiones firmadas con keystores distintas**: si más adelante quiero firmar con una keystore propia, el usuario tendrá que desinstalar el APK actual antes de instalar el nuevo.

**Para el TFG, firmar con debug es la elección correcta** porque el objetivo es la distribución directa al tribunal, no la publicación oficial. Si en una versión 2.0 se quisiera publicar en Play Store, habría que:

1. Generar una keystore propia con `keytool -genkey`.
2. Crear el fichero `android/key.properties` con la ruta y contraseña.
3. Modificar `build.gradle.kts` para usarlo en `release`.
4. **Guardar la keystore en sitio seguro** (si se pierde, jamás podrás actualizar la app publicada).
5. Pagar la cuota única de 25 USD de Google Play Console.

### 10.3. Opciones de distribución del APK

Una vez generado el archivo `app-release.apk`, hay varias formas de hacérselo llegar a otras personas. Comparativa de las opciones más realistas:

| Opción | Coste | Setup | Privacidad | Tope tamaño | Notas |
|---|---|---|---|---|---|
| **Google Drive** ✅ | Gratis (15 GB) | Subir + compartir enlace | Por enlace o restringido a correos | 5 TB | Lo más rápido. Funciona en cualquier dispositivo. Es lo que usé inicialmente. |
| **GitHub Releases** ✅✅ | Gratis | Crear release en GitHub | Pública (repo público) o privada | 2 GB por archivo | Lo más profesional: queda versionado, enlazado al commit exacto, con changelog. |
| **WeTransfer** | Gratis hasta 2 GB | Subir + enviar enlace | Link efímero (7 días) | 2 GB | Útil para envío puntual, pero el enlace caduca. |
| **Mega / Mediafire** | Gratis | Subir + compartir | Por enlace | 20-50 GB | Alternativas a Drive si el destinatario no quiere usar Google. |
| **WhatsApp / Telegram** | Gratis | Compartir archivo | Solo destinatarios elegidos | 100 MB WhatsApp / 2 GB Telegram | Telegram cabe perfecto. WhatsApp comprime y a veces falla. |
| **Appetize.io** | Gratis con límite | Subir APK al servicio | Pública o privada | 100 MB | **No es distribución**, es un emulador Android en navegador. Útil para que el tribunal lo "pruebe" desde un PC sin instalar nada. |
| **Firebase App Distribution** | Gratis | Setup CLI + invitar testers | Solo testers invitados | Limit alto | Lo más profesional para beta-testing. Pero requiere setup que para un TFG es excesivo. |
| **Diawi** | Gratis | Subir | Por enlace | 70 MB | Específico para distribución de APK/IPA. Limpio pero limitado en tamaño. |
| **Google Play (Internal Testing)** | 25 USD único | Crear cuenta dev + subir build + verificar | Cerrada a testers invitados | — | El estándar profesional. Requiere keystore release. Excesivo para TFG. |

**Decisión tomada para el TFG**: **Google Drive** para distribución a compañeros (rápido, conocido por todos, sin caducidad) + **enlace en la memoria del TFG** para que el tribunal lo descargue cuando quiera. Si el TFG saliera bien y se publicase, se migraría a GitHub Releases o Google Play.

### 10.4. Distribución elegida: Google Drive paso a paso

Esto es lo que se hizo para subir el APK y compartirlo:

#### 10.4.1. Subida del archivo

1. Abrir `https://drive.google.com` con mi cuenta personal.
2. Crear una carpeta nueva: **`Victorino Style — APK`**.
3. Dentro de la carpeta, pulsar **`+ Nuevo`** → **`Subir archivo`**.
4. Seleccionar `app-release.apk` de `C:\Users\El Jefe\IdeaProjects\Victorino_Style\frontend_victorino\build\app\outputs\flutter-apk\`.
5. **Renombrarlo** a algo más descriptivo, ej. `VictorinoStyle-v1.0.0.apk` (clic derecho → Cambiar nombre). Esto evita el genérico `app-release.apk` y deja constancia de la versión.
6. Esperar a que termine la subida (60-100 MB tarda 30 segundos con buena conexión).

#### 10.4.2. Configurar los permisos del enlace

Hay dos modos según con quién se quiera compartir:

**Modo A — "Cualquiera con el enlace"** (recomendado para tribunal + compañeros):

1. Clic derecho sobre el archivo → **`Compartir`** → **`Compartir`**.
2. En "Acceso general", cambiar de "Restringido" a **"Cualquier persona con el enlace"**.
3. Rol: **`Lector`** (solo descarga, no edición).
4. **`Copiar enlace`**.
5. El enlace tiene esta forma: `https://drive.google.com/file/d/1XXXXXXXXXXX/view?usp=sharing`.

**Modo B — "Solo correos específicos"** (más estricto):

1. Mismo menú **`Compartir`**.
2. En el campo de correos, añadir los correos del tribunal o de tus compañeros uno a uno.
3. Rol: **`Lector`**.
4. Activar **`Notificar`** para que les llegue un email con el enlace.

Para el TFG se usó **Modo A**: cualquier persona con el enlace puede descargar, lo que cubre tanto al tribunal (que aún no sabes qué correo tienen) como a los compañeros que lo quieran probar.

#### 10.4.3. (Opcional) Generar un enlace de descarga directa

El enlace que da Drive por defecto abre una página de previsualización. Para distribuir un enlace que **descargue directamente** el APK al pulsarlo (más cómodo desde el móvil), se transforma así:

Enlace normal:
```
https://drive.google.com/file/d/ABC123XYZ456/view?usp=sharing
```

Enlace de descarga directa:
```
https://drive.google.com/uc?export=download&id=ABC123XYZ456
```

(Se sustituye la parte `/file/d/<ID>/view?usp=sharing` por `/uc?export=download&id=<ID>` manteniendo el mismo ID).

> **Nota**: para archivos grandes (>100 MB) Google Drive intercala una página de aviso "el archivo es grande, ¿descargar de todos modos?". No se puede saltar, pero es solo un clic más.

### 10.5. Guía de instalación para el usuario final

Esta es **la guía que se entrega al tribunal o a un compañero** junto con el enlace de descarga. Asume cero conocimiento técnico.

#### 10.5.1. Requisitos previos

- Un dispositivo Android con versión **6.0 (Marshmallow) o superior**.
- Espacio libre: al menos **150 MB** (el APK ocupa ~90 MB, pero la instalación requiere algo más).
- Conexión a Internet (para descargar el APK y para que la app funcione contra el backend).

#### 10.5.2. Pasos para instalar el APK

**Paso 1 — Descargar el APK al móvil**

Opción A (desde el enlace de Drive):
1. Abre el enlace del Drive en el navegador del móvil (Chrome).
2. Si te muestra la previsualización, pulsa el icono de descarga (la flecha hacia abajo, normalmente arriba a la derecha).
3. Google Drive avisará: "Este archivo puede ser perjudicial. ¿Descargarlo de todos modos?" → **Sí, descargar**. (Lo dice porque es un APK; no significa que tenga virus, solo es la advertencia estándar de Android ante cualquier instalable que no venga de Play Store).
4. Espera a que la descarga termine. Quedará en la carpeta `Descargas` del móvil.

Opción B (si te lo paso por Telegram/WhatsApp):
1. Pulsa el archivo en la conversación → "Descargar".

**Paso 2 — Permitir instalación de "fuentes desconocidas"**

Esto es **obligatorio una sola vez** porque el APK no viene de Google Play.

En Android 8+ (la mayoría de móviles modernos):
1. Abre el gestor de archivos del móvil (o el navegador donde lo descargaste).
2. Pulsa el archivo `VictorinoStyle-v1.0.0.apk`.
3. Android dirá: *"Por seguridad, no se permite instalar apps desconocidas desde esta fuente. Puedes cambiarlo en Ajustes"*.
4. Pulsa **`Ajustes`** en el aviso → activa el interruptor **`Permitir desde esta fuente`**.
5. Vuelve atrás. Android te volverá a preguntar si quieres instalar.

En Android 7 o anterior:
1. Ajustes → Seguridad → activar **`Orígenes desconocidos`**. Luego pulsa el APK.

**Paso 3 — Instalar**

1. Android muestra una pantalla con el icono y nombre de la app: **Victorino Style**.
2. Pulsa **`Instalar`**.
3. Espera 10-15 segundos.
4. Pulsa **`Abrir`** cuando termine.

**Paso 4 — Probar la app**

1. Al abrir verás la pantalla de bienvenida / login.
2. Para hacer login como **administrador** (acceso completo a todas las funciones):
   - Correo: `victorino@admin.com`
   - Contraseña: `Admin1234!`
3. Para hacer login como **empleado** (vista de peluquero):
   - Correo: `maradona@victorinostyle.com` o `jerson@victorinostyle.com`
   - Contraseña: `Empleado1234!`
4. Para hacer login como **cliente** (uno de los 50 ya cargados):
   - Correo: `andres.lozano@gmail.com` (o cualquiera de los demás)
   - Contraseña: `Cliente1234!` (para los 10 demos) o `Cliente20!`/`Cliente21!`/... para los rasos.

#### 10.5.3. Permisos que pedirá la app la primera vez

Tras el primer login, la app pedirá algunos permisos según las funciones que se usen:

- **Notificaciones**: para recibir confirmaciones, recordatorios 24h, cancelaciones. → Permitir.
- **Cámara / Galería**: solo si se intenta cambiar la foto de perfil. → Permitir cuando se pida.
- **Almacenamiento**: para guardar fotos descargadas. → Permitir cuando se pida.

#### 10.5.4. Desinstalación

Como cualquier otra app: mantener pulsado el icono → **`Desinstalar`**.

### 10.6. Alternativa para quien no quiere instalar nada: Appetize.io

Si algún miembro del tribunal **no quiere instalar la app en su móvil personal**, existe la opción de ejecutarla en un **emulador Android dentro del navegador** vía Appetize.io:

1. Crear cuenta gratuita en `https://appetize.io`.
2. Subir el archivo `app-release.apk`. Plan gratuito permite hasta 100 MB y 30 minutos de uso al mes.
3. Appetize genera un enlace único tipo `https://appetize.io/app/<id>` que abre un emulador Android en cualquier navegador.
4. El tribunal usa la app **sin instalar nada** en su dispositivo.

**Limitaciones**:
- 30 minutos al mes en el plan gratuito.
- Las notificaciones push no se reciben en el navegador (Appetize no tiene FCM completo).
- El rendimiento es menor que en un móvil real.

**Cuándo usarlo**: para una primera impresión rápida o si el tribunal evalúa el TFG desde un PC sin móvil cerca. Para una evaluación realista, instalar en un móvil real sigue siendo lo recomendable.

### 10.7. FAQ específico sobre el APK

**P: ¿Por qué Android me dice "no se permite instalar apps desconocidas"?**
R: Es una protección de Android. Como el APK no viene de Google Play Store (no he pagado los 25€ y publicado oficialmente porque es un TFG), el sistema lo considera "fuente desconocida". Activar el permiso una sola vez es seguro porque el archivo viene directamente de mí.

**P: ¿Por qué pesa 60 MB si la app no parece tan grande?**
R: Flutter incluye su propio runtime (motor Skia para renderizar, motor Dart, librerías nativas) dentro de cada APK. Es el coste de hacer multi-plataforma con un único código fuente. Una app nativa equivalente en Kotlin pesaría ~10 MB, pero requeriría mantener un código aparte para iOS.

**P: ¿Funciona en iPhone / iPad?**
R: No directamente — el APK es exclusivo de Android. Para iOS habría que generar un IPA (`flutter build ios`), pero eso requiere **un Mac, una cuenta de Apple Developer (99 USD/año) y firmar con certificado**. Por coste y tiempo se descartó para el TFG.

**P: ¿Cómo actualizo a una versión nueva si la sacas?**
R: Mientras se firme con la misma keystore (la debug en este caso), basta con descargar el nuevo APK e instalarlo encima. Android lo detecta como actualización y conserva los datos locales. Si en el futuro cambio de keystore (al migrar a una propia), habrá que desinstalar la versión antigua antes.

**P: ¿La app consume muchos datos móviles?**
R: Las peticiones HTTP son pequeñas (JSON de pocos KB cada una). Solo las fotos (subir foto de perfil o ver fotos de servicios) usan ancho de banda relevante. Estimación: <5 MB por sesión típica de uso, salvo que se suban muchas fotos.

**P: ¿Funciona sin conexión a Internet?**
R: No. La app es un cliente que **siempre** necesita hablar con el backend en Railway. Sin Internet sale un error. Una versión futura podría tener caché local con SQLite para algunas vistas, pero no es prioridad.

**P: ¿Se pueden ver los datos personales de los usuarios desde el APK?**
R: Solo los datos del rol con el que has hecho login. Un cliente ve sus propias citas y los empleados de la peluquería. Un empleado ve su propia agenda. Un administrador ve todo. Spring Security en el backend impone estas restricciones; el frontend solo muestra lo que el backend le devuelve.

**P: ¿Qué pasa con las notificaciones push si tengo el móvil en modo "No molestar"?**
R: Las notificaciones llegan al móvil (queda registro en la pestaña de notificaciones) pero **no suenan**. Cuando salgas del modo "No molestar" las verás en la bandeja del sistema. Es el comportamiento normal de Android.

**P: ¿Y si Google decide bloquear el APK como "potencialmente peligroso"?**
R: Puede pasar la primera vez que un usuario lo descarga porque Google Play Protect escanea APKs no firmados por desarrolladores verificados. Suele bastar con pulsar "Instalar de todos modos". Si fuera un problema recurrente, la solución profesional sería pagar la cuota de Google y publicarlo en Play Store, pero excede el alcance del TFG.

---

## 11. iOS (iPhone / iPad)

> ⚠️ **Esta sección es teórica**: el TFG no ha generado la versión iOS porque para hacerlo se necesita un Mac físico (Apple solo permite compilar iOS con Xcode, que únicamente existe en macOS) y una cuenta de Apple Developer de pago. Aun así, **el código Flutter ya está preparado** para que, en una máquina con esos requisitos, la compilación funcione sin tocar el código fuente. Esta sección documenta cómo se haría, paso a paso, asumiendo que se parte de un **Mac completamente vacío** sin ningún programa instalado.

### 11.1. Por qué Flutter permite generar iOS desde el mismo código

Flutter es un framework **multi-plataforma**: el código Dart que se ha escrito para la peluquería sirve, sin cambios, para Android, iOS, Web, Windows, 
Linux y macOS. Cada plataforma se compila a binario nativo de esa plataforma (no es una WebView ni un emulador): la app en iPhone 
corre tan fluida como una app nativa Swift/Objective-C.

Esto se nota especialmente en:
- Las animaciones (60 fps nativos).
- El consumo de memoria (similar al de una app nativa).
- Acceso a APIs del sistema (cámara, notificaciones push, biometría) a través de plugins oficiales.

**Conclusión clave**: el coste de añadir el soporte iOS al proyecto **es cero en términos de programación**; el coste está en la infraestructura 
(hardware + cuenta de desarrollador). De ahí la decisión de no hacerlo dentro del alcance del TFG, pero dejarlo "preparado para cuando se quiera".

### 11.2. Requisitos previos (hardware + cuentas)

Para compilar y firmar la app iOS hace falta:

#### 11.2.1. Hardware: un Mac

| Modelo | Coste aprox. | Validez |
|---|---|---|
| Mac mini M2 (8 GB RAM, 256 GB SSD) | ~700 € | ✅ Recomendado. Suficiente para compilar Flutter iOS sin problema. |
| MacBook Air M2 | ~1.200 € | ✅ Si se necesita portabilidad |
| MacBook Pro M3 | ~1.700 € | ✅ Si se quiere lo mejor, pero excesivo para un TFG |
| iMac M3 | ~1.500 € | ✅ Si se quiere todo-en-uno |
| Mac Intel antiguo (2018+) | 300-500 € usado | ⚠️ Compila pero las nuevas versiones de Xcode (16+) ya solo soportan macOS Sonoma 14+ y exigen Apple Silicon o Intel reciente. Revisar compatibilidad antes de comprar. |
| Cualquier PC con Hackintosh / macOS virtualizado | "gratis" | ❌ **Viola los Términos de Uso de Apple**, no es legalmente válido para distribuir apps. Descartado para un TFG. |

Mi recomendación si alguien quiere replicar el despliegue iOS: **Mac mini M2** (700 € es el precio de entrada más bajo razonable y rinde de sobra).

#### 11.2.2. Cuenta de Apple Developer

Apple obliga a tener una cuenta de desarrollador para:
- Firmar el APK iOS (en iOS se llama IPA).
- Distribuir la app a otras personas (sin esto, solo puedes instalarla en tu propio iPhone con un workaround llamado "free provisioning", limitado a 7 días).
- Subir a TestFlight (beta-testing oficial) o App Store.

Tipos de cuenta:

| Tipo | Coste | Para qué |
|---|---|---|
| **Apple ID gratis** | 0 € | Solo instalar en tu propio iPhone con caducidad de 7 días. Cada semana hay que volver a sideloadear desde Xcode. **Para una demo del TFG es viable pero molesto**. |
| **Apple Developer Program (individual)** | **99 USD/año** (~91 €/año, no es pago único) | Distribución vía TestFlight, App Store, Ad-hoc. Lo que se usaría en serio. |
| **Apple Developer Enterprise** | 299 USD/año | Solo para empresas, distribución interna. No aplica al TFG. |

**Coste total estimado para una versión iOS distribuible**: ~800 € de entrada (Mac) + 91 €/año (cuenta). En un TFG, esto no compensa frente al APK Android que ya cubre el 70-80% del mercado en España.

### 11.3. Preparación del Mac (desde cero)

Asumimos que el Mac está recién encendido por primera vez, con el sistema operativo de fábrica (macOS Sequoia o equivalente) y nada más.

#### 11.3.1. Actualizar macOS

1. **Apple () → Ajustes del Sistema → General → Actualización de software**.
2. Si hay actualizaciones pendientes, instalarlas todas. Para Xcode 16 hace falta macOS Sonoma 14+ o Sequoia 15+.
3. Reiniciar.

#### 11.3.2. Instalar Xcode

Xcode es el IDE oficial de Apple. Es **obligatorio**: contiene el compilador Swift, los simuladores de iPhone, las herramientas de firma, y todo el SDK de iOS.

1. Abrir **App Store** (icono azul con una "A").
2. Buscar **Xcode**.
3. **Obtener** → **Instalar**. Pide la contraseña del Apple ID.
4. **Descarga de ~12 GB**, instalación final de ~40 GB. Tarda **30-90 minutos** según conexión y velocidad del disco.
5. Una vez instalado, abrir Xcode una vez para que termine de configurar componentes adicionales (CommandLineTools, simuladores, etc.). Aceptar la licencia.
6. Aceptar la licencia desde terminal también para que otras herramientas (como Flutter) la respeten:
   ```bash
   sudo xcodebuild -license accept
   ```

#### 11.3.3. Instalar Command Line Tools

Aunque Xcode ya incluye las herramientas de línea de comandos, conviene asegurarse:

```bash
xcode-select --install
```

Si ya están, dirá "command line tools are already installed". Si no, abre un instalador gráfico.

#### 11.3.4. Instalar Homebrew

Homebrew es el "apt-get" de macOS, el gestor de paquetes que usaremos para instalar Flutter, Git y CocoaPods.

En Terminal:
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Tras la instalación, **seguir las instrucciones que muestre en pantalla** (suele pedir añadir Homebrew al PATH con dos comandos). En Mac Apple Silicon (M1/M2/M3) son típicamente:
```bash
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"
```

Verificación:
```bash
brew --version
```

#### 11.3.5. Instalar Git

```bash
brew install git
```

#### 11.3.6. Instalar Flutter SDK

Dos opciones:

**Opción A — vía Homebrew (recomendada)**:
```bash
brew install --cask flutter
```

**Opción B — descarga manual**:
1. Descargar el SDK de Flutter desde `https://flutter.dev/docs/get-started/install/macos`.
2. Descomprimir el ZIP en `~/development/flutter`.
3. Añadir al PATH:
   ```bash
   echo 'export PATH="$PATH:$HOME/development/flutter/bin"' >> ~/.zprofile
   source ~/.zprofile
   ```

Verificación:
```bash
flutter --version
```
Debe devolver `Flutter 3.41.2` o similar.

#### 11.3.7. Instalar CocoaPods

CocoaPods es el gestor de dependencias nativas iOS (equivalente a Gradle en Android). Flutter lo usa para Firebase, plugins, etc.

```bash
sudo gem install cocoapods
```

Si pide la contraseña del Mac, introducirla. Tarda unos minutos.

#### 11.3.8. Verificación final con `flutter doctor`

```bash
flutter doctor
```

Resultado esperado:
```
[√] Flutter (3.41.2, on macOS ...)
[√] Android toolchain  (opcional, solo si también quieres compilar Android desde el Mac)
[√] Xcode - develop for iOS and macOS (Xcode 16.x)
[√] Chrome - develop for the web
[√] Connected device
```

Si Xcode aparece con ❌ o ⚠️, leer el mensaje: suele faltar `xcodebuild -license accept` o algún componente menor.

### 11.4. Clonar el repositorio y configurar el proyecto iOS

#### 11.4.1. Clonar

```bash
cd ~
mkdir -p IdeaProjects
cd IdeaProjects
git clone https://github.com/KevinFlow-ai/Victorino_Style.git
cd Victorino_Style/frontend_victorino
```

> Si el repositorio es privado, Git pedirá credenciales o token. Recomendado usar `gh auth login` (de la GitHub CLI) o un Personal Access Token.

#### 11.4.2. Instalar dependencias Flutter

```bash
flutter pub get
```

#### 11.4.3. Instalar dependencias iOS nativas

```bash
cd ios
pod install --repo-update
cd ..
```

Esto descarga los pods de Firebase y todas las dependencias nativas iOS. Tarda 5-10 minutos la primera vez.

#### 11.4.4. Configurar Firebase para iOS

El proyecto **ya tiene Firebase configurado para Android** (`google-services.json`). Para iOS hace falta un archivo equivalente llamado 
**`GoogleService-Info.plist`** que **NO está en el repositorio** (por eso `flutter_launcher_icons` generó iconos iOS pero no se puede compilar todavía).

Para obtenerlo:

1. Ir a la consola Firebase: `https://console.firebase.google.com`.
2. Entrar al proyecto **`victorino-style`** (el mismo que usa Android).
3. **Configuración del proyecto** (engranaje) → **General**.
4. En la sección "Tus apps", pulsar **`Agregar app`** → icono de Apple (iOS+).
5. Bundle ID: `com.example.frontend_victorino` (debe coincidir EXACTAMENTE con el que Flutter pone por defecto, que figura en `ios/Runner.xcodeproj/project.pbxproj` como `PRODUCT_BUNDLE_IDENTIFIER`).
6. Nickname: `Victorino Style iOS`.
7. App Store ID: vacío (no aplica todavía).
8. **Registrar**.
9. Firebase ofrece descargar **`GoogleService-Info.plist`**. Descargar.
10. Mover el archivo a `frontend_victorino/ios/Runner/` (con drag & drop en Xcode para que se incluya en el target Runner correctamente).

#### 11.4.5. Abrir el proyecto en Xcode

```bash
open ios/Runner.xcworkspace
```

> ⚠️ **Abrir `.xcworkspace`, no `.xcodeproj`**. La diferencia es importante: `xcworkspace` incluye los pods de CocoaPods; `xcodeproj` solo el proyecto principal y fallará al compilar.

#### 11.4.6. Configurar la firma del código (Signing)

Esto es lo más friccionante. En Xcode:

1. Seleccionar el proyecto **Runner** (icono azul, arriba a la izquierda).
2. Pestaña **Signing & Capabilities** → target **Runner**.
3. Marcar **`Automatically manage signing`**.
4. **Team**: desplegable. Hay que haber iniciado sesión con un Apple ID:
   - Si es Apple ID gratis (sin Developer Program): aparece como "Free" y permite firmar para "personal use".
   - Si es Apple ID con Developer Program: aparece tu nombre o el de tu organización, permite distribución.
5. Xcode genera automáticamente un certificado de firma y un **provisioning profile** asociado al Bundle ID.

Si aparece un error rojo tipo *"No matching profiles found"*:
- Comprobar que el Apple ID tiene acceso a la cuenta Developer en *Xcode → Settings → Accounts*.
- O cambiar el Bundle ID a uno único: `com.<tudominio>.victorinostyle`.

#### 11.4.7. Configurar capacidades adicionales

En la misma pestaña **Signing & Capabilities**, pulsar **+ Capability** y añadir:

- **Push Notifications** (para FCM).
- **Background Modes** → activar `Remote notifications`.

### 11.5. Iconos para iOS (ya generados)

Cuando ejecutamos `dart run flutter_launcher_icons` durante la preparación, **ya se generaron todos los iconos iOS**. Ubicación:

```
frontend_victorino/ios/Runner/Assets.xcassets/AppIcon.appiconset/
```

Se generaron 20+ tamaños distintos (iPhone, iPad, Settings, Notifications, Spotlight, App Store), cada uno en sus densidades `@1x`, `@2x`, `@3x`. Algunos ejemplos:

| Archivo | Tamaño | Para qué |
|---|---|---|
| `Icon-App-60x60@3x.png` | 180×180 | Icono en pantalla principal del iPhone 6 Plus en adelante |
| `Icon-App-76x76@2x.png` | 152×152 | Icono en pantalla principal del iPad |
| `Icon-App-1024x1024@1x.png` | 1024×1024 | App Store marketing icon |
| `Icon-App-29x29@2x.png` | 58×58 | Icono de Ajustes |

> **Nota técnica**: iOS NO usa adaptive icons como Android. Cada tamaño es una imagen separada, fija, sin transparencias. Por eso en la configuración pusimos `remove_alpha_ios: true` y `background_color_ios: "#0A0A0F"`: el plugin aplana el PNG transparente sobre el fondo oscuro para evitar el rechazo de App Store (Apple no admite iconos con canal alfa).

Resultado: cuando se instale la app en un iPhone aparecerá con el mismo logo que en Android, **sin tocar más código**.

### 11.6. Generación del archivo IPA

Una vez todo configurado, generar el IPA es un solo comando:

```bash
cd ~/IdeaProjects/Victorino_Style/frontend_victorino
flutter build ipa --release \
  --dart-define=API_BASE_URL=https://victorinostyle-production.up.railway.app/api/v1
```

Resultado en:
```
frontend_victorino/build/ios/ipa/frontend_victorino.ipa
```

Tamaño esperado: 50-90 MB (similar al APK Android).

### 11.7. Distribución del IPA

A diferencia del APK Android, **iOS NO permite instalar IPAs descargados de Internet libremente**. Apple impone canales oficiales. Las opciones son:

| Canal | Coste | Quién puede instalar | Setup |
|---|---|---|---|
| **TestFlight** ✅ | Incluido en Developer Program | Hasta 10.000 testers invitados por correo | Subir IPA a App Store Connect → asignar testers → ellos instalan TestFlight desde App Store y abren el invite |
| **Ad-hoc** | Incluido en Developer Program | Hasta 100 dispositivos cuyos UDID estés registrados | Pedir el UDID a cada tester, registrarlo, regenerar provisioning profile, recompilar IPA, distribuir |
| **App Store** | Incluido en Developer Program | Cualquiera con un iPhone | Subir IPA → review de Apple (1-7 días) → publicación |
| **Free Provisioning** | Gratis | Solo tu iPhone, válido 7 días | Conectar iPhone por USB y `flutter run --release` desde Xcode. Se reinstala manualmente cada semana. |
| **Enterprise** | 299 USD/año, solo empresas | Empleados de la empresa | No aplica al TFG |
| **Diawi / Installonair** | Gratis con límite | Pocos dispositivos | Sube IPA al servicio, te dan enlace, los testers instalan vía Safari. **Solo funciona con Ad-hoc provisioning** (UDIDs registrados) |

**Para un TFG, lo recomendable sería TestFlight**:

1. Comprar Apple Developer Program (99 USD/año).
2. Abrir Xcode → Window → Organizer → Distribute App → seleccionar el `.ipa`.
3. Subirlo a App Store Connect.
4. En App Store Connect → TestFlight → invitar al tribunal por correo.
5. Los miembros del tribunal reciben un email, instalan TestFlight en su iPhone desde App Store, abren el invite y descargan tu app.

### 11.8. FAQ específico iOS

**P: ¿Por qué Apple obliga a usar Mac?**
R: Es una decisión comercial de Apple. Xcode es propietario y solo corre en macOS. No hay alternativa legal: cualquier "Hackintosh" o macOS virtualizado en PC viola los Términos de Uso de Apple y el IPA generado puede ser rechazado por App Store.

**P: ¿Por qué Apple cobra 99 USD/año si Google cobra 25 USD pago único?**
R: Política comercial. Es un modelo de suscripción que Apple justifica con los servicios incluidos (TestFlight, App Analytics, App Store Connect, etc.). Quien deja de pagar pierde la capacidad de subir actualizaciones, pero la app publicada sigue en App Store hasta el siguiente reset.

**P: ¿Funcionará todo igual que en Android?**
R: Sí, salvo detalles cosméticos: las notificaciones tienen estilo iOS (no Material), el indicador de carga es el de iOS por defecto, etc. La lógica de negocio y las pantallas son **idénticas** porque Flutter las renderiza con su propio motor (Skia), no usa componentes nativos del sistema.

**P: ¿Las notificaciones push funcionan en iPhone?**
R: Sí, pero hay un paso extra: hay que generar un **APNs Auth Key** en *https://developer.apple.com → Keys* y subirlo a Firebase Console → Project Settings → Cloud Messaging → Apple app configuration. Tras esto, FCM enruta a APNs automáticamente y el iPhone las recibe.

**P: ¿Se podría hacer el TFG todo desde un Mac y olvidarse de Windows?**
R: Sí. Flutter funciona idéntico en macOS y Windows. La elección de mi entorno (Windows con WSL para Linux) fue por coste y porque ya tenía el equipo. Un Mac habría permitido cubrir Android + iOS + Web + macOS desde un único equipo, pero supone una inversión inicial que el TFG no justificaba.

---

## 12. Windows (escritorio)

> ⚠️ **Sección teórica**: el TFG no ha generado el ejecutable Windows porque **mi máquina no tiene instalado Visual Studio** y, una vez generado, 
**la distribución en Windows es menos cómoda que en Android/Web** (no hay tienda equivalente a Play Store que el usuario tipo conozca y use de 
forma natural). El código Flutter ya está preparado, así que un futuro `flutter build windows` funcionaría tras instalar el toolchain.

### 12.1. ¿Por qué Flutter para Windows?

Flutter 3.x soporta de forma estable la generación de **aplicaciones nativas Windows x64**, no es WebView ni Electron. Comparte el 
99% del código con Android/iOS/Web y se compila a un `.exe` con varias DLLs adjuntas. Casos de uso típicos:

- Una empresa quiere un cliente "de escritorio" para PCs.
- El usuario prefiere un programa siempre disponible en la bandeja del sistema, sin pasar por navegador.
- Funciones específicas de escritorio (atajos de teclado, multiventana).

Para Victorino Style (una peluquería) el caso de uso real es marginal: los clientes usarán móvil, los empleados un móvil o 
web, y el administrador puede usar la web. Por eso se documenta como "soportable pero no implementado".

### 12.2. Requisitos en una máquina Windows

| Componente | Coste | Notas |
|---|---|---|
| Windows 10 / 11 (64 bits) | — | Cualquier máquina moderna lo cumple |
| Flutter SDK | gratis | El mismo que para Android |
| **Visual Studio 2022 Community** | gratis | Es **obligatorio** para compilar C++ nativo. La edición Community es gratis para uso personal y proyectos open source / TFG. |
| Carga "Desktop development with C++" | incluida en VS | Sin esta carga `flutter build windows` falla. Selectable durante la instalación de Visual Studio. |
| Espacio en disco | ~12 GB | Para Visual Studio + Flutter |

### 12.3. Preparación de la máquina

1. Descargar **Visual Studio Community 2022** de `https://visualstudio.microsoft.com/downloads/`.
2. Ejecutar el instalador. En la pantalla "Workloads", marcar **`Desktop development with C++`** (todos los componentes por defecto).
3. Instalar (~5-8 GB de descarga, 30-60 minutos).
4. Reiniciar la máquina.
5. Comprobar con:
   ```powershell
   flutter doctor
   ```
   Debe aparecer:
   ```
   [√] Visual Studio - develop Windows apps (Visual Studio Community 2022 17.x.x)
   ```

### 12.4. Generación del ejecutable

Una vez Visual Studio instalado:

```powershell
cd "C:\Users\El Jefe\IdeaProjects\Victorino_Style\frontend_victorino"
flutter clean
flutter pub get
flutter build windows --release `
  --dart-define=API_BASE_URL=https://victorinostyle-production.up.railway.app/api/v1
```

Tiempo: 3-10 minutos.

Resultado en:
```
build\windows\x64\runner\Release\
├── frontend_victorino.exe         ← el ejecutable principal
├── flutter_windows.dll
├── data\
└── (otras DLLs de plugins)
```

**El usuario final necesita la carpeta COMPLETA**, no solo el `.exe`. El `.exe` por sí solo no arranca: necesita las DLLs y la carpeta `data/`.

### 12.5. Iconos para Windows (ya generados)

`flutter_launcher_icons` generó:
```
frontend_victorino/windows/runner/resources/app_icon.ico
```

Es un fichero ICO con varios tamaños embebidos (16x16, 32x32, 48x48, 256x256). El `runner.exe` lo embebe automáticamente al compilar, 
por lo que el `.exe` final muestra el logo de Victorino Style en el explorador de archivos y en la barra de tareas.

### 12.6. Distribución del ejecutable Windows

Las opciones más realistas:

| Opción | Coste | Setup | Notas |
|---|---|---|---|
| **ZIP comprimido** ✅ | Gratis | Comprimir la carpeta `Release/` entera y subir a Drive | Lo más simple. El usuario descomprime y ejecuta el `.exe`. Sin instalador. |
| **Inno Setup** ✅✅ | Gratis | Crear script .iss + compilar | Genera un `setup.exe` real, instala en `Program Files`, crea atajo en menú Inicio. Profesional. |
| **NSIS** | Gratis | Similar a Inno Setup | Alternativa. Más antigua pero potente. |
| **MSIX** | Gratis | Empaquetado moderno (requiere certificado) | Formato moderno de Windows 10/11. Permite subir a Microsoft Store. |
| **Microsoft Store** | 19 USD pago único | Crear cuenta dev + subir MSIX | Distribución oficial. Excesivo para TFG. |

Para el TFG, **ZIP en Drive** es suficiente. Estructura recomendada:

```
VictorinoStyle-Windows-v1.0.0.zip
└── VictorinoStyle/
    ├── frontend_victorino.exe
    ├── flutter_windows.dll
    ├── data/
    ├── LEEME.txt   ← Instrucciones para el usuario
    └── ...
```

### 12.7. Guía de instalación para el usuario final Windows

1. Descargar el ZIP del enlace de Drive.
2. **Extraer todo el contenido** en una carpeta cualquiera (Escritorio, Documentos, etc.). **No ejecutar el `.exe` desde dentro del ZIP comprimido**; algunos antivirus lo bloquean y faltan permisos.
3. Abrir la carpeta extraída y hacer **doble clic en `frontend_victorino.exe`**.
4. Windows SmartScreen puede mostrar: *"Windows protegió tu PC"* (porque el .exe no está firmado con certificado).
5. Pulsar **`Más información`** → **`Ejecutar de todas formas`**.
6. La app arranca y muestra la pantalla de login.

> Para evitar el SmartScreen habría que firmar el .exe con un certificado de Authenticode (~250 €/año). Innecesario para TFG.

### 12.8. FAQ específico Windows

**P: ¿Por qué necesita Visual Studio si Flutter compila Dart?**
R: Porque el "shell" nativo de Flutter en Windows está escrito en C++ (incluyendo el bootstrapper del runtime). Visual Studio aporta el compilador 
MSVC, sin el cual `flutter build windows` no puede generar el .exe final.

**P: ¿Funciona en Windows 7 o 8?**
R: Oficialmente no. Flutter Windows requiere Windows 10 o superior. Microsoft retiró soporte de Windows 7 hace años.

**P: ¿Por qué la carpeta de salida tiene tantas DLLs?**
R: Cada plugin nativo Flutter compila su propio DLL. `firebase_messaging`, `flutter_secure_storage`, etc. son DLLs separadas. Son ligeras (pocos KB cada una) y se cargan en runtime.

---

## 13. Linux (escritorio)

> ⚠️ **Sección teórica**: el TFG **no ha generado el binario Linux** porque Flutter exige que la compilación ocurra desde una máquina Linux real. Mi entorno es Windows, y aunque WSL2 permite simular Linux dentro de Windows, instalar todas las dependencias gráficas (GTK, OpenGL) en WSL para compilar Flutter Linux es complejo. Por simplicidad, se documenta el procedimiento teórico.

### 13.1. ¿Por qué Flutter para Linux?

Flutter 3.x permite generar aplicaciones nativas Linux x64 que usan GTK como toolkit de ventanas. Casos de uso:

- Distribuciones populares: Ubuntu, Debian, Fedora, Arch, openSUSE.
- Para empresas que tienen flotas de PCs con Linux (administración pública española, por ejemplo).
- Para usuarios que prefieren no usar Windows.

Para el TFG el caso real es marginal, pero **el código ya está listo**: solo falta el toolchain.

### 13.2. Requisitos en una máquina Linux

Lo siguiente es para Ubuntu/Debian, en otras distros los nombres de paquetes cambian ligeramente.

```bash
sudo apt update
sudo apt install -y \
  clang \
  cmake \
  ninja-build \
  pkg-config \
  libgtk-3-dev \
  liblzma-dev \
  libstdc++-12-dev
```

Además, Flutter SDK (descarga manual o snap):
```bash
sudo snap install flutter --classic
flutter doctor
```

Resultado esperado en `flutter doctor`:
```
[√] Linux toolchain - develop for Linux desktop
```

### 13.3. Alternativa: WSL2 desde Windows

Si no se tiene una máquina Linux pero sí Windows 10/11, se puede usar **WSL2** (Windows Subsystem for Linux) como Linux virtual:

```powershell
wsl --install -d Ubuntu
```

Una vez dentro de Ubuntu en WSL2, los comandos del apartado anterior funcionan. **Peeero**: compilar Flutter Linux desde WSL2 requiere también configurar **WSLg** 
(las extensiones gráficas) para que GTK pueda enlazar. Es factible pero supera el alcance básico.

### 13.4. Generación del binario Linux

```bash
cd ~/Victorino_Style/frontend_victorino
flutter clean
flutter pub get
flutter build linux --release \
  --dart-define=API_BASE_URL=https://victorinostyle-production.up.railway.app/api/v1
```

Resultado en:
```
build/linux/x64/release/bundle/
├── frontend_victorino       ← el ejecutable
├── lib/                     ← librerías .so
├── data/
└── ...
```

### 13.5. Iconos para Linux

`flutter_launcher_icons` **no soporta Linux de forma nativa** (Linux usa archivos `.desktop` con icono asociado, no un sistema central como Android/iOS). Lo que se haría:

1. Tomar el `assets/logos_app/logo_app1.3.png` ya redimensionado.
2. Crear un archivo `.desktop` durante el empaquetado:
   ```ini
   [Desktop Entry]
   Name=Victorino Style
   Exec=/opt/victorinostyle/frontend_victorino
   Icon=/opt/victorinostyle/data/flutter_assets/assets/logos_app/logo_app1.3.png
   Type=Application
   Categories=Office;
   ```
3. Instalar el `.desktop` en `/usr/share/applications/` para que aparezca en el menú de aplicaciones.

### 13.6. Distribución del binario Linux

| Opción | Coste | Quién la usa | Notas |
|---|---|---|---|
| **Tarball (`.tar.gz`)** ✅ | Gratis | Cualquiera | Comprimir `bundle/`, el usuario descomprime y ejecuta. Más simple. |
| **Paquete `.deb`** | Gratis | Debian, Ubuntu, Mint | Profesional. Se instala con `sudo apt install ./victorino.deb`. Hay que crear el control file. |
| **Snap** | Gratis | Ubuntu y muchas otras | Sandbox automático, autoupdates. Subir a `snapcraft.io`. |
| **Flatpak** | Gratis | Fedora, Arch y otras | Igual que Snap pero del ecosistema GNOME. |
| **AppImage** | Gratis | Cualquier distro | Un solo archivo ejecutable, sin instalación. Muy práctico para distribución directa. |

Para el TFG, **tarball en Drive** sería suficiente.

### 13.7. Guía de instalación para el usuario final Linux

Asumiendo distribución por tarball:

```bash
# Descargar el tarball del enlace de Drive
wget "https://drive.google.com/uc?export=download&id=ABC123" -O victorino-linux.tar.gz

# Extraer
tar -xzf victorino-linux.tar.gz
cd bundle

# Dar permisos de ejecución
chmod +x frontend_victorino

# Ejecutar
./frontend_victorino
```

### 13.8. FAQ específico Linux

**P: ¿Por qué Flutter no permite cross-compile a Linux desde Windows?**
R: Porque la compilación necesita enlazarse contra GTK, glibc, OpenGL y otras librerías nativas Linux, que no están disponibles en el toolchain Windows. La solución oficial de Flutter es "compila en cada plataforma desde esa plataforma". Hay proyectos comunitarios que cross-compile, pero no son oficiales y dan problemas con plugins.

**P: ¿La app Linux funciona en distros derivadas como Linux Mint o Pop!_OS?**
R: Sí, todas las basadas en Debian/Ubuntu comparten los mismos binarios. Para distros muy distintas (Arch, NixOS) puede haber pequeños ajustes pero la base funciona.

**P: ¿Y para ARM Linux (Raspberry Pi)?**
R: Flutter Linux **solo se compila a x86_64 oficialmente**. Para ARM (Raspberry Pi 4/5) habría que hacer un build cruzado con un toolchain ARM, que es experimental.

---

## 14. Preguntas frecuentes (FAQ para el tribunal)

Esta es la parte más importante para la defensa del TFG. Anticipa preguntas que se pueden hacer y prepara una respuesta sólida.

### 🌐 Sobre la plataforma

**P: ¿Por qué Railway y no AWS / Google Cloud / Azure?**
R: AWS, GCP o Azure son **IaaS o PaaS de propósito general**, pensados para empresas con equipos dedicados a infraestructura. Tienen una curva de aprendizaje muy alta (IAM, VPCs, security groups, etc.) y una facturación compleja. Railway es un **PaaS especializado** que abstrae todo eso. Para un TFG, donde el foco está en demostrar el **conocimiento del proceso de despliegue**, no en perderse semanas configurando infraestructura, Railway es la elección equilibrada. Además, **la misma aplicación se podría mover a AWS** sin cambios de código gracias a que todo está parametrizado por variables de entorno.

**P: ¿Cuánto cuesta tener esto en producción?**
R: Railway tiene un plan **Hobby de 5 €/mes** con 8 GB de RAM y 8 vCPUs compartidas entre los servicios del proyecto, suficiente de sobra para un TFG y miles de usuarios reales. El primer mes ofrece un crédito gratuito de 5 € que cubre el coste inicial. Para una hipotética versión "profesional" (Pro plan), serían unos 20 €/mes con recursos garantizados.

**P: ¿Y si Railway desaparece como empresa o sube los precios?**
R: La aplicación está diseñada para ser **portable**. Todo está parametrizado por variables de entorno y no hay nada específico de Railway en el código. Migrar a Render, Fly.io, Heroku, AWS App Runner o incluso a un VPS con Docker llevaría unas horas, no días. El backend es un JAR estándar Spring Boot, el frontend es un contenedor nginx estándar, y la base de datos es MySQL exportable con `mysqldump`.

**P: ¿Por qué desplegaste el backend y el frontend como servicios separados?**
R: Por dos motivos: (1) **escalabilidad independiente** — si en el futuro el backend recibe mucha carga, puedo darle más RAM/CPU sin tocar el frontend; (2) **separación de responsabilidades** — el frontend es estático (HTML/CSS/JS) y se sirve con un nginx ligerísimo, mientras que el backend es una JVM pesada. Tenerlos juntos sería ineficiente.

### 🔒 Sobre seguridad

**P: ¿Cómo se protegen las contraseñas?**
R: Con **BCrypt cost 10**. Nunca se guarda la contraseña en texto plano: se guarda un hash irreversible que tarda ~100ms en generarse. Eso hace **inviable la fuerza bruta** incluso si un atacante consiguiera dump de la base de datos. Cada hash incluye un *salt* aleatorio único, así dos usuarios con la misma contraseña tienen hashes distintos.

**P: ¿Cómo se protege la sesión del usuario?**
R: Con **JWT firmado HS256**. El backend emite un *access token* válido 15 minutos y un *refresh token* válido 7 días. El access token va en el header `Authorization: Bearer <token>` de cada petición. Si alguien intenta modificar el token, la firma deja de cuadrar y el backend lo rechaza. El refresh token se guarda en `flutter_secure_storage` (encryptado por el sistema operativo del dispositivo), nunca en `localStorage` ni en `SharedPreferences`.

**P: ¿Y si me roban el access token?**
R: Solo es válido **15 minutos**. Para mitigarlo además: las peticiones van por HTTPS (cifrado en tránsito), el backend rota el refresh token cada vez que se usa, y los refresh tokens se guardan como hash SHA-256 en BD (si me roban la BD no pueden usarlos).

**P: ¿La conexión es HTTPS?**
R: Sí, **automáticamente**. Railway provisiona certificados Let's Encrypt y los renueva solos. Toda la comunicación entre el navegador/móvil y el backend va cifrada.

**P: ¿Cómo proteges el acceso al MySQL?**
R: Por defecto, el MySQL **no es accesible desde Internet**: solo el backend (que vive en la misma red privada de Railway) puede conectarse. Para cargar los datos iniciales hubo que activar puntualmente un *TCP Proxy* público; se puede desactivar después si no se necesita administración remota.

**P: ¿Dónde están las claves secretas?**
R: **Únicamente en Railway**, como variables de entorno del servicio. No están en el repositorio de GitHub (parametrizadas con `${VAR:default}`), ni en el código fuente, ni en logs (se enmascararían si apareciesen). El JSON del *service account* de Firebase también se inyecta como variable de entorno multilínea, no como archivo.

**P: ¿Y CORS? ¿No es vulnerable?**
R: La política de CORS está **explícitamente acotada** a los orígenes conocidos: `localhost` en desarrollo, y la URL pública del frontend en producción (vía la variable `VICTORINO_CORS_ORIGENES_EXTRA`). No se usa `*` (wildcard). Eso evita que páginas maliciosas en otros dominios puedan llamar al API en nombre del usuario.

**P: ¿Hay rate limiting? ¿Y si alguien hace miles de peticiones por segundo?**
R: A nivel de aplicación todavía no hay rate limiting implementado en el backend (sería una mejora futura usando, por ejemplo, `Bucket4j` o un filtro Spring). A nivel de plataforma, **Railway tiene protección DDoS básica en su proxy edge**. Para producción real se recomendaría poner un Cloudflare delante.

### 🛢️ Sobre la base de datos

**P: ¿Qué pasa si se cae la base de datos?**
R: Si el contenedor MySQL se cae, Railway intenta reiniciarlo automáticamente. Como los datos están en un **volumen persistente separado** del contenedor, no se pierden al reiniciar. El backend tiene configurado un pool de conexiones HikariCP que reintenta automáticamente si pierde la conexión durante unos segundos.

**P: ¿Y si se corrompen los datos?**
R: Aquí es donde entra la **política de backups** (ver siguiente pregunta).

**P: ¿Tienes política de backups?**
R: Railway hace **snapshots automáticos diarios** del volumen del MySQL en el plan Hobby (configurable a más frecuencia en planes superiores). Estos snapshots se conservan 7 días y permiten restaurar a un punto anterior con un par de clicks. Adicionalmente, para un TFG profesional se recomendaría:
- Hacer `mysqldump` manuales antes de cambios grandes y guardarlos en local / Google Drive.
- En producción real, replicar a una segunda BD (read-replica) en otro proveedor para disaster recovery.

**P: ¿Y si se cae el backend?**
R: Railway detecta automáticamente que el proceso ha muerto y lo **reinicia**. Si el problema persiste (por ejemplo, un bug que mata el proceso al arrancar), Railway lanza una alerta y deja el deploy anterior funcionando (rolling deploys). La media de downtime ante un crash transitorio es de **20-40 segundos** mientras el contenedor se reinicia.

**P: ¿Qué pasa con las sesiones de los usuarios si se cae el backend?**
R: Como los JWT son **stateless** (no se guardan en memoria del backend), las sesiones sobreviven a reinicios. El usuario sigue con su token válido y al hacer su siguiente petición simplemente la atiende el backend reiniciado. No hay "pérdida de sesión".

**P: ¿Por qué MySQL y no PostgreSQL / MongoDB / Firestore?**
R: El proyecto tiene un modelo de datos muy relacional (citas con FK a clientes, empleados, servicios, con constraints como el XOR cliente/invitado o las CHECK de horario). MySQL es perfecto para eso. PostgreSQL habría sido equivalente, pero ya tenía MySQL Workbench y experiencia con él. MongoDB / Firestore (NoSQL) habrían sido peor encaje porque no tienen JOINs ni constraints de integridad referencial nativas.

**P: ¿Por qué `ddl-auto=update` y no `validate`?**
R: Durante desarrollo, `update` es cómodo porque deja a Hibernate añadir columnas que falten al cambiar una entidad. **Para producción estricta**, lo correcto sería `validate`: el `schema.sql` es la fuente única de verdad y Hibernate solo verifica que cuadra. Es una mejora pendiente para una versión 1.1 del TFG.

### 📦 Sobre el almacenamiento de archivos

**P: ¿Por qué un volumen de Railway y no AWS S3 / Cloudinary?**
R: Por **simplicidad**. Un volumen es transparente para el código: el backend escribe en `/app/uploads/foto.png` como si fuera una carpeta local. S3 o Cloudinary requerirían añadir SDKs, gestionar credenciales, manejar URLs firmadas, etc. Para el volumen actual (las fotos de la peluquería: empleados, servicios, clientes), el volumen sobra. Si la app creciera hasta gigabytes de imágenes, migrar a S3 sería el siguiente paso lógico.

**P: ¿Qué pasa con las fotos si se borra el volumen accidentalmente?**
R: Las **7 imágenes seed** (admin.png, fotos de los servicios, etc.) están dentro del JAR compilado (en `classpath:uploads-seed/`). El `UploadsSeederRunner` las restaura automáticamente al arrancar si faltan. Las fotos subidas por usuarios sí se perderían, pero eso lo cubre el snapshot diario del volumen.

**P: ¿Las fotos están protegidas? ¿Cualquiera puede acceder a ellas con la URL?**
R: Sí, cualquiera con la URL puede ver la foto. Esto es aceptable para fotos de **empleados** (información pública: nombre + foto del peluquero) y de **servicios** (catálogo). Para las fotos de **perfil del cliente** —si en el futuro se considera información sensible— se añadiría un filtro de autenticación en `UploadsConfig`. De momento se asume que la URL es difícil de adivinar (nombres UUID) y eso basta.

### 🔄 Sobre los despliegues

**P: ¿Cómo se hace un nuevo despliegue?**
R: Con un simple `git push` a la rama `Produccion-Railway`. Railway detecta el push (tiene Auto-Deploys activo), descarga el código, lo compila y arranca la nueva versión. Mientras tanto, la versión antigua sigue sirviendo peticiones (zero-downtime deploy). Una vez la nueva versión está sana, Railway corta la antigua. Todo el proceso tarda 1-3 minutos.

**P: ¿Hay CI/CD?**
R: A día de hoy, el despliegue continuo está habilitado (cada push redespliega) pero **no hay tests automatizados ejecutándose antes** del despliegue. La opción `Wait for CI` está desactivada. En una versión 1.1, se añadiría GitHub Actions con `mvn test` y `flutter test`, y solo si pasan se permitiría el despliegue.

**P: ¿Se puede hacer rollback?**
R: Sí. En Railway → Deployments → cada deploy tiene un botón **Redeploy** que vuelve a esa versión. También se puede revertir el commit en git y hacer push, y Railway desplegará la versión revertida.

**P: ¿Cómo se cambia una variable de entorno?**
R: En Railway → Variables del servicio → editar el valor → Save. Eso dispara un redeploy automático con la nueva variable. No hace falta tocar código.

**P: ¿Cómo monitorizas la salud del servicio?**
R: Railway provee de serie una pestaña **Metrics** con uso de CPU, RAM, ancho de banda y latencia. También una pestaña **Logs** con los logs en vivo del proceso. Para producción profesional se añadiría integración con Sentry para errores, Datadog/Grafana para métricas detalladas, y Healthchecks.io para alertas si la URL deja de responder.

### 🚀 Sobre la escalabilidad

**P: ¿Y si llegan miles de usuarios simultáneos?**
R: Para una carga moderada (cientos de usuarios concurrentes), el servicio actual aguanta. Si fuera necesario:
- **Vertical**: subir el plan de Railway a Pro y darle más RAM/CPU.
- **Horizontal**: configurar el servicio como **replica set** (Railway permite N réplicas con balanceador automático). Esto requiere que la app sea **stateless**, cosa que se cumple gracias al uso de JWT (no hay sesiones en memoria que tendrían que compartir las réplicas).
- **BD**: añadir una réplica de lectura, separar lecturas/escrituras.

**P: ¿Por qué Spring Boot y no Quarkus / Micronaut, que son más ligeros?**
R: Spring Boot es el **estándar del mercado**: documentación masiva, ecosistema enorme, lo que conozco mejor. Quarkus o Micronaut tendrían menor uso de RAM (importante en el plan Hobby), pero la inversión de aprenderlos no se justifica para un TFG.

### 🧪 Sobre el desarrollo

**P: ¿Funciona la app en local? ¿O solo en Railway?**
R: Funciona perfectamente en local **sin tocar nada**. Todas las variables de entorno tienen valores por defecto en `application.properties` que apuntan a un MySQL local en `localhost:3306`. El mismo código sirve para ambos entornos.

**P: ¿Cómo se pasa información entre entornos (local → producción) sin filtrar secretos?**
R: Hay un archivo `.env.example` documentando las variables de entorno y su propósito **con valores de ejemplo, no reales**. El `.env` real con valores de producción está en Railway, no en el repositorio. Cuando un compañero quiere desarrollar en local, copia `.env.example`, lo rellena con sus credenciales (incluso una BD MySQL distinta a la de producción) y listo.

### 💸 Sobre la sostenibilidad

**P: ¿Cuánto consume el backend en producción?**
R: En estado idle (sin tráfico), unos 200-300 MB de RAM y 1-2% de CPU. Con tráfico moderado, puede subir a 400-500 MB de RAM. Por eso se ha configurado `JAVA_TOOL_OPTIONS` con `-Xmx400m`, para que el JVM no intente reservar más de lo que hay en el plan Hobby.

**P: ¿La aplicación gasta mucha luz / es sostenible?**
R: Al estar desplegada en un proveedor en la nube, **comparte la infraestructura** con otros miles de aplicaciones (multi-tenant). El consumo energético es proporcional al uso real, no a tener un servidor encendido 24/7 solo para ti. Railway anuncia compromiso con energía renovable en sus centros de datos.

### 🧹 Buenas prácticas y futuro

**P: ¿Qué mejorarías si tuvieras más tiempo?**
R:
1. Cambiar `ddl-auto` de `update` a `validate` para forzar `schema.sql` como única fuente de verdad.
2. Añadir GitHub Actions con tests obligatorios antes del despliegue.
3. Implementar rate limiting con Bucket4j.
4. Migrar las fotos a Cloudinary / S3 para que el backend no sea responsable de servir archivos estáticos.
5. Añadir un dominio personalizado (ej. `victorinostyle.com`) con DNS apuntando a Railway.
6. Configurar **monitorización con Sentry** para detectar excepciones en producción.
7. Renombrar el campo `password` del DTO a `contrasena` por coherencia con el resto del proyecto.
8. Rotar todos los secretos comprometidos durante el desarrollo (Gmail app password, JWT secret, Firebase service account).

**P: ¿Qué pasa si un atacante ve el código del repositorio público?**
R: El repositorio del TFG está **privado**. Pero aunque fuera público, **no contiene secretos**: todas las contraseñas y claves están en Railway. Sí contiene la **estructura** del proyecto (entidades, servicios, controladores), que es información que un atacante podría usar para mapear endpoints. Por eso es importante mantener Spring Security con políticas restrictivas (todo cerrado por defecto, abrir solo lo necesario).

**P: ¿Cumple GDPR / RGPD?**
R: A nivel de diseño se siguieron prácticas RGPD:
- **Soft-delete con anonimización**: cuando un cliente borra su cuenta, sus datos personales (nombre, apellidos, teléfono, foto) se anonimizan, pero las citas pasadas se conservan (con id anonimizado) para mantener integridad estadística para la peluquería. Cumple el "derecho al olvido" sin destruir información de negocio legítima.
- **Datos sensibles cifrados en tránsito** (HTTPS).
- **Contraseñas hashed** con BCrypt.
- A pleno cumplimiento RGPD profesional habría que añadir: aviso de cookies (aunque la app casi no usa cookies), política de privacidad pública, DPO designado, y registro de tratamientos.

---

## 15. Anexo A — Variables de entorno completas

Estas son las variables configuradas en Railway en el servicio backend. **Los valores se enmascaran con `***` por seguridad**.

| Variable | Valor (enmascarado) | Origen | Propósito |
|---|---|---|---|
| `PORT` | (lo inyecta Railway, normalmente 8080) | Railway | Puerto donde escucha Spring Boot |
| `SPRING_DATASOURCE_URL` | `jdbc:mysql://${{MySQL.MYSQLHOST}}:...` | Referencia a MySQL | Conexión JDBC |
| `SPRING_DATASOURCE_USERNAME` | `${{MySQL.MYSQLUSER}}` | Referencia | Usuario MySQL |
| `SPRING_DATASOURCE_PASSWORD` | `${{MySQL.MYSQLPASSWORD}}` | Referencia | Contraseña MySQL |
| `VICTORINO_JWT_SECRET` | `Y2FtYmlh***` | Manual | Firma de JWT (HS256, mínimo 256 bits Base64) |
| `SPRING_MAIL_USERNAME` | `peluqueria.victorinostyle@gmail.com` | Manual | Cuenta Gmail emisora |
| `SPRING_MAIL_PASSWORD` | `***` | Manual | App password Gmail (16 chars) |
| `VICTORINO_ADMIN_PRUEBA_ACTIVO` | `true` | Manual | Crea admin al arrancar |
| `VICTORINO_ADMIN_PRUEBA_PASSWORD` | `Admin1234!` | Manual | Contraseña del admin demo |
| `VICTORINO_UPLOADS_DIRECTORIO` | `/app/uploads` | Manual | Ruta del volumen montado |
| `VICTORINO_CORS_ORIGENES_EXTRA` | (pendiente, URL frontend) | Manual | Orígenes CORS de producción |
| `VICTORINO_FIREBASE_PROJECT_ID` | `victorino-style` | Manual | Project ID de Firebase |
| `VICTORINO_FIREBASE_CREDENTIALS_JSON` | `{"type":"service_account",...}` | Manual | JSON entero del service account |
| `NIXPACKS_JDK_VERSION` | `21` | Manual | Forzar JDK 21 en lugar del 17 por defecto |
| `JAVA_TOOL_OPTIONS` | `-Xmx400m -Xms256m -XX:+UseSerialGC -XX:MaxMetaspaceSize=128m` | Manual | Límite de RAM del JVM |

---

## 16. Anexo B — Comandos útiles

### Local

```powershell
# Compilar el backend
cd Backend_Victorino
.\mvnw clean install -DskipTests

# Arrancar el backend en local
.\mvnw spring-boot:run

# Build de Flutter Web apuntando a producción
cd ..\frontend_victorino
flutter build web --release `
  --dart-define=API_BASE_URL=https://victorinostyle-production.up.railway.app/api/v1

# Build del APK
flutter build apk --release `
  --dart-define=API_BASE_URL=https://victorinostyle-production.up.railway.app/api/v1
```

### Railway CLI

```powershell
# Login (solo la primera vez)
railway login

# Vincular carpeta local al proyecto
railway link

# Ver logs del servicio actual
railway logs

# Abrir cliente MySQL conectado al servicio (requiere mysql CLI instalado)
railway connect MySQL

# Ejecutar un comando con las variables del servicio inyectadas
railway run java -version
```

### MySQL Workbench (carga inicial)

```sql
USE railway;
-- Ejecutar schema_railway.sql (rayo amarillo o Ctrl+Shift+Enter)
-- Ejecutar seed_railway.sql (tarda 1-3 minutos)

-- Verificación
SELECT COUNT(*) AS usuarios FROM usuario;     -- esperado: 53
SELECT COUNT(*) AS citas FROM cita;           -- esperado: ~1000
SELECT COUNT(*) AS servicios FROM servicio;   -- esperado: 4
```

---

## 17. Anexo C — Glosario de términos

- **PaaS (Platform as a Service)**: servicio cloud que te abstrae la infraestructura (sistema operativo, runtime, servidor web). Solo entregas el código.
- **IaaS (Infrastructure as a Service)**: servicio cloud que te da máquinas virtuales en bruto (ej. AWS EC2). Tú instalas todo.
- **Nixpacks**: el builder por defecto de Railway. Detecta el tipo de proyecto y configura el contenedor automáticamente.
- **Reverse proxy**: servidor intermedio entre el cliente y tu aplicación. Suele encargarse de HTTPS, balanceo y caché.
- **Terminación TLS**: descifrar HTTPS en un punto antes de pasar la petición. El backend recibe HTTP plano.
- **Volumen persistente**: disco que sobrevive a reinicios del contenedor.
- **Stateless**: sin estado en memoria. Cada petición es independiente. Permite escalar horizontalmente.
- **JWT (JSON Web Token)**: token de autenticación autocontenido y firmado.
- **BCrypt**: algoritmo de hash lento, diseñado para guardar contraseñas.
- **CORS (Cross-Origin Resource Sharing)**: política del navegador que controla qué dominios pueden llamar a un API.
- **Mixed content**: cuando una página HTTPS intenta cargar recursos HTTP. Los navegadores lo bloquean por seguridad.
- **Build arg**: variable que se pasa a Docker en tiempo de **compilación** (no de ejecución).
- **Idempotente**: ejecutarlo N veces produce el mismo resultado que ejecutarlo 1 vez. El `UploadsSeederRunner` lo es.
- **Soft-delete**: borrado lógico (marcar `fecha_eliminacion`) en lugar de borrado físico (`DELETE FROM`).
- **DTO (Data Transfer Object)**: objeto plano usado para transportar datos entre capas, sin lógica.
- **ORM (Object-Relational Mapping)**: capa que traduce entre objetos del lenguaje (clases Java) y tablas SQL.
- **Pool de conexiones**: conjunto de conexiones a BD reutilizables, evita abrir/cerrar conexiones por cada petición. Spring Boot usa HikariCP.

---

> **Nota final**: este documento está vivo. Se actualizará cuando se complete el despliegue del frontend Flutter Web y la distribución del APK Android. Si alguien encuentra una errata o un punto poco claro, dejar feedback en el issue tracker del repositorio.
