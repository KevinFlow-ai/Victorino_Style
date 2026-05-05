package org.victorino_style.service;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.victorino_style.dto.admin.MetricasResumenResponse;
import org.victorino_style.entity.enums.EstadoCita;
import org.victorino_style.repository.CitaRepository;

import java.time.DayOfWeek;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

// Servicio de métricas. TODAS las consultas son agregaciones en BD: no se cargan
// entidades en memoria. Esto mantiene el tiempo de respuesta estable cuando la
// tabla `cita` crezca.
@Service // Marca la clase como un "servicio" dentro de la arquitectura de la aplicación.
@RequiredArgsConstructor
public class MetricaService {

    private final CitaRepository citaRepository;

    @Transactional(readOnly = true)
    public MetricasResumenResponse resumen(LocalDate desde, LocalDate hasta) {
        // 1) Conteos básicos por estado.
        long total       = citaRepository.contarTotal(desde, hasta);
        long completadas = citaRepository.contarPorEstado(desde, hasta, EstadoCita.COMPLETADA);
        long canceladasC = citaRepository.contarPorEstado(desde, hasta, EstadoCita.CANCELADA_CLIENTE);
        long canceladasP = citaRepository.contarPorEstado(desde, hasta, EstadoCita.CANCELADA_PELUQUERIA);
        long noPresentado= citaRepository.contarPorEstado(desde, hasta, EstadoCita.NO_PRESENTADO);
        long canceladas  = canceladasC + canceladasP;

        // 2) Tasa de asistencia = completadas / (total - canceladas) * 100.
        long denominador = total - canceladas;
        double tasa = denominador > 0
                ? Math.round(((double) completadas / denominador) * 10000.0) / 100.0
                : 0.0;

        // 3) Servicio más solicitado y empleado más reservado: primer Object[] del ranking.
        MetricasResumenResponse.ServicioPopular servicioTop = null;
        List<Object[]> rankingS = citaRepository.rankingServicios(desde, hasta);
        if (!rankingS.isEmpty()) {
            Object[] r = rankingS.get(0);
            servicioTop = new MetricasResumenResponse.ServicioPopular(
                    (Long) r[0], (String) r[1], (Long) r[2]);
        }

        MetricasResumenResponse.EmpleadoPopular empleadoTop = null;
        List<Object[]> rankingE = citaRepository.rankingEmpleados(desde, hasta);
        if (!rankingE.isEmpty()) {
            Object[] r = rankingE.get(0);
            empleadoTop = new MetricasResumenResponse.EmpleadoPopular(
                    (Long) r[0], r[1] + " " + r[2], (Long) r[3]);
        }

        // 4) Distribución por día de la semana.
        List<MetricasResumenResponse.DistribucionDia> distDia = new ArrayList<>();
        for (Object[] r : citaRepository.distribucionPorDiaSemana(desde, hasta)) {
            // MySQL DAYOFWEEK: 1=Domingo … 7=Sábado. Java DayOfWeek: 1=Lunes … 7=Domingo.
            int mysqlDay = ((Number) r[0]).intValue();
            DayOfWeek dia = mysqlAJavaDayOfWeek(mysqlDay);
            distDia.add(new MetricasResumenResponse.DistribucionDia(dia, ((Number) r[1]).longValue()));
        }

        // 5) Distribución por franja horaria.
        List<MetricasResumenResponse.DistribucionFranja> distFranja = new ArrayList<>();
        for (Object[] r : citaRepository.distribucionPorFranjaHoraria(desde, hasta)) {
            int hora = ((Number) r[0]).intValue();
            distFranja.add(new MetricasResumenResponse.DistribucionFranja(
                    String.format("%02d:00", hora), ((Number) r[1]).longValue()));
        }

        return new MetricasResumenResponse(
                total, completadas, canceladas, noPresentado, tasa,
                servicioTop, empleadoTop, distDia, distFranja);
    }

    // Traduce el entero de MySQL DAYOFWEEK a la enumeración Java DayOfWeek.
    private DayOfWeek mysqlAJavaDayOfWeek(int dayOfWeekMysql) {
        return switch (dayOfWeekMysql) {
            case 1 -> DayOfWeek.SUNDAY;
            case 2 -> DayOfWeek.MONDAY;
            case 3 -> DayOfWeek.TUESDAY;
            case 4 -> DayOfWeek.WEDNESDAY;
            case 5 -> DayOfWeek.THURSDAY;
            case 6 -> DayOfWeek.FRIDAY;
            case 7 -> DayOfWeek.SATURDAY;
            default -> DayOfWeek.MONDAY;
        };
    }
}
