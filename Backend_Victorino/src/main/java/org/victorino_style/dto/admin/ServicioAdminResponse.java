package org.victorino_style.dto.admin;

import java.math.BigDecimal;

// DTO de salida que devuelve el panel del administrador al consultar el catálogo de servicios.
// Se usa tanto en listado como en detalle y tras alta/edición.
public record ServicioAdminResponse(

        // Identificador interno del servicio.
        Long idServicio,

        // Nombre comercial del servicio.
        String nombre,

        // Descripción visible al cliente.
        String descripcion,

        // Duración del servicio en minutos.
        Integer duracionMinutos,

        // Precio en euros.
        BigDecimal precio,

        // Ruta relativa de la foto (ej. "/uploads/servicios/abc.png"). Siempre presente.
        String fotoUrl,

        // Indica si el servicio está activo en el catálogo (false = baja lógica).
        boolean activo
) {
}

// ============================================================================
// ServicioAdminResponse
// ----------------------------------------------------------------------------
// Respuesta JSON para el panel admin cuando consulta o modifica servicios.
//
// ¿PARA QUÉ SIRVE?
// - Se devuelve en GET /admin/servicios, GET /admin/servicios/{id},
//   POST /admin/servicios y PUT /admin/servicios/{id}.
// - ServicioMapper transforma una entidad `Servicio` en este DTO.
//
// CAMPO `activo`:
// - true cuando `fecha_eliminacion_servicio IS NULL`.
// - El frontend filtra por este flag para mostrar solo servicios activos en
//   la pestaña "Catálogo" o todos (activos+inactivos) si el admin marca
//   "incluir inactivos".
//
// CAMPO `precio`:
// - BigDecimal serializado como número decimal en JSON (ej. 15.00).
// - Se renderiza con el sufijo "€" en la UI; el backend nunca incluye el
//   símbolo en este campo (se queda como dato puro).
// ============================================================================
