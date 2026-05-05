package org.victorino_style.dto.admin;

import java.util.List;

// DTO de salida con el historial completo de citas de un cliente registrado,
// pensado para el panel del administrador.
public record HistorialClienteResponse(

        // Datos básicos del cliente para mostrar en la cabecera de la pantalla.
        Long idCliente,
        String nombreCompleto,
        String correo,
        String telefono,
        String fotoUrl,

        // Indica si el cliente todavía existe (false = cuenta eliminada con anonimización RGPD).
        boolean cuentaActiva,

        // Total de citas en el historial (todas, en cualquier estado).
        int totalCitas,

        // Lista completa de citas del cliente, ordenadas de la más reciente a la más antigua.
        List<CitaAdminResponse> citas
) {
}

// ============================================================================
// HistorialClienteResponse
// ----------------------------------------------------------------------------
// Detalle completo del historial de un cliente, accesible desde el panel
// del administrador.
//
// ¿PARA QUÉ SIRVE?
// - Endpoint GET /admin/clientes/{id}/historial.
// - Ofrece al admin una vista 360° de un cliente: datos personales,
//   total de citas y la lista cronológica de cada una.
//
// CAMPO `cuentaActiva`:
// - true cuando el cliente está dado de alta (no eliminado).
// - false cuando el cliente ejerció su derecho RGPD de baja: las citas
//   pasadas se mantienen anonimizadas con el id_cliente, pero el nombre
//   y los datos personales aparecerán como "Cliente eliminado".
//
// PRIVACIDAD:
// - Esta respuesta solo es visible para el rol ADMINISTRADOR. El empleado
//   tiene un endpoint distinto que solo le devuelve las citas atendidas
//   por él mismo (regla del CLAUDE.md).
// ============================================================================
