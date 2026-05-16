package org.victorino_style.exception;

// Lanzada cuando el cliente intenta reservar una cita con fecha anterior a hoy o
// posterior al límite de 30 días naturales (regla 5 del CLAUDE.md).
// Se traduce a HTTP 409 Conflict.
public class CitaFueraDeAntelacionException extends RuntimeException {

    // Constructor con mensaje personalizado para distinguir "fecha pasada"
    // de "fecha más allá de 30 días" según convenga al servicio.
    public CitaFueraDeAntelacionException(String mensaje) {
        super(mensaje);
    }

    // Constructor por defecto con mensaje genérico.
    public CitaFueraDeAntelacionException() {
        super("La fecha debe estar entre hoy y los próximos 30 días naturales");
    }
}

// ============================================================================
// CitaFueraDeAntelacionException
// ----------------------------------------------------------------------------
// Aplica la regla "antelación máxima 30 días, mínima 0" del CLAUDE.md.
//
// CASOS QUE LA DISPARAN:
// - El cliente envía una fecha anterior a hoy (LocalDate.now()).
// - El cliente envía una fecha posterior a hoy+30 días.
//
// EL FRONTEND DEBERÍA HABER PREVENIDO ESTO ya que solo muestra chips de 0 a 30
// días en el Paso 3 del wizard. Esta excepción actúa como red de seguridad para
// llamadas directas a la API (curl, Postman) o relojes desfasados.
// ============================================================================
