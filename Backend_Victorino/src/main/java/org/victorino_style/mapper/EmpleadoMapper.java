package org.victorino_style.mapper;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import org.victorino_style.dto.admin.EmpleadoAdminResponse;
import org.victorino_style.dto.empleado.PerfilEmpleadoResponse;
import org.victorino_style.entity.Empleado;
import org.victorino_style.entity.HorarioEmpleado;
import org.victorino_style.entity.Usuario;
import org.victorino_style.repository.AdministradorRepository;
import org.victorino_style.repository.HorarioEmpleadoRepository;

// Convierte la entidad Empleado (que arrastra a Usuario por herencia JOINED)
// en DTOs para el panel admin o para el propio perfil del empleado.
@Component
@RequiredArgsConstructor
public class EmpleadoMapper {

    private final AdministradorRepository administradorRepository;
    private final HorarioEmpleadoRepository horarioEmpleadoRepository;

    // Conversión para el panel de administración
    public EmpleadoAdminResponse aRespuesta(Empleado empleado) {
        Usuario usuario = empleado.getUsuario();
        boolean esAdmin = administradorRepository.existsById(empleado.getId());

        HorarioEmpleado horario = horarioEmpleadoRepository
                .findByIdEmpleado_Id(empleado.getId())
                .orElse(null);

        String horaDescanso = null;
        Integer duracionDescansoMinutos = null;
        if (horario != null && horario.getDescansoInicioHorario() != null) {
            String horaStr = horario.getDescansoInicioHorario().toString();
            horaDescanso = horaStr.length() >= 5 ? horaStr.substring(0, 5) : horaStr;
            duracionDescansoMinutos = horario.getDescansoDuracionHorario();
        }

        return new EmpleadoAdminResponse(
                empleado.getId(),
                empleado.getNombreEmpleado(),
                empleado.getApellidosEmpleado(),
                usuario.getCorreoUsuario(),
                null,
                empleado.getFotoEmpleado(),
                usuario.getFechaEliminacionUsuario() == null,
                usuario.getRolUsuario(),
                esAdmin,
                horaDescanso,
                duracionDescansoMinutos
        );
    }

    // Conversión para el perfil propio del empleado
    public PerfilEmpleadoResponse aPerfilRespuesta(Empleado empleado) {
        Usuario usuario = empleado.getUsuario();
        return new PerfilEmpleadoResponse(
                empleado.getId(),
                empleado.getNombreEmpleado(),
                empleado.getApellidosEmpleado(),
                usuario.getCorreoUsuario(),
                empleado.getFotoEmpleado(),
                usuario.getRolUsuario(),
                empleado.getSilencioInicioEmpleado(),
                empleado.getSilencioFinEmpleado(),
                empleado.getNoMolestarEmpleado()
        );
    }
}
