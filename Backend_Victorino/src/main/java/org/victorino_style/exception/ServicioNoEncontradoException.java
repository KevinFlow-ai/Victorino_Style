package org.victorino_style.exception;

// Lanzada cuando un id de servicio no existe en BD o el servicio está dado de baja lógica.
// El handler global la traduce a HTTP 404 Not Found.
public class ServicioNoEncontradoException extends RecursoNoEncontradoException {

    // Constructor con el id del servicio para construir un mensaje claro.
    public ServicioNoEncontradoException(Long idServicio) {
        super("No existe un servicio activo con id " + idServicio);
    }
}
