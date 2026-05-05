package org.victorino_style.exception;

// Excepción genérica para indicar que un recurso identificado por un id no existe
// (o existe pero está soft-deleted). El handler global la traduce a HTTP 404.
public class RecursoNoEncontradoException extends RuntimeException {

    // Constructor con un mensaje libre.
    public RecursoNoEncontradoException(String mensaje) {
        super(mensaje);
    }
}

// ============================================================================
// RecursoNoEncontradoException
// ----------------------------------------------------------------------------
// Padre genérico de todas las excepciones de "recurso 404" del proyecto.
//
// ¿PARA QUÉ SIRVE?
// - Los servicios la lanzan cuando una búsqueda por id devuelve Optional.empty()
//   o cuando la fila existe pero tiene fecha_eliminacion no nula.
// - GlobalExceptionHandler la captura y devuelve HTTP 404 Not Found con el
//   mensaje recibido.
//
// SE USA COMO PADRE DE:
// - EmpleadoNoEncontradoException
// - ServicioNoEncontradoException
// - PeluqueriaNoConfiguradaException (en este caso 500, ver mapeo del handler)
// ============================================================================

/*
        ============================================================================
        RecursoNoEncontradoException
        ----------------------------------------------------------------------------
        Esta excepción representa un error genérico cuando un recurso solicitado
        no existe en la base de datos o no está disponible.

        ¿POR QUÉ ES NECESARIA ESTA EXCEPCIÓN?
                - Sirve como clase base para excepciones más específicas como:
        EmpleadoNoEncontradoException
                ClienteNoEncontradoException
        ServicioNoEncontradoException
        - Permite mantener una jerarquía clara y coherente de errores.
        - Facilita que el GlobalExceptionHandler capture todos los casos de
          “recurso no encontrado” y devuelva un HTTP 404 Not Found.

                ¿POR QUÉ EXTIENDE RuntimeException?
                - Las RuntimeException no requieren declararse con "throws".
                - Son ideales para errores de negocio que deben interrumpir el flujo normal.
                - Mantienen el código más limpio y evitan propagación innecesaria.

        ¿QUÉ MENSAJE GENERA?
                - El constructor recibe un mensaje libre.
                - Las clases hijas lo utilizan para construir mensajes como:
                "No existe un empleado activo con id 10"
                "No se encontró el servicio solicitado"
                - Este mensaje se envía al cliente dentro del JSON de ApiError.

        Esta clase es fundamental para estructurar correctamente la gestión de
        errores en la aplicación, permitiendo reutilizar lógica y mantener una
        arquitectura limpia y escalable.
                ============================================================================


 */