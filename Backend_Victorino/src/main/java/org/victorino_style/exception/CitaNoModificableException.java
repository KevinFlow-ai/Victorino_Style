package org.victorino_style.exception;

// Esta clase define una EXCEPCIÓN PERSONALIZADA para el caso en que
// una cita NO pueda modificarse (por ejemplo, porque ya está finalizada,
// cancelada o en un estado que no permite cambios).

public class CitaNoModificableException extends RuntimeException {

    // Constructor que recibe el ID de la cita y genera un mensaje automático.
    // Se usa cuando quieres indicar claramente qué cita no se puede modificar.
    public CitaNoModificableException(Long idCita) {
        super("La cita " + idCita + " no se puede modificar en su estado actual.");
    }

    // Constructor alternativo que permite enviar un mensaje personalizado.
    // Útil cuando el motivo del error es más específico.
    public CitaNoModificableException(String mensaje) {
        super(mensaje);
    }
}

