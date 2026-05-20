# Guía junior — Módulo CLIENTE

> Bienvenido/a al módulo del cliente final de Victorino Style. Esta guía está pensada para que alguien que 
**no ha tocado nunca el proyecto** pueda entender qué hace cada archivo, cómo se conectan entre sí y cómo arrancar todo en local.
> Si has tocado solo Flutter o solo Java, esta guía es para ti.

---

## Tabla de contenidos

1. [Mapa mental del módulo](#1-mapa-mental-del-módulo)
2. [Cómo arrancar en local](#2-cómo-arrancar-en-local)
3. [Cómo se conectan los sistemas](#3-cómo-se-conectan-los-sistemas)
4. [Estructura por capas (Clean Architecture)](#4-estructura-por-capas-clean-architecture)
5. [Archivo por archivo — Backend](#5-archivo-por-archivo--backend)
6. [Archivo por archivo — Frontend](#6-archivo-por-archivo--frontend)
7. [Flujos de datos típicos](#7-flujos-de-datos-típicos)
8. [Recetas comunes](#8-recetas-comunes)
9. [Errores frecuentes y cómo arreglarlos](#9-errores-frecuentes)
10. [Glosario rápido](#10-glosario-rápido)

---

## 1. Mapa mental del módulo

El módulo cliente es **la mitad consumidora** del producto: la que usa el cliente final de la peluquería. Vive en dos sitios físicos:

```
   ┌──────────────────────────────────┐         ┌────────────────────────────┐
   │  Backend (Java + Spring Boot)    │ ◀────▶  │  Frontend (Flutter + Dart) │
   │  Backend_Victorino/               │  HTTP  │  frontend_victorino/        │
   │                                   │  JWT   │                             │
   │  - Controllers REST              │         │  - 4 pantallas (pestañas)  │
   │  - Servicios con reglas          │         │  - Wizard de 4 pasos       │
   │  - Repositorios JPA              │         │  - Riverpod (estado)        │
   │  - Notificaciones in-app + push  │         │  - Dio (HTTP)               │
   └──────────────┬───────────────────┘         └─────────────────────────────┘
                  │
                  ▼
            ┌──────────────┐
            │  MySQL 8     │
            │  15 tablas   │
            └──────────────┘
```

Las **4 pestañas** del cliente: Inicio · Reservar · Historial · Perfil.

Si nunca has visto el módulo: empieza por [cliente.md](cliente.md) (visión funcional) y vuelve aquí cuando entiendas qué hace.

---

## 2. Cómo arrancar en local

### 2.1 Requisitos previos

| Herramienta | Versión | Para qué |
|---|---|---|
| JDK Temurin | **21** | Compilar y ejecutar el backend |
| Maven | 3.9+ (incluido el wrapper `./mvnw`) | Build del backend |
| MySQL | **8.0.x** | Base de datos |
| Flutter SDK | **3.41.2** | Compilar y ejecutar la app |
| Dart | **3.11.0** (viene con Flutter) | |
| Android Studio o emulador | cualquiera con API 33+ | Probar la app en Android |
| IntelliJ IDEA 2026.1 (opcional) | | Recomendado para backend |

### 2.2 Pasos para arrancar el backend

```bash
# 1) Crear la BD y aplicar el schema.
mysql -u root -p < Backend_Victorino/src/main/resources/db/schema.sql

# 2) Aplicar seed con datos iniciales (admin victorino@admin.com / Admin1234!).
mysql -u root -p < Backend_Victorino/src/main/resources/db/seed.sql

# 3) Configurar credenciales en application.properties (si no es root/root).
#    Editar Backend_Victorino/src/main/resources/application.properties

# 4) Arrancar el backend.
cd Backend_Victorino
./mvnw spring-boot:run
```

Spring Boot expone:
- `http://localhost:8080/api/v1/swagger-ui.html` → Swagger UI (probar endpoints desde el navegador).
- `http://localhost:8080/api/v1/...` → todos los endpoints REST.

### 2.3 Pasos para arrancar el frontend

```bash
cd frontend_victorino

# 1) Descargar dependencias.
flutter pub get

# 2) Arrancar la app en un emulador o dispositivo.
#    En Android Emulator → usa 10.0.2.2 para apuntar al backend del host.
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080/api/v1

# Para iOS simulator o desktop:
# flutter run --dart-define=API_BASE_URL=http://localhost:8080/api/v1
```

### 2.4 Crear un cliente de prueba

Tres opciones:

1. **Desde la app**: pulsa "Registrarse" en el login, rellena el formulario. Al confirmar te loguea y te lleva al Home.
2. **Desde Swagger**: `POST /auth/registro` con body `{nombre, apellidos, correo, password}`.
3. **Desde curl**:
   ```bash
   curl -X POST http://localhost:8080/api/v1/auth/registro \
     -H "Content-Type: application/json" \
     -d '{"nombre":"Test","apellidos":"Cliente","correo":"test@x.com","password":"Test1234"}'
   ```

### 2.5 Tests

```bash
# Backend (JUnit 5 + Mockito)
cd Backend_Victorino
./mvnw test
# Excluyendo CancelacionMasivaServiceTest si da problemas preexistentes:
./mvnw test -Dtest='!CancelacionMasivaServiceTest'

# Frontend (analyze + tests)
cd frontend_victorino
flutter analyze
flutter test
```

---

## 3. Cómo se conectan los sistemas

### 3.1 Frontend → Backend (HTTP)

Cada vez que el cliente hace algo (reservar, listar, cambiar foto…) la app envía una petición HTTP al backend con su token JWT. El proceso es **siempre** el mismo:

```
   Pantalla Flutter
         │
         │ ref.read(casoUsoProvider).ejecutar(...)
         ▼
   Caso de uso (validación defensiva)
         │
         ▼
   Repositorio (interfaz)
         │
         ▼  inyección
   RepositorioImpl (Dio HTTP)
         │
         ▼  añade header Authorization: Bearer <access>
   JwtInterceptor → RefreshInterceptor → red
         │
         ▼  HTTP
   Spring Controller
         │
         ▼
   @PreAuthorize("hasRole('CLIENTE')")
         │
         ▼
   Service (reglas de negocio)
         │
         ▼
   Repository (JPA)
         │
         ▼
       MySQL
```

Si algo falla, la cadena vuelve hacia arriba con un `Failure` tipado (`FailureValidacion`, `FailureCredenciales`, `FailureConflicto`…) que la pantalla muestra al usuario.

### 3.2 Backend → Cliente (notificaciones in-app)

Cuando el cliente hace una reserva exitosa, el backend inserta una fila en `notificacion` para él. Cuando la app refresca su bandeja (o el endpoint `/notificaciones`), trae todas las filas y las pinta.

### 3.3 Backend → Cliente (push FCM)

Si el cliente tiene `push_activa_cliente = true` y tokens FCM registrados, el `NotificacionService` también envía un mensaje push a Firebase, que entrega la notificación al móvil incluso con la app cerrada.

Este flujo se activa **tras el commit** de la transacción para evitar carreras: primero se confirma la fila en BD, luego se manda el push.

### 3.4 Frontend ↔ Frontend (Riverpod)

Riverpod es el "armario" que permite a las pantallas compartir estado sin pasárselo a mano:

- `sesionProvider` → ¿hay sesión? ¿con qué rol?
- `proximaCitaProvider` → ¿cuál es mi próxima cita?
- `serviciosCatalogoProvider` → lista de servicios activos.
- `wizardNotifierProvider` → estado del wizard en curso.
- `historialNotifierProvider` → lista de mis citas con filtro.
- `perfilNotifierProvider` → mi perfil.

Cuando reservas una cita, el wizard llama a `recargar()` del `proximaCitaProvider`, y el Home se repinta automáticamente con la nueva info — sin que tengas que avisar manualmente.

---

## 4. Estructura por capas (Clean Architecture)

Tanto el backend como el frontend siguen una división por capas. La idea es:

- **Capa UI (Flutter)** o **Capa Controller (Spring)**: solo orquesta. No tiene reglas.
- **Capa de Casos de Uso / Servicios**: aplica reglas de negocio. No conoce HTTP ni BD.
- **Capa de Datos**: traduce entre el mundo de fuera (HTTP, BD) y el del dominio.

Por qué importa: si mañana cambias la BD de MySQL a PostgreSQL, solo tocas la capa de datos. Si cambias el lenguaje del backend, las pantallas del frontend siguen funcionando porque hablan por HTTP.

---

## 5. Archivo por archivo — Backend

> Backend_Victorino/src/main/java/org/victorino_style/...

### 5.1 DTOs (`dto/cliente/`)

DTOs son los "sobres" que viajan entre el cliente y el servidor.

| Archivo | Para qué |
|---|---|
| `ServicioPublicoResponse.java` | Servicio del catálogo (foto, nombre, duración, precio). |
| `EmpleadoPublicoResponse.java` | Empleado del catálogo (foto, nombre, apellidos). |
| `PerfilClienteResponse.java` | Datos del cliente autenticado (incluye `pushActiva`). |
| `EditarPerfilClienteRequest.java` | Body de `PUT /cliente/perfil`. |
| `CambiarPasswordClienteRequest.java` | Body de `POST /cliente/perfil/cambiar-pwd`. |
| `ConfiguracionPushRequest.java` | Body de `PUT /cliente/perfil/notificaciones`. |
| `EliminarCuentaRequest.java` | Body de `DELETE /cliente/perfil` (solo `password`). |
| `CitaClienteResponse.java` | Vista de una cita para el cliente (con foto de servicio y empleado). |
| `ReservarCitaRequest.java` | Body de `POST /cliente/citas` (incluye `cualquieraDisponible`). |
| `ModificarCitaRequest.java` | Body de `PUT /cliente/citas/{id}`. |
| `HuecoDisponibleResponse.java` | Cada hueco del cálculo de disponibilidad. |
| `DetalleCitaExistenteError.java` | Payload del campo `detalles` del 409 cuando hay cita conflictiva (con código, id, fecha, hora, nombre del servicio). |

Todos son `record` de Java 21 con validaciones Bean Validation (`@NotBlank`, `@Size`, etc.).

### 5.2 Excepciones (`exception/`)

| Archivo | HTTP | Cuándo |
|---|---|---|
| `CitaMismoDiaException.java` | 409 | El cliente ya tiene cita activa este día. Lleva el detalle estructurado. |
| `CitaSemanaDuplicadaException.java` | 409 | Misma semana ISO. |
| `CitaServicioDuplicadoException.java` | 409 | Mismo servicio activo. |
| `CitaFueraDeAntelacionException.java` | 409 | Fecha pasada o > HOY+30 días. |
| `PasswordIncorrectaException.java` | 409 | Pwd actual incorrecta en cambio o eliminación. |

Las 3 primeras son **enriquecidas**: llevan un `DetalleCitaExistenteError` que el `GlobalExceptionHandler` mete en el campo `detalles` del `ApiError` JSON.

El `GlobalExceptionHandler.java` global se modificó para añadir los nuevos handlers.

### 5.3 Repositorios (`repository/`)

| Archivo | Lo que añadió el módulo cliente |
|---|---|
| `CitaRepository.java` | 6 queries nuevas: `findActivasClienteEnRango`, `findActivasClienteServicio`, `findActivasEmpleadoFechaParaActualizar` (con LOCK), `findActivasEmpleadoFecha`, `findCitasCliente`, `findFuturasConfirmadasCliente`. |
| `NotificacionRepository.java` | `marcarTodasComoLeidas(idUsuario, ahora)` con `@Modifying UPDATE`. |

### 5.4 Mappers (`mapper/`)

Transforman entidades JPA en DTOs.

| Archivo | Convierte |
|---|---|
| `CitaClienteMapper.java` | `Cita` → `CitaClienteResponse`. |
| `CatalogoMapper.java` | `Servicio` → `ServicioPublicoResponse` y `Empleado` → `EmpleadoPublicoResponse`. |

### 5.5 Servicios (`service/`)

Los tres servicios nuevos del módulo cliente:

#### `DisponibilidadService.java`

Motor del cálculo de huecos. Su único método público:
```java
public List<HuecoDisponibleResponse> calcularHuecos(
    Long idServicio, LocalDate fecha, Long idEmpleado, Long idCitaExcluir);
```

Pasos:
1. Carga el servicio (para conocer su duración).
2. Si la fecha es festivo o cierre anual → lista vacía.
3. Carga `Peluqueria` → horario de apertura/cierre del día de la semana.
4. Si la fecha es HOY, descarta horas pasadas.
5. Genera slots cada `duracionServicio` minutos.
6. Para cada slot:
   - Si `idEmpleado` concreto: comprueba descanso + citas activas.
   - Si "Cualquiera": para todos los empleados activos, descarta los ocupados y elige el de menor carga del día.
7. Devuelve `List<HuecoDisponibleResponse>`.

Es `@Transactional(readOnly = true)`: rápido, no toma locks.

#### `CitaClienteService.java`

Centraliza TODA la lógica de citas del cliente. Métodos públicos:

- `reservar(idCliente, dto)` — `POST /cliente/citas`.
- `modificar(idCliente, idCita, dto)` — `PUT /cliente/citas/{id}`.
- `cancelar(idCliente, idCita)` — `POST /cliente/citas/{id}/cancelar`.
- `listarMisCitas(idCliente, estadoOpc)` — `GET /cliente/citas`.
- `obtenerMiCitaActiva(idCliente)` — `GET /cliente/citas/activa`.
- `obtenerMiCita(idCliente, idCita)` — `GET /cliente/citas/{id}`.

Aplica las **3 reglas combinadas** en orden:
1. Antelación (hoy ≤ fecha ≤ hoy+30) → `CitaFueraDeAntelacionException`.
2. Día abierto → `CitaSolapadaException` con mensaje "peluquería cerrada".
3. Mismo día → `CitaMismoDiaException`.
4. Misma semana → `CitaSemanaDuplicadaException`.
5. Mismo servicio → `CitaServicioDuplicadoException`.
6. Solape franja → `CitaSolapadaException`.

Para el lock pesimista usa `citaRepository.findActivasEmpleadoFechaParaActualizar(...)`. Para `@Version` se basa en lo que Hibernate haga automáticamente con la entidad `Cita`.

Para el **fallback "Cualquiera"**: si el cliente eligió "Cualquiera" en el wizard y el peluquero preferido está ocupado al hacer commit, busca un alternativo en el mismo lock.

#### `PerfilClienteService.java`

Operaciones del perfil del cliente:

- `obtenerPerfil(idCliente)` — `GET /cliente/perfil`.
- `editarPerfil(idCliente, dto)` — `PUT /cliente/perfil`.
- `subirFoto(idCliente, MultipartFile)` — `POST /cliente/perfil/foto`.
- `cambiarPassword(idCliente, dto)` — `POST /cliente/perfil/cambiar-pwd`. Revoca refresh tokens del usuario.
- `configurarPush(idCliente, dto)` — `PUT /cliente/perfil/notificaciones`.
- `eliminarCuenta(idCliente, dto)` — `DELETE /cliente/perfil`. Cancela citas futuras una por una en `REQUIRES_NEW`, anonimiza Cliente + Usuario, revoca tokens.

Reusa **el mismo patrón** que `CancelacionMasivaService`: inyección lazy de sí mismo (`@Lazy @Autowired private PerfilClienteService self;`) para que `REQUIRES_NEW` funcione en llamadas internas.

### 5.6 Controladores (`controller/`)

Los 3 controladores nuevos + 1 modificación:

| Archivo | Endpoints |
|---|---|
| `CatalogoController.java` | `GET /servicios`, `GET /empleados`. Anotado `@PreAuthorize("isAuthenticated()")`. |
| `CitaClienteController.java` | 7 endpoints `/cliente/citas/...`. Rol `CLIENTE`. |
| `PerfilClienteController.java` | 6 endpoints `/cliente/perfil/...`. Rol `CLIENTE`. |
| `NotificacionController.java` | + `POST /notificaciones/leer-todas`. |

Los controladores son **finos**: solo extraen el `idCliente` del JWT (`Long.parseLong(authentication.getName())`), validan el body con `@Valid` y delegan al servicio.

### 5.7 Configuración (`config/`)

`SecurityConfig.java` añadió:
- `/cliente/**` → `hasRole("CLIENTE")`.
- `/servicios` y `/empleados` → `authenticated()` (cualquier rol).

### 5.8 Enums (`entity/enums/`)

`TipoNotificacion.java` añadió `MODIFICACION_CITA`. El `schema.sql` se modificó para incluir el nuevo valor en el ENUM MySQL de `notificacion.tipo_notificacion`.

### 5.9 Scheduler

`RecordatorioScheduler.java` no se modificó porque ya respetaba la preferencia `push_activa_cliente` del cliente (delega en `NotificacionService.crearNotificacion`).

### 5.10 Tests

| Archivo | Cubre |
|---|---|
| `CitaClienteServiceTest.java` | 13 tests: reservar OK, antelación, festivo, las 3 reglas, solape, modificar, cancelar. |
| `DisponibilidadServiceTest.java` | 10 tests: festivo, cierre anual, día cerrado, empleado concreto, descanso, solape, edición, "Cualquiera" con menor carga, sin empleados. |
| `PerfilClienteServiceTest.java` | 9 tests: obtener, editar (correo duplicado), foto, cambio pwd, push, eliminación de cuenta. |

---

## 6. Archivo por archivo — Frontend

> frontend_victorino/lib/features/cliente/...

### 6.1 Shell

`shell/presentation/shell_cliente_screen.dart` — contenedor con bottom nav y 4 ramas independientes via `StatefulShellRoute.indexedStack`. Idéntico patrón que el admin.

### 6.2 Shared

Lo que comparten los 4 submódulos:

```
shared/
├── domain/
│   ├── entidades/
│   │   ├── estado_cita.dart            enum + extension con etiqueta y backendValue
│   │   ├── cita_cliente.dart            entidad central (Home, Reservar, Historial)
│   │   ├── servicio_publico.dart        catálogo del cliente
│   │   ├── empleado_publico.dart        catálogo del cliente
│   │   ├── hueco.dart                   Paso 3 del wizard
│   │   └── datos_reserva.dart           estado acumulado del wizard (copyWith)
│   ├── repositorios/
│   │   ├── catalogo_repositorio.dart    contrato GET /servicios + /empleados
│   │   └── citas_cliente_repositorio.dart  contrato de los 7 endpoints de citas
│   └── casos_uso/obtener_catalogo.dart
├── data/
│   ├── modelos/
│   │   ├── cita_cliente_dto.dart        fromJson + aEntidad
│   │   ├── servicio_publico_dto.dart
│   │   ├── empleado_publico_dto.dart
│   │   └── hueco_dto.dart
│   └── repositorios/
│       ├── catalogo_repositorio_impl.dart      Dio + ErrorMapper
│       └── citas_cliente_repositorio_impl.dart Dio + multipart + DateFormat
└── application/
    ├── catalogo_provider.dart            FutureProviders del catálogo
    └── citas_cliente_provider.dart        Provider del repo de citas
```

**Por qué compartido**: las entidades `CitaCliente`, `ServicioPublico` y el repositorio de citas se reusan en Home, Reservar e Historial. Tenerlas duplicadas sería un desastre de mantenimiento.

### 6.3 Home

```
home/
├── application/home_providers.dart        AsyncNotifier de próxima cita
└── presentation/
    ├── home_cliente_screen.dart           ListView con cabecera + card + servicios
    └── widgets/
        ├── cabecera_home.dart             saludo + nombre + campana con badge
        ├── card_proxima_cita.dart         gradiente púrpura → cian, foto empleado
        ├── card_sin_cita.dart             CTA grande "Reservar ahora"
        ├── servicio_destacado_card.dart   card vertical con FotoServicio (ratio dinámico)
        └── bottom_sheet_notificaciones.dart  abierto desde la campana
```

`bottom_sheet_notificaciones.dart` contiene:
- Switch "Recibir notificaciones push" → modifica `cliente.push_activa_cliente`.
- Botón "Marcar todas como leídas" → `POST /notificaciones/leer-todas`.
- Lista de notificaciones del usuario con resaltado de no-leídas.

### 6.4 Reservar (wizard)

```
reservar/
├── application/
│   ├── reservar_providers.dart           casos de uso
│   └── wizard_notifier.dart              Notifier<EstadoWizard>
├── domain/casos_uso/
│   ├── obtener_disponibilidad.dart
│   ├── crear_cita.dart                   valida esCompleto antes de POST
│   ├── modificar_cita.dart
│   └── obtener_cita_activa.dart
└── presentation/
    ├── pestana_reservar_screen.dart      entrada bottom nav (bloqueo preventivo)
    ├── wizard_reserva_screen.dart        contenedor + barra + botones
    ├── paso_1_servicio.dart              lista vertical
    ├── paso_2_empleado.dart              grid 2 col + "Cualquiera"
    ├── paso_3_dia_hora.dart              chips días + calendario + huecos
    ├── paso_4_confirmar.dart             resumen + nota
    └── widgets/
        ├── barra_progreso.dart            4 segmentos
        └── dialogo_cita_existente.dart    diálogo 409 contextual
```

**`wizard_notifier.dart`** mantiene un `EstadoWizard` con: paso actual (0..3), `DatosReserva` y opcionalmente `idCitaEditar` si está en modo edición. Métodos públicos: `reiniciar`, `precargarParaEdicion`, `setServicio`, `setEmpleado`, `setFechaHora`, `setNota`, `siguiente`, `anterior`, `irAlPaso`.

### 6.5 Historial

```
historial/
├── application/historial_providers.dart   AsyncNotifier con filtro de estado
├── domain/casos_uso/
│   ├── obtener_historial.dart
│   ├── obtener_detalle_cita.dart
│   └── cancelar_cita.dart
└── presentation/
    ├── historial_screen.dart              lista + chips de filtro + pull-to-refresh
    ├── detalle_cita_screen.dart           detalle + modificar/cancelar/repetir
    └── widgets/
        ├── filtro_estado_chips.dart       Todas/Confirmadas/Completadas/Canceladas/No acudiste
        └── cita_historial_card.dart       card + chip estado coloreado + botón Repetir
```

El historial **observa el cambio de usuario** vía `sesionProvider.select((s) => s.value?.idUsuario)`. Cuando el usuario hace logout y login con otra cuenta, la lista se recarga automáticamente.

### 6.6 Perfil

```
perfil/
├── application/perfil_providers.dart      AsyncNotifier con todos los métodos
├── domain/
│   ├── entidades/perfil_cliente.dart      PerfilCliente + DatosPerfilCliente
│   ├── repositorios/perfil_repositorio.dart contrato
│   └── casos_uso/
│       ├── obtener_perfil.dart
│       ├── editar_perfil.dart
│       ├── subir_foto.dart
│       ├── cambiar_password.dart
│       ├── configurar_push.dart
│       └── eliminar_cuenta.dart
├── data/
│   ├── modelos/perfil_cliente_dto.dart
│   └── repositorios/perfil_repositorio_impl.dart
└── presentation/
    ├── perfil_cliente_screen.dart          secciones: Datos, Seguridad, Cuenta
    └── widgets/dialogo_eliminar_cuenta.dart doble confirmación + pwd
```

La pantalla del perfil escucha `sesionProvider` con `ref.listen(...)`: en cuanto la sesión cambia de no-null a null (= se cerró sesión), navega a `/login` antes de que la pantalla intente repintarse con "Sin perfil cargado".

### 6.7 Core compartido (no cliente-only)

| Archivo | Para qué |
|---|---|
| `core/api/api_endpoints.dart` | Tabla central de URLs. Aquí están todas las rutas `/cliente/...`. |
| `core/api/dio_cliente.dart` | Cliente Dio compartido con baseUrl + JwtInterceptor + RefreshInterceptor. |
| `core/errors/failure.dart` | Tipos de error tipados (`FailureConflicto` con campo `detalles` para 409 enriquecidos). |
| `core/errors/error_mapper.dart` | Convierte `DioException` → `Failure`. Extrae el campo `detalles` del 409. |
| `core/widgets_compartidos/selector_imagen.dart` | Selecciona foto (galería/cámara) + recorta. Lo usan admin, empleado y cliente. |
| `core/widgets_compartidos/foto_servicio.dart` | Renderiza foto de servicio con aspect ratio real subido. Lo usa el Home del cliente. |
| `core/widgets_compartidos/widget_inferior_cliente.dart` | Bottom navigation de 4 ítems. |

---

## 7. Flujos de datos típicos

### 7.1 Flujo de "Reservar una cita"

```
Usuario → pestaña Reservar
                │
                ▼
   pestana_reservar_screen.dart  ◀── observa proximaCitaProvider
                │
                │ pulsa "Reservar ahora"
                ▼
   wizard_reserva_screen.dart    ◀── observa wizardNotifierProvider
                │
                │ Paso 1: elige servicio
                │ Paso 2: elige peluquero o "Cualquiera"
                │ Paso 3: pide disponibilidad → backend
                │ Paso 3: elige hora
                │ Paso 4: confirma
                ▼
   crearCitaProvider.ejecutar(datos)
                │
                ▼
   CitasClienteRepositorioImpl.reservar(datos)
                │
                ▼ POST /cliente/citas
   Backend → CitaClienteController.reservar(...)
                │
                ▼
   CitaClienteService.reservar(idCliente, dto)
                │
                │ Carga cliente + servicio
                │ Valida antelación
                │ Carga peluquería + festivos
                │ Valida día abierto
                │ Valida 3 reglas (mismo día/semana/servicio)
                │ Resuelve empleado (con fallback si "Cualquiera")
                │ LOCK PESIMISTA → valida solape final
                │ Inserta Cita
                │ Notifica al cliente y al empleado
                │ Audita CREAR_CITA
                │
                ▼ 201 CitaClienteResponse
   Frontend recibe → mapper.aEntidad() → CitaCliente
                │
                ▼
   ProximaCitaNotifier.recargar() automático
                │
                ▼
   Home repinta la card "Mi próxima cita"
```

### 7.2 Flujo de "Cambiar la foto de perfil"

```
Usuario → Perfil → toca la foto
              │
              ▼
   SelectorImagen.elegirYRecortar(formaCircular: true)
              │
              ▼ devuelve File recortado
   PerfilNotifier.subirFoto(archivo)
              │
              ▼
   PerfilRepositorioImpl.subirFoto(archivo)
              │
              ▼ multipart POST /cliente/perfil/foto
   Backend → PerfilClienteController.subirFoto(...)
              │
              ▼
   FileStorageService.reemplazar(archivo, "cliente", fotoAntigua)
              │
              │ valida formato y tamaño
              │ guarda con UUID en /uploads/cliente/
              │ borra la foto antigua
              ▼
   200 OK { "fotoUrl": "/uploads/cliente/uuid.jpg" }
              │
              ▼ frontend actualiza state
   PerfilCliente.fotoUrl = "/uploads/cliente/uuid.jpg"
              │
              ▼ cabecera del Home y del Perfil repintan
```

### 7.3 Flujo de "Eliminar mi cuenta"

```
Usuario → Perfil → Eliminar mi cuenta
              │
              ▼
   dialogo_eliminar_cuenta.dart
              │
              │ paso 1: advertencia → confirma
              │ paso 2: pide pwd actual → introduce
              ▼
   PerfilNotifier.eliminarCuenta(pwd)
              │
              ▼ DELETE /cliente/perfil { password }
   Backend → PerfilClienteService.eliminarCuenta(idCliente, dto)
              │
              │ verifica pwd → si falla 409
              │ busca citas futuras CONFIRMADAS
              │ por cada cita (REQUIRES_NEW):
              │    estado = CANCELADA_PELUQUERIA
              │    notifica empleado con CANCELACION_CLIENTE
              │ anonimiza Cliente
              │ anonimiza Usuario + soft-delete
              │ revoca refresh_tokens
              │ borra device_token_fcm
              │ borra foto del disco
              │ audita ELIMINAR_CUENTA
              ▼ 204 No Content
   Frontend → ref.read(sesionProvider.notifier).cerrarSesion()
              │
              ▼ ref.listen detecta sesión null
   context.go('/login')
```

---

## 8. Recetas comunes

### Receta A — Añadir un nuevo endpoint REST en el cliente

1. **Backend**:
   1. Crear el DTO `Request`/`Response` en `dto/cliente/` (record con validaciones).
   2. Si toca una excepción nueva, crearla en `exception/` y registrar el handler en `GlobalExceptionHandler.java`.
   3. Si toca una nueva query, añadirla a `CitaRepository.java` (o el repo que toque).
   4. Implementar la lógica en `CitaClienteService.java` o `PerfilClienteService.java`.
   5. Exponer el endpoint en el controller correspondiente con `@PreAuthorize("hasRole('CLIENTE')")`.
   6. Escribir test unitario del servicio.
2. **Frontend**:
   1. Añadir la URL a `lib/core/api/api_endpoints.dart`.
   2. Añadir el método al contrato del repositorio (`shared/domain/repositorios/...`).
   3. Implementarlo en el `RepositorioImpl` con `Dio` + `ErrorMapper`.
   4. Crear el caso de uso en `<submodulo>/domain/casos_uso/`.
   5. Exponerlo como provider en `<submodulo>/application/<submodulo>_providers.dart`.
   6. Consumirlo desde la pantalla via `ref.read(...)` o `ref.watch(...)`.

### Receta B — Cambiar la regla "1 cita activa por semana"

1. Edita `CitaClienteService.validarReglasCliente(...)`.
2. Ajusta o quita el bloque que lanza `CitaSemanaDuplicadaException`.
3. Si quitas la regla, considera quitar también la excepción y su handler.
4. Actualiza `cliente.md` para reflejar la regla.
5. Actualiza los tests de `CitaClienteServiceTest.java`.

### Receta C — Añadir un nuevo tipo de notificación

1. Añadir el valor al enum `TipoNotificacion.java`.
2. Añadirlo al ENUM MySQL en `schema.sql`. Si la BD ya existe, ejecutar:
   ```sql
   ALTER TABLE notificacion
     MODIFY COLUMN tipo_notificacion ENUM(... , 'NUEVO_TIPO') NOT NULL;
   ```
3. Llamar a `notificacionService.crearNotificacion(usuario, cita, NUEVO_TIPO, titulo, cuerpo)` desde el servicio que toque.
4. Si quieres que tenga icono específico en la bandeja, modificar `notificacion_card.dart`.

### Receta D — Cambiar el número de chips de días del wizard

1. Editar `paso_3_dia_hora.dart`, línea `final dias = List<DateTime>.generate(31, ...)`.
2. Cambiar `31` por el número deseado.
3. Considerar que el backend valida `fecha <= HOY + 30 días`. Si subes a 60, también hay que ajustar `CitaClienteService.validarAntelacion(...)` y la regla 5 del CLAUDE.md.

---

## 9. Errores frecuentes

### 9.1 "No se ha encontrado lo solicitado" al intentar reservar

**Causa probable**: el `idServicio` o `idEmpleado` enviado no existe en BD o está dado de baja.

**Fix**: revisa que la lista de catálogo esté actualizada (`pull-to-refresh` en Home). Si persiste, mira la pestaña Network de tu emulador o el log del backend (`tail -f` sobre los logs).

### 9.2 "Ya tienes una cita ..." aunque acabas de cancelar la anterior

**Causa probable**: el frontend está mostrando la lista cacheada. La cancelación se hizo en BD pero el `proximaCitaProvider` aún no se ha recargado.

**Fix**: pull-to-refresh en Home, o ejecuta `ref.read(proximaCitaProvider.notifier).recargar()` tras cualquier mutación.

### 9.3 La foto no se ve en producción aunque sí en local

**Causa probable**: `urlImagen()` está concatenando una baseUrl que no apunta al servidor de producción.

**Fix**: lanzar la app con `--dart-define=API_BASE_URL=https://...` para que `ApiEndpoints.baseUrl` apunte al servidor correcto.

### 9.4 Compilo el backend pero los nuevos endpoints devuelven 404

**Causa probable**: Spring no detectó los nuevos `@RestController` porque no están en el package escaneado.

**Fix**: revisa que el package del nuevo controller esté bajo `org.victorino_style.controller` (o cualquier package por debajo del `BackendVictorinoApplication`).

### 9.5 `ApiException: Datos inválidos` con `fields: [...]`

**Causa**: validación de Bean Validation del body. El frontend ya muestra los errores por campo en el formulario gracias a `FailureValidacion.errores`. Si no se ven, comprueba que la pantalla está leyendo `failure.errores` y poniendo `errorText:` en cada `TextField`.

### 9.6 "You have popped the last page off of the stack" (GoRouter)

**Causa**: estás haciendo `Navigator.pop(context, ...)` dentro de un `showDialog` o `showModalBottomSheet` usando el `context` exterior en lugar del `dialogContext` del builder.

**Fix**: cambiar `builder: (_) => ...` por `builder: (dialogContext) => ...` y usar `Navigator.pop(dialogContext, ...)`. Más detalle en [errores.md](../errores.md#2026-05-16--frontend-cliente--crash-al-cancelar-cita-desde-el-home).

### 9.7 "Sin perfil cargado" al cerrar sesión

**Causa**: la pantalla del perfil observa `sesionProvider` y, al pasar a null, repinta antes de que termine la navegación a `/login`.

**Fix**: añadir `ref.listen` en la pantalla del perfil para navegar a `/login` en cuanto la sesión pase a null. Ver [errores.md](../errores.md#2026-05-16--frontend-cliente--mi-perfil-sin-perfil-cargado-al-cerrar-sesión).

---

## 10. Glosario rápido

| Término | Qué significa |
|---|---|
| **AsyncNotifier** | Una clase de Riverpod que mantiene un estado asíncrono (cargando, datos, error) y permite que las pantallas se suscriban. |
| **Bean Validation** | Las anotaciones `@NotNull`, `@Size`, `@Email`, etc. que validan los DTOs en el backend antes de entrar al controller. |
| **Dio** | El cliente HTTP de Flutter. Equivalente a `axios` en JavaScript. |
| **GoRouter** | El sistema de navegación declarativa de Flutter usado en este proyecto. |
| **Lock pesimista** | Mecanismo de BD que bloquea filas para que dos transacciones no las modifiquen a la vez. Se activa con `@Lock(LockModeType.PESSIMISTIC_WRITE)` en JPA. |
| **REQUIRES_NEW** | Propagación transaccional que abre una nueva transacción independiente de la actual. Permite que un fallo aislado no aborte el lote completo. |
| **`@Version`** | Anotación JPA que activa lock optimista: incrementa un contador en cada UPDATE, detecta pisadas concurrentes. |
| **Soft-delete** | "Borrar pero no del todo": en lugar de eliminar fila, se le pone una fecha de baja. La fila se conserva. |
| **Anonimizar** | Borrar los datos personales pero mantener la fila para histórico/auditoría. Requisito del RGPD. |
| **Walk-in** | Cliente sin cuenta que llega presencialmente. El empleado le crea una cita con sus datos en una fila de `cliente_invitado`. |

---

## Ver también

- [cliente.md](cliente.md) — visión funcional + 50+ preguntas para no técnicos.
- [api_cliente.md](api_cliente.md) — referencia técnica de los endpoints.
- [errores.md](../errores.md) — bitácora de incidentes y soluciones.
- [admin.md](../administrador/admin.md), [api_admin.md](../administrador/api_admin.md), [guia_junior_admin.md](../administrador/guia_junior_admin.md) — equivalentes del módulo admin.
- [notificaciones.md](../administrador/notificaciones.md) — explicación del subsistema FCM + in-app.

¡Bienvenido al equipo!
