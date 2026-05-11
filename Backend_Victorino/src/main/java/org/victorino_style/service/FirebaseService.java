package org.victorino_style.service;

import com.google.firebase.messaging.AndroidConfig;
import com.google.firebase.messaging.AndroidNotification;
import com.google.firebase.messaging.FirebaseMessaging;
import com.google.firebase.messaging.FirebaseMessagingException;
import com.google.firebase.messaging.Message;
import com.google.firebase.messaging.Notification;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;
import org.victorino_style.entity.enums.TipoNotificacion;

import java.util.List;

// Servicio responsable de enviar notificaciones push a través de Firebase Cloud Messaging.
// Usa FirebaseMessaging.getInstance().send(message) con el Service Account configurado
// en FirebaseConfig. Devuelve true si al menos un push se envió correctamente.
//
// Hemos puesto el siguiente sistema hibido para garantizar que la notificación se muestre INMEDIATAMENTE en Android cuando la app está en background o cerrada, sin pasar por WorkManager ni por Dart (cero retraso), y al mismo tiempo permitir que Flutter reciba el mensaje en onMessage para mostrar la notificación local solo cuando la app está en foreground (evita duplicado en background). El payload de cada mensaje incluye tanto el bloque "notification" (que Firebase SDK muestra automáticamente en background) como el bloque "data" (que Flutter puede usar para mostrar la notificación local en foreground).
//
// Sistema híbrido (notification + data + HIGH):
//    - En background/cerrada: Firebase SDK nativo muestra la notificación
//      INMEDIATAMENTE desde el payload "notification" sin pasar por WorkManager.
//    - En foreground: Flutter recibe el mensaje en onMessage y muestra
//      la notificación local desde el payload "data" (el sistema no muestra
//      automáticamente el payload notification cuando la app está en primer plano).
//    - El campo "data" lleva titulo/cuerpo/tipo para que el handler de Flutter
//      pueda acceder a ellos en cualquier estado de la app.
@Slf4j
@Service
public class FirebaseService {

    // ID del canal de Android que coincide con el creado en el frontend Flutter.
    private static final String CANAL_ANDROID = "canal_victorino_principal";

    // ------------------------------------------------------------------------
    // Envía un push a una lista de tokens FCM concretos.
    // Devuelve true si se envió a al menos un dispositivo, false si no.
    // ------------------------------------------------------------------------
    public boolean enviarPush(List<String> tokensFcm, String titulo, String cuerpo, TipoNotificacion tipo) {
        if (tokensFcm == null || tokensFcm.isEmpty()) {
            log.warn("[FCM] enviarPush() llamado con lista de tokens vacía");
            return false;
        }
        log.info("[FCM] Enviando push a {} dispositivo(s) | título='{}' | tipo={}", tokensFcm.size(), titulo, tipo);
        boolean alMenosUnoEnviado = false;

        String tituloSafe = titulo != null ? titulo : "";
        String cuerpoSafe = cuerpo != null ? cuerpo : "";

        for (String token : tokensFcm) {
            String tokenResumen = token.length() > 20 ? token.substring(0, 20) + "..." : token;
            try {
                // Mensaje HÍBRIDO: notification payload + data payload + HIGH priority.
                //
                // notification payload → Firebase SDK lo muestra en el intento de Android
                //   de forma inmediata cuando la app está en background o cerrada,
                //   sin pasar por WorkManager ni por Dart (cero retraso).
                //
                // data payload → Firebase SDK lo entrega al handler de Flutter
                //   (onMessage en foreground, firebaseMessagingBackgroundHandler si se llega
                //   a ejecutar). El handler lo usa para mostrar la notificación local
                //   solo cuando la app está en foreground (evita duplicado en background).
                //
                // AndroidConfig.Priority.HIGH → FCM despierta el dispositivo de inmediato
                //   para entregar el mensaje (evita batching por Doze/Standby Buckets).
                //
                // channelId → la notificación se encola en el canal correcto del frontend.
                Message message = Message.builder()
                        .setToken(token)
                        // Payload notification: Android lo muestra nativammente de fondo
                        .setNotification(Notification.builder()
                                .setTitle(tituloSafe)
                                .setBody(cuerpoSafe)
                                .build())
                        // Configuración específica de Android
                        .setAndroidConfig(AndroidConfig.builder()
                                .setPriority(AndroidConfig.Priority.HIGH)
                                .setNotification(AndroidNotification.builder()
                                        .setChannelId(CANAL_ANDROID)   // canal creado en Flutter
                                        .setSound("default")
                                        .build())
                                .build())
                        // Payload data: accesible desde Flutter en cualquier estado
                        .putData("titulo", tituloSafe)
                        .putData("cuerpo",  cuerpoSafe)
                        .putData("tipo",    tipo.name())
                        .build();

                String messageId = FirebaseMessaging.getInstance().send(message);
                log.info("[FCM]  Push enviado OK → token={} | messageId={}", tokenResumen, messageId);
                alMenosUnoEnviado = true;
            } catch (FirebaseMessagingException e) {
                log.error("[FCM]  Error enviando push → token={} | errorCode={} | mensaje={}",
                        tokenResumen,
                        e.getMessagingErrorCode(),
                        e.getMessage());
            } catch (Exception e) {
                log.error("[FCM]  Error inesperado enviando push → token={}", tokenResumen, e);
            }
        }
        return alMenosUnoEnviado;
    }

    // ------------------------------------------------------------------------
    // Versión ASÍNCRONA de enviarPush().
    // Se ejecuta en un hilo del thread-pool de Spring (@Async) por lo que
    // el hilo HTTP del controlador se libera INMEDIATAMENTE sin esperar el
    // ACK de Firebase (~300-800 ms). El push llega al dispositivo igual de
    // rápido que antes; solo cambia cuándo el backend responde al frontend.
    //
    // USO: llamar desde NotificacionService.crearNotificacion() para que la
    // respuesta HTTP llegue a Flutter en ~50 ms en lugar de ~1 s.
    // El resultado booleano se descarta (se usa el flag optimista en la BD).
    // ------------------------------------------------------------------------
    @Async
    public void enviarPushAsync(List<String> tokensFcm, String titulo, String cuerpo, TipoNotificacion tipo) {
        enviarPush(tokensFcm, titulo, cuerpo, tipo);
    }

}

// ============================================================================
// FirebaseService
// ----------------------------------------------------------------------------
// Capa de envío real de notificaciones push. La firma del método público es
// estable: todos los consumidores solo llaman a enviarPush().
//
// CONFIGURACIÓN:
// - La dependencia firebase-admin está en pom.xml.
// - El Service Account Key se carga desde firebase-service-account.json (resources).
// - FirebaseConfig inicializa FirebaseApp al arrancar la aplicación.
// ============================================================================
