package org.victorino_style.dto.admin;

import org.victorino_style.entity.enums.TipoFestivo;

import java.time.LocalDate;

// DTO de salida que representa un festivo del calendario de la peluquería.
public record FestivoResponse(

        // Identificador interno del festivo.
        Long idFestivo,

        // Fecha concreta del festivo.
        LocalDate fecha,

        // Descripción visible (ej. "Día del Trabajo").
        String descripcion,

        // Tipo de festivo (NACIONAL, AUTONOMICO, LOCAL, VACACIONES, MANTENIMIENTO).
        TipoFestivo tipo
) {
}

// ============================================================================
// FestivoResponse
// ----------------------------------------------------------------------------
// Respuesta con un festivo registrado en el calendario.
//
// ¿PARA QUÉ SIRVE?
// - GET /admin/festivos devuelve una lista ordenada cronológicamente.
// - POST /admin/festivos devuelve el recién creado.
//
// FRONTEND:
// - La sección "Festivos" del panel de Negocio pinta cada elemento con un
//   chip de color según el tipo y un botón para eliminar
//   (DELETE /admin/festivos/{id}).
// ============================================================================
