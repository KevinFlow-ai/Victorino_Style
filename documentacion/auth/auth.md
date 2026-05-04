# Autenticación — Victorino Style

> Documento principal del módulo de autenticación.
> Última actualización: 2026-05-03.

## 1. Resumen funcional

El módulo de autenticación cubre cuatro operaciones:

1. **Registro de cliente** (`POST /auth/registro`). Crea fila en `usuario` (rol=`CLIENTE`) y en `cliente`, y devuelve los tokens. El cliente queda logueado tras registrarse.
2. **Login compartido** (`POST /auth/login`). Funciona igual para `CLIENTE`, `EMPLEADO` y `ADMINISTRADOR`. El backend devuelve el rol y la app navega a la home correspondiente.
3. **Refresh silencioso** (`POST /auth/refresh`). Renueva el access token cada ~15 min sin que el usuario note nada.
4. **Logout** (`POST /auth/logout`). Marca el refresh token como revocado en BD; la sesión local se borra.

### Lo que ve el usuario

- **Splash** (600 ms con logo). Si ya hay refresh en disco intenta restaurar la sesión.
- **Pantalla de login** con tarjeta blanca, logo, dos campos (correo + pwd), botón con loader, link a registro y link a recuperación.
- **Pantalla de registro** con seis campos (nombre, apellidos, teléfono opcional, correo, pwd, confirmar pwd), checkbox RGPD, botón con loader.
- **Home placeholder** según rol. Cada home tiene un botón de logout en la AppBar.

### Reglas de negocio aplicadas

- Política de contraseña: 8–72 caracteres, ≥1 mayúscula, ≥1 número.
- Mensaje de login fallido genérico (OWASP): «Correo o contraseña incorrectos» tanto si el correo no existe como si la pwd no coincide.
- Solo se registran **clientes** desde la app. Empleados y admin los crea el administrador en otra pantalla (fuera de este módulo).
- BCrypt cost 10 para todas las contraseñas.
- Refresh token 7 días, access token 15 minutos.
- Refresh token persistido en BD como SHA-256 hex (64 caracteres). Nunca en claro.

## 2. Arquitectura de capas

### Backend (Spring Boot · capas clásicas)

```
┌──────────────────────────────────────────────────────────┐
│  AuthController  (REST, valida @Valid, delega)           │
└────────────┬─────────────────────────────────────────────┘
             │
┌────────────▼─────────────────────────────────────────────┐
│  AuthService     (lógica de negocio: registro, login,    │
│                   refresh, logout, BCrypt, transacciones)│
└────────────┬─────────────────────────────────────────────┘
             │
   ┌─────────┼─────────────┬───────────────────────────┐
   ▼         ▼             ▼                           ▼
┌──────┐ ┌────────┐ ┌──────────────┐ ┌─────────────────────┐
│Usuario│ │Cliente │ │RefreshToken  │ │ JwtService           │
│Repo  │ │Repo    │ │Repo          │ │ (genera+valida JWT)  │
└──┬───┘ └───┬────┘ └──────┬───────┘ └─────────┬───────────┘
   │         │             │                    │
   ▼         ▼             ▼                    ▼
┌──────────────────────────────────────────────────────────┐
│                       MySQL 8                            │
│  usuario · cliente · refresh_token (+ resto)             │
└──────────────────────────────────────────────────────────┘
```

Filtro JWT global: cualquier petición con `Authorization: Bearer <jwt>` pasa
por `JwtAuthenticationFilter`, que valida la firma y deja un `Authentication`
en el `SecurityContextHolder` con `ROLE_<rol>`.

### Frontend (Flutter · Clean Architecture)

```
┌───────────────────────────────────────────────────────────┐
│  Presentation                                             │
│   - LoginScreen / RegistroScreen / Splash / Homes         │
│   - GoRouter con redirect según sesión + rol              │
└────────────────────────┬──────────────────────────────────┘
                         │
┌────────────────────────▼──────────────────────────────────┐
│  Application (Notifiers Riverpod)                         │
│   - LoginNotifier · RegistroNotifier                      │
│   - SesionNotifier (estado global)                        │
└────────────────────────┬──────────────────────────────────┘
                         │
┌────────────────────────▼──────────────────────────────────┐
│  Domain                                                   │
│   - IniciarSesion · RegistrarCliente (casos de uso)       │
│   - AuthRepositorio (interfaz)                            │
└────────────────────────┬──────────────────────────────────┘
                         │
┌────────────────────────▼──────────────────────────────────┐
│  Data                                                     │
│   - AuthRepositorioImpl (Dio)                             │
│   - AuthResponseDto (fromJson)                            │
└────────────────────────┬──────────────────────────────────┘
                         │
                         ▼
                ┌─────────────────┐
                │  HTTP /api/v1   │
                └─────────────────┘
```

`Dio` lleva dos interceptores:
- **JwtInterceptor** añade `Authorization: Bearer <access>` excepto en rutas `/auth/*`.
- **RefreshInterceptor** detecta 401, llama a `/auth/refresh` con bloqueo (Completer) y reintenta la petición original.

## 3. Diagramas de secuencia

### LOGIN (caso feliz)

```
Cliente Flutter           Backend Spring          MySQL
│                          │                       │
│ POST /auth/login         │                       │
├─────────────────────────>│                       │
│ {correo, password}       │                       │
│                          │ findByCorreoUsuario   │
│                          ├──────────────────────>│
│                          │<──────────────────────┤
│                          │ BCrypt.matches        │
│                          │ generarAccessToken    │
│                          │ generarRefreshOpaco   │
│                          │ INSERT refresh_token  │
│                          │  (hash SHA-256)       │
│                          ├──────────────────────>│
│ 200 OK                   │                       │
│<─────────────────────────┤                       │
│ {access, refresh, rol,   │                       │
│  idUsuario, nombre, foto}│                       │
│ guarda refresh+id+rol    │                       │
│ en flutter_secure_storage│                       │
│ context.go(rutaSegunRol) │                       │
```

### LOGIN (credenciales incorrectas)

```
Cliente                   Backend                 MySQL
│ POST /auth/login        │                       │
├────────────────────────>│ findByCorreoUsuario   │
│                         ├──────────────────────>│
│                         │<──────────────────────┤ (Optional.empty
│                         │                       │  o pwd no match)
│                         │ throw                 │
│                         │ CredencialesInvalidas │
│ 401 Unauthorized        │                       │
│<────────────────────────┤                       │
│ {message: "Correo o     │                       │
│  contraseña incorrectos"│                       │
│ ErrorMapper → Failure   │                       │
│ Credenciales            │                       │
│ SnackBar rojo           │                       │
```

### REGISTRO

```
Cliente                  Backend                  MySQL
│ POST /auth/registro    │                        │
├───────────────────────>│ existsByCorreoUsuario  │
│ {nombre, apellidos,    ├───────────────────────>│
│  telefono?, correo,    │<───────────────────────┤ (false)
│  password}             │                        │
│                        │ BCrypt.encode(pwd)     │
│                        │ INSERT usuario         │
│                        ├───────────────────────>│
│                        │<───────────────────────┤ id_usuario=N
│                        │ INSERT cliente         │
│                        │  (id_cliente == N)     │
│                        ├───────────────────────>│
│                        │ INSERT refresh_token   │
│                        ├───────────────────────>│
│ 201 Created            │                        │
│<───────────────────────┤                        │
│ {access, refresh, ...} │                        │
│ context.go(/cliente/   │                        │
│  home)                 │                        │
```

### REFRESH SILENCIOSO

```
Cliente Flutter (interceptor)       Backend                  MySQL
│ GET /citas/mias                   │                        │
├──────────────────────────────────>│                        │
│ Authorization: Bearer <expirado>  │ Filtro JWT → 401       │
│ 401                               │                        │
│<──────────────────────────────────┤                        │
│ RefreshInterceptor.onError        │                        │
│ POST /auth/refresh                │ SHA-256 + busca activo │
├──────────────────────────────────>├───────────────────────>│
│ {refreshToken}                    │<───────────────────────┤
│                                   │ valida no caducado     │
│                                   │ generaAccessToken      │
│ 200 {accessToken: nuevo}          │                        │
│<──────────────────────────────────┤                        │
│ actualiza access en memoria       │                        │
│ reintenta GET /citas/mias         │                        │
├──────────────────────────────────>│                        │
│ Authorization: Bearer <nuevo>     │                        │
│ 200 OK                            │                        │
│<──────────────────────────────────┤                        │
```

## 4. Detalle de cada endpoint

Ver `api_auth.md` para los contratos exactos (request, response y errores).

Resumen rápido:

| Endpoint | Método | Auth | 2xx | 4xx |
|----------|--------|------|-----|-----|
| `/auth/registro` | POST | público | 201 + AuthResponse | 400, 409 |
| `/auth/login` | POST | público | 200 + AuthResponse | 400, 401 |
| `/auth/refresh` | POST | público | 200 + RefreshResponse | 401 |
| `/auth/logout` | POST | público (con refresh) | 204 | — (idempotente) |

## 5. Manejo de tokens

| Token | Dónde se guarda | TTL | Cómo se revoca |
|-------|-----------------|-----|----------------|
| Access JWT | Memoria del cliente (Riverpod) | 15 min | No se revoca; se deja caducar |
| Refresh opaco (32 bytes base64) | `flutter_secure_storage` (cliente) y SHA-256 hex en BD | 7 días | `/auth/logout` o admin via SQL |

**Por qué el refresh va hasheado en BD**: si la base de datos se filtra, los hashes SHA-256 sin sal no permiten al atacante autenticarse — el refresh original es irrecuperable a partir del hash.

**Por qué el access vive solo en memoria**: minimiza la ventana de robo. Si la app se cierra, el access se pierde y se obtiene uno nuevo via refresh al volver.

## 6. Seguridad aplicada

- **BCrypt cost 10** para `contrasena_usuario` (64 chars).
- **HS256** para firmar el JWT con secreto base64 ≥256 bits.
- **SHA-256 hex** del refresh antes de persistir.
- **Sesión stateless**: sin JSESSIONID, sin CSRF.
- **CORS** abierto a `localhost:*` solo en dev.
- **Mensaje genérico** en login fallido (OWASP Authentication Cheat Sheet).
- **Soft-delete**: el login filtra por `fecha_eliminacion_usuario IS NULL`.
- **Validación con Bean Validation** en TODOS los DTO de entrada.
- **Lock pesimista** en `CitaService` para concurrencia (no aplica aquí, pero el pattern es uniforme).

## 7. Guía para desarrolladores junior

### Cambiar la duración de los tokens

`Backend_Victorino/src/main/resources/application.properties`:
```
victorino.jwt.access-ttl=PT30M     # 30 min
victorino.jwt.refresh-ttl=P30D     # 30 días
```
Formato ISO-8601 Duration. Reinicia el backend; los tokens emitidos antes mantienen su duración original.

### Añadir un nuevo rol (ej. `RECEPCION`)

1. `entity/enums/RolUsuario.java` → añadir el valor.
2. `schema.sql` → ampliar el `ENUM` de `usuario.rol_usuario`.
3. Crear entidad/tabla específica si tiene atributos propios (siguiendo el patrón `@MapsId`).
4. `UsuarioMapper.aAuthResponse` → añadir caso al `switch(rolUsuario)`.
5. `SecurityConfig` → añadir reglas si tienes `/recepcion/**`.
6. Frontend `app_router.dart` → añadir ruta `/recepcion/home` y rama en el `switch` de redirect.

### Testear el flujo en local

1. Arranca MySQL y crea la BD `victorino_style_bbdd_tfg_2dam_2025_2026_puig`.
2. `cd Backend_Victorino && ./mvnw spring-boot:run`.
3. Comprueba Swagger: http://localhost:8080/api/v1/swagger-ui.html.
4. `cd frontend_victorino && flutter pub get && flutter run`.
5. Registra un cliente nuevo desde la pantalla.
6. Cierra y reabre la app: el splash debería llevarte directo a su home.
7. Botón logout → vuelves a login.

### ¿Cómo invalidar todos los refresh de un usuario?

Tras un cambio de contraseña o sospecha de robo, llama desde un service:

```java
refreshTokenRepository.revocarTodosPorUsuario(idUsuario);
```

(Query ya implementada en `RefreshTokenRepository`.)
