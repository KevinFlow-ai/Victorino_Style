package org.victorino_style.controller;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.victorino_style.dto.auth.AuthResponse;
import org.victorino_style.dto.auth.CambiarPasswordRequest;
import org.victorino_style.dto.auth.LoginRequest;
import org.victorino_style.dto.auth.LogoutRequest;
import org.victorino_style.dto.auth.RefreshRequest;
import org.victorino_style.dto.auth.RefreshResponse;
import org.victorino_style.dto.auth.RegistroRequest;
import org.victorino_style.service.AuthService;

// Controller REST de autenticación. Solo orquesta: delega TODA la lógica en AuthService.
// Las rutas se mapean bajo /api/v1 (configurado en server.servlet.context-path).
// @RestController indica que esta clase es un controlador REST y que los métodos
// devuelven directamente objetos serializados a JSON (no vistas HTML).
@RestController
// @RequestMapping("/auth") define el prefijo común para todas las rutas de este controlador.
// Es decir, todos los endpoints empezarán por /auth (p.ej. /auth/login, /auth/registro, etc.).
@RequestMapping("/auth")
// @RequiredArgsConstructor (Lombok) genera un constructor con los campos final,
// permitiendo la inyección de dependencias por constructor sin escribirlo a mano.
@RequiredArgsConstructor
// @Tag se usa para documentar este controlador en Swagger/OpenAPI, agrupando
// sus endpoints bajo el nombre "Autenticación" con una descripción.
@Tag(name = "Autenticación", description = "Registro, login, refresh y logout")









public class AuthController {

    // Dependencia al servicio de autenticación. Es final para que Lombok la incluya
    // en el constructor generado por @RequiredArgsConstructor.
    // AuthService contiene la lógica de negocio: creación de usuarios, login,
    // generación de tokens, refresh, logout, etc.
    private final AuthService authService;





    // ============================================================
    //  POST /auth/registro
    // ============================================================

    // @PostMapping("/registro") indica que este métoodo maneja peticiones HTTP POST
    // a la ruta /auth/registro.
    @PostMapping("/registro")
    // @Operation documenta el endpoint en Swagger con un resumen legible.
    @Operation(summary = "Registra un nuevo cliente y devuelve tokens de sesión")
    // El métodoo devuelve un ResponseEntity<AuthResponse>, es decir, una respuesta HTTP
    // con un cuerpo de tipo AuthResponse (tokens, datos básicos, etc.).
    // @Valid activa la validación del DTO RegistroRequest según sus anotaciones (p.ej. @NotNull).
    // @RequestBody indica que el contenido JSON del cuerpo de la petición se deserializa
    // a un objeto RegistroRequest.
    public ResponseEntity<AuthResponse> registro(@Valid @RequestBody RegistroRequest body) {
        // Llama al servicio de autenticación para registrar un nuevo cliente usando
        // los datos recibidos en el body. El servicio devuelve un AuthResponse con
        // los tokens de sesión y la información necesaria.
        AuthResponse respuesta = authService.registrarCliente(body);
        // Construye una respuesta HTTP con código 201 CREATED y el cuerpo con la respuesta.
        return ResponseEntity.status(HttpStatus.CREATED).body(respuesta);
    }






    // ============================================================
    //  POST /auth/login
    // ============================================================

    // Endpoint para el login de cualquier tipo de usuario (CLIENTE, EMPLEADO, ADMIN).
    // Maneja peticiones POST a /auth/login.
    @PostMapping("/login")
    // Documentación Swagger indicando que el login es compartido para varios roles.
    @Operation(summary = "Login compartido para CLIENTE, EMPLEADO y ADMINISTRADOR")
    // Recibe un LoginRequest en el cuerpo de la petición (email/usuario + contraseña),
    // validado con @Valid, y devuelve un AuthResponse con los tokens de sesión.
    public ResponseEntity<AuthResponse> login(@Valid @RequestBody LoginRequest body) {
        // Llama al servicio de autenticación para iniciar sesión con las credenciales
        // proporcionadas. Si son correctas, devuelve tokens y datos del usuario.
        // Si son incorrectas, el servicio lanzará una excepción que Spring traducirá
        // a un error HTTP adecuado (por ejemplo, 401 Unauthorized).
        return ResponseEntity.ok(authService.iniciarSesion(body));
    }










    // ============================================================
    //  POST /auth/refresh
    // ============================================================

    // Endpoint para renovar el access token usando un refresh token válido.
    // Maneja peticiones POST a /auth/refresh.
    @PostMapping("/refresh")
    // Documentación Swagger explicando que renueva el access token.
    @Operation(summary = "Renueva el access token a partir del refresh token vigente")
    // Recibe un RefreshRequest con el refresh token en el cuerpo de la petición.
    // Devuelve un RefreshResponse con un nuevo access token (y posiblemente otros datos).
    public ResponseEntity<RefreshResponse> refresh(@Valid @RequestBody RefreshRequest body) {
        // Llama al servicio de autenticación para refrescar el token.
        // Se extrae el refreshToken del DTO (por ejemplo, body.refreshToken()) y se pasa
        // al servicio, que valida el token, comprueba que no esté revocado/expirado y
        // genera un nuevo access token.
        return ResponseEntity.ok(authService.refrescar(body.refreshToken()));
    }






    // ============================================================
    //  POST /auth/logout
    // ============================================================

    // Endpoint para cerrar sesión revocando un refresh token concreto.
    // Maneja peticiones POST a /auth/logout.
    @PostMapping("/logout")
    // Documentación Swagger indicando que revoca el refresh token enviado.
    @Operation(summary = "Revoca el refresh token enviado (cierra una sesión concreta)")
    // Recibe un LogoutRequest con el refresh token que se desea revocar.
    // Devuelve una respuesta sin cuerpo (Void) con código 204 No Content.
    public ResponseEntity<Void> logout(@Valid @RequestBody LogoutRequest body) {
        // Llama al servicio de autenticación para cerrar la sesión asociada al
        // refresh token recibido. Normalmente esto implica marcar el token como
        // revocado en base de datos o eliminarlo de una lista de tokens válidos.
        authService.cerrarSesion(body.refreshToken());
        // Devuelve una respuesta HTTP 204 No Content, indicando que la operación
        // se ha realizado correctamente pero no hay contenido en el cuerpo.
        return ResponseEntity.noContent().build();
    }
}

// ============================================================================
// AuthController
// ----------------------------------------------------------------------------
// Este controlador REST se encarga de gestionar las operaciones de autenticación
// de la aplicación Victorino Style. Expone los endpoints bajo el path /auth
// (que a su vez cuelga de /api/v1 si está configurado como context-path).
//
// RESPONSABILIDADES PRINCIPALES:
// - Recibir peticiones HTTP relacionadas con autenticación:
//      * Registro de nuevos clientes.
//      * Login de usuarios (CLIENTE, EMPLEADO, ADMINISTRADOR).
//      * Refresh del access token usando un refresh token válido.
//      * Logout (revocación de un refresh token concreto).
// - Validar el cuerpo de las peticiones mediante @Valid y DTOs específicos.
// - Delegar TODA la lógica de negocio en AuthService (este controlador
//   únicamente orquesta y no contiene lógica de autenticación).
// - Devolver respuestas HTTP adecuadas (códigos de estado y cuerpos).
//
// TECNOLOGÍAS Y ANOTACIONES CLAVE:
// - @RestController: indica que es un controlador REST (devuelve JSON).
// - @RequestMapping("/auth"): prefijo común para todas las rutas de este controlador.
// - @RequiredArgsConstructor: genera un constructor con los campos final para inyección.
// - @Tag: documentación OpenAPI/Swagger para agrupar endpoints de autenticación.
// - @PostMapping: define endpoints POST específicos.
// - @Operation: describe cada endpoint para la documentación Swagger.
// - ResponseEntity: permite controlar código de estado y cuerpo de la respuesta.
// ============================================================================