# API del Administrador — Contratos REST

> Ruta base: `http://localhost:8080/api/v1`
> Todos los endpoints aceptan/devuelven `application/json` UTF-8 salvo los multipart de subida de foto.
> Todos requieren `Authorization: Bearer <accessToken>` con rol `ADMINISTRADOR`. Cualquier otro rol → **403 Forbidden**.
> Errores siempre con el formato `ApiError` (`timestamp`, `status`, `error`, `message`, `path`, `fields`).

---

## EMPLEADOS

### `POST /admin/empleados`
Alta de un empleado. La foto se sube en endpoint separado.

**Request**
```json
{
  "nombre": "Marco",
  "apellidos": "Polo",
  "telefono": "600111222",
  "correo": "marco@victorino.es",
  "passwordProvisional": "Abcdefg1"
}
```

**Validaciones:** `@NotBlank` nombre/apellidos/correo, `@Email`, `@Pattern` de pwd (8-72 chars, mayúscula + dígito).

**Response 201**
```json
{
  "idEmpleado": 12,
  "nombre": "Marco",
  "apellidos": "Polo",
  "correo": "marco@victorino.es",
  "telefono": null,
  "fotoUrl": "",
  "activo": true,
  "rol": "EMPLEADO",
  "esAdministrador": false
}
```

**Errores:** 400 validación · 409 `CorreoDuplicadoException`.

### `GET /admin/empleados?incluirInactivos=false`
Lista de empleados. Si `incluirInactivos=true` incluye también los dados de baja.

**Response 200**: `List<EmpleadoAdminResponse>` (mismo formato que el alta).

### `GET /admin/empleados/{id}`
Detalle de un empleado activo. **404** si no existe o está dado de baja.

### `PUT /admin/empleados/{id}`
Edición. La `passwordProvisional` es opcional: si llega vacía o nula, no se cambia.

### `DELETE /admin/empleados/{id}`
Baja lógica. **204 No Content**. Si el id corresponde al admin actual logueado, **409 Conflict** ("No puedes darte de baja a ti mismo").

### `POST /admin/empleados/{id}/foto` (multipart)
Sube o reemplaza la foto.

**Request**
```http
POST /admin/empleados/12/foto
Content-Type: multipart/form-data; boundary=...

archivo=@foto.jpg
```

**Validaciones:** archivo no vacío, ≤ 5 MB, extensión jpg/jpeg/png/webp.

**Response 200**
```json
{ "fotoUrl": "/uploads/empleados/<uuid>.jpg" }
```

**Errores:** 400 `FotoObligatoriaException`.

### `POST /admin/empleados/{id}/cancelar-citas`
Cancela TODAS las citas futuras CONFIRMADAS del empleado. Cada cita en su transacción independiente; cada cliente notificado in-app + push.

**Response 200**
```json
{
  "idEmpleado": 12,
  "nombreEmpleado": "Marco Polo",
  "citasCanceladas": 8,
  "clientesNotificados": 6,
  "citasOmitidas": 1
}
```

**Errores:** 404 empleado no existe · 409 `NoCitasFuturasCancelablesException`.

---

## SERVICIOS

### `POST /admin/servicios`
**Request**
```json
{
  "nombre": "Tinte completo",
  "descripcion": "Coloración con productos premium",
  "duracionMinutos": 90,
  "precio": 35.00
}
```

**Validaciones:** `@NotBlank` nombre, `@Min(5) @Max(480)` duración, `@DecimalMin("0.01")` precio.

**Response 201**: `ServicioAdminResponse`.

### `GET /admin/servicios?incluirInactivos=false`
Lista de servicios.

### `GET /admin/servicios/{id}`
Detalle.

### `PUT /admin/servicios/{id}`
Edición.

### `DELETE /admin/servicios/{id}`
Baja lógica. **204**.

### `POST /admin/servicios/{id}/foto` (multipart)
Idéntico al de empleados. Carpeta destino `/uploads/servicios/`.

---

## NEGOCIO (horario, descansos, festivos, cierre anual)

### `GET /admin/horario`
Singleton de la peluquería con horario semanal.

**Response 200**
```json
{
  "idPeluqueria": 1,
  "nombre": "Victorino Style",
  "aperturaLunes": "10:00:00", "cierreLunes": "20:00:00",
  "aperturaMartes": "10:00:00", "cierreMartes": "20:00:00",
  ...
  "aperturaDomingo": null, "cierreDomingo": null
}
```

`null` en cualquiera de las dos columnas de un día = día cerrado.

### `PUT /admin/horario`
Mismo body que la respuesta. **500** `PeluqueriaNoConfiguradaException` si no hay fila singleton (problema de inicialización).

### `PUT /admin/empleados/{id}/descanso`
**Request**
```json
{ "horaInicio": "14:00:00", "duracionMinutos": 30 }
```

**Validaciones:** `@Min(10) @Max(120)` duración.

**Response 200**
```json
{
  "idEmpleado": 12,
  "nombreEmpleado": "Marco Polo",
  "horaInicio": "14:00:00",
  "duracionMinutos": 30
}
```

**Errores:** 404 si el empleado no existe.

### `GET /admin/festivos`
Lista cronológica.

**Response 200**
```json
[
  {
    "idFestivo": 5,
    "fecha": "2026-12-25",
    "descripcion": "Navidad",
    "tipo": "NACIONAL"
  }
]
```

### `POST /admin/festivos`
**Request**
```json
{ "fecha": "2026-05-01", "descripcion": "Día del Trabajo", "tipo": "NACIONAL" }
```

**Errores:** 409 `FestivoDuplicadoException` si ya existe un festivo con esa fecha.

### `DELETE /admin/festivos/{id}`
**204**. **404** si no existe.

### `GET /admin/cierre-anual`
**Response 200**
```json
{ "fechaInicio": "2026-08-01", "fechaFin": "2026-08-31" }
```
Ambos pueden ser `null` si no hay cierre programado.

### `PUT /admin/cierre-anual`
**Errores:** 400 `IllegalArgumentException` si `fechaFin < fechaInicio`.

---

## AGENDA, WALK-IN, HISTORIAL Y AVISOS

### `GET /admin/agenda?desde=YYYY-MM-DD&hasta=YYYY-MM-DD&empleadoId=&estado=`
Citas en el rango. Filtros opcionales por empleado y estado.

**Response 200**
```json
[
  {
    "idCita": 42,
    "fecha": "2026-05-15",
    "horaInicio": "10:00:00",
    "horaFin": "10:30:00",
    "estado": "CONFIRMADA",
    "nota": "Solicita corte degradado",
    "idCliente": 100,
    "nombreCliente": "Andrés Lozano",
    "esInvitado": false,
    "idEmpleado": 2,
    "nombreEmpleado": "Vito Corleone",
    "fotoEmpleado": "/uploads/empleados/admin.jpg",
    "idServicio": 1,
    "nombreServicio": "Corte clásico",
    "duracionMinutos": 30,
    "precioServicio": 15.00
  }
]
```

### `GET /admin/clientes/{id}/historial`
Historial completo del cliente. Incluye sus citas en cualquier estado, ordenadas desc.

**Response 200**
```json
{
  "idCliente": 100,
  "nombreCompleto": "Andrés Lozano",
  "correo": "andres@example.com",
  "telefono": "600111222",
  "fotoUrl": null,
  "cuentaActiva": true,
  "totalCitas": 12,
  "citas": [ /* List<CitaAdminResponse> */ ]
}
```

### `POST /admin/citas/walk-in`
Crea una cita manual. XOR cliente registrado / invitado.

**Request — walk-in**
```json
{
  "idEmpleado": 2,
  "idServicio": 1,
  "fecha": "2026-05-15",
  "horaInicio": "16:00:00",
  "nombreInvitado": "Pedro",
  "apellidosInvitado": "García",
  "telefonoInvitado": "+34 600999888",
  "nota": "Camina sin cita"
}
```

**Request — cliente registrado**
```json
{
  "idEmpleado": 2,
  "idServicio": 1,
  "fecha": "2026-05-15",
  "horaInicio": "16:00:00",
  "idCliente": 100
}
```

**Validación XOR**: si llegan ambos o ninguno → 400 con mensaje:
> "Debe indicarse un cliente registrado o los datos de un invitado, pero no ambos"

**Otros errores 409:**
- "La peluquería está cerrada (festivo) el …"
- "La peluquería está cerrada (vacaciones) el …"
- "La franja queda fuera del horario de apertura."
- "El empleado descansa en esa franja."
- "El empleado ya tiene una cita en esa franja."

**Response 201**: `CitaAdminResponse`.

### `GET /admin/avisos/cancelaciones-frecuentes`
Clientes con más de **3** cancelaciones en los últimos **30 días** (umbral configurable en `application.properties`).

**Response 200**
```json
[
  {
    "idCliente": 100,
    "nombreCompleto": "Andrés Lozano",
    "correo": "andres@example.com",
    "cancelacionesUltimos30Dias": 5
  }
]
```

---

## MÉTRICAS

### `GET /admin/metricas/resumen?fechaInicio=YYYY-MM-DD&fechaFin=YYYY-MM-DD`
Devuelve KPIs y series para el panel de estadísticas.

**Response 200**
```json
{
  "totalCitas": 120,
  "citasCompletadas": 95,
  "citasCanceladas": 18,
  "citasNoPresentado": 7,
  "tasaAsistencia": 93.13,
  "servicioMasSolicitado": {
    "idServicio": 1,
    "nombre": "Corte clásico",
    "reservas": 45
  },
  "empleadoMasReservado": {
    "idEmpleado": 2,
    "nombre": "Vito Corleone",
    "citasAtendidas": 60
  },
  "distribucionPorDiaSemana": [
    { "dia": "MONDAY", "citas": 18 },
    { "dia": "TUESDAY", "citas": 22 }
  ],
  "distribucionPorFranjaHoraria": [
    { "horaInicio": "09:00", "citas": 4 },
    { "horaInicio": "10:00", "citas": 12 }
  ]
}
```

**Cálculo:** todas las cifras provienen de `@Query` JPQL con agregaciones (`COUNT`, `GROUP BY`, `FUNCTION HOUR/DAYOFWEEK`). No se cargan entidades en memoria.

---

## Tabla de errores

| HTTP | Excepción | Cuándo |
|---|---|---|
| **400** | `MethodArgumentNotValidException` | Validaciones de Bean Validation (campos en `fields`) |
| **400** | `FotoObligatoriaException` | Multipart vacío / extensión no soportada / archivo > 5 MB |
| **400** | `IllegalArgumentException` | Reglas de coherencia (ej. `fechaFin < fechaInicio`) |
| **401** | `CredencialesInvalidasException` / `TokenInvalidoException` | Sin auth o token caducado/revocado |
| **403** | `AccessDeniedException` | Rol distinto a ADMINISTRADOR |
| **404** | `EmpleadoNoEncontradoException` / `ServicioNoEncontradoException` / `RecursoNoEncontradoException` | Recurso inexistente o eliminado |
| **409** | `CorreoDuplicadoException` | Alta o edición con correo ya en uso |
| **409** | `FestivoDuplicadoException` | Festivo con la misma fecha |
| **409** | `CitaSolapadaException` | Walk-in fuera de horario / con descanso / con otra cita |
| **409** | `CitaNoModificableException` | Cita en estado terminal |
| **409** | `NoCitasFuturasCancelablesException` | Cancelación masiva sin citas que cancelar |
| **500** | `PeluqueriaNoConfiguradaException` | Singleton de `peluqueria` ausente — falta seed |
