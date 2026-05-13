package org.victorino_style.scheduler;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.victorino_style.entity.Cita;
import org.victorino_style.entity.enums.TipoNotificacion;
import org.victorino_style.repository.CitaRepository;
import org.victorino_style.service.NotificacionService;

import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.List;

// ============================================================
// Scheduler de notificaciones pendientes.
//
// Objetivo: detectar citas cuyo estado cambio DIRECTAMENTE en la BD
// (sin pasar por la capa de servicio) y enviar las notificaciones
// que no se generaron por el flujo normal.
//
// Se ejecuta cada 2 minutos. Solo procesa citas con fechaCita en los
// ultimos 30 dias o en el futuro para evitar spam historico.
//
// Tipos gestionados:
//   CANCELACION_CLIENTE    -> Cita CANCELADA_CLIENTE | destinatario: empleado
//   CANCELACION_PELUQUERIA -> Cita CANCELADA_PELUQUERIA | destinatario: cliente
//   CONFIRMACION_RESERVA   -> Cita CONFIRMADA sin notif | destinatario: cliente
// ============================================================
@Slf4j
@Component
@RequiredArgsConstructor
public class NotificacionPendienteScheduler {

    private final CitaRepository         citaRepository;
    private final NotificacionService    notificacionService;

    private static final DateTimeFormatter FMT_FECHA = DateTimeFormatter.ofPattern("dd/MM/yyyy");
    private static final DateTimeFormatter FMT_HORA  = DateTimeFormatter.ofPattern("HH:mm");

    // Ventana hacia atras: solo procesamos citas de los ultimos 30 dias.
    private static final int DIAS_VENTANA = 30;

    // 2 minutos de periodo. Inicio diferido de 90 s tras arrancar la app
    // para no solaparse con RecordatorioScheduler (que arranca a los 60 s).
    @Scheduled(fixedRate = 2 * 60 * 1000L, initialDelay = 90 * 1000L)
    public void detectarPendientes() {
        LocalDate corte = LocalDate.now().minusDays(DIAS_VENTANA);

        detectarCancelacionesCliente(corte);
        detectarCancelacionesPeluqueria(corte);
        detectarConfirmacionesNuevas(corte);
    }

    // ------------------------------------------------------------------
    // CANCELACION_CLIENTE
    // Cita paso a CANCELADA_CLIENTE pero el empleado no recibio notif.
    // ------------------------------------------------------------------
    private void detectarCancelacionesCliente(LocalDate corte) {
        List<Cita> pendientes = citaRepository.findCanceladasClienteSinNotifEmpleado(corte);

        if (!pendientes.isEmpty()) {
            log.info("[PendienteScheduler] {} cita(s) CANCELADA_CLIENTE sin notificacion al empleado", pendientes.size());
        }

        for (Cita c : pendientes) {
            try {
                String nombreCliente = nombreCompleto(
                        c.getIdCliente() != null ? c.getIdCliente().getNombreCliente() : "Un cliente",
                        c.getIdCliente() != null ? c.getIdCliente().getApellidosCliente() : "");

                String titulo = "Cita cancelada por cliente";
                String cuerpo = nombreCliente
                        + " ha cancelado su cita del "
                        + c.getFechaCita().format(FMT_FECHA)
                        + " a las " + c.getHoraInicioCita().format(FMT_HORA) + ".";

                notificacionService.crearNotificacion(
                        c.getIdEmpleado().getUsuario(),
                        c,
                        TipoNotificacion.CANCELACION_CLIENTE,
                        titulo,
                        cuerpo);

                log.info("[PendienteScheduler] CANCELACION_CLIENTE -> empleado={} | cita={}",
                        c.getIdEmpleado().getId(), c.getId());

            } catch (Exception ex) {
                log.warn("[PendienteScheduler] Error procesando CANCELACION_CLIENTE cita={}: {}",
                        c.getId(), ex.getMessage());
            }
        }
    }

    // ------------------------------------------------------------------
    // CANCELACION_PELUQUERIA
    // Cita paso a CANCELADA_PELUQUERIA pero el cliente no recibio notif.
    // ------------------------------------------------------------------
    private void detectarCancelacionesPeluqueria(LocalDate corte) {
        List<Cita> pendientes = citaRepository.findCanceladasPeluqueriaSinNotifCliente(corte);

        if (!pendientes.isEmpty()) {
            log.info("[PendienteScheduler] {} cita(s) CANCELADA_PELUQUERIA sin notificacion al cliente", pendientes.size());
        }

        for (Cita c : pendientes) {
            try {
                String titulo = "Tu cita ha sido cancelada";
                String cuerpo = "Lo sentimos, tu cita del "
                        + c.getFechaCita().format(FMT_FECHA)
                        + " a las " + c.getHoraInicioCita().format(FMT_HORA)
                        + " con " + c.getIdEmpleado().getNombreEmpleado()
                        + " ha sido cancelada por la peluqueria.";

                notificacionService.crearNotificacion(
                        c.getIdCliente().getUsuario(),
                        c,
                        TipoNotificacion.CANCELACION_PELUQUERIA,
                        titulo,
                        cuerpo);

                log.info("[PendienteScheduler] CANCELACION_PELUQUERIA -> cliente={} | cita={}",
                        c.getIdCliente().getId(), c.getId());

            } catch (Exception ex) {
                log.warn("[PendienteScheduler] Error procesando CANCELACION_PELUQUERIA cita={}: {}",
                        c.getId(), ex.getMessage());
            }
        }
    }

    // ------------------------------------------------------------------
    // CONFIRMACION_RESERVA
    // Cita esta CONFIRMADA con cliente registrado pero no recibio notif.
    // Solo citas cuya fecha sea >= hoy (citas futuras o del dia).
    // ------------------------------------------------------------------
    private void detectarConfirmacionesNuevas(LocalDate corte) {
        // Para CONFIRMACION_RESERVA usamos LocalDate.now() como corte
        // (solo citas futuras/hoy) para evitar enviar confirmaciones de
        // citas ya pasadas que simplemente no tenian notificacion.
        LocalDate corteConfirmacion = LocalDate.now();

        List<Cita> pendientes = citaRepository.findConfirmadasClienteSinNotifReserva(corteConfirmacion);

        if (!pendientes.isEmpty()) {
            log.info("[PendienteScheduler] {} cita(s) CONFIRMADA sin CONFIRMACION_RESERVA al cliente", pendientes.size());
        }

        for (Cita c : pendientes) {
            try {
                String titulo = "Cita confirmada";
                String cuerpo = "Tu cita del "
                        + c.getFechaCita().format(FMT_FECHA)
                        + " a las " + c.getHoraInicioCita().format(FMT_HORA)
                        + " con " + c.getIdEmpleado().getNombreEmpleado()
                        + " ha sido confirmada.";

                notificacionService.crearNotificacion(
                        c.getIdCliente().getUsuario(),
                        c,
                        TipoNotificacion.CONFIRMACION_RESERVA,
                        titulo,
                        cuerpo);

                log.info("[PendienteScheduler] CONFIRMACION_RESERVA -> cliente={} | cita={}",
                        c.getIdCliente().getId(), c.getId());

            } catch (Exception ex) {
                log.warn("[PendienteScheduler] Error procesando CONFIRMACION_RESERVA cita={}: {}",
                        c.getId(), ex.getMessage());
            }
        }
    }

    // ------------------------------------------------------------------
    // Utilidad: combina nombre y apellidos en un string no vacio.
    // ------------------------------------------------------------------
    private String nombreCompleto(String nombre, String apellidos) {
        if (nombre == null) nombre = "";
        if (apellidos == null) apellidos = "";
        String full = (nombre + " " + apellidos).trim();
        return full.isEmpty() ? "Un cliente" : full;
    }
}

