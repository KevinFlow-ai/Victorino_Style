# Guía de despliegue a producción — Victorino Style

> **Autor**: Kevin (KevinFlow-ai)
> **Proyecto**: TFG 2DAM, curso 2025/2026
> **Fecha del despliegue**: mayo de 2026
> **Plataforma**: Railway
> **Backend público**: `https://victorinostyle-production.up.railway.app/api/v1`
> **Frontend público**: `https://frontendvictorino-style-production.up.railway.app`
> **APK Android**: `app-release.apk` (60 MB) distribuido vía Google Drive

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
9. [Frontend Flutter Web](#9-frontend-flutter-web)
10. [APK Android](#10-apk-android)
11. [iOS (iPhone / iPad)](#11-ios-iphone--ipad)
12. [Windows (escritorio)](#12-windows-escritorio)
13. [Linux (escritorio)](#13-linux-escritorio)
14. [Operaciones post-despliegue](#14-operaciones-post-despliegue)
15. [Plan de contingencia](#15-plan-de-contingencia)
16. [Preguntas frecuentes (FAQ para el tribunal)](#16-preguntas-frecuentes-faq-para-el-tribunal)
17. [Anexo A — Variables de entorno completas](#17-anexo-a--variables-de-entorno-completas)
18. [Anexo B — Comandos útiles](#18-anexo-b--comandos-útiles)
19. [Anexo C — Glosario de términos](#19-anexo-c--glosario-de-términos)

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
Se completo Un segundo servicio para el **frontend Flutter Web** que sirve la aplicación a través de una URL pública mediante un contenedor Docker con nginx.

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

### 2.5.1 ¿Qué es NGINX?
es un servidor web de alto rendimiento, de código abierto, que también funciona como proxy inverso, balanceador de carga y proxy de correo electrónico. 
Su arquitectura asíncrona basada en eventos le permite manejar miles de conexiones simultáneas con muy bajo consumo de recursos, lo que lo hace ideal para sitios con mucho tráfico

Qué es exactamente NGINX
Es un servidor web capaz de servir contenido estático (HTML, CSS, JS, imágenes) de forma muy rápida. 

Actúa como proxy inverso, recibiendo peticiones y repartiéndolas a servidores backend (Node.js, Python, PHP, etc.). 

Puede funcionar como balanceador de carga, distribuyendo tráfico entre varios servidores para evitar saturaciones. 

También soporta protocolos de correo como IMAP, POP3 y SMTP. 

Cómo funciona
A diferencia de servidores tradicionales que crean un hilo por cada petición, NGINX usa un modelo asíncrono y orientado a eventos, donde un solo proceso puede manejar muchas conexiones simultáneas (hasta miles). Esto lo hace extremadamente eficiente y escalable

Un poco de historia
Fue creado por Igor Sysoev en 2002 para resolver el problema C10K (manejar 10.000 conexiones simultáneas). Su primera versión pública salió en 2004. 

Ejemplo 1. Para entenderlo en pocas palabras
NGINX es como un portero súper rápido de un edificio.  
Cuando muchas personas quieren entrar a una web al mismo tiempo, él abre la puerta, organiza la fila y manda a cada persona al sitio correcto sin que nadie se choque.

En pocas líneas:
Es un programa que ayuda a que las páginas web carguen rápido.
Puede repartir el trabajo entre varios ordenadores para que ninguno se sature.
Funciona como un portero inteligente que decide a dónde enviar cada visita.

Ejemplo 2. Para entenderlo en pocas palabras

NGINX es como un camarero muy rápido en un restaurante.  
Cuando llegan muchos clientes a la vez, él toma los pedidos, los reparte a la cocina correcta y entrega la comida sin que nadie espere demasiado.

En pocas líneas:
Muchas personas piden “comida” (páginas web) al mismo tiempo.
NGINX es el camarero que organiza todo para que nadie se quede sin servir.
Si la cocina está llena, él manda pedidos a otra cocina para que todo vaya más rápido.

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


### 2.10. ¿Qué es  OOM?
Un OOM ocurre cuando un programa, proceso o sistema se queda sin memoria disponible para continuar funcionando. Cuando pasa, el sistema suele cerrar el proceso que consume más memoria o directamente se bloquea.

Qué significa exactamente
- El programa intenta usar más memoria RAM de la que el sistema puede darle.
- El sistema operativo detecta que no puede asignar más memoria.
- Para evitar un colapso total, mata el proceso responsable (en Linux lo hace el OOM Killer).

JAVA_TOOL_OPTIONS limita la RAM y previene OOM
El backend corre sobre una JVM(Máquina Virtual de Java). Si no limitas la memoria, la aplicación puede intentar usar más RAM de la disponible en el servidor o contenedor.
Cuando eso pasa, aparece un OOM (Out Of Memory) y la JVM(Máquina Virtual de Java) se cae.

Al definir variables como:JAVA_TOOL_OPTIONS="-Xms512m -Xmx1024m"

estás:

- Controlando cuánta memoria puede usar la JVM
- Evitando que consuma toda la RAM del servidor
- Provocando un fallo controlado antes de que el sistema operativo mate el proceso

En otras palabras:
Limitar la memoria evita que el backend colapse de forma descontrolada por OOM.

Spring Boot devuelve mensajes de error consistentes vía @RestControllerAdvice
Cuando ocurre un error —incluyendo uno relacionado con memoria, base de datos o lógica interna— Spring Boot puede devolver respuestas inconsistentes si no se manejan.

@RestControllerAdvice permite:

- Interceptar excepciones globalmente
- Formatear un JSON de error uniforme
- Evitar que el cliente reciba stacktraces o mensajes confusos
- Registrar el error de forma clara para diagnóstico

Esto significa que, incluso si ocurre un problema como un OOM o un fallo de conexión, el backend:

- No se comporta de forma errática
- Responde con un mensaje claro y consistente
- Facilita la observabilidad del incidente

Es decir:
Aunque haya fallos internos, el backend mantiene una interfaz estable hacia el cliente.


Hibernate + HikariCP reintentan automáticamente al perder conexión con MySQL
Cuando la base de datos se cae, se reinicia o pierde conexión temporalmente, sin un pool de conexiones robusto el backend puede:

- Lanzar excepciones no controladas
- Quedarse colgado esperando conexiones
- Caer por acumulación de threads bloqueados

HikariCP (el pool de conexiones por defecto en Spring Boot) hace:

- Reintentos automáticos
- Validación de conexiones antes de usarlas
- Recuperación rápida cuando MySQL vuelve
- Evita fugas de conexiones


Hibernate se apoya en HikariCP para mantener la estabilidad.

Esto significa que:
Una caída temporal de MySQL no tumba el backend.






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
            Frontend["🌐 Frontend Flutter Web + nginx<br/>frontendvictorino-style-production.up.railway.app"]
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

### Error 7: CORS bloqueaba el login desde el frontend web

**Síntoma**: tras desplegar el frontend, al hacer login desde el navegador la consola (F12) mostraba:

```
Access to XMLHttpRequest at 'https://victorinostyle-production.up.railway.app/api/v1/auth/login'
from origin 'https://frontendvictorino-style-production.up.railway.app'
has been blocked by CORS policy: Response to preflight request doesn't pass access
control check: No 'Access-Control-Allow-Origin' header is present on the requested
resource.
```

**Causa**: la variable de entorno `VICTORINO_CORS_ORIGENES_EXTRA` del backend se configuró inicialmente con el valor:
```
frontendvictorino-style-production.up.railway.app
```
**Sin el protocolo `https://`**. Spring Security `setAllowedOriginPatterns()` necesita el origen completo (esquema + host) para comparar contra el 
header `Origin` que envía el navegador. Sin el `https://` el patrón es inválido, no hace match, y el backend responde a la petición 
preflight `OPTIONS` sin el header `Access-Control-Allow-Origin`. El navegador bloquea la petición.

**Solución**: editar la variable en Railway y poner el valor completo:
```
https://frontendvictorino-style-production.up.railway.app
```
Sin `/` al final. Tras el redeploy del backend, el login funciona inmediatamente.

> **Lección**: cuando una librería pide un "origen", se refiere al estándar Web (`scheme://host[:port]`), no solo al dominio. Confundirlos es un error frecuente.

### Error 8: Caché agresivo de nginx impedía que los cambios llegaran al usuario tras un redeploy

**Síntoma**: tras hacer push del cambio para deshabilitar la subida de fotos en web (sub-apartado 9.6.1), el redeploy del frontend 
en Railway terminó con éxito, pero al recargar la página en el navegador el `SnackBar` no aparecía. En **ventana de incógnito sí aparecía**, 
y al hacer `Ctrl+Shift+R` también.

**Causa**: la regla del Dockerfile decía:
```nginx
location ~* \.(?:js|css|woff2?|png|jpg|jpeg|gif|svg|webp|ico)$ {
    expires 30d;
    add_header Cache-Control "public, immutable";
}
```

El header `Cache-Control: immutable` indica al navegador: *"este archivo NUNCA cambiará bajo esta misma URL durante 30 días, NO me preguntes siquiera"*. 
Como Flutter Web compila siempre con el mismo nombre fijo `main.dart.js`, **el navegador estaba sirviendo el bundle viejo de antes del redeploy**, 
sin pedir el nuevo. Solo el `index.html` (con `no-store`) se actualizaba, pero referenciaba el `main.dart.js` viejo cacheado.

**Solución**: refinar las reglas de caché para diferenciar dos casos:

- **Archivos de nombre FIJO entre deploys** (`main.dart.js`, `flutter_bootstrap.js`, `flutter.js`, `flutter_service_worker.js`, `manifest.json`, `version.json`): 
pasar a `Cache-Control: public, no-cache, must-revalidate` con `etag on` activado en nginx. El navegador **conserva** el caché 
pero envía un `If-None-Match: <ETag>` al servidor antes de usarlo. Si el archivo no cambió, nginx responde **304 Not Modified (~100 bytes)** 
y el navegador reutiliza el caché. Si cambió, se descarga la nueva versión. Velocidad casi idéntica a `immutable`, pero los cambios llegan al instante.
- **Assets bajo `/assets/` y `/icons/`** (fuentes, imágenes embebidas, iconos PWA): siguen con `immutable 30d`. Estos archivos solo cambian cuando se modifican los assets fuente y siguen un patrón estable.

Tras este cambio, los redeploys futuros ya no necesitan que el usuario haga recarga forzada: el navegador se actualiza automáticamente.

> **Lección**: `immutable` es muy potente pero solo es correcto para archivos cuya URL única garantiza un contenido único. Los archivos de Flutter con nombre fijo NO son inmutables. La política `must-revalidate + ETag` es el equilibrio correcto.

---

## 8. Verificación y pruebas

Tras todo el despliegue, se realizó una batería de pruebas end-to-end en **tres entornos distintos** 
para confirmar que el sistema funciona realmente, no solo "técnicamente". Se documentan en tres bloques: 
backend en aislado, frontend web, y APK Android.

### 8.1. Backend (vía Swagger UI y SQL directo)

| Prueba | Resultado |
|---|---|
| `GET /api/v1/swagger-ui.html` | 200, página de Swagger carga correctamente |
| `POST /api/v1/auth/login` con `victorino@admin.com` / `Admin1234!` | 200 + `accessToken`, `refreshToken`, `rol: ADMINISTRADOR`, `idUsuario: 1`, `nombreCompleto: "Victorino Admin"`, `foto: "/uploads/empleados/admin.png"` |
| `SELECT COUNT(*) FROM usuario` en MySQL Workbench | 53 (1 admin + 2 empleados + 50 clientes) |
| `SELECT COUNT(*) FROM cita` | ~1000 citas |
| `SELECT COUNT(*) FROM servicio` | 4 |
| `SELECT COUNT(*) FROM notificacion` | ~2500 |
| Foto `/uploads/empleados/admin.png` accesible vía URL pública | Servida correctamente desde el volumen Railway |
| Log `[SEED uploads] Listo. Copiados: 7, ya existian: 0` | Confirmado en deploy logs del primer arranque |
| Log `[FCM] FirebaseApp inicializado correctamente` | Confirmado |
| Log `Started BackendVictorinoApplication in 13.303 seconds` | Confirmado |

### 8.2. Frontend Web

| Prueba | Resultado |
|---|---|
| Cargar `https://frontendvictorino-style-production.up.railway.app` | Pantalla de login en ~10 segundos (primera carga) |
| Login como admin (`victorino@admin.com` / `Admin1234!`) | Entrada correcta al panel admin |
| Login como empleado (`maradona@victorinostyle.com` / `Empleado1234!`) | Entrada correcta al panel empleado |
| Login como cliente (varios, ej. `andres.lozano@gmail.com` / `Cliente1234!`) | Entrada correcta al panel cliente |
| Listar servicios (panel admin) | 4 servicios con sus fotos correctas |
| Listar empleados (panel admin) | 3 empleados con sus fotos correctas |
| Listar citas (panel admin) | ~1000 citas correctamente distribuidas entre 01/03/2026 y 20/06/2026 |
| Crear una cita nueva como cliente | Cita creada y visible al refrescar |
| Ver foto del admin en su perfil | Imagen carga desde el volumen Railway sin problemas |
| Cambiar/subir foto desde navegador | **SnackBar avisando que solo está disponible en móvil** (limitación conocida, ver 9.6.1) |
| Notificaciones push en navegador | **No funcionan** (limitación conocida, ver 9.6.2) — la app móvil sigue siendo el canal principal |

### 8.3. APK Android

| Prueba | Resultado |
|---|---|
| Compilar APK con `flutter build apk --release --dart-define=API_BASE_URL=...` | `app-release.apk` generado, 80-90 MB |
| Instalar en Xiaomi (Android 14) | Instalación correcta, icono "Victorino Style" en cajón de apps |
| Login con cualquier rol | Funciona igual que en web |
| Cambiar foto perfil desde galería | Funciona ✅ |
| Cambiar foto perfil desde cámara | Funciona ✅ |
| Recortar foto antes de subir | Funciona ✅ |
| Notificaciones push (pendiente de verificar end-to-end con scheduler) | Token FCM se registra correctamente; pendiente de probar la entrega real desde el scheduler 24h |

### 8.4. Métricas del backend tras varias horas de uso

- **RAM**: estable entre **500 y 700 MB** (dentro del límite del plan Hobby, con margen).
- **CPU**: < 5% en idle, picos al 30% durante login (BCrypt hace trabajo intencionalmente costoso).
- **No volvió a aparecer el aviso "Out of Memory"** tras la configuración de `JAVA_TOOL_OPTIONS`.

**Resultado global**: **sistema 100 % operativo en producción**, con dos limitaciones conocidas documentadas (subida fotos web + push web) que NO afectan a los flujos críticos del TFG.

---

## 9. Frontend Flutter Web

Esta sección describe el despliegue del **frontend Flutter compilado a Web** como un segundo servicio en Railway, 
en el mismo proyecto que el backend. El frontend queda servido por **nginx** dentro de un contenedor Docker, 
accesible públicamente en una URL HTTPS. Es la versión que cualquier persona puede abrir en su navegador (Chrome, Edge, Safari, Firefox) 
sin instalar absolutamente nada.

**URL final desplegada**: `https://frontendvictorino-style-production.up.railway.app`

### 9.1. Diferencia clave respecto al despliegue del backend

| Aspecto | Backend Spring Boot | Frontend Flutter Web |
|---|---|---|
| **Builder Railway** | Nixpacks (detecta `pom.xml` solo) | Dockerfile (escrito a mano por mí) |
| **Tipo de servicio** | App de larga ejecución (JVM) | Archivos estáticos (HTML+JS+CSS) servidos por nginx |
| **Variables de runtime** | Muchas (BD, JWT, SMTP, Firebase...) | Una sola: `API_BASE_URL` |
| **Inyección de la URL del backend** | Variables de entorno en runtime | **Build Arg** (se "hornea" en el bundle JS) |
| **Volumen persistente** | Sí (`/app/uploads`) | No, es completamente stateless |
| **Memoria RAM** | ~500-700 MB | <50 MB (nginx es ligerísimo) |

### 9.2. Dockerfile multi-etapa

El archivo `frontend_victorino/Dockerfile` (versionado en el repositorio) tiene **dos etapas**:

**Etapa 1 (build)**: parte de la imagen oficial `ghcr.io/cirruslabs/flutter:3.41.2`, copia el código fuente del frontend, ejecuta `flutter pub get` 
para descargar dependencias y luego `flutter build web --release --dart-define=API_BASE_URL=$API_BASE_URL`. La URL del 
backend se inyecta como **build argument**, lo que significa que queda **embebida en el JavaScript final**, sin necesidad de variables de runtime.

**Etapa 2 (runtime)**: parte de `nginx:alpine` (una imagen Linux mínima de ~10 MB), copia los assets compilados de la etapa anterior 
a `/usr/share/nginx/html`, y configura nginx con un `default.conf.template` que define:

- Puerto dinámico vía `$PORT` (Railway inyecta el puerto en runtime).
- `try_files $uri $uri/ /index.html` para que las rutas internas de GoRouter funcionen al recargar la página (fallback SPA).
- **Reglas de caché** (refinadas tras el primer despliegue, ver Error 8 en la sección 7).

### 9.3. Crear el servicio frontend en Railway

#### 9.3.1. Añadir nuevo servicio desde GitHub

Desde el canvas del proyecto Victorino-Style en Railway:

1. Pulsar **`+ Create`** (botón violeta arriba a la derecha) → **`GitHub Repo`** → seleccionar **`Victorino_Style`** 
(el MISMO repositorio que el backend; ambos servicios viven en el mismo monorepo).
2. Railway crea una tercera cajita en el canvas. Como con el backend, el **primer deploy automático va a fallar** 
porque Railway toma la rama y carpeta por defecto. Esperado, lo arreglaremos en los siguientes pasos.

#### 9.3.2. Configurar Settings del servicio

Pulsar la cajita nueva → pestaña **Settings**:

**Service Name** (Service section):
- Quedó como `frontend_Victorino-Style` por defecto. Lo dejé así. Si quieres uno más corto y limpio (ej. `frontend`), se puede renombrar en cualquier momento (ver sección 14.1 sobre cómo hacerlo).

**Source** (sección Source):
| Campo | Valor |
|---|---|
| Source Repo | `KevinFlow-ai/Victorino_Style` |
| Root Directory | `frontend_victorino` (sin barra inicial) |
| Branch | `Produccion-Railway` |
| Wait for CI | Desactivado |

**Build** (sección Build):
| Campo | Valor |
|---|---|
| Builder | **`Dockerfile`** (autodetectado porque hay un `Dockerfile` en `frontend_victorino/`) |
| Dockerfile Path | vacío (autodetecta `Dockerfile` en la raíz del Root Directory) |
| Custom Build Command | vacío (el Dockerfile ya tiene los `RUN` necesarios) |

**Deploy** (sección Deploy):
| Campo | Valor |
|---|---|
| Custom Start Command | **vacío** (el Dockerfile ya define `CMD` con el comando de nginx) |

#### 9.3.3. Variables de entorno

Solo hace falta UNA. En pestaña **Variables** → **+ New Variable**:

| Variable | Value |
|---|---|
| `API_BASE_URL` | `https://victorinostyle-production.up.railway.app/api/v1` |

> 🔑 Railway pasa automáticamente esta variable como **Build Arg** al Dockerfile porque tenemos `ARG API_BASE_URL` declarado en él. El comando `flutter build 
web --release --dart-define=API_BASE_URL=$API_BASE_URL` "hornea" la URL en el JavaScript final. 
El bundle resultante ya sabe contra qué backend hablar y no necesita ninguna otra configuración.

#### 9.3.4. Generar el dominio público

Settings → **Networking** → **Generate Domain**.

Railway asigna:
```
frontendvictorino-style-production.up.railway.app
```
(El nombre se forma a partir del nombre del servicio, sustituyendo guiones bajos por guiones y añadiendo `-production`).

**Public Port**: `8080` (el Dockerfile lo configura con `ENV PORT=8080` aunque Railway le pasará el real).

#### 9.3.5. Lanzar el deploy

Tras configurar todo lo anterior, Railway dispara automáticamente un nuevo deploy. Si no lo hace, pulsar **Deploy**.

**Tiempo del build la primera vez: 8-15 minutos**, porque:
- Descarga la imagen `ghcr.io/cirruslabs/flutter:3.41.2` (~3 GB).
- Ejecuta `flutter pub get` (~10 s).
- Compila el código Dart a JavaScript (~40 s).
- Construye la imagen nginx final (~30 s).
- Sube la imagen final (~50 MB) al registry interno de Railway.

Los siguientes deploys son **mucho más rápidos** (~3-5 minutos) gracias al cache de capas de Docker.

#### 9.3.6. Logs esperados

**Build Logs** (resumen de lo que aparece):
```
scheduling build on Metal builder
unpacking archive
load build definition from frontend_victorino/Dockerfile
load metadata for docker.io/library/nginx:alpine
load metadata for ghcr.io/cirruslabs/flutter:3.41.2
FROM ghcr.io/cirruslabs/flutter:3.41.2@sha256:c69039...
preparing inline document
FROM docker.io/library/nginx:alpine@sha256:7e8ff0...
WORKDIR /app
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get                                              10s
COPY . .                                                         693ms
RUN flutter build web --release --dart-define=API_BASE_URL=...   41s
   ✓ Built build/web
COPY --from=build /app/build/web /usr/share/nginx/html           28s
RUN rm -f /etc/nginx/conf.d/default.conf
COPY <<EOF /etc/nginx/templates/default.conf.template
exporting to docker image format
image push                                                       54 MB
```

**Deploy Logs** (nginx arrancando):
```
2026/05/23 16:21:16 [notice] 1#1: using the "epoll" event method
2026/05/23 16:21:16 [notice] 1#1: nginx/1.31.1
2026/05/23 16:21:16 [notice] 1#1: built by gcc 15.2.0 (Alpine 15.2.0)
2026/05/23 16:21:16 [notice] 1#1: OS: Linux 6.18.15+deb13-cloud-amd64
2026/05/23 16:21:16 [notice] 1#1: start worker processes
... (~50 workers, uno por vCPU)
Starting Container
```

Y a partir de ahí, cada visita al frontend genera líneas tipo:
```
100.64.0.2 - - [23/May/2026:16:27:43 +0000] "GET / HTTP/1.1" 200 1547 ...
100.64.0.2 - - [23/May/2026:16:27:43 +0000] "GET /flutter_bootstrap.js HTTP/1.1" 200 9974 ...
100.64.0.2 - - [23/May/2026:16:27:44 +0000] "GET /main.dart.js HTTP/1.1" 200 4438123 ...
```

### 9.4. Abrir el CORS del backend para que acepte el dominio del frontend

Sin este paso, el navegador bloquea las peticiones del frontend al backend con un error **CORS policy**. Hay que añadir 
el dominio del frontend a la lista de orígenes permitidos del backend:

1. Railway → servicio **backend** → pestaña **Variables**.
2. Buscar `VICTORINO_CORS_ORIGENES_EXTRA` (estaba creada vacía durante el sub-paso 6.3.7).
3. Editar y poner:
   ```
   https://frontendvictorino-style-production.up.railway.app
   ```
   ⚠️ **Atención**:
   - Con `https://` al principio (sin esto, Spring no reconoce el patrón como válido y el preflight CORS falla, ver Error 7 en la sección 7).
   - **Sin `/` al final**.
   - Sin espacios.
4. Save. Railway redesplegará el backend automáticamente (~1 minuto). Durante ese tiempo el backend está unos segundos inalcanzable; es normal.

### 9.5. Verificación end-to-end

Tras el redeploy del backend, abrir en el navegador:
```
https://frontendvictorino-style-production.up.railway.app
```

Comportamiento esperado:
1. **Pantalla de splash de Flutter** durante 5-15 segundos la primera vez (el navegador descarga el bundle JS de ~4.4 MB).
2. **Pantalla de login** con el logo "Victorino Style" y el favicon en la pestaña del navegador.
3. **Login** con `victorino@admin.com` / `Admin1234!` → entrada al panel de administrador con todos los datos del seed (53 usuarios, ~1000 citas, 4 servicios, etc.).

### 9.6. Limitaciones conocidas de Flutter Web en este proyecto

Tras desplegar y probar el frontend, se identificaron **dos limitaciones funcionales en la versión web** que no afectan al APK Android. 
Se documentan honestamente porque pueden surgir preguntas del tribunal y porque tienen workaround documentado para la v1.1.

#### 9.6.1. Subida y cambio de fotos NO disponible en Web

- **Síntoma**: pulsar el botón "Cambiar foto" en cualquiera de los tres lugares (perfil cliente, panel admin de empleados, panel admin de servicios) 
muestra un `SnackBar` con el mensaje **"La subida de fotos solo está disponible desde la app móvil. Descarga el APK Android para cambiar tu foto."**.

- **Causa técnica**: el flujo de subida usa el paquete `image_cropper` que **no soporta Flutter Web** (oficialmente solo Android, iOS, macOS, Windows, Linux). 
Además, el `SelectorImagen.elegirYRecortar()` devuelve un `File` de `dart:io`, clase que en Web es solo un *stub* sin funcionalidad real. Si no se controla 
el caso, el código crashea con un `Uncaught Error` en `main.dart.js` al pulsar el botón.

- **Workaround implementado**: en `lib/core/widgets_compartidos/selector_imagen.dart` se añadió al principio del método `elegirYRecortar` un `if (kIsWeb) 
{ mostrar SnackBar; return null; }`. Así los tres lugares quedan cubiertos con un único punto de control.

- **Visualización**: las fotos previamente subidas desde el APK Android **se ven perfectamente** en la versión web (es solo la **escritura** la que está deshabilitada en navegador, no la lectura).
- **Pendiente para v1.1**: reemplazar `image_cropper` por `crop_your_image` (que sí soporta Web), cambiar la firma del selector a `XFile`, y 
en los repositorios usar `MultipartFile.fromBytes(await xFile.readAsBytes())` en lugar de `fromFile(file.path)`.

#### 9.6.2. Notificaciones push FCM no disponibles en Web

- **Síntoma**: en la consola del navegador (F12) aparece el error `[FCM] No se pudo registrar token: TypeError: Instance 
of 'minified:Mb' is not a subtype of type 'minified:ee'` al iniciar sesión.

- **Causa técnica**: Firebase Cloud Messaging en navegador **requiere dos configuraciones adicionales que no están actualmente en el proyecto**:
  1. Una **VAPID Key** generada en Firebase Console → Cloud Messaging → Web Push certificates, que identifica al servidor web autorizado a enviar push.

  2. Un **Service Worker** (`firebase-messaging-sw.js`) registrado en `web/`, que recibe los push mientras la pestaña no está activa.
- **Impacto real**: las notificaciones push **funcionan perfectamente en el APK Android** (canal principal del proyecto, con FCM directamente sobre 
el `google-services.json`). El TFG usa la web como complemento de demostración (login, agenda, ver citas), no como canal principal de push.
- **Pendiente para v1.1**: generar VAPID key + crear `firebase-messaging-sw.js` + ajustar `lib/main.dart` para no intentar registrar token en web sin las credenciales correctas.

### 9.7. FAQ específico Frontend Web

**P: ¿Por qué tanto Dockerfile y no Nixpacks como con el backend?**
R: Nixpacks no detecta proyectos Flutter Web automáticamente porque el pipeline `flutter build web` no es estándar de los frameworks que Nixpacks conoce. 
Un Dockerfile multi-etapa es la solución limpia: compilamos con la imagen oficial de Flutter y servimos con nginx, sin que Railway tenga que adivinar nada.

**P: ¿Por qué nginx y no servir directamente con Flutter desde Dart?**
R: Flutter Web genera archivos estáticos (HTML, JS, CSS, fuentes, imágenes). nginx está optimizado para servir estáticos con 
la máxima eficiencia (procesos asíncronos, sendfile, compresión gzip, caché HTTP). Una "app Dart sirviendo estáticos" sería mucho más pesada y lenta.

**P: ¿Cuánto consume el frontend en Railway?**
R: Muy poco. nginx en alpine ocupa unos **20-50 MB de RAM** y casi nada de CPU en idle. El cuello de botella es siempre el backend.

**P: ¿El frontend funciona sin el backend?**
R: La página de login carga (es estático), pero al intentar autenticar, la petición POST a `/auth/login` falla con error de red porque 
el backend está caído. La app no funciona "sin backend"; ambos servicios viven juntos.

**P: ¿Puedo abrir el frontend en el navegador del móvil?**
R: Sí. La web es responsive y funciona en cualquier navegador móvil. Es una alternativa al APK Android para usuarios que prefieren no instalar nada.

**P: ¿Y si quiero un dominio propio (`victorinostyle.com`) en lugar de `.up.railway.app`?**
R: Se puede, ver sección 14.2 sobre dominios personalizados.

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

## 14. Operaciones post-despliegue

Esta sección recopila las operaciones de **mantenimiento y mejoras opcionales** que se pueden hacer una vez que el despliegue inicial 
funciona. Sirve para responder en la defensa "¿y si mañana quiero X?" sin tener que improvisar, y como referencia futura si el proyecto evoluciona.

Apartados:

- **14.1.** Renombrar un servicio en Railway
- **14.2.** Dominio propio (custom domain)
- **14.3.** Limitaciones conocidas por plataforma
- **14.4.** Cerrar el TCP Proxy del MySQL cuando ya no se necesita
- **14.5.** Backups manuales de la base de datos
- **14.6.** Actualizar la app sin downtime
- **14.7.** Monitorizar y diagnosticar problemas
- **14.8.** Actualización automática por plataforma (qué se actualiza solo y qué no)

### 14.1. Renombrar un servicio en Railway

Mi servicio frontend se llamó por defecto `frontend_Victorino-Style` y produjo el dominio `frontendvictorino-style-production.up.railway.app`. 
Si quisiera un dominio más corto (ej. `frontend-production-xxxx.up.railway.app`) habría que renombrar el servicio. 
**No es algo que rompa nada, pero implica un paso extra crítico que no se debe olvidar**.

**Pasos**:

1. Railway → pulsar la cajita del servicio a renombrar → pestaña **Settings**.
2. Sección **Service** → **Service Name** → cambiar a `frontend` (o lo que se quiera). **Save**.
3. Railway **regenera automáticamente el dominio público** asociado. La URL antigua deja de funcionar al cabo de unos segundos. La nueva URL aparece en Settings → Networking.
4. ⚠️ **Paso crítico que es fácil de olvidar**: si el servicio renombrado tenía un dominio público referenciado en otra parte 
(en mi caso, en la variable `VICTORINO_CORS_ORIGENES_EXTRA` del backend), **hay que actualizarla con el nuevo dominio**. 
De lo contrario, el navegador empezará a recibir errores CORS de nuevo.
5. También hay que regenerar el APK Android con la nueva `API_BASE_URL` si el servicio renombrado es el backend (no era mi caso).

**Recomendación**: si tienes claro un nombre desde el principio, ponlo. Renombrar después tiene esa cascada de actualizaciones que es fácil de pasar por alto.

### 14.2. Dominio propio (custom domain)

El dominio `*.up.railway.app` es funcional pero **no es la imagen profesional** que un cliente real esperaría. Para una versión 
"de producción de verdad" se contrataría un dominio propio (ej. `victorinostyle.com`) y se conectaría a Railway.

#### 14.2.1. ¿Railway lo soporta? ¿Cuesta?

**Sí, lo soporta desde el plan Hobby (5 €/mes)**. Railway no cobra extra por dominio personalizado. Lo único que se paga es:
- **El dominio en sí** en un registrador externo: 8-15 €/año típicamente (`.com`, `.es`, `.app`...).

Railway **genera y renueva automáticamente el certificado SSL/TLS de Let's Encrypt** para el dominio. No hay que gestionar certificados manualmente.

#### 14.2.2. Proveedores recomendados para comprar el dominio

| Proveedor | Coste aprox. `.com` | Notas |
|---|---|---|
| **Cloudflare Registrar** ✅✅ | ~10 €/año (precio "at cost", sin markup) | El más barato. Incluye DNS, protección DDoS, caché global. Mi recomendación. |
| **Namecheap** ✅ | ~11 €/año el primer año, ~14 € renovación | Famoso, fiable, soporte humano. |
| **IONOS** | ~10-12 €/año | Español, factura en euros, atención telefónica. |
| **GoDaddy** | ~15 €/año el primero, sube en renovaciones | Famoso pero caro a largo plazo, lleno de upsells. |
| **Google Domains** | descontinuado en 2024 | Ya no existe. Squarespace compró el negocio. |

#### 14.2.3. Configuración paso a paso (asumiendo Cloudflare como ejemplo)

1. **Comprar el dominio**: en Cloudflare Registrar buscar `victorinostyle.com` (o `.es`). Pagar. Cloudflare automáticamente configura sus servidores DNS.

2. **En Railway → servicio backend → Settings → Networking → Custom Domain → Add domain**:
   - Escribir `api.victorinostyle.com` (subdominio para el backend).
   - Railway te muestra:
     ```
     Set a CNAME record:
       Name: api
       Value: backend-production-XXXX.up.railway.app
     ```

3. **En Cloudflare → DNS → Add Record**:
   - Type: `CNAME`
   - Name: `api`
   - Target: `backend-production-XXXX.up.railway.app`
   - Proxy status: **DNS only** (sin nube naranja). Si lo dejas con nube naranja (Cloudflare proxy), funciona también pero a veces da problemas con WebSocket o uploads grandes.
   - Save.

4. **Esperar la propagación DNS** (5-30 minutos). Railway muestra el dominio como "verified" cuando detecta el CNAME.

5. **Railway genera el certificado SSL** automáticamente (~5 minutos más).

6. Repetir el proceso para el frontend con `app.victorinostyle.com` o el dominio raíz `victorinostyle.com`. Si quieres usar el dominio raíz (sin subdominio) 
hace falta un registro tipo `A` o `ALIAS` en lugar de `CNAME`, porque los registros CNAME no se permiten en la raíz por estándar DNS. Cloudflare 
lo resuelve transparentemente con su feature "CNAME flattening".

7. **Actualizar las variables de entorno y rebuild**:
   - Backend: `VICTORINO_CORS_ORIGENES_EXTRA` debe incluir `https://victorinostyle.com` o `https://app.victorinostyle.com`.
   - Frontend: `API_BASE_URL` debe ser `https://api.victorinostyle.com/api/v1` (rebuild necesario para que se hornee en el bundle).
   - APK: regenerar con `flutter build apk --dart-define=API_BASE_URL=https://api.victorinostyle.com/api/v1`.

#### 14.2.4. ¿Quito el dominio `.up.railway.app` antiguo?

No es obligatorio. Pueden coexistir. Pero si quieres "limpieza", en Railway → Networking puedes borrar el dominio antiguo. Recuerda actualizar todos los CORS antes para evitar romper accesos.

#### 14.2.5. Coste total y mantenimiento del dominio

- **Año 1**: ~10 € (Cloudflare) + 60 € de Railway (5 €/mes × 12 meses) = **~70 €**.
- **Mantenimiento**: cero. Cloudflare renueva DNS automáticamente. Railway renueva SSL automáticamente cada 90 días.

### 14.3. Limitaciones conocidas por plataforma

Esta tabla es importante para responder al tribunal "¿qué NO funciona y por qué?". Honesto y documentado.

| Plataforma | Funcionalidad | Estado | Razón |
|---|---|---|---|
| **Android (APK)** | Login, citas, fotos, push, todo | ✅ Funciona 100% | Plataforma principal del TFG |
| **iOS (iPhone/iPad)** | Todo | 🔵 No generado | Requiere Mac + Apple Developer Program (99 USD/año). Ver sección 11. El código está preparado. |
| **Web (navegador)** | Login, listar, ver citas | ✅ Funciona | — |
| **Web (navegador)** | Subir/cambiar foto | ❌ Deshabilitada con SnackBar | `image_cropper` no soporta Web. Workaround documentado, ver 9.6.1. |
| **Web (navegador)** | Notificaciones push | ❌ No funcionan | FCM en Web requiere VAPID Key + Service Worker, no configurados. Ver 9.6.2. |
| **Windows (escritorio)** | Todo | 🔵 No generado | Requiere Visual Studio Community 2022 con carga C++. Ver sección 12. El código está preparado. |
| **Linux (escritorio)** | Todo | 🔵 No generado | No se puede compilar desde Windows. Requiere máquina Linux. Ver sección 13. El código está preparado. |
| **macOS (escritorio)** | Todo | 🔵 No generado | Carpeta `macos/` no existe en el proyecto. Habría que ejecutar `flutter create --platforms=macos .` para crearla, luego compilar en un Mac. |

**Leyenda**: ✅ funciona · ❌ no funciona / deshabilitado · 🔵 no generado (preparado pero no compilado)

#### 14.3.1. Por qué se priorizó Android + Web

| Plataforma | Coste de generar | Coste de distribuir | Cobertura usuarios España |
|---|---|---|---|
| Android (APK) | Gratis | Gratis (Drive/Telegram) | ~75 % del mercado |
| Web | Gratis | Gratis (Railway) | 100 % cualquier dispositivo con navegador |
| iOS | 800€ Mac + 91 €/año | Gratis (TestFlight con cuenta paga) | ~25 % |
| Desktop | Gratis (con VS) | Trivial (ZIP) | Casi nadie usa apps de peluquería en escritorio |

La combinación Android + Web cubre **prácticamente al 100% del público objetivo** con coste cero. iOS y desktop quedan como evoluciones documentadas para una v1.1 con presupuesto.

### 14.4. Cerrar el TCP Proxy del MySQL cuando ya no se necesita

Durante la carga inicial de datos (sub-paso 6.4) se activó un *TCP Proxy* público en el servicio MySQL para poder conectar MySQL Workbench 
desde la máquina local. Para una operación normal del sistema (frontend ↔ backend ↔ MySQL), **ese proxy NO es necesario**: backend y MySQL 
viven en la misma red privada de Railway y se comunican por el host interno `mysql.railway.internal`.

**Recomendación de seguridad**: cerrar el proxy una vez cargados los datos.

**Pasos**:
1. Servicio MySQL → Settings → Networking → Public Networking.
2. Pulsar la X o "Remove" del dominio TCP Proxy.
3. Confirmar.

Si más adelante se necesita administración remota (modificar datos, hacer backup manual), se vuelve a activar puntualmente con un clic.

**Por qué importa**: aunque el MySQL está protegido por contraseña, cualquier bot que escanee Internet podría intentar ataques 
de fuerza bruta contra el puerto público. Cerrarlo elimina por completo esa superficie de ataque.

### 14.5. Backups manuales de la base de datos

Railway hace snapshots automáticos del volumen MySQL cada día (retenidos 7 días en el plan Hobby). Aun así, **conviene hacer un backup manual** 
antes de cambios grandes (migración de schema, borrado masivo, etc.).

**Procedimiento con `mysqldump` desde local** (requiere el cliente mysql instalado o accesible vía Workbench):

```powershell
# 1. Activar temporalmente el TCP Proxy del MySQL en Railway (sub-apartado 6.4.1)
# 2. Desde PowerShell, lanzar el dump:
mysqldump -h monorail.proxy.rlwy.net -P 32400 -u root -p railway > backup_2026_05_23.sql

# 3. Pedirá la contraseña (la copio del Variables del MySQL en Railway).
# 4. Guardar el archivo en sitio seguro (Drive, disco externo, etc.).
# 5. Cerrar el TCP Proxy.
```

**Para restaurar** desde un dump:
```powershell
mysql -h monorail.proxy.rlwy.net -P 32400 -u root -p railway < backup_2026_05_23.sql
```

**Frecuencia recomendada**:
- **Antes de cualquier cambio sensible** en producción.
- **Mensualmente** como hábito (aunque Railway tenga sus snapshots, tener uno propio en local es la defensa final).

### 14.6. Actualizar la app sin downtime

Railway hace **rolling deploys** por defecto: cuando empujas un nuevo commit, el servicio antiguo sigue sirviendo peticiones 
hasta que el nuevo está sano. Solo entonces se corta el antiguo. El usuario nunca ve una interrupción.

Cosas a tener en cuenta para minimizar problemas en updates:

- **Migraciones de BD**: si añades columnas o tablas, hacer la migración **antes** de empujar el código que las usa (con MySQL Workbench).
- **Variables nuevas**: añadirlas en Railway antes de pushear el código que las lee, o el primer arranque fallará.
- **Cambios en el frontend**: el `index.html` siempre se sirve fresco gracias al `Cache-Control: no-store`, y los 
archivos JS de Flutter revalidan con ETag (ver Error 8). Los cambios llegan al usuario en su próxima visita.

### 14.7. Monitorizar y diagnosticar problemas

Railway provee de serie:

- **Pestaña Metrics** de cada servicio: gráficas de CPU, RAM, Network in/out, Disk usage.
- **Pestaña Logs** (Deploy Logs + HTTP Logs): logs en vivo de stdout/stderr del proceso.
- **Pestaña Deployments**: historial completo de deploys con sus logs guardados.

Si quisieras llevar la monitorización a nivel profesional (alertas, dashboards históricos, agregación de logs), las opciones gratuitas son:
- **Sentry** para errores (gratis hasta 5.000 errores/mes).
- **Better Stack (Logtail)** para agregación de logs (gratis hasta 1 GB/mes).
- **Grafana Cloud** para métricas (gratis hasta 14 días retención).
- **Healthchecks.io** para uptime monitoring (gratis 20 checks).

Para un TFG, las pestañas integradas de Railway son más que suficientes.

### 14.8. Actualización automática por plataforma (qué se actualiza solo y qué no)

Una pregunta que surge en cuanto el proyecto lleva un tiempo desplegado es: **"si hago un cambio en el código, ¿se actualiza solo en todas las plataformas, o tengo que regenerar y redistribuir los binarios?"**. La respuesta corta es **depende de la plataforma**, y conviene tenerlo claro tanto para el día a día como para defenderlo ante el tribunal.

#### 14.8.1. Situación actual del proyecto

Tenemos **tres servicios en Railway** (ver sección 3 para el diagrama de arquitectura):

| Servicio en Railway | Qué es | ¿Auto-update al hacer `git push`? |
|---|---|---|
| `Victorino_Style` | Backend Spring Boot (API REST) | ✅ **Sí**. Railway detecta el push, recompila y redepliega. Rolling deploy sin downtime. ✅ se actualiza solo |
| `MySQL` | Base de datos | — (los datos persisten en el volumen; nada que actualizar) |
| `frontend_Victorino-Style` | Build web de Flutter (HTML/JS/WASM) | ✅ **Sí**. Mismo mecanismo: push → Railway reconstruye y publica. El usuario refresca el navegador y ve la versión nueva. |

Pero **los binarios nativos no están en Railway** — son ficheros que el usuario instala en su dispositivo:

| Plataforma | Tipo de binario | ¿Auto-update? | Por qué |
|---|---|---|---|
| **Web** (navegador) | Estáticos servidos por Railway | ✅ **Sí** | Cada refresco del navegador descarga la versión nueva (gracias al `Cache-Control: no-store` del `index.html`). |
| **Android** | `.apk` | ❌ No | El APK es un binario nativo con el código Dart compilado dentro. Para que el usuario tenga la versión nueva, hay que regenerar el APK y reinstalarlo. |
| **iOS** | `.ipa` | ❌ No | Igual que Android. Requiere Mac + cuenta de Apple Developer para regenerar. |
| **Windows** | `.exe` | ❌ No | Binario nativo Win64. Hay que regenerar y redistribuir. |
| **Linux** | bundle / AppImage / .deb | ❌ No | Binario nativo. Hay que regenerar y redistribuir. |


Railway (en la nube, auto-update on git push):
   └── Backend Spring Boot  ✅ se actualiza solo

NO está en Railway:
   ├── App Android (.apk)        ← binario estático en el dispositivo del usuario
   ├── App iOS (.ipa)            ← binario estático en el dispositivo del usuario
   ├── App Windows (.exe)        ← binario estático en el ordenador del usuario
   ├── App Linux (AppImage/deb)  ← binario estático en el ordenador del usuario

   **El .exe y el binario Linux NO se actualizan solos. Son binarios nativos compilados que contienen todo el código Dart en ese momento. Funcionan exactamente igual que un programa de toda la vida: si cambias el código, tienes que volver a compilar y volver a distribuir el ejecutable nuevo**.

## Tabla de tipos de cambio y necesidad de recompilación

| Tipo de cambio                                   | ¿Hay que recompilar la app? |
|--------------------------------------------------|------------------------------|
| **Cambio solo en el backend (Spring Boot)**      | **NO.** Railway redespliega el backend automáticamente al hacer `git push`. La app `.exe` sigue funcionando porque continúa llamando al mismo `https://...railway.app/api/v1`, ahora con la lógica nueva. |
| **Cambio en el frontend (Dart, widgets, MarcoMovil, etc.)** | **SÍ.** Hay que volver a compilar cada plataforma que distribuyas: Windows, Linux, Android, iOS. Luego debes entregar el binario actualizado a los usuarios. |
| **Cambio en el contrato API (endpoint, DTO)**    | **AMBOS.** Backend (Railway lo redepliega) + frontend (recompilar y redistribuir). |

#### 14.8.2. Cómo afecta cada tipo de cambio

| Cambio | Backend Railway | Frontend Web Railway | APK / .exe / Linux instalados |
|---|---|---|---|
| **Backend solo** (Service, Repository, lógica de negocio, fix SMTP/Brevo, etc.) | ✅ Actualiza | — | ✅ "Funciona" porque llaman a la API actualizada, pero el código Dart sigue siendo el viejo. Si el cambio era de comportamiento del backend, los usuarios ven el efecto sin reinstalar. |
| **Frontend solo** (Dart, widgets, `MarcoMovil`, textos, colores, navegación) | — | ✅ Actualiza | ❌ NO se ven los cambios. Los binarios entregados están "congelados" en el commit con el que se compilaron. Hay que regenerar y redistribuir. |
| **Contrato de API** (nuevo endpoint, cambio en DTO) | ✅ Actualiza | ✅ Actualiza | ❌ Hay que regenerar binarios; mientras tanto pueden romperse (peticiones a campos que ya no existen, etc.). |
| **Migración de BD** | Migrar **antes** del push del backend (ver 14.6) | — | — |

**Confusión típica que conviene aclarar**: cuando alguien ve que "el APK funciona" tras un cambio, suele ser porque el cambio era de **backend** y el APK simplemente está consumiendo la API actualizada. El código de la pantalla dentro del APK sigue siendo el de cuando se compiló. La prueba inequívoca es cambiar algo puramente visual (un texto, un color, el `MarcoMovil`) y comprobar si el APK ya instalado lo refleja sin reinstalar — **no lo hace**.

#### 14.8.3. Comandos para regenerar cada binario

Cada `flutter build` debe ejecutarse **en el sistema operativo destino** (no se puede cross-compilar `.exe` desde Linux sin pipelines especiales).

```bash
cd frontend_victorino

# Android — desde cualquier SO con SDK Android
flutter build apk --release
# Salida: build/app/outputs/flutter-apk/app-release.apk

# iOS — solo en macOS con Xcode
flutter build ipa --release
# Salida: build/ios/ipa/

# Windows — solo en Windows con Visual Studio 2022 (carga C++)
flutter build windows --release
# Salida: build/windows/x64/runner/Release/

# Linux — solo en una distro Linux con dependencias GTK
flutter build linux --release
# Salida: build/linux/x64/release/bundle/

# Web — ya se hace solo en Railway, pero para tener una copia local:
flutter build web --release
# Salida: build/web/


```
## Estado de cada plataforma y qué hacer si cambias el frontend

| Plataforma     | ¿Lo tienes ya construido?            | Qué hacer si cambias el frontend |
|----------------|--------------------------------------|----------------------------------|
| **Web (URL de Railway)** | ✅ Sí, autoupdate | Nada. `git push` actualiza automáticamente. |
| **Android APK** | El que generaste manualmente | Ejecutar `flutter build apk --release` y entregar el `.apk` nuevo. |
| **Windows .exe** | El que generaste manualmente | Ejecutar `flutter build windows --release` y entregar el `.exe` nuevo. |
| **Linux** | El que generaste manualmente | Ejecutar `flutter build linux --release` y entregar el bundle nuevo. |
| **iOS .ipa** | Solo si lo generaste en Mac | Ejecutar `flutter build ipa --release`. |


Tras cada `build`, hay que **redistribuir el binario** a los usuarios (Drive, Telegram, USB, etc.). El usuario tiene que desinstalar el viejo e instalar el nuevo, salvo que se monte alguno de los mecanismos del siguiente sub-apartado.

#### 14.8.4. Opciones para conseguir auto-update también en binarios nativos

Si se quisiera que un cambio en Dart llegase también a los `.apk` / `.exe` / Linux ya instalados sin que el usuario tenga que reinstalar, hay opciones. Ordenadas de menos a más esfuerzo:

## Para Android

| Solución | Esfuerzo | Coste | Cómo funciona |
|---|---|---|---|
| **Shorebird** ✅ recomendada | Bajo | Gratis (tier free) | OTA real para Flutter. Cambias Dart, ejecutas shorebird release + shorebird patch, y los APK ya instalados descargan el código nuevo silenciosamente al abrirse. Es lo más "wow" para el tribunal. |
| **Google Play Store** (track interno) | Medio | 25 € pago único | Subes el AAB, todos los usuarios reciben actualización automática como cualquier app del store. |
| **Firebase App Distribution** | Bajo | Gratis | Subes el APK, los testers reciben notificación. Tienen que tocar "instalar" — no es totalmente silencioso. |
| **Updater casero**  | Alto |Gratis | Endpoint /api/v1/version en el backend. App al arrancar lo consulta; si hay versión nueva, descarga el .apk y lo instala. Requiere "fuentes desconocidas" y código nativo. Hacky. |

## Opciones para distribuir iOS (.ipa)

| Solución     | Esfuerzo | Coste                         | Cómo funciona |
|--------------|----------|-------------------------------|----------------|
| **Shorebird** | Bajo     | Gratis (tier free)            | Igual que en Android: también soporta iOS y permite actualizaciones OTA. |
| **TestFlight** | Medio    | 99 €/año (Apple Developer)     | Distribución beta oficial. Los testers reciben la app actualizada automáticamente. |
| **App Store** | Alto     | 99 €/año + tiempo de revisión | La opción más profesional. Apple revisa cada release (1–3 días). |

## Para Windows

| Solución | Esfuerzo | Coste | Cómo funciona |
|---|---|---|---|
| **MSIX con AppInstaller** | Medio | Gratis | Empaquetas como MSIX y configuras un fichero `.appinstaller` apuntando a Railway. Windows comprueba periódicamente y actualiza solo. |
| **Microsoft Store** | Medio | ~16 € pago único | Lo subes y los usuarios reciben actualizaciones como cualquier app de la Store. |
| **Updater casero** | Alto | Gratis | Tu app consulta `/api/v1/version`, descarga el `.exe` nuevo de Railway y lanza el instalador. Funciona pero requiere código. |

## Para Linux

| Solución | Esfuerzo | Coste | Cómo funciona |
|---|---|---|---|
| **AppImage + AppImageUpdate** | Bajo | Gratis | Formato single-file, mecanismo de update basado en zsync. |
| **Snap Store** | Medio | Gratis | Empaquetas como `.snap`, `snapd` actualiza automáticamente. |
| **Flatpak / Flathub** | Medio | Gratis | Igual con `.flatpak`. Más popular en distros modernas. |

#### 14.8.5. Shorebird en detalle (recomendado para Android/iOS en TFG)

Shorebird es la única solución que da **OTA real para Flutter** sin pasar por una store, y tiene un tier gratuito suficiente para un TFG. Funciona así:

1. Empaqueta el APK/IPA con una **runtime de Flutter modificada** que, al arrancar, consulta los servidores de Shorebird.
2. Si hay un "patch" (parche con código Dart nuevo) disponible para esa release, lo descarga y lo aplica antes de pintar la primera pantalla.
3. El binario nativo no cambia, pero el código Dart sí — así que cualquier cambio puramente Flutter (widgets, lógica de presentación, estado…) llega al usuario sin reinstalar.

##### Limitaciones que hay que conocer antes de adoptarlo

- **No parchea cambios en plugins nativos** ni en código Kotlin/Swift. Si se añade un plugin nuevo (p.ej. otro `firebase_*` package) eso sí exige rebuild completo y reinstalación.
- **Tier free** tiene un límite mensual de patches (suficiente para un TFG con pocos usuarios).
- **Solo Android e iOS**. No cubre Windows ni Linux.
- Añade una dependencia externa: si Shorebird desaparece, las apps siguen funcionando pero pierden el OTA.

##### Pasos para integrarlo en este proyecto

```bash
# 1. Instalar el CLI (una sola vez en la máquina)
dart pub global activate shorebird_cli

# 2. Login (abre el navegador con OAuth)
shorebird login

# 3. Inicializar el proyecto Flutter (añade shorebird.yaml al repo)
cd frontend_victorino
shorebird init

# 4. Primera release Android (sustituye al flutter build apk --release)
shorebird release android
# Salida: build/app/outputs/flutter-apk/app-release.apk + sube metadatos a Shorebird

# 5. Distribuir ese APK como siempre (Drive, USB, Telegram…). Es el binario base.

# --- A partir de aquí, cada cambio puramente Dart se publica como patch: ---

# 6. Editas código Dart (p.ej. MarcoMovil, texto de un botón, etc.)
git commit -am "..."

# 7. Generar y subir el patch
shorebird patch android
# Los APK ya instalados detectarán el patch al abrirse y se actualizarán silenciosamente.

# 8. Para iOS (solo en macOS):
shorebird release ios
shorebird patch ios
```

##### Lo que hay que documentar en la memoria si se adopta

- Que existe una dependencia con Shorebird (servicio externo).
- Que el flujo de release tiene **dos verbos**: `release` (cuando hay cambios nativos o plugins nuevos) y `patch` (cuando solo cambia Dart).
- Que el RGPD queda intacto: Shorebird solo recibe el código Dart compilado, no datos de usuarios.

#### 14.8.6. Estrategia recomendada para el TFG

Honestamente, montar auto-update para **todas** las plataformas en un TFG es sobrecualificación y consume tiempo que no suma en la rúbrica. La rúbrica valora *que la app funcione, esté desplegada y sea accesible*, no que cada binario tenga OTA propio.

La estrategia equilibrada (la que aplico en este proyecto) es:

| Plataforma | Estrategia | Justificación |
|---|---|---|
| **Web** (Railway) | Auto-update vía Railway. **Entrega principal** para la defensa. | Ya está. Cero coste, siempre actualizada, el tribunal abre la URL y ve la última versión. |
| **Android (.apk)** | (Opcional) Shorebird para OTA Dart | Free, se monta en una tarde, punto destacable de arquitectura en la memoria. Si no se monta, se entrega el APK final como "snapshot" y listo. |
| **iOS** | Sáltatelo salvo que tengas Mac + Apple Developer | La web cubre iOS perfectamente desde Safari. |
| **Windows / Linux** | Sin auto-update | Generar el binario una vez antes de la entrega final y meterlo en el USB del TFG. Defendible: "para escritorio se recomienda usar la versión web; los binarios nativos son una entrega congelada de la versión final". |

#### 14.8.7. Workflow real día a día (resumen)

```
Cambio en el código
        │
        ▼
   ¿Qué cambió?
        │
   ┌────┴───────────────────────────┬──────────────────────────────┐
   ▼                                ▼                              ▼
Backend Java                  Frontend Dart                  Contrato API
   │                                │                              │
git push                       git push                        git push
   │                                │                              │
   ▼                                ▼                              ▼
Railway redepliega           Railway redepliega              Railway redepliega
backend (1-3 min).           frontend web (1-3 min).         backend + frontend.
   │                                │                              │
   ▼                                ▼                              ▼
APK / .exe / Linux           APK / .exe / Linux              APK / .exe / Linux
funcionan con la             NO ven el cambio.               pueden romperse.
API nueva sin más.           Hay que regenerar y             Hay que regenerar
                             redistribuir.                   y redistribuir.
                             (Salvo Shorebird en             Coordinar el orden
                              Android/iOS, que                de despliegue
                              parchea OTA.)                   (BD → backend → frontend).
```

En condiciones normales del desarrollo del TFG, el ciclo es: **edito código → `git push` → en 2-3 minutos la web está actualizada → refresco el navegador → veo el cambio**. Los binarios nativos solo se regeneran en hitos importantes (defensa, entrega final, demo a cliente).

---

## 15. Plan de contingencia

Un **plan de contingencia** es un conjunto de estrategias y procedimientos diseñados para garantizar que el sistema **continúe funcionando, o se recupere lo más rápido posible, ante cualquier imprevisto grave**. Su objetivo es minimizar el impacto sobre los usuarios y proteger la integridad de los datos.

Esta sección describe el plan de contingencia para nuestra App llamado Victorino Style en producción: un único desarrollador, plan Hobby de Railway, sin equipo de operaciones dedicado. Para cada riesgo se documenta tanto la medida real aplicada como la que tendría un equipo profesional, de forma que quede claro qué se ha asumido conscientemente y qué se haría con más recursos.

### 15.1. Identificación y análisis de riesgos

Los riesgos a los que se expone el sistema se agrupan en cuatro grandes categorías. Esta clasificación está alineada con los marcos estándar de gestión de riesgos en proyectos software (PMBOK, ISO 27005).

#### 15.1.1. Riesgos técnicos

| ID | Riesgo | Descripción |
|---|---|---|
| T1 | **Caída del backend Spring Boot** | El proceso JVM se cae por un crash, OOM o un bug en runtime. La app deja de responder. |
| T2 | **Caída del servicio MySQL en Railway** | El contenedor MySQL muere. Sin BD el backend no puede atender peticiones. |
| T3 | **Caída del frontend nginx** | El servicio del frontend cae. Los usuarios web ven "Application failed to respond". El APK Android sigue funcionando (habla directo con el backend). |
| T4 | **Bug crítico introducido en un deploy** | Un push a `Produccion-Railway` rompe una funcionalidad importante (login, reservar, cancelar). |
| T5 | **Corrupción de datos en BD** | Un INSERT/UPDATE mal hecho destroza datos consistentes (citas con horas inválidas, FK rotas, etc.). |
| T6 | **Pérdida del volumen de uploads** | El disco persistente de `/app/uploads` se borra accidentalmente. Las fotos subidas por usuarios se pierden. Las seed se recuperan solas. |
| T7 | **Build fallido tras un push** | Maven o Docker fallan al compilar. El servicio antiguo sigue corriendo (gracias a rolling deploys), pero los cambios no llegan. |
| T8 | **Saturación de RAM (OOM)** | El JVM intenta usar más RAM que la disponible. El kernel mata el proceso. |
| T9 | **Saturación de disco MySQL** | La BD crece más de lo previsto y el volumen se llena. |

#### 15.1.2. Riesgos de personal ("factor autobús")

El **factor autobús** es la métrica que mide *"si esta persona desaparece mañana, ¿el proyecto sigue?"*. En Victorino Style hoy el factor es **1** (el peor posible): si yo, Kevin, dejo de estar, nadie más conoce el sistema.

| ID | Riesgo | Descripción |
|---|---|---|
| P1 | **Único desarrollador (factor autobús = 1)** | Solo yo conozco la arquitectura. Si me pasa algo, nadie puede mantener el sistema. |
| P2 | **Credenciales centralizadas en mi cuenta personal** | Mi cuenta Google (Drive, Firebase, Gmail), Railway, GitHub. Si pierdo acceso a mi cuenta principal, pierdo control de todo. |
| P3 | **Conocimiento implícito** | Decisiones de diseño y "porqués" no documentados que solo están en mi cabeza. |
| P4 | **Indisponibilidad temporal** | Vacaciones, enfermedad, exámenes. No hay quien atienda incidencias en ese tiempo. |

#### 15.1.3. Riesgos operativos

Dependencias de proveedores externos sobre los que no tengo control.

| ID | Riesgo | Descripción |
|---|---|---|
| O1 | **Railway sube precios o cambia condiciones** | El plan Hobby pasa de 5 €/mes a 50 €/mes, o deja de existir. |
| O2 | **Railway sufre un incidente global** | Un fallo en la infraestructura de Railway deja todos sus servicios caídos. Ha pasado puntualmente. |
| O3 | **Firebase cambia condiciones del Spark plan** | Google decide cobrar por FCM en el plan gratuito, o cambia el formato de credenciales. |
| O4 | **Gmail bloquea la cuenta SMTP** | Google detecta envíos masivos atípicos y bloquea la app password. El cliente no puede recuperar contraseña. |
| O5 | **GitHub suspende mi cuenta** | Violación accidental de TOS, cuota de Actions excedida, o cierre administrativo. Pierdo el repo (aunque tengo copia local). |
| O6 | **Dominio `.up.railway.app` deja de funcionar** | Railway decide migrar sus dominios o sufre un fallo DNS. |

#### 15.1.4. Riesgos de seguridad

| ID | Riesgo | Descripción |
|---|---|---|
| S1 | **Secretos en el historial git** | Decisión consciente de no rotar tras la limpieza. Si el repo se hace público o se filtra, un atacante puede leer la app password de Gmail, el JWT secret y la clave privada de Firebase del historial. |
| S2 | **TCP Proxy del MySQL abierto** | Mientras el proxy público esté activo (lo dejé activo por comodidad), hay un puerto MySQL accesible desde Internet expuesto a ataques de fuerza bruta. |
| S3 | **JWT secret comprometido** | Si se filtra `VICTORINO_JWT_SECRET`, un atacante puede forjar tokens válidos y suplantar a cualquier usuario. |
| S4 | **App password Gmail comprometida** | Un atacante podría usar `peluqueria.victorinostyle@gmail.com` como spam relay. |
| S5 | **DDoS a la URL pública** | Un bot envía millones de peticiones para saturar el backend. |
| S6 | **Inyección SQL** | Mitigado en el código (Hibernate hace parametrización automática) pero teóricamente posible en queries nativas mal hechas. |
| S7 | **XSS en la app web** | Mitigado por Flutter (escapa automáticamente el output) pero teóricamente posible si se introduce HTML sin sanitizar. |
| S8 | **CSRF** | Mitigado por usar JWT en header `Authorization` (no cookies) y CORS restringido. |

### 15.2. Matriz de priorización (impacto × probabilidad)

Cada riesgo se evalúa con dos métricas en escala 1-5:

- **Impacto (I)**: cómo de mal afectaría si se materializa. 1 = molestia menor, 5 = sistema completamente caído / pérdida de datos masiva.
- **Probabilidad (P)**: lo probable que es que suceda en los próximos 12 meses. 1 = casi imposible, 5 = casi seguro.

**Score = I × P**. Los riesgos con score más alto requieren más atención. Clasificación:

- **Crítico** (score 20-25): mitigación/acción obligatoria.
- **Alto** (score 12-19): plan de respuesta documentado.
- **Medio** (score 6-11): aceptable con vigilancia.
- **Bajo** (score 1-5): aceptable sin acciones especiales.

| ID | Riesgo | I | P | Score | Nivel |
|---|---|:-:|:-:|:-:|---|
| T1 | Caída backend | 4 | 3 | 12 | **Alto** |
| T2 | Caída MySQL | 5 | 2 | 10 | Medio |
| T3 | Caída frontend nginx | 2 | 2 | 4 | Bajo |
| T4 | Bug crítico en deploy | 4 | 4 | 16 | **Alto** |
| T5 | Corrupción de datos BD | 5 | 2 | 10 | Medio |
| T6 | Pérdida volumen uploads | 3 | 1 | 3 | Bajo |
| T7 | Build fallido | 2 | 3 | 6 | Medio |
| T8 | Saturación RAM (OOM) | 4 | 2 | 8 | Medio |
| T9 | Saturación disco MySQL | 4 | 1 | 4 | Bajo |
| P1 | Único desarrollador | 5 | 3 | 15 | **Alto** |
| P2 | Credenciales en cuenta personal | 4 | 2 | 8 | Medio |
| P3 | Conocimiento implícito | 3 | 4 | 12 | **Alto** |
| P4 | Indisponibilidad temporal | 3 | 5 | 15 | **Alto** |
| O1 | Railway sube precios | 3 | 2 | 6 | Medio |
| O2 | Incidente global Railway | 5 | 1 | 5 | Bajo |
| O3 | Firebase cambia condiciones | 2 | 1 | 2 | Bajo |
| O4 | Gmail bloquea cuenta | 3 | 1 | 3 | Bajo |
| O5 | GitHub suspende cuenta | 4 | 1 | 4 | Bajo |
| O6 | Dominio Railway caduca | 4 | 1 | 4 | Bajo |
| S1 | Secretos en historial git | 5 | 3 | 15 | **Alto** |
| S2 | TCP Proxy MySQL abierto | 4 | 3 | 12 | **Alto** |
| S3 | JWT secret comprometido | 5 | 2 | 10 | Medio |
| S4 | App password Gmail comprometida | 3 | 2 | 6 | Medio |
| S5 | DDoS | 3 | 1 | 3 | Bajo |
| S6 | Inyección SQL | 5 | 1 | 5 | Bajo |
| S7 | XSS | 3 | 1 | 3 | Bajo |
| S8 | CSRF | 4 | 1 | 4 | Bajo |

**Riesgos críticos / altos identificados** (8 en total, marcados en negrita): T1, T4, P1, P3, P4, S1, S2 y… ninguno alcanza nivel "Crítico" puro (score 20+). Esto es coherente: ningún riesgo es probable y catastrófico al mismo tiempo.

### 15.3. Estrategias de mitigación y respuesta

Para cada riesgo de nivel **Alto** se define:

- **Medida preventiva**: lo que se hace AHORA para reducir la probabilidad o el impacto.
- **Medida reactiva**: lo que se hace SI el riesgo se materializa.
- **RTO (Recovery Time Objective)**: tiempo máximo aceptable hasta que el servicio vuelve a estar disponible.
- **RPO (Recovery Point Objective)**: pérdida máxima aceptable de datos medida en tiempo (ej. "hasta 24h de datos pueden perderse").

| Riesgo | Medida preventiva | Medida reactiva | RTO | RPO |
|---|---|---|---|---|
| **T1** Caída backend | (1) `JAVA_TOOL_OPTIONS` limita la RAM y previene OOM. (2) Spring Boot devuelve mensajes de error consistentes vía `RestControllerAdvice`. (3) Hibernate HikariCP reintenta automáticamente al perder conexión MySQL. | (1) Railway reinicia el proceso automáticamente al detectar crash. (2) Si persiste tras 3 reintentos, hacer **Rollback al deploy anterior** desde la pestaña Deployments. (3) Investigar logs para identificar la causa raíz. | **5 min** | 0 (no se pierden datos, solo conexiones puntuales) |
| **T4** Bug crítico en deploy | (1) Revisión mental del diff antes del push. (2) Probar en local antes de pushear. (3) Si los Build Logs fallan, el servicio antiguo sigue corriendo (rolling deploys). | (1) **Redeploy del commit anterior**: Railway → Deployments → seleccionar el último deploy verde → menú ⋮ → Redeploy. (2) `git revert` del commit malo y push. (3) Postmortem documentando qué falló y cómo evitarlo. | **3 min** (un clic en Redeploy) | 0 |
| **P1** Único desarrollador | (1) **Esta guía** documenta todo lo necesario para que otra persona técnica pueda mantener el sistema. (2) `.env.example` documenta todas las variables. (3) `schema.sql` y `seed.sql` versionados en el repo. (4) Repositorio GitHub vinculado a cuenta personal con 2FA. | (1) Compartir credenciales con persona de confianza en sobre sellado físico. (2) En caso de baja prolongada, autorizar acceso al repo y a Railway. | — | — |
| **P3** Conocimiento implícito | (1) Esta guía documenta arquitectura, decisiones y "porqués". (2) Comentarios extensos en código crítico (`CitaService`, `JwtService`, `CorsConfig`, `FirebaseConfig`, `UploadsSeederRunner`). (3) Memoria del TFG explica el dominio funcional. | (1) Sesión de transferencia de conocimiento con el sucesor. (2) Pair programming durante un periodo de transición. | — | — |
| **P4** Indisponibilidad temporal | (1) El sistema arranca solo (autodeploys), no requiere intervención manual diaria. (2) Railway reinicia procesos caídos automáticamente. | (1) Si surge una incidencia y no puedo atenderla, los usuarios verán errores pero el sistema sigue intentando reiniciarse. (2) Activar respuesta automática en el correo `peluqueria.victorinostyle@gmail.com` indicando "Servicio en mantenimiento, volvemos pronto". | **24 h** (tiempo aceptable de respuesta del único dev) | 0 |
| **S1** Secretos en historial git | (1) Repositorio PRIVADO en GitHub. (2) `.gitignore` actualizado para que no vuelva a ocurrir. (3) Decisión documentada: aceptar el riesgo en el TFG. | (1) Si se filtra el repo, **rotar inmediatamente**: cambiar app password de Gmail, regenerar JWT secret, generar nueva clave de Firebase. (2) Actualizar las 3 variables en Railway. (3) Forzar logout global desde la BD: `DELETE FROM refresh_token;`. | **30 min** | 0 |
| **S2** TCP Proxy MySQL abierto | (1) Contraseña root MySQL de 32+ caracteres (la genera Railway). (2) Monitorizar logs de conexiones fallidas. | (1) Cerrar el TCP Proxy desde Railway (sub-apartado 14.4) si no se necesita acceso administrativo. (2) Si se detecta intento de fuerza bruta, cambiar la contraseña MySQL desde Railway. | **2 min** (cerrar el proxy) | 0 |

#### 15.3.1. Estrategias para riesgos de nivel Medio

Aunque su score es menor, conviene documentar también la respuesta para que el plan esté completo.

| Riesgo | Medida preventiva | Medida reactiva | RTO | RPO |
|---|---|---|---|---|
| **T2** Caída del MySQL | (1) Railway gestiona la BD con alta disponibilidad básica del propio plugin. (2) HikariCP reintenta conexiones perdidas. (3) Snapshots diarios del volumen MySQL. | (1) Railway intenta reiniciar el contenedor MySQL automáticamente. (2) Si tarda, comprobar el estado de Railway. (3) Si se confirma corrupción del volumen, restaurar del último snapshot (ver Runbook 15.5.2). | **15 min** | 24 h (entre snapshots automáticos) |
| **T5** Corrupción de datos | (1) Hibernate parametriza queries (previene SQL injection). (2) Las constraints (FK, CHECK, NOT NULL) del schema impiden estados inválidos. (3) `@Transactional` garantiza atomicidad de operaciones complejas. | (1) Parar el backend para evitar más escrituras. (2) Restaurar desde el último backup limpio. (3) Replay manual de transacciones legítimas perdidas si se identifican. | **30 min** | 24 h |
| **T7** Build fallido tras push | (1) `./mvnw compile` en local antes de pushear. (2) Si el build falla en Railway, el servicio anterior sigue corriendo (rolling deploys). | (1) Revisar Build Logs en Railway para identificar el error. (2) `git revert` + push de la corrección. (3) Mientras tanto, los usuarios siguen usando la versión anterior. | **10 min** | 0 |
| **T8** Saturación de RAM (OOM) | (1) `JAVA_TOOL_OPTIONS` limita el heap a 400 MB. (2) Monitorización en pestaña Metrics. (3) HikariCP con pool de conexiones acotado. | (1) Railway mata el proceso y lo reinicia automáticamente. (2) Si persiste, ajustar `-Xmx` a un valor más bajo o subir al plan Pro con más RAM. | **5 min** | 0 |
| **P2** Credenciales en cuenta personal | (1) 2FA activado en Google, Railway, GitHub. (2) Contraseñas únicas guardadas en gestor de contraseñas. (3) Esta guía documenta qué cuenta es responsable de qué. | (1) En caso de pérdida de acceso, usar opciones de recuperación de Google/GitHub/Railway. (2) Si se pierden todas las cuentas, recurrir al `mysqldump` local y `.env.example` para reconstruir el sistema. | **2-7 días** (recuperación de cuentas) | Variable |
| **O1** Railway sube precios | (1) Toda la configuración está parametrizada por variables de entorno. (2) Código portable entre PaaS (Render, Fly.io, Heroku). | (1) Evaluar el cambio y decidir si compensa migrar. (2) Si se migra, seguir el plan documentado en 15.5.4 (paso 3). | **4 h** (migración a otro PaaS) | 24 h |
| **S3** JWT secret comprometido | (1) Secret de 88 caracteres base64 (256+ bits de entropía). (2) Solo Railway lo conoce; no aparece en logs. | (1) Rotar el secret (ver Runbook 15.5.3). (2) `DELETE FROM refresh_token;` para invalidar sesiones. (3) Forzar relogin a todos los usuarios. | **30 min** | 0 |
| **S4** App password Gmail comprometida | (1) No es la contraseña real de Gmail, es una app password específica que se puede revocar sin perder la cuenta. (2) Gmail tiene rate limiting y monitorización de actividad. | (1) Revocar la app password y crear una nueva. (2) Actualizar `SPRING_MAIL_PASSWORD` en Railway. (3) Si Gmail detectó abuso, esperar a que levante el bloqueo o migrar a SendGrid (ver Runbook 15.5.5). | **15 min** | 0 |

#### 15.3.2. Estrategias para riesgos de nivel Bajo

Estos riesgos son aceptables sin acciones especiales, pero conviene tener una respuesta documentada por si suceden.

| Riesgo | Medida preventiva | Medida reactiva | RTO |
|---|---|---|---|
| **T3** Caída frontend nginx | nginx alpine es muy estable; Railway reinicia automáticamente. | El APK Android sigue funcionando contra el backend mientras el frontend se reinicia (~10 s). | 1 min |
| **T6** Pérdida volumen uploads | El `UploadsSeederRunner` repuebla las 7 fotos seed al arrancar. | (1) Reiniciar el backend → se restauran las fotos seed automáticamente. (2) Las fotos subidas por usuarios sí se pierden; restaurar del último snapshot del volumen si lo hubiera. | 5 min |
| **T9** Saturación disco MySQL | Solo se hacen INSERTs de citas/notificaciones; el crecimiento es predecible (~1 KB por cita). El plan Hobby permite varios GB. | Borrar manualmente notificaciones antiguas (>1 año) desde MySQL Workbench. Si crece mucho, subir al plan Pro con más espacio. | 30 min |
| **O2** Incidente global Railway | Status page de Railway monitorizada. | Esperar. Comunicar a los usuarios. Si se alarga >24h, considerar migración temporal a otro PaaS (Runbook 15.5.4). | Variable |
| **O3** Firebase cambia condiciones | Mantenerse informado vía blog oficial de Firebase. | Implementar un proveedor alternativo de push (OneSignal, AWS SNS) que es estructuralmente similar. | 2 días |
| **O4** Gmail bloquea cuenta | Volúmenes bajos de envío (recuperación de contraseña es ocasional). No usar Gmail como remitente masivo. | Crear cuenta Gmail nueva o migrar a SendGrid/Brevo (Runbook 15.5.5). | 1 h |
| **O5** GitHub suspende cuenta | No subir contenido que viole TOS. Tener copia local del repo. | Restaurar el repo en GitLab o Bitbucket desde la copia local. Reconectar Railway al nuevo origen. | 2 h |
| **O6** Dominio Railway caduca | Railway gestiona los dominios `.up.railway.app`, no se renuevan manualmente. | Regenerar el dominio público en Settings → Networking. Actualizar `VICTORINO_CORS_ORIGENES_EXTRA` y recompilar APK + frontend con la nueva URL. | 30 min |
| **S5** DDoS | Railway proxy edge tiene protección DDoS básica. | Si el ataque persiste, poner Cloudflare delante (gratis hasta cierto volumen). | 1 h |
| **S6** Inyección SQL | Hibernate parametriza queries automáticamente. No hay queries nativas en el código. | Si se identifica una query vulnerable, parchar y desplegar. Auditar BD por daños. | 30 min |
| **S7** XSS | Flutter escapa automáticamente el output de texto. No se renderiza HTML del usuario. | Si se introduce una vulnerabilidad, sanitizar el campo afectado y desplegar. | 30 min |
| **S8** CSRF | Mitigado por JWT en header (no cookies). CORS restrictivo. | No requiere acción específica. | — |

### 15.4. Roles y responsabilidades

#### 15.4.1. Roles en una versión enterprise

En un sistema profesional con equipo dedicado, los roles típicos durante una crisis serían:

| Rol | Responsabilidad |
|---|---|
| **Coordinador de crisis** (Incident Commander) | Activa el plan, toma decisiones de alto nivel, asigna recursos, decide si escalar. |
| **Líder técnico / SRE** | Coordina la recuperación técnica. Lee logs, identifica la causa raíz, ejecuta el rollback o el hotfix. |
| **DBA** (Database Administrator) | Gestiona la base de datos: restaura backups, repara corrupciones, optimiza queries. |
| **Gestor de comunicación** | Habla con clientes, redes sociales, prensa. Mantiene la imagen pública durante la crisis. |
| **DPO** (Data Protection Officer) | Responsable RGPD. Si hay filtración de datos personales, lleva las comunicaciones a la AEPD y a los usuarios afectados. |
| **Líder de seguridad** (CISO) | Coordina la respuesta ante incidentes de seguridad: aislamiento del sistema, análisis forense, rotación de credenciales. |

#### 15.4.2. Realidad en Victorino Style (TFG)

En el TFG, **todos esos roles los desempeña la misma persona: yo (Kevin)**. Esto es típico de proyectos pequeños y se asume conscientemente como riesgo (P1 en la matriz). Para una "v1.1 profesional" se delegarían a:

- **Coordinador + Líder técnico**: el propio Kevin como dueño técnico.
- **DBA**: contratar a un especialista a demanda (~30 €/hora cuando haga falta), o si la peluquería real lo adopta, el responsable de IT de la peluquería.
- **DPO**: la peluquería real designa uno (obligatorio por RGPD si trata datos de muchos clientes).
- **Comunicación**: lo asume el dueño del negocio (Victorino) directamente.

### 15.5. Procedimientos operativos detallados (runbooks)

Un **runbook** es una guía paso a paso para responder a un incidente concreto, escrita en frío para poder seguirse en caliente. Aquí los 5 más relevantes.

#### 15.5.1. Runbook: "El backend no responde"

**Síntoma**: las peticiones a `https://victorinostyle-production.up.railway.app/api/v1/auth/login` devuelven timeouts o errores 502/504. El frontend muestra "Failed to fetch" o queda colgado.

**Pasos**:

1. **Verificar el estado del servicio en Railway**:
   - Acceder a Railway → proyecto Victorino-Style → cajita del backend.
   - Mirar el indicador: ¿punto verde "Active" o rojo "Crashed"?

2. **Si está crashed**:
   - Pestaña **Deployments** → mirar el último deploy.
   - Pestaña **Deploy Logs** → buscar excepción.
   - Si el error es de runtime (NullPointer, etc.) → ir al paso 4.
   - Si el error es de inicialización (no conecta a MySQL, no encuentra una variable) → ir al paso 3.

3. **Si el problema es de variables o conexión**:
   - Pestaña **Variables**: comprobar que `SPRING_DATASOURCE_URL`, `SPRING_DATASOURCE_PASSWORD`, etc. están bien.
   - Pestaña del MySQL: comprobar que está "Online".
   - Pulsar **Restart** en el deploy del backend.

4. **Si es un bug introducido por un deploy reciente**:
   - Pestaña **Deployments** → buscar el último deploy que funcionaba (etiqueta verde).
   - Menú ⋮ → **Redeploy** → confirmar.
   - El servicio antiguo vuelve a estar activo en ~3 minutos.

5. **Tras restaurar el servicio**:
   - `git revert` del commit problemático en local.
   - `git push` → Railway redesplegará la versión "buena".
   - Postmortem: documentar qué pasó en `documentacion/incidentes/<fecha>.md`.

#### 15.5.2. Runbook: "La base de datos ha perdido datos"

**Síntoma**: faltan citas, usuarios o cualquier otro registro que se esperaba. Posibles causas: borrado accidental, query mal hecha, corrupción.

**Pasos**:

1. **Parar el backend inmediatamente** para evitar más pérdida o sobreescritura:
   - Railway → servicio backend → menú ⋮ → **Stop**.

2. **Conectar a MySQL desde Workbench** (activar TCP Proxy si está cerrado, ver sub-apartado 6.4.1).

3. **Confirmar el alcance del daño**:
   ```sql
   SELECT COUNT(*) FROM usuario;
   SELECT COUNT(*) FROM cita;
   SELECT MAX(fecha_creacion_cita) FROM cita;
   ```
   Comparar con los valores esperados (53 usuarios, ~1000 citas).

4. **Restaurar desde el snapshot diario de Railway**:
   - Railway → servicio MySQL → pestaña **Settings** → sección **Backups** (si el plan lo incluye).
   - Seleccionar el snapshot anterior al incidente.
   - **Restore**.

5. **Restaurar desde un dump manual** (alternativa si no hay snapshot reciente):
   - Localizar el último `backup_YYYY_MM_DD.sql` en mi Drive.
   - `mysql -h ... -u root -p railway < backup_YYYY_MM_DD.sql`.

6. **Rearrancar el backend**:
   - Railway → backend → **Start**.

7. **Postmortem**: documentar qué query/acción causó el problema.

**RPO esperado**: hasta 24h de pérdida (snapshot diario). Con backups manuales más frecuentes el RPO baja.

#### 15.5.3. Runbook: "Han comprometido un secreto"

**Síntoma**: detección de comportamiento anómalo (logins desde IPs raras, envíos masivos de emails desde la cuenta, etc.).

**Pasos**:

1. **Rotar inmediatamente** el secreto comprometido:
   - **JWT secret**: generar nuevo con `openssl rand -base64 64` → actualizar `VICTORINO_JWT_SECRET` en Railway.
   - **App password Gmail**: ir a Cuenta Google → Seguridad → Contraseñas de aplicación → eliminar la actual → crear nueva → actualizar `SPRING_MAIL_PASSWORD` en Railway.
   - **Firebase service account**: ir a Firebase Console → Configuración → Cuentas de servicio → eliminar la clave comprometida → generar nueva → pegar el JSON nuevo en `VICTORINO_FIREBASE_CREDENTIALS_JSON`.

2. **Invalidar sesiones activas** (si fue el JWT secret):
   ```sql
   DELETE FROM refresh_token;
   ```
   Todos los usuarios tendrán que volver a hacer login (mejor que dejarles con sesiones potencialmente comprometidas).

3. **Esperar el redeploy automático** (Railway lo dispara al cambiar una variable).

4. **Auditoría**:
   - Revisar la tabla `auditoria` para ver acciones anómalas.
   - Revisar logs de los últimos días en Railway para identificar accesos sospechosos.

5. **Comunicación a usuarios** (si hay impacto sobre ellos): enviar correo a todos los usuarios afectados informando del incidente y de las medidas tomadas.

#### 15.5.4. Runbook: "Railway está caído globalmente"

**Síntoma**: la URL pública no responde. El propio dashboard de Railway tampoco carga. Reportes en el [status page de Railway](https://status.railway.com).

**Pasos**:

1. **Verificar que es Railway y no algo mío**:
   - Comprobar `https://status.railway.com`.
   - Si confirma un incidente: solo queda esperar.

2. **Activar la comunicación**:
   - Email automático en `peluqueria.victorinostyle@gmail.com` indicando "Estamos sufriendo una caída temporal por un incidente en nuestro proveedor cloud. Estimación de recuperación: pendiente".

3. **Plan B a largo plazo** (si la caída se alarga >24h): migrar a otro proveedor (Render, Fly.io). Como toda la configuración está parametrizada por variables de entorno y el código es portable, **la migración es factible en ~4 horas**:
   - Crear cuenta en Render.
   - Crear servicio PostgreSQL/MySQL y backend desde el repo de GitHub.
   - Migrar el dump de la BD.
   - Configurar variables.
   - Actualizar DNS si hay dominio propio.

4. **Postmortem**: aprender del incidente. Si pasa más de una vez al año, replantear la dependencia exclusiva de Railway.

#### 15.5.5. Runbook: "Gmail ha bloqueado la cuenta SMTP"

**Síntoma**: el correo de recuperación de contraseña no llega. Los logs muestran `SMTPAuthenticationException` o similar.

**Pasos**:

1. **Verificar la cuenta Gmail**:
   - Acceder a `peluqueria.victorinostyle@gmail.com` desde un navegador.
   - Comprobar si Google muestra una advertencia ("Detectamos actividad inusual...").

2. **Generar nueva app password** (las antiguas pueden estar revocadas):
   - Cuenta → Seguridad → Verificación en dos pasos → Contraseñas de aplicaciones → Nueva.
   - Actualizar `SPRING_MAIL_PASSWORD` en Railway.

3. **Si Google bloquea la cuenta completamente** (raro pero posible):
   - Crear una cuenta Gmail nueva (`peluqueria.victorinostyle2@gmail.com`).
   - Actualizar `SPRING_MAIL_USERNAME` y `SPRING_MAIL_PASSWORD` en Railway.
   - Comunicar el cambio en la página web si fuera relevante.

4. **Plan B**: cambiar de proveedor SMTP a uno especializado:
   - **SendGrid** (gratis hasta 100 emails/día con cuenta verificada).
   - **Brevo** (gratis hasta 300/día).
   - Solo cambian las variables `SPRING_MAIL_*` en Railway, no hace falta tocar código.

### 15.6. Pruebas y simulacros (chaos engineering ligero)

Un plan que no se prueba no se sabe si funciona. Estos simulacros son baratos de ejecutar en un TFG y aumentan la confianza en el plan.

#### 15.6.1. Simulacro mensual: tirar el backend manualmente

**Objetivo**: medir el tiempo real de recuperación tras un crash.

1. Railway → backend → menú ⋮ → **Restart**.
2. Cronometrar cuánto tarda en volver a estar "Active".
3. Confirmar que el frontend recupera la sesión (no exige relogin).
4. Documentar el tiempo medido. Objetivo: <60 segundos.

**Resultado típico observado**: 10-15 segundos.

#### 15.6.2. Simulacro trimestral: restaurar un backup completo

**Objetivo**: verificar que los backups son útiles (no basta con tenerlos, hay que probar que se pueden restaurar).

1. Crear un proyecto Railway nuevo "Victorino-Style-Test".
2. Añadir un servicio MySQL.
3. Conectar Workbench y ejecutar el último `backup_YYYY_MM_DD.sql`.
4. Verificar contadores: `SELECT COUNT(*) FROM usuario`, etc.
5. Borrar el proyecto Railway test (no se queda cargando).

**Tiempo estimado del simulacro**: 30 minutos.

#### 15.6.3. Simulacro semestral: rotar el JWT secret

**Objetivo**: validar que el procedimiento de rotación funciona end-to-end.

1. Generar nuevo `VICTORINO_JWT_SECRET`.
2. Actualizarlo en Railway.
3. Esperar al redeploy.
4. Confirmar que TODOS los usuarios son deslogueados (tokens antiguos invalidados).
5. Hacer login de nuevo con `victorino@admin.com` → confirmar token nuevo emitido.

#### 15.6.4. Simulacro anual: deploy roto y rollback

**Objetivo**: practicar el flujo de emergencia.

1. Hacer un commit deliberadamente roto (ej. un import inexistente en el backend).
2. Push a `Produccion-Railway`.
3. Esperar al fallo del build en Railway.
4. Hacer Redeploy del commit anterior.
5. Cronometrar el tiempo total de recuperación.

### 15.7. Comunicación durante una crisis

#### 15.7.1. Plantillas de mensajes

**Detección inicial** (a usuarios afectados, por correo o redes):
> Estamos detectando problemas con el acceso a la aplicación. Nuestro equipo ya está investigando. Disculpa las molestias.

**Actualización en curso**:
> Hemos identificado el origen del problema y estamos trabajando en la solución. Estimamos recuperar el servicio en aproximadamente [X minutos].

**Servicio restaurado**:
> El servicio ya está funcionando con normalidad. Si sigues notando problemas, escríbenos a peluqueria.victorinostyle@gmail.com. Gracias por tu paciencia.

**Postmortem (24-48h después)**:
> Resumen del incidente del [fecha]: [descripción breve]. Causa raíz: [explicación]. Medidas tomadas para que no vuelva a ocurrir: [acciones]. No se perdieron datos de usuarios.

#### 15.7.2. Canales de comunicación

| Canal | Cuándo se usa |
|---|---|
| Correo masivo a usuarios | Caídas > 1h o incidentes que afecten directamente al acceso |
| Banner en la app web | Avisos no críticos (mantenimientos programados) |
| Notificación push | Mantenimientos urgentes (si la BD sigue operativa) |
| WhatsApp directo al dueño | Comunicación interna conmigo y Victorino |

### 15.8. Actualización continua del plan

El plan de contingencia **no es un documento estático**. Hay que revisarlo y actualizarlo periódicamente:

| Frecuencia | Acción |
|---|---|
| Trimestralmente | Revisar la matriz de riesgos: ¿hay nuevos riesgos? ¿la probabilidad o el impacto han cambiado? |
| Tras cada incidente | Añadir un nuevo runbook si el incidente no estaba contemplado. Actualizar los procedimientos si los existentes resultaron ineficaces. |
| Tras cada cambio de arquitectura mayor | Por ejemplo, si se migra de Railway a AWS, prácticamente todo el plan cambia. |
| Anualmente | Revisión completa del documento. |

**Última revisión de este plan**: mayo de 2026 (versión inicial del TFG).

### 15.9. FAQ específico del plan de contingencia

Preguntas y respuestas cortas pensadas para responder en directo durante la defensa.

**P: ¿Qué pasa exactamente si el backend Spring Boot se cae?**
R: Railway detecta el crash a los pocos segundos (el proceso devuelve un exit code distinto de 0), mata el contenedor y arranca uno nuevo automáticamente. Tiempo total de recuperación medido: **10-15 segundos**. Durante ese intervalo los usuarios ven un error "Failed to fetch"; al recargar ya funciona.

**P: ¿Y si el contenedor MySQL se cae?**
R: Lo mismo: Railway lo reinicia solo. **Los datos NO se pierden** porque viven en el `mysql-volume` (disco persistente que es independiente del contenedor). Cuando el contenedor nuevo arranca, monta el mismo volumen con todos los datos intactos. Tiempo típico: 20-30 segundos.

**P: ¿Cómo se entera Railway de que un servicio está caído?**
R: Por dos vías: (1) si el proceso del contenedor termina, Railway lo detecta al instante; (2) si el proceso está vivo pero no responde, Railway hace *health checks* HTTP periódicos. Si fallan repetidamente, mata y reinicia el contenedor.

**P: ¿Cuánto datos puedo perder en el peor caso?**
R: Como **máximo 24 horas** (RPO), porque ese es el intervalo entre snapshots automáticos del volumen MySQL. En la práctica, una caída no causa pérdida de datos: los datos confirmados con `COMMIT` están en el volumen persistente. Solo se perderían transacciones a medio escribir, y MySQL las descarta limpiamente al reiniciarse.

**P: ¿Tienes backups? ¿Cuán frecuentes?**
R: Sí, dos niveles: (1) **Snapshots automáticos diarios** del volumen MySQL gestionados por Railway (retención 7 días); (2) **Backups manuales con `mysqldump`** que hago antes de cambios sensibles y mensualmente como rutina, guardados en mi Drive personal.

**P: ¿Y si Railway entero se cae globalmente?**
R: Es muy raro (varios meses entre incidentes serios). Si pasa, esperar y comunicar. Si el incidente supera las 24h, ejecutar el Runbook 15.5.4 que describe la migración a otro PaaS (Render o Fly.io) en ~4 horas, gracias a que toda la configuración está parametrizada por variables de entorno.

**P: ¿Y si me roban el JWT secret?**
R: Rotación inmediata: generar nuevo secret con `openssl rand -base64 64`, actualizarlo en Railway, y ejecutar `DELETE FROM refresh_token` para invalidar todas las sesiones. Todos los usuarios tendrán que volver a hacer login pero el sistema queda seguro en 30 minutos.

**P: ¿Y si me roban la base de datos entera?**
R: Las contraseñas son hashes BCrypt cost 10, **prácticamente imposibles de revertir** (un ataque por fuerza bruta tomaría siglos). El daño real sería el de los datos personales (nombres, correos, teléfonos) que tendría que notificar a la AEPD por RGPD en menos de 72 horas.

**P: ¿Cómo te enteras tú de que está pasando algo malo?**
R: De varias formas: (1) usuarios que avisan por correo; (2) revisión periódica de las métricas de Railway (CPU/RAM/Network) — si veo picos raros, investigo; (3) Railway envía emails automáticos cuando un deploy falla; (4) en una v1.1 se añadiría monitorización con Sentry/Healthchecks.io que avisaría al instante.

**P: ¿Cuánto tardas en restaurar un backup?**
R: Con un `mysqldump` de ~5 MB (lo que ocupa nuestra BD actual), **5-10 minutos** de extremo a extremo: 1 min para activar el TCP Proxy, 2 min para restaurar el dump, 2 min para reiniciar el backend.

**P: ¿Qué pasa si tú (Kevin) no estás disponible durante una crisis?**
R: Es el riesgo P4 de la matriz. Mitigado parcialmente por: (1) el sistema se autorrecupera ante la mayoría de incidentes sin intervención; (2) esta guía permite que otra persona técnica resuelva incidencias siguiendo los runbooks; (3) las credenciales están en un gestor de contraseñas con acceso documentado para personas de confianza.

**P: ¿Qué hago si la app deja de responder de repente sin razón aparente?**
R: Seguir el Runbook 15.5.1 paso a paso: (1) verificar estado en Railway → (2) si está caído, ver logs → (3) si es bug reciente, hacer Redeploy del commit anterior → (4) restaurar versión "buena".

**P: ¿Y si Gmail bloquea la cuenta de correo?**
R: Runbook 15.5.5: generar nueva app password (suele bastar). Si Google bloquea la cuenta entera, crear una nueva o migrar a SendGrid/Brevo cambiando solo dos variables de entorno en Railway. **No requiere tocar código**.

**P: ¿Puedo cambiar de proveedor cloud si Railway sube precios?**
R: Sí, en ~4 horas. El código no depende de Railway en absoluto. Lo único que cambia entre proveedores es: (1) dónde se ponen las variables de entorno; (2) cómo se gestiona el volumen persistente; (3) la sintaxis de Dockerfile/Procfile que casi todos los PaaS aceptan tal cual.

**P: ¿Hay rate limiting o protección DDoS?**
R: A nivel de plataforma, Railway tiene **protección DDoS básica en su edge proxy**. A nivel de aplicación todavía no hay rate limiting (mejora pendiente para v1.1 con Bucket4j). Para producción real se pondría Cloudflare delante (gratis), que añade rate limiting + protección WAF + DDoS más robusta.

**P: ¿Qué pasa con las sesiones de usuario si reinicio el backend?**
R: Las sesiones **NO se pierden** porque son JWT *stateless*: el token vive en el cliente (Flutter), no en memoria del servidor. Al reiniciar, el backend vuelve a validar tokens existentes con la misma clave secreta y los acepta. Para el usuario es transparente: como mucho ve una petición que falla y se reintenta sola.

**P: ¿Y si la base de datos se queda sin espacio?**
R: Es el riesgo T9 (probabilidad baja porque cada cita ocupa ~1 KB y nuestro volumen tiene varios GB libres). Si pasara: borrar manualmente notificaciones antiguas (>1 año), o subir al plan Pro de Railway con más espacio. Migración transparente al usuario.

**P: ¿Cómo se hace un rollback a una versión anterior?**
R: Railway → servicio → pestaña **Deployments** → buscar el último deploy verde → menú **⋮** → **Redeploy**. En **3 minutos** el servicio anterior está activo otra vez. La BD no se toca durante el rollback (a menos que el commit malo incluyera migraciones de schema, que es un caso especial).

**P: ¿Cómo notificas a los usuarios cuando hay un incidente?**
R: Plantillas predefinidas en la sub-sección 15.7.1 (detección, en curso, restaurado, postmortem). Canales: correo masivo desde `peluqueria.victorinostyle@gmail.com`, banner en la app web, notificación push (si la BD sigue operativa). Para incidentes menores, simplemente respondemos al correo del usuario que avisa.

**P: ¿Has probado el plan alguna vez?**
R: Sí, los simulacros del apartado 15.6: he reiniciado manualmente el backend para medir tiempos de recuperación, he probado restaurar un backup en un proyecto de pruebas, y he validado que el redeploy de versiones anteriores funciona. Pendientes simulacros de rotación de secretos y de deploy roto (los haré antes de la defensa).

**P: ¿Y si pierdo todas mis cuentas (Google, GitHub, Railway) a la vez?**
R: Es el escenario peor. Mitigaciones: (1) 2FA con códigos de recuperación impresos guardados físicamente; (2) `mysqldump` reciente guardado en Drive personal Y en disco externo local; (3) repositorio clonado en local. Reconstruir el sistema desde cero llevaría ~1 día asumiendo que tengo el código y un dump fresco.

---

## 16. Preguntas frecuentes (FAQ para el tribunal)

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

## 17. Anexo A — Variables de entorno completas

Estas son las variables configuradas en Railway. **Los valores sensibles se enmascaran con `***` por seguridad**.

### 15.1. Servicio backend (Spring Boot)

| Variable | Valor (enmascarado) | Origen | Propósito |
|---|---|---|---|
| `PORT` | (lo inyecta Railway, normalmente 8080) | Railway | Puerto donde escucha Spring Boot |
| `SPRING_DATASOURCE_URL` | `jdbc:mysql://${{MySQL.MYSQLHOST}}:${{MySQL.MYSQLPORT}}/${{MySQL.MYSQLDATABASE}}?useSSL=false&serverTimezone=Europe/Madrid&allowPublicKeyRetrieval=true` | Referencia a MySQL | Conexión JDBC |
| `SPRING_DATASOURCE_USERNAME` | `${{MySQL.MYSQLUSER}}` | Referencia | Usuario MySQL |
| `SPRING_DATASOURCE_PASSWORD` | `${{MySQL.MYSQLPASSWORD}}` | Referencia | Contraseña MySQL |
| `VICTORINO_JWT_SECRET` | `Y2FtYmlh***` | Manual | Firma de JWT (HS256, mínimo 256 bits Base64) |
| `SPRING_MAIL_USERNAME` | `peluqueria.victorinostyle@gmail.com` | Manual | Cuenta Gmail emisora |
| `SPRING_MAIL_PASSWORD` | `***` | Manual | App password Gmail (16 chars) |
| `VICTORINO_ADMIN_PRUEBA_ACTIVO` | `true` | Manual | Crea admin al arrancar |
| `VICTORINO_ADMIN_PRUEBA_PASSWORD` | `Admin1234!` | Manual | Contraseña del admin demo |
| `VICTORINO_UPLOADS_DIRECTORIO` | `/app/uploads` | Manual | Ruta del volumen montado |
| `VICTORINO_CORS_ORIGENES_EXTRA` | `https://frontendvictorino-style-production.up.railway.app` | Manual | Orígenes CORS de producción. **Atención**: debe incluir el `https://`, ver Error 7. |
| `VICTORINO_FIREBASE_PROJECT_ID` | `victorino-style` | Manual | Project ID de Firebase |
| `VICTORINO_FIREBASE_CREDENTIALS_JSON` | `{"type":"service_account",...}` | Manual | JSON entero del service account |
| `NIXPACKS_JDK_VERSION` | `21` | Manual | Forzar JDK 21 en lugar del 17 por defecto |
| `JAVA_TOOL_OPTIONS` | `-Xmx400m -Xms256m -XX:+UseSerialGC -XX:MaxMetaspaceSize=128m` | Manual | Límite de RAM del JVM |

### 15.2. Servicio frontend (Flutter Web + nginx)

| Variable | Valor | Origen | Propósito |
|---|---|---|---|
| `PORT` | (lo inyecta Railway) | Railway | Puerto donde escucha nginx |
| `API_BASE_URL` | `https://victorinostyle-production.up.railway.app/api/v1` | Manual | URL del backend. **Se pasa como Build Arg** al Dockerfile (`ARG API_BASE_URL`) y queda horneada en el `main.dart.js` final via `--dart-define`. |

### 15.3. Servicio MySQL (autogeneradas por Railway)

Estas las pone Railway automáticamente al provisionar el plugin MySQL. **No las pongo yo manualmente**, las referencio desde el backend con `${{MySQL.X}}`.

| Variable | Visible | Para qué |
|---|---|---|
| `MYSQLHOST` | sí | Host interno: `mysql.railway.internal` |
| `MYSQLPORT` | sí | Puerto interno: `3306` |
| `MYSQLUSER` | sí | `root` |
| `MYSQLPASSWORD` | enmascarada | Contraseña aleatoria de 32+ chars |
| `MYSQLDATABASE` | sí | `railway` (nombre por defecto) |
| `MYSQL_URL` | enmascarada | URL completa con credenciales |
| `MYSQL_PUBLIC_URL` | enmascarada (solo si activé TCP Proxy) | URL externa, usada temporalmente para cargar `schema_railway.sql` y `seed_railway.sql` desde MySQL Workbench |
| `RAILWAY_TCP_PROXY_DOMAIN` | sí (solo con TCP Proxy) | Dominio público para Workbench |
| `RAILWAY_TCP_PROXY_PORT` | sí (solo con TCP Proxy) | Puerto público para Workbench |

---

## 18. Anexo B — Comandos útiles

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

## 19. Anexo C — Glosario de términos

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
