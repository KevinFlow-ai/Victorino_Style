package org.victorino_style.dto.cliente;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.time.LocalDate;
import java.time.LocalTime;

// DTO de entrada para modificar una cita ya CONFIRMADA del cliente.
// Lo recibe PUT /cliente/citas/{id}. Permite cambiar servicio, empleado, fecha,
// hora y nota — el cliente puede ajustar todo desde el wizard precargado.
public record ModificarCitaRequest(

        // Servicio (puede cambiar respecto al original).
        @NotNull(message = "El servicio es obligatorio")
        Long idServicio,

        // Empleado (puede cambiar). NULLABLE: si es null se asigna "Cualquiera disponible".
        Long idEmpleado,

        // Fecha. Obligatoria, validada entre hoy y hoy+30 días.
        @NotNull(message = "La fecha es obligatoria")
        LocalDate fecha,

        // Hora de inicio. Obligatoria. La hora_fin se recalcula con la nueva duración del servicio.
        @NotNull(message = "La hora de inicio es obligatoria")
        LocalTime horaInicio,

        // Nota opcional, máx. 280 caracteres.
        @Size(max = 280, message = "La nota no puede superar los 280 caracteres")
        String nota,

        // Flag "Cualquiera disponible" igual que en ReservarCitaRequest. Solo se aplica si la
        // nueva franja del idEmpleado concreto esta ocupada y el cliente habia elegido cualquiera.
        Boolean cualquieraDisponible
) {
}

// ============================================================================
// ModificarCitaRequest
// ----------------------------------------------------------------------------
// Cuerpo del wizard cuando se entra en MODO EDICIÓN desde:
//   - Botón "Modificar" en la card "Mi próxima cita" del Home.
//   - 409 CITA_MISMA_SEMANA / CITA_MISMO_DIA → botón "Modificar la existente".
//
// REGLAS:
//   - Solo se permite si la cita está en estado CONFIRMADA (cualquier otro
//     estado → CitaNoModificableException 409).
//   - El cliente puede cambiar TODOS los campos (servicio, empleado, fecha, hora, nota)
//     (decisión consolidada con el usuario).
//   - El cálculo de disponibilidad excluye la propia cita para que no aparezca
//     como ocupada en su franja actual.
//
// CONCURRENCIA:
//   - Se carga la cita con @Lock(PESSIMISTIC_WRITE).
//   - El @Version de la entidad Cita detecta pisadas paralelas
//     (OptimisticLockException → 409 HUECO_OCUPADO).
//
// NOTIFICACIONES:
//   - Al empleado: tipo MODIFICACION_CITA (nuevo en el enum, ver migración de schema.sql).
//
// AUDITORÍA:
//   - Acción "MODIFICAR_CITA" con detalle "{id} de {fechaOriginal}_{horaOriginal} a {fechaNueva}_{horaNueva}".
// ============================================================================
