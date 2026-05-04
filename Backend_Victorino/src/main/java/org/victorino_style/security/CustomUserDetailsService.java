package org.victorino_style.security;

import lombok.RequiredArgsConstructor;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.User;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service; // Spring: marca esta clase como servicio inyectable.
import org.springframework.transaction.annotation.Transactional; // Garantiza transacciones de solo lectura para consultas.
import org.victorino_style.entity.Usuario; // Entidad Usuario.
import org.victorino_style.repository.UsuarioRepository; // Repositorio para buscar usuarios en la BD.

// Implementación de UserDetailsService que carga usuarios desde MySQL.
// Se usa para el AuthenticationManager que valida correo/pwd en el login,
// y también desde JwtAuthenticationFilter para reconstruir el contexto.
@Service
@RequiredArgsConstructor
public class CustomUserDetailsService implements UserDetailsService {

    private final UsuarioRepository usuarioRepository; // Repositorio para acceder a la tabla usuario.



    // ------------------------------------------------------------------------
    // Métodoo principal de UserDetailsService.
    // Spring Security lo llama automáticamente cuando necesita cargar un usuario.
    //
    // En este sistema, el "username" ES el correo electrónico.
    // ------------------------------------------------------------------------
    @Override
    @Transactional(readOnly = true)
    public UserDetails loadUserByUsername(String correo) throws UsernameNotFoundException {


        // Busca un usuario activo (no soft-deleted) por su correo.
        // Si no existe, lanza UsernameNotFoundException → Spring devuelve 401.
        Usuario usuario = usuarioRepository
                .findByCorreoUsuarioAndFechaEliminacionUsuarioIsNull(correo)
                .orElseThrow(() -> new UsernameNotFoundException("Usuario no encontrado: " + correo));

        // El authority lleva prefijo ROLE_ para que Spring Security lo trate como rol.
        // Ej: ROLE_CLIENTE, ROLE_EMPLEADO, ROLE_ADMINISTRADOR.
        String authority = "ROLE_" + usuario.getRolUsuario().name();



        // Construye el UserDetails que Spring Security usará internamente.
        return User.builder()
                .username(usuario.getCorreoUsuario())
                .password(usuario.getContrasenaUsuario())
                .authorities(new SimpleGrantedAuthority(authority))
                // El soft-delete ya filtra arriba; los flags se quedan en true por defecto.
                .accountLocked(false)
                .disabled(false)
                .build();
    }
}



    // ============================================================================
    // CustomUserDetailsService
    // ----------------------------------------------------------------------------
    // Esta clase implementa UserDetailsService, un componente clave de Spring Security.
    // Su función es **cargar un usuario desde la base de datos** cuando Spring necesita
    // autenticarlo o reconstruir su contexto de seguridad.
    //
    // ¿CUÁNDO SE USA ESTE SERVICIO?
    // 1. Durante el login:
    //      - El AuthenticationManager llama a loadUserByUsername(correo)
    //        para obtener el usuario y validar la contraseña.
    // 2. Durante la validación del JWT:
    //      - JwtAuthenticationFilter extrae el correo del token
    //        y vuelve a llamar a este servicio para reconstruir el UserDetails.
    //
    // ¿QUÉ DEVUELVE?
    // - Un objeto UserDetails (implementación de Spring Security) que contiene:
    //      * username → correo del usuario
    //      * password → contraseña encriptada (BCrypt)
    //      * authorities → roles con prefijo "ROLE_"
    //      * flags de cuenta (locked, disabled…)
    //
    // NOTAS IMPORTANTES:
    // - Solo se cargan usuarios activos (soft delete filtrado por fechaEliminacionUsuario).
    // - El rol se convierte a SimpleGrantedAuthority con prefijo ROLE_.
    // - @Transactional(readOnly = true) asegura eficiencia y evita problemas de lazy loading.
    // ============================================================================