package org.victorino_style.dto.auth;

import org.victorino_style.entity.enums.RolUsuario;

// ============================================================================
// AuthResponse
// ----------------------------------------------------------------------------
// Este record representa la respuesta que devuelve el backend después de un
// proceso de autenticación exitoso (registro o login).
//
// ¿PARA QUÉ SIRVE ESTE DTO?
// - Se envía al cliente (Flutter) cuando un usuario inicia sesión o se registra.
// - Contiene los tokens necesarios para mantener la sesión:
//      * accessToken  → token corto para acceder a la API.
//      * refreshToken → token largo para renovar el accessToken.
// - Incluye información básica del usuario autenticado:
//      * rol del usuario (CLIENTE, EMPLEADO, ADMIN).
//      * id del usuario (para identificarlo en la app).
//      * nombre completo (para mostrarlo en la UI).
//      * foto (URL de la imagen de perfil).
//
// ¿POR QUÉ ES UN RECORD?
// - Los records en Java son inmutables, ideales para DTOs.
// - Reducen código repetitivo (getters, constructor, equals, hashCode…).
// - Son perfectos para respuestas REST donde solo se transportan datos.
//
// Este record se serializa automáticamente a JSON cuando se devuelve en un
// ResponseEntity desde AuthController.
// ============================================================================

public record AuthResponse(

        // accessToken: token JWT de corta duración (ej. 15 minutos).
        // Se envía en cada petición protegida dentro del header Authorization.
        String accessToken,

        // refreshToken: token JWT de larga duración (ej. 7 días).
        // Sirvee para obtener un nuevo accessToken sin volver a iniciar sesión.
        String refreshToken,

        // rol: indica el tipo de usuario autenticado (CLIENTE, EMPLEADO, ADMIN).
        // Permite que el frontend adapte la interfaz según permisos.
        RolUsuario rol,

        // idUsuario: identificador único del usuario en la base de datos.
        // Útil para cargar datos del perfil, citas, historial, etc.
        Long idUsuario,

        // nombreCompleto: nombre del usuario para mostrarlo en la UI.
        String nombreCompleto,

        // foto: URL de la imagen de perfil del usuario.
        // Puede ser null si el usuario no tiene foto.
        String foto

) {
}
