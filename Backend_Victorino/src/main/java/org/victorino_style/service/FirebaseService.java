package org.victorino_style.service;

import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.victorino_style.entity.enums.TipoNotificacion;

// Servicio responsable de enviar notificaciones push a través de Firebase Cloud Messaging.
//
// Implementación REAL pendiente. Por ahora el métoddo deja una traza en el log y devuelve
// false para que NotificacionService marque la columna `enviada_push_notificacion = false`.
//
// TODOo FCM: integrar con FirebaseMessaging.getInstance().send(message) cuando se cargue
// el Service Account Key. La estructura de este servicio ya queda preparada para que el
// día que se conecte FCM no haya que tocar a sus consumidores.
@Slf4j // generar automáticamente un logger llamado "log" dentro de la clase.
@Service // Marca la clase como un "servicio" dentro de la arquitectura de la aplicación.
public class FirebaseService {

    // ------------------------------------------------------------------------
    // Envía un push a una lista de tokens FCM concretos.
    // Devuelve true si se envió a al menos un dispositivo, false si no.
    // ------------------------------------------------------------------------
    public boolean enviarPush(java.util.List<String> tokensFcm,
                              String titulo,
                              String cuerpo,
                              TipoNotificacion tipo) {
        if (tokensFcm == null || tokensFcm.isEmpty()) {
            log.debug("Sin tokens FCM para enviar push: tipo={}", tipo);
            return false;
        }
        // TODOo FCM: aquí iría la llamada real a Firebase Admin SDK.
        log.info("[FCM TODO] Push '{}' '{}' (tipo={}) a {} dispositivo(s)",
                titulo, cuerpo, tipo, tokensFcm.size());
        return false;
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
