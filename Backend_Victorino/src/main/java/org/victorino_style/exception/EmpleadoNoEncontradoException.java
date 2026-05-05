package org.victorino_style.exception;

// Lanzada por EmpleadoService / CitaService / ConfiguracionService cuando un id de empleado
// no existe en BD o pertenece a un empleado dado de baja lógica.
// El handler global la traduce a HTTP 404 Not Found.
public class EmpleadoNoEncontradoException extends RecursoNoEncontradoException {

    // Constructor con el id del empleado para construir un mensaje claro.
    public EmpleadoNoEncontradoException(Long idEmpleado) {
        super("No existe un empleado activo con id " + idEmpleado);
    }
}
/*
============================================================================
EmpleadoNoEncontradoException
----------------------------------------------------------------------------
Esta excepción personalizada se lanza cuando un servicio intenta obtener
un empleado por su ID y dicho empleado no existe o no está activo en la BD.

¿POR QUÉ ES NECESARIA ESTA EXCEPCIÓN?
        - Permite distinguir este caso concreto del resto de errores de "no encontrado".
        - Facilita que el GlobalExceptionHandler devuelva un HTTP 404 Not Found.
        - Ayuda a que el frontend pueda mostrar un mensaje claro al usuario.

        ¿POR QUÉ EXTIENDE RecursoNoEncontradoException?
        - Mantiene una jerarquía limpia de excepciones de "recurso no encontrado".
        - Permite que todas estas excepciones se manejen de forma uniforme.
        - A la vez, permite identificar específicamente cuándo el recurso faltante es un empleado.

        ¿QUÉ MENSAJE GENERA?
        - El constructor recibe el id del empleado buscado.
        - Construye un mensaje como:
        "No existe un empleado activo con id 15"
        - Este mensaje se envía al cliente dentro del JSON de ApiError.

Esta clase es simple pero esencial para mantener una arquitectura clara,
separando la lógica de negocio de la gestión de errores HTTP.
============================================================================


 */