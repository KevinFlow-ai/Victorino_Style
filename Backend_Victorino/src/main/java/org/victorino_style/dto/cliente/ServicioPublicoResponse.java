package org.victorino_style.dto.cliente;

import java.math.BigDecimal;

// DTO ligero del catálogo de servicios para el cliente final.
// Devuelve solo los campos que el cliente debe ver al reservar: id, nombre, descripción,
// duración, precio y foto. NO incluye fechas de auditoría ni flag "activo" (porque el
// endpoint ya filtra los inactivos en el servidor).
//
// Usado por: GET /servicios (autenticado, cualquier rol). El admin sigue teniendo
// ServicioAdminResponse con más campos para su panel.
public record ServicioPublicoResponse(

        // Identificador del servicio.
        Long idServicio,

        // Nombre comercial (ej. "Corte de pelo masculino").
        String nombre,

        // Descripción visible al cliente. Puede ser null si el admin no la rellenó.
        String descripcion,

        // Duración del servicio en minutos. La usa el wizard para calcular hora_fin.
        Integer duracionMinutos,

        // Precio en euros. BigDecimal para evitar errores de coma flotante.
        BigDecimal precio,

        // Ruta relativa de la foto (ej. "/uploads/servicios/abc.jpg").
        // El frontend la combina con ApiEndpoints.urlImagen(...) para obtener URL absoluta.
        String fotoUrl
) {
}

// ============================================================================
// ServicioPublicoResponse
// ----------------------------------------------------------------------------
// Vista del catálogo de servicios pensada para clientes finales que reservan
// citas. Se diferencia de ServicioAdminResponse en que:
//   - NO expone fechas de creación/modificación (irrelevantes para el cliente).
//   - NO expone el flag activo (el endpoint solo devuelve activos).
//
// Se reusa también en el Home (sección "Servicios destacados") y en el Paso 1
// del wizard de reserva (lista de selección).
// ============================================================================
