# API de Autenticación — Contratos

> Ruta base: `http://localhost:8080/api/v1`
> Todos los endpoints aceptan/devuelven `application/json` UTF-8.

## POST /auth/registro

Registra un nuevo cliente y deja la sesión iniciada.

### Request

```http
POST /api/v1/auth/registro
Content-Type: application/json

{
  "nombre": "Ana",
  "apellidos": "García López",
  "telefono": "+34 600111222",
  "correo": "ana@victorino.es",
  "password": "Abcd1234"
}
```

Validaciones:
- `nombre`, `apellidos`, `correo`, `password` obligatorios.
- `correo` formato email, máx. 254 caracteres.
- `password`: regex `^(?=.*[A-Z])(?=.*\d).{8,72}$`.
- `telefono` opcional, máx. 20 caracteres.

### Respuesta 201

```json
{
  "accessToken": "eyJhbGciOiJIUzI1NiJ9...",
  "refreshToken": "uVHOj-fjk0lQp...",
  "rol": "CLIENTE",
  "idUsuario": 7,
  "nombreCompleto": "Ana García López",
  "foto": null
}
```

### Errores

**400 Bad Request** (validación):
```json
{
  "timestamp": "2026-05-03T14:00:00Z",
  "status": 400,
  "error": "Bad Request",
  "message": "Los datos enviados no son válidos",
  "path": "/api/v1/auth/registro",
  "fields": [
    {"field": "password",
     "message": "La contraseña debe tener entre 8 y 72 caracteres, al menos una mayúscula y un número"}
  ]
}
```

**409 Conflict** (correo duplicado):
```json
{
  "timestamp": "2026-05-03T14:00:00Z",
  "status": 409,
  "error": "Conflict",
  "message": "Ya existe una cuenta con el correo: ana@victorino.es",
  "path": "/api/v1/auth/registro",
  "fields": []
}
```

### Notas de seguridad

- Se valida con `@Valid` y se rechaza antes de tocar BD.
- BCrypt(cost=10) para hashear la pwd antes del INSERT.
- Genera refresh token y persiste su SHA-256.
- Logueo: solo el correo + idUsuario, nunca la pwd.

---

## POST /auth/login

Login compartido para los tres roles.

### Request

```http
POST /api/v1/auth/login
Content-Type: application/json

{
  "correo": "ana@victorino.es",
  "password": "Abcd1234"
}
```

### Respuesta 200

```json
{
  "accessToken": "eyJhbGciOiJIUzI1NiJ9...",
  "refreshToken": "uVHOj-fjk0lQp...",
  "rol": "CLIENTE",
  "idUsuario": 7,
  "nombreCompleto": "Ana García López",
  "foto": "/uploads/cliente/7.jpg"
}
```

### Errores

**400** mismo formato que registro.

**401 Unauthorized** (correo no existe O pwd incorrecta — mismo mensaje):
```json
{
  "timestamp": "2026-05-03T14:00:00Z",
  "status": 401,
  "error": "Unauthorized",
  "message": "Correo o contraseña incorrectos",
  "path": "/api/v1/auth/login",
  "fields": []
}
```

### Notas de seguridad

- OWASP: el mismo mensaje para "correo no existe" y "pwd incorrecta".
- Filtra por `fecha_eliminacion_usuario IS NULL` (cuentas anonimizadas no pueden volver a entrar).
- Logueo: nivel INFO para fallos de login, WARN solo si hay >5/min del mismo correo (futuro: rate limit).

---

## POST /auth/refresh

Renueva el access token con el refresh existente. **No rota** el refresh.

### Request

```http
POST /api/v1/auth/refresh
Content-Type: application/json

{
  "refreshToken": "uVHOj-fjk0lQp..."
}
```

### Respuesta 200

```json
{
  "accessToken": "eyJhbGciOiJIUzI1NiJ9...nuevo..."
}
```

### Errores

**401 Unauthorized** (refresh inexistente, revocado o caducado):
```json
{
  "timestamp": "2026-05-03T14:00:00Z",
  "status": 401,
  "error": "Unauthorized",
  "message": "Refresh token inválido",
  "path": "/api/v1/auth/refresh",
  "fields": []
}
```

### Notas de seguridad

- El cliente envía el refresh **en claro**; el backend lo hashea con SHA-256 y compara contra `hash_refresh_token`.
- Si el usuario fue eliminado entre la emisión del refresh y el refresh actual, se rechaza.

---

## POST /auth/logout

Revoca el refresh token enviado. Idempotente (si no existe, devuelve 204 igual).

### Request

```http
POST /api/v1/auth/logout
Content-Type: application/json

{
  "refreshToken": "uVHOj-fjk0lQp..."
}
```

(El header `Authorization` no es obligatorio: revocamos por refresh, no por access.)

### Respuesta 204 No Content

Sin cuerpo.

### Errores

**400** si el body no incluye `refreshToken`.

### Notas de seguridad

- Solo se revoca el refresh enviado, no todos los del usuario.
- Para "cerrar TODAS las sesiones" se llama desde el service a `refreshTokenRepository.revocarTodosPorUsuario(idUsuario)` (uso futuro tras cambio de contraseña).

---

## Códigos de error transversales

| Código | Significado | Cuándo ocurre |
|--------|-------------|---------------|
| 400 | Bad Request | Validación de DTO falla |
| 401 | Unauthorized | Credenciales o token inválido |
| 403 | Forbidden | Autenticado pero sin rol suficiente |
| 404 | Not Found | Recurso inexistente |
| 409 | Conflict | Correo duplicado, solape de cita, etc. |
| 500 | Internal Server Error | Error inesperado (loguea stacktrace) |

Estructura del cuerpo de error siempre:

```json
{
  "timestamp": "2026-05-03T14:00:00Z",
  "status": 400,
  "error": "Bad Request",
  "message": "...",
  "path": "/api/v1/...",
  "fields": [{"field": "...", "message": "..."}]
}
```
