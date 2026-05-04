# Guía para nuevos desarrolladores

> Pensada para alguien que entra al proyecto y quiere tener el flujo de auth funcionando en local en menos de 30 minutos.

## 1. Requisitos

- **JDK 21** Eclipse Temurin.
- **Maven** ≥ 3.9 (incluido como `mvnw` en el repo).
- **MySQL 8.0+** corriendo en `localhost:3306`.
- **Flutter 3.41.2 + Dart 3.11.0**.
- **IntelliJ IDEA 2026.1** (backend) y **Android Studio Panda 2** (frontend), opcional pero recomendado.

## 2. Arrancar el flujo en local

### 2.1 Base de datos

```bash
mysql -u root -p
CREATE DATABASE victorino_style_bbdd_tfg_2dam_2025_2026_puig
       CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

Hibernate creará/actualizará el schema (ddl-auto=update). Cuando el seed esté listo:
```bash
mysql -u root -p victorino_style_bbdd_tfg_2dam_2025_2026_puig < Backend_Victorino/src/main/resources/db/seed.sql
```

### 2.2 Backend

```bash
cd Backend_Victorino
./mvnw spring-boot:run
```

- Puerto: 8080
- Context path: `/api/v1`
- Swagger: http://localhost:8080/api/v1/swagger-ui.html
- Health: http://localhost:8080/api/v1/actuator/health (cuando se añada)

### 2.3 Frontend

```bash
cd frontend_victorino
flutter pub get
flutter run                      # emulador o dispositivo
```

Si arrancas en **Android Emulator**, la URL `10.0.2.2` apunta al host. Si arrancas en **iOS simulador / web**, sobreescribe la URL:

```bash
flutter run --dart-define=API_BASE_URL=http://localhost:8080/api/v1
```

## 3. Usuarios de prueba (seed)

> Pendiente: el seed se incorporará en una tarea separada. Mientras tanto, registra un cliente nuevo desde la pantalla de registro y úsalo para probar.

Ejemplo manual con curl:

```bash
curl -X POST http://localhost:8080/api/v1/auth/registro \
  -H "Content-Type: application/json" \
  -d '{"nombre":"Test","apellidos":"User","correo":"test@victorino.es","password":"Abcd1234"}'
```

## 4. Cómo extender

### 4.1 Añadir un campo al registro

Ejemplo: añadir `fechaNacimiento`.

1. **`schema.sql`** (cuando exista) y **`Cliente.java`**: añadir columna `fecha_nacimiento_cliente DATE`.
2. **`RegistroRequest.java`**: añadir parámetro al record con `@NotNull` o no según necesidad.
3. **`AuthService.registrarCliente`**: setear el valor en `cliente.setFechaNacimientoCliente(...)`.
4. **Frontend `DatosRegistro`** + **`AuthRepositorioImpl.registrarCliente`** + nuevo campo en `RegistroScreen`.
5. Actualizar `auth.md` y este fichero.

### 4.2 Añadir validación

Cualquier `@NotBlank`, `@Size`, `@Pattern` en el record DTO. El `GlobalExceptionHandler` ya devuelve 400 con `fields[]` automáticamente.

Para el frontend: añadir validador al `TextFormField` en la pantalla correspondiente.

### 4.3 Cambiar duración del access token

`application.properties`:
```
victorino.jwt.access-ttl=PT5M     # 5 min
```
Reinicia el backend.

### 4.4 Hacer logout en TODAS las sesiones del usuario

Crear un endpoint nuevo o ampliar `cerrarSesion` con un parámetro extra. La query ya está:
```java
refreshTokenRepository.revocarTodosPorUsuario(idUsuario);
```

## 5. Errores frecuentes

### "Communications link failure"

MySQL no está arrancado o el usuario/password es distinto. Edita `application.properties`.

### "Required request body is missing"

El cliente no envió JSON o se le olvidó `Content-Type: application/json`.

### "401 Unauthorized" inesperado en una ruta protegida

El access token ha caducado y aún no ha entrado en juego el `RefreshInterceptor`. Comprueba:
- Que `dioProvider` tenga ambos interceptores en orden (jwt primero, refresh después).
- Que la sesión persistida en `flutter_secure_storage` no esté corrupta. Borra y vuelve a hacer login.

### "MissingPluginException: flutter_secure_storage" en web

Solo soporte parcial en web. Para web, el plan oficial es solo desktop/mobile en v1.0.

### Tests del backend fallan con "Mockito self-attaching..."

Aviso, no error. Para silenciarlo añade `-javaagent:byte-buddy-agent.jar` a la config de surefire (futuro).

## 6. Comandos útiles

```bash
# Backend
./mvnw clean compile -DskipTests       # compila rápido
./mvnw test                             # ejecuta todos los tests
./mvnw test -Dtest=AuthServiceTest      # un solo test
./mvnw spring-boot:run                  # arranca el server

# Frontend
flutter analyze                         # linter
flutter test                            # tests
flutter run                             # arranca app
flutter clean && flutter pub get        # limpieza dura
```

## 7. Referencias

- Plan original: `documentacion/auth/auth.md`
- Contratos API: `documentacion/auth/api_auth.md`
- Bitácora de errores: `documentacion/errores.md`
- CLAUDE.md (contexto operativo del proyecto): raíz del repo.
