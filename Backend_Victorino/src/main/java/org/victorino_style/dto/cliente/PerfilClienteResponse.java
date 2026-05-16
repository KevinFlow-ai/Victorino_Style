package org.victorino_style.dto.cliente;

// DTO de salida con los datos del perfil del cliente autenticado.
// Devuelto por GET /cliente/perfil y por PUT /cliente/perfil tras una edición.
// No expone la contraseña (siempre se queda en BD como hash BCrypt).
public record PerfilClienteResponse(

        // Identificador del cliente (mismo que id_usuario por herencia JOINED).
        Long idCliente,

        // Nombre.
        String nombre,

        // Apellidos.
        String apellidos,

        // Correo electrónico (lo identifica de forma única en BD).
        String correo,

        // Teléfono (opcional, puede ser null).
        String telefono,

        // Ruta relativa de la foto. Null si el cliente nunca subió foto.
        String fotoUrl,

        // Preferencia de notificaciones push. Si false, solo recibe in-app, no push FCM.
        boolean pushActiva
) {
}

// ============================================================================
// PerfilClienteResponse
// ----------------------------------------------------------------------------
// Vista del perfil del cliente autenticado para la pestaña "Perfil" de la app.
//
// SE DEVUELVE EN:
//   - GET /cliente/perfil
//   - PUT /cliente/perfil (tras una edición exitosa de datos personales)
//
// EL CAMPO pushActiva:
//   - Refleja cliente.push_activa_cliente en BD.
//   - El frontend lo usa en la sección "Configuración" del perfil para mostrar
//     el switch en posición ON/OFF.
//   - Cuando es false, NotificacionService NO envía push pero SÍ inserta fila
//     en la tabla notificacion (la bandeja in-app siempre funciona).
//
// EL CAMPO fotoUrl:
//   - Es null cuando el cliente nunca subió foto (es opcional en el registro).
//   - El frontend lo combina con ApiEndpoints.urlImagen(...) para construir la
//     URL absoluta. Si es null muestra un avatar por defecto con iniciales.
// ============================================================================
