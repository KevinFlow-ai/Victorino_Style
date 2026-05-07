package org.victorino_style.mapper;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import org.victorino_style.dto.admin.EmpleadoAdminResponse;
import org.victorino_style.entity.Empleado;
import org.victorino_style.entity.HorarioEmpleado;
import org.victorino_style.entity.Usuario;
import org.victorino_style.repository.AdministradorRepository;
import org.victorino_style.repository.HorarioEmpleadoRepository;

// Convierte la entidad Empleado (que arrastra a Usuario por herencia JOINED)
// en EmpleadoAdminResponse para devolverla al panel admin.
// Necesita AdministradorRepository para detectar si el empleado también es administrador.
@Component
@RequiredArgsConstructor
public class EmpleadoMapper {

    private final AdministradorRepository administradorRepository;
    private final HorarioEmpleadoRepository horarioEmpleadoRepository;

    // Conversión simple: extrae los campos del empleado y enriquece con flags y descanso.
    public EmpleadoAdminResponse aRespuesta(Empleado empleado) {
        // Recupera el usuario relacionado para sacar correo, rol y estado de eliminación.
        Usuario usuario = empleado.getUsuario();

        // Comprueba si la fila tiene también una entrada en la tabla `administrador`.
        boolean esAdmin = administradorRepository.existsById(empleado.getId());

        // Recupera el descanso fijo del empleado si ya está configurado.
        HorarioEmpleado horario = horarioEmpleadoRepository
                .findByIdEmpleado_Id(empleado.getId())
                .orElse(null);

        String horaDescanso = null;
        Integer duracionDescansoMinutos = null;
        if (horario != null) {
            // LocalTime.toString() devuelve "HH:mm" o "HH:mm:ss" según tenga segundos;
            // recortamos a 5 caracteres para garantizar siempre el formato "HH:mm".
            String horaStr = horario.getDescansoInicioHorario().toString();
            horaDescanso = horaStr.length() >= 5 ? horaStr.substring(0, 5) : horaStr;
            duracionDescansoMinutos = horario.getDescansoDuracionHorario();
        }

        return new EmpleadoAdminResponse(
                empleado.getId(),
                empleado.getNombreEmpleado(),
                empleado.getApellidosEmpleado(),
                usuario.getCorreoUsuario(),
                null, // teléfono: la entidad Empleado no lo guarda; el módulo cliente sí
                empleado.getFotoEmpleado(),
                usuario.getFechaEliminacionUsuario() == null,
                usuario.getRolUsuario(),
                esAdmin,
                horaDescanso,
                duracionDescansoMinutos
        );
    }
}

// Un "mapper" es una clase cuya única responsabilidad es TRANSFORMAR datos
// de un tipo a otro. En este caso, convierte una entidad de base de datos
// (Servicio) en un DTO que se envía al cliente (ServicioAdminResponse).
//
// La idea es separar la lógica interna del modelo de la estructura que
// realmente expones en la API. Esto mantiene el código limpio, modular
// y evita exponer directamente las entidades de la BD.