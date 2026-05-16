package org.victorino_style.mapper;

import org.springframework.stereotype.Component;
import org.victorino_style.dto.cliente.CitaClienteResponse;
import org.victorino_style.entity.Cita;
import org.victorino_style.entity.Empleado;
import org.victorino_style.entity.Servicio;

// Mapper que transforma una entidad Cita en su DTO CitaClienteResponse para la app del cliente.
// A diferencia de CitaMapper (panel admin), aqui:
//   - NO se incluyen datos del cliente (la cita siempre es del usuario autenticado).
//   - SI se incluye la foto del servicio (las pantallas del cliente la muestran).
//   - Se separa el nombre y los apellidos del empleado (mejor UX en la card).
@Component
public class CitaClienteMapper {

    // Convierte la entidad en el DTO publico que ve la app del cliente.
    public CitaClienteResponse aRespuesta(Cita c) {
        Empleado empleado = c.getIdEmpleado();
        Servicio servicio = c.getIdServicio();

        return new CitaClienteResponse(
                c.getId(),
                c.getFechaCita(),
                c.getHoraInicioCita(),
                c.getHoraFinCita(),
                c.getEstadoCita(),
                c.getNotaCita(),
                empleado.getId(),
                empleado.getNombreEmpleado(),
                empleado.getApellidosEmpleado(),
                empleado.getFotoEmpleado(),
                servicio.getId(),
                servicio.getNombreServicio(),
                servicio.getDuracionServicio(),
                servicio.getPrecioServicio(),
                servicio.getFotoServicio()
        );
    }
}

// ============================================================================
// CitaClienteMapper
// ----------------------------------------------------------------------------
// Componente Spring que convierte una `Cita` en un `CitaClienteResponse`.
//
// ¿POR QUE OTRO MAPPER ADEMAS DE CitaMapper?
//   Las pantallas del cliente y del admin muestran informacion distinta:
//     - El admin necesita ver QUIEN es el cliente (registrado o invitado).
//     - El cliente solo ve "sus" citas, asi que no hace falta repetir esos datos.
//     - El cliente quiere ver fotos prominentes del empleado y del servicio,
//       por eso ambas se exponen aqui (la del admin solo trae la del empleado).
//
// PATRON DE USO:
//   - CitaClienteService inyecta este mapper.
//   - Tras crear/modificar una cita o devolverla en un GET, llama a
//     mapper.aRespuesta(cita) y devuelve el DTO al controller.
//
// EXCEPCION DE DATOS:
//   - Si la cita fuera de un walk-in (id_cliente null), este mapper sigue
//     funcionando porque NO accede a getIdCliente(). Aun asi, el servicio
//     del cliente nunca debe devolver citas de invitados al cliente final.
// ============================================================================
