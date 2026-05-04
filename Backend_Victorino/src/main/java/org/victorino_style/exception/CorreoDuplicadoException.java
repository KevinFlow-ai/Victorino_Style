package org.victorino_style.exception;

// Lanzada por AuthService.registrar cuando el correo ya existe en BD.
// La traduce GlobalExceptionHandler a HTTP 409 Conflict.
public class CorreoDuplicadoException extends RuntimeException {



    // Constructor que recibe el correo duplicado.
    // Llama al constructor de RuntimeException con un mensaje personalizado.
    public CorreoDuplicadoException(String correo) {
        super("Ya existe una cuenta con el correo: " + correo);
    }




}


// ============================================================================
// CorreoDuplicadoException
// ----------------------------------------------------------------------------
// Esta excepción personalizada se lanza desde AuthService.registrarCliente()
// cuando se intenta registrar un usuario con un correo que ya existe en la BD.
//
// ¿POR QUÉ ES NECESARIA ESTA EXCEPCIÓN?
// - Permite distinguir claramente este caso de error del resto.
// - GlobalExceptionHandler la captura y la convierte en una respuesta HTTP 409 Conflict.
// - Facilita que el frontend (Flutter) pueda mostrar un mensaje claro al usuario.
//
// ¿POR QUÉ EXTIENDE RuntimeException?
// - Las RuntimeException no requieren ser declaradas con "throws".
// - Son ideales para errores de negocio que deben interrumpir el flujo normal.
//
// ¿QUÉ MENSAJE GENERA?
// - El constructor recibe el correo duplicado y construye un mensaje como:
//      "Ya existe una cuenta con el correo: ejemplo@correo.com"
// - Este mensaje se envía al cliente dentro del JSON de ApiError.
//
// Esta clase es simple pero esencial para mantener una arquitectura limpia,
// separando la lógica de negocio de la gestión de errores HTTP.
// ============================================================================