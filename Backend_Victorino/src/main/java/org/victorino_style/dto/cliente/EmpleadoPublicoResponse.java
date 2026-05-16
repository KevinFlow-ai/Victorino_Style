package org.victorino_style.dto.cliente;

// DTO ligero del catálogo de empleados para el cliente final.
// Devuelve solo lo que el cliente debe ver al reservar: id, nombre, apellidos y foto.
// NO expone correo, teléfono, configuración de silencio ni flag activo (ya filtrado).
//
// Usado por: GET /empleados (autenticado, cualquier rol). El admin tiene
// EmpleadoAdminResponse con más campos para su panel.
public record EmpleadoPublicoResponse(

        // Identificador del empleado.
        Long idEmpleado,

        // Nombre del empleado (ej. "Carlos").
        String nombre,

        // Apellidos del empleado (ej. "García López").
        String apellidos,

        // Ruta relativa de la foto (ej. "/uploads/empleados/abc.jpg"). Siempre presente
        // porque la foto es obligatoria al crear un empleado (regla 11 del CLAUDE.md).
        String fotoUrl
) {
}

// ============================================================================
// EmpleadoPublicoResponse
// ----------------------------------------------------------------------------
// Vista del catálogo de empleados pensada para clientes finales. Se diferencia
// de EmpleadoAdminResponse en que:
//   - NO expone correo, teléfono (datos personales).
//   - NO expone configuración de silencio ni modo "no molestar" (privado).
//   - NO expone si es administrador (irrelevante para el cliente).
//
// El endpoint que lo devuelve (GET /empleados) ya filtra los empleados dados
// de baja lógica (fecha_eliminacion_usuario != null), así que el cliente solo
// ve los empleados activos disponibles para reservar.
// ============================================================================
