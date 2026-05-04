package org.victorino_style.security;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;

// Bean único de PasswordEncoder. Se separa de SecurityConfig para evitar dependencias
// circulares entre AuthenticationManager y la cadena de filtros (problema clásico).
@Configuration
public class PasswordEncoderConfig {

    // BCrypt con cost 10 (estándar recomendado por OWASP en 2026, balance velocidad/seguridad).
    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder(10);
    }
}


    // ============================================================================
    // PasswordEncoderConfig
    // ----------------------------------------------------------------------------
    // Esta clase define un **único bean de PasswordEncoder** para toda la aplicación.
    //
    // ¿POR QUÉ EXISTE ESTA CLASE?
    // - Spring Security necesita un PasswordEncoder para validar contraseñas
    //   durante el login y para encriptarlas durante el registro.
    // - Si el PasswordEncoder se declara dentro de SecurityConfig, es muy común
    //   provocar **dependencias circulares** entre:
    //        AuthenticationManager  ↔  SecurityFilterChain  ↔  PasswordEncoder
    // - Separarlo en su propia clase evita ese problema y mantiene la configuración
    //   limpia y modular.
    //
    // ¿QUÉ ALGORITMO SE USA?
    // - BCrypt con *cost* 10.
    // - Es el estándar recomendado por OWASP para 2026: seguro y razonablemente rápido.
    // - BCrypt incorpora *salt* aleatorio y es resistente a ataques de fuerza bruta.
    //
    // Este bean será inyectado automáticamente donde se necesite (AuthService,
    // AuthenticationManager, etc.).