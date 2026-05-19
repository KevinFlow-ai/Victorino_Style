# Módulo CLIENTE — Visión general

> Memoria funcional del módulo del cliente final de Victorino Style.
> Léeme entero antes de tocar las pantallas, los servicios o las reglas de citas del cliente.

---

## 0. Qué es el módulo cliente en una frase

Es **todo lo que ve un cliente desde su móvil** desde que se registra hasta que elimina su cuenta: navegar el catálogo, 
reservar una cita en 4 pasos guiados, ver su próxima cita, cancelarla o modificarla, consultar su historial completo, recibir 
notificaciones y gestionar su perfil. Es el principal "consumidor" del backend, y el corazón comercial del producto.

---

## 1. Submódulos

El módulo cliente está dividido en **4 submódulos** independientes, accesibles desde una barra inferior con 4 pestañas:

| Pestaña | Submódulo | Para qué sirve |
|---|---|---|
| 🏠 Inicio | `home` | Saludo, próxima cita activa (o CTA "Reservar ahora"), servicios destacados, campana de notificaciones |
| 📅 Reservar | `reservar` | Entrada al wizard de 4 pasos. Si ya hay cita activa, muestra bloqueo preventivo |
| 🕘 Historial | `historial` | Lista de todas las citas del cliente con filtros por estado (Todas, Confirmadas, Completadas, Canceladas, No acudiste) |
| 👤 Perfil | `perfil` | Foto, datos personales, cambio de contraseña, cerrar sesión, eliminar cuenta |

Internamente, los 4 submódulos comparten un `shared/` con entidades, DTOs y un repositorio único `CitasClienteRepositorio` que cubre todas las operaciones REST sobre citas. Así no se duplica nada entre Home, Reservar e Historial.

---

## 2. Arquitectura de capas (Clean Architecture)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                                CAPA UI                                       │
│   (Screens, Widgets, Notifiers/AsyncNotifiers — Flutter + Riverpod)         │
│                                                                              │
│   home/      reservar/      historial/      perfil/      shared/widgets/    │
└──────────────────────────────────┬──────────────────────────────────────────┘
                                   │
                                   ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                              CAPA DOMINIO                                    │
│   (Entidades inmutables, contratos de repositorio, casos de uso)            │
│                                                                              │
│   shared/domain/entidades/    *.domain.casos_uso/                           │
│   shared/domain/repositorios/                                                │
└──────────────────────────────────┬──────────────────────────────────────────┘
                                   │
                                   ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                                CAPA DATA                                     │
│   (DTOs espejo del backend, implementaciones HTTP con Dio + ErrorMapper)    │
│                                                                              │
│   shared/data/modelos/    shared/data/repositorios/                         │
└──────────────────────────────────┬──────────────────────────────────────────┘
                                   │
                                   ▼  HTTP (Dio + JWT)
┌─────────────────────────────────────────────────────────────────────────────┐
│                              BACKEND Spring                                  │
│                                                                              │
│   /cliente/citas/*       /cliente/perfil/*       /servicios   /empleados    │
│   /notificaciones/leer-todas                                                 │
└──────────────────────────────────┬──────────────────────────────────────────┘
                                   │
                                   ▼  JPA
                              ┌──────────┐
                              │  MySQL   │
                              └──────────┘
```

**Regla de oro**: la UI nunca conoce DTOs ni endpoints. Solo entidades de dominio + casos de uso. Si un casa de uso devuelve un error, llega como `Failure` (no como `DioException` ni JSON crudo).

---

## 3. Wizard de reserva — el flujo más importante

El wizard guía al cliente en 4 pasos. Cada paso valida lo necesario para habilitar "Siguiente"; el último paso permite "Confirmar reserva":

```
   ┌──────────────────────────────────────────────────────────────────────┐
   │                       WIZARD DE RESERVA                               │
   │                                                                       │
   │  Paso 1: SERVICIO         ◀── Lista vertical de servicios            │
   │      ↓                       (foto + nombre + duración + precio)     │
   │  Paso 2: PELUQUERO        ◀── Grid 2 columnas con foto               │
   │      ↓                       Primera opción: "Cualquiera disponible" │
   │  Paso 3: DÍA Y HORA       ◀── Chips horizontales 30 días             │
   │      ↓                       + Botón "Calendario" (DatePicker)       │
   │      ↓                       + Lista de huecos disponibles           │
   │      ↓                       (en modo "Cualquiera", debajo de cada   │
   │      ↓                        hora aparece el nombre del peluquero)  │
   │  Paso 4: CONFIRMACIÓN     ◀── Resumen + nota opcional                │
   │      ↓                       Botón "Confirmar reserva"               │
   │      ▼                                                                │
   │   POST /cliente/citas                                                 │
   └──────────────────────────────────────────────────────────────────────┘
```

### Modo edición

Cuando el cliente entra al wizard desde "Modificar mi próxima cita" o desde el diálogo de 409 "Modificar esa cita":
- El `WizardNotifier.precargarParaEdicion(...)` rellena los 4 pasos con los valores actuales de la cita.
- El wizard arranca en el **Paso 3** (día y hora) en lugar del Paso 1, porque suele ser lo que se cambia.
- El cliente puede ir hacia atrás y modificar también servicio o peluquero.
- Al confirmar, se llama a `PUT /cliente/citas/{id}` en lugar de `POST /cliente/citas`.

### Modo "Cualquiera disponible"

En el Paso 2, la primera tarjeta es "Cualquiera disponible" (icono shuffle). Si el cliente la elige:
1. En el Paso 3, cada chip de hora muestra debajo el nombre del peluquero que estará libre (lo calcula el backend con la regla "menor carga ese día").
2. El frontend envía `idEmpleado` = el peluquero mostrado + `cualquieraDisponible: true`.
3. Si al hacer commit otro cliente robó la franja con ese peluquero concreto, el backend hace **fallback**: 
busca otro peluquero libre y reserva con él. El cliente recibe la confirmación con el peluquero finalmente asignado.

---

## 4. Reglas de negocio del cliente (CRÍTICAS)

Las **3 reglas combinadas** de citas activas, ordenadas por estrictez:

```
   ┌─────────────────────────────────────────────────────────────────┐
   │ Regla                              │ HTTP │ Código en detalles  │
   ├─────────────────────────────────────────────────────────────────┤
   │ 1 cita activa por DÍA              │ 409  │ CITA_MISMO_DIA      │
   │ 1 cita activa por SEMANA ISO       │ 409  │ CITA_MISMA_SEMANA   │
   │ 1 cita activa por SERVICIO         │ 409  │ CITA_MISMO_SERVICIO │
   └─────────────────────────────────────────────────────────────────┘
```

**Activa** = estado `CONFIRMADA` o `EN_PROCESO`. Una vez `COMPLETADA`/`CANCELADA_*`/`NO_PRESENTADO` ya no cuenta.

**Otras reglas**:
- Antelación: la fecha debe estar entre **HOY** y **HOY + 30 días naturales**.
- Día abierto: no festivo, no cierre anual, dentro del horario semanal de la peluquería.
- Solape: la franja `[hora_inicio, hora_inicio + duracion]` no puede solapar con citas activas del mismo peluquero ni con su descanso fijo.
- Solo se puede **modificar** o **cancelar** citas en estado `CONFIRMADA`.

**Concurrencia**:
- `findActivasEmpleadoFechaParaActualizar` carga las citas activas del peluquero ese día con `@Lock(PESSIMISTIC_WRITE)` antes de insertar o modificar.
- La entidad `Cita` tiene `@Version` como red de seguridad adicional (lock optimista).

---

## 5. Diagrama de secuencia — Reservar una cita

```
Cliente Flutter         WizardNotifier        ReservarCitaRequest       Backend
      │                       │                       │                    │
      │ Paso 1: elige svc     │                       │                    │
      ├──────────────────────►│                       │                    │
      │ Paso 2: elige emp     │                       │                    │
      ├──────────────────────►│                       │                    │
      │ Paso 3: pide huecos                            │                    │
      ├──────────────────────────────────────────────►│ GET /disponibilidad│
      │                                                ├───────────────────►│
      │                                                │ List<Hueco>        │
      │                                                ◄───────────────────┤
      │ Paso 3: elige hora    │                       │                    │
      ├──────────────────────►│                       │                    │
      │ Paso 4: confirma      │                       │                    │
      ├──────────────────────►│ build body            │                    │
      │                       ├──────────────────────►│ POST /cliente/citas│
      │                       │                       ├───────────────────►│
      │                       │                       │                    │ valida 3 reglas
      │                       │                       │                    │ valida solape
      │                       │                       │                    │ inserta Cita
      │                       │                       │                    │ notifica cliente + empleado
      │                       │                       │                    │ audita
      │                       │                       │ 201 CitaCliente    │
      │                       │                       ◄───────────────────┤
      │ snackbar "OK"         ◄──────────────────────┤                    │
      │ refresh próxima cita  │                       │                    │
      │ navega a /cliente/inicio                       │                    │
```

Si el backend devuelve 409 con código `CITA_MISMO_DIA` / `CITA_MISMA_SEMANA` / `CITA_MISMO_SERVICIO`, el wizard muestra `dialogo_cita_existente.dart` con el detalle de la cita ya existente y un botón "Modificar esa cita" que redirige al wizard precargado.

---

## 6. Mapa de archivos (jerarquía)

```
features/cliente/
├── shell/presentation/shell_cliente_screen.dart    Bottom nav + StatefulShellRoute
├── shared/                                          ★ Reusado por home/, reservar/, historial/
│   ├── domain/
│   │   ├── entidades/                              estado_cita, cita_cliente, hueco,
│   │   │                                            datos_reserva, servicio_publico,
│   │   │                                            empleado_publico
│   │   ├── repositorios/                           catalogo_repositorio,
│   │   │                                            citas_cliente_repositorio (7 métodos)
│   │   └── casos_uso/obtener_catalogo.dart         servicios + empleados públicos
│   ├── data/
│   │   ├── modelos/                                DTOs espejo de los records Java
│   │   └── repositorios/                           Implementaciones HTTP con Dio
│   └── application/
│       ├── catalogo_provider.dart                  FutureProviders del catálogo
│       └── citas_cliente_provider.dart             Provider del repo de citas
│
├── home/
│   ├── application/home_providers.dart             AsyncNotifier de próxima cita
│   └── presentation/
│       ├── home_cliente_screen.dart                Pantalla principal
│       └── widgets/
│           ├── cabecera_home.dart                  Saludo + campana con badge
│           ├── card_proxima_cita.dart              Card gradiente con próxima cita
│           ├── card_sin_cita.dart                  CTA "Reservar ahora"
│           ├── servicio_destacado_card.dart        Card del catálogo (vertical)
│           └── bottom_sheet_notificaciones.dart    Sheet de la campana
│
├── reservar/
│   ├── application/
│   │   ├── reservar_providers.dart                 Casos de uso
│   │   └── wizard_notifier.dart                    EstadoWizard (paso + datos)
│   ├── domain/casos_uso/                           obtener_disponibilidad,
│   │                                                crear_cita, modificar_cita,
│   │                                                obtener_cita_activa
│   └── presentation/
│       ├── pestana_reservar_screen.dart            Entrada bottom nav (bloqueo preventivo)
│       ├── wizard_reserva_screen.dart              Contenedor del wizard
│       ├── paso_1_servicio.dart                    Lista vertical
│       ├── paso_2_empleado.dart                    Grid 2 col + "Cualquiera"
│       ├── paso_3_dia_hora.dart                    Chips 30 días + huecos
│       ├── paso_4_confirmar.dart                   Resumen + nota
│       └── widgets/
│           ├── barra_progreso.dart                 4 segmentos
│           └── dialogo_cita_existente.dart         Diálogo 409 contextual
│
├── historial/
│   ├── application/historial_providers.dart        AsyncNotifier con filtro
│   ├── domain/casos_uso/                           obtener_historial,
│   │                                                obtener_detalle_cita,
│   │                                                cancelar_cita
│   └── presentation/
│       ├── historial_screen.dart                   Lista + chips de filtro
│       ├── detalle_cita_screen.dart                Detalle + modificar/cancelar/repetir
│       └── widgets/
│           ├── filtro_estado_chips.dart            Chips de estado
│           └── cita_historial_card.dart            Card de fila
│
└── perfil/
    ├── application/perfil_providers.dart            AsyncNotifier con todos los métodos
    ├── domain/
    │   ├── entidades/perfil_cliente.dart            PerfilCliente + DatosPerfilCliente
    │   ├── repositorios/perfil_repositorio.dart     Contrato
    │   └── casos_uso/                               obtener, editar, foto, pwd,
    │                                                 configurar_push, eliminar
    ├── data/
    │   ├── modelos/perfil_cliente_dto.dart
    │   └── repositorios/perfil_repositorio_impl.dart
    └── presentation/
        ├── perfil_cliente_screen.dart               4 secciones
        └── widgets/dialogo_eliminar_cuenta.dart     Doble confirmación + pwd
```

---

## 7. Notificaciones — quién recibe qué

```
   ┌────────────────────────────────────────────────────────────────────────┐
   │ Acción del cliente              │ Destinatario  │ TipoNotificacion    │
   ├────────────────────────────────────────────────────────────────────────┤
   │ Reservar nueva cita             │ Cliente       │ CONFIRMACION_RESERVA│
   │ Reservar nueva cita             │ Empleado      │ NUEVA_CITA_EMPLEADO │
   │ Modificar cita                  │ Empleado      │ MODIFICACION_CITA   │
   │ Cancelar cita                   │ Empleado      │ CANCELACION_CLIENTE │
   │ Eliminar cuenta                 │ Empleados de  │ CANCELACION_CLIENTE │
   │   (cancela citas futuras)       │   cada cita   │   (texto especial)  │
   ├────────────────────────────────────────────────────────────────────────┤
   │ El scheduler 24h antes          │ Cliente       │ RECORDATORIO_24H    │
   └────────────────────────────────────────────────────────────────────────┘
```

**Reglas de envío** (las gestiona `NotificacionService`):
- **In-app SIEMPRE**: se inserta fila en tabla `notificacion`. La bandeja del usuario siempre se actualiza.
- **Push FCM opcional**: solo si el destinatario lo permite.
  - Cliente → respeta `cliente.push_activa_cliente`.
  - Empleado → respeta `noMolestarEmpleado` y el rango `[silencio_inicio, silencio_fin]`.

El cliente puede activar/desactivar el push desde el **bottom sheet de la campana** del Home (switch "Recibir notificaciones push").

---

## 8. Verificación end-to-end

### Pre-requisitos

1. Backend en `localhost:8080/api/v1` (Swagger en `http://localhost:8080/api/v1/swagger-ui.html`).
2. BD limpia con `schema.sql` aplicado (incluye `MODIFICACION_CITA` en el ENUM de notificaciones).
3. Seed con al menos un servicio activo + un empleado activo + el admin `victorino@admin.com` / `Admin1234!`.
4. Frontend arrancado con `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080/api/v1` (emulador Android).

### Casos de prueba (smoke)

- **TC-CLI-01** — Registro: registrar un cliente nuevo desde `/registro`. Tras éxito, navega automáticamente a `/cliente/inicio`. El Home muestra "No tienes citas pendientes" y los servicios destacados.
- **TC-CLI-02** — Reserva con peluquero concreto: wizard → Paso 1 elige "Corte", Paso 2 elige un peluquero, Paso 3 elige día + hora, Paso 4 confirma. En BD aparece 1 fila en `cita`, 2 filas en `notificacion` (cliente + empleado), 1 fila en `auditoria` con `accion=CREAR_CITA`.
- **TC-CLI-03** — Reserva con "Cualquiera disponible": wizard → Paso 2 "Cualquiera", Paso 3 verifica que cada chip muestra el nombre del peluquero asignado. Confirmar. Estado idéntico a TC-CLI-02 pero con peluquero asignado por el backend.
- **TC-CLI-04** — Regla mismo día: intentar reservar dos citas el mismo día → 409 con código `CITA_MISMO_DIA` y diálogo "Ya tienes una cita el [fecha]". Botón "Modificar esa cita" abre wizard precargado.
- **TC-CLI-05** — Regla misma semana: tener cita el lunes, intentar reservar el viernes → 409 con código `CITA_MISMA_SEMANA`.
- **TC-CLI-06** — Regla mismo servicio: tener corte la próxima semana, intentar reservar otro corte para dentro de 3 semanas → 409 con código `CITA_MISMO_SERVICIO`, mensaje "Ya tienes una cita activa de Corte".
- **TC-CLI-07** — Modificar cita: desde Home pulsar "Modificar" → wizard arranca en Paso 3 con los valores actuales → cambia hora → confirma. En BD: estado sigue `CONFIRMADA`, hora actualizada, notificación `MODIFICACION_CITA` al empleado, auditoría `MODIFICAR_CITA`.
- **TC-CLI-08** — Cancelar cita: desde Home pulsar "Cancelar" → diálogo de confirmación → confirmar. En BD: estado pasa a `CANCELADA_CLIENTE`, notificación `CANCELACION_CLIENTE` al empleado, auditoría `CANCELAR_CITA`.
- **TC-CLI-09** — Historial: ir a la pestaña Historial → ver la cita cancelada. Aplicar filtro "Canceladas" → solo aparece esa.
- **TC-CLI-10** — Repetir cita completada: en el historial, pulsar "Repetir" en una cita completada → abre wizard precargado con servicio + empleado de esa cita.
- **TC-CLI-11** — Subir foto perfil: Perfil → pulsar la foto → galería → seleccionar imagen → recortar (cuadrado) → la foto aparece en cabecera Home y en Perfil.
- **TC-CLI-12** — Cambio de contraseña: Perfil → Seguridad → actual + nueva + repetir → guardar. Backend devuelve 204. En BD `usuario.contrasena_usuario` cambia, `refresh_token` activos del usuario se revocan, fila `notificacion` con tipo `CONTRASENA_ACTUALIZADA`.
- **TC-CLI-13** — Eliminar cuenta: Perfil → Eliminar mi cuenta → doble confirmación + pwd → backend cancela todas las citas futuras (notificando a cada empleado), anonimiza `cliente` y `usuario`, revoca tokens. Frontend cierra sesión y navega a `/login`.
- **TC-CLI-14** — Bottom sheet notificaciones: Home → campana → switch desactivado → reservar otra cita → fila en `notificacion` sí se crea pero `enviada_push_notificacion = false`. Botón "Marcar todas leídas" pone `fecha_lectura_notificacion` en todas.
- **TC-CLI-15** — Festivo: admin añade un festivo → cliente intenta reservar ese día → el chip aparece gris o no aparece y, si llega a confirmar, recibe 409 "peluquería cerrada".
- **TC-CLI-16** — Tiempo real con el admin: admin da de baja a un empleado → cliente hace pull-to-refresh en el Home → ese empleado desaparece del Paso 2 del wizard.
- **TC-CLI-17** — Concurrencia: dos clientes intentan reservar la misma franja con el mismo peluquero (curl simultáneo). Uno recibe 201; el otro recibe 409 `CitaSolapada`. Si el segundo había elegido "Cualquiera", el backend hace fallback y le asigna otro peluquero libre.

---

## 9. 50+ preguntas para no técnicos

> Estas preguntas las puede hacer alguien que no programe (familia, profesor del TFG, tribunal, etc.). Las respuestas usan analogías cotidianas y evitan jerga.

### 1. ¿Qué es el "módulo cliente"?
Es la parte de la aplicación que usa **el cliente final**: la persona que pide cita en la peluquería desde su móvil. Tiene 4 pestañas: Inicio, Reservar, Historial y Perfil.

### 2. ¿Por qué hace falta un wizard en vez de un formulario único?
Porque las decisiones dependen unas de otras. Para enseñar **qué horas hay libres**, primero hace falta saber qué **servicio** quieres (porque un corte 
tarda 30 min y un tinte 90 min) y qué **peluquero** prefieres. Por eso van paso a paso: cada paso "alimenta" al siguiente.

### 3. ¿Qué significa "Cualquiera disponible" en el paso del peluquero?
Que al cliente le da igual quién le atienda con tal de tener cita. El sistema busca automáticamente al peluquero 
con **menos carga ese día** y se lo asigna. Es como decir "el primero que esté libre, gracias".

### 4. ¿Y si dos clientes pulsan "Confirmar" exactamente a la vez para la misma hora?
El servidor usa un **candado** (lock pesimista en la base de datos): la primera petición bloquea la franja, hace la reserva y libera; 
la segunda llega un instante después, ve la franja ocupada y devuelve un error. El cliente bloqueado ve un mensaje "esa hora se acaba de ocupar".

### 5. ¿Qué pasa si tengo una cita el lunes e intento reservar otra el viernes?
El sistema te avisa: "Esta semana ya tienes una cita el lunes a las X". Por defecto solo se permite **una cita activa por semana**. 
Esto evita acumular reservas que luego no cumples.

### 6. ¿Y si quiero reservar otra cita del mismo servicio dentro de un mes?
Tampoco te deja. Mientras tengas una cita de **Corte** activa (sin completar ni cancelar), 
no puedes reservar otra de Corte. Tienes que esperar a que pase la actual o cancelarla.

### 7. ¿Por qué tantas reglas? ¿No es muy estricto?
Son reglas decididas con el dueño de la peluquería para evitar abusos (reservar 5 cortes "por si acaso" y 
luego cancelar 4). Si la peluquería en el futuro quiere relajarlas, basta con cambiar tres líneas en el backend.

### 8. ¿Qué pasa cuando cancelo una cita?
1. El estado de tu cita cambia a "Cancelada por ti".
2. El peluquero recibe automáticamente una notificación: "Tu cliente X ha cancelado su cita del día Y".
3. La franja queda libre para que otro cliente la reserve.

### 9. ¿Puedo cancelar a última hora?
Sí. No hay penalización ni mínimo de antelación. El sistema solo registra la cancelación; 
si un cliente cancela más de 3 veces en 30 días, el panel del admin muestra un aviso.

### 10. ¿Y si quiero MODIFICAR la cita en lugar de cancelarla?
Pulsa "Modificar" desde el Home (en la card de tu próxima cita). Se abre el wizard precargado con tus datos 
actuales y puedes cambiar día, hora, servicio o peluquero. Al guardar, el peluquero recibe una notificación "El cliente X ha modificado su cita".

### 11. ¿Hasta cuándo puedo reservar?
Hasta **30 días naturales** a partir de hoy. Si intentas más allá, el sistema bloquea. Si intentas en el pasado, también.

### 12. ¿Qué es el calendario del Paso 3?
Verás chips horizontales con los próximos 30 días. Si pulsas un día, el sistema pide al backend las horas libres 
con ese servicio + peluquero, y te las muestra como chips. Si prefieres ver un calendario clásico, hay un botón "Calendario" arriba.

### 13. ¿Por qué algunos días no aparecen?
Si la peluquería está **cerrada** ese día (festivo nacional, vacaciones de agosto, día de mantenimiento, etc.), 
el sistema no te lo deja seleccionar. Lo configura el admin desde su panel.

### 14. ¿Cómo recibo las notificaciones?
De dos formas, ambas SIEMPRE en el móvil:
1. **Bandeja in-app**: la lista de mensajes que ves dentro de la app pulsando la campana del Home.
2. **Push FCM** (opcional): mensajes que llegan al móvil incluso con la app cerrada. Puedes activar o desactivar este push con un switch.

### 15. ¿Y si desactivo el push?
Sigues viendo las notificaciones cuando abras la app (bandeja in-app), pero el móvil **no** te suena ni vibra 
cuando está cerrada. La información no se pierde, solo no se hace ruido.

### 16. ¿Qué notificaciones recibo como cliente?
- **Confirmación de reserva**: cuando reservas con éxito.
- **Recordatorio 24h**: el día anterior a tu cita.
- **Cancelación por la peluquería**: si el peluquero se pone enfermo y el admin cancela tus citas.

### 17. ¿Cómo se "olvida" la app de mí si quiero darme de baja?
Pulsas "Eliminar mi cuenta" en el Perfil. El sistema:
1. Te pide confirmación dos veces (para que no sea un accidente).
2. Te pide tu contraseña actual (por si alguien usa tu móvil).
3. Cancela automáticamente todas tus citas futuras y avisa a cada peluquero afectado.
4. **Anonimiza** tus datos: tu nombre pasa a ser "Cliente eliminado", tu correo a "eliminado-123@victorino.es", tu teléfono y foto se borran.
5. Te lleva al login.

### 18. ¿Por qué "anonimiza" en lugar de borrar?
Porque la ley europea de protección de datos (RGPD) exige que las citas pasadas se conserven para el historial del negocio, 
pero **sin datos personales**. Tu fila se queda en la BD para los registros contables, pero ya no se sabe quién eras.

### 19. ¿Por qué me pide la contraseña para eliminar la cuenta?
Para evitar que alguien con tu móvil desbloqueado entre a tu app y elimine tu cuenta sin que te enteres. Sin la pwd, el sistema no procede.

### 20. ¿Qué es eso de "JWT" o "token"?
Un token es una **pulsera virtual** que llevas puesta mientras estás logueado. Cuando inicias sesión, el servidor te da una pulsera; 
tu móvil la enseña en cada petición; el servidor la mira y dice "ah, eres tú, ok". Si cierras sesión, 
te quitas la pulsera y dejas de tener acceso.

### 21. Si cambio de móvil, ¿pierdo mi cuenta?
No. Tu cuenta vive en el servidor. Cuando instalas la app en el móvil nuevo y entras con tu correo y contraseña, todo aparece como estaba: tus citas, tu historial, tu foto.

### 22. ¿Qué es el "Home"?
La pestaña principal. Lo primero que ves al entrar. Tiene:
- Saludo con tu nombre.
- Una campana arriba a la derecha (con un punto rojo si hay novedades).
- Tu próxima cita (o un botón grande "Reservar ahora" si no tienes ninguna).
- Una lista vertical de servicios destacados, con foto y precio.

### 23. ¿Por qué la imagen del servicio en el Home es ancha y la del wizard es pequeña?
Porque en el Home estamos **mostrando el catálogo** como en un menú de restaurante: queremos que 
las fotos llamen la atención. En el wizard estamos **eligiendo rápido** de una lista, 
así que las fotos son miniaturas para que quepa más en pantalla.

### 24. Si el admin cambia la foto de un servicio, ¿lo veo al momento?
No al momento exacto (la app no escucha cambios push del catálogo), 
pero la próxima vez que abras el Home o hagas pull-to-refresh ("tirar hacia abajo para refrescar"), verás la nueva foto.

### 25. ¿Qué pasa en el Historial?
Verás **todas** tus citas, las activas y las terminadas (completadas, canceladas, no presentadas). Hay chips arriba para 
filtrar: "Todas", "Confirmadas", "Completadas", "Canceladas", "No acudiste".

### 26. ¿Qué es "No acudiste"?
Si tenías una cita y no apareciste en el margen de tolerancia, el peluquero la marca manualmente como "no presentado". 
Aparece en tu historial con un chip naranja. No tiene penalización automática, es solo para informar al admin.

### 27. ¿Qué es el botón "Repetir" del historial?
Si una cita ya terminó (completada), puedes pulsar "Repetir" para volver a reservar con 
**el mismo servicio y el mismo peluquero**. El wizard arranca con esos dos pasos rellenados.

### 28. ¿Por qué algunas opciones del wizard están deshabilitadas?
El botón "Siguiente" solo se activa cuando has elegido lo necesario en el paso actual:
- Paso 1: tienes que elegir un servicio.
- Paso 2: tienes que elegir peluquero (o "Cualquiera").
- Paso 3: tienes que elegir día y hora.
- Paso 4: el botón se llama "Confirmar reserva" y se activa solo si los 3 pasos anteriores están completos.

### 29. ¿Qué pasa con la "barra de progreso" del wizard?
Es la línea de colores arriba del wizard. Cada segmento se ilumina cuando ese paso está activo o completado. Te da sensación 
de avance, como en una tienda online cuando te dicen "1. Carrito → 2. Dirección → 3. Pago".

### 30. ¿Qué pasa si pierdo la conexión a mitad del wizard?
Tus elecciones se mantienen **solo mientras la app esté abierta** (el wizard guarda el estado en memoria). Si cierras la app y la 
vuelves a abrir, el wizard arranca limpio. La reserva en sí se envía al servidor solo al pulsar "Confirmar".

### 31. ¿Qué es la "campana" del Home?
Es un icono arriba a la derecha. Cuando lo pulsas se abre un panel desde abajo con:
- Switch para activar/desactivar las notificaciones push.
- Botón "Marcar todas como leídas".
- Lista de tus notificaciones (las no leídas resaltadas en color).

### 32. ¿Por qué a veces me llega una notificación 24h antes de la cita?
Es un recordatorio automático. El servidor tiene un reloj que se ejecuta cada 5 minutos y busca citas que estén exactamente a 
24 horas vista. Si encuentra alguna, te envía "Recuerda: mañana tienes cita a las X".

### 33. ¿Y si el servidor está dormido y pasa la ventana?
Está protegido: aunque el reloj se ejecute 10 minutos tarde, la consulta busca en una ventana amplia y la única regla 
es "si ya te mandé un recordatorio para esa cita, no te lo vuelvo a mandar".

### 34. ¿Qué es eso de "concurrencia"?
Imagina dos clientes que pulsan "Confirmar" en el mismo momento para la misma hora con el mismo peluquero. Sin protección, 
podrían reservar los dos y habría conflicto. El servidor usa un **candado** en la base de datos para que solo uno gane y el otro reciba un error claro.

### 35. ¿Qué es "Riverpod"?
Es el "armario inteligente" de la app: guarda todos los datos que las distintas pantallas necesitan (tu sesión, las citas, 
el catálogo…) y avisa a las pantallas cuando algo cambia. Si reservas una cita, la card "Mi próxima cita" del Home 
se actualiza sola sin que tengas que refrescar.

### 36. ¿Y "Dio"?
Es la "biblioteca" que la app usa para hablar con el servidor. Cada vez que pides huecos, reservas o cambias datos, 
Dio prepara la petición HTTP, le añade tu token, la envía y procesa la respuesta.

### 37. ¿Qué pasa cuando hago "pull-to-refresh"?
Tiras del Home hacia abajo y la app pide al servidor lo más reciente:
- Tu próxima cita (por si la cancelaste desde otro dispositivo).
- El catálogo de servicios (por si el admin añadió algo).
- Las notificaciones (por si entró una nueva).

### 38. ¿Y si el servidor está caído?
La app intenta la llamada, espera unos segundos y, si no responde, te muestra un mensaje suave: "No se pudo cargar, inténtalo de nuevo". No te crashea ni te tira al login.

### 39. ¿Por qué la app a veces me pide la contraseña aunque ya estoy logueado?
Para acciones **delicadas**: cambiar tu contraseña, eliminar la cuenta. Aunque tu sesión esté activa, esas acciones requieren una verificación extra para evitar usos accidentales o maliciosos.

### 40. ¿Cómo guarda la app mi contraseña?
**No la guarda**. Tu contraseña solo viaja al servidor cuando te logueas o la cambias. El servidor la transforma en un 
"código de un solo sentido" (hash BCrypt) y guarda ese código. Ni siquiera el dueño de la peluquería puede ver tu pwd real.

### 41. ¿Y el token? ¿Dónde se guarda?
- El **access token** (corto, 15 min) vive solo en memoria mientras usas la app.
- El **refresh token** (largo, 7 días) se guarda en una zona segura del móvil (Keychain en iOS, KeyStore en Android). No lo verás nunca en ficheros sin cifrar.

### 42. ¿Qué pasa si alguien me roba el móvil?
El acceso a la app requiere el desbloqueo del móvil (huella, PIN, patrón). Si lo desbloquean, podrían usar la 
app hasta que tú cambies la contraseña en otro dispositivo (al cambiarla, todos los tokens existentes se revocan).

### 43. ¿Qué es "soft-delete"?
"Borrar pero no del todo". En lugar de eliminar tu fila de la BD, se le pone una **fecha de eliminación**. Para el 
sistema, dejas de existir; para la contabilidad de la peluquería, tu historial sigue ahí (pero anonimizado).

### 44. ¿Por qué hay 4 secciones en el Perfil?
- **Datos personales**: tus campos editables (nombre, apellidos, correo, teléfono).
- **Seguridad**: cambiar contraseña.
- **Configuración** [se ha quitado en la última iteración]: el switch de notificaciones push se gestiona ahora desde la campana del Home.
- **Cuenta**: cerrar sesión y eliminar cuenta.

### 45. ¿Cómo se hace una foto de perfil "circular"?
La aplicación tiene un **recortador** integrado. Al elegir una foto desde galería o cámara, te aparece una ventana 
donde mueves y ajustas el cuadrado/círculo de recorte. Para el perfil del cliente el recorte está forzado a 
círculo (ratio 1:1). El servidor recibe ya la imagen recortada.

### 46. ¿Pesa mucho una foto subida?
El sistema limita a **5 MB** y solo acepta JPG, PNG o WEBP. La app pre-comprime la imagen tras el recorte para reducirla más.

### 47. ¿Qué pasa si en mitad del wizard me sale "Sin conexión"?
El paso actual se queda como está y aparece un mensaje pidiendo que vuelvas a intentar. No pierdes nada de lo elegido.

### 48. ¿Puedo usar la app sin conexión?
No. La app es 100% **cliente-servidor**: depende de comunicar con el backend para casi todo 
(catálogo, citas, perfil, notificaciones). Es necesario tener internet activo.

### 49. ¿Cuándo se borra el caché?
La app no guarda caché agresiva: cada vez que abres una pestaña, vuelve a preguntar al servidor lo que toca. Solo guarda en 
memoria viva los datos del usuario actual. Al cerrar sesión todo se limpia.

### 50. ¿Qué hace exactamente el botón "Marcar todas como leídas"?
Manda una orden al servidor para que actualice **todas** tus notificaciones no leídas a "leída". El punto rojo de la campana desaparece y los mensajes pierden el resaltado.

### 51. ¿Por qué la app está en español de España y no se puede cambiar?
Es una decisión del proyecto: el público objetivo son clientes españoles y la peluquería es ficticia en Madrid. Por 
eso no hay sistema de idiomas (i18n). Todos los textos, mensajes de error y nombres de campos viven directamente en español dentro del código.

### 52. ¿Puede el cliente saltarse las reglas de citas?
No desde la app. El admin o el empleado SÍ pueden crear "walk-ins" para clientes presenciales saltándose las reglas 
(porque el dueño puede atender excepciones). Pero el cliente desde su móvil siempre pasa por todos los filtros.

### 53. ¿Qué es el "modo edición" del wizard?
Cuando entras al wizard desde "Modificar" en lugar de "Reservar", el sistema sabe que estás cambiando una cita existente. 
Precarga tus elecciones actuales y, al confirmar, llama a un endpoint distinto (`PUT` en lugar de `POST`) que actualiza en lugar de crear.

### 54. ¿Qué pasa si mientras edito mi cita, alguien reserva la nueva hora que estoy eligiendo?
El servidor lo detecta y devuelve un error 409. El wizard te lleva de vuelta al Paso 3 con un mensaje "Esa hora se acaba de ocupar" y te invita a elegir otra.

### 55. ¿Qué es la "auditoría"?
Una "caja negra" del sistema. Cada vez que pasa algo importante (creas, modificas o cancelas una cita, eliminas la cuenta…) 
se anota una fila en la tabla `auditoria` con: quién lo hizo, qué hizo, sobre qué entidad y cuándo. Sirve para investigar problemas o cumplir requisitos legales.

---

## 10. Glosario express

| Término | Significado en cristiano |
|---|---|
| **Backend** | El servidor que vive en `localhost:8080`. Gestiona la base de datos y aplica las reglas. |
| **Frontend** | La app que tienes en el móvil. Es Flutter. |
| **JWT / token** | "Pulsera virtual" que demuestra que estás logueado. |
| **Lock pesimista** | Candado que bloquea filas en la BD para evitar conflictos cuando dos personas hacen algo a la vez. |
| **Push** | Mensaje que llega al móvil aunque la app esté cerrada (lo manda Firebase). |
| **Bandeja in-app** | Lista de mensajes dentro de la app, accesible desde la campana. |
| **RGPD** | Ley europea de protección de datos. Por eso "anonimizamos" en lugar de "borrar". |
| **Walk-in** | Cliente que llega presencialmente sin reserva. El empleado le crea la cita en su panel. |
| **AsyncNotifier** | Un "guardián" que mantiene un trozo de estado (lista, número, objeto) y avisa a las pantallas cuando cambia. |
| **Wizard** | Asistente paso a paso (como los que usabas en programas Windows antiguos). |

---

## Documentos relacionados

- 📖 [api_cliente.md](api_cliente.md) — referencia técnica de TODOS los endpoints del cliente.
- 🛠️ [guia_junior_cliente.md](guia_junior_cliente.md) — onboarding del módulo cliente para alguien que se incorpora al equipo.
- 🔔 [notificaciones.md](../administrador/notificaciones.md) — explicación del subsistema FCM + in-app (común a todos los roles).
- 🐛 [errores.md](../errores.md) — bitácora de incidentes resueltos.
- 📐 [admin.md](../administrador/admin.md) — visión general del módulo admin (complementario a este).
