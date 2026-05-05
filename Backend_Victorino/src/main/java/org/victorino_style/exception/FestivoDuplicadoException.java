package org.victorino_style.exception;

import java.time.LocalDate;

// Lanzada al intentar añadir un festivo cuya fecha ya existe en la tabla `festivo`.
// Se traduce a HTTP 409 Conflict.
public class FestivoDuplicadoException extends RuntimeException {

    public FestivoDuplicadoException(LocalDate fecha) {
        super("Ya hay un festivo registrado para la fecha " + fecha + ".");
    }
}


/*

    ============================================================================
    FestivoDuplicadoException
    ----------------------------------------------------------------------------
    Esta excepción personalizada se lanza cuando se intenta registrar un festivo
    en una fecha que ya está registrada en la base de datos.

    ¿POR QUÉ ES NECESARIA ESTA EXCEPCIÓN?
    - Permite identificar claramente el caso de error: un festivo duplicado.
    - Facilita que el GlobalExceptionHandler devuelva un HTTP 409 Conflict.
    - Permite que el frontend muestre un mensaje claro y específico al usuario.

    ¿POR QUÉ EXTIENDE RuntimeException?
    - Las RuntimeException no requieren declararse con "throws".
    - Son ideales para errores de negocio que deben interrumpir el flujo normal.
    - Mantiene el código más limpio y evita propagación innecesaria de excepciones.

    ¿QUÉ MENSAJE GENERA?
    - El constructor recibe la fecha duplicada.
    - Construye un mensaje como:
          "Ya hay un festivo registrado para la fecha 2024-12-25."
    - Este mensaje se envía al cliente dentro del JSON de ApiError.

    Esta clase es sencilla pero esencial para mantener una arquitectura clara,
    permitiendo separar la lógica de negocio de la gestión de errores HTTP.
    ============================================================================

 */