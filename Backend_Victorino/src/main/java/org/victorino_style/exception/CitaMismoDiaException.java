package org.victorino_style.exception;

import org.victorino_style.dto.cliente.DetalleCitaExistenteError;

// Lanzada cuando un cliente intenta reservar una cita y ya tiene otra cita ACTIVA
// el mismo día. Es una regla más estricta que la de "una cita por semana": aunque
// la cita existente esté hoy y la nueva fuera para hoy a otra hora distinta, se
// rechaza igualmente. Se traduce a HTTP 409 Conflict.
public class CitaMismoDiaException extends RuntimeException {

    // Detalle estructurado de la cita ya existente que bloquea la nueva reserva.
    private final DetalleCitaExistenteError detalle;

    public CitaMismoDiaException(DetalleCitaExistenteError detalle) {
        super("Ya tienes una cita este día");
        this.detalle = detalle;
    }

    public DetalleCitaExistenteError getDetalle() {
        return detalle;
    }
}

// ============================================================================
// CitaMismoDiaException
// ----------------------------------------------------------------------------
// Aplica la regla "1 cita por día por cliente" (regla 6 del CLAUDE.md, derivada
// de la regla semanal). Si el cliente ya tiene una cita activa hoy y trata de
// reservar otra para hoy, este 409 dispara un modal en el frontend con
// "Modificar la existente" como única acción.
//
// El admin/empleado SÍ puede crear walk-in para el mismo cliente el mismo día
// (esto lo gestiona CitaService, no esta excepción que solo se lanza desde el
// flujo del cliente).
// ============================================================================
