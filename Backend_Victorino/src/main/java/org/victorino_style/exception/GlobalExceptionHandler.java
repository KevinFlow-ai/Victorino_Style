package org.victorino_style.exception;


import jakarta.servlet.http.HttpServletRequest; // Importa HttpServletRequest para obtener información de la petición fallida.

import jakarta.validation.ConstraintViolationException; // Importa excepción de validación a nivel de parámetros.

import lombok.extern.slf4j.Slf4j; // Lombok: genera un logger (log.info, log.warn, log.error).

import org.springframework.http.HttpStatus; // Clases de Spring para construir respuestas HTTP.
import org.springframework.http.ResponseEntity;

import org.springframework.security.authentication.BadCredentialsException;// Excepciones de Spring Security.
import org.springframework.security.core.AuthenticationException;
import org.springframework.security.access.AccessDeniedException;

import org.springframework.web.bind.MethodArgumentNotValidException; // Excepción de validación de DTOs con @Valid.

import org.springframework.web.bind.annotation.ExceptionHandler; // Anotaciones para manejar excepciones globalmente.
import org.springframework.web.bind.annotation.RestControllerAdvice;

import java.time.Instant;
import java.util.List;


// Handler global de excepciones que traduce cualquier error a un ApiError uniforme.


@Slf4j // @Slf4j → añade un logger.
@RestControllerAdvice // @RestControllerAdvice → aplica este manejador a todos los controladores REST.
public class GlobalExceptionHandler {






    // ------------------------------------------------------------------------
    // 400: errores de validación de DTOs con @Valid.
    // Se lanza cuando un campo anotado con @NotBlank, @Email, @Pattern, etc. falla.
    // ------------------------------------------------------------------------
    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ApiError> manejarValidacion(MethodArgumentNotValidException ex,
                                                      HttpServletRequest req) {
        // Recoge todos los errores de campo y los empaqueta en la lista "fields".
        List<ApiError.CampoError> campos = ex.getBindingResult()
                .getFieldErrors()
                .stream()
                .map(fe -> new ApiError.CampoError(fe.getField(),
                        fe.getDefaultMessage() != null ? fe.getDefaultMessage() : "Valor inválido"))
                .toList();
        ApiError error = new ApiError( // Construye el objeto ApiError con detalles del error.
                Instant.now(),                     // timestamp
                HttpStatus.BAD_REQUEST.value(),    // 400
                "Bad Request",                     // nombre del error
                "Los datos enviados no son válidos", // mensaje genérico
                req.getRequestURI(),               // endpoint donde ocurrió
                campos                             // lista de errores de campo
        );
        log.warn("Validación fallida en {}: {}", req.getRequestURI(), campos); // Log de advertencia con los campos inválidos
        return ResponseEntity.badRequest().body(error);
    }




    // 400: errores de validación a nivel de parámetro de métodoo.
    @ExceptionHandler(ConstraintViolationException.class)
    public ResponseEntity<ApiError> manejarConstraint(ConstraintViolationException ex,
                                                      HttpServletRequest req) {
        List<ApiError.CampoError> campos = ex.getConstraintViolations()
                .stream()
                .map(cv -> new ApiError.CampoError(cv.getPropertyPath().toString(), cv.getMessage()))
                .toList();
        ApiError error = new ApiError(
                Instant.now(), HttpStatus.BAD_REQUEST.value(), "Bad Request",
                "Datos inválidos", req.getRequestURI(), campos
        );
        return ResponseEntity.badRequest().body(error);
    }




    // ------------------------------------------------------------------------
    // 401: credenciales inválidas (correo o contraseña incorrectos).
    // Maneja tanto excepciones personalizadas como BadCredentialsException.
    // ------------------------------------------------------------------------
    @ExceptionHandler({CredencialesInvalidasException.class, BadCredentialsException.class})
    public ResponseEntity<ApiError> manejarCredenciales(RuntimeException ex,
                                                        HttpServletRequest req) {
        // Log informativo del intento fallido.
        log.info("Login fallido en {}: {}", req.getRequestURI(), ex.getMessage());
        return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                .body(ApiError.sinCampos(401, "Unauthorized",
                        "Correo o contraseña incorrectos", req.getRequestURI()));
    }






    // ------------------------------------------------------------------------
    // 401: refresh token inválido, caducado o revocado.
    // ------------------------------------------------------------------------
    @ExceptionHandler(TokenInvalidoException.class)
    public ResponseEntity<ApiError> manejarTokenInvalido(TokenInvalidoException ex,
                                                         HttpServletRequest req) {
        return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                .body(ApiError.sinCampos(401, "Unauthorized", ex.getMessage(), req.getRequestURI()));
    }





    // ------------------------------------------------------------------------
    // 401: cualquier otra AuthenticationException no manejada arriba.
    // ------------------------------------------------------------------------
    @ExceptionHandler(AuthenticationException.class)
    public ResponseEntity<ApiError> manejarAuth(AuthenticationException ex,
                                                HttpServletRequest req) {
        return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                .body(ApiError.sinCampos(401, "Unauthorized",
                        "Autenticación requerida", req.getRequestURI()));
    }




    // ------------------------------------------------------------------------
    // 403: usuario autenticado pero sin permisos suficientes.
    // ------------------------------------------------------------------------
    @ExceptionHandler(AccessDeniedException.class)
    public ResponseEntity<ApiError> manejarAccesoDenegado(AccessDeniedException ex,
                                                          HttpServletRequest req) {
        return ResponseEntity.status(HttpStatus.FORBIDDEN)
                .body(ApiError.sinCampos(403, "Forbidden",
                        "No tienes permiso para realizar esta acción", req.getRequestURI()));
    }






    // ------------------------------------------------------------------------
    // 409: correo duplicado en registro.
    // ------------------------------------------------------------------------
    @ExceptionHandler(CorreoDuplicadoException.class)
    public ResponseEntity<ApiError> manejarCorreoDuplicado(CorreoDuplicadoException ex,
                                                           HttpServletRequest req) {
        return ResponseEntity.status(HttpStatus.CONFLICT)
                .body(ApiError.sinCampos(409, "Conflict", ex.getMessage(), req.getRequestURI()));
    }

    // ------------------------------------------------------------------------
    // 404: recurso no encontrado (empleado, servicio o cualquier subclase).
    // ------------------------------------------------------------------------
    @ExceptionHandler(RecursoNoEncontradoException.class)
    public ResponseEntity<ApiError> manejarNoEncontrado(RecursoNoEncontradoException ex,
                                                        HttpServletRequest req) {
        return ResponseEntity.status(HttpStatus.NOT_FOUND)
                .body(ApiError.sinCampos(404, "Not Found", ex.getMessage(), req.getRequestURI()));
    }

    // ------------------------------------------------------------------------
    // 400: foto obligatoria al crear empleado o servicio.
    // ------------------------------------------------------------------------
    @ExceptionHandler(FotoObligatoriaException.class)
    public ResponseEntity<ApiError> manejarFotoObligatoria(FotoObligatoriaException ex,
                                                           HttpServletRequest req) {
        return ResponseEntity.badRequest()
                .body(ApiError.sinCampos(400, "Bad Request", ex.getMessage(), req.getRequestURI()));
    }

    // ------------------------------------------------------------------------
    // 409: cancelación masiva sin citas futuras / festivo duplicado / cita solapada / cita no modificable.
    // ------------------------------------------------------------------------
    @ExceptionHandler({
            NoCitasFuturasCancelablesException.class,
            FestivoDuplicadoException.class,
            CitaSolapadaException.class,
            CitaNoModificableException.class
    })
    public ResponseEntity<ApiError> manejarConflicto(RuntimeException ex,
                                                     HttpServletRequest req) {
        return ResponseEntity.status(HttpStatus.CONFLICT)
                .body(ApiError.sinCampos(409, "Conflict", ex.getMessage(), req.getRequestURI()));
    }

    // ------------------------------------------------------------------------
    // 500: la peluquería no está configurada (problema de inicialización del proyecto).
    // ------------------------------------------------------------------------
    @ExceptionHandler(PeluqueriaNoConfiguradaException.class)
    public ResponseEntity<ApiError> manejarPeluqueriaNoConfigurada(PeluqueriaNoConfiguradaException ex,
                                                                   HttpServletRequest req) {
        log.error("Error de configuración: peluquería singleton no encontrada en BD");
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(ApiError.sinCampos(500, "Internal Server Error", ex.getMessage(), req.getRequestURI()));
    }



    // ------------------------------------------------------------------------
    // 500: cualquier excepción no contemplada cae aquí.
    // al cliente se le devuelve un mensaje genérico para no filtrar internals.
    // ------------------------------------------------------------------------

    @ExceptionHandler(Exception.class)
    public ResponseEntity<ApiError> manejarGenerica(Exception ex, HttpServletRequest req) {
        log.error("Error inesperado en {}", req.getRequestURI(), ex);
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(ApiError.sinCampos(500, "Internal Server Error",
                        "Ha ocurrido un error inesperado", req.getRequestURI()));
    }
}

// ============================================================================
// GlobalExceptionHandler
// ----------------------------------------------------------------------------
// Este componente centraliza el manejo de excepciones en toda la API.
// Cualquier excepción lanzada desde un @RestController que no sea capturada
// localmente termina aquí, donde se transforma en un objeto ApiError uniforme.
//
// ¿POR QUÉ ES IMPORTANTE?
// - Garantiza que todas las respuestas de error tengan el mismo formato JSON.
// - Evita filtrar detalles internos del servidor.
// - Permite devolver códigos HTTP correctos según el tipo de error.
// - Facilita al frontend (Flutter) interpretar y mostrar errores.
//
// TIPOS DE ERRORES MANEJADOS:
// - 400 → errores de validación (@Valid, @ConstraintViolation).
// - 401 → credenciales incorrectas, tokens inválidos, autenticación fallida.
// - 403 → usuario autenticado pero sin permisos suficientes.
// - 409 → correo duplicado en registro.
// - 500 → errores inesperados.
//
// Usa @RestControllerAdvice para aplicarse globalmente y @ExceptionHandler
// para interceptar excepciones específicas.
// ============================================================================

