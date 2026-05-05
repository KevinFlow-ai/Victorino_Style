package org.victorino_style.dto.admin;

import jakarta.validation.constraints.AssertTrue;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.time.LocalDate;
import java.time.LocalTime;

// DTO de entrada para crear una cita manual ("walk-in") desde el panel del administrador.
// La cita puede ser para un cliente registrado (idCliente) o para un cliente sin cuenta
// (nombre + apellidos + telefono opcional). Se aplica la regla XOR: exactamente uno.
public record WalkInRequest(

        // Empleado que atenderá la cita.
        @NotNull(message = "El empleado es obligatorio")
        Long idEmpleado,

        // Servicio que se va a realizar.
        @NotNull(message = "El servicio es obligatorio")
        Long idServicio,

        // Fecha de la cita.
        @NotNull(message = "La fecha es obligatoria")
        LocalDate fecha,

        // Hora de inicio (HH:mm).
        @NotNull(message = "La hora de inicio es obligatoria")
        LocalTime horaInicio,

        // Cliente registrado (puede ser null si la cita es para un walk-in).
        Long idCliente,

        // Datos del cliente sin cuenta (todos null si se usa idCliente).
        @Size(max = 100, message = "El nombre del invitado no puede superar los 100 caracteres")
        String nombreInvitado,

        @Size(max = 150, message = "Los apellidos del invitado no pueden superar los 150 caracteres")
        String apellidosInvitado,

        @Size(max = 20, message = "El teléfono del invitado no puede superar los 20 caracteres")
        String telefonoInvitado,

        // Nota opcional para el empleado.
        @Size(max = 350, message = "La nota no puede superar los 350 caracteres")
        String nota
) {

    // Valida que exactamente UNA de las dos identidades esté informada (cliente XOR invitado).
    @AssertTrue(message = "Debe indicarse un cliente registrado o los datos de un invitado, pero no ambos")
    public boolean esIdentidadValida() {
        boolean esCliente = idCliente != null;
        boolean esInvitado = nombreInvitado != null && !nombreInvitado.isBlank()
                && apellidosInvitado != null && !apellidosInvitado.isBlank();
        return esCliente ^ esInvitado;
    }
}

// ============================================================================
// WalkInRequest
// ----------------------------------------------------------------------------
// DTO para crear una cita manual desde el panel del administrador, sea para
// un cliente registrado o para un cliente que llega sin cuenta (walk-in).
//
// ¿PARA QUÉ SIRVE?
// - Endpoint POST /admin/citas/walk-in.
// - AgendaAdminService valida disponibilidad (sin solape, dentro de
//   horario, fuera de descanso del empleado, no festivo, no cierre anual)
//   y crea la cita.
//
// REGLA XOR (CRÍTICA):
// - El métodoo `esIdentidadValida()` es una validación @AssertTrue que se
//   ejecuta automáticamente con @Valid. Garantiza que la cita apunta a
//   un cliente registrado O a un cliente invitado, nunca ambos ni ninguno.
// - El backend convierte automáticamente los datos de invitado en una
//   fila de `cliente_invitado` antes de crear la cita.
//
// HORA DE FIN:
// - No se incluye en la petición. El servicio la calcula como
//   `horaInicio + servicio.duracionServicio` antes de persistir.
// ============================================================================
