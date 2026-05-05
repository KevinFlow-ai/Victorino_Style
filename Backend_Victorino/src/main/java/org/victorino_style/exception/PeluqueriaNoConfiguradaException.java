package org.victorino_style.exception;

// Lanzada cuando se intenta operar sobre la peluquería singleton y la fila no existe en BD.
// Se traduce a HTTP 500 porque indica un fallo de inicialización del proyecto:
// el seed.sql debe insertar la fila antes de cualquier uso.
public class PeluqueriaNoConfiguradaException extends RuntimeException {

    public PeluqueriaNoConfiguradaException() {
        super("La peluquería no está configurada. Ejecuta el seed.sql antes de operar.");
    }
}


/*
        ============================================================================
        PeluqueriaNoConfiguradaException
        ----------------------------------------------------------------------------
        Esta excepción se lanza cuando la aplicación intenta acceder a información
        básica de la peluquería (horarios, servicios, configuración inicial, etc.)
        pero dicha información no existe en la base de datos.

        ¿POR QUÉ ES NECESARIA ESTA EXCEPCIÓN?
        - Permite detectar un error crítico de configuración inicial.
        - Evita que el sistema funcione en un estado inconsistente o incompleto.
        - Facilita que el GlobalExceptionHandler devuelva un HTTP 500 o 503,
          indicando que el servidor no está correctamente preparado.
        - Permite mostrar al administrador un mensaje claro sobre qué falta.

        ¿POR QUÉ EXTIENDE RuntimeException?
        - Las RuntimeException no requieren declararse con "throws".
        - Son ideales para errores de negocio o de estado que deben detener el flujo.
        - Mantiene el código más limpio y evita propagación innecesaria.

        ¿QUÉ MENSAJE GENERA?
        - El mensaje indica explícitamente:
              "La peluquería no está configurada. Ejecuta el seed.sql antes de operar."
        - Esto ayuda a identificar rápidamente el problema y su solución.

        Esta clase es simple pero esencial para garantizar que la aplicación no
        funcione sin la configuración mínima necesaria para operar correctamente.
        ============================================================================

 */