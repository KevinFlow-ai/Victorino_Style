package org.victorino_style.dto.admin;

import org.victorino_style.entity.enums.RolUsuario;

// DTO de salida que devuelve el panel del administrador al consultar empleados.
// Se utiliza tanto en listado como en detalle y tras alta/edición.
public record EmpleadoAdminResponse(

        // Identificador interno del empleado (también es id de la fila `usuario` por herencia JOINED).
        Long idEmpleado,

        // Nombre del empleado.
        String nombre,

        // Apellidos del empleado.
        String apellidos,

        // Correo electrónico.
        String correo,

        // Teléfono. Puede ser null porque es opcional.
        String telefono,

        // Ruta relativa de la foto (ej. "/uploads/empleados/abc.jpg"). Siempre presente porque la foto es obligatoria.
        String fotoUrl,

        // Indica si el empleado está activo. Si es false, el empleado está dado de baja lógicamente.
        boolean activo,

        // Rol del empleado. Se incluye para que el frontend pinte el badge "Administrador" cuando proceda.
        RolUsuario rol,

        // Bandera de conveniencia para el frontend: true si el empleado también es administrador.
        boolean esAdministrador,

        // Hora de inicio del descanso fijo diario en formato "HH:mm".
        // Null si el empleado todavía no tiene descanso configurado.
        String horaDescanso,

        // Duración del descanso en minutos. Null si no está configurado.
        Integer duracionDescansoMinutos
) {
}

// ============================================================================
// EmpleadoAdminResponse
// ----------------------------------------------------------------------------
// Respuesta JSON para el panel admin cuando consulta o modifica empleados.
//
// ¿PARA QUÉ SIRVE?
// - Se devuelve en GET /admin/empleados, GET /admin/empleados/{id},
//   POST /admin/empleados, PUT /admin/empleados/{id}.
// - EmpleadoMapper transforma `Empleado` (+ `Usuario`) en este DTO.
//
// CAMPO `activo`:
// - Se calcula en el mapper como `usuario.fechaEliminacionUsuario == null`.
// - El frontend usa este flag para pintar la card en gris (escala de grises)
//   cuando es false, según el mockup de gestión de empleados.
//
// CAMPO `esAdministrador`:
// - Se calcula consultando si existe fila en la tabla `administrador`.
// - Lo usa el frontend para pintar el badge "Administrador" y deshabilitar
//   el botón de baja sobre el propio admin (autoprotección visual).
//
// ¿POR QUÉ NO INCLUIMOS LA CONTRASEÑA?
// - Las contraseñas NUNCA salen en respuestas. Son hash BCrypt y se quedan
//   exclusivamente en la columna `contrasena_usuario`.
// ============================================================================
