package org.victorino_style.dto.admin;

import org.victorino_style.entity.enums.EstadoCita;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalTime;

// DTO de salida con los datos completos de una cita para la vista del administrador.
// Incluye datos del cliente (registrado o invitado), del empleado y del servicio
// para que el frontend no tenga que hacer llamadas adicionales.
public record CitaAdminResponse(

        // Identificador único de la cita.
        Long idCita,

        // Día de la cita.
        LocalDate fecha,

        // Hora de inicio.
        LocalTime horaInicio,

        // Hora de fin (calculada como inicio + duracion del servicio).
        LocalTime horaFin,

        // Estado actual de la cita.
        EstadoCita estado,

        // Nota opcional dejada por el cliente o el empleado.
        String nota,

        // Datos del cliente. Uno de los dos campos siguientes es null por la regla XOR.
        // ID del cliente registrado (null si la cita es de un cliente invitado).
        Long idCliente,
        // Nombre completo del cliente registrado o invitado.
        String nombreCliente,
        // Indica si el cliente es un walk-in (true) o un cliente con cuenta (false).
        boolean esInvitado,

        // Datos del empleado.
        Long idEmpleado,
        String nombreEmpleado,
        String fotoEmpleado,

        // Datos del servicio.
        Long idServicio,
        String nombreServicio,
        Integer duracionMinutos,
        BigDecimal precioServicio
) {
}

// ============================================================================
// CitaAdminResponse
// ----------------------------------------------------------------------------
// Vista de una cita pensada para el panel del administrador.
//
// ¿PARA QUÉ SIRVE?
// - Lo devuelven GET /admin/agenda y POST /admin/citas/walk-in.
// - El frontend pinta una card con: badge de servicio coloreado, hora,
//   nombre cliente, nombre empleado, estado y nota.
//
// CAMPOS COMPUESTOS:
// - `nombreCliente` se compone como "nombre + apellidos" tanto para
//   `Cliente` como para `ClienteInvitado` (ambos tienen los dos campos).
// - `fotoEmpleado` viene como ruta relativa (ej. "/uploads/empleados/...").
//
// CAMPO `esInvitado`:
// - true cuando la cita pertenece a un cliente_invitado (walk-in).
// - El frontend usa este flag para pintar una etiqueta "Walk-in" en la card.
// ============================================================================
