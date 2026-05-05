package org.victorino_style.service;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.victorino_style.dto.admin.MetricasResumenResponse;
import org.victorino_style.entity.enums.EstadoCita;
import org.victorino_style.repository.CitaRepository;

import java.time.DayOfWeek;
import java.time.LocalDate;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;

// Tests del servicio MetricaService.
// Cubren tasa de asistencia, rankings y traducción de día de semana MySQL→Java.
@ExtendWith(MockitoExtension.class)
class MetricaServiceTest {

    @Mock private CitaRepository citaRepository;

    @InjectMocks
    private MetricaService metricaService;

    private LocalDate desde;
    private LocalDate hasta;

    @BeforeEach
    void preparar() {
        desde = LocalDate.of(2026, 1, 1);
        hasta = LocalDate.of(2026, 12, 31);
    }

    @Test
    @DisplayName("resumen vacío: total 0, tasa 0 y series vacías")
    void resumenSinDatos() {
        when(citaRepository.contarTotal(any(), any())).thenReturn(0L);
        when(citaRepository.contarPorEstado(any(), any(), any())).thenReturn(0L);
        when(citaRepository.rankingServicios(any(), any())).thenReturn(List.of());
        when(citaRepository.rankingEmpleados(any(), any())).thenReturn(List.of());
        when(citaRepository.distribucionPorDiaSemana(any(), any())).thenReturn(List.of());
        when(citaRepository.distribucionPorFranjaHoraria(any(), any())).thenReturn(List.of());

        MetricasResumenResponse r = metricaService.resumen(desde, hasta);

        assertThat(r.totalCitas()).isZero();
        assertThat(r.tasaAsistencia()).isZero();
        assertThat(r.servicioMasSolicitado()).isNull();
        assertThat(r.empleadoMasReservado()).isNull();
        assertThat(r.distribucionPorDiaSemana()).isEmpty();
        assertThat(r.distribucionPorFranjaHoraria()).isEmpty();
    }

    @Test
    @DisplayName("tasa asistencia: 8 completadas / (10 total - 2 canceladas) = 100%")
    void tasaAsistenciaCalculada() {
        when(citaRepository.contarTotal(any(), any())).thenReturn(10L);
        when(citaRepository.contarPorEstado(any(), any(), eqEstado(EstadoCita.COMPLETADA))).thenReturn(8L);
        when(citaRepository.contarPorEstado(any(), any(), eqEstado(EstadoCita.CANCELADA_CLIENTE))).thenReturn(1L);
        when(citaRepository.contarPorEstado(any(), any(), eqEstado(EstadoCita.CANCELADA_PELUQUERIA))).thenReturn(1L);
        when(citaRepository.contarPorEstado(any(), any(), eqEstado(EstadoCita.NO_PRESENTADO))).thenReturn(0L);
        when(citaRepository.rankingServicios(any(), any())).thenReturn(List.of());
        when(citaRepository.rankingEmpleados(any(), any())).thenReturn(List.of());
        when(citaRepository.distribucionPorDiaSemana(any(), any())).thenReturn(List.of());
        when(citaRepository.distribucionPorFranjaHoraria(any(), any())).thenReturn(List.of());

        MetricasResumenResponse r = metricaService.resumen(desde, hasta);

        // 8 / (10-2) = 1.0 → 100.0
        assertThat(r.tasaAsistencia()).isEqualTo(100.0);
        assertThat(r.citasCanceladas()).isEqualTo(2L);
    }

    @Test
    @DisplayName("rankings: toma la primera fila para servicio y empleado top")
    void rankings() {
        when(citaRepository.contarTotal(any(), any())).thenReturn(5L);
        when(citaRepository.contarPorEstado(any(), any(), any())).thenReturn(0L);
        when(citaRepository.rankingServicios(any(), any())).thenReturn(List.<Object[]>of(
                new Object[]{1L, "Corte clásico", 12L},
                new Object[]{2L, "Tinte", 5L}
        ));
        when(citaRepository.rankingEmpleados(any(), any())).thenReturn(List.<Object[]>of(
                new Object[]{7L, "Vito", "Corleone", 20L}
        ));
        when(citaRepository.distribucionPorDiaSemana(any(), any())).thenReturn(List.of());
        when(citaRepository.distribucionPorFranjaHoraria(any(), any())).thenReturn(List.of());

        MetricasResumenResponse r = metricaService.resumen(desde, hasta);

        assertThat(r.servicioMasSolicitado().idServicio()).isEqualTo(1L);
        assertThat(r.servicioMasSolicitado().nombre()).isEqualTo("Corte clásico");
        assertThat(r.servicioMasSolicitado().reservas()).isEqualTo(12L);
        assertThat(r.empleadoMasReservado().nombre()).isEqualTo("Vito Corleone");
        assertThat(r.empleadoMasReservado().citasAtendidas()).isEqualTo(20L);
    }

    @Test
    @DisplayName("traduce día de semana MySQL (1=Domingo) a Java DayOfWeek")
    void traduceDiaSemana() {
        when(citaRepository.contarTotal(any(), any())).thenReturn(5L);
        when(citaRepository.contarPorEstado(any(), any(), any())).thenReturn(0L);
        when(citaRepository.rankingServicios(any(), any())).thenReturn(List.of());
        when(citaRepository.rankingEmpleados(any(), any())).thenReturn(List.of());
        when(citaRepository.distribucionPorFranjaHoraria(any(), any())).thenReturn(List.of());
        // MySQL DAYOFWEEK: 1=Sunday, 2=Monday, ..., 7=Saturday
        when(citaRepository.distribucionPorDiaSemana(any(), any())).thenReturn(List.<Object[]>of(
                new Object[]{1, 5L}, // Domingo → SUNDAY
                new Object[]{2, 12L} // Lunes → MONDAY
        ));

        MetricasResumenResponse r = metricaService.resumen(desde, hasta);

        assertThat(r.distribucionPorDiaSemana()).hasSize(2);
        assertThat(r.distribucionPorDiaSemana().get(0).dia()).isEqualTo(DayOfWeek.SUNDAY);
        assertThat(r.distribucionPorDiaSemana().get(1).dia()).isEqualTo(DayOfWeek.MONDAY);
    }

    @Test
    @DisplayName("franja horaria: convierte int hora a 'HH:00'")
    void franjaHoraria() {
        when(citaRepository.contarTotal(any(), any())).thenReturn(5L);
        when(citaRepository.contarPorEstado(any(), any(), any())).thenReturn(0L);
        when(citaRepository.rankingServicios(any(), any())).thenReturn(List.of());
        when(citaRepository.rankingEmpleados(any(), any())).thenReturn(List.of());
        when(citaRepository.distribucionPorDiaSemana(any(), any())).thenReturn(List.of());
        when(citaRepository.distribucionPorFranjaHoraria(any(), any())).thenReturn(List.<Object[]>of(
                new Object[]{9, 4L},
                new Object[]{10, 8L}
        ));

        MetricasResumenResponse r = metricaService.resumen(desde, hasta);

        assertThat(r.distribucionPorFranjaHoraria()).hasSize(2);
        assertThat(r.distribucionPorFranjaHoraria().get(0).horaInicio()).isEqualTo("09:00");
        assertThat(r.distribucionPorFranjaHoraria().get(1).horaInicio()).isEqualTo("10:00");
    }

    // Helper: matcher para verificar el enum exacto en stubbing.
    private static EstadoCita eqEstado(EstadoCita e) {
        return org.mockito.ArgumentMatchers.eq(e);
    }
}
