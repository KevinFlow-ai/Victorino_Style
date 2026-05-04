package org.victorino_style.exception;

// Lanzada en /auth/refresh cuando el refresh token no existe, está revocado o ha caducado.
// La traduce GlobalExceptionHandler a HTTP 401 Unauthorized.
public class TokenInvalidoException extends RuntimeException {



    // Constructor que recibe un mensaje personalizado describiendo el motivo
    // por el cual el refresh token es inválido.
    public TokenInvalidoException(String mensaje) {
        super(mensaje);
    }
}



    // ============================================================================
    // TokenInvalidoException
    // ----------------------------------------------------------------------------
    // Esta excepción personalizada se lanza durante el proceso de renovación de
    // tokens (endpoint POST /auth/refresh) cuando el refresh token:
    //
    //   - No existe en la base de datos.
    //   - Ha sido revocado manualmente (logout).
    //   - Ha caducado según su tiempo de vida (refreshTtl).
    //   - No coincide con el usuario esperado.
    //   - Tiene un formato inválido.
    //
    // ¿POR QUÉ ES IMPORTANTE ESTA EXCEPCIÓN?
    // - Permite distinguir claramente los errores relacionados con tokens inválidos.
    // - GlobalExceptionHandler la captura y la convierte en un HTTP 401 Unauthorized.
    // - Evita que el backend devuelva errores genéricos y facilita al frontend
    //   mostrar mensajes claros al usuario.
    //
    // ¿POR QUÉ EXTIENDE RuntimeException?
    // - Las RuntimeException no requieren declaración con "throws".
    // - Son ideales para errores de negocio que deben interrumpir el flujo normal.
    // - Permiten que Spring las capture automáticamente en el manejador global.
    //
    // El mensaje recibido en el constructor se envía tal cual al cliente dentro del
    // ApiError generado por GlobalExceptionHandler.
    // ============================================================================