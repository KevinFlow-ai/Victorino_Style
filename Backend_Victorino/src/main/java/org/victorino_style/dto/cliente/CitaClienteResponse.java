package org.victorino_style.dto.cliente;

import org.victorino_style.entity.enums.EstadoCita;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalTime;

// DTO de salida con los datos de una cita pensada para la app del cliente.
// Devuelto por GET /cliente/citas, GET /cliente/citas/{id}, GET /cliente/citas/activa,
// POST /cliente/citas, PUT /cliente/citas/{id}.
public record CitaClienteResponse(

        // Identificador único de la cita.
        Long idCita,

        // Día de la cita (YYYY-MM-DD).
        LocalDate fecha,

        // Hora de inicio (HH:mm:ss).
        LocalTime horaInicio,

        // Hora de fin (calculada como inicio + duracion del servicio).
        LocalTime horaFin,

        // Estado actual: CONFIRMADA / EN_PROCESO / COMPLETADA / CANCELADA_CLIENTE /
        // CANCELADA_PELUQUERIA / NO_PRESENTADO.
        EstadoCita estado,

        // Nota libre que el cliente o el empleado dejaron. Null si nadie escribió nada.
        String nota,

        // Datos del empleado asignado.
        Long idEmpleado,
        String nombreEmpleado,
        String apellidosEmpleado,
        // Ruta relativa de la foto del empleado (siempre presente).
        String fotoEmpleado,

        // Datos del servicio reservado.
        Long idServicio,
        String nombreServicio,
        Integer duracionMinutos,
        BigDecimal precioServicio,
        // Ruta relativa de la foto del servicio (siempre presente).
        String fotoServicio
) {
}

// ============================================================================
// CitaClienteResponse
// ----------------------------------------------------------------------------
// Vista de una cita pensada para la app del cliente final. Más enriquecida que
// CitaAdminResponse en cuanto a fotos (incluye foto del servicio además de la
// del empleado) porque las pantallas del cliente las muestran prominentemente.
//
// NO INCLUYE datos del cliente porque siempre es el propio usuario autenticado
// (el frontend ya los tiene en sesionProvider).
//
// REUTILIZADO POR:
//   - Home: card "Mi próxima cita" → /cliente/citas/activa.
//   - Historial: lista completa → /cliente/citas.
//   - Detalle: → /cliente/citas/{id}.
//   - Confirmación tras reservar/modificar.
// ============================================================================
