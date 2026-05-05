package org.victorino_style.dto.admin;

import java.time.LocalTime;

// DTO de salida con el horario semanal actual de la peluquería.
// Lo devuelve HorarioAdminController en GET /admin/horario y PUT /admin/horario.
public record HorarioPeluqueriaResponse(

        // Identificador del singleton (siempre 1, pero se incluye por completitud).
        Long idPeluqueria,

        // Nombre comercial de la peluquería (sale del seed: "Victorino Style").
        String nombre,

        // Horario por día (null en cualquiera de las dos columnas implica día cerrado).
        LocalTime aperturaLunes,
        LocalTime cierreLunes,
        LocalTime aperturaMartes,
        LocalTime cierreMartes,
        LocalTime aperturaMiercoles,
        LocalTime cierreMiercoles,
        LocalTime aperturaJueves,
        LocalTime cierreJueves,
        LocalTime aperturaViernes,
        LocalTime cierreViernes,
        LocalTime aperturaSabado,
        LocalTime cierreSabado,
        LocalTime aperturaDomingo,
        LocalTime cierreDomingo
) {
}

// ============================================================================
// HorarioPeluqueriaResponse
// ----------------------------------------------------------------------------
// Respuesta con el horario semanal de la peluquería en su estado actual.
//
// ¿PARA QUÉ SIRVE?
// - GET /admin/horario: el frontend pinta los pares apertura/cierre por día.
// - PUT /admin/horario: tras guardar, devuelve el estado actualizado.
//
// FORMATO DE LAS HORAS:
// - LocalTime se serializa como "HH:mm:ss" (ej. "10:00:00"). El frontend
//   muestra solo "10:00".
//
// FRONTEND:
// - La sección "Shop Hours" del mockup `gestion_peluqueria_admin.jpeg`
//   consume este DTO para pintar los selectores de día y hora.
// ============================================================================
