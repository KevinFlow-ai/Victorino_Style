package org.victorino_style.dto.auth;

// DTO de salida de /auth/refresh. Solo se rota el access; el refresh sigue siendo válido.
public record RefreshResponse(


        // accessToken: nuevo token JWT de corta duración generado a partir del refresh token.
        String accessToken
) {
}


// ============================================================================
// RefreshResponse
// ----------------------------------------------------------------------------
// Este DTO representa la respuesta que devuelve el backend cuando el cliente
// realiza una petición POST /auth/refresh.
//
// ¿PARA QUÉ SIRVE?
// - Cuando el cliente envía un refresh token válido, el backend genera un nuevo
//   access token (de corta duración) sin necesidad de volver a iniciar sesión.
// - Este DTO contiene únicamente ese nuevo access token.
//
// ¿POR QUÉ SOLO CONTIENE EL ACCESS TOKEN?
// - El refresh token NO se rota en este endpoint.
// - El refresh token original sigue siendo válido hasta su expiración o hasta
//   que el usuario haga logout.
// - Esto reduce carga en el servidor y evita generar refresh tokens innecesarios.
//
// Este DTO es extremadamente simple porque su única responsabilidad es transportar
// el nuevo access token generado por AuthService.
// ============================================================================