package org.victorino_style.exception;

import com.fasterxml.jackson.annotation.JsonInclude; // Importa JsonInclude para omitir campos nulos al serializar.

import java.time.Instant; // Importa Instant para registrar el momento exacto del error.
import java.util.List; // Importa List para manejar la lista de errores de campos.

// Estructura JSON estándar de error que devuelve la API.
// Lo serializa Jackson tal cual desde GlobalExceptionHandler.
@JsonInclude(JsonInclude.Include.NON_NULL) // Si "detalles" es null, Jackson lo omite del JSON.
public record ApiError(

        // timestamp: fecha y hora exacta en la que ocurrió el error.
        Instant timestamp,

        // status: código HTTP del error (400, 401, 404, 500…).
        int status,

        // error: nombre del error (ej. "Bad Request", "Unauthorized", "Not Found").
        String error,

        // message: descripción detallada del error.
        String message,

        // path: endpoint donde ocurrió el error (ej. "/auth/login").
        String path,

        // fields: lista de errores de validación de campos.
        // Si no hay errores de validación, será una lista vacía.
        List<CampoError> fields,

        // detalles: objeto opcional con información estructurada extra.
        // Se usa por ejemplo en 409 CITA_MISMA_SEMANA para devolver el id, fecha y hora de la cita ya existente
        // de modo que el frontend pueda construir un mensaje contextual y un botón "Modificar".
        // Cuando es null se omite del JSON gracias a @JsonInclude(NON_NULL).
        Object detalles

) {
    // Detalle de un campo concreto que falló validación.
    public record CampoError(String field, String message) {
    }

    // Constructor sin "fields" ni "detalles" para errores que no son de validación.
    public static ApiError sinCampos(int status, String error, String message, String path) {
        return new ApiError(Instant.now(), status, error, message, path, List.of(), null);
    }

    // Constructor con "detalles" para errores enriquecidos (ej. 409 cita misma semana).
    public static ApiError conDetalles(int status, String error, String message, String path, Object detalles) {
        return new ApiError(Instant.now(), status, error, message, path, List.of(), detalles);
    }
}


    // ============================================================================
    // ApiError
    // ----------------------------------------------------------------------------
    // Esta clase define la **estructura estándar de error** que devuelve tu API
    // cuando ocurre cualquier excepción controlada por el GlobalExceptionHandler.
    //
    // ¿PARA QUÉ SIRVE ESTE DTO?
    // - Representa un error en formato JSON uniforme para toda la API.
    // - Permite que el frontend (Flutter) reciba errores consistentes y fáciles
    //   de interpretar.
    // - Incluye información útil para depurar y mostrar mensajes al usuario.
    //
    // CAMPOS PRINCIPALES:
    // - timestamp → momento exacto del error.
    // - status → código HTTP (400, 401, 404, 500…).
    // - error → nombre del error (ej. "Bad Request").
    // - message → mensaje detallado del error.
    // - path → endpoint donde ocurrió el error.
    // - fields → lista de errores de validación (solo si aplica).
    //
    // SUBRECORD CampoError:
    // - Representa un error específico de un campo (ej. "correo", "El correo no es válido").
    // - Se usa cuando fallan validaciones @NotBlank, @Email, @Size, etc.
    //
    // MÉTODOO sinCampos():
    // - Crea un ApiError sin lista de campos (para errores que no son de validación).
    // - Se usa para errores como 401, 403, 404, 500…
    //
    // Jackson serializa este record automáticamente a JSON.
    // ============================================================================