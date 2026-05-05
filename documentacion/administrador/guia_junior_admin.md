# Guía junior — Módulo Administrador

> Cómo arrancar el panel admin, qué hace cada archivo creado/modificado y cómo se conecta con el resto del sistema (frontend ↔ backend ↔ MySQL ↔ notificaciones).
> Si solo has tocado Flutter o solo Java, esta guía está pensada para que entiendas el flujo completo de punta a punta.

---

## 1 · Cómo arrancar el módulo en local

### Backend
```bash
# 1. Asegúrate de tener MySQL 8 corriendo y la BD creada con schema.sql + seed.sql.
mysql -u root -p < Backend_Victorino/src/main/resources/db/schema.sql
mysql -u root -p < Backend_Victorino/src/main/resources/db/seed.sql

# 2. Arranca Spring Boot.
cd Backend_Victorino
./mvnw spring-boot:run
# El puerto es 8080 y el contexto /api/v1.
# Swagger UI: http://localhost:8080/api/v1/swagger-ui.html
```

### Frontend
```bash
cd frontend_victorino
flutter pub get
flutter run -d <device>
```

Por defecto el cliente apunta a `http://10.0.2.2:8080/api/v1` (Android Emulator). Para iOS / web / dispositivo físico, lanza con `--dart-define`:
```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8080/api/v1
```

### Usuario admin de prueba (seed)

| Campo | Valor |
|---|---|
| Correo | `victorino@admin.com` |
| Contraseña | `Admin1234!` |
| Foto | `/uploads/empleados/admin.jpg` |

Tras el login eres redirigido a `/admin/agenda` (la primera pestaña del bottom nav).

---

## 2 · Mapa mental de la arquitectura

```
┌──────────────────────────── FLUTTER ────────────────────────────┐
│  Pantalla (presentation)                                        │
│       ↓ pulsa botón                                             │
│  AsyncNotifier (application)                                    │
│       ↓ ejecutar()                                              │
│  Caso de uso (domain)                                           │
│       ↓ valida y delega                                         │
│  Repositorio (interfaz domain) ← contrato                       │
│       ↑                                                         │
│  Repositorio impl (data) ─► Dio (HTTP) ─► Failure si error      │
└────────────────────────────│────────────────────────────────────┘
                             │  Authorization: Bearer <accessToken>
                             ▼
┌──────────────────────── SPRING BOOT ────────────────────────────┐
│  JwtAuthenticationFilter ▶ SecurityContextHolder con rol        │
│       ↓                                                         │
│  Controller (`@PreAuthorize ROLE_ADMINISTRADOR`)                │
│       ↓                                                         │
│  Service (lógica + @Transactional)                              │
│       ↓                                                         │
│  ├── Repository (Spring Data JPA / @Query JPQL)                 │
│  ├── FileStorageService (subida fotos a /uploads/<carpeta>/)    │
│  ├── NotificacionService ─► tabla `notificacion` + FCM (TODO)   │
│  └── AuditoriaService (REQUIRES_NEW) ─► tabla `auditoria`       │
│       ↓                                                         │
│  Mapper ─► DTO record ─► JSON                                   │
└────────────────────────────│────────────────────────────────────┘
                             ▼
                       MySQL 8 InnoDB
                  utf8mb4_unicode_ci · Europe/Madrid
```

---

## 3 · Inventario de archivos del módulo

### Convenciones rápidas

- **Backend:** paquete base `org.victorino_style`. Paquetes planos (`controller/`, `service/`, etc.). Anotaciones Spring/JPA en inglés, identificadores de dominio en español.
- **Frontend:** Clean Architecture + features. Carpetas en español (`entidades`, `repositorios`, `casos_uso`, `modelos`).
- **Snake_case** en archivos Dart, **PascalCase** en clases Java, **camelCase** en métodos.

### 3.1 · Backend — Entidades y enums

| Archivo | Qué hace | Conexiones |
|---|---|---|
| `entity/enums/EstadoCita.java` | Enum con los 6 estados de una cita: CONFIRMADA, EN_PROCESO, COMPLETADA, CANCELADA_CLIENTE, CANCELADA_PELUQUERIA, NO_PRESENTADO. | Mapea la columna `cita.estado_cita` (ENUM en MySQL). Lo usan `Cita`, `CitaService`, `CancelacionMasivaService`, `MetricaService`, `CitaRepository`. |
| `entity/enums/TipoFestivo.java` | Enum con los 5 tipos de festivo. | `festivo.tipo_festivo`. Lo usan `Festivo`, `ConfiguracionService`, `FestivoMapper`. |
| `entity/enums/TipoNotificacion.java` | Enum con 7 tipos de notificación. | `notificacion.tipo_notificacion`. Lo usan `NotificacionService`, `FirebaseService`. |
| `entity/Cita.java` (modificada) | Añadido `@Version` (`version_cita`) y `estadoCita` migrado a `@Enumerated(STRING) EstadoCita`. | Punto de unión de `Cliente`/`ClienteInvitado` (XOR), `Empleado`, `Servicio`. La fila se serializa a `CitaAdminResponse` vía `CitaMapper`. |
| `db/schema.sql` (modificada) | Añadida columna `version_cita BIGINT UNSIGNED NOT NULL DEFAULT 0` para el `@Version` JPA. | Hibernate la usa para detectar conflictos de concurrencia optimista (UPDATE WHERE version=?) cuando dos transacciones tocan la misma cita. |

### 3.2 · Backend — DTOs (`dto/admin/`)

Todos son `record` Java 21 con Bean Validation. Espejos de los modelos del frontend.

| Archivo | Endpoint | Validaciones clave |
|---|---|---|
| `EmpleadoAdminRequest.java` | POST/PUT empleados | `@NotBlank`, `@Email`, `@Size(254)`, `@Pattern` pwd |
| `EmpleadoAdminResponse.java` | GET/POST/PUT empleados | trae `esAdministrador` calculado por el mapper |
| `ServicioAdminRequest.java` | POST/PUT servicios | `@DecimalMin("0.01")`, `@Min(5) @Max(480)` |
| `ServicioAdminResponse.java` | GET/POST/PUT servicios | — |
| `HorarioPeluqueriaRequest.java` / `Response` | GET/PUT `/horario` | 7 días apertura/cierre opcionales |
| `DescansoRequest.java` / `Response` | PUT `/empleados/{id}/descanso` | `@Min(10) @Max(120)` |
| `FestivoRequest.java` / `Response` | POST/GET `/festivos` | TipoFestivo enum |
| `CierreAnualRequest.java` / `Response` | GET/PUT `/cierre-anual` | fechas opcionales |
| `CitaAdminResponse.java` | GET `/agenda` | Combina cliente/invitado + empleado + servicio en un solo objeto |
| `HistorialClienteResponse.java` | GET `/clientes/{id}/historial` | Flag `cuentaActiva` (RGPD) |
| `WalkInRequest.java` | POST `/citas/walk-in` | `@AssertTrue esIdentidadValida()` (XOR cliente/invitado) |
| `AvisoClienteResponse.java` | GET `/avisos/cancelaciones-frecuentes` | — |
| `CancelacionMasivaResponse.java` | POST `/empleados/{id}/cancelar-citas` | `citasCanceladas`, `clientesNotificados`, `citasOmitidas` |
| `MetricasResumenResponse.java` | GET `/metricas/resumen` | 4 sub-records: `ServicioPopular`, `EmpleadoPopular`, `DistribucionDia`, `DistribucionFranja` |
| `FotoResponse.java` | POST foto empleado/servicio | `{ fotoUrl: "/uploads/.../<uuid>.jpg" }` |

### 3.3 · Backend — Repositorios (`repository/`)

Todos extienden `JpaRepository<Entity, Long>`. Sólo se listan los métodos custom añadidos en este módulo.

| Repositorio | Métodos clave |
|---|---|
| `EmpleadoRepository.java` | `findActivoById`, `findAllActivos`, `findAllOrderActivosPrimero` (JPQL con join a `usuario.fechaEliminacionUsuario`). |
| `ServicioRepository.java` | `findByIdAndFechaEliminacionServicioIsNull`, listados ordenados por nombre, `existsByNombreServicioIgnoreCaseAndFechaEliminacionServicioIsNull`. |
| `CitaRepository.java` | 12 queries: `findCitasFuturasParaCancelar` (PESSIMISTIC_WRITE), `findByIdParaActualizar` (PESSIMISTIC_WRITE), `buscarAgenda`, `contarPorEstado`, `contarTotal`, `rankingServicios`, `rankingEmpleados`, `distribucionPorDiaSemana`, `distribucionPorFranjaHoraria`, `avisosCancelacionesFrecuentes`, `contarSolapes`. |
| `HorarioEmpleadoRepository.java` | `findByIdEmpleado_Id` (1:1 con empleado). |
| `FestivoRepository.java` | listados ordenados, `existsByFechaFestivo`. |
| `PeluqueriaRepository.java` | `findFirstByOrderByIdAsc` (singleton). |
| `NotificacionRepository.java` | `findByIdDestinatarioNotificacion_Id…OrderByFecha…Desc`. |
| `AdministradorRepository.java` | `existsById` (detectar si un empleado es también admin). |
| `DeviceTokenFcmRepository.java` | `findByIdUsuario_Id` (tokens FCM por usuario). |

### 3.4 · Backend — Servicios (`service/`)

Donde vive la lógica de negocio. Se invocan desde los Controller y se apoyan en Repository + Mapper + Auditoria + Notificacion + FileStorage.

```
┌──────────────────────────────┐
│ FileStorageService (NUEVO)   │  Subida y borrado de fotos en /uploads/<carpeta>/<uuid>.<ext>
│ AuditoriaService (relleno)   │  registrar(accion, entidad, idEntidad, detalle) en REQUIRES_NEW
│ NotificacionService (relleno)│  in-app SIEMPRE + push delegado a FirebaseService
│ FirebaseService  (relleno)   │  enviarPush stub con TODO FCM
└──────────────────────────────┘
              ▲
              │ inyectados como dependencia
              │
┌─────────────┼──────────────────────────────────────────────┐
│ EmpleadoService          → CRUD + foto + auditoría         │
│ ServicioService          → CRUD + foto + auditoría         │
│ ConfiguracionService     → horario, descansos, festivos,   │
│                            cierre anual + auditoría        │
│ CitaService              → agenda global, walk-in,         │
│                            historial cliente, avisos       │
│ MetricaService           → resumen agregado en JPQL        │
│ CancelacionMasivaService → flujo crítico con REQUIRES_NEW  │
└────────────────────────────────────────────────────────────┘
```

**Detalle por archivo:**

- `service/FileStorageService.java` (NUEVO): valida archivo (no vacío, ≤5 MB, JPG/PNG/WEBP), genera UUID, guarda en `uploads/<carpeta>/`, devuelve URL relativa. Tiene `reemplazar(...)` que borra la antigua. Lo usan `EmpleadoService.subirFoto` y `ServicioService.subirFoto`.

- `service/AuditoriaService.java` (relleno): único método `registrar(accion, entidad, idEntidad, detalle)`. Resuelve el usuario actual desde `SecurityContextHolder` (correo) → busca su `Usuario`. Inserta fila en `auditoria` en una transacción independiente (`REQUIRES_NEW`) — así, aunque la transacción de negocio haga rollback, la pista queda. Lo llaman TODOS los services en escrituras (alta empleado, baja servicio, cambio horario, festivo creado, walk-in, cancelación masiva, etc.).

- `service/NotificacionService.java` (relleno): método `crearNotificacion(usuarioDestinatario, citaRelacionada, tipo, titulo, cuerpo)`. **Siempre** inserta fila en `notificacion`. Si el destinatario es cliente con `pushActivaCliente=true`, o empleado/admin fuera de su rango de silencio, llama a `FirebaseService.enviarPush(...)`. Si Firebase confirma envío, marca `enviada_push_notificacion=true`.

- `service/FirebaseService.java` (relleno mínimo): hoy un stub que loggea. La integración real con Firebase Admin SDK queda como `// TODO FCM` — bloque dedicado en el archivo. La firma del método `enviarPush(tokens, titulo, cuerpo, tipo)` ya es estable: cuando se conecte FCM no hay que tocar a sus consumidores.

- `service/EmpleadoService.java` (relleno completo):
  - `crear(dto)`: valida correo único, encripta pwd con BCrypt, crea fila `usuario` (rol EMPLEADO) + fila `empleado` con foto vacía, audita. La foto se sube luego con `subirFoto`.
  - `editar(id, dto)`: actualiza nombre/apellidos/correo. Si la pwd llega no vacía, se cambia.
  - `darBaja(id)`: marca `fecha_eliminacion_usuario`. **Auto-protección**: si el id corresponde al admin actual logueado, lanza `IllegalStateException`.
  - `subirFoto(id, archivo)`: delega en `FileStorageService.reemplazar`.
  - `listar(incluirInactivos)`: usa `findAllActivos` o `findAllOrderActivosPrimero`.

- `service/ServicioService.java` (relleno completo): mismo patrón que `EmpleadoService` pero sobre `servicio`. Soft-delete vía `fecha_eliminacion_servicio`.

- `service/ConfiguracionService.java` (relleno completo): cuatro sub-dominios:
  - **Horario semanal**: opera sobre `peluqueria` (singleton). `obtenerPeluqueria()` privado lanza `PeluqueriaNoConfiguradaException` si no hay fila (problema de seed).
  - **Descansos**: encuentra/crea fila en `horario_empleado` y actualiza `descanso_inicio_horario` + `descanso_duracion_horario`.
  - **Festivos**: comprueba duplicados con `existsByFechaFestivo`, lanza `FestivoDuplicadoException`.
  - **Cierre anual**: valida `fechaFin >= fechaInicio`.

- `service/CitaService.java` (relleno completo):
  - `agendaGlobal(...)`: delega en `CitaRepository.buscarAgenda` + mapea a DTO.
  - `historialCliente(idCliente)`: une datos del cliente + lista de sus citas.
  - `crearWalkIn(dto)`: valida XOR, calcula `horaFin = horaInicio + servicio.duracionServicio`, llama a `validarDisponibilidad(...)` (festivo, cierre anual, horario, descanso, solape), persiste `cliente_invitado` si procede, crea cita y notifica al empleado con `NUEVA_CITA_EMPLEADO`.
  - `avisosCancelacionesFrecuentes()`: ejecuta la `@Query` HAVING > umbral.

- `service/MetricaService.java` (relleno completo): orquesta 6 queries de `CitaRepository` y compone `MetricasResumenResponse`. Calcula tasa de asistencia con cuidado de no dividir por cero. Traduce `MySQL DAYOFWEEK (1=Domingo)` a `Java DayOfWeek (1=Lunes)`.

- `service/CancelacionMasivaService.java` (NUEVO): flujo crítico. Diagrama detallado en [admin.md §3](admin.md). El método público `cancelarFuturasDelEmpleado(id)` recorre las citas futuras y llama, por cada una, a `cancelarUnaCita(id)` que está marcado con `@Transactional(propagation = REQUIRES_NEW)` para que cada cita quede aislada. Si una cita ya estaba en estado terminal o no se pudo bloquear, se cuenta como omitida y se sigue.

### 3.5 · Backend — Mappers (`mapper/`)

| Archivo | Convierte |
|---|---|
| `EmpleadoMapper.java` | `Empleado` (+ `Usuario` por herencia JOINED) → `EmpleadoAdminResponse`. Consulta `AdministradorRepository.existsById` para enriquecer con `esAdministrador`. |
| `ServicioMapper.java` | `Servicio` → `ServicioAdminResponse`. |
| `CitaMapper.java` | `Cita` → `CitaAdminResponse`. Resuelve el XOR cliente/invitado y compone nombres completos. |
| `HorarioMapper.java` | `Peluqueria` → `HorarioPeluqueriaResponse` y `CierreAnualResponse`. `HorarioEmpleado` → `DescansoResponse` (incluye nombre del empleado). |
| `FestivoMapper.java` | `Festivo` → `FestivoResponse`. Convierte `String tipoFestivo` (BD) a enum `TipoFestivo` con fallback NACIONAL si la BD tuviera datos corruptos. |

### 3.6 · Backend — Excepciones (`exception/`)

| Archivo | HTTP | Causa |
|---|---|---|
| `RecursoNoEncontradoException.java` (relleno, padre genérico) | 404 | Padre de Empleado/Servicio NoEncontrado |
| `EmpleadoNoEncontradoException.java` | 404 | id de empleado inexistente o dado de baja |
| `ServicioNoEncontradoException.java` | 404 | id de servicio inexistente o dado de baja |
| `FotoObligatoriaException.java` | 400 | Multipart vacío / extensión no soportada / >5 MB |
| `NoCitasFuturasCancelablesException.java` | 409 | Cancelación masiva sin citas que cancelar |
| `PeluqueriaNoConfiguradaException.java` | 500 | Singleton de peluquería ausente (falta seed) |
| `FestivoDuplicadoException.java` | 409 | Fecha de festivo ya registrada |
| `CitaSolapadaException.java` (relleno) | 409 | Walk-in fuera de horario / con descanso / con otra cita |
| `CitaNoModificableException.java` (relleno) | 409 | Cita en estado terminal |
| `GlobalExceptionHandler.java` (modificado) | varios | Maneja todas las anteriores + las de auth y las de validación de Bean Validation |

### 3.7 · Backend — Controllers (`controller/`)

Cada uno es delgado: orquesta y serializa. Toda la lógica vive en el Service. Todos llevan `@PreAuthorize("hasRole('ADMINISTRADOR')")`.

| Archivo | Rutas |
|---|---|
| `EmpleadoController.java` | `/admin/empleados/...` + foto + cancelar-citas |
| `ServicioController.java` | `/admin/servicios/...` + foto |
| `ConfiguracionController.java` | `/admin/horario`, `/admin/empleados/{id}/descanso`, `/admin/festivos`, `/admin/cierre-anual` |
| `CitaController.java` | `/admin/agenda`, `/admin/clientes/{id}/historial`, `/admin/citas/walk-in`, `/admin/avisos/cancelaciones-frecuentes` |
| `MetricaController.java` | `/admin/metricas/resumen` |

### 3.8 · Backend — Configuración

| Archivo | Cambio |
|---|---|
| `config/SecurityConfig.java` | Añadida regla `.requestMatchers("/admin/**").hasRole("ADMINISTRADOR")` (defensa en profundidad junto al `@PreAuthorize`). |
| `application.properties` | Añadidos: `victorino.uploads.directorio=uploads`, `spring.servlet.multipart.max-file-size=5MB`, `spring.servlet.multipart.max-request-size=5MB`, `victorino.avisos.umbral-cancelaciones=3`. |

### 3.9 · Backend — Tests (`src/test/.../service/`)

| Archivo | Escenarios |
|---|---|
| `EmpleadoServiceTest.java` | 10 escenarios: alta (correo duplicado, ok, sin pwd) · edición · baja · listado · foto |
| `ServicioServiceTest.java` | 6 escenarios: listar, obtener, crear (trim del nombre), editar, baja, foto |
| `ConfiguracionServiceTest.java` | 8 escenarios: horario, descanso, festivos (duplicado, ok), cierre anual (invertido, ok) |
| `CancelacionMasivaServiceTest.java` | 6 escenarios: empleado no existe, sin citas, 2 citas + 2 clientes, 1 omitida, walk-in invitado, mismo cliente 2 veces |
| `MetricaServiceTest.java` | 5 escenarios: vacío, tasa asistencia, rankings, día semana MySQL→Java, franja horaria |

**Total: 35 tests admin** (51 tests con los 16 pre-existentes de auth y JWT).

---

### 3.10 · Frontend — Capa core actualizada

| Archivo | Cambio |
|---|---|
| `lib/main.dart` | Llamada a `initializeDateFormatting('es_ES')` para que `DateFormat.yMMMd('es')` no lance `LocaleDataException`. |
| `lib/core/api/api_endpoints.dart` | Añadidas 20 rutas admin (`adminEmpleados`, `adminServicios`, `adminHorario`, `adminAgenda`, `adminMetricasResumen`, etc.) y helpers `adminEmpleadoPorId(int id)`. |
| `lib/core/router/app_router.dart` | Reemplazada `/admin/home` por un `StatefulShellRoute.indexedStack` con 5 ramas (agenda, métricas, empleados, servicios, negocio) + rutas anidadas para crear/editar y para el walk-in. Conserva el redirect post-login basado en rol. |
| `lib/core/widgets_compartidos/widget_inferior_admin.dart` | Refactor completo: ahora es **stateless**, recibe `indiceActual` y `alSeleccionar`. La navegación real la lleva GoRouter. Pegada al borde inferior (sin margin), respeta el SafeArea por gestos. |

### 3.11 · Frontend — Submódulos

Estructura uniforme para los 5 (con variantes según las acciones que necesitan):

```
lib/features/administrador/<submódulo>/
├── data/
│   ├── modelos/<dto>.dart            # DTOs JSON ↔ entidad
│   └── repositorios/<repo>_impl.dart # Implementación HTTP
├── domain/
│   ├── entidades/<entidad>.dart      # Modelos inmutables del dominio
│   ├── repositorios/<repo>.dart      # Interfaz (contrato)
│   └── casos_uso/<acción>.dart       # Validan + delegan al repo
├── application/
│   └── <submódulo>_providers.dart    # Riverpod: repos, casos uso, AsyncNotifiers
└── presentation/
    ├── <pantalla>_screen.dart
    └── widgets/<widgets>.dart
```

**Conexiones entre capas**:

```
   Pantalla (presentation)
        │ ref.watch(<submódulo>_notifierProvider)
        ▼
   AsyncNotifier (application)
        │ usa los casos de uso
        ▼
   Caso de uso (domain)
        │ implementa la interfaz del repo
        ▼
   Repositorio impl (data)
        │ Dio + ErrorMapper  ─►  ApiException(Failure)
        ▼
   Backend Spring Boot
```

**Por submódulo** (resumen de los archivos más importantes):

| Submódulo | Archivos clave | Highlight |
|---|---|---|
| `empleados/` | `lista_empleados_screen.dart`, `crear_editar_empleado_screen.dart`, `widgets/empleado_card.dart`, `widgets/dialogo_cancelacion_masiva.dart`, `application/empleados_providers.dart` | Foto en escala de grises si baja, badges ACTIVO/BAJA/ADMIN, autoprotección visual del admin. |
| `servicios/` | `lista_servicios_screen.dart`, `crear_editar_servicio_screen.dart`, `widgets/servicio_card.dart`, `application/servicios_providers.dart` | Cards con foto grande de cabecera, precio destacado en €. |
| `negocio/` | `negocio_screen.dart` + 5 secciones (`seccion_horario_widget`, `seccion_descansos_widget`, `seccion_cancelacion_masiva_widget`, `seccion_festivos_widget`, `seccion_cierre_anual_widget`) | Una sola pantalla scroll con 5 secciones (mockup `gestion_peluqueria_admin.jpeg`). |
| `agenda/` | `agenda_global_screen.dart`, `crear_walkin_screen.dart`, `avisos_screen.dart`, `widgets/cita_admin_card.dart`, `application/agenda_providers.dart` | `FiltrosAgendaNotifier` para fecha + empleado + estado. FAB walk-in. |
| `metricas/` | `metricas_screen.dart`, `widgets/{kpi_card,grafica_estados,grafica_franjas}_widget.dart`, `application/metricas_providers.dart` | 4 KPIs en grid + barras (estados) + líneas (franjas) + 2 ranking cards. Usa `fl_chart`. |

### 3.12 · Frontend — Documentación a actualizar

| Archivo | Cuándo |
|---|---|
| `documentacion/administrador/admin.md` | Cuando añadas un submódulo nuevo o cambies un flujo crítico (cancelación masiva, walk-in, métricas). |
| `documentacion/administrador/api_admin.md` | Cuando añadas, modifiques o elimines un endpoint. |
| `documentacion/administrador/guia_junior_admin.md` | Cuando añadas archivos nuevos o cambies la conexión entre capas. |
| `documentacion/errores.md` | Cada vez que te encuentres un bug que mereció una solución particular (lo agradeceréis tu yo del futuro y los siguientes juniors). |

---

## 4 · Recetas: cómo añadir una funcionalidad nueva

### Recipe A — "Quiero añadir un nuevo servicio al catálogo desde el admin"

Ya existe el flujo. Solo entra en la app:
1. Login admin → pestaña inferior **Servicios** → botón flotante **Nuevo servicio**.
2. Foto (obligatoria) → nombre → descripción → duración → precio.
3. Pulsa "Crear servicio". El backend:
   - Crea fila en `servicio` con `fotoServicio=""`.
   - Audita la acción (`CREAR_SERVICIO`).
   - El segundo paso del frontend sube la foto: `POST /admin/servicios/{id}/foto`.
4. Tras la subida, la foto pasa a `/uploads/servicios/<uuid>.jpg` y se actualiza `foto_servicio` en BD.

### Recipe B — "Quiero cambiar el umbral de avisos (3 → 5 cancelaciones)"

1. Edita `Backend_Victorino/src/main/resources/application.properties`:
   ```
   victorino.avisos.umbral-cancelaciones=5
   ```
2. Reinicia el backend.
3. La consulta `CitaRepository.avisosCancelacionesFrecuentes` lo lee dinámicamente desde `CitaService.umbralCancelaciones` (`@Value`).
4. **No** hace falta tocar el frontend.

### Recipe C — "Quiero testear la cancelación masiva sin esperar a tener citas reales"

```bash
# 1. Login admin y obtén un access token (Swagger, Postman, etc.).
# 2. Inserta citas de prueba con MySQL:
INSERT INTO cita (id_cliente, id_empleado, id_servicio, fecha_cita, hora_inicio_cita, hora_fin_cita, estado_cita)
VALUES (10, 2, 1, '2026-06-01', '10:00:00', '10:30:00', 'CONFIRMADA'),
       (10, 2, 1, '2026-06-02', '11:00:00', '11:30:00', 'CONFIRMADA');

# 3. Llama al endpoint:
curl -X POST http://localhost:8080/api/v1/admin/empleados/2/cancelar-citas \
  -H "Authorization: Bearer <token>"

# 4. Comprobaciones:
SELECT estado_cita FROM cita WHERE id_empleado = 2 AND fecha_cita >= CURDATE();
-- Esperado: todas en CANCELADA_PELUQUERIA.

SELECT * FROM notificacion WHERE id_destinatario_notificacion = 10;
-- Esperado: una fila por cita cancelada.

SELECT * FROM auditoria WHERE accion_auditoria = 'CANCELACION_MASIVA';
-- Esperado: una fila con detalle "Canceladas N citas futuras del empleado ..."
```

---

## 5 · Errores frecuentes y cómo arreglarlos

### `LocaleDataException: Locale data has not been initialized` al abrir la pantalla
- **Causa**: alguien usa `DateFormat.yMMMd('es')` sin haber llamado a `initializeDateFormatting('es_ES')` en el `main.dart`.
- **Fix**: ya está hecho en `lib/main.dart`. Si añades nuevos locales, llama a `initializeDateFormatting('xx_XX')` antes de `runApp`.

### `The function 'StateProvider' isn't defined`
- **Causa**: Riverpod 3.x ha eliminado `StateProvider`.
- **Fix**: usa `Notifier<T>` con `state =` (ver `FiltrosAgendaNotifier` o `RangoFechasNotifier` como referencia).

### `cannot find symbol method setNombreEmpleado` y otros errores en cascada al compilar
- **Causa**: una excepción está como `class` vacía en lugar de extender `RuntimeException`. Lombok deja de procesar las anotaciones cuando algo no compila.
- **Fix**: comprueba siempre que las nuevas excepciones extiendan `RuntimeException`. Mira `EmpleadoNoEncontradoException` como referencia.

### El admin no puede dar de baja a otros empleados
- **Causa**: la cuenta logueada es el admin objetivo. La auto-protección lo bloquea.
- **Fix**: usa otra cuenta admin para dar de baja al admin actual, o desactiva el flag manualmente en la columna `usuario.fecha_eliminacion_usuario`.

### "La peluquería está cerrada (festivo) el ..." al crear walk-in
- **Causa**: ese día tiene fila en `festivo` o cae dentro de `cierre_anual_inicio..cierre_anual_fin`.
- **Fix**: o cambia la fecha del walk-in, o (con permiso) elimina el festivo desde Negocio → sección Festivos.

### `LinkException: Connection refused` en Flutter contra `http://10.0.2.2:8080`
- **Causa**: el backend no está arrancado o estás en iOS / dispositivo físico (10.0.2.2 solo funciona en Android Emulator).
- **Fix**: arranca con `flutter run --dart-define=API_BASE_URL=http://localhost:8080/api/v1` (o la IP de tu máquina en LAN).

### "La barra de navegación queda flotando, quiero que esté pegada abajo"
- **Causa**: estaba envuelta en `SafeArea` con `margin`.
- **Fix**: ya corregido. El widget actual usa `MediaQuery.padding.bottom` para respetar gestos sin separarse del borde.

---

## 6 · Cosas que conviene saber sobre el flujo de datos

### Flujo de un click "Crear empleado"

```
[CrearEditarEmpleadoScreen] usuario rellena formulario y pulsa "Crear empleado"
        │
        ▼
[CrearEditarEmpleadoScreen._guardar()]
        │  empleadoService = ref.read(crearEmpleadoProvider)
        │  empleado = await empleadoService.ejecutar(datos)
        ▼
[CrearEmpleado caso de uso]
        │  valida no-vacíos
        │  return repositorio.crear(datos)
        ▼
[EmpleadoAdminRepositorioImpl.crear()]
        │  POST http://10.0.2.2:8080/api/v1/admin/empleados con JSON
        ▼
[EmpleadoController.crear] (Spring Boot)
        │  @PreAuthorize ADMINISTRADOR
        │  @Valid valida el record
        ▼
[EmpleadoService.crear]
        │  comprueba correo único
        │  encripta pwd con BCrypt
        │  inserta usuario + empleado en MySQL
        │  auditoriaService.registrar('CREAR_EMPLEADO', ...)
        ▼
[EmpleadoMapper.aRespuesta] → JSON
        │
        ▼
HTTP 201 → Dio → DTO.aEntidad() → empleado
        │
        ▼
[CrearEditarEmpleadoScreen._guardar()] continúa:
        │  if (_foto != null) await ref.read(subirFotoEmpleadoProvider).ejecutar(emp.id, _foto!)
        │  context.pop() y notifier.recargar()
        ▼
La lista se refresca y aparece el nuevo empleado.
```

### Por qué la auditoría va en `REQUIRES_NEW`

Imagina que `EmpleadoService.crear` lanza una excepción justo después de insertar el `usuario` pero antes del `empleado`. La transacción principal hace rollback y el `usuario` desaparece — perfecto. Pero **la fila de auditoría también desaparecería** si compartiera transacción, perdiendo la pista del intento. `REQUIRES_NEW` arranca una transacción aparte para la auditoría, que se commitea independientemente.

### Por qué el push FCM aún no funciona

Es un TODO consciente: `FirebaseService.enviarPush` solo loggea por ahora. La tabla `notificacion` se llena correctamente y el cliente verá el aviso al abrir la bandeja in-app (cuando esa pantalla esté implementada). El día que se conecte FCM real (Service Account Key + Firebase Admin SDK), `NotificacionService` ya está preparado para llamarlo sin cambios en sus consumidores.

---

## 7 · Glosario rápido

| Término | Significado en este proyecto |
|---|---|
| **Walk-in** | Cita creada manualmente por admin/empleado para un cliente sin cuenta (`cliente_invitado`). |
| **Baja lógica** | El registro no se borra. Se marca `fecha_eliminacion_*`. Sus citas pasadas se conservan. |
| **Auditoría** | Fila en tabla `auditoria` con `accion`, `entidad`, `idEntidad`, `detalle` y usuario ejecutor. |
| **JOINED inheritance** | Estrategia JPA donde `usuario` y `empleado` comparten id, y cada uno tiene su propia tabla. |
| **REQUIRES_NEW** | Política transaccional Spring: arranca una transacción nueva e independiente, ignorando la actual. |
| **PESSIMISTIC_WRITE** | `SELECT ... FOR UPDATE` en SQL: bloquea las filas hasta el commit, evita carreras. |
| **AsyncNotifier** | Clase Riverpod que gestiona estado asíncrono (`AsyncValue<T>`) y expone métodos para mutar. |
| **Failure** | Sealed class del frontend que representa un error de dominio (`FailureRed`, `FailureValidacion`, etc.). |
| **ApiException** | Excepción Dart que envuelve un `Failure`. Las screens nunca la ven directamente. |
| **GoRouter** | Sistema de rutas declarativas. Aquí montamos un `StatefulShellRoute.indexedStack` para el bottom nav. |

---

¿Algo no encaja? Mira primero `documentacion/errores.md`. Si tu problema no está, **añádelo** después de resolverlo: ese archivo es la memoria viva del proyecto.
