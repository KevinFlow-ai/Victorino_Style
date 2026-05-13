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
import org.victorino_style.repository.UsuarioRepository;
import org.victorino_style.dto.NotificacionDto;

import org.springframework.transaction.support.TransactionSynchronization;
import org.springframework.transaction.support.TransactionSynchronizationManager;

import java.time.Instant;
import java.time.LocalTime;
import java.util.List;

// Servicio de notificaciones in-app + push.
//
// Reglas:
// - In-app SIEMPRE: por cada llamada se inserta una fila en `notificacion`.
// - Push solo si el destinatario lo permite:
//      * Cliente: respeta `cliente.push_activa_cliente`.
//      * Empleado: respeta el modo "no molestar" y el rango de silencio.
//      * Administrador: recibe push sin restricciones.
//
// Registro de token FCM (guardarTokenFcm):
// Si el token es NUEVO (primera instalacion / reinstalacion) -> notificacion "Sesion iniciada".
// Si el token ya existia (restauracion de sesion desde splash) -> sin notificacion.
//
// El push real se delega en FirebaseService.enviarPushAsync (@Async).
@Slf4j
@Service
@RequiredArgsConstructor
public class NotificacionService {

    private final NotificacionRepository notificacionRepository;
    private final ClienteRepository clienteRepository;
    private final EmpleadoRepository empleadoRepository;
    private final DeviceTokenFcmRepository deviceTokenFcmRepository;
    private final FirebaseService firebaseService;
    private final UsuarioRepository usuarioRepository;

    // ------------------------------------------------------------------------
    // Punto de entrada principal: crea una notificacion in-app y, si procede,
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
        fila.setTipoNotificacion(tipo.name());
        fila.setTituloNotificacion(recortar(titulo, 250));
        fila.setCuerpoNotificacion(recortar(cuerpo, 500));
        fila.setEnviadaPushNotificacion(false);
        fila.setFechaCreacionNotificacion(Instant.now());
        fila = notificacionRepository.save(fila);

        // 2) Decide si toca enviar push segun las preferencias del destinatario.
        if (deboEnviarPush(destinatario)) {
            List<String> tokens = deviceTokenFcmRepository
                    .findByIdUsuario_Id(destinatario.getId())
                    .stream()
                    .map(DeviceTokenFcm::getTokenFcm)
                    .toList();

            if (!tokens.isEmpty()) {
                // Marca la fila como "push enviada" de forma OPTIMISTA antes de llamar a
                // Firebase. Asi el HTTP thread no espera el ACK de Google (~300-800 ms)
                // y el frontend recibe la respuesta de inmediato.
                fila.setEnviadaPushNotificacion(true);
                notificacionRepository.save(fila);

                // Dispara el push DESPUES de que la transaccion haga commit.
                // Esto evita la race condition en la que Firebase entrega el push
                // antes de que la BD haya confirmado la fila de notificacion, lo que
                // causaba que el movil consultara /notificaciones y no viera nada todavia.
                dispararPushTrasCommit(List.copyOf(tokens), titulo, cuerpo, tipo);
            }
        }

        return fila;
    }

    // esLoginExplicito = true  -> login explicito (el usuario escribio credenciales): SIEMPRE notificacion.
    // esLoginExplicito = false -> restauracion de sesion desde splash: NUNCA notificacion.
    @Transactional
    public void guardarTokenFcm(Long idUsuario, String tokenFcm, String plataforma, boolean esLoginExplicito) {
        log.info("[FCM] Solicitud de registro -> usuario={}, plataforma={}, esLoginExplicito={}, token_inicio={}",
                idUsuario, plataforma, esLoginExplicito,
                tokenFcm != null && tokenFcm.length() > 20 ? tokenFcm.substring(0, 20) + "..." : tokenFcm);

        Usuario usuario = usuarioRepository.findById(idUsuario)
                .orElseThrow(() -> {
                    log.error("[FCM] Usuario con id={} no encontrado en BD", idUsuario);
                    return new RuntimeException("Usuario no encontrado: " + idUsuario);
                });

        DeviceTokenFcm deviceToken = deviceTokenFcmRepository.findByTokenFcm(tokenFcm)
                .orElse(null);

        if (deviceToken == null) {
            deviceToken = new DeviceTokenFcm();
            deviceToken.setTokenFcm(tokenFcm);
            deviceToken.setPlataformaFcm(plataforma);
            log.info("[FCM] Token nuevo guardado para usuario={}", idUsuario);
        } else {
            if (!usuario.getId().equals(deviceToken.getIdUsuario().getId())) {
                log.info("[FCM] Token reasignado de usuario={} a usuario={}", deviceToken.getIdUsuario().getId(), idUsuario);
            } else {
                log.info("[FCM] Token ya existente - actualizando fechaAlta para usuario={}", idUsuario);
            }
        }
        deviceToken.setIdUsuario(usuario);
        deviceToken.setFechaAltaFcm(Instant.now());
        deviceTokenFcmRepository.saveAndFlush(deviceToken);

        // Notificacion in-app SOLO en login explicito (credenciales escritas).
        // La restauracion de sesion (splash con refresh token) pasa esLoginExplicito=false.
        // NO enviamos push FCM para "Sesion iniciada": la app esta en foreground y Flutter
        // mostrara la notificacion local directamente, evitando el throttling de FCM HIGH priority.
        //
        // Antes del catch-up reseteamos enviada_push=false en TODAS las notificaciones no leidas.
        // Motivo: si el empleado tenia sesion activa (token FCM en BD) cuando el admin creo la cita,
        // la notificacion fue marcada enviada_push=true optimisticamente aunque el push pudo no llegar.
        // Al resetear aqui garantizamos que el catch-up las reenvie en este login explicito.
        if (esLoginExplicito) {
            log.info("[FCM] Login explicito -> reseteando enviada_push de notificaciones no leidas para usuario={}", idUsuario);
            notificacionRepository.resetEnviadaPushParaNoLeidas(usuario.getId());

            log.info("[FCM] Login explicito -> creando notificacion in-app (sin push) para usuario={}", idUsuario);
            crearSoloInApp(
                    usuario,
                    TipoNotificacion.AVISO_GENERAL,
                    "Sesion iniciada",
                    "Has iniciado sesion en Victorino Style. Bienvenido/a."
            );
            // Catch-up push: reenviar via FCM las notificaciones pendientes (no leidas).
            if (deboEnviarPush(usuario)) {
                enviarPushPendientesAlLogin(usuario);
            }
        }
    }

    // ------------------------------------------------------------------------
    // Catch-up push al login.
    // Busca las notificaciones que NO se entregaron como push y las reenvía.
    // ------------------------------------------------------------------------
    @Transactional
    private void enviarPushPendientesAlLogin(Usuario usuario) {
        List<Notificacion> pendientes =
                notificacionRepository
                        .findByIdDestinatarioNotificacion_IdAndEnviadaPushNotificacionFalseAndFechaLecturaNotificacionIsNull(
                                usuario.getId());

        if (pendientes.isEmpty()) {
            log.info("[FCM] Sin notificaciones pendientes de push para usuario={}", usuario.getId());
            return;
        }

        List<String> tokens = deviceTokenFcmRepository
                .findByIdUsuario_Id(usuario.getId())
                .stream()
                .map(DeviceTokenFcm::getTokenFcm)
                .toList();

        if (tokens.isEmpty()) {
            log.warn("[FCM] Usuario={} sin tokens FCM registrados, no se puede hacer catch-up push", usuario.getId());
            return;
        }

        log.info("[FCM] Catch-up push: enviando {} notificacion(es) pendiente(s) a usuario={}", pendientes.size(), usuario.getId());

        for (Notificacion notif : pendientes) {
            TipoNotificacion tipo;
            try {
                tipo = TipoNotificacion.valueOf(notif.getTipoNotificacion());
            } catch (IllegalArgumentException e) {
                tipo = TipoNotificacion.AVISO_GENERAL;
            }
            notif.setEnviadaPushNotificacion(true);
            notificacionRepository.save(notif);
            dispararPushTrasCommit(List.copyOf(tokens), notif.getTituloNotificacion(), notif.getCuerpoNotificacion(), tipo);
        }
    }

    // ------------------------------------------------------------------------
    // Determina si el destinatario quiere recibir push segun su rol y preferencias.
    // ------------------------------------------------------------------------
    private boolean deboEnviarPush(Usuario u) {
        if (u.getRolUsuario() == RolUsuario.CLIENTE) {
            return clienteRepository.findById(u.getId())
                    .map(Cliente::getPushActivaCliente)
                    .orElse(false);
        }
        if (u.getRolUsuario() == RolUsuario.ADMINISTRADOR) {
            // El administrador siempre recibe push (no tiene preferencias de silencio propias).
            return true;
        }
        // Empleado: respeta el "no molestar" y el rango horario de silencio.
        return empleadoRepository.findActivoById(u.getId())
                .map(this::empleadoPermitePush)
                .orElse(false);
    }

    // Obtener todas las notificaciones de un usuario
    public List<NotificacionDto> obtenerNotificaciones(Long idUsuario) {
        return notificacionRepository
                .findByIdDestinatarioNotificacion_IdOrderByFechaCreacionNotificacionDesc(idUsuario)
                .stream()
                .map(NotificacionDto::from)
                .toList();
    }

    // Marcar una notificacion como leida
    @Transactional
    public void marcarComoLeida(Long idNotificacion) {
        Notificacion n = notificacionRepository.findById(idNotificacion).orElseThrow();
        n.setFechaLecturaNotificacion(Instant.now());
        notificacionRepository.save(n);
    }

    // ------------------------------------------------------------------------
    // Envia un aviso general a un usuario concreto (de un admin a cualquier usuario).
    // ------------------------------------------------------------------------
    @Transactional
    public void enviarAvisoGeneral(Long idDestinatario, String titulo, String cuerpo) {
        Usuario destinatario = usuarioRepository.findById(idDestinatario)
                .orElseThrow(() -> new RuntimeException("Usuario no encontrado: " + idDestinatario));
        crearNotificacion(destinatario, null, TipoNotificacion.AVISO_GENERAL, titulo, cuerpo);
        log.info("[AVISO_GENERAL] Enviado a idUsuario={} | titulo='{}'", idDestinatario, titulo);
    }

    // El empleado permite push si NO esta en modo "no molestar" y la hora actual
    // NO esta dentro de su rango de silencio (silencio_inicio, silencio_fin).
    private boolean empleadoPermitePush(Empleado e) {
        if (Boolean.TRUE.equals(e.getNoMolestarEmpleado())) return false;
        LocalTime ini = e.getSilencioInicioEmpleado();
        LocalTime fin = e.getSilencioFinEmpleado();
        if (ini == null || fin == null) return true;
        LocalTime ahora = LocalTime.now();
        // Soporta rangos que cruzan la medianoche.
        if (ini.isBefore(fin)) {
            return ahora.isBefore(ini) || ahora.isAfter(fin);
        }
        return ahora.isAfter(fin) && ahora.isBefore(ini);
    }

    // Se crea unicamente el registro in-app SIN enviar push FCM.
    // Se usa en el flujo de login explicito: la app esta en foreground y Flutter
    // mostrara la notificacion local directamente (sin roundtrip FCM).
    // Se marca como enviada_push=true para que el mecanismo de catch-up
    // no la incluya en futuros logins.
    @Transactional
    private void crearSoloInApp(Usuario destinatario, TipoNotificacion tipo, String titulo, String cuerpo) {
        Notificacion fila = new Notificacion();
        fila.setIdDestinatarioNotificacion(destinatario);
        fila.setIdCitaRelacionadaNotificacion(null);
        fila.setTipoNotificacion(tipo.name());
        fila.setTituloNotificacion(recortar(titulo, 250));
        fila.setCuerpoNotificacion(recortar(cuerpo, 500));
        // true = "ya gestionada" - Flutter la mostrara como notificacion local.
        fila.setEnviadaPushNotificacion(true);
        fila.setFechaCreacionNotificacion(Instant.now());
        notificacionRepository.save(fila);
        log.info("[FCM] Notificacion in-app creada (mostrada como local, sin FCM) para usuario={} | tipo={}", destinatario.getId(), tipo);
    }

    // ------------------------------------------------------------------------
    // Despacha el push DESPUES de que la transaccion activa haga commit.
    // Evita la race condition en la que Firebase entrega la notificacion push
    // antes de que la BD confirme la fila en la tabla `notificacion`, haciendo
    // que el movil consulte /notificaciones y no encuentre nada todavia.
    //
    // Si no hay transaccion activa (caso raro, p.ej. test directo) envia de inmediato.
    // ------------------------------------------------------------------------
    private void dispararPushTrasCommit(List<String> tokens, String titulo, String cuerpo, TipoNotificacion tipo) {
        if (TransactionSynchronizationManager.isActualTransactionActive()) {
            TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
                @Override
                public void afterCommit() {
                    firebaseService.enviarPushAsync(tokens, titulo, cuerpo, tipo);
                }
            });
        } else {
            firebaseService.enviarPushAsync(tokens, titulo, cuerpo, tipo);
        }
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