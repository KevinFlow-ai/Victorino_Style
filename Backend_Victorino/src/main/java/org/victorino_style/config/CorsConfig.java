package org.victorino_style.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

import java.util.List;

// Configuración de CORS para desarrollo: permite cualquier origen localhost (Flutter web,
// Android emulador, iOS simulador) con credenciales.
// IMPORTANTE: en producción se debe restringir a los dominios reales.
@Configuration
public class CorsConfig {

    // Bean expuesto a SecurityConfig.cors(). Define qué orígenes/headers/métodos se aceptan.
    @Bean
    public UrlBasedCorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration config = new CorsConfiguration();
        // Patrones (no orígenes literales) para permitir cualquier puerto de localhost/127.0.0.1.
        config.setAllowedOriginPatterns(List.of(
                "http://localhost:*",
                "http://127.0.0.1:*",
                "http://10.0.2.2:*"
        ));
        config.setAllowedMethods(List.of("GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"));
        config.setAllowedHeaders(List.of("*"));
        // Necesario para que el navegador exponga el header Authorization en respuestas.
        config.setExposedHeaders(List.of("Authorization", "Content-Disposition"));
        config.setAllowCredentials(true);
        config.setMaxAge(3600L);

        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", config);
        return source;
    }
}

/*
    Este archivo CorsConfig define la configuración CORS (Cross-Origin Resource Sharing) de tu backend.
    CORS controla qué aplicaciones cliente pueden hacer peticiones HTTP a tu API.

    En tu caso, como tienes:

    Cliente Flutter Web
    Cliente Flutter Android
    Cliente Flutter iOS
    Backend Spring Boot
    Toodo en desarrollo local

    @ConfigurationIndica que esta clase contiene beans de configuración que Spring debe cargar al iniciar la aplicación
    Métoodo corsConfigurationSource() Este métoodo crea y expone un bean que Spring Security usará cuando llames a:http.cors()

    CorsConfiguration config = new CorsConfiguration();
    Crea un objeto donde defines:
    qué orígenes pueden acceder
    qué métodos HTTP se permiten
    qué cabeceras se aceptan
    si se permiten credenciales (cookies, tokens, etc.)

    config.setAllowedMethods(List.of("GET", "POST", "PUT", "DELETE", "OPTIONS"));
    Define qué métodos HTTP acepta tu API desde otros orígenes.

    config.setAllowedHeaders(List.of("*"));
    Permite todas las cabeceras, incluidas:
    Authorization
    Content-Type
    X-Requested-With

    config.setAllowCredentials(true)
    Permite enviar:cookies, tokens JWT en headers, sesiones. Esto es necesario si tu cliente Flutter envía tokens en cada petición.


 */