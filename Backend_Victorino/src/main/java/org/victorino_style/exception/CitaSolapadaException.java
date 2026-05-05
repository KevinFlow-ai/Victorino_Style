package org.victorino_style.exception;

// Lanzada cuando una nueva cita choca con otra existente del mismo empleado o queda fuera del
// horario / dentro del descanso / festivo / cierre anual. Se traduce a HTTP 409 Conflict.


// Esta clase define una EXCEPCIÓN PERSONALIZADA que se lanza cuando
// una cita NO puede crearse o modificarse porque se SOLAPA con otra
// en la misma franja horaria.
//
// Extiende RuntimeException, por lo que es una excepción NO comprobada
// (no requiere try/catch obligatorio).
//
// Tiene dos constructores:
//
// 1) Uno que recibe un mensaje personalizado, útil cuando quieres
//    indicar exactamente qué franja está ocupada.
//
// 2) Otro sin parámetros que usa un mensaje por defecto:
//    "La franja horaria solicitada no está disponible."

public class CitaSolapadaException extends RuntimeException {

    // Constructor con mensaje personalizado.
    public CitaSolapadaException(String mensaje) {
        super(mensaje);
    }

    // Constructor con mensaje por defecto.
    public CitaSolapadaException() {
        super("La franja horaria solicitada no está disponible.");
    }
}

