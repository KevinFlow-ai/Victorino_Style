package org.victorino_style.config;

import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Configuration;

import java.time.Duration;

// Bean de configuración tipada que mapea las propiedades "victorino.jwt.*" del
// application.properties. Permite inyectar la config en JwtService sin
// hardcodear claves ni leer @Value en cada sitio.

@Getter
@Setter
@Configuration
@ConfigurationProperties(prefix = "victorino.jwt")
public class JwtConfig {

    // Clave secreta en base64 para firmar los JWT con HS256.
    private String secret;

    // Duración del access token (ej. PT15M = 15 min).
    private Duration accessTtl;

    // Duración del refresh token (ej. P7D = 7 días).
    private Duration refreshTtl;

    // Emisor que se incluye en el claim "iss" del JWT.
    private String issuer;
}



/*
    Idea principal
    Esta clase define un bean de configuración tipada que Spring rellena automáticamente con
    los valores que tengas en tu application.properties o application.yml bajo el prefijo: victorino.jwt.*
    Es decir:
    Spring convierte propiedades externas en un objeto Java listo para usar, sin hardcodear valores
    sensibles en el código.

    Qué hace cada anotación
    @Configuration Le dice a Spring: “Esta clase contiene beans de configuración que deben
    cargarse al iniciar la aplicación”.

    @ConfigurationProperties(prefix = "victorino.jwt") Esta es la clave de todoo.
    Indica que Spring debe buscar en tu application.properties todas las propiedades
    que empiecen por:
    victorino.jwt.secret
    victorino.jwt.access-ttl
    victorino.jwt.refresh-ttl
    victorino.jwt.issuer

    Ejemplo típico en application.properties:
    victorino.jwt.secret=MI_CLAVE_BASE64
    victorino.jwt.access-ttl=PT15M
    victorino.jwt.refresh-ttl=P7D
    victorino.jwt.issuer=victorino-style

    Qué representa cada campo
    private String secret; La clave secreta en Base64 para firmar los JWT con HS256.
    Tu JwtService la usará para: firmar tokens, validar tokens, verificar integridad

    private Duration accessTtl;
    Tiempo de vida del access token. Ejemplos válidos:
    PT15M → 15 minutos
    PT1H → 1 hora
    Spring convierte automáticamente el texto en un objeto Duration

    private Duration refreshTtl; Tiempo de vida del refresh token.
    Ejemplos:
    P7D → 7 días
    P30D → 30 días

    private String issuer; El valor que se incluirá en el claim "iss" del JWT.
    Sirve para: identificar quién emitió el token, validar tokens que vienen de tu backend y
    no de otro sitio

    ¿Por qué es útil esta clase? Porque te permite:
    ✔ Centralizar la configuración JWT: Todoo está en un solo sitio, no disperso por el código.
    ✔ Evitar hardcodear valores sensibles La clave secreta no aparece en el código fuente.
    ✔ Inyectar la configuración fácilmente

    Resumen en una frase
    JwtConfig es un bean de configuración que mapea automáticamente las propiedades JWT
    del application.properties a un objeto Java, permitiendo que tu JwtService use
    esos valores sin hardcodearlos.




 */