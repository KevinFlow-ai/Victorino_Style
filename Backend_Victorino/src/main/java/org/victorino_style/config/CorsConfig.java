package org.victorino_style.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

// Configuracion de CORS. En desarrollo permite los origenes habituales (localhost,
// emulador Android, ngrok, red WiFi local). En produccion se anaden los dominios
// reales mediante la propiedad victorino.cors.origenes-extra (lista separada por coma).
@Configuration
public class CorsConfig {

    // Origenes adicionales inyectados por configuracion. En Railway se pone aqui
    // la URL del frontend (ej. https://victorino-frontend.up.railway.app).
    @Value("${victorino.cors.origenes-extra:}")
    private String origenesExtra;

    // Bean expuesto a SecurityConfig.cors(). Define que origenes/headers/metodos se aceptan.
    @Bean
    public UrlBasedCorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration config = new CorsConfiguration();
        // Patrones de desarrollo: cualquier puerto de localhost/127.0.0.1, emulador
        // Android, tuneles ngrok/localhost.run y red local WiFi.
        List<String> origenes = new ArrayList<>(List.of(
                "http://localhost:*",
                "http://127.0.0.1:*",
                "http://10.0.2.2:*",
                "https://*.lhr.life",          // localhost.run tunnel
                "https://*.ngrok-free.app",    // ngrok tunnel (gratuito)
                "https://*.ngrok.io",          // ngrok tunnel (legacy)
                "http://192.168.*.*",          // red local WiFi
                "http://192.168.*.*:*"         // red local WiFi con puerto
        ));

        // Anade los origenes extra de produccion (separados por coma en la propiedad).
        if (origenesExtra != null && !origenesExtra.isBlank()) {
            Arrays.stream(origenesExtra.split(","))
                    .map(String::trim)
                    .filter(s -> !s.isEmpty())
                    .forEach(origenes::add);
        }

        config.setAllowedOriginPatterns(origenes);
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