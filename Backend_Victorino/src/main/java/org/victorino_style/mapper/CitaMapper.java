package org.victorino_style.mapper;

import org.springframework.stereotype.Component;
import org.victorino_style.dto.admin.CitaAdminResponse;
import org.victorino_style.entity.Cita;
import org.victorino_style.entity.Cliente;
import org.victorino_style.entity.ClienteInvitado;

// CitaMapper es una clase encargada de convertir entidades Cita en DTOs,
// en este caso CitaAdminResponse
@Component // indica a Spring que esta clase es un bean que puede inyectarse donde se necesite.
public class CitaMapper {

    public CitaAdminResponse aRespuesta(Cita c) { //Métoddo que recibe una entidad Cita y devuelve un DTO CitaAdminResponse
        // Decide qué identidad de cliente está informada (regla XOR a nivel de BD).
        //Una cita puede tener cliente registrado o cliente invitado, pero nunca ambos (regla XOR).
        Cliente cliente = c.getIdCliente();
        ClienteInvitado invitado = c.getIdClienteInvitado();

        Long idCliente = cliente != null ? cliente.getId() : null; //Si la cita tiene un cliente registrado, se obtiene su ID.
        // Si no, se deja en null (porque los invitados no tienen ID persistente).

        String nombreCliente; // Variables auxiliares para construir el nombre del cliente
        boolean esInvitado; // y marcar si es invitado.



        if (cliente != null) {
            nombreCliente = cliente.getNombreCliente() + " " + cliente.getApellidosCliente();
            esInvitado = false;
            /*
                Caso 1: la cita pertenece a un cliente registrado.

                Se arma el nombre completo.

                esInvitado = false.
             */

        } else if (invitado != null) {
            nombreCliente = invitado.getNombreClienteInvitado() + " " + invitado.getApellidosClienteInvitado();
            esInvitado = true;

            /*Caso 2: la cita pertenece a un cliente invitado.

             Se arma el nombre completo usando los campos de invitado.

             esInvitado = true

             */
        } else {
            // Defensa frente a datos corruptos. La BD no debería permitirlo.
            nombreCliente = "Cliente desconocido";
            esInvitado = false;
        }

        // Se construye el nombre completo del empleado. Estos datos siempre existen porque la BD los marca como NOT NULL
        String nombreEmpleado = c.getIdEmpleado().getNombreEmpleado() + " " + c.getIdEmpleado().getApellidosEmpleado();

        return new CitaAdminResponse(
                c.getId(),
                c.getFechaCita(),
                c.getHoraInicioCita(),
                c.getHoraFinCita(),
                c.getEstadoCita(),
                c.getNotaCita(),
                idCliente,
                nombreCliente,
                esInvitado,
                c.getIdEmpleado().getId(),
                nombreEmpleado,
                c.getIdEmpleado().getFotoEmpleado(),
                c.getIdServicio().getId(),
                c.getIdServicio().getNombreServicio(),
                c.getIdServicio().getDuracionServicio(),
                c.getIdServicio().getPrecioServicio()

                /*
                Se construye el DTO CitaAdminResponse con todos los datos necesarios para
                el panel de administración.

                Incluye: Datos de la cita, Datos del cliente o invitado,
                Datos del empleado, Datos del servicio








                 */
        );
    }
}

/*


        ============================================================================
                CitaMapper
        ----------------------------------------------------------------------------
                Este componente se encarga de transformar una entidad Cita en un DTO
                CitaAdminResponse, que es el formato que el backend envía al panel de
                administración.

        ¿POR QUÉ ES NECESARIO ESTE MAPPER?
                - Evita exponer entidades JPA directamente al frontend.
        - Permite controlar exactamente qué datos se envían.
        - Centraliza la lógica de construcción del DTO, evitando duplicación.
                - Aplica reglas de negocio como la identificación del cliente o invitado.

        ¿QUÉ PROBLEMA RESUELVE?
                - Una cita puede tener un cliente registrado o un cliente invitado (regla XOR).
                - El mapper decide cuál usar y construye un nombre coherente.
                - También arma los datos del empleado y del servicio, garantizando que el
                frontend reciba información completa y lista para mostrar.

                ¿QUÉ DEVUELVE?
                - Un objeto CitaAdminResponse con:
                - Datos de la cita
              - Datos del cliente o invitado
              - Datos del empleado
              - Datos del servicio
        - Todoo en un formato compacto y amigable para el frontend.

                Este mapper es esencial para mantener una arquitectura limpia, separando
                las entidades internas del backend de los datos que realmente necesita
                el cliente.
                ============================================================================
*/