package org.victorino_style.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.victorino_style.entity.Cita;
import org.victorino_style.entity.Cliente;
import org.victorino_style.entity.DeviceTokenFcm;
import org.victorino_style.entity.Empleado;
import org.victorino_style.entity.Notificacion;
import org.victorino_style.entity.Usuario;
import org.victorino_style.entity.enums.RolUsuario;
import org.victorino_style.entity.enums.TipoNotificacion;
import org.victorino_style.repository.ClienteRepository;
import org.victorino_style.repository.DeviceTokenFcmRepository;
import org.victorino_style.repository.EmpleadoRepository;
import org.victorino_style.repository.NotificacionRepository;

import java.time.Instant;
import java.time.LocalTime;
import java.util.List;

// Servicio de notificaciones in-app + push.
//
// Reglas:
// - In-app SIEMPRE: por cada llamada se inserta una fila en `notificacion`.
// - Push solo si el destinatario lo permite:
//      * Cliente: respeta `cliente.push_activa_cliente`.
//      * Empleado/Admin: respeta el modo "no molestar" y el rango de silencio.
//
// El push real se delega en FirebaseService.enviarPush, hoy todavía un stub.
@Slf4j
@Service
@RequiredArgsConstructor
public class NotificacionService {

    private final NotificacionRepository notificacionRepository;
    private final ClienteRepository clienteRepository;
    private final EmpleadoRepository empleadoRepository;
    private final DeviceTokenFcmRepository deviceTokenFcmRepository;
    private final FirebaseService firebaseService;

    // ------------------------------------------------------------------------
    // Punto de entrada principal: crea una notificación in-app y, si procede,
    // intenta enviar el push.
    // ------------------------------------------------------------------------
    @Transactional
    public Notificacion crearNotificacion(Usuario destinatario,
                                          Cita citaRelacionada,
                                          TipoNotificacion tipo,
                                          String titulo,
                                          String cuerpo) {
        // 1) Inserta la fila in-app SIEMPRE (es la bandeja interna).
        Notificacion fila = new Notificacion();
        fila.setIdDestinatarioNotificacion(destinatario);
        fila.setIdCitaRelacionadaNotificacion(citaRelacionada);
        fila.setTipoNotificacion(tipo.name()); // la entidad usa String hasta que se migre el mapping
        fila.setTituloNotificacion(recortar(titulo, 250));
        fila.setCuerpoNotificacion(recortar(cuerpo, 500));
        fila.setEnviadaPushNotificacion(false);
        fila.setFechaCreacionNotificacion(Instant.now());
        fila = notificacionRepository.save(fila);

        // 2) Decide si toca enviar push según las preferencias del destinatario.
        if (deboEnviarPush(destinatario)) {
            List<String> tokens = deviceTokenFcmRepository
                    .findByIdUsuario_Id(destinatario.getId())
                    .stream()
                    .map(DeviceTokenFcm::getTokenFcm)
                    .toList();
            boolean enviado = firebaseService.enviarPush(tokens, titulo, cuerpo, tipo);
            // 3) Marca la fila como enviada por push si Firebase confirmó éxito.
            if (enviado) {
                fila.setEnviadaPushNotificacion(true);
                notificacionRepository.save(fila);
            }
        }

        return fila;
    }

    // ------------------------------------------------------------------------
    // Determina si el destinatario quiere recibir push según su rol y preferencias.
    // ------------------------------------------------------------------------
    private boolean deboEnviarPush(Usuario u) {
        if (u.getRolUsuario() == RolUsuario.CLIENTE) {
            // El cliente puede haber desactivado el push global desde su perfil.
            return clienteRepository.findById(u.getId())
                    .map(Cliente::getPushActivaCliente)
                    .orElse(false);
        }
        // Empleado y administrador comparten reglas: respetan el "no molestar"
        // y el rango horario de silencio configurado.
        return empleadoRepository.findActivoById(u.getId())
                .map(this::empleadoPermitePush)
                .orElse(false);
    }

    // El empleado permite push si NO está en modo "no molestar" y la hora actual
    // NO está dentro de su rango de silencio (silencio_inicio, silencio_fin).
    private boolean empleadoPermitePush(Empleado e) {
        if (Boolean.TRUE.equals(e.getNoMolestarEmpleado())) return false;
        LocalTime ini = e.getSilencioInicioEmpleado();
        LocalTime fin = e.getSilencioFinEmpleado();
        if (ini == null || fin == null) return true;
        LocalTime ahora = LocalTime.now();
        // Soporta rangos que cruzan la medianoche: si ini > fin, el silencio
        // abarca [ini..23:59] ∪ [00:00..fin].
        if (ini.isBefore(fin)) {
            return ahora.isBefore(ini) || ahora.isAfter(fin);
        }
        return ahora.isAfter(fin) && ahora.isBefore(ini);
    }

    // Recorta el texto a `max` caracteres para no romper la columna BD.
    private String recortar(String texto, int max) {
        if (texto == null) return null;
        return texto.length() > max ? texto.substring(0, max) : texto;
    }
}

// ============================================================================
// NotificacionService
// ----------------------------------------------------------------------------
// Servicio único para crear notificaciones in-app y enviar el push asociado.
//
// LA BANDEJA IN-APP ES LA FUENTE DE VERDAD:
// - Se inserta SIEMPRE una fila en `notificacion`, sea cual sea el resultado
//   del envío push. Garantiza que el usuario vea el mensaje al abrir la app.
//
// PUSH OPCIONAL Y SIN BLOQUEO:
// - El push se envía solo si el destinatario lo permite. La fila in-app se
//   marca con `enviada_push_notificacion = true` solo si Firebase confirmó.
// - Hoy FirebaseService es un stub: la fila quedará SIEMPRE con false hasta
//   que se configure FCM.
// ============================================================================


// ------------------------------------------------------------------------
// @Slf4j
// ------------------------------------------------------------------------
// Esta anotación pertenece a Lombok. Lo que hace es generar automáticamente
// un logger llamado "log" dentro de la clase.
//
// Es decir, en vez de escribir:
//
//   private static final Logger log = LoggerFactory.getLogger(MiClase.class);
//
// Lombok lo genera por ti.
//
// ¿Para qué sirve?
//   → Para escribir logs fácilmente:
//        log.info("Mensaje");
//        log.error("Error", ex);
//        log.debug("Debug...");
//
// Es muy útil en servicios, repositorios y controladores para dejar trazas
// de lo que ocurre en la aplicación.
//
// ------------------------------------------------------------------------
// @Service
// ------------------------------------------------------------------------
// Esta anotación es de Spring. Marca la clase como un "servicio" dentro
// de la arquitectura de la aplicación.
//
// ¿Qué implica?
//   → Spring detecta la clase automáticamente (component scanning).
//   → La instancia se gestiona como un bean del contenedor.
//   → Puede ser inyectada en otras clases con @Autowired o constructor injection.
//
// En la arquitectura típica de Spring:
//
//   - @Controller  → capa de entrada (API)
//   - @Service     → lógica de negocio
//   - @Repository  → acceso a datos
//
// @Service indica que esta clase contiene reglas de negocio,
// validaciones, cálculos, operaciones complejas, etc.
//
// ------------------------------------------------------------------------
// En resumen:
//   @Slf4j   → añade un logger "log" automáticamente.
//   @Service → convierte la clase en un servicio gestionado por Spring.
// ------------------------------------------------------------------------