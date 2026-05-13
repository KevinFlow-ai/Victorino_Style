package org.victorino_style.scheduler;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.victorino_style.entity.Cita;
import org.victorino_style.entity.enums.EstadoCita;
import org.victorino_style.entity.enums.TipoNotificacion;
import org.victorino_style.repository.CitaRepository;
import org.victorino_style.service.NotificacionService;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.format.DateTimeFormatter;
import java.util.List;

// Ejecuta cada 5 minutos. El sistema busca citas en la ventana de 24h a 24h5m desde ahora, solo aquellas
// con estado CONFIRMADA y dispara RECORDATORIO_24H al cliente (si tiene usuario registrado).
// La query findCitasEnVentanaRecordatorio filtra las citas que YA tienen RECORDATORIO_24H para evitar
// enviar duplicados cuando el scheduler vuelve a pasar por la misma ventana.
// El initialDelay de 60 s evita que se dispare en el mismo segundo del arranque.
@Slf4j
@Component
@RequiredArgsConstructor
public class RecordatorioScheduler {

    private final CitaRepository citaRepository;
    private final NotificacionService notificacionService;

    private static final DateTimeFormatter FMT_FECHA = DateTimeFormatter.ofPattern("dd/MM/yyyy");
    private static final DateTimeFormatter FMT_HORA  = DateTimeFormatter.ofPattern("HH:mm");

    // 5 minutos = 300_000 ms. Inicio diferido de 60 s tras arrancar la app.
    @Scheduled(fixedRate = 5 * 60 * 1000L, initialDelay = 60 * 1000L)
    public void disparar() {
        LocalDateTime desde = LocalDateTime.now().plusHours(24);
        LocalDateTime hasta = desde.plusMinutes(5);

        LocalDate fechaDesde = desde.toLocalDate();
        LocalTime horaDesde  = desde.toLocalTime();
        LocalDate fechaHasta = hasta.toLocalDate();
        LocalTime horaHasta  = hasta.toLocalTime();

        List<Cita> citas = citaRepository.findCitasEnVentanaRecordatorio(
                fechaDesde, horaDesde, fechaHasta, horaHasta, EstadoCita.CONFIRMADA);

        log.info("[RecordatorioScheduler] Ventana {}/{} - {}/{} -> {} citas encontradas",
                fechaDesde, horaDesde, fechaHasta, horaHasta, citas.size());

        for (Cita c : citas) {
            // Solo notificamos a clientes registrados (no walk-in invitados).
            if (c.getIdCliente() == null) {
                continue;
            }

            try {
                String fechaFormateada = c.getFechaCita().format(FMT_FECHA);
                String horaFormateada  = c.getHoraInicioCita().format(FMT_HORA);

                notificacionService.crearNotificacion(
                        c.getIdCliente().getUsuario(),
                        c,
                        TipoNotificacion.RECORDATORIO_24H,
                        "Recordatorio: tu cita es manana",
                        "Te esperamos el " + fechaFormateada + " a las " + horaFormateada
                                + " con " + c.getIdEmpleado().getNombreEmpleado() + "."
                );
            } catch (Exception ex) {
                log.warn("[RecordatorioScheduler] Fallo al notificar cita id={}: {}",
                        c.getId(), ex.getMessage());
            }
        }
    }
}
