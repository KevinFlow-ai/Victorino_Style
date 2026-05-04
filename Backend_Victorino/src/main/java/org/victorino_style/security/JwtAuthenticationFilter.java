package org.victorino_style.security;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.JwtException;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.lang.NonNull;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.web.authentication.WebAuthenticationDetailsSource;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.List;

// Filtro que se ejecuta una vez por petición. Lee el header Authorization,
// valida el JWT y si es correcto deja un Authentication en el SecurityContext
// para que Spring Security autorice el endpoint.
@Slf4j
@Component
@RequiredArgsConstructor
public class JwtAuthenticationFilter extends OncePerRequestFilter {

    // Servicio encargado de validar firma, expiración y extraer claims del JWT.
    private final JwtService jwtService;

    // Nombre del header estándar donde viene el token.
    private static final String CABECERA = "Authorization";

    // Prefijo estándar del esquema Bearer.
    private static final String PREFIJO = "Bearer ";

    @Override
    protected void doFilterInternal(@NonNull HttpServletRequest request,
                                    @NonNull HttpServletResponse response,
                                    @NonNull FilterChain filterChain)
            throws ServletException, IOException {

        // Si no hay header o no empieza por "Bearer ", se continúa sin autenticar.
        // SecurityConfig decidirá si la ruta requiere auth (401) o es pública.
        String header = request.getHeader(CABECERA);
        if (header == null || !header.startsWith(PREFIJO)) {
            filterChain.doFilter(request, response);
            return;
        }

        String token = header.substring(PREFIJO.length()).trim(); // Extraemos el token quitando el prefijo "Bearer ".

        try {
            // Si el token es inválido o caducado, validarAccessToken lanza JwtException.
            Claims claims = jwtService.validarAccessToken(token);

            String idUsuario = claims.getSubject();
            String rol = claims.get("rol", String.class); // claim personalizado "rol" → CLIENTE, EMPLEADO, ADMINISTRADOR




            // ----------------------------------------------------------------
            // 3. Establecer Authentication en el SecurityContext
            // ----------------------------------------------------------------
            // Solo si aún no hay autenticación previa (defensa contra duplicados).
            if (rol != null && SecurityContextHolder.getContext().getAuthentication() == null) {
                List<SimpleGrantedAuthority> authorities =
                        List.of(new SimpleGrantedAuthority("ROLE_" + rol));



                // Creamos la autenticación:
                // - Principal = idUsuario (String)
                // - Credentials = null (ya validamos el token)
                // - Authorities = rol del usuario
                UsernamePasswordAuthenticationToken auth =
                        new UsernamePasswordAuthenticationToken(idUsuario, null, authorities);
                auth.setDetails(new WebAuthenticationDetailsSource().buildDetails(request));

                SecurityContextHolder.getContext().setAuthentication(auth);
            }
        } catch (JwtException ex) {
            // Token inválido: NO se establece auth y se deja el SecurityContext vacío.
            // El EntryPoint o el handler de 401 se encargará de devolver el error.
            log.debug("JWT inválido recibido: {}", ex.getMessage());
            SecurityContextHolder.clearContext();
        }

        // Sea cual sea el resultado, la petición continúa por la cadena de filtros.
        filterChain.doFilter(request, response);
    }
}


    // ============================================================================
    // JwtAuthenticationFilter
    // ----------------------------------------------------------------------------
    // Este filtro se ejecuta **una vez por petición** (OncePerRequestFilter).
    // Su misión es:
    //
    // 1. Leer el header Authorization.
    // 2. Extraer el token JWT (access token).
    // 3. Validarlo con JwtService (firma, expiración, integridad).
    // 4. Si es válido, crear una Authentication y guardarla en el SecurityContext.
    // 5. Dejar que la petición continúe por la cadena de filtros.
    //
    // Si el token es inválido, simplemente NO autentica al usuario y deja que
    // Spring Security gestione el 401 mediante su EntryPoint.
    // ============================================================================
