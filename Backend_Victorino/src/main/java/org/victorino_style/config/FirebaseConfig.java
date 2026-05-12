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
import java.io.InputStream;

// Inicializa Firebase Admin SDK al arrancar la app.
// Si las credenciales no existen o fallan, loggea pero no rompe la app:
// NotificacionService seguirá funcionando para in-app aunque el push falle.
@Slf4j
@Configuration
public class FirebaseConfig {

    @Value("${victorino.firebase.credentials-path}")
    private String credentialsPath;

    private final ResourceLoader resourceLoader;

    public FirebaseConfig(ResourceLoader resourceLoader) {
        this.resourceLoader = resourceLoader;
    }

    @PostConstruct
    public void inicializar() {
        try {
            Resource res = resourceLoader.getResource(credentialsPath);
            if (!res.exists()) {
                log.warn("[FCM] Credenciales no encontradas en {} — push deshabilitado", credentialsPath);
                return;
            }
            try (InputStream in = res.getInputStream()) {
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

    @Bean
    public FirebaseMessaging firebaseMessaging() {
        return FirebaseApp.getApps().isEmpty()
                ? null
                : FirebaseMessaging.getInstance();
    }
}
