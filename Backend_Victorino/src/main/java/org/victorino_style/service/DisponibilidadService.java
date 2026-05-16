package org.victorino_style.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.victorino_style.dto.cliente.HuecoDisponibleResponse;
import org.victorino_style.entity.Cita;
import org.victorino_style.entity.Empleado;
import org.victorino_style.entity.HorarioEmpleado;
import org.victorino_style.entity.Peluqueria;
import org.victorino_style.entity.Servicio;
import org.victorino_style.exception.EmpleadoNoEncontradoException;
import org.victorino_style.exception.PeluqueriaNoConfiguradaException;
import org.victorino_style.exception.ServicioNoEncontradoException;
import org.victorino_style.repository.CitaRepository;
import org.victorino_style.repository.EmpleadoRepository;
import org.victorino_style.repository.FestivoRepository;
import org.victorino_style.repository.HorarioEmpleadoRepository;
import org.victorino_style.repository.PeluqueriaRepository;
import org.victorino_style.repository.ServicioRepository;

import java.time.DayOfWeek;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

// Servicio dedicado al calculo de HUECOS DISPONIBLES para reservar una cita.
// Es el motor del Paso 3 del wizard del cliente.
//
// FLUJO GENERAL:
//   1. Validar entrada (servicio existe, dia abierto).
//   2. Generar todos los slots posibles del dia segun apertura/cierre de la peluqueria
//      y la duracion del servicio.
//   3. Para cada slot, encontrar el empleado (o empleados) que pueden atenderlo:
//        - no esta en descanso
//        - no tiene ya una cita activa solapada
//        - sigue activo en el sistema
//   4. Devolver lista de huecos con el empleado asignado a cada hueco.
//
// MODOS DE OPERACION:
//   - idEmpleado != null: solo se calculan huecos para ese empleado concreto.
//   - idEmpleado == null: modo "Cualquiera disponible". Para cada slot se elige
//     el empleado con MENOS carga ese dia (empate → menor id). Asi se distribuye
//     equitativamente.
//
// MODO EDICION (idCitaExcluir != null):
//   - Al modificar una cita, su propia franja debe aparecer como disponible.
//     Por eso se excluye del calculo de conflictos.
@Slf4j
@Service
@RequiredArgsConstructor
public class DisponibilidadService {

    private final ServicioRepository servicioRepository;
    private final EmpleadoRepository empleadoRepository;
    private final PeluqueriaRepository peluqueriaRepository;
    private final FestivoRepository festivoRepository;
    private final HorarioEmpleadoRepository horarioEmpleadoRepository;
    private final CitaRepository citaRepository;

    // Punto de entrada principal: calcula los huecos disponibles para reservar.
    // Solo lectura; nunca persiste nada.
    @Transactional(readOnly = true)
    public List<HuecoDisponibleResponse> calcularHuecos(Long idServicio,
                                                        LocalDate fecha,
                                                        Long idEmpleado,
                                                        Long idCitaExcluir) {

        // 1) Cargar servicio activo. Si no existe → 404.
        Servicio servicio = servicioRepository.findByIdAndFechaEliminacionServicioIsNull(idServicio)
                .orElseThrow(() -> new ServicioNoEncontradoException(idServicio));
        int duracion = servicio.getDuracionServicio();

        // 2) Validar dia: festivo o cierre anual → lista vacia.
        if (festivoRepository.existsByFechaFestivo(fecha)) {
            log.debug("Disponibilidad: {} es festivo, devuelvo lista vacia", fecha);
            return List.of();
        }
        Peluqueria peluqueria = peluqueriaRepository.findFirstByOrderByIdAsc()
                .orElseThrow(PeluqueriaNoConfiguradaException::new);
        if (estaEnCierreAnual(peluqueria, fecha)) {
            log.debug("Disponibilidad: {} cae dentro del cierre anual, lista vacia", fecha);
            return List.of();
        }

        // 3) Horario de apertura/cierre del dia de la semana.
        LocalTime apertura = aperturaPara(peluqueria, fecha.getDayOfWeek());
        LocalTime cierre   = cierrePara(peluqueria, fecha.getDayOfWeek());
        if (apertura == null || cierre == null) {
            log.debug("Disponibilidad: peluqueria cerrada el {} ({}), lista vacia",
                    fecha, fecha.getDayOfWeek());
            return List.of();
        }

        // 4) Si la fecha es HOY, no devolver slots cuyo inicio sea anterior a la hora actual.
        LocalTime horaMinima = fecha.equals(LocalDate.now()) ? LocalTime.now() : LocalTime.MIN;

        // 5) Generar todos los slots posibles [apertura, apertura+duracion, ...] hasta el cierre.
        List<LocalTime> slots = generarSlots(apertura, cierre, duracion, horaMinima);
        if (slots.isEmpty()) {
            log.debug("Disponibilidad: no hay slots posibles para servicio={} fecha={}", idServicio, fecha);
            return List.of();
        }

        // 6) Resolver candidatos: lista de empleados activos a considerar.
        List<Empleado> empleadosCandidatos;
        if (idEmpleado != null) {
            // Modo empleado concreto: solo ese empleado, debe estar activo.
            Empleado empleado = empleadoRepository.findActivoById(idEmpleado)
                    .orElseThrow(() -> new EmpleadoNoEncontradoException(idEmpleado));
            empleadosCandidatos = List.of(empleado);
        } else {
            // Modo "Cualquiera": todos los empleados activos.
            empleadosCandidatos = empleadoRepository.findAllActivos();
            if (empleadosCandidatos.isEmpty()) {
                log.debug("Disponibilidad: no hay empleados activos en el sistema");
                return List.of();
            }
        }

        // 7) Precargar para cada empleado: su descanso y sus citas activas del dia.
        //    Asi evitamos consultas dentro de bucles anidados.
        Map<Long, HorarioEmpleado> descansoPorEmpleado = new HashMap<>();
        Map<Long, List<Cita>> citasPorEmpleado = new HashMap<>();
        Map<Long, Integer> cargaPorEmpleado = new HashMap<>();
        for (Empleado e : empleadosCandidatos) {
            horarioEmpleadoRepository.findByIdEmpleado_Id(e.getId())
                    .ifPresent(h -> descansoPorEmpleado.put(e.getId(), h));
            List<Cita> citas = citaRepository.findActivasEmpleadoFecha(e.getId(), fecha);
            // Si estamos en modo edicion, descartamos la propia cita del calculo.
            if (idCitaExcluir != null) {
                citas = citas.stream()
                        .filter(c -> !c.getId().equals(idCitaExcluir))
                        .toList();
            }
            citasPorEmpleado.put(e.getId(), citas);
            cargaPorEmpleado.put(e.getId(), citas.size());
        }

        // 8) Para cada slot, encontrar el empleado disponible y construir el hueco.
        List<HuecoDisponibleResponse> huecos = new ArrayList<>(slots.size());
        for (LocalTime inicio : slots) {
            LocalTime fin = inicio.plusMinutes(duracion);

            // El slot debe entrar dentro del horario (defensivo: ya filtrado por generarSlots).
            if (fin.isAfter(cierre)) continue;

            // Filtra los empleados libres en este slot.
            List<Empleado> libres = new ArrayList<>();
            for (Empleado e : empleadosCandidatos) {
                if (!estaDisponibleEnFranja(e, inicio, fin,
                        descansoPorEmpleado.get(e.getId()),
                        citasPorEmpleado.get(e.getId()))) {
                    continue;
                }
                libres.add(e);
            }
            if (libres.isEmpty()) continue;

            // Elegimos: el de MENOS carga ese dia; empate → menor id.
            Empleado asignado = libres.stream()
                    .min(Comparator
                            .<Empleado>comparingInt(e -> cargaPorEmpleado.getOrDefault(e.getId(), 0))
                            .thenComparing(Empleado::getId))
                    .orElseThrow();  // jamas vacio aqui (ya validamos arriba)

            huecos.add(new HuecoDisponibleResponse(
                    inicio,
                    fin,
                    asignado.getId(),
                    asignado.getNombreEmpleado(),
                    asignado.getFotoEmpleado()
            ));
        }

        log.debug("Disponibilidad: servicio={}, fecha={}, modo={}, huecos={}",
                idServicio, fecha, idEmpleado == null ? "CUALQUIERA" : "EMPLEADO_" + idEmpleado, huecos.size());
        return huecos;
    }

    // ---- Helpers ------------------------------------------------------------

    // Genera la lista de horas de inicio posibles para el servicio dado.
    // Avanza en pasos del tamaño de la duracion del servicio (ej. 30 min para corte,
    // 90 min para tinte). Asi los huecos se alinean con la duracion real del servicio.
    // Filtra los slots cuya hora de inicio sea anterior a horaMinima.
    private List<LocalTime> generarSlots(LocalTime apertura, LocalTime cierre,
                                          int duracionMinutos, LocalTime horaMinima) {
        List<LocalTime> slots = new ArrayList<>();
        LocalTime cursor = apertura;
        while (!cursor.plusMinutes(duracionMinutos).isAfter(cierre)) {
            if (!cursor.isBefore(horaMinima)) {
                slots.add(cursor);
            }
            cursor = cursor.plusMinutes(duracionMinutos);
        }
        return slots;
    }

    // ¿Esta el empleado libre en la franja [inicio, fin) ese dia?
    // Considera descanso fijo y citas activas (ya filtradas para excluir idCitaExcluir si toca).
    private boolean estaDisponibleEnFranja(Empleado empleado, LocalTime inicio, LocalTime fin,
                                           HorarioEmpleado descanso, List<Cita> citasDelDia) {
        // 1) Solape con el descanso del empleado.
        if (descanso != null) {
            LocalTime descansoIni = descanso.getDescansoInicioHorario();
            LocalTime descansoFin = descansoIni.plusMinutes(descanso.getDescansoDuracionHorario());
            // Hay solape si el slot empieza antes del fin del descanso Y termina despues del inicio.
            if (inicio.isBefore(descansoFin) && fin.isAfter(descansoIni)) {
                return false;
            }
        }
        // 2) Solape con alguna cita activa.
        if (citasDelDia != null) {
            for (Cita c : citasDelDia) {
                if (inicio.isBefore(c.getHoraFinCita()) && fin.isAfter(c.getHoraInicioCita())) {
                    return false;
                }
            }
        }
        return true;
    }

    // ¿La fecha cae dentro del periodo de cierre anual configurado en la peluqueria?
    private boolean estaEnCierreAnual(Peluqueria p, LocalDate fecha) {
        LocalDate ini = p.getCierreAnualInicio();
        LocalDate fin = p.getCierreAnualFin();
        if (ini == null || fin == null) return false;
        return !fecha.isBefore(ini) && !fecha.isAfter(fin);
    }

    // Devuelve la hora de apertura para el dia de la semana correspondiente.
    private LocalTime aperturaPara(Peluqueria p, DayOfWeek d) {
        return switch (d) {
            case MONDAY    -> p.getAperturaLunes();
            case TUESDAY   -> p.getAperturaMartes();
            case WEDNESDAY -> p.getAperturaMiercoles();
            case THURSDAY  -> p.getAperturaJueves();
            case FRIDAY    -> p.getAperturaViernes();
            case SATURDAY  -> p.getAperturaSabado();
            case SUNDAY    -> p.getAperturaDomingo();
        };
    }

    private LocalTime cierrePara(Peluqueria p, DayOfWeek d) {
        return switch (d) {
            case MONDAY    -> p.getCierreLunes();
            case TUESDAY   -> p.getCierreMartes();
            case WEDNESDAY -> p.getCierreMiercoles();
            case THURSDAY  -> p.getCierreJueves();
            case FRIDAY    -> p.getCierreViernes();
            case SATURDAY  -> p.getCierreSabado();
            case SUNDAY    -> p.getCierreDomingo();
        };
    }
}

// ============================================================================
// DisponibilidadService
// ----------------------------------------------------------------------------
// Motor del Paso 3 del wizard de reserva del cliente.
//
// FLUJO COMPLETO ASCII:
//
//   Cliente abre Paso 3            GET /cliente/citas/disponibilidad?
//   ────────────────────  ───►     idServicio=&fecha=&idEmpleado=&idCitaExcluir=
//          │
//          ▼
//   ┌─────────────────────────────────────────────────────────────┐
//   │ DisponibilidadService.calcularHuecos(...)                   │
//   │                                                              │
//   │ 1) ServicioRepository → duracion del servicio               │
//   │ 2) FestivoRepository  → ¿es festivo?                        │
//   │ 3) PeluqueriaRepository → horario del dia + cierre anual    │
//   │ 4) Empleados candidatos (concreto o todos activos)          │
//   │ 5) HorarioEmpleadoRepository → descanso de cada candidato   │
//   │ 6) CitaRepository.findActivasEmpleadoFecha → solapes        │
//   │ 7) Generar slots, asignar empleado por slot                 │
//   └─────────────────────────────────────────────────────────────┘
//          │
//          ▼
//   List<HuecoDisponibleResponse>   ─────────►   chips del Paso 3
//
// DECISIONES DE DISEÑO:
//
//  - SE PRECARGAN datos por empleado al inicio (descanso y citas del dia) para
//    no hacer N consultas dentro del bucle de slots. Esto da O(slots × empleados)
//    en memoria, despreciable para un dia normal (~30 slots × 5 empleados).
//
//  - En modo "Cualquiera" elegimos siempre el empleado de MENOR carga del dia.
//    Asi se distribuye equitativamente. El empate (mismo numero de citas) se
//    resuelve por menor id, dando un resultado determinista para tests.
//
//  - El metodo es @Transactional(readOnly = true) para que JPA optimice las
//    consultas y NO tome locks.
//
// COMPLEJIDAD: O(slots × empleados × citasDelDia). Tipicamente trivial.
// ============================================================================
