# Módulo Administrador — Resumen funcional y arquitectura

> Panel completo del rol **ADMINISTRADOR**. Cubre los 5 submódulos del CLAUDE.md: empleados, servicios, configuración del negocio (horario / descansos / festivos / cierre anual), agenda global con walk-in y métricas. Toda la lógica vive bajo `/api/v1/admin/...` en el backend y `lib/features/administrador/...` en el frontend.

## 1 · Submódulos

| Pestaña inferior | Pantalla principal | Endpoints (`/api/v1/admin/...`) |
|---|---|---|
| **Agenda** (inicial) | `AgendaGlobalScreen` | `GET /agenda`, `POST /citas/walk-in`, `GET /clientes/{id}/historial`, `GET /avisos/cancelaciones-frecuentes` |
| **Estadísticas** | `MetricasScreen` | `GET /metricas/resumen` |
| **Empleados** | `ListaEmpleadosScreen` | `GET/POST/PUT/DELETE /empleados[/{id}]`, `POST /empleados/{id}/foto`, `POST /empleados/{id}/cancelar-citas` |
| **Servicios** | `ListaServiciosScreen` | `GET/POST/PUT/DELETE /servicios[/{id}]`, `POST /servicios/{id}/foto` |
| **Negocio** | `NegocioScreen` (5 secciones) | `GET/PUT /horario`, `PUT /empleados/{id}/descanso`, `GET/POST/DELETE /festivos[/{id}]`, `GET/PUT /cierre-anual` |

## 2 · Arquitectura por capas

```
                ┌───────────────────────────────────────────────────────┐
                │             Frontend Flutter (Clean Arch)             │
                │                                                       │
   UI  ─►  Notifier (Riverpod AsyncNotifier)  ─►  Caso de uso  ─►  Repo │
                │                                              │        │
                └──────────────────────────────────────────────│────────┘
                                                               ▼
                                                            Dio (HTTP)
                                                               │
                                                               ▼
   ┌───────────────────────────────────────────────────────────────────┐
   │                      Backend Spring Boot                          │
   │                                                                   │
   │ Controller (REST + @PreAuthorize)                                 │
   │      │                                                            │
   │      ▼                                                            │
   │ Service (lógica de negocio + @Transactional + AuditoriaService)   │
   │      │                                                            │
   │      ├──►  Mapper  ──►  DTO ────────────────────► JSON al cliente │
   │      │                                                            │
   │      └──►  Repository (Spring Data JPA + @Query)                  │
   │                              │                                    │
   └──────────────────────────────│────────────────────────────────────┘
                                  ▼
                         ┌──────────────────────────┐
                         │     MySQL 8.0.46         │
                         │ usuario · empleado · cita│
                         │ servicio · peluqueria    │
                         │ horario_empleado·festivo │
                         │ notificacion · auditoria │
                         └──────────────────────────┘

   Notificaciones:
   NotificacionService ─► fila in-app en `notificacion`        (siempre)
                       └► FirebaseService.enviarPush  (TODO FCM, según preferencias)
```

## 3 · Diagrama de secuencia: cancelación masiva de citas

Es el flujo más crítico del módulo. Reúne lock pesimista, transacciones independientes por cita, notificación in-app y auditoría.

```
   Admin       UI            Notifier       Caso de uso     Repo HTTP   |   Controller    Service           CitaRepo   NotificacionService    AuditoriaService    BD
    │           │               │              │              │         |       │            │                  │              │                    │              │
    │ click "Cancelar todas"    │              │              │         |       │            │                  │              │                    │              │
    │──────────►│               │              │              │         |       │            │                  │              │                    │              │
    │           │ ejecutar(id)  │              │              │         |       │            │                  │              │                    │              │
    │           │──────────────►│              │              │         |       │            │                  │              │                    │              │
    │           │               │ ejecutar(id) │              │         |       │            │                  │              │                    │              │
    │           │               │─────────────►│              │         |       │            │                  │              │                    │              │
    │           │               │              │ POST /admin/empleados/{id}/cancelar-citas    │                  │              │                    │              │
    │           │               │              │─────────────►│─────────────────►│            │                  │              │                    │              │
    │           │               │              │              │         |       │ cancelarFuturasDelEmpleado    │              │                    │              │
    │           │               │              │              │         |       │───────────►│                  │              │                    │              │
    │           │               │              │              │         |       │            │ findActivoById   │              │                    │              │
    │           │               │              │              │         |       │            │─────────────────►│              │                    │              │
    │           │               │              │              │         |       │            │ findCitasFuturasParaCancelar (LOCK PESIMISTA)        │              │
    │           │               │              │              │         |       │            │─────────────────►│              │                    │              │
    │           │               │              │              │         |       │            │                  │              │                    │              │
    │           │               │              │              │         |       │            │ ┌─ por cada cita ─┐                                                  │
    │           │               │              │              │         |       │            │ │ cancelarUnaCita(id) (REQUIRES_NEW)                               │
    │           │               │              │              │         |       │            │ │   findByIdParaActualizar (LOCK)                                  │
    │           │               │              │              │         |       │            │ │   estadoCita = CANCELADA_PELUQUERIA                              │
    │           │               │              │              │         |       │            │ │   save                                                           │
    │           │               │              │              │         |       │            │ │   crearNotificacion(CANCELACION_PELUQUERIA) ───►  fila + push    │
    │           │               │              │              │         |       │            │ └─ commit/rollback de la cita ─┘                                   │
    │           │               │              │              │         |       │            │                  │              │                    │              │
    │           │               │              │              │         |       │            │ registrar(CANCELACION_MASIVA, EMPLEADO, idEmpleado, detalle)        │
    │           │               │              │              │         |       │            │──────────────────────────────────────────────────────►│              │
    │           │               │              │              │         |       │            │ {citasCanceladas, clientesNotificados, omitidas}                    │
    │           │ snackbar resumen ◄────────────◄─────────────◄─────────────────────────────◄│                                                                      │
```

**Garantías clave:**
- Cada cita se cancela en su **propia transacción** (`@Transactional(propagation = REQUIRES_NEW)`). Si una falla, el resto continúa.
- Se usa **lock pesimista** (`@Lock(LockModeType.PESSIMISTIC_WRITE)`) en `findCitasFuturasParaCancelar` y `findByIdParaActualizar` para evitar carreras con cancelaciones simultáneas del cliente.
- El `Set<Long>` de `clientesNotificados` deduplica: dos citas del mismo cliente cuentan como **1 cliente** notificado.
- Las citas walk-in (cliente invitado, sin `Usuario`) se cancelan pero NO suman al contador (no hay a quién notificar).

## 4 · Reglas de negocio implementadas

| Regla del CLAUDE.md | Dónde vive |
|---|---|
| Baja lógica siempre (nunca DELETE físico) | `EmpleadoService.darBaja`, `ServicioService.darBaja` |
| Foto obligatoria empleado/servicio | `FileStorageService` + 400 `FotoObligatoriaException` |
| El admin no puede darse de baja a sí mismo | `EmpleadoService.darBaja` (compara con `SecurityContextHolder`) |
| Auditoría de toda escritura sensible | `AuditoriaService.registrar` (REQUIRES_NEW) en cada Service |
| Concurrencia en cancelación masiva | `CancelacionMasivaService` con REQUIRES_NEW + PESSIMISTIC_WRITE |
| Festivos y cierre anual bloquean huecos | `CitaService.validarDisponibilidad` |
| `hora_fin = hora_inicio + duracion_servicio` | `CitaService.crearWalkIn` |
| Métricas con `@Query` JPQL (sin cargar entidades) | `CitaRepository.contarPorEstado / ranking* / distribucion*` + `MetricaService` |
| Avisos > 3 cancelaciones / 30 días | `CitaRepository.avisosCancelacionesFrecuentes` (HAVING > umbral) |
| Endpoints solo accesibles a `ROLE_ADMINISTRADOR` | `SecurityConfig` (`/admin/**`) + `@PreAuthorize` en cada controller |

## 5 · Cómo añadir una nueva acción admin (recipe)

1. **DTO**: añade un nuevo record en `dto/admin/`. Decora con Bean Validation.
2. **Repository**: si la consulta no es CRUD básica, añade `@Query` JPQL.
3. **Service**: nueva entrada en el service correspondiente; envuelve en `@Transactional`; llama a `auditoriaService.registrar(...)` si es escritura.
4. **Mapper**: si tu DTO es de salida y necesita combinar varias entidades, añade método al mapper.
5. **Controller**: nuevo método REST con `@PreAuthorize("hasRole('ADMINISTRADOR')")`.
6. **Test**: añade caso happy + edge en el test correspondiente.
7. **Frontend**: en este orden — entidad de dominio → repositorio (interfaz + impl HTTP) → caso de uso → provider → screen.
8. **Documentación**: actualiza `api_admin.md` con el endpoint nuevo.

## 6 · Verificación end-to-end

### Backend
```bash
cd Backend_Victorino
./mvnw clean install          # ejecuta los 51 tests unitarios
./mvnw spring-boot:run        # arranca en localhost:8080, contexto /api/v1
# Swagger: http://localhost:8080/api/v1/swagger-ui.html
```

### Frontend
```bash
cd frontend_victorino
flutter pub get
flutter analyze
flutter run -d <device>       # login con victorino@admin.com / Admin1234!
```

### Smoke test crítico (cancelación masiva)
1. Login admin → Negocio → Incidencias de plantilla → selecciona empleado → "Cancelar todas".
2. Verificar en BD: `SELECT estado_cita FROM cita WHERE id_empleado = ?` → todas `CANCELADA_PELUQUERIA`.
3. Verificar `SELECT * FROM notificacion WHERE id_destinatario_notificacion IN (...)` → fila por cliente.
4. Verificar `SELECT * FROM auditoria WHERE accion_auditoria = 'CANCELACION_MASIVA'`.
