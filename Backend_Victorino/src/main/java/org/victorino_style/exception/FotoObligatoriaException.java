package org.victorino_style.exception;

// Lanzada cuando un endpoint de subida de foto no recibe el archivo o el archivo está vacío.
// El handler global la traduce a HTTP 400 Bad Request.
public class FotoObligatoriaException extends RuntimeException {

    public FotoObligatoriaException() {
        super("La foto es obligatoria. Adjunta una imagen válida.");
    }

    public FotoObligatoriaException(String mensaje) {
        super(mensaje);
    }
}

/*
============================================================================
FotoObligatoriaException
----------------------------------------------------------------------------
Esta excepción se lanza cuando un endpoint que requiere la subida de una
imagen (por ejemplo, la foto de un empleado o un servicio) no recibe el
archivo o recibe un archivo vacío.

        ¿POR QUÉ ES NECESARIA ESTA EXCEPCIÓN?
        - Permite detectar de forma clara un error común en endpoints multipart.
- Evita que el backend procese solicitudes incompletas.
- El GlobalExceptionHandler la convierte en un HTTP 400 Bad Request,
indicando al cliente que la petición está mal formada.

¿POR QUÉ EXTIENDE RuntimeException?
        - Las RuntimeException no requieren declararse con "throws".
        - Son ideales para errores de validación o negocio que deben interrumpir
el flujo normal de ejecución.
- Mantiene el código más limpio y evita propagación innecesaria.

¿QUÉ MENSAJE GENERA?
        - El constructor por defecto devuelve:
        "La foto es obligatoria. Adjunta una imagen válida."
        - También permite enviar un mensaje personalizado si se usa el segundo
constructor.

Esta clase es esencial para garantizar que los endpoints que requieren
una imagen funcionen correctamente y que el cliente reciba un mensaje
claro cuando no se adjunta la foto.
============================================================================


 */