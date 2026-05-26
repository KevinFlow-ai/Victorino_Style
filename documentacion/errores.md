# Bitácora de errores — Victorino Style

> Cada incidente se registra aquí con: descripción, causa, solución, y código si aplica.
> Orden cronológico inverso: lo más reciente arriba.

---

## 2026-05-26 · Backend / Despliegue — Recuperación de contraseña no funcionaba en Railway (SMTP saliente bloqueado)

### Síntoma

En **local** el "olvidé mi contraseña" funcionaba perfecto: el usuario recibía el código de 6 dígitos en su correo, vía Gmail SMTP (`smtp.gmail.com:587` con la contraseña de aplicación de Google).

En **Railway**, el mismo flujo daba error 503 al cliente y este stacktrace en los logs:

```
ERROR o.v.exception.GlobalExceptionHandler : Error SMTP en /api/v1/auth/forgot-password:
Mail server connection failed. Failed messages:
org.eclipse.angus.mail.util.MailConnectException:
Couldn't connect to host, port: smtp.gmail.com, 587; timeout -1;
```

### Diagnóstico

El mensaje `Couldn't connect to host ... timeout -1` significa que **el socket TCP nunca llega a establecerse**: el paquete 
sale del contenedor pero no alcanza Gmail. No es un problema de credenciales (Gmail ni siquiera ve el intento), ni de bloqueo 
de cuenta, ni de la contraseña de aplicación.

Causa real: **Railway (y la mayoría de PaaS: Heroku, Render, Fly.io en plan gratuito) bloquean por defecto los puertos SMTP salientes (25, 465, 587)** 
para evitar que las apps desplegadas se usen como spammers. Solo se desbloquea pasando al plan **Pro** (≈20 USD/mes), lo cual no compensa para un TFG.

Es de Railway bloqueando el puerto SMTP saliente. Esto está documentado por Railway: SMTP saliente solo está disponible 
en el plan Pro (≈20 USD/mes); en Hobby/Trial está bloqueado.  
En local seguirás usando Gmail SMTP, en Railway 
usarás la API HTTP de Brevo (atraviesa el firewall sin problema).





#### Comprobación que hicimos

Antes de migrar, intentamos confirmar el diagnóstico forzando el puerto 465 con SSL directo. Se añadieron temporalmente estas variables en Railway:

| Variable | Valor |
|---|---|
| `SPRING_MAIL_PORT` | `465` |
| `SPRING_MAIL_PROPERTIES_MAIL_SMTP_SSL_ENABLE` | `true` |
| `SPRING_MAIL_PROPERTIES_MAIL_SMTP_STARTTLS_ENABLE` | `false` |

(Spring Boot mapea estas variables de entorno con `_` mayúsculas a las propiedades `.` minúsculas equivalentes en `application.properties`.)

Resultado: mismo error con puerto 465. **Confirmado** que Railway bloquea SMTP saliente. Tocaba cambiar de transporte.

### Solución adoptada: API HTTP de Brevo

En lugar de SMTP (que va por puerto TCP propietario y está bloqueado), usamos la **API transaccional HTTP de Brevo**, que viaja por HTTPS estándar (puerto 443) y por tanto sí sale del contenedor de Railway sin problema.

**Por qué Brevo y no otros:**

- 300 correos/día gratis (más que suficiente para una peluquería ficticia).
- **Servidores en la UE** → mejor argumento de RGPD ante el tribunal del TFG.
- Registro sin tarjeta de crédito.
- API simple: un único `POST /v3/smtp/email` con cabecera `api-key`.

Otras opciones consideradas: Resend (100/día gratis, servidores EEUU, requiere dominio propio verificado para producción) y Mailgun (gratis solo 3 meses).

### Arquitectura del envío de correo (post-cambio)

El backend decide en tiempo de arranque qué proveedor usar según la variable `victorino.mail.provider`:

- **`smtp`** (defecto): camino clásico con `JavaMailSender`. Se usa el SMTP de la BD si la peluquería lo tiene configurado (panel de admin), si no el de `application.properties` (Gmail con contraseña de aplicación). **Este es el camino activo en local.**
- **`brevo`**: se llama a la API HTTP de Brevo vía `BrevoEmailClient`. **Este es el camino activo en Railway.**

El cliente Flutter no se entera de nada — el endpoint `/auth/forgot-password` sigue siendo exactamente igual.

### Pasos en el panel de Brevo (registro y verificación)

1. **Registro** en [brevo.com](https://www.brevo.com) (sin tarjeta).
2. **Verificar el remitente** — sin esto la API rechaza los envíos con 400 "sender not allowed":
   - Menú izquierdo → **Remitentes, dominios y direcciones IP dedicadas → Remitentes**.
   - Botón **"Agregar remitente"**.
   - Nombre: `Victorino Style`. Email: `peluqueria.victorinostyle@gmail.com`.
   - Brevo envía un correo de verificación a esa dirección con un enlace; al pulsarlo, el remitente queda como **Verificado** (estado verde).
3. **Generar la API key v3** — **OJO con la pestaña**, hay dos tipos de clave y son distintas:
   - Menú izquierdo → **SMTP y API**.
   - Pestaña **"Claves API y MCP"** (NO la pestaña "SMTP", ver sección de "Tropiezos" más abajo).
   - **"+ Generar una nueva clave API"** → nombre `victorino_style_api_v3` → crear.
   - **Copiar el valor entero** que aparece (empieza por `xkeysib-...`, ~80-90 caracteres). Solo se ve una vez.

### Variables de entorno nuevas en Railway

Tres variables nuevas (y se eliminan las temporales del intento de puerto 465):

| Variable | Valor | Propósito |
|---|---|---|
| `VICTORINO_MAIL_PROVIDER` | `brevo` | Activa el camino HTTP en lugar del SMTP |
| `VICTORINO_MAIL_BREVO_API_KEY` | `xkeysib-...` (la generada en el paso 3) | Autenticación contra la API de Brevo |
| `VICTORINO_MAIL_BREVO_FROM_EMAIL` | `peluqueria.victorinostyle@gmail.com` | Remitente. **Tiene que coincidir con el verificado en Brevo.** |

Opcionalmente `VICTORINO_MAIL_BREVO_FROM_NAME` (por defecto `Victorino Style`).

En **local NO se define ninguna** de estas — el defecto `smtp` arranca y se sigue usando Gmail.

### Archivos modificados / creados

**Nuevo** — `Backend_Victorino/src/main/java/org/victorino_style/service/BrevoEmailClient.java`

Componente Spring (`@Component`) que encapsula la llamada HTTP a Brevo:

- Construye un `RestClient` (dependencia `spring-boot-starter-restclient` ya estaba en el `pom.xml`).
- Hace `POST https://api.brevo.com/v3/smtp/email` con cabecera `api-key: <KEY>` y cuerpo JSON:
  ```json
  {
    "sender":  { "name": "Victorino Style", "email": "peluqueria.victorinostyle@gmail.com" },
    "to":      [ { "email": "destinatario@dominio.com" } ],
    "subject": "Recuperación de contraseña - Victorino Style",
    "textContent": "...código..."
  }
  ```
- Cualquier respuesta 4xx/5xx o error de red se convierte en `org.springframework.mail.MailSendException` para que el `GlobalExceptionHandler` global devuelva 503 igual que con el camino SMTP. El `RestController` no necesita saber qué proveedor está activo.
- Valida que `api-key` y `from-email` no estén vacíos en arranque; si falta alguno lanza `MailSendException` con un mensaje claro.

**Modificado** — `Backend_Victorino/src/main/java/org/victorino_style/service/MailService.java`

- Inyecta `BrevoEmailClient` (además del `JavaMailSender` y el `PeluqueriaRepository` que ya tenía).
- Nueva propiedad inyectada: `@Value("${victorino.mail.provider:smtp}") private String provider`.
- Se extrae el armado de mensaje (`asunto`, `cuerpo`) a un método privado `enviar(destinatario, asunto, cuerpo)` que enruta:
  - Si `provider="brevo"` → `brevoEmailClient.enviarTexto(...)`.
  - Si no → camino SMTP de siempre (incluye fallback BD → `application.properties`).
- Los métodos públicos `enviarCodigoRecuperacion` y `enviarCorreoPrueba` mantienen la misma firma (no hay que tocar nada en el `PasswordRecoveryController`).

**Modificado** — `Backend_Victorino/src/main/resources/application.properties`

Bloque nuevo añadido después de la configuración SMTP existente:

```properties
# Proveedor de envio: "smtp" (defecto, local) o "brevo" (API HTTP).
victorino.mail.provider=${VICTORINO_MAIL_PROVIDER:smtp}
victorino.mail.brevo.api-key=${VICTORINO_MAIL_BREVO_API_KEY:}
victorino.mail.brevo.from-email=${VICTORINO_MAIL_BREVO_FROM_EMAIL:}
victorino.mail.brevo.from-name=${VICTORINO_MAIL_BREVO_FROM_NAME:Victorino Style}
```

Todas leen variable de entorno con valor por defecto vacío excepto el `provider` (defecto `smtp`) y el `from-name` (defecto `Victorino Style`).

### Tropiezo intermedio: clave SMTP vs clave API v3

La primera prueba en Railway falló con:

```
ERROR o.v.service.BrevoEmailClient : Brevo HTTP 401 UNAUTHORIZED ->
  {"message":"Key not found","code":"unauthorized"}
```

**Causa**: en Brevo, dentro de **SMTP y API** hay **dos pestañas** con dos tipos de claves distintos:

| Pestaña | Formato | Para qué sirve |
|---|---|---|
| **SMTP** | `xsmtpsib-...` | Autenticarse en `smtp-relay.brevo.com:587` (SMTP relay) |
| **Claves API y MCP** | `xkeysib-` + 64 chars | API HTTP v3 (lo que usa nuestro `BrevoEmailClient`) |

Habíamos generado la primera (SMTP) por error. La API HTTP v3 no la reconoce — devuelve 401 "Key not found". Generando la correcta (pestaña "Claves API y MCP") y actualizando `VICTORINO_MAIL_BREVO_API_KEY` en Railway, el envío funcionó.

La clave SMTP de Brevo se **borró** después (nadie la usa en el código y reduce superficie de ataque).

### Cómo funciona ahora extremo a extremo

#### En local (desarrollo)

```
Cliente Flutter
    → POST /api/v1/auth/forgot-password { correo }
        → PasswordRecoveryController
            → PasswordRecoveryService.crearCodigoRecuperacion()   [genera 6 dígitos en BD]
            → MailService.enviarCodigoRecuperacion()
                → provider="smtp" (defecto)
                → resolverSender() lee BD → si no hay SMTP en BD, usa application.properties
                → JavaMailSender.send() → smtp.gmail.com:587 con contraseña de aplicación
```

Funciona porque la red local no bloquea el 587.

#### En Railway (producción)

```
Cliente Flutter
    → POST /api/v1/auth/forgot-password { correo }
        → PasswordRecoveryController
            → PasswordRecoveryService.crearCodigoRecuperacion()   [genera 6 dígitos en BD]
            → MailService.enviarCodigoRecuperacion()
                → provider="brevo" (variable de entorno)
                → BrevoEmailClient.enviarTexto()
                → RestClient POST https://api.brevo.com/v3/smtp/email   (HTTPS:443, no bloqueado)
                → Brevo entrega el correo al destinatario
```

### Verificación final

Log de éxito en Railway tras la corrección:

```
INFO o.v.service.PasswordRecoveryService : Código de recuperación generado para usuario id=67
INFO o.v.service.BrevoEmailClient        : Brevo OK (201) destinatario=... from=peluqueria.victorinostyle@gmail.com
```

El correo llega al inbox del usuario con el código de 6 dígitos. El usuario lo introduce, `/auth/verify-otp` lo valida, `/auth/reset-password` cambia la contraseña. Flujo completo verificado.

### Lecciones / cosas a recordar

1. **PaaS gratuitos bloquean SMTP saliente**. Para producción, siempre planificar usar una API HTTP (Brevo, Resend, Mailgun, SendGrid…) en lugar de SMTP directo. SMTP solo es viable en local o en VPS propios.
2. **No mantener dos vías** activas en producción: el `victorino.mail.provider` es un único conmutador y eso simplifica el debugging — si algo va mal, el log dice exactamente qué camino se tomó.
3. **El controlador no debe saber qué proveedor está activo**. Toda la lógica de enrutamiento vive en `MailService`. El `PasswordRecoveryController` no cambió ni una línea.
4. **Las claves de Brevo son dos**, no una. Si aparece 401 "Key not found" → estás usando la SMTP donde toca la v3 (o al revés).
5. **NUNCA pegar claves en `application.properties` ni siquiera como comentario** — el fichero está en git. Las claves solo en variables de entorno (Railway o `.env` local listado en `.gitignore`).

### Costes

Cero. Plan gratuito de Brevo (300 correos/día) es más que suficiente para el volumen de un TFG con una sola peluquería ficticia.

---

## 2026-05-19 · Frontend Empleado — La franja gris del descanso no aparecía en la agenda del empleado

**Síntoma**: en la agenda del **administrador** se ve perfectamente la franja gris del descanso de cada empleado, pero 
en la agenda del **empleado** (su propia agenda) esa franja no se pinta. La lógica del backend impide 
reservar en ese rango (si pides una cita en la hora del descanso devuelve 409), así que 
era **solo un problema visual**: el empleado no ve marcado su descanso aunque exista.

Encontré el bug. En agenda_empleado_screen.dart:226-237 se construye un Empleado "manualmente" a partir 
de la sesión, pasando horaDescanso: null y duracionDescansoMinutos: null. Por eso _FranjaDescanso nunca se 
pinta en la agenda del empleado (en admin sí porque viene del provider real con datos completos).

Diagnóstico confirmado. El bug está en agenda_empleado_screen.dart:226-237:
final empleado = Empleado(
  ...
  horaDescanso: null,          // ← nunca se rellena
  duracionDescansoMinutos: null,  // ← nunca se rellena
);

_FranjaDescanso solo pinta si esos dos campos no son null. En admin sí se ven porque vienen 
del provider empleadosAdminNotifierProvider (usa GET /admin/empleados, que es de admin). Mirando los DTOs:

SesionUsuario no guarda nada del descanso.
EmpleadoPublicoResponse (GET /empleados) solo expone id, nombre, apellidos y foto.
EmpleadoAdminResponse (GET /admin/empleados) sí tiene descanso, pero ese endpoint es solo admin.
Es decir, hoy no hay forma de que el empleado obtenga su propio descanso desde el backend.

¿Cómo prefieres que el empleado obtenga su descanso?
Endpoint nuevo GET /empleados/

Una nota antes de implementar: investigando vi que ya existe GET /empleado/perfil (PerfilEmpleadoController.java) que 
devuelve PerfilEmpleadoResponse del empleado autenticado. Solo le falta horaDescanso y duracionDescansoMinutos. El proyecto sigue el patrón:
empleados/... (plural) → catálogo público
/empleado/... (singular) → gestión propia del empleado autenticado
Crear GET /empleados/me añadiría un endpoint nuevo que pisa esa convención. Lo más limpio sería añadir los 2 campos al 
PerfilEmpleadoResponse existente y usar el endpoint ya creado.

Resumen del fix (7 archivos):

Backend — el endpoint GET /empleado/perfil ahora devuelve el descanso:

PerfilEmpleadoResponse.java: añadidos campos horaDescanso y duracionDescansoMinutos.
EmpleadoMapper.java:55: aPerfilRespuesta consulta el horario del empleado y rellena ambos campos.actualizar EmpleadoMapper.aPerfilRespuesta 
para incluir los datos del descanso:

Frontend — la agenda del empleado consume el descanso real:

api_endpoints.dart:46: constante empleadoPerfil. añadir endpoint en api_endpoints.dart:
perfil_empleado_repositorio.dart: método nuevo obtenerDescanso() en la interfaz. añadir método a la interfaz del repo:
perfil_empleado_repositorio_impl.dart: implementación que llama a GET /empleado/perfil y mapea solo los dos campos.  implementar el método en el repo HTTP:
perfil_empleado_providers.dart: descansoEmpleadoProvider (FutureProvider). provider Riverpod para el descans
agenda_empleado_screen.dart:230: ref.watch(descansoEmpleadoProvider) y se pasan los datos reales al Empleado (en vez de los null que había). usar el provider en la agenda del empleado:

Notas:
Mientras el provider carga (o si falla la petición) los campos quedan null y el comportamiento es el mismo que antes (no se pinta la franja). La lógica del backend ya impide reservar en el descanso, así que esto era solo visual como dijiste.
---

### Qué pasaba (explicado fácil)

El widget que pinta la columna de un empleado en la agenda (`_ColumnaEmpleado`) es compartido entre 
admin y empleado. Para decidir si pinta la franja gris del descanso mira dos campos del objeto `Empleado` 
que recibe: `horaDescanso` y `duracionDescansoMinutos`. Si los dos vienen rellenos, pinta la franja; 
si vienen a `null`, no pinta nada.

En la pantalla del **admin**, los empleados se obtienen del servidor con todos sus datos (la lista del panel de empleados), 
así que esos campos siempre llegan rellenos. En la pantalla del **empleado**, en cambio, no había forma 
de pedir al servidor "dame mi propio descanso" — el único endpoint público de empleados (`GET /empleados`) 
devuelve solo foto + nombre, y el endpoint admin (`GET /admin/empleados`) sí los devuelve pero está restringido a admin.

La consecuencia: la pantalla del empleado construía un objeto `Empleado` "a mano" a partir de los datos
de la sesión (nombre, foto, id…) y rellenaba a fuerza `horaDescanso: null` y `duracionDescansoMinutos: null`. 
Por eso la franja gris nunca aparecía.

---

### Causa técnica

En `agenda_empleado_screen.dart`, dentro de `_CuerpoAgenda.build()`, el `Empleado` que se pasa a `AgendaGrid` se construía así:

```dart
final empleado = Empleado(
  id: sesion.idUsuario,
  nombre: nombre,
  apellidos: apellidos,
  correo: '',
  telefono: '',
  fotoUrl: sesion.foto ?? '',
  activo: true,
  esAdministrador: false,
  horaDescanso: null,            // ⚠️ nunca se rellenaba
  duracionDescansoMinutos: null, // ⚠️ nunca se rellenaba
);
```

Y `_FranjaDescanso` solo se renderiza si la función `franjaDescansoDelDia(...)` devuelve algo, lo cual exige que 
ambos campos no sean `null`. Por eso en admin sí salía (los empleados venían del `empleadosAdminNotifierProvider` con datos completos) y en empleado no.

Además, mirando los DTOs del backend:
- `EmpleadoPublicoResponse` (de `GET /empleados`): solo id, nombre, apellidos, fotoUrl. No expone descanso.
- `EmpleadoAdminResponse` (de `GET /admin/empleados`): sí expone descanso, pero el endpoint requiere rol ADMINISTRADOR.
- `PerfilEmpleadoResponse` (de `GET /empleado/perfil`, accesible al empleado autenticado): tampoco incluía descanso.

Es decir, **el empleado no tenía ningún endpoint que le devolviera su propio descanso**.

---

### Solución

Aprovechar el endpoint que ya existía para el empleado autenticado (`GET /empleado/perfil`) y ampliarlo para 
que devuelva también los datos del descanso. En el frontend, crear un provider que lo consuma y rellenar el `Empleado` 
con los datos reales en lugar de pasar `null`.

**Backend (2 archivos)**:

`PerfilEmpleadoResponse.java` — añadir dos campos al record:
```java
// ✅ Después
public record PerfilEmpleadoResponse(
        Long idEmpleado,
        String nombre,
        String apellidos,
        String correo,
        String fotoUrl,
        RolUsuario rol,
        LocalTime silencioInicio,
        LocalTime silencioFin,
        boolean noMolestar,
        String horaDescanso,              // ← NUEVO
        Integer duracionDescansoMinutos   // ← NUEVO
) {}
```

`EmpleadoMapper.aPerfilRespuesta(...)` — consultar el horario del empleado y rellenar los nuevos campos (mismo patrón que ya usaba `aRespuesta` para el panel admin):
```java
HorarioEmpleado horario = horarioEmpleadoRepository
        .findByIdEmpleado_Id(empleado.getId())
        .orElse(null);

String horaDescanso = null;
Integer duracionDescansoMinutos = null;
if (horario != null && horario.getDescansoInicioHorario() != null) {
    String horaStr = horario.getDescansoInicioHorario().toString();
    horaDescanso = horaStr.length() >= 5 ? horaStr.substring(0, 5) : horaStr;
    duracionDescansoMinutos = horario.getDescansoDuracionHorario();
}
```

**Frontend (5 archivos)**:

1. `api_endpoints.dart` — nueva constante:
   ```dart
   static const empleadoPerfil = '/empleado/perfil';
   ```

2. `perfil_empleado_repositorio.dart` (interfaz) — método nuevo:
   ```dart
   Future<({String? horaDescanso, int? duracionDescansoMinutos})> obtenerDescanso();
   ```

3. `perfil_empleado_repositorio_impl.dart` — implementación: GET al endpoint y mapea solo los dos campos del descanso.

4. `perfil_empleado_providers.dart` — `FutureProvider` nuevo:
   ```dart
   final descansoEmpleadoProvider =
       FutureProvider<({String? horaDescanso, int? duracionDescansoMinutos})>(
           (ref) async { ... });
   ```

5. `agenda_empleado_screen.dart` — consumir el provider:
   ```dart
   // ❌ Antes
   final empleado = Empleado(
     ...
     horaDescanso: null,
     duracionDescansoMinutos: null,
   );

   // ✅ Después
   final descanso = ref.watch(descansoEmpleadoProvider).value;
   final empleado = Empleado(
     ...
     horaDescanso: descanso?.horaDescanso,
     duracionDescansoMinutos: descanso?.duracionDescansoMinutos,
   );
   ```

Mientras el provider carga (o si la petición falla) los campos quedan `null` y la franja simplemente 
no se pinta — comportamiento idéntico al de antes, sin pantalla roja.

---

### Consejo para evitar este patrón

- Cuando un widget de dominio (como `Empleado`) tiene campos opcionales que afectan al renderizado (descanso, foto, flags), 
**no construyas el objeto "a mano" rellenándolos con `null`** si esa información sí existe en el backend. Es preferible: 
o reutilizar el DTO completo del servidor, o crear un endpoint específico que devuelva justo lo necesario.
- Si tu app tiene una pantalla compartida entre roles (admin/empleado) que muestra los mismos datos, asegúrate de que 
**ambos roles tienen un endpoint** que les devuelve la misma información. No basta con que el admin tenga acceso "completo" y 
el empleado se construya un objeto a medias: la pantalla se ve incompleta.
- Antes de añadir un endpoint nuevo, comprueba si **ya existe uno parecido** (en este caso, `GET /empleado/perfil` ya existía y 
faltaban dos campos). Ampliar un DTO existente suele ser preferible a duplicar endpoints.
- Importante: tras tocar el DTO hay que **reiniciar el backend** (no es hot-reloadable). Lo mismo con el frontend si Riverpod cachea el provider.

---

## 2026-05-19 · Frontend Empleado — El SnackBar de errores queda tapado por el bottom sheet al crear una cita walk-in

**Síntoma**: al crear una cita walk-in desde la agenda del **empleado** (pulsando el "+" de un hueco libre), cuando saltaba un 
error de validación — "no puedes reservar una hora que ya ha pasado", "esa hora cae fuera del hueco libre", "hueco ocupado" 
(409 del backend), "fuera de horario", etc. — el SnackBar **sí se disparaba**, pero quedaba renderizado **por detrás del bottom sheet** y 
el usuario no lo veía. En la agenda del **administrador** se veía a medias porque el sheet del admin era más bajo y 
dejaba un trocito de pantalla libre por abajo donde el SnackBar asomaba.

---

### Qué pasaba (explicado fácil)

Cuando llamas a `ScaffoldMessenger.of(context).showSnackBar(...)` desde dentro de un `showModalBottomSheet`, Flutter 
busca el `ScaffoldMessenger` más cercano hacia arriba en el árbol de widgets. Encuentra el del `Scaffold` **raíz** (el 
de la pantalla padre), no uno propio del bottom sheet — porque el bottom sheet no tiene `Scaffold` propio. Así que el 
SnackBar se pinta sobre el `Scaffold` raíz, en la parte inferior de la **pantalla**. Pero el bottom sheet, que está 
dibujado encima del Scaffold raíz, **lo tapa visualmente**.

En la agenda del admin el sheet era más bajo, dejaba 100-200 px libres abajo y el usuario llegaba a ver el SnackBar a 
duras penas. En la del empleado el sheet ocupaba más alto y lo escondía del todo.

---

### Causa técnica

El widget `BottomSheetCrearCitaRapida` (compartido entre admin y empleado) usaba `ScaffoldMessenger.of(context).showSnackBar(...)` 
en 4 puntos para mostrar errores de validación al usuario. Como el árbol de widgets dentro del modal era:

```
showModalBottomSheet
  └── Padding > SafeArea > SingleChildScrollView > Form > Column > ...
```

…no había ningún `Scaffold` o `ScaffoldMessenger` propio en el sheet, así que los SnackBars subían al messenger raíz y se renderizaban detrás del modal.

**Por qué no se puede arreglar simplemente "envolviendo el body en `Scaffold`"**: un `Scaffold` siempre intenta ocupar `double.infinity` 
en alto. Si el `showModalBottomSheet` se invoca con `isScrollControlled: true` (como aquí), el sheet se auto-dimensiona al alto de su hijo, 
con un `Column(mainAxisSize: MainAxisSize.min)`. Si ese hijo es un `Scaffold`, el sheet se expandiría a pantalla completa y rompería la UX.

---

### Solución

Implementar un "aviso in-sheet" propio: un widget posicionado en la parte inferior del propio bottom sheet, con 
el mismo look que un SnackBar estándar (gris oscuro `#323232`, texto blanco, 4 s), gestionado por estado local en el `State`.

**Patrón aplicado** en `bottom_sheet_crear_cita_rapida.dart`:

```dart
// Estado del aviso
String? _aviso;
Color _avisoColor = const Color(0xFF323232);
Timer? _timerAviso;

void _mostrarAviso(String texto, {Color? color}) {
  _timerAviso?.cancel();
  setState(() {
    _aviso = texto;
    _avisoColor = color ?? const Color(0xFF323232);
  });
  _timerAviso = Timer(const Duration(seconds: 4), () {
    if (!mounted) return;
    setState(() => _aviso = null);
  });
}

@override
void dispose() {
  _timerAviso?.cancel();
  ...
  super.dispose();
}
```

Y el árbol del `build()` pasa de:

```dart
// ❌ Antes
Padding > SafeArea > SingleChildScrollView > Form > Column
```

…a:

```dart
// ✅ Después
Padding > SafeArea > Stack > [
  SingleChildScrollView > Form > Column,
  if (_aviso != null) Positioned(
    left: 12, right: 12, bottom: 12,
    child: Material(
      elevation: 6,
      color: _avisoColor,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Text(_aviso!, style: const TextStyle(color: Colors.white, fontSize: 14)),
      ),
    ),
  ),
]
```

Y las 4 llamadas de error/validación se cambian:

```dart
// ❌ Antes
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text('No puedes reservar una hora que ya ha pasado.')),
);

// ✅ Después
_mostrarAviso('No puedes reservar una hora que ya ha pasado.');
```

El SnackBar de **éxito** se deja como estaba: como el sheet hace `pop(true)` inmediatamente después, no hay modal que lo tape y se renderiza correctamente en la pantalla padre (admin o empleado).

**Archivo modificado**: `frontend_victorino/lib/features/administrador/agenda/presentation/widgets/agenda_grid/bottom_sheet_crear_cita_rapida.dart`.

Como el widget es compartido entre admin y empleado, el arreglo se aplica a los dos roles sin tocar nada más.

---

### Consejo para evitar este patrón

- **`ScaffoldMessenger.of(context)` dentro de un `showModalBottomSheet` siempre sube al messenger raíz**, no al del sheet. Resultado: el SnackBar queda renderizado detrás del modal. Aplicable también a `showDialog` y a cualquier overlay que tape la parte inferior de la pantalla.
- Posibles soluciones (de menos a más invasiva):
  1. **Asumir el comportamiento** y cerrar el modal antes de mostrar el SnackBar (sirve para mensajes de éxito, no para errores que dejan el modal abierto para corregir).
  2. **Aviso in-sheet custom con `Stack` + `Positioned`** (el patrón usado aquí). Ventaja: no rompe el auto-sizing del bottom sheet.
  3. Envolver el body en `Scaffold` + `ScaffoldMessenger` locales. Solo viable si el bottom sheet ocupa pantalla completa fija — rompe el auto-sizing si el sheet se quiere ajustar al contenido.
- **Regla práctica**: cuando un widget vive dentro de un `showModalBottomSheet` con `isScrollControlled: true` y necesita mostrar avisos al usuario sin cerrar el modal, no uses `ScaffoldMessenger`. Implementa un aviso propio con `Stack`.

---

## 2026-05-17 · Frontend Cliente — "No se pudieron cargar las notificaciones" al volver a la pestaña (segundo error)

**Síntoma**: incluso después de aplicar el fix del `.select()`, al cambiar de pestaña y volver a la bandeja de notificaciones aparecía el mensaje 
"No se pudieron cargar las notificaciones". La única forma de recuperarlas era hacer pull-to-refresh manualmente.

---

### Qué pasaba (explicado fácil)

Imagina que tienes a un empleado que trabaja con dos herramientas: una bolsa para recoger notificaciones del servidor, y un 
bolígrafo para marcarlas como leídas. El empleado las guarda en su bolsillo cuando empieza a trabajar por primera vez.

En el código, esas "herramientas" se marcaban como `late final`: eso significa "te las doy la primera vez y **nunca las cambies**". El problema es que Riverpod, 
en algunas situaciones (como cambiar de pestaña y volver), llama a `build()` — que es el "arranque" del empleado — más de una vez 
**sobre el mismo empleado**, sin crear uno nuevo. La segunda vez que el 
empleado intentaba guardar las herramientas en su bolsillo, Dart decía: "¡Oye, ya 
tienes algo ahí y dijiste que era definitivo!". Lanzaba un error interno y la pantalla quedaba en estado de fallo.

Lo más confuso del asunto: `recargar()` (el pull-to-refresh) sí funcionaba, porque ese método usaba 
las herramientas directamente **sin intentar reasignarlas**. El error solo ocurría al entrar a `build()` una segunda vez.

---

### Causa técnica

`NotificacionesNotifier` declaraba sus dependencias con `late final`:

```dart
// ❌ late final: solo se puede asignar una vez por instancia de la clase.
late final ObtenerBandeja _obtenerBandeja;
late final MarcarLeida _marcarLeida;

@override
Future<List<Notificacion>> build() async {
  _obtenerBandeja = ref.read(obtenerBandejaProvider);  // OK en la 1ª llamada
  _marcarLeida = ref.read(marcarLeidaProvider);         // OK en la 1ª llamada
  ...
}
```

Riverpod 3.x puede invocar `build()` varias veces sobre **la misma instancia** del notifier (por ejemplo, cuando la dependencia 
observada con `.select()` cambia pero el notifier no se descarta). En la segunda llamada a `build()`, Dart lanzaba `LateInitializationError` 
al intentar reasignar un `late final`, y Riverpod capturaba esa excepción convirtiéndola en `AsyncError` — de ahí el mensaje de error en pantalla.

El pull-to-refresh **no fallaba** porque `recargar()` usaba `_obtenerBandeja` ya asignado (en la primera llamada a `build()`), sin 
reasignarlo. Pero en la llamada a `build()` la segunda vuelta, el intento de asignación explotaba.

---

### Solución

Cambiar `late final` por campos nullable ordinarios que se pueden reasignar sin restricciones:

```dart
// ✅ Nullable sin late final: se puede reasignar en cada llamada a build().
ObtenerBandeja? _obtenerBandeja;
MarcarLeida? _marcarLeida;

@override
Future<List<Notificacion>> build() async {
  _obtenerBandeja = ref.read(obtenerBandejaProvider);  // siempre seguro
  _marcarLeida = ref.read(marcarLeidaProvider);         // siempre seguro
  ...
  return _obtenerBandeja!.ejecutar();
}
```

El `!` (null assertion) es seguro porque los campos se asignan siempre antes de usarlos dentro del mismo `build()`.

**Archivo modificado**: `frontend_victorino/lib/features/notificaciones/application/notificaciones_notifier.dart`

---

### Consejo para evitar este patrón

- **Nunca uses `late final` para campos que se inicializan dentro de `build()`** en un `AsyncNotifier` o `Notifier`. `build()` puede llamarse más de una vez en la vida de la misma instancia.
- Usa `late final` solo para campos que se asignan **una única vez** fuera de `build()` (por ejemplo, en el constructor o en `initState` si fuera un `StatefulWidget`).
- Como regla general: si un campo lo inicializas DENTRO de `build()`, decláralo sin `final` (o como nullable `T?`).

---

## 2026-05-17 · Frontend Cliente — Notificaciones (y otros datos) desaparecen al cambiar de pestaña

**Síntoma**: las notificaciones, la próxima cita del Home y el historial de citas desaparecen y quedan vacíos cada vez que 
el usuario cambia de pestaña (por ejemplo, de Inicio a Perfil y vuelta). La única forma de recuperar los datos es hacer **pull-to-refresh** manualmente.

---

### Qué hace la aplicación por dentro (explicado fácil)

Imagina que la app tiene empleados que se encargan de ir a buscar información al servidor. Cada empleado solo trabaja 
cuando alguien le avisa de que algo ha cambiado. El aviso llega a través de un tablón de anuncios llamado **sesión**:

- Cuando el usuario inicia sesión, se pone en el tablón: "Hay un usuario activo: María".
- Cuando cierra sesión, se pone: "No hay nadie".

Los empleados de Notificaciones, Historial y Próxima Cita estaban mirando **todo lo que ponía en el tablón**: el 
nombre del usuario, su rol… y también su **código de seguridad temporal** (el token de acceso). Ese código caduca y 
se renueva automáticamente cada vez que se hace alguna consulta al servidor.

El problema: **cada vez que el código se renovaba** (lo que ocurre al cambiar de pestaña, porque la nueva pestaña hace una consulta), 
el tablón cambiaba. Los empleados lo veían, creían que había una novedad importante y **volvían a empezar su trabajo desde cero**: tiraban 
los datos que ya tenían cargados y salían a buscarlos de nuevo al servidor. Mientras regresaban (eso tarda un segundo), la pantalla aparecía vacía.

---

### Causa técnica

`NotificacionesNotifier`, `PerfilNotifier`, `HistorialNotifier` y `ProximaCitaNotifier` hacían `ref.watch(sesionProvider)` completo. El `sesionProvider` cambia no solo cuando el usuario hace login/logout, sino también cada vez que el interceptor Dio renueva el **access token** (llamada a `actualizarAccessToken()`). Esa llamada ocurre automáticamente al detectar un token caducado, que puede pasar en cualquier cambio de pestaña que dispare una petición HTTP.

Resultado: cada renovación de token → sesionProvider cambia → los cuatro notifiers se reconstruyen → estado pasa a `AsyncLoading` → datos desaparecen → petición HTTP en curso → datos vuelven.

---

### Solución

Usar **`sesionProvider.select()`** en lugar de observar el sesionProvider completo. Así cada notifier solo reacciona cuando cambia el **identificador del usuario** (`idUsuario`), que es lo único que importa para saber si hay que recargar datos. Si solo cambia el token pero el usuario sigue siendo el mismo, los notifiers no se molestan.

**Archivos modificados**:
- `frontend_victorino/lib/features/notificaciones/application/notificaciones_notifier.dart`
- `frontend_victorino/lib/features/cliente/perfil/application/perfil_providers.dart`
- `frontend_victorino/lib/features/cliente/historial/application/historial_providers.dart`
- `frontend_victorino/lib/features/cliente/home/application/home_providers.dart`

**Diff** (el mismo patrón en los cuatro):
```dart
// ❌ Antes — observa TODO el sesionProvider, incluyendo el token.
// Se reconstruye en cada renovación de token → datos desaparecen.
final sesion = ref.watch(sesionProvider).value;
if (sesion == null) return const [];

// ✅ Después — observa SOLO el idUsuario.
// Solo se reconstruye cuando cambia el usuario (login/logout), no el token.
final idUsuario = ref.watch(
  sesionProvider.select((s) => s.value?.idUsuario),
);
if (idUsuario == null) return const [];
```

---

### Consejo para evitar este patrón

- Cuando un provider necesita "saber quién es el usuario para cargar sus datos", no debe observar el objeto de sesión entero. Debe usar **`.select()`** para observar solo el campo que determina la identidad del usuario (`idUsuario`).
- El access token es un detalle de infraestructura, no de identidad. Los interceptores ya lo gestionan solos. Los providers de datos no tienen por qué enterarse de sus renovaciones.
- **Regla de oro**: `ref.watch(sesionProvider.select((s) => s.value?.idUsuario))` en lugar de `ref.watch(sesionProvider).value` en cualquier notifier que cargue datos específicos de un usuario.

---

## 2026-05-17 · Frontend Cliente — Historial y próxima cita no se actualizaban al cambiar de cuenta

**Síntoma**: al cerrar sesión con el clienteA e iniciar sesión con el clienteB, las pantallas de **Historial de citas** y la **tarjeta de próxima cita** 
del Home seguían mostrando los datos del clienteA. Había que hacer pull-to-refresh en cada pantalla para que aparecieran los datos correctos.

---

### Qué pasaba (explicado fácil)

Imagina que tienes dos cajones: uno para los datos de María (clienteA) y otro para los de Carlos (clienteB). Cuando María 
cierra sesión, la app debería vaciar su cajón. Cuando Carlos inicia sesión, debería abrir el suyo y llenarlo con sus datos.

El problema: los "empleados" encargados del Historial y la Próxima Cita **no estaban mirando el tablón de anuncios de sesión**. Nadie les 
avisaba de que había cambiado el usuario. Seguían mostrando el cajón de María aunque ya estuviera Carlos.

Los otros dos (Perfil y Notificaciones) sí estaban mirando el tablón, por eso sí se actualizaban solos. Pero Historial y Próxima Cita no.

---

### Causa técnica

`HistorialNotifier.build()` y `ProximaCitaNotifier.build()` no incluían ningún `ref.watch(sesionProvider)`. Riverpod 
no tenía forma de saber que estos providers dependían de la sesión, por lo que nunca les notificaba del cambio 
de usuario. Sus datos se quedaban congelados con los del usuario anterior.

---

### Solución

Añadir el guard de sesión en el `build()` de ambos notifiers, exactamente igual que ya tenían `PerfilNotifier` y `NotificacionesNotifier`:

```dart
// ✅ Añadido en HistorialNotifier.build() y ProximaCitaNotifier.build()
final idUsuario = ref.watch(sesionProvider.select((s) => s.value?.idUsuario));
if (idUsuario == null) return const []; // o null según el provider
```

Ahora Riverpod sabe que estos providers dependen de quién es el usuario activo y los reconstruye automáticamente al hacer login/logout.

**Archivos modificados**:
- `frontend_victorino/lib/features/cliente/historial/application/historial_providers.dart`
- `frontend_victorino/lib/features/cliente/home/application/home_providers.dart`

---

## 2026-05-16 · Frontend Cliente — "Mi perfil, sin perfil cargado" al cerrar sesión

> 📸 **Captura asociada**: `cliente_error_cerrar_cesion`

**Síntoma**: cuando el cliente está en la pestaña "Perfil" y pulsa el botón **"Cerrar sesión"**, durante un instante (~medio segundo) la pantalla muestra el mensaje:
```
Mi perfil
Sin perfil cargado
```
…en lugar de llevarle DIRECTAMENTE al login como sí pasa con el admin. Es un parpadeo desagradable que da sensación de bug.

---

### Qué hace este botón (explicado fácil)

Imagina la sesión como una "pulsera" que llevas puesta cuando entras a la peluquería: lleva tu nombre, tu rol (cliente/empleado/admin) y un código secreto (el token). Mientras la lleves, las pantallas saben quién eres y te enseñan tus datos.

Cuando le das a "Cerrar sesión":
1. La aplicación se **quita la pulsera** (borra los tokens, avisa al servidor).
2. Como ya no llevas pulsera, la pantalla de perfil ya no sabe quién eres → muestra "Sin perfil cargado".
3. **Luego** la aplicación te lleva al login.

El problema es ese **"luego"** del paso 3: el paso 2 ocurre ANTES y, durante un instante, ves la pantalla fea de "Sin perfil".

---

### Por qué pasaba (más técnico, en cristiano)

La pantalla del perfil estaba "**escuchando**" en cada momento si había sesión. En cuanto la sesión cambiaba a vacía, la pantalla se reconstruía y, como no tenía datos, mostraba "Sin perfil cargado".

El botón cerraba sesión primero (esto es lo que avisa al servidor y borra los tokens) y SOLO DESPUÉS llamaba a la navegación al login. Entre paso 1 y paso 2, la pantalla ya se había repintado con la versión "vacía".

**Analogía**: es como si para cerrar una tienda, primero apagaras las luces y después echaras las cortinas. Durante un instante la gente ve la tienda a oscuras desde fuera. Lo correcto es **echar las cortinas primero** (o a la vez), para que nunca se vea el local apagado.

---

### Solución

En la pantalla de perfil añadimos un **"escucha"** sobre el estado de sesión. En cuanto detecta que la sesión pasa de **estar a no estar**, 
navega INMEDIATAMENTE a `/login` —antes de que el repintado de la pantalla muestre nada raro.

Así, el orden ahora es:
1. Sesión cambia a vacía.
2. El "escucha" lo detecta y dispara `context.go('/login')` al instante.
3. La pantalla de perfil ni se repinta porque ya hemos saltado al login.

**Archivo**: `frontend_victorino/lib/features/cliente/perfil/presentation/perfil_cliente_screen.dart`

**Diff**:
```dart
// ❌ Antes — la pantalla pintaba "Sin perfil cargado" durante el instante
// que tardaba el botón en ejecutar context.go('/login').
class PerfilClienteScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perfilAsync = ref.watch(perfilNotifierProvider);
    return Scaffold(...);
  }
}

// ✅ Después — añadimos un ref.listen que reacciona en cuanto la sesión se cierra
// y navega a /login antes de pintar nada raro.
class PerfilClienteScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<SesionUsuario?>>(sesionProvider, (prev, next) {
      final habiaSesion = prev?.value != null;
      final hayAhora = next.value != null;
      if (habiaSesion && !hayAhora && context.mounted) {
        context.go('/login');
      }
    });
    final perfilAsync = ref.watch(perfilNotifierProvider);
    return Scaffold(...);
  }
}
```

---

### Consejos para evitar este patrón

- **No esperes** a hacer la navegación DESPUÉS de un cambio de estado global (sesión, login, logout). El intervalo entre 
"cambia el estado" y "se ejecuta la navegación" es suficiente para que la UI vea un estado intermedio.
- Usa **`ref.listen`** en pantallas que dependen del estado de sesión: te permite reaccionar al cambio en lugar de tener que ejecutar la navegación manualmente desde cada botón.
- El patrón "Pasó de X a Y → navega" es muy reutilizable. Sirve para sesión, pero también para "compra completada → ir a éxito" o "pedido cancelado → volver a la lista".
- Esto también se aplica al botón **"Eliminar mi cuenta"**: como ambas acciones acaban cerrando la sesión, el mismo `ref.listen` cubre los dos casos automáticamente.

---

## 2026-05-16 · Frontend Cliente — Crash al cancelar cita desde el Home

> 📸 **Captura asociada**: `cliente_error_cancelar_cita_1`

**Síntoma**: al pulsar el botón **"Cancelar"** de la card "Mi próxima cita" en el Home del cliente, la app crasheaba con dos errores encadenados en consola:
```
You have popped the last page off of the stack, there are no pages left to show
'package:go_router/src/delegate.dart': Failed assertion: line 175 pos 7:
'currentConfiguration.isNotEmpty'

'package:flutter/src/widgets/navigator.dart': Failed assertion: line 4081 pos 12:
'!_debugLocked': is not true.
```
El diálogo de confirmación se quedaba en pantalla, la cita NO se cancelaba y la app entraba en un estado inconsistente del que no se podía salir sin reiniciar.

---

### Qué hace este botón (explicado fácil)

La idea es muy simple: ves tu próxima cita en el Home, pulsas "Cancelar" y aparece un cartel con dos botones:
- **"No"** → cierras el cartel y no pasa nada.
- **"Sí, cancelar"** → cierras el cartel, el servidor cancela la cita y el peluquero recibe una notificación.

Eso debería ser todo. Pero pasaba un follón gordo: al pulsar cualquiera de los dos botones, en lugar de cerrar el cartel se cerraba TODA la pantalla y la app se quedaba en un estado raro.

---

### Por qué pasaba (en cristiano)

Imagina que tu aplicación tiene un sistema de "**ventanas apiladas**", como cuando abres pantallas dentro de pantallas. Hay dos jefes que mandan en esta pila:

1. **El jefe grande (GoRouter)**: maneja las pantallas principales — Home, Reservar, Historial, Perfil. Cuando navegas entre pestañas, es él quien se encarga.
2. **El jefe pequeño (Navigator)**: maneja las "ventanitas" más pequeñas que aparecen ENCIMA de la pantalla principal — los diálogos de confirmación, los bottom sheets, etc.

Cuando abres un diálogo `showDialog(builder: (X) => AlertDialog(...))`, ese "X" es una **etiqueta** especial que solo conoce al jefe pequeño (al Navigator del diálogo). Esa etiqueta es la que tienes que usar cuando le pidas a alguien "cierra esto".

**El bug**: en el código se ponía `builder: (_) => ...` (descartando la etiqueta) y dentro de los botones se hacía `Navigator.pop(context, ...)` usando el `context` GENERAL de la pantalla, no el del diálogo. Como ese `context` general lo conoce el JEFE GRANDE (GoRouter), el "pop" intentaba cerrar la PANTALLA entera en lugar del diálogo. Y como el Home es la primera pantalla del cliente y no hay nada debajo, el jefe grande lanzaba la excepción "ya no quedan pantallas que mostrar".

**Analogía**: imagina que tienes una nota Post-it pegada en la puerta de tu casa, y un mensaje en el móvil del jefe de la empresa. Si quieres que alguien quite el Post-it y le dices al jefe "quita esto", entiende que quieres cerrar la puerta entera (¡y se queda sin oficina!), no quitar la nota. Tienes que ser específico: hablar con la persona que tiene la nota delante, no con el jefe grande.

---

### Solución

Cambiar el nombre del parámetro del builder de `_` a `dialogContext` y usarlo en TODOS los `Navigator.pop(...)` dentro del diálogo. Así le hablamos al "jefe del diálogo" y no al "jefe grande de la app".

**Archivos corregidos**: 5 diálogos en 4 archivos del módulo cliente.
- `frontend_victorino/lib/features/cliente/home/presentation/home_cliente_screen.dart`
- `frontend_victorino/lib/features/cliente/reservar/presentation/pestana_reservar_screen.dart`
- `frontend_victorino/lib/features/cliente/historial/presentation/detalle_cita_screen.dart`
- `frontend_victorino/lib/features/cliente/perfil/presentation/widgets/dialogo_eliminar_cuenta.dart`
- `frontend_victorino/lib/features/cliente/reservar/presentation/widgets/dialogo_cita_existente.dart`

**Diff** (el patrón se repite en los 5 diálogos):
```dart
// ❌ Antes — el builder descarta el contexto del diálogo (con "_") y se usa
// el "context" general de la pantalla. Resultado: Navigator.pop pide cerrar
// la pantalla entera a GoRouter → assertion error.
showDialog<bool>(
  context: context,
  builder: (_) => AlertDialog(
    title: const Text('Cancelar cita'),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context, false),   // ⚠️ context exterior
        child: const Text('No'),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(context, true),    // ⚠️ context exterior
        child: const Text('Sí, cancelar'),
      ),
    ],
  ),
);

// ✅ Después — el builder captura el contexto del diálogo en "dialogContext"
// y se usa en los Navigator.pop. Así solo se cierra el diálogo, sin tocar la
// navegación principal de la app.
showDialog<bool>(
  context: context,
  builder: (dialogContext) => AlertDialog(
    title: const Text('Cancelar cita'),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(dialogContext, false),
        child: const Text('No'),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(dialogContext, true),
        child: const Text('Sí, cancelar'),
      ),
    ],
  ),
);
```

---

### Consejos para evitar este patrón

- **Regla de oro**: cuando uses `showDialog`, `showModalBottomSheet` o cualquier pop-up parecido, **nunca descartes el `context` del builder con `_`**. Captúralo en una variable con nombre (`dialogContext`, `sheetContext`, etc.) y úsalo SIEMPRE en los `Navigator.pop` que estén dentro de ese pop-up.
- Si te preguntas si necesitas el contexto del builder: la respuesta es **siempre sí** cuando vas a cerrar el pop-up. El `context` exterior es para acceder a temas, providers, scaffold messenger… pero NO para hacer pop.
- Esto se vuelve crítico cuando combinas **GoRouter + diálogos**: GoRouter maneja la pila principal, los diálogos viven en una pila SECUNDARIA. Si los confundes, GoRouter intenta sacar de la pila principal y rompe la navegación.
- Un truco para depurar: si ves el error "You have popped the last page off of the stack", busca todos tus `Navigator.pop` y revisa que cada uno use el contexto del builder más cercano, NO el context de la pantalla padre.

---

## 2026-05-15 · Frontend — Pantalla roja al abrir "Incidencias de plantilla" tras cancelar citas (Negocio)

**Síntoma**: después de arreglar el error del backend, al abrir la sección de "Incidencias de plantilla" en el panel Negocio la app se quedaba en rojo con el mensaje:
```
There should be exactly one item with [DropdownButton]'s value: Instance of 'Empleado'.
Either zero or 2 or more [DropdownMenuItem]s were detected with the same value.
```
En cristiano: el desplegable de empleados estaba en un estado imposible — tenía un valor seleccionado que no coincidía con ningún elemento de su lista, y Flutter se negó a pintar la pantalla.

---

### Por qué ocurrió

Cuando el administrador cancela las citas de un empleado, Riverpod (el sistema de estado de la app) recarga la lista de empleados desde el servidor para reflejar los cambios. Al recargar, crea **objetos nuevos en memoria** para cada empleado.

El problema está en cómo Dart compara objetos. Por defecto, Dart no compara dos objetos por su contenido (nombre, id, etc.) sino por su **dirección en memoria** — es decir, si son literalmente el mismo objeto. El empleado "Maradona" antes de la recarga y el "Maradona" después son dos objetos distintos para Dart, aunque tengan exactamente los mismos datos.

El estado del widget guardaba en `_seleccionado` el objeto antiguo de "Maradona". Tras la recarga, la lista tenía un "Maradona" nuevo. Flutter buscaba en la lista cuántos items coincidían con el valor seleccionado, encontraba cero (porque el objeto antiguo ≠ objeto nuevo por referencia), y lanzaba el error.

**Analogía**: es como si alguien fotocopiara tu DNI. Los dos DNIs tienen los mismos datos, pero si comparas los papeles físicamente, son dos papeles distintos. Dart hace esa comparación física, no la comparación de datos.

---

### Solución

Antes de construir el desplegable, buscar en la lista actual el empleado cuyo **id** coincide con el seleccionado. Así, aunque la lista se haya recargado con objetos nuevos, siempre se encuentra el empleado correcto por su identificador único.

**Archivo**: `frontend_victorino/lib/features/administrador/negocio/presentation/secciones/seccion_cancelacion_masiva_widget.dart`

**Diff**:
```dart
// ❌ Antes — se usaba directamente el objeto guardado en estado
DropdownButtonFormField<Empleado>(
  initialValue: _seleccionado,   // puede ser un objeto "viejo" que ya no está en la lista
  ...
),
FilledButton.icon(
  onPressed: _seleccionado == null || _ejecutando ? null : _ejecutar,
  ...
),

// ✅ Después — se busca el empleado en la lista actual por id antes de usarlo
final seleccionadoActual = _seleccionado == null
    ? null
    : activos.where((e) => e.id == _seleccionado!.id).firstOrNull;

DropdownButtonFormField<Empleado>(
  initialValue: seleccionadoActual,   // siempre apunta a un objeto de la lista actual
  ...
),
FilledButton.icon(
  onPressed: seleccionadoActual == null || _ejecutando ? null : _ejecutar,
  ...
),
```

---

**Lección aprendida**: en Flutter, cuando el valor de un `DropdownButtonFormField` es un objeto (no un tipo primitivo como `int` o `String`), hay que asegurarse de que ese objeto ES exactamente uno de los que hay en la lista de items — el mismo objeto, no una copia. Si el provider puede recargar los datos, siempre hay que resincronizar el valor seleccionado con la lista fresca antes de construir el dropdown, buscando por id o por cualquier campo único.

---

## 2026-05-15 · Backend — "Error inesperado" al cancelar todas las citas de un empleado (Negocio → Incidencias de plantilla)

**Síntoma**: al seleccionar un empleado en el panel Negocio y pulsar "Cancelar todas las citas futuras", la app mostraba el mensaje de error `ApiException: ha ocurrido un error inesperado`. En el terminal del backend aparecía:
```
InvalidDataAccessApiUsageException: No active transaction
  at CancelacionMasivaService.cancelarFuturasDelEmpleado (línea 54)
```
No se cancelaba ninguna cita ni se notificaba a ningún cliente.

---

### Qué hace esta funcionalidad (explicado fácil)

Cuando un empleado se pone enfermo o causa baja, el administrador puede pulsar un botón para cancelar de golpe TODAS sus citas futuras. El sistema cancela cada cita una por una y envía una notificación automática a cada cliente afectado para que pueda reservar de nuevo cuando quiera.

El diseño tenía una lógica inteligente de resiliencia: si por algún motivo una cita concreta falla (por ejemplo, un cliente la canceló justo en ese mismo instante desde su móvil), el sistema no para — la apunta como "omitida" y sigue con las demás. Al final muestra el resumen: cuántas se cancelaron, cuántos clientes fueron notificados y cuántas se omitieron.

Para lograr esa resiliencia, cada cita se cancela en su propia "mini-operación" independiente en la base de datos (`REQUIRES_NEW`). Si una mini-operación falla, no arrastra a las demás.

---

### Causa real (dos problemas encadenados)

**Problema 1 — El lock pedía algo que no existía**

En la base de datos, cuando vas a modificar registros de forma masiva, es buena práctica "bloquear" esas filas para que nadie más las toque mientras tú las estás procesando. En el código, el repositorio tenía esa instrucción de bloqueo (`@Lock`) en la consulta que carga la lista inicial de citas.

El problema: ese bloqueo solo funciona si hay una "transacción" activa (una transacción es como una sesión con la base de datos que garantiza que todo se hace o no se hace). El método que carga esa lista no tenía ninguna transacción abierta → la base de datos respondía: "¿qué bloqueo? ¡Si ni siquiera tenemos una sesión abierta!".

**Problema 2 — La llamada interna no pasaba por el intermediario**

Spring funciona con un sistema de "interceptores" que envuelven los métodos para añadirles comportamientos (como abrir una transacción). Pero esos interceptores solo funcionan cuando la llamada viene de FUERA de la clase. Si un método llama a otro método de su propia clase (`this.cancelarUnaCita()`), Spring no puede interceptarlo y el comportamiento transaccional se ignora silenciosamente.

En cristiano: el método `cancelarFuturasDelEmpleado` llamaba a `cancelarUnaCita` directamente, como si uno le susurrara al oído al de al lado. Spring no se enteraba y la instrucción "abre una transacción nueva para esto" (el `REQUIRES_NEW`) era completamente ignorada.

---

### Solución (dos cambios)

**Cambio 1 — Quitar el bloqueo de la consulta inicial** (`CitaRepository.java`)

La consulta que carga la lista de citas solo necesita los datos, no necesita bloquearlos. El bloqueo real se hace después, cita a cita, en el momento de cancelar cada una individualmente. Se eliminó el `@Lock` de `findCitasFuturasParaCancelar`.

```java
// ❌ Antes — bloqueo en la carga inicial (requería transacción que no existía)
@Lock(LockModeType.PESSIMISTIC_WRITE)
@Query("SELECT c FROM Cita c WHERE ...")
List<Cita> findCitasFuturasParaCancelar(...);

// ✅ Después — carga simple sin bloqueo (el bloqueo ocurre al cancelar cada una)
@Query("SELECT c FROM Cita c WHERE ...")
List<Cita> findCitasFuturasParaCancelar(...);
```

**Cambio 2 — Forzar que la llamada pase por el intermediario de Spring** (`CancelacionMasivaService.java`)

En lugar de llamar al método directamente (`this.cancelarUnaCita()`), se inyecta una referencia a la propia clase a través del sistema de Spring (`self`). Así la llamada sí pasa por el interceptor y el `REQUIRES_NEW` funciona de verdad.

```java
// Añadir al principio de la clase:
@Lazy
@Autowired
private CancelacionMasivaService self;

// ❌ Antes — llamada directa, Spring no se entera, REQUIRES_NEW ignorado
Long idCliente = cancelarUnaCita(c.getId());

// ✅ Después — llamada a través del proxy de Spring, REQUIRES_NEW funciona
Long idCliente = self.cancelarUnaCita(c.getId());
```

El `@Lazy` es necesario para que Spring no entre en bucle al intentar construir la clase que depende de sí misma.

---

**Archivos modificados**:
- `Backend_Victorino/src/main/java/org/victorino_style/repository/CitaRepository.java`
- `Backend_Victorino/src/main/java/org/victorino_style/service/CancelacionMasivaService.java`

**Lección aprendida**: en Spring, un método que llama a otro método de su propia clase (`this.xxx()`) NUNCA activa las anotaciones transaccionales del método llamado. Si necesitas que `REQUIRES_NEW` funcione en una llamada interna, debes inyectar la propia clase con `@Lazy @Autowired` y llamar a través de esa referencia.

---

## 2026-05-15 · Frontend — Números del eje Y amontonados y superpuestos en el gráfico "Citas por franja horaria" (Estadísticas admin)

**Síntoma**: en el apartado de Estadísticas del administrador, en la gráfica de líneas llamada "Citas por franja horaria", los números del lado izquierdo (eje Y) aparecían todos juntos y encima unos de otros, haciendo imposible leerlos. Se veían valores como `0`, `0.5`, `1`, `7.2`, `14`, `28`, `33` apilados en el mismo espacio.

---

### Qué hace ese gráfico y cómo funciona (explicado fácil)

**Para qué sirve a la peluquería**: de un vistazo, el dueño puede ver a qué horas del día hay más clientes. Si la gráfica sube mucho a las 10h y baja a las 15h, sabe que por la mañana está a tope y por la tarde floja — útil para decidir turnos, refuerzos o promociones en horas valle.

¿ Qué es La tasa de asistencia?
la tasa de asistencia solo entre las citas que no fueron canceladas.Muchas peluquerías usan esta fórmula porque consideran que una cancelación no es un fallo de asistencia, sino una cita liberada. Citas activas = completadas + no presentados = 772 Cancelaciones no se cuentan porque no hubo oportunidad de asistir.
Asistencia efectiva: Mide cuántos clientes asistieron cuando realmente tenían intención de venir. Muchos negocios prefieren esta segunda porque:
Las cancelaciones anticipadas permiten reprogramar.



**Eje X (horizontal — la base)**: representa las **horas del día**. Cada punto en el suelo de la gráfica es una hora: 10h, 11h, 12h… hasta la última hora con citas en el rango de fechas seleccionado.

**Eje Y (vertical — la altura)**: representa **cuántas citas hubo** en esa hora. Cuanto más alto llega la línea en un punto, más citas se hicieron en esa franja horaria.

**La línea**: une todos los puntos (hora → número de citas) formando una curva. Si sube bruscamente es que a esa hora se concentran muchas reservas.

**Dónde vive el código del gráfico**:
`frontend_victorino/lib/features/administrador/metricas/presentation/widgets/grafica_franjas_widget.dart`

**Cómo calcula los puntos** (la "fórmula"):
```
Para cada franja horaria recibida del backend:
  hora  = los dos primeros dígitos de "HH:00"  →  eje X
  citas = número de citas en esa hora           →  eje Y
  punto = (hora, citas)
```
Es decir, si el backend dice "a las 10:00 hubo 33 citas", el gráfico pone un punto en x=10, y=33.

**Cómo se calcula el rango del eje Y**:
```
máximo real   = el valor más alto de citas en cualquier hora
techo visual  = máximo × 1.2   (se deja un 20 % de aire arriba para que la línea no toque el borde)
suelo visual  = 0              (siempre empieza en cero)
```
Con esto el gráfico nunca "corta" la línea por arriba y siempre se lee bien.

---

### Causa del error

El intervalo entre etiquetas del eje Y estaba calculado como `maxY ÷ 2`. Eso suena razonable, pero generaba números con decimales (por ejemplo, si maxY = 33, el intervalo era 16.5). fl_chart (la librería de gráficas) rellenaba entonces el espacio desde 0 hasta el techo (39.6) usando ese intervalo decimal, produciendo etiquetas intermedias como 0, 0.5, 1, 7.2, 14, 28, 33… que no cabían en el espacio reservado (solo 32 px de ancho) y se solapaban todas.

### Solución

Dos cambios en `grafica_franjas_widget.dart`, línea 44:

1. **Intervalo limpio**: en lugar de `maxY ÷ 2` se usa `ceil(maxY ÷ 4)` — es decir, se divide el rango en 4 partes y se redondea al entero superior. Con maxY = 33, el intervalo pasa a ser 9, y las etiquetas quedan en 0, 9, 18, 27: cuatro números enteros bien espaciados.

2. **Filtro de decimales**: se añade una función que dice "si el valor no es un número entero exacto, no lo dibujes". Así el techo 39.6 (que es maxY × 1.2) no aparece como etiqueta.

3. **Más espacio para los números**: el ancho reservado para el eje Y pasa de 32 a 36 píxeles, para que los números de dos cifras tengan margen.

**Diff**:
```dart
// ❌ Antes — intervalo decimal, etiquetas apiladas
leftTitles: AxisTitles(
  sideTitles: SideTitles(
    showTitles: true,
    reservedSize: 32,
    interval: (maxY == 0 ? 1 : maxY / 2).toDouble(),
  ),
),

// ✅ Después — intervalo entero, ~4 etiquetas limpias
leftTitles: AxisTitles(
  sideTitles: SideTitles(
    showTitles: true,
    reservedSize: 36,
    interval: (maxY <= 4 ? 1 : (maxY / 4).ceil()).toDouble(),
    getTitlesWidget: (value, meta) {
      if (value != value.roundToDouble()) return const SizedBox.shrink();
      return Text(value.toInt().toString(), style: const TextStyle(fontSize: 11));
    },
  ),
),
```

**Archivo**: `frontend_victorino/lib/features/administrador/metricas/presentation/widgets/grafica_franjas_widget.dart` — línea 43.

---

**Lección aprendida**: en fl_chart, si el `interval` del eje tiene decimales, la librería genera etiquetas intermedias que desbordan el espacio. Siempre usar `ceil()` o redondear al entero más próximo para garantizar etiquetas limpias y separadas.

---

## 2026-05-14 · Frontend — Franja amarilla de desbordamiento al abrir "Crear cita rápida" (admin)

**Síntoma**: al pulsar un hueco libre en la agenda del administrador y abrirse la ventana emergente para crear una nueva cita, aparecía una franja amarilla y negra en el borde derecho de la pantalla junto con el mensaje en el terminal:
```
A RenderFlex overflowed by 0.189 pixels on the right.
```
En cristiano: Flutter estaba intentando dibujar algo 0.189 píxeles más ancho de lo que cabía en la pantalla, y lo avisaba con esa franja de obra. *(Ver captura: `error en crear cita admin`)*

---

### Intento 1 — ❌ No resolvió el problema

**Lo que pensamos**: mirando el código, había una fila horizontal (`Row`) con el selector de hora que tenía un texto sin restricción de ancho — el texto "Libre 11:30 – 14:00" que aparece a la derecha. Pensamos que ese texto era el que no cabía.

**Lo que hicimos**: envolvimos ese texto en un `Flexible` para que pudiera encogerse si no había sitio.

**Por qué no funcionó**: el texto del selector de hora no era el culpable. El error seguía apareciendo igual, porque había otro widget más conflictivo que no habíamos identificado.

---

### Intento 2 — ❌ No resolvió el problema

**Lo que pensamos**: quizá el contenedor principal (el `SingleChildScrollView`, que es como la caja que envuelve todo el formulario) no estaba recortando bien los bordes horizontales.

**Lo que hicimos**: añadimos `clipBehavior: Clip.hardEdge` al `SingleChildScrollView` para forzar que recortara cualquier cosa que sobresaliera.

**Por qué no funcionó**: ese parámetro ya era el valor por defecto en Flutter — básicamente le dijimos que hiciera lo que ya estaba haciendo. No tuvo ningún efecto.

---

### Intento 3 — ✅ Solución real

**Cómo encontramos el culpable**: en lugar de seguir adivinando, miramos el terminal de debug de Flutter, que mostraba exactamente qué widget estaba causando el error:
```
The relevant error-causing widget was:
  DropdownButtonFormField<int>
  file:///...bottom_sheet_crear_cita_rapida.dart:116
```

**El culpable real**: el desplegable de selección de servicio (`DropdownButtonFormField`). Internamente, este desplegable tiene una fila horizontal con el texto del servicio seleccionado y la flecha. Sin la propiedad `isExpanded: true`, ese desplegable mide su propio ancho basándose en el texto que contiene (nombre del servicio + duración), y con la fuente Poppins el resultado es un número con decimales que se pasaba 0.189 px del borde.

**La solución**: añadir `isExpanded: true` al desplegable. Esto le dice que, en lugar de medir su propio contenido para calcular su ancho, simplemente ocupe todo el espacio que le da su contenedor padre — sin decimales, sin desbordamiento.

**Diff**:
```dart
// ❌ Antes
DropdownButtonFormField<int>(
  initialValue: _idServicio,
  decoration: _dec('Servicio'),
  ...
),

// ✅ Después
DropdownButtonFormField<int>(
  initialValue: _idServicio,
  isExpanded: true,   // ← esta línea
  decoration: _dec('Servicio'),
  ...
),
```

**Archivo**: `frontend_victorino/lib/features/administrador/agenda/presentation/widgets/agenda_grid/bottom_sheet_crear_cita_rapida.dart` — línea 117.

---

**Lección aprendida**: cuando aparece este tipo de error en Flutter, lo primero es mirar el terminal — Flutter indica exactamente qué widget lo causa. No hay que adivinar. Además, cualquier `DropdownButtonFormField` dentro de un formulario con ancho limitado necesita `isExpanded: true` para no desbordar.

---

## 2026-05-04 · Frontend — `LocaleDataException: Locale data has not been initialized`

**Síntoma**: la app crashea con pantalla roja al entrar al panel admin:
```
LocaleDataException: Locale data has not been initialized,
call initializeDateFormatting(<locale>).
```

**Causa**: las pantallas de agenda, métricas y festivos usan `DateFormat.yMMMd('es')` y `DateFormat.yMMMMEEEEd('es')`. La librería `intl` necesita que se carguen los datos de localización del idioma elegido **antes** de instanciar cualquier `DateFormat` con locale específico.

**Solución**: invocar `initializeDateFormatting('es_ES')` en `main.dart` ANTES de `runApp`. El método llega vía `package:intl/date_symbol_data_local.dart`.

**Diff**:
```dart
// ❌ Antes
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: VictorinoApp()));
}

// ✅ Después
import 'package:intl/date_symbol_data_local.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_ES');
  runApp(const ProviderScope(child: VictorinoApp()));
}
```

---

## 2026-05-04 · Frontend Riverpod 3 — `StateProvider` no está definido

**Síntoma**: `flutter analyze` reporta:
```
error - The function 'StateProvider' isn't defined - undefined_function
```

**Causa**: `flutter_riverpod 3.x` ha eliminado `StateProvider`. La API moderna apuesta por `Notifier`/`AsyncNotifier` con métodos explícitos en lugar del setter `.state =`.

**Solución**: convertir cada `StateProvider<T>` en un `NotifierProvider<MiNotifier, T>` con un método público que mute el estado.

**Diff**:
```dart
// ❌ Antes
final filtrosAgendaProvider = StateProvider<FiltrosAgenda>(
  (ref) => FiltrosAgenda(fecha: DateTime.now()),
);
// uso:
ref.read(filtrosAgendaProvider.notifier).state = nuevo;

// ✅ Después
class FiltrosAgendaNotifier extends Notifier<FiltrosAgenda> {
  @override
  FiltrosAgenda build() => FiltrosAgenda(fecha: DateTime.now());
  void establecer(FiltrosAgenda nuevo) => state = nuevo;
}

final filtrosAgendaProvider =
    NotifierProvider<FiltrosAgendaNotifier, FiltrosAgenda>(FiltrosAgendaNotifier.new);
// uso:
ref.read(filtrosAgendaProvider.notifier).establecer(nuevo);
```

---

## 2026-05-04 · Backend — Excepciones existentes como `class` vacías rompen Lombok en cascada

**Síntoma**: tras añadir handlers en `GlobalExceptionHandler` para `CitaSolapadaException` y `CitaNoModificableException`, **todo el módulo** dejó de compilar con errores en cascada del estilo:
```
error - cannot find symbol method setNombreEmpleado
error - cannot find symbol variable log
error - incompatible types: Class<CitaSolapadaException> cannot be converted to Class<? extends Throwable>
```

**Causa**: las dos excepciones existían en el repo como `class CitaSolapadaException {}` (vacías, sin extender `RuntimeException`). Al usarlas como handlers de `@ExceptionHandler`, el compilador rechaza la clase y **aborta el procesado de annotations**. Como Lombok genera setters/getters/loggers vía annotation processor, todo el código que dependía de Lombok dejó de tener esos métodos.

**Solución**: rellenar los stubs y hacer que extiendan `RuntimeException`. Lección general: **toda excepción del proyecto debe extender RuntimeException o una subclase**, nunca quedarse como `class` vacía.

**Diff**:
```java
// ❌ Antes
public class CitaSolapadaException {}

// ✅ Después
public class CitaSolapadaException extends RuntimeException {
    public CitaSolapadaException(String mensaje) { super(mensaje); }
    public CitaSolapadaException() { super("La franja horaria no está disponible."); }
}
```

**Cómo identificarlo rápido**: si Maven dice "cannot find symbol set/get…" en clases que SÍ tienen `@Getter @Setter`, no es un problema de Lombok. Mira **el primer error** del log: ahí está la causa real.

---

## 2026-05-04 · Frontend — Bottom navigation flotando en lugar de pegada al borde inferior

**Síntoma**: la barra de 5 pestañas del admin aparecía flotando con un margen de 12 px alrededor.

**Causa**: el primer borrador del `WidgetInferiorAdmin` heredaba un `SafeArea` con `margin: EdgeInsets.all(12)`, lo que la separaba del fondo del Scaffold.

**Solución**: quitar el `margin` y el `SafeArea` envolvente. El widget se pega al ancho completo y respeta el inset inferior con `MediaQuery.of(context).padding.bottom`. Las esquinas redondeadas se aplican solo arriba (`BorderRadius.vertical(top: Radius.circular(24))`) para que la barra "se enganche" al borde.

```dart
// ❌ Antes
return SafeArea(
  child: Container(
    margin: const EdgeInsets.all(12),
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(30), ...),
    ...
  ),
);

// ✅ Después
final safeBottom = MediaQuery.of(context).padding.bottom;
return Container(
  padding: EdgeInsets.only(top: 8, bottom: 8 + safeBottom, left: 6, right: 6),
  decoration: BoxDecoration(
    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
    ...
  ),
  ...
);
```

---

## 2026-05-04 · Backend — Tests de Mockito: `List.of(new Object[]{...})` no compila

**Síntoma**: `MetricaServiceTest.java` no compilaba con:
```
error - no suitable method found for thenReturn(List<Object>)
   inference variable E has incompatible bounds
       equality constraints: Object[]
       lower bounds: Object
```

**Causa**: en Java, al hacer `List.of(new Object[]{1L, "a"}, new Object[]{2L, "b"})` el compilador infiere `List<Object>` (mira el primer elemento como un `Object`, no como `Object[]`).

**Solución**: parametrizar explícitamente el tipo del `List.of`.

**Diff**:
```java
// ❌ Antes
when(citaRepository.rankingServicios(any(), any())).thenReturn(List.of(
    new Object[]{1L, "Corte clásico", 12L},
    new Object[]{2L, "Tinte", 5L}
));

// ✅ Después
when(citaRepository.rankingServicios(any(), any())).thenReturn(List.<Object[]>of(
    new Object[]{1L, "Corte clásico", 12L},
    new Object[]{2L, "Tinte", 5L}
));
```

---

## 2026-05-03 · Frontend Riverpod 3 — `AutoDisposeAsyncNotifier` no existe

**Síntoma**: `flutter analyze` falla con:
```
error - Classes can only extend other classes - extends_non_class
error - The function 'AutoDisposeAsyncNotifierProvider' isn't defined
```

**Causa**: en flutter_riverpod 3.3.1 las clases `AutoDisposeAsyncNotifier` y los providers `AutoDisposeAsyncNotifierProvider` se han fusionado. Ahora todos los providers se auto-disposan por defecto (o se controla con un parámetro).

**Solución**:
- `AutoDisposeAsyncNotifier<T>` → `AsyncNotifier<T>`.
- `AutoDisposeAsyncNotifierProvider<N, T>` → `AsyncNotifierProvider<N, T>`.

**Diff**:
```dart
// ❌ Antes
class LoginNotifier extends AutoDisposeAsyncNotifier<void> { ... }
final loginNotifierProvider =
    AutoDisposeAsyncNotifierProvider<LoginNotifier, void>(LoginNotifier.new);

// ✅ Después
class LoginNotifier extends AsyncNotifier<void> { ... }
final loginNotifierProvider =
    AsyncNotifierProvider<LoginNotifier, void>(LoginNotifier.new);
```

---

## 2026-05-03 · Frontend Riverpod 3 — `AsyncValue.valueOrNull` no existe

**Síntoma**: `error - The getter 'valueOrNull' isn't defined for the type 'AsyncValue<T>'`.

**Causa**: en Riverpod 3 se ha simplificado la API: `valueOrNull` se eliminó porque `value` ahora ya devuelve `T?`.

**Solución**: cambiar todas las llamadas `.valueOrNull` → `.value`.

```dart
// ❌ Antes
final sesion = ref.watch(sesionProvider).valueOrNull;

// ✅ Después
final sesion = ref.watch(sesionProvider).value;
```

---

## 2026-05-03 · Imports relativos mal contados en `registrar_cliente.dart`

**Síntoma**: `error - Target of URI doesn't exist: '../../../../core/errors/api_exception.dart'`.

**Causa**: el archivo está en `lib/features/cliente/registro/domain/casos_uso/`. Para llegar a `lib/core/` hay que subir **5 niveles** (`../../../../../`), no 4. Los imports a una feature hermana sí necesitan 4 niveles (hasta `lib/features/`).

**Solución**: contar bien los niveles:
- `casos_uso → domain → registro → cliente → features → lib` = 5 niveles para llegar a `lib/core/`.
- 4 niveles para llegar a `lib/features/<otra-feature>/`.

```dart
// ❌ Antes
import '../../../../core/errors/api_exception.dart';
import '../../../login_admin_empleado_cliente/domain/repositorios/auth_repositorio.dart';

// ✅ Después
import '../../../../../core/errors/api_exception.dart';
import '../../../../login_admin_empleado_cliente/domain/repositorios/auth_repositorio.dart';
```

---

## Plantilla para nuevos errores

```markdown
## YYYY-MM-DD · Componente — Título corto

**Síntoma**: qué falló (mensaje exacto si lo hay).

**Causa**: por qué fallaba realmente.

**Solución**: qué se cambió.

**Diff** (opcional):
\```dart
// ❌ Antes
...
// ✅ Después
...
\```
```
