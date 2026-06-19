package org.victorino_style.scheduler;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;
import org.victorino_style.repository.CitaRepository;

import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalTime;

// Avanza el estado de las citas con el reloj de la zona Europe/Madrid:
//   CONFIRMADA  → EN_PROCESO   cuando llega hora_inicio
//   EN_PROCESO  → COMPLETADA   cuando pasa hora_fin
//
// También recupera las citas atrasadas (por ejemplo, las que cayeron en una
// franja con la aplicación apagada) saltando directamente CONFIRMADA →
// COMPLETADA si su hora_fin ya está en el pasado.
//
// Se ejecuta cada minuto con un retardo inicial de 30 s tras arrancar para
// dejar que el contexto de Spring termine de cargar.
@Slf4j
@Component
@RequiredArgsConstructor
public class CompletadaScheduler {

    private final CitaRepository citaRepository;

    @Scheduled(fixedRate = 60_000L, initialDelay = 30_000L)
    @Transactional
    public void avanzarEstados() {
        Instant ahora = Instant.now();
        LocalDate hoy = LocalDate.now();
        LocalTime horaActual = LocalTime.now();

        int completadas = citaRepository.marcarComoCompletadas(hoy, horaActual, ahora);
        int enProceso = citaRepository.marcarComoEnProceso(hoy, horaActual, ahora);

        if (completadas > 0 || enProceso > 0) {
            log.info("[CompletadaScheduler] {} citas COMPLETADAS, {} citas EN_PROCESO",
                    completadas, enProceso);
        }
    }
}
