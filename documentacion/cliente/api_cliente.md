# API REST — Módulo CLIENTE

> Referencia técnica de todos los endpoints que consume la app del cliente.
> Ruta base: **`http://<host>:8080/api/v1`**.
> Todos los endpoints `/cliente/**` exigen rol `CLIENTE`. El catálogo (`/servicios`, `/empleados`) exige cualquier rol autenticado.

---

## Tabla de contenidos

1. [Convenciones](#1-convenciones)
2. [Autenticación y cabeceras](#2-autenticación-y-cabeceras)
3. [Catálogo público (autenticado)](#3-catálogo-público)
4. [Cliente — Perfil](#4-cliente--perfil)
5. [Cliente — Citas](#5-cliente--citas)
6. [Notificaciones (compartido)](#6-notificaciones-compartido)
7. [Tabla central de errores](#7-tabla-central-de-errores)
8. [Estructura del ApiError](#8-estructura-del-apierror)

---

## 1. Convenciones

- **Cuerpos JSON**: todas las peticiones y respuestas con cuerpo usan `Content-Type: application/json`. Excepción: la subida de foto que usa `multipart/form-data`.
- **Fechas**: formato ISO `YYYY-MM-DD` (sin hora).
- **Horas**: formato ISO `HH:mm:ss`.
- **Importes**: número decimal con 2 decimales (`15.00`).
- **IDs**: enteros largos positivos (`BIGINT UNSIGNED` en BD, `Long` en Java, `int` en Dart).
- **Códigos HTTP**: ver [§7](#7-tabla-central-de-errores).
- **Idioma**: todos los mensajes de error y campos están en español de España.

---

## 2. Autenticación y cabeceras

Todas las llamadas (salvo `/auth/**`) requieren:

```
Authorization: Bearer <access_token>
```

El access token tiene una vida de 15 minutos. Cuando expira, el `RefreshInterceptor` del frontend lo renueva silenciosamente usando 
el refresh token guardado en almacenamiento seguro y reenvía la petición original. El cliente final NO debe gestionar tokens manualmente.

El JWT pone el **id del usuario** como `sub`. Los servicios backend extraen el id con:
```java
Long idCliente = Long.parseLong(authentication.getName());
```

---

## 3. Catálogo público

Visible para CUALQUIER rol autenticado (cliente, empleado o administrador). Sirve listas ligeras pensadas para que el cliente 
decida qué reservar. NO equivalen a `/admin/servicios` y `/admin/empleados`, que devuelven más campos.

### GET `/servicios`

Lista de servicios activos (sin baja lógica), ordenados alfabéticamente por nombre.

**Response** `200 OK`:
```json
[
  {
    "idServicio": 1,
    "nombre": "Corte de pelo",
    "descripcion": "Corte clásico para hombre o mujer.",
    "duracionMinutos": 30,
    "precio": 15.00,
    "fotoUrl": "/uploads/servicios/abc123.jpg"
  },
  {
    "idServicio": 2,
    "nombre": "Tinte completo",
    "descripcion": null,
    "duracionMinutos": 90,
    "precio": 45.00,
    "fotoUrl": "/uploads/servicios/def456.jpg"
  }
]
```

Notas:
- `descripcion` puede ser `null` si el admin no la rellenó.
- `fotoUrl` es **ruta relativa**: el cliente la concatena con `baseUrl` para descargar la imagen.

---

### GET `/empleados`

Empleados activos (sin baja lógica del usuario), ordenados por nombre + apellidos.

**Response** `200 OK`:
```json
[
  {
    "idEmpleado": 7,
    "nombre": "Vito",
    "apellidos": "Corleone",
    "fotoUrl": "/uploads/empleados/vito.jpg"
  },
  {
    "idEmpleado": 11,
    "nombre": "Elena",
    "apellidos": "Ferrante",
    "fotoUrl": "/uploads/empleados/elena.jpg"
  }
]
```

---

## 4. Cliente — Perfil

Endpoints bajo `/cliente/perfil`. Rol exigido: `CLIENTE`.

### GET `/cliente/perfil`

Devuelve los datos del cliente autenticado.

**Response** `200 OK`:
```json
{
  "idCliente": 100,
  "nombre": "Marco",
  "apellidos": "Polo",
  "correo": "marco@x.com",
  "telefono": "600111222",
  "fotoUrl": "/uploads/cliente/abc.jpg",
  "pushActiva": true
}
```

`fotoUrl` y `telefono` pueden ser `null`.

---

### PUT `/cliente/perfil`

Edita los datos personales (nombre, apellidos, correo, teléfono).

**Request body**:
```json
{
  "nombre": "Marco",
  "apellidos": "Polo Lugones",
  "correo": "marco@nuevo.com",
  "telefono": "+34600999888"
}
```

**Response** `200 OK`: el mismo objeto del GET con los datos actualizados.

**Errores**:
- `400` validación si algún campo obligatorio está vacío.
- `409 Conflict` con mensaje `Ya existe un usuario con el correo ...` si el correo nuevo está ocupado por otro usuario.

---

### POST `/cliente/perfil/foto` — multipart

Sube o reemplaza la foto del cliente.

**Request** `multipart/form-data`:
- Campo `foto`: archivo JPG/PNG/WEBP, máx. 5 MB.

**Response** `200 OK`:
```json
{ "fotoUrl": "/uploads/cliente/uuid-nuevo.jpg" }
```

**Errores**:
- `400 Bad Request` si la foto excede 5 MB o el formato no está soportado (`FotoObligatoriaException`).

Tras la subida, la app reemplaza la foto local optimistamente y la próxima recarga del perfil traerá la URL definitiva.

---

### POST `/cliente/perfil/cambiar-pwd`

Cambia la contraseña del cliente.

**Request body**:
```json
{
  "actual": "Pass1234",
  "nueva": "Nueva5678"
}
```

**Response** `204 No Content`.

**Reglas de la nueva contraseña**: entre 8 y 72 caracteres, al menos una mayúscula y un número.

**Errores**:
- `400` validación si la nueva no cumple la regex.
- `409 Conflict` con mensaje `La contraseña actual no es correcta` si la actual no coincide con el hash BCrypt almacenado.

**Efectos secundarios**:
- Todos los refresh tokens del usuario se **revocan** (cierre de sesión en otros dispositivos).
- Se crea una notificación tipo `CONTRASENA_ACTUALIZADA` para el propio cliente.
- Se registra una fila en `auditoria` con `accion = CAMBIAR_PWD_CLIENTE`.

---

### PUT `/cliente/perfil/notificaciones`

Activa o desactiva las notificaciones push.

**Request body**:
```json
{ "pushActiva": true }
```

**Response** `204 No Content`.

**Efecto**: actualiza `cliente.push_activa_cliente`. Las notificaciones in-app se siguen creando siempre; solo se controla si Firebase entrega push al dispositivo.

---

### DELETE `/cliente/perfil`

Elimina la cuenta del cliente. Soft-delete con anonimización RGPD.

**Request body**:
```json
{ "password": "Pass1234" }
```

**Response** `204 No Content`.

**Errores**:
- `409 Conflict` con mensaje `La contraseña actual no es correcta` si la pwd no coincide.

**Efectos secundarios** (transaccionales):
1. Cancelar TODAS las citas futuras con estado `CONFIRMADA` → estado `CANCELADA_PELUQUERIA`. Cada cancelación se hace en una transacción `REQUIRES_NEW` separada para que un fallo aislado no aborte el resto.
2. Notificar a cada empleado afectado con `CANCELACION_CLIENTE` y mensaje especial "cliente eliminado".
3. Anonimizar `cliente`: `nombre = "Cliente eliminado"`, `apellidos = ""`, `telefono = null`, `foto = null`, `push_activa = false`.
4. Anonimizar `usuario`: `correo = "eliminado-{id}@victorino.es"`, contraseña aleatoria, `fecha_eliminacion_usuario = now()`.
5. Revocar todos los `refresh_token` activos del usuario.
6. Borrar todos los `device_token_fcm` del usuario.
7. Borrar físicamente la foto antigua del disco.
8. Registrar en `auditoria` (`accion = ELIMINAR_CUENTA`).

Tras la respuesta 204, el frontend cierra sesión y navega a `/login`.

---

## 5. Cliente — Citas

Endpoints bajo `/cliente/citas`. Rol exigido: `CLIENTE`.

### GET `/cliente/citas`

Lista las citas del cliente. Acepta filtro opcional por estado.

**Query params**:
- `estado` (opcional): uno de `CONFIRMADA`, `EN_PROCESO`, `COMPLETADA`, `CANCELADA_CLIENTE`, `CANCELADA_PELUQUERIA`, `NO_PRESENTADO`. Si se omite, devuelve TODAS.

**Response** `200 OK`:
```json
[
  {
    "idCita": 555,
    "fecha": "2026-05-20",
    "horaInicio": "10:00:00",
    "horaFin": "10:30:00",
    "estado": "CONFIRMADA",
    "nota": null,
    "idEmpleado": 7,
    "nombreEmpleado": "Vito",
    "apellidosEmpleado": "Corleone",
    "fotoEmpleado": "/uploads/empleados/vito.jpg",
    "idServicio": 1,
    "nombreServicio": "Corte de pelo",
    "duracionMinutos": 30,
    "precioServicio": 15.00,
    "fotoServicio": "/uploads/servicios/corte.jpg"
  }
]
```

Ordenadas **descendente por fecha + hora**: las más recientes primero.

---

### GET `/cliente/citas/activa`

Devuelve la cita activa más próxima (`CONFIRMADA` o `EN_PROCESO`) del cliente, dentro de los próximos 30 días.

**Response**:
- `200 OK` con el mismo formato que `/cliente/citas/{id}` si hay cita activa.
- `204 No Content` si no hay.

Lo usa el Home para decidir si pintar la card de próxima cita o el CTA "Reservar ahora".

---

### GET `/cliente/citas/{id}`

Detalle de una cita propia.

**Response** `200 OK`: idéntico al elemento de `GET /cliente/citas`.

**Errores**:
- `404 Not Found` si la cita no existe O no pertenece al cliente autenticado (no diferenciamos para no filtrar info).

---

### GET `/cliente/citas/disponibilidad`

Calcula los huecos disponibles para reservar una cita en una fecha concreta con un servicio concreto.

**Query params**:
- `idServicio` (obligatorio): id del servicio.
- `fecha` (obligatorio): `YYYY-MM-DD`.
- `idEmpleado` (opcional): si se omite o llega como `null`, el modo es **"Cualquiera disponible"** — el backend elige el de menor carga ese día para cada hueco.
- `idCitaExcluir` (opcional): id de la cita que se está modificando. Las citas con ese id NO cuentan como ocupadas (modo edición).

**Response** `200 OK`:
```json
[
  {
    "horaInicio": "10:00:00",
    "horaFin": "10:30:00",
    "idEmpleado": 7,
    "nombreEmpleado": "Vito",
    "fotoEmpleado": "/uploads/empleados/vito.jpg"
  },
  {
    "horaInicio": "10:30:00",
    "horaFin": "11:00:00",
    "idEmpleado": 11,
    "nombreEmpleado": "Elena",
    "fotoEmpleado": "/uploads/empleados/elena.jpg"
  }
]
```

Lista vacía si:
- El día es festivo o cae en cierre anual.
- La peluquería no abre ese día de la semana.
- No hay empleados libres a ninguna hora.

**Errores**:
- `404 Not Found` si el servicio no existe.

---

### POST `/cliente/citas`

Reserva una nueva cita.

**Request body**:
```json
{
  "idServicio": 1,
  "idEmpleado": 7,
  "fecha": "2026-05-20",
  "horaInicio": "10:00:00",
  "nota": "Sin patilla, por favor.",
  "cualquieraDisponible": false
}
```

Campos:
- `idServicio` (obligatorio).
- `idEmpleado` (opcional `null`): si es `null` y `cualquieraDisponible=true`, el backend asigna el peluquero. Si tiene valor concreto, intenta con ese.
- `fecha` (obligatorio): debe estar entre HOY y HOY+30 días.
- `horaInicio` (obligatorio): `HH:mm:ss`.
- `nota` (opcional, máx 280 chars).
- `cualquieraDisponible` (opcional, default `false`): si `true` y el `idEmpleado` propuesto está ocupado al hacer commit, el backend reintenta con otro disponible (**fallback**).

**Response** `201 Created`: el `CitaClienteResponse` recién insertado.

**Errores**:
- `400 Bad Request` validación de campos.
- `404 Not Found` si el servicio o el empleado no existen.
- `409 Conflict` con los códigos enriquecidos del `ApiError.detalles`:
  - `CITA_MISMO_DIA` — el cliente ya tiene cita activa ese día.
  - `CITA_MISMA_SEMANA` — el cliente ya tiene cita activa esa semana ISO.
  - `CITA_MISMO_SERVICIO` — el cliente ya tiene cita activa del mismo servicio.
  - Sin código: `CitaSolapadaException`, `CitaFueraDeAntelacionException`, etc.

**Efectos secundarios**:
- Notificación `CONFIRMACION_RESERVA` al cliente.
- Notificación `NUEVA_CITA_EMPLEADO` al peluquero.
- Fila en `auditoria` con `accion = CREAR_CITA`.

---

### PUT `/cliente/citas/{id}`

Modifica una cita existente. Solo si está en estado `CONFIRMADA`.

**Request body**: mismo formato que `POST /cliente/citas`.

**Response** `200 OK`: el `CitaClienteResponse` actualizado.

**Errores**:
- `404 Not Found` si la cita no existe o no pertenece al cliente.
- `409 Conflict`:
  - `CitaNoModificableException` si el estado no es `CONFIRMADA`.
  - Reglas de solape / antelación / día abierto (las 3 reglas de mismo día/semana/servicio EXCLUYEN la propia cita del cálculo, así que no se disparan por uno mismo).

**Efectos secundarios**:
- Notificación `MODIFICACION_CITA` al peluquero (puede ser distinto al original si se cambió de empleado).
- Fila en `auditoria` con `accion = MODIFICAR_CITA`.

---

### POST `/cliente/citas/{id}/cancelar`

Cancela una cita propia. Solo si está en estado `CONFIRMADA`.

**Request**: sin cuerpo.

**Response** `204 No Content`.

**Errores**:
- `404 Not Found` si la cita no existe o no es del cliente.
- `409 Conflict` con `CitaNoModificableException` si ya está en estado terminal.

**Efectos secundarios**:
- Estado pasa a `CANCELADA_CLIENTE`.
- Notificación `CANCELACION_CLIENTE` al peluquero.
- Fila en `auditoria` con `accion = CANCELAR_CITA`.

---

## 6. Notificaciones (compartido)

### POST `/notificaciones/leer-todas`

Marca como leídas TODAS las notificaciones no leídas del usuario autenticado. Endpoint compartido por **cualquier rol** autenticado (cliente, empleado o administrador).

**Request**: sin cuerpo.

**Response** `204 No Content`.

**Efecto**: actualiza `notificacion.fecha_lectura_notificacion = now()` en todas las filas no leídas del usuario.

---

## 7. Tabla central de errores

| HTTP | Cuándo | Excepción Java | Notas |
|---|---|---|---|
| `400 Bad Request` | Validación de Bean Validation falló (`@NotNull`, `@Size`, etc.) | `MethodArgumentNotValidException` | Devuelve `fields[]` con cada campo erróneo. |
| `400 Bad Request` | Foto vacía / tamaño excedido / formato no soportado | `FotoObligatoriaException` | |
| `401 Unauthorized` | Sin Bearer token o token caducado e irrecuperable | — | El frontend redirige a `/login`. |
| `401 Unauthorized` | Refresh inválido / revocado / caducado | `TokenInvalidoException` | |
| `403 Forbidden` | Usuario autenticado pero rol incorrecto (ej. EMPLEADO en `/cliente/**`) | `AccessDeniedException` | |
| `404 Not Found` | Cita, servicio o empleado inexistente (o no pertenece al cliente) | `RecursoNoEncontradoException` y subclases | |
| `409 Conflict` | Mismo día | `CitaMismoDiaException` | `detalles.codigo = "CITA_MISMO_DIA"` |
| `409 Conflict` | Misma semana | `CitaSemanaDuplicadaException` | `detalles.codigo = "CITA_MISMA_SEMANA"` |
| `409 Conflict` | Mismo servicio activo | `CitaServicioDuplicadoException` | `detalles.codigo = "CITA_MISMO_SERVICIO"` |
| `409 Conflict` | Fecha fuera de antelación (pasada o > 30 días) | `CitaFueraDeAntelacionException` | |
| `409 Conflict` | Solape / fuera de horario / dentro de descanso / día cerrado | `CitaSolapadaException` | |
| `409 Conflict` | Modificar/cancelar cita en estado terminal | `CitaNoModificableException` | |
| `409 Conflict` | Contraseña actual incorrecta | `PasswordIncorrectaException` | |
| `409 Conflict` | Correo duplicado al editar perfil | `CorreoDuplicadoException` | |
| `409 Conflict` | Race condition en escritura (otra transacción se adelantó) | `OptimisticLockException` | Atrapado por el handler genérico. |
| `500 Internal Server Error` | Inesperado | `Exception` | El cliente ve "Ha ocurrido un error inesperado". Detalles en logs del servidor. |
| `500 Internal Server Error` | Peluquería singleton no configurada | `PeluqueriaNoConfiguradaException` | Bug de inicialización — ejecutar `seed.sql`. |

---

## 8. Estructura del `ApiError`

Todas las respuestas de error siguen este formato:

### Sin detalles enriquecidos

```json
{
  "timestamp": "2026-05-16T22:45:12.345Z",
  "status": 409,
  "error": "Conflict",
  "message": "La franja horaria solicitada no está disponible.",
  "path": "/api/v1/cliente/citas",
  "fields": []
}
```

### Con campos de validación

```json
{
  "timestamp": "2026-05-16T22:45:12.345Z",
  "status": 400,
  "error": "Bad Request",
  "message": "Los datos enviados no son válidos",
  "path": "/api/v1/cliente/perfil",
  "fields": [
    { "field": "nombre",  "message": "El nombre es obligatorio" },
    { "field": "correo",  "message": "El correo no es válido" }
  ]
}
```

### Con detalles enriquecidos (409 de cita)

```json
{
  "timestamp": "2026-05-16T22:45:12.345Z",
  "status": 409,
  "error": "Conflict",
  "message": "Ya tienes una cita este día",
  "path": "/api/v1/cliente/citas",
  "fields": [],
  "detalles": {
    "codigo": "CITA_MISMO_DIA",
    "idCitaExistente": 42,
    "fechaCitaExistente": "2026-05-20",
    "horaCitaExistente": "10:00:00",
    "nombreServicioExistente": "Corte de pelo"
  }
}
```

El campo `detalles` se omite del JSON (gracias a `@JsonInclude(NON_NULL)`) cuando no hay payload enriquecido — los clientes antiguos no se rompen.

---

## Ver también

- [cliente.md](cliente.md) — visión general del módulo cliente, reglas de negocio y diagramas.
- [guia_junior_cliente.md](guia_junior_cliente.md) — onboarding archivo por archivo.
- [api_admin.md](../administrador/api_admin.md) — API del módulo admin (complementario).
- [api_auth.md](../auth/api_auth.md) — autenticación y refresh tokens.
