package org.victorino_style.exception;

import org.victorino_style.dto.cliente.DetalleCitaExistenteError;

// Lanzada cuando un cliente intenta reservar una cita y ya tiene otra cita ACTIVA
// (CONFIRMADA o EN_PROCESO) en la misma semana ISO (lunes a domingo).
// Se traduce a HTTP 409 Conflict con el campo "detalles" del ApiError relleno.
public class CitaSemanaDuplicadaException extends RuntimeException {

    // Detalle estructurado de la cita ya existente que bloquea la nueva reserva.
    // El handler lo coloca en el campo "detalles" del ApiError para que el frontend
    // pueda construir el mensaje contextual y el botón "Modificar".
    private final DetalleCitaExistenteError detalle;

    public CitaSemanaDuplicadaException(DetalleCitaExistenteError detalle) {
        super("Ya tienes una cita esta semana");
        this.detalle = detalle;
    }

    public DetalleCitaExistenteError getDetalle() {
        return detalle;
    }
}

// ============================================================================
// CitaSemanaDuplicadaException
// ----------------------------------------------------------------------------
// Bloquea la reserva de una segunda cita si el cliente ya tiene una activa esa
// semana (regla 6 del CLAUDE.md). Es de las pocas excepciones que llevan
// payload estructurado: además del mensaje, se devuelve al frontend el id y
// los datos de la cita existente para que pueda ofrecer el botón "Modificar".
//
// CÓMO LA USA EL HANDLER:
// - GlobalExceptionHandler.manejarCitaSemanaDuplicada → ApiError.conDetalles(...).
//
// ¿POR QUÉ EXTIENDE RuntimeException Y NO RecursoNoEncontradoException?
// - Porque NO es un 404, es un 409 (conflicto de negocio).
// ============================================================================
