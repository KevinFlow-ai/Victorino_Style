package org.victorino_style.exception;

// Lanzada cuando el admin solicita una cancelación masiva de las citas futuras de un empleado
// pero no hay ninguna cita en estado CONFIRMADA por delante. Se traduce a HTTP 409 Conflict.
public class NoCitasFuturasCancelablesException extends RuntimeException {

    public NoCitasFuturasCancelablesException(Long idEmpleado) {
        super("El empleado " + idEmpleado + " no tiene citas futuras cancelables.");
    }
}

/*
    ============================================================================
    NoCitasFuturasCancelablesException
    ----------------------------------------------------------------------------
    Esta excepción se lanza cuando se intenta cancelar una cita futura de un
    empleado, pero dicho empleado no tiene ninguna cita futura que pueda ser
    cancelada.

    ¿POR QUÉ ES NECESARIA ESTA EXCEPCIÓN?
            - Permite identificar claramente este caso de negocio: no hay citas futuras.
            - Facilita que el GlobalExceptionHandler devuelva un HTTP 400 o 404,
    según cómo esté diseñado el flujo.
            - Permite que el frontend muestre un mensaje claro al usuario, evitando
    comportamientos confusos o silenciosos.

            ¿POR QUÉ EXTIENDE RuntimeException?
            - Las RuntimeException no requieren declararse con "throws".
            - Son ideales para errores de negocio que deben interrumpir el flujo normal.
            - Mantiene el código más limpio y evita propagación innecesaria de excepciones.

    ¿QUÉ MENSAJE GENERA?
            - El constructor recibe el id del empleado.
    - Construye un mensaje como:
            "El empleado 12 no tiene citas futuras cancelables."
            - Este mensaje se envía al cliente dentro del JSON de ApiError.

    Esta clase es simple pero esencial para mantener una arquitectura clara,
    permitiendo separar la lógica de negocio de la gestión de errores HTTP.
    ============================================================================


 */