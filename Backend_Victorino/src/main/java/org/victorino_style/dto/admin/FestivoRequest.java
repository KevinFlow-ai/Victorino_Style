package org.victorino_style.dto.admin;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import org.victorino_style.entity.enums.TipoFestivo;

import java.time.LocalDate;

// DTO de entrada para añadir un festivo personalizado al calendario de la peluquería.
// Lo recibe HorarioAdminController en POST /admin/festivos.
// DTO de entrada (request) para crear o registrar un festivo en el sistema.
// Este record se utiliza cuando el administrador quiere añadir un nuevo día festivo
// al calendario de la peluquería.
//
// Un "record" en Java es una clase inmutable pensada para transportar datos,
// ideal para requests porque:
// - Es conciso y fácil de leer
// - Genera automáticamente constructor, getters, equals, hashCode y toString
// - Garantiza que los valores no cambian una vez creado el objeto
//
// Este DTO contiene:
// - fecha: día exacto del festivo (sin hora). Debe ser único en la base de datos.
// - descripcion: texto legible que explica el motivo del festivo.
// - tipo: categoría del festivo (por ejemplo: FESTIVO_NACIONAL, MANTENIMIENTO, EVENTO_INTERNO, etc.)
//
// Además, incluye validaciones con anotaciones:
// - @NotNull: obliga a que el campo no sea null
// - @NotBlank: obliga a que el texto no esté vacío
// - @Size: limita la longitud máxima de la descripción
//
// Si alguna validación falla, Spring devolverá automáticamente un error 400 Bad Request.

public record FestivoRequest(

        // Fecha concreta del festivo (sin hora). Debe ser única en la tabla.
        @NotNull(message = "La fecha del festivo es obligatoria")
        LocalDate fecha,

        // Descripción legible: "Día del Trabajo", "Mantenimiento general", etc.
        @NotBlank(message = "La descripción del festivo es obligatoria")
        @Size(max = 150, message = "La descripción no puede superar los 150 caracteres")
        String descripcion,

        // Tipo de festivo. Útil para clasificación y filtros en el panel.
        @NotNull(message = "El tipo de festivo es obligatorio")
        TipoFestivo tipo

) {
        // No se necesita cuerpo adicional a menos que quieras métodos extra.
}


// ============================================================================
// FestivoRequest
// ----------------------------------------------------------------------------
// DTO para registrar un día concreto en el que la peluquería NO abre.
//
// ¿PARA QUÉ SIRVE?
// - Endpoint POST /admin/festivos.
// - HorarioAdminService valida que no exista ya un festivo con esa fecha
//   (FestivoDuplicadoException → 409) y crea la fila.
//
// EFECTO EN LA RESERVA:
// - Cualquier festivo bloquea el día completo, sea cual sea el `tipo`.
// - El cliente verá ese día en gris en el calendario y no podrá reservar.
//
// CAMPOS:
// - `fecha`: única (constraint UNIQUE en BD).
// - `descripcion`: máx. 150 caracteres (igual que la columna).
// - `tipo`: una de las cinco opciones del enum TipoFestivo.
// ============================================================================
