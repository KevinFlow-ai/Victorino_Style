package org.victorino_style.dto.admin;

// DTO de respuesta para avisos de clientes con cancelaciones frecuentes.
// Este record se utiliza para enviar al frontend información resumida
// sobre clientes que han cancelado varias citas recientemente.
//
// Un "record" en Java es una clase inmutable diseñada para transportar datos.
// Se usa mucho en APIs porque:
// - Es más limpio y conciso que una clase tradicional
// - Genera automáticamente constructor, getters, equals, hashCode y toString
// - Garantiza inmutabilidad (los campos no pueden cambiar)
//
// Este DTO contiene:
// - idCliente: identificador único del cliente
// - nombreCompleto: nombre y apellidos del cliente
// - correo: email del cliente
// - cancelacionesUltimos30Dias: número de cancelaciones recientes

public record AvisoClienteResponse(

        // Identificador del cliente.
        Long idCliente,

        // Nombre completo del cliente.
        String nombreCompleto,

        // Correo electrónico del cliente.
        String correo,

        // Número de cancelaciones registradas en los últimos 30 días.
        long cancelacionesUltimos30Dias

) {
    // Los records no necesitan cuerpo adicional a menos que quieras métodos extra.
}


// ============================================================================
// AvisoClienteResponse
// ----------------------------------------------------------------------------
// Aviso INFORMATIVO (sin acción automática) sobre clientes con varias
// cancelaciones en los últimos 30 días.
//
// ¿PARA QUÉ SIRVE?
// - Endpoint GET /admin/avisos/cancelaciones-frecuentes.
// - El admin lo usa para detectar patrones, hablar con el cliente o
//   reorganizar la agenda. NO bloquea ni penaliza al cliente.
//
// CÓMO SE CALCULA:
// - Una @Query JPQL en CitaRepository agrupa las citas con estado
//   CANCELADA_CLIENTE de los últimos 30 días por id_cliente y filtra
//   con HAVING > umbral. El umbral por defecto es 3 (configurable vía
//   `victorino.avisos.umbral-cancelaciones` en application.properties).
//
// CAMPO `cancelacionesUltimos30Dias`:
// - long porque viene directamente de un COUNT(*) JPQL.
// ============================================================================
