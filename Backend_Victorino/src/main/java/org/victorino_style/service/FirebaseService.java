package org.victorino_style.service;

import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.victorino_style.entity.enums.TipoNotificacion;


// Notificaciones import
import com.google.firebase.FirebaseApp;
import com.google.firebase.messaging.AndroidConfig;
import com.google.firebase.messaging.AndroidNotification;
import com.google.firebase.messaging.FirebaseMessaging;
import com.google.firebase.messaging.FirebaseMessagingException;
import com.google.firebase.messaging.Message;
import com.google.firebase.messaging.Notification;
import org.springframework.scheduling.annotation.Async;
import java.util.List;


// Servicio responsable de enviar notificaciones push a través de Firebase Cloud Messaging.
//
// Implementación REAL pendiente. Por ahora el métoddo deja una traza en el log y devuelve
// false para que NotificacionService marque la columna `enviada_push_notificacion = false`.
//
// TODOo FCM: integrar con FirebaseMessaging.getInstance().send(message) cuando se cargue
// el Service Account Key. La estructura de este servicio ya queda preparada para que el
// día que se conecte FCM no haya que tocar a sus consumidores.



// Usa FirebaseMessaging.getInstance().send(message) con el Service Account configurado
// en FirebaseConfig.
//
// Sistema hibrido (notification + data + HIGH):
//    - En background/cerrada: Firebase SDK nativo muestra la notificacion
//      INMEDIATAMENTE desde el payload "notification" sin pasar por WorkManager.
//    - En foreground: Flutter recibe el mensaje en onMessage y muestra
//      la notificacion local desde el payload "data".
//    - AndroidConfig.Priority.HIGH: FCM despierta el dispositivo de inmediato.


@Slf4j // generar automáticamente un logger llamado "log" dentro de la clase.
@Service // Marca la clase como un "servicio" dentro de la arquitectura de la aplicación.
public class FirebaseService {


    // ID del canal de Android que coincide con el creado en el frontend Flutter.
    private static final String CANAL_ANDROID = "canal_victorino_principal";


    // ------------------------------------------------------------------------
    // Envía un push a una lista de tokens FCM concretos.
    // Devuelve true si se envió a al menos un dispositivo, false si no.
    // ------------------------------------------------------------------------
    public boolean enviarPush(List<String> tokensFcm, String titulo, String cuerpo, TipoNotificacion tipo) {
        if (tokensFcm == null || tokensFcm.isEmpty()) {
            log.warn("[FCM] enviarPush() llamado con lista de tokens vacia");
            return false;
        }

        // Si Firebase no esta inicializado (credenciales no encontradas), loguea y sale.
        if (FirebaseApp.getApps().isEmpty()) {
            log.warn("[FCM] FirebaseApp no inicializado (credenciales no configuradas). Push omitido.");
            return false;
        }

        log.info("[FCM] Enviando push a {} dispositivo(s) | titulo='{}' | tipo={}", tokensFcm.size(), titulo, tipo);
        boolean alMenosUnoEnviado = false;

        String tituloSafe = titulo != null ? titulo : "";
        String cuerpoSafe = cuerpo != null ? cuerpo : "";

        for (String token : tokensFcm) {
            String tokenResumen = token.length() > 20 ? token.substring(0, 20) + "..." : token;
            try {
                // Mensaje HIBRIDO: notification payload + data payload + HIGH priority.
                Message message = Message.builder()
                        .setToken(token)
                        // Payload notification: Android lo muestra nativamente de fondo
                        .setNotification(Notification.builder()
                                .setTitle(tituloSafe)
                                .setBody(cuerpoSafe)
                                .build())
                        // Configuracion especifica de Android
                        .setAndroidConfig(AndroidConfig.builder()
                                .setPriority(AndroidConfig.Priority.HIGH)
                                .setNotification(AndroidNotification.builder()
                                        .setChannelId(CANAL_ANDROID)
                                        .setSound("default")
                                        .build())
                                .build())
                        // Payload data: accesible desde Flutter en cualquier estado
                        .putData("titulo", tituloSafe)
                        .putData("cuerpo",  cuerpoSafe)
                        .putData("tipo",    tipo.name())
                        .build();

                String messageId = FirebaseMessaging.getInstance().send(message);
                log.info("[FCM] Push enviado OK - token={} | messageId={}", tokenResumen, messageId);
                alMenosUnoEnviado = true;
            } catch (FirebaseMessagingException e) {
                log.error("[FCM] Error enviando push - token={} | errorCode={} | mensaje={}",
                        tokenResumen,
                        e.getMessagingErrorCode(),
                        e.getMessage());
            } catch (Exception e) {
                log.error("[FCM] Error inesperado enviando push - token={}", tokenResumen, e);
            }
        }
        return alMenosUnoEnviado;
    }

    // ------------------------------------------------------------------------
    // Version ASINCRONA de enviarPush().
    // Se ejecuta en un hilo del thread-pool de Spring (@Async) por lo que
    // el hilo HTTP del controlador se libera INMEDIATAMENTE sin esperar el
    // ACK de Firebase (~300-800 ms).
    //
    // USO: llamar desde NotificacionService.crearNotificacion() para que la
    // respuesta HTTP llegue a Flutter en ~50 ms en lugar de ~1 s.
    // ------------------------------------------------------------------------
    @Async
    public void enviarPushAsync(List<String> tokensFcm, String titulo, String cuerpo, TipoNotificacion tipo) {
        enviarPush(tokensFcm, titulo, cuerpo, tipo);
    }
}


// ============================================================================
// FirebaseService
// ----------------------------------------------------------------------------
// Capa de envío real de notificaciones push. La firma del métoddo público es
// estable: cuando se conecte Firebase de verdad, el resto del código no
// necesitará cambios.
//
// CONFIGURACIÓN PENDIENTE:
// - Añadir dependencia firebase-admin (ya está en el stack del CLAUDE.md).
// - Cargar el Service Account Key desde una ruta segura.
// - Reemplazar el log por la llamada a FirebaseMessaging.send(message).
// ============================================================================
