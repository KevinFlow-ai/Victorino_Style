package org.victorino_style.config;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import com.google.firebase.messaging.FirebaseMessaging;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.io.Resource;
import org.springframework.core.io.ResourceLoader;

import jakarta.annotation.PostConstruct;
import java.io.ByteArrayInputStream;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;

// Inicializa Firebase Admin SDK al arrancar la app.
// Soporta dos modos para leer las credenciales (en este orden de prioridad):
//   1) victorino.firebase.credentials-json: contenido COMPLETO del service
//      account JSON inline. Pensado para entornos cloud (Railway, Heroku, etc.)
//      donde no se pueden montar ficheros y solo hay variables de entorno.
//   2) victorino.firebase.credentials-path: ruta tipo Spring Resource
//      ("classpath:..." o "file:...") al archivo JSON. Pensado para local.
//
// Si ambas estan vacias o falla la lectura, se loguea un aviso pero la app NO
// rompe — NotificacionService seguira funcionando para notificaciones in-app
// aunque el push FCM quede deshabilitado.
@Slf4j
@Configuration
public class FirebaseConfig {

    @Value("${victorino.firebase.credentials-json:}")
    private String credentialsJson;

    @Value("${victorino.firebase.credentials-path:}")
    private String credentialsPath;

    private final ResourceLoader resourceLoader;

    public FirebaseConfig(ResourceLoader resourceLoader) {
        this.resourceLoader = resourceLoader;
    }

    @PostConstruct
    public void inicializar() {
        try {
            InputStream credenciales = abrirCredenciales();
            if (credenciales == null) {
                log.warn("[FCM] Credenciales no disponibles (ni JSON inline ni archivo). Push deshabilitado.");
                return;
            }
            try (InputStream in = credenciales) {
                FirebaseOptions options = FirebaseOptions.builder()
                        .setCredentials(GoogleCredentials.fromStream(in))
                        .build();
                if (FirebaseApp.getApps().isEmpty()) {
                    FirebaseApp.initializeApp(options);
                    log.info("[FCM] FirebaseApp inicializado correctamente.");
                }
            }
        } catch (Exception ex) {
            log.error("[FCM] Error al inicializar Firebase. Push deshabilitado.", ex);
        }
    }

    /**
     * Devuelve un InputStream con el JSON del service account.
     * Prioriza la variable inline (cloud) sobre el archivo (local).
     * Devuelve null si no hay nada legible.
     */
    private InputStream abrirCredenciales() {
        // 1) Variable de entorno con el JSON inline (preferida en Railway).
        if (credentialsJson != null && !credentialsJson.isBlank()) {
            log.info("[FCM] Cargando credenciales desde variable inline (JSON).");
            return new ByteArrayInputStream(credentialsJson.getBytes(StandardCharsets.UTF_8));
        }
        // 2) Archivo apuntado por classpath: o file:.
        if (credentialsPath != null && !credentialsPath.isBlank()) {
            Resource res = resourceLoader.getResource(credentialsPath);
            if (res.exists()) {
                try {
                    log.info("[FCM] Cargando credenciales desde {}", credentialsPath);
                    return res.getInputStream();
                } catch (Exception ex) {
                    log.error("[FCM] No se pudo abrir {}", credentialsPath, ex);
                }
            } else {
                log.warn("[FCM] Recurso no encontrado: {}", credentialsPath);
            }
        }
        return null;
    }

    @Bean
    public FirebaseMessaging firebaseMessaging() {
        return FirebaseApp.getApps().isEmpty()
                ? null
                : FirebaseMessaging.getInstance();
    }
}
