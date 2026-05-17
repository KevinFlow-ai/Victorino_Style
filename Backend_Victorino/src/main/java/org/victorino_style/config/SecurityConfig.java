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

@Configuration
@EnableMethodSecurity
@RequiredArgsConstructor
public class SecurityConfig {

    private final JwtAuthenticationFilter jwtAuthenticationFilter;
    private final CorsConfigurationSource corsConfigurationSource;

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
                .cors(c -> c.configurationSource(corsConfigurationSource))
                .csrf(AbstractHttpConfigurer::disable)
                .sessionManagement(s -> s.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                .authorizeHttpRequests(auth -> auth
                        .requestMatchers(HttpMethod.POST, "/auth/**").permitAll()
                        .requestMatchers(
                                "/swagger-ui/**", "/swagger-ui.html",
                                "/v3/api-docs/**", "/v3/api-docs.yaml"
                        ).permitAll()
                        .requestMatchers(HttpMethod.GET, "/uploads/**").permitAll()
                        .requestMatchers("/error", "/actuator/health").permitAll()
                        
                        .requestMatchers(HttpMethod.POST, "/notificaciones/fcm-token").permitAll()
                        .requestMatchers("/test/**").permitAll()

                        // ACCESO A LA AGENDA Y RECURSOS PARA EMPLEADO Y ADMINISTRADOR
                        .requestMatchers(
                                "/admin/agenda/**",
                                "/admin/citas/**",
                                "/admin/clientes/**",
                                "/admin/empleados/**",
                                "/admin/empleados",
                                "/admin/servicios/**",
                                "/admin/servicios",
                                "/admin/horario/**",
                                "/admin/horario",
                                "/admin/festivos/**",
                                "/admin/festivos",
                                "/admin/cierre-anual/**",
                                "/admin/cierre-anual"
                        ).hasAnyRole("ADMINISTRADOR", "EMPLEADO")

                        // Panel administrador: solo ADMINISTRADOR
                        .requestMatchers("/admin/**").hasRole("ADMINISTRADOR")
                        
                        // Perfil y gestión propia del EMPLEADO
                        .requestMatchers("/empleado/**").hasRole("EMPLEADO")

                        // Perfil y gestión del CLIENTE
                        .requestMatchers("/cliente/**").hasRole("CLIENTE")

                        // Catálogo público
                        .requestMatchers(HttpMethod.GET, "/servicios", "/servicios/**").authenticated()
                        .requestMatchers(HttpMethod.GET, "/empleados", "/empleados/**").authenticated()
                        
                        .anyRequest().authenticated()
                )
                .addFilterBefore(jwtAuthenticationFilter, UsernamePasswordAuthenticationFilter.class);

        return http.build();
    }

    @Bean
    public DaoAuthenticationProvider daoAuthenticationProvider(UserDetailsService userDetailsService,
                                                               PasswordEncoder passwordEncoder) {
        DaoAuthenticationProvider provider = new DaoAuthenticationProvider(userDetailsService);
        provider.setPasswordEncoder(passwordEncoder);
        return provider;
    }

    @Bean
    public AuthenticationManager authenticationManager(DaoAuthenticationProvider provider) {
        return new org.springframework.security.authentication.ProviderManager(provider);
    }
}
