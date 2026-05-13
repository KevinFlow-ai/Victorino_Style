package org.victorino_style.controller;

import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.victorino_style.entity.Usuario;
import org.victorino_style.entity.enums.TipoNotificacion;
import org.victorino_style.repository.UsuarioRepository;
import org.victorino_style.service.NotificacionService;

import java.util.LinkedHashMap;
import java.util.Map;

// ============================================================
// ARCHIVO TEMPORAL DE PRUEBAS - ELIMINAR ANTES DE PRODUCCION
// ============================================================
// Permite disparar cualquier tipo de notificacion a cualquier
// usuario sin pasar por los flujos normales del negocio.
// Util para verificar que push + in-app funcionan correctamente.
//
// Endpoint: POST /test/notificaciones/disparar
// Body JSON:
//   {
//     "idDestinatario": 1,
//     "tipo": "CONFIRMACION_RESERVA",   // ver TipoNotificacion.java
//     "titulo": "Titulo de prueba",
//     "cuerpo": "Cuerpo de prueba"
//   }
//
// Tipos disponibles:
//   CONFIRMACION_RESERVA, RECORDATORIO_24H, CANCELACION_CLIENTE,
//   CANCELACION_PELUQUERIA, NUEVA_CITA_EMPLEADO,
//   CONTRASENA_ACTUALIZADA, AVISO_GENERAL
//
// TODO: Eliminar este archivo (y la regla /test/** en SecurityConfig)
//       antes de pasar a produccion.
// ============================================================
@RestController
@RequestMapping("/test/notificaciones")
@RequiredArgsConstructor
public class TestNotificacionesController {

    private final NotificacionService notificacionService;
    private final UsuarioRepository usuarioRepository;

    @PostMapping("/disparar")
    public ResponseEntity<Map<String, Object>> disparar(@RequestBody Map<String, Object> body) {
        // Extrae parametros del body con valores por defecto razonables.
        Long idDestinatario = Long.valueOf(body.get("idDestinatario").toString());
        String tipo = body.getOrDefault("tipo", "AVISO_GENERAL").toString();
        String titulo = body.getOrDefault("titulo", "Notificacion de prueba").toString();
        String cuerpo = body.getOrDefault("cuerpo", "Esta es una notificacion de prueba desde el endpoint de test.").toString();

        // Valida que el usuario existe.
        Usuario destinatario = usuarioRepository.findById(idDestinatario)
                .orElse(null);
        if (destinatario == null) {
            Map<String, Object> err = new LinkedHashMap<>();
            err.put("ok", false);
            err.put("error", "Usuario no encontrado con id=" + idDestinatario);
            return ResponseEntity.status(404).body(err);
        }

        // Valida el tipo de notificacion.
        TipoNotificacion tipoEnum;
        try {
            tipoEnum = TipoNotificacion.valueOf(tipo.toUpperCase());
        } catch (IllegalArgumentException e) {
            Map<String, Object> err = new LinkedHashMap<>();
            err.put("ok", false);
            err.put("error", "Tipo de notificacion invalido: " + tipo
                    + ". Usa uno de: CONFIRMACION_RESERVA, RECORDATORIO_24H, CANCELACION_CLIENTE, "
                    + "CANCELACION_PELUQUERIA, NUEVA_CITA_EMPLEADO, CONTRASENA_ACTUALIZADA, AVISO_GENERAL");
            return ResponseEntity.badRequest().body(err);
        }

        // Dispara la notificacion (in-app + push si el usuario lo permite).
        var notificacion = notificacionService.crearNotificacion(destinatario, null, tipoEnum, titulo, cuerpo);

        boolean pushEnviada = notificacion != null && Boolean.TRUE.equals(notificacion.getEnviadaPushNotificacion());

        // Respuesta de confirmacion.
        Map<String, Object> resp = new LinkedHashMap<>();
        resp.put("ok", true);
        resp.put("idDestinatario", idDestinatario);
        resp.put("rolDestinatario", destinatario.getRolUsuario().name());
        resp.put("tipo", tipoEnum.name());
        resp.put("titulo", titulo);
        resp.put("cuerpo", cuerpo);
        resp.put("inAppGuardada", true);
        resp.put("pushEnviada", pushEnviada);
        resp.put("mensaje", pushEnviada
                ? "Notificacion disparada. Push enviada por Firebase + in-app guardada en bandeja."
                : "Notificacion in-app guardada. Push NO enviada (el destinatario no tiene tokens FCM registrados, "
                  + "tiene las notificaciones push desactivadas, o Firebase rechazo los tokens).");
        return ResponseEntity.ok(resp);
    }
}

