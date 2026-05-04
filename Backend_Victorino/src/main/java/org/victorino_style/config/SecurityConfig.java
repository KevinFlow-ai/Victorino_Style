package org.victorino_style.config;

import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.dao.DaoAuthenticationProvider;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.web.cors.CorsConfigurationSource;
import org.victorino_style.security.JwtAuthenticationFilter;

// Configuración principal de Spring Security:
// - Sesión stateless (no JSESSIONID, no cookies de sesión).
// - CSRF desactivado (es una API REST consumida con tokens).
// - Whitelist para auth, swagger y uploads.
// - Resto autenticado.
// - Filtro JWT antes del UsernamePasswordAuthenticationFilter.
@Configuration
@EnableMethodSecurity
@RequiredArgsConstructor
public class SecurityConfig {

    private final JwtAuthenticationFilter jwtAuthenticationFilter;
    private final CorsConfigurationSource corsConfigurationSource;

    // Cadena de filtros principal.
    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
                // CORS conectado al bean del CorsConfig.
                .cors(c -> c.configurationSource(corsConfigurationSource))
                // CSRF off: la API no usa cookies, los tokens van en cabecera.
                .csrf(AbstractHttpConfigurer::disable)
                // No se mantiene sesión en servidor.
                .sessionManagement(s -> s.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                .authorizeHttpRequests(auth -> auth
                        // Endpoints públicos: registro, login, refresh, logout y recuperación.
                        // (logout no requiere autenticación porque revoca el refresh con el body).
                        .requestMatchers(HttpMethod.POST, "/auth/**").permitAll()
                        // Documentación de la API.
                        .requestMatchers(
                                "/swagger-ui/**", "/swagger-ui.html",
                                "/v3/api-docs/**", "/v3/api-docs.yaml"
                        ).permitAll()
                        // Archivos subidos (fotos de empleados, servicios, clientes).
                        .requestMatchers(HttpMethod.GET, "/uploads/**").permitAll()
                        // Endpoints de error y health.
                        .requestMatchers("/error", "/actuator/health").permitAll()
                        // Cualquier otra petición exige token válido.
                        .anyRequest().authenticated()
                )
                // Inserta el filtro JWT antes del de autenticación clásica de Spring.
                .addFilterBefore(jwtAuthenticationFilter, UsernamePasswordAuthenticationFilter.class);

        return http.build();
    }

    // Provider que delega en CustomUserDetailsService + BCryptPasswordEncoder.
    @Bean
    public DaoAuthenticationProvider daoAuthenticationProvider(UserDetailsService userDetailsService,
                                                              PasswordEncoder passwordEncoder) {
        DaoAuthenticationProvider provider = new DaoAuthenticationProvider(userDetailsService);
        provider.setPasswordEncoder(passwordEncoder);
        return provider;
    }

    // AuthenticationManager expuesto para que AuthService pueda hacer auth.authenticate().
    @Bean
    public AuthenticationManager authenticationManager(DaoAuthenticationProvider provider) {
        return new org.springframework.security.authentication.ProviderManager(provider);
    }
}

/*
    Qué es esta clase en una frase
    Define toda la configuración de Spring Security para tu API REST:
    Sin sesiones, Sin cookies, Sin CSRF, con JWT, Con un filtro personalizado, Con endpoints públicos y privados
    Con CORS configurado


    Explicación completa por secciones
     1. Anotaciones de la clase


    @Configuration: Spring debe cargar esta clase como configuración.
    @EnableMethodSecurity: Activa anotaciones como: @PreAuthorize, @PostAuthorize, @Secured
    Esto te permite proteger métodos específicos en tus servicios o controladores.
    @RequiredArgsConstructor: Lombok genera un constructor con los final:


    private final JwtAuthenticationFilter jwtAuthenticationFilter;
    private final CorsConfigurationSource corsConfigurationSource;
    Spring los inyecta automáticamente.


     2. SecurityFilterChain — El corazón de la seguridad
    Este métodoo define toda la cadena de filtros que Spring Security aplicará a cada petición.

    2.1 CORS
    .cors(c -> c.configurationSource(corsConfigurationSource))
    Conecta Spring Security con tu bean CorsConfig.
    Permite que Flutter Web, Android, iOS… puedan llamar a tu API sin errores CORS.

    2.2 CSRF desactivado
    .csrf(AbstractHttpConfigurer::disable)
    CSRF solo tiene sentido cuando:
    hay sesiones, hay cookies, hay formularios HTML Tu API usa JWT en headers, así que CSRF
    no aplica.


    2.3 Sesión stateless
    .sessionManagement(s -> s.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
    Tu API no usa sesiones.

    Cada petición debe incluir un JWT válido.

    Spring no crea: JSESSIONID, cookies de sesión, estado del usuario

    2.4 Autorización de endpoints
    .authorizeHttpRequests(auth -> auth
        .requestMatchers(HttpMethod.POST, "/auth/**").permitAll()
    Endpoints públicos:
    ✔ /auth/** (POST)
    login
    register
    refresh
    logout
    recovery

    ✔ Swagger
    "/swagger-ui/**", "/swagger-ui.html",
    "/v3/api-docs/**", "/v3/api-docs.yaml"
    ✔ Archivos subidos
    .requestMatchers(HttpMethod.GET, "/uploads/**").permitAll()
    ✔ Health y errores
    java
    "/error", "/actuator/health"
    Todo0 lo demás requiere JWT
    .anyRequest().authenticated()


    2.5 Filtro JWT
    java
    .addFilterBefore(jwtAuthenticationFilter, UsernamePasswordAuthenticationFilter.class)
    Esto es clave.
    Tu filtro:
    lee el header Authorization: Bearer ...
    valida el token
    carga el usuario
    mete el usuario en el contexto de seguridad
    Y se ejecuta antes del filtro estándar de Spring.

    🧬 3. DaoAuthenticationProvider
    @Bean
    public DaoAuthenticationProvider daoAuthenticationProvider(...)
    Este provider:
    usa tu UserDetailsService para cargar usuarios desde la BD
    usa BCryptPasswordEncoder para validar contraseñas
    Es el que se usa en el login.

    🧩 4. AuthenticationManager
    @Bean
    public AuthenticationManager authenticationManager(DaoAuthenticationProvider provider)
    Expone un AuthenticationManager para que tu AuthService pueda hacer:

    authManager.authenticate(
        new UsernamePasswordAuthenticationToken(email, password)
    );
    Esto dispara: carga de usuario, validación de contraseña, generación de excepciones si falla

    Resumen final
    Tu SecurityConfig:

    ✔ Define una API REST 100% stateless
    ✔ Usa JWT para autenticación
    ✔ Permite endpoints públicos específicos
    ✔ Protege todoo lo demás
    ✔ Inserta un filtro JWT personalizado
    ✔ Desactiva CSRF
    ✔ Configura CORS
    ✔ Expone AuthenticationManager para login
    ✔ Usa BCrypt + UserDetailsService para validar credenciales

 */