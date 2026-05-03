## 🧱 Arquitectura general del backend (n‑tier en Spring Boot)

La arquitectura clásica en capas divide el backend en **responsabilidades separadas**, de forma que cada capa hace solo una cosa y la hace bien. Las capas principales son:

1. **Controller (Capa de Presentación / expone la API REST.)**
    
2. **Service (Capa de Lógica de Negocio)**
    
3. **Repository  (Capa de Acceso a Datos)**
    
4. **Entity/model (Entidades del modelo)**
    
5. **DTO (Objetos de transferencia de datos)**
    
6. **Mapper (Conversión entre Entity ↔ DTO)** 
    

7. **Exception Handling 
    
8. **Security Layer (si usas JWT o roles)**
    
9. **Configuration**


# 🧩 Explicación conceptual de cada capa

## 1. **Controller 

**Qué es:** La capa que expone endpoints REST al cliente (Flutter en tu caso).

**Responsabilidad:**

- Recibir peticiones HTTP (GET, POST, PUT, DELETE).
    
- Validar datos de entrada (con `@Valid`).
    
- Convertir DTOs de entrada → objetos de negocio.
    
- Llamar a los servicios.
    
- Devolver DTOs de salida → cliente.
    

**Qué NO debe hacer:**

- No debe contener lógica de negocio.
    
- No debe acceder a la base de datos.

## 2. **Service 

**Qué es:** El corazón del backend. Aquí vive la lógica de negocio.

**Responsabilidad:**

- Procesar reglas de negocio.
    
- Validar condiciones complejas.
    
- Orquestar llamadas a repositorios.
    
- Gestionar transacciones (`@Transactional`).
    
- Aplicar lógica según roles (admin, empleado, cliente).
    

**Qué NO debe hacer:**

- No debe exponer endpoints.
    
- No debe devolver entidades directamente al cliente.

## 3. **Repository **

**Qué es:** La capa que habla directamente con la base de datos.

**Responsabilidad:**

- Consultas SQL automáticas con Spring Data JPA.
    
- Consultas personalizadas con `@Query`.
    
- Guardar, actualizar, borrar entidades.
    

**Qué NO debe hacer:**

- No debe contener lógica de negocio.
    
- No debe procesar DTOs.


## 4. **Entity/model **

**Qué es:** Las clases que representan tablas de la base de datos.

**Responsabilidad:**

- Definir atributos persistentes.
    
- Definir relaciones (`@OneToMany`, `@ManyToOne`).
    
- Representar el modelo real del negocio.
    

**Qué NO debe hacer:**

- No deben viajar al cliente.
    
- No deben contener lógica compleja.

## 5. **DTO 

**Qué es:** Objetos diseñados para transportar datos hacia/desde el cliente.

**Responsabilidad:**

- Evitar exponer entidades directamente.
    
- Controlar qué datos se envían al cliente.
    
- Separar el modelo interno del modelo externo.
## 6. **Mapper 

**Qué es:** Clases que convierten Entity ↔ DTO.

**Responsabilidad:**

- Evitar duplicar código de conversión.
    
- Mantener limpio el controller y el service.

## 7. **Exception Handling 

**Qué es:** Una capa centralizada para manejar errores.

**Responsabilidad:**

- Capturar excepciones.
    
- Devolver respuestas JSON limpias y uniformes.
    
- Evitar stacktraces en el cliente.


## 8. **Security 


**Responsabilidad:**

- Autenticación (login).
    
- Autorización (roles: admin, empleado, cliente).
    
- Filtros JWT.
    
- Configuración de rutas públicas/privadas.
    

**Archivos típicos:**

- `SecurityConfig.java`
    
- `JwtFilter.java`
    
- `CustomUserDetailsService.java`


### Paquete `config`

Aquí estás metiendo toda la **configuración técnica y transversal**:

- `CorsConfig.java` **Rol:** Configura CORS (qué orígenes, métodos y cabeceras puede usar tu app Flutter para llamar al backend). **Capa:** Configuración transversal, afecta a la capa de presentación (controllers).
    
- `FirebaseConfig.java` **Rol:** Configura el cliente para hablar con Firebase Cloud Messaging (credenciales, inicialización del SDK, etc.). **Capa:** Infraestructura, usada por `FirebaseService`.
    
- `JwtConfig.java` **Rol:** Propiedades y parámetros del JWT (secret, expiración, etc.). **Capa:** Soporte para la capa de seguridad.
    
- `OpenApiConfig.java` **Rol:** Configuración de Swagger / OpenAPI para documentar tu API REST. **Capa:** Presentación/documentación.
    
- `SchedulingConfig.java` **Rol:** Habilita y configura tareas programadas (`@EnableScheduling`, etc.). **Capa:** Infraestructura para `scheduler`.
    
- `SecurityConfig.java` **Rol:** Configura Spring Security: rutas públicas/privadas, filtros JWT, manejo de sesiones, etc. **Capa:** Seguridad, afecta a cómo se accede a los controllers.
    

### Paquete `controller`

Aquí tienes la **capa de presentación / API REST**. Cada controller expone endpoints para un “subdominio”:

- `AuthController.java` **Rol:** Login, registro, refresh token, recuperación de contraseña, etc. **Hace:** Recibe credenciales, llama a `AuthService`, devuelve tokens/DTOs.
    
- `CitaController.java` **Rol:** CRUD y operaciones sobre citas (crear, cancelar, listar, reprogramar…). **Hace:** Recibe peticiones del cliente (cliente/empleado/admin), llama a `CitaService`.
    
- `ClienteController.java` **Rol:** Operaciones relacionadas con el cliente (perfil, datos personales, historial de citas…). **Hace:** Orquesta `ClienteService`.
    
- `ConfiguracionController.java` **Rol:** Configuración de la peluquería (horarios, festivos, parámetros de negocio). **Hace:** Llama a `ConfiguracionService`.
    
- `EmpleadoController.java` **Rol:** Gestión de empleados (alta, baja, horarios, servicios que ofrecen). **Hace:** Llama a `EmpleadoService`.
    
- `MetricaController.java` **Rol:** Exponer métricas (nº citas, cancelaciones, productividad, etc.). **Hace:** Llama a `MetricaService`.
    
- `NotificacionController.java` **Rol:** Gestión de notificaciones (marcar como leída, listar notificaciones, etc.). **Hace:** Llama a `NotificacionService`.
    
- `ServicioController.java` **Rol:** Gestión de servicios de peluquería (corte, tinte, duración, precio…). **Hace:** Llama a `ServicioService`.
    

**Importante:** aquí deberían entrar y salir **DTOs**, no entidades.

### Paquete `dto`

Ahora mismo está vacío, pero aquí deberías definir:

- **DTOs de entrada** (lo que te manda Flutter):
    
    - `CrearCitaRequestDTO`
        
    - `LoginRequestDTO`
        
    - `ActualizarPerfilClienteDTO`
        
- **DTOs de salida** (lo que devuelves a Flutter):
    
    - `CitaResponseDTO`
        
    - `ClienteResponseDTO`
        
    - `EmpleadoResponseDTO`
        
    - `ServicioResponseDTO`
        
    - `AuthResponseDTO` (token, rol, etc.)
        

Conceptualmente: esta capa es el **contrato** entre tu backend y tu app Flutter.

### Paquete `entity` y `entity.enums`

Aquí está tu **modelo de dominio** (lo que se persiste en la base de datos):

- `Usuario.java` **Rol:** Representa un usuario del sistema (cliente, empleado, admin). **Debe tener:** campos como id, nombre, email, contraseña, rol (`RolUsuario`), etc. **Capa:** Dominio/persistencia.
    
- `enums`
    
    - `EstadoCita.java` → estados posibles de una cita (PENDIENTE, CONFIRMADA, CANCELADA, COMPLETADA…).
        
    - `PlataformaFcm.java` → tipo de dispositivo/plataforma para FCM (ANDROID, IOS, WEB…).
        
    - `RolUsuario.java` → roles del sistema (ADMIN, CLIENTE, EMPLEADO).
        
    - `TipoFestivo.java` → tipos de festivo (LOCAL, NACIONAL, PERSONALIZADO…).
        
    - `TipoNotificacion.java` → tipos de notificación (RECORDATORIO_CITA, CITA_CANCELADA, NUEVA_CITA, etc.).
        

Estas enums son parte del **lenguaje del dominio**: ayudan a que tu código exprese reglas de negocio de forma clara.

### Paquete `exception`

Aquí tienes una **capa de manejo de errores de negocio**:

- `ApiError.java` **Rol:** Modelo de error que devuelves al cliente (mensaje, código, timestamp, etc.).
    
- **Excepciones específicas:**
    
    - `CitaNoModificableException.java` → cuando se intenta modificar una cita que ya no se puede cambiar.
        
    - `CitaSolapadaException.java` → cuando se intenta crear/modificar una cita que se solapa con otra.
        
    - `CorreoDuplicadoException.java` → al registrar un usuario con correo ya existente.
        
    - `CredencialesInvalidasException.java` → login fallido.
        
    - `RecursoNoEncontradoException.java` → entidad no encontrada (cita, usuario, servicio…).
        
- `GlobalExceptionHandler.java` **Rol:** Captura estas excepciones y las transforma en respuestas HTTP limpias (400, 404, 409, etc.).
    

Esto encaja perfecto con la capa de **Exception Handling** que comentábamos.

### Paquete `mapper`

Ahora está vacío, pero aquí irían:

- `UsuarioMapper.java` → `Usuario` ↔ `UsuarioResponseDTO` / `CrearUsuarioDTO`.
    
- `CitaMapper.java` → `Cita` ↔ `CitaResponseDTO` / `CrearCitaRequestDTO`.
    
- etc.
    

Conceptualmente: esta capa evita que el controller y el service se llenen de código de conversión.

### Paquete `repository`

Aquí está la **capa de acceso a datos**:

- `CitaRepository.java` **Rol:** Interfaz que extiende `JpaRepository` o similar. **Hace:** Buscar citas por cliente, por empleado, por fecha, por estado, etc. **Capa:** Persistencia pura, sin lógica de negocio.
    

Más adelante seguramente tendrás:

- `UsuarioRepository.java`
    
- `EmpleadoRepository.java`
    
- `ServicioRepository.java`
    
- `NotificacionRepository.java`
    
- etc.
    

### Paquete `scheduler`

Aquí tienes **tareas programadas** que se ejecutan automáticamente:

- `CompletadaScheduler.java` **Rol:** Marcar citas como completadas automáticamente cuando pasa su hora, por ejemplo.
    
- `LimpiezaTokensScheduler.java` **Rol:** Limpiar tokens caducados, registros temporales, etc.
    
- `RecordatorioScheduler.java` **Rol:** Enviar recordatorios de citas (por ejemplo, 24h antes) usando `FirebaseService` y/o `MailService`.
    

Estas clases suelen usar **services** por debajo (no repositorios directamente, idealmente).

### Paquete `security`

Aquí está tu **capa de seguridad**:

- `CustomUserDetailsService.java` **Rol:** Cargar usuarios desde la base de datos para Spring Security (por email/username). **Conecta:** `UsuarioRepository` (cuando lo tengas) con Spring Security.
    
- `JwtAuthenticationFilter.java` **Rol:** Filtro que intercepta peticiones, lee el token JWT, valida, y mete el usuario en el contexto de seguridad.
    
- `JwtService.java` **Rol:** Generar, validar y parsear tokens JWT.
    
- `PasswordEncoderConfig.java` **Rol:** Define el `PasswordEncoder` (BCrypt, etc.) para encriptar contraseñas.
    

### Paquete `service`

Aquí está tu **capa de lógica de negocio**:

- `AuditoriaService.java` **Rol:** Registrar acciones importantes (quién hizo qué y cuándo).
    
- `AuthService.java` **Rol:** Login, registro, recuperación de contraseña, generación de tokens, etc.
    
- `CitaService.java` **Rol:** Reglas de negocio de las citas:
    
    - comprobar solapamientos,
        
    - validar horarios,
        
    - aplicar restricciones según rol,
        
    - lanzar `CitaSolapadaException`, `CitaNoModificableException`, etc.
        
- `ClienteService.java` **Rol:** Lógica relacionada con clientes (perfil, historial, alta/baja lógica, etc.).
    
- `ConfiguracionService.java` **Rol:** Reglas sobre configuración de la peluquería (festivos, horarios, parámetros globales).
    
- `EmpleadoService.java` **Rol:** Gestión de empleados, horarios, servicios que ofrecen, etc.
    
- `FirebaseService.java` **Rol:** Enviar notificaciones push a través de FCM.
    
- `MailService.java` **Rol:** Enviar correos (por ejemplo, código de recuperación de contraseña).
    
- `MetricaService.java` **Rol:** Calcular métricas de negocio (nº citas por día, cancelaciones, etc.).
    
- `NotificacionService.java` **Rol:** Gestionar notificaciones internas (guardar en BD, marcar como leídas, etc.).
    
- `ServicioService.java` **Rol:** Lógica de los servicios de peluquería (duración, precio, disponibilidad).