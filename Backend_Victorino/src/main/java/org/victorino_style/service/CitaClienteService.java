package org.victorino_style.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.victorino_style.dto.cliente.CitaClienteResponse;
import org.victorino_style.dto.cliente.DetalleCitaExistenteError;
import org.victorino_style.dto.cliente.ModificarCitaRequest;
import org.victorino_style.dto.cliente.ReservarCitaRequest;
import org.victorino_style.entity.Cita;
import org.victorino_style.entity.Cliente;
import org.victorino_style.entity.Empleado;
import org.victorino_style.entity.HorarioEmpleado;
import org.victorino_style.entity.Peluqueria;
import org.victorino_style.entity.Servicio;
import org.victorino_style.entity.enums.EstadoCita;
import org.victorino_style.entity.enums.TipoNotificacion;
import org.victorino_style.exception.CitaFueraDeAntelacionException;
import org.victorino_style.exception.CitaMismoDiaException;
import org.victorino_style.exception.CitaNoModificableException;
import org.victorino_style.exception.CitaSemanaDuplicadaException;
import org.victorino_style.exception.CitaServicioDuplicadoException;
import org.victorino_style.exception.CitaSolapadaException;
import org.victorino_style.exception.EmpleadoNoEncontradoException;
import org.victorino_style.exception.PeluqueriaNoConfiguradaException;
import org.victorino_style.exception.RecursoNoEncontradoException;
import org.victorino_style.exception.ServicioNoEncontradoException;
import org.victorino_style.mapper.CitaClienteMapper;
import org.victorino_style.repository.CitaRepository;
import org.victorino_style.repository.ClienteRepository;
import org.victorino_style.repository.EmpleadoRepository;
import org.victorino_style.repository.FestivoRepository;
import org.victorino_style.repository.HorarioEmpleadoRepository;
import org.victorino_style.repository.PeluqueriaRepository;
import org.victorino_style.repository.ServicioRepository;

import java.time.DayOfWeek;
import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.Comparator;
import java.util.List;
import java.util.Optional;

// Servicio que centraliza TODAS las operaciones sobre citas del cliente final autenticado:
//   - Reservar (POST /cliente/citas).
//   - Modificar (PUT /cliente/citas/{id}).
//   - Cancelar (POST /cliente/citas/{id}/cancelar).
//   - Listar historial y obtener cita activa o detalle.
//
// REGLAS DE NEGOCIO QUE APLICA (en orden de validacion):
//   1) Antelacion: la fecha debe estar entre HOY y HOY+30 dias.
//   2) Dia abierto: no festivo, no cierre anual y dentro del horario semanal.
//   3) Mismo dia: el cliente no puede tener otra cita activa el mismo dia.
//   4) Misma semana ISO (lun-dom): solo una cita activa por semana.
//   5) Mismo servicio: solo una cita activa por servicio (en cualquier fecha).
//   6) Solape horario, descanso, fuera de horario: rechaza si el empleado no esta libre.
//
// CONCURRENCIA:
//   - Antes de insertar/modificar se carga la lista de citas del empleado en esa fecha
//     con LOCK PESIMISTA (findActivasEmpleadoFechaParaActualizar), bloqueando a otras
//     transacciones hasta el commit.
//   - Como red de seguridad adicional, la entidad Cita tiene @Version (lock optimista).
//
// MODO "CUALQUIERA DISPONIBLE":
//   - Si el cliente eligio "Cualquiera" en el Paso 2 del wizard, el frontend envia
//     idEmpleado = empleado mostrado en el chip + cualquieraDisponible = true.
//   - Si al hacer commit ese empleado ya esta ocupado, el backend busca un alternativo
//     dentro de la misma transaccion (fallback). Solo un reintento.
@Slf4j
@Service
@RequiredArgsConstructor
public class CitaClienteService {

    private final CitaRepository citaRepository;
    private final ClienteRepository clienteRepository;
    private final EmpleadoRepository empleadoRepository;
    private final ServicioRepository servicioRepository;
    private final PeluqueriaRepository peluqueriaRepository;
    private final FestivoRepository festivoRepository;
    private final HorarioEmpleadoRepository horarioEmpleadoRepository;
    private final NotificacionService notificacionService;
    private final AuditoriaService auditoriaService;
    private final CitaClienteMapper mapper;

    // ============================================================
    //  RESERVAR (POST /cliente/citas)
    // ============================================================
    @Transactional
    public CitaClienteResponse reservar(Long idCliente, ReservarCitaRequest dto) {
        // 1) Cargar referencias (cliente, servicio).
        Cliente cliente = clienteRepository.findById(idCliente)
                .orElseThrow(() -> new RecursoNoEncontradoException("Cliente no encontrado con id " + idCliente));
        Servicio servicio = servicioRepository.findByIdAndFechaEliminacionServicioIsNull(dto.idServicio())
                .orElseThrow(() -> new ServicioNoEncontradoException(dto.idServicio()));

        // 2) Validar antelacion y dia abierto.
        validarAntelacion(dto.fecha());
        Peluqueria peluqueria = cargarPeluqueria();
        validarDiaAbierto(peluqueria, dto.fecha());

        // 3) Reglas "mismo dia / misma semana / mismo servicio".
        validarReglasCliente(idCliente, dto.fecha(), servicio, null);

        // 4) Resolver empleado (con fallback "Cualquiera" si procede).
        Empleado empleado = resolverEmpleadoConFallback(
                dto.idEmpleado(), Boolean.TRUE.equals(dto.cualquieraDisponible()),
                dto.fecha(), dto.horaInicio(),
                dto.horaInicio().plusMinutes(servicio.getDuracionServicio()),
                peluqueria, null);

        // 5) Validar disponibilidad final del empleado elegido (defensa en profundidad).
        LocalTime horaFin = dto.horaInicio().plusMinutes(servicio.getDuracionServicio());
        validarDisponibilidadEmpleado(empleado, dto.fecha(), dto.horaInicio(), horaFin, peluqueria, null);

        // 6) Persistir la cita.
        Cita cita = new Cita();
        cita.setIdCliente(cliente);
        cita.setIdEmpleado(empleado);
        cita.setIdServicio(servicio);
        cita.setFechaCita(dto.fecha());
        cita.setHoraInicioCita(dto.horaInicio());
        cita.setHoraFinCita(horaFin);
        cita.setEstadoCita(EstadoCita.CONFIRMADA);
        cita.setNotaCita(textoLimpio(dto.nota()));
        Instant ahora = Instant.now();
        cita.setFechaCreacionCita(ahora);
        cita.setFechaModificacionCita(ahora);
        cita.setVersionCita(0L);
        cita = citaRepository.save(cita);

        // 7) Notificar al cliente (CONFIRMACION_RESERVA) y al empleado (NUEVA_CITA_EMPLEADO).
        notificacionService.crearNotificacion(
                cliente.getUsuario(), cita, TipoNotificacion.CONFIRMACION_RESERVA,
                "Cita confirmada",
                "Tu cita del " + dto.fecha() + " a las " + dto.horaInicio()
                        + " con " + empleado.getNombreEmpleado()
                        + " (" + servicio.getNombreServicio() + ") esta confirmada.");
        notificacionService.crearNotificacion(
                empleado.getUsuario(), cita, TipoNotificacion.NUEVA_CITA_EMPLEADO,
                "Nueva cita asignada",
                "Tienes una cita el " + dto.fecha() + " a las " + dto.horaInicio()
                        + " (" + servicio.getNombreServicio() + ").");

        // 8) Auditar la accion.
        auditoriaService.registrar("CREAR_CITA", "CITA", cita.getId(),
                "Cliente " + idCliente + " reservo cita con empleado " + empleado.getId()
                        + " el " + dto.fecha() + " " + dto.horaInicio());

        log.info("Cita reservada: idCita={}, idCliente={}, idEmpleado={}, fecha={}, hora={}",
                cita.getId(), idCliente, empleado.getId(), dto.fecha(), dto.horaInicio());

        return mapper.aRespuesta(cita);
    }

    // ============================================================
    //  MODIFICAR (PUT /cliente/citas/{idCita})
    // ============================================================
    @Transactional
    public CitaClienteResponse modificar(Long idCliente, Long idCita, ModificarCitaRequest dto) {
        // 1) Cargar la cita con lock pesimista para evitar concurrencia.
        Cita cita = citaRepository.findByIdParaActualizar(idCita)
                .orElseThrow(() -> new RecursoNoEncontradoException("Cita no encontrada con id " + idCita));

        // 2) La cita debe pertenecer al cliente autenticado.
        if (cita.getIdCliente() == null || !cita.getIdCliente().getId().equals(idCliente)) {
            throw new RecursoNoEncontradoException("Cita no encontrada con id " + idCita);
        }

        // 3) Solo se puede modificar si esta CONFIRMADA.
        if (cita.getEstadoCita() != EstadoCita.CONFIRMADA) {
            throw new CitaNoModificableException(idCita);
        }

        // 4) Cargar referencias del cambio.
        Servicio servicioNuevo = servicioRepository.findByIdAndFechaEliminacionServicioIsNull(dto.idServicio())
                .orElseThrow(() -> new ServicioNoEncontradoException(dto.idServicio()));

        // 5) Validar antelacion y dia abierto.
        validarAntelacion(dto.fecha());
        Peluqueria peluqueria = cargarPeluqueria();
        validarDiaAbierto(peluqueria, dto.fecha());

        // 6) Reglas "mismo dia / semana / servicio" excluyendo la propia cita del calculo.
        validarReglasCliente(idCliente, dto.fecha(), servicioNuevo, cita.getId());

        // 7) Resolver empleado (con fallback "Cualquiera" si procede).
        Empleado empleadoNuevo = resolverEmpleadoConFallback(
                dto.idEmpleado(), Boolean.TRUE.equals(dto.cualquieraDisponible()),
                dto.fecha(), dto.horaInicio(),
                dto.horaInicio().plusMinutes(servicioNuevo.getDuracionServicio()),
                peluqueria, cita.getId());

        // 8) Validar disponibilidad final del empleado en la nueva franja, excluyendo la propia cita.
        LocalTime horaFin = dto.horaInicio().plusMinutes(servicioNuevo.getDuracionServicio());
        validarDisponibilidadEmpleado(empleadoNuevo, dto.fecha(), dto.horaInicio(), horaFin, peluqueria, cita.getId());

        // 9) Aplicar los cambios.
        cita.setIdServicio(servicioNuevo);
        cita.setIdEmpleado(empleadoNuevo);
        cita.setFechaCita(dto.fecha());
        cita.setHoraInicioCita(dto.horaInicio());
        cita.setHoraFinCita(horaFin);
        cita.setNotaCita(textoLimpio(dto.nota()));
        cita.setFechaModificacionCita(Instant.now());
        cita = citaRepository.save(cita);

        // 10) Notificar al empleado nuevo (MODIFICACION_CITA).
        notificacionService.crearNotificacion(
                empleadoNuevo.getUsuario(), cita, TipoNotificacion.MODIFICACION_CITA,
                "Cita modificada",
                "El cliente " + cita.getIdCliente().getNombreCliente()
                        + " ha modificado su cita: ahora es el " + dto.fecha()
                        + " a las " + dto.horaInicio() + " (" + servicioNuevo.getNombreServicio() + ").");

        auditoriaService.registrar("MODIFICAR_CITA", "CITA", cita.getId(),
                "Cliente " + idCliente + " modifico cita " + idCita + " -> "
                        + dto.fecha() + " " + dto.horaInicio() + " empleado " + empleadoNuevo.getId());

        log.info("Cita modificada: idCita={}, idCliente={}, fechaNueva={}, horaNueva={}",
                idCita, idCliente, dto.fecha(), dto.horaInicio());

        return mapper.aRespuesta(cita);
    }

    // ============================================================
    //  CANCELAR (POST /cliente/citas/{idCita}/cancelar)
    // ============================================================
    @Transactional
    public void cancelar(Long idCliente, Long idCita) {
        Cita cita = citaRepository.findByIdParaActualizar(idCita)
                .orElseThrow(() -> new RecursoNoEncontradoException("Cita no encontrada con id " + idCita));

        if (cita.getIdCliente() == null || !cita.getIdCliente().getId().equals(idCliente)) {
            throw new RecursoNoEncontradoException("Cita no encontrada con id " + idCita);
        }
        if (cita.getEstadoCita() != EstadoCita.CONFIRMADA) {
            throw new CitaNoModificableException(idCita);
        }

        cita.setEstadoCita(EstadoCita.CANCELADA_CLIENTE);
        cita.setFechaModificacionCita(Instant.now());
        citaRepository.save(cita);

        // Notificar al empleado dueño de la cita.
        notificacionService.crearNotificacion(
                cita.getIdEmpleado().getUsuario(), cita, TipoNotificacion.CANCELACION_CLIENTE,
                "Cita cancelada por el cliente",
                "El cliente " + cita.getIdCliente().getNombreCliente() + " "
                        + cita.getIdCliente().getApellidosCliente()
                        + " ha cancelado su cita del " + cita.getFechaCita()
                        + " a las " + cita.getHoraInicioCita() + ".");

        auditoriaService.registrar("CANCELAR_CITA", "CITA", idCita,
                "Cliente " + idCliente + " cancelo cita " + idCita);

        log.info("Cita cancelada por cliente: idCita={}, idCliente={}", idCita, idCliente);
    }

    // ============================================================
    //  CONSULTAS DE LECTURA
    // ============================================================

    // Lista las citas del cliente. Si estado es null, devuelve todas (historial completo).
    @Transactional(readOnly = true)
    public List<CitaClienteResponse> listarMisCitas(Long idCliente, EstadoCita estado) {
        return citaRepository.findCitasCliente(idCliente, estado)
                .stream().map(mapper::aRespuesta).toList();
    }

    // Devuelve la cita activa mas proxima del cliente (CONFIRMADA o EN_PROCESO).
    // Empty si no tiene ninguna. La pestaña Home y "Reservar" la usan para mostrar la card o bloquear.
    @Transactional(readOnly = true)
    public Optional<CitaClienteResponse> obtenerMiCitaActiva(Long idCliente) {
        LocalDate hoy = LocalDate.now();
        LocalDate horizonte = hoy.plusDays(30);
        return citaRepository.findActivasClienteEnRango(idCliente, hoy, horizonte)
                .stream()
                .min(Comparator.comparing(Cita::getFechaCita).thenComparing(Cita::getHoraInicioCita))
                .map(mapper::aRespuesta);
    }

    // Detalle de UNA cita propia. Lanza 404 si no existe o no pertenece al cliente.
    @Transactional(readOnly = true)
    public CitaClienteResponse obtenerMiCita(Long idCliente, Long idCita) {
        Cita cita = citaRepository.findById(idCita)
                .orElseThrow(() -> new RecursoNoEncontradoException("Cita no encontrada con id " + idCita));
        if (cita.getIdCliente() == null || !cita.getIdCliente().getId().equals(idCliente)) {
            throw new RecursoNoEncontradoException("Cita no encontrada con id " + idCita);
        }
        return mapper.aRespuesta(cita);
    }

    // ============================================================
    //  HELPERS DE VALIDACION
    // ============================================================

    // Regla 1: la fecha debe estar entre HOY y HOY+30 dias inclusive.
    private void validarAntelacion(LocalDate fecha) {
        LocalDate hoy = LocalDate.now();
        if (fecha.isBefore(hoy)) {
            throw new CitaFueraDeAntelacionException("No puedes reservar en fechas pasadas");
        }
        if (fecha.isAfter(hoy.plusDays(30))) {
            throw new CitaFueraDeAntelacionException("Solo puedes reservar hasta 30 dias por adelantado");
        }
    }

    // Regla 2: la peluqueria debe estar abierta ese dia.
    private void validarDiaAbierto(Peluqueria p, LocalDate fecha) {
        if (festivoRepository.existsByFechaFestivo(fecha)) {
            throw new CitaSolapadaException("La peluqueria esta cerrada (festivo) el " + fecha);
        }
        if (p.getCierreAnualInicio() != null && p.getCierreAnualFin() != null
                && !fecha.isBefore(p.getCierreAnualInicio()) && !fecha.isAfter(p.getCierreAnualFin())) {
            throw new CitaSolapadaException("La peluqueria esta cerrada (vacaciones) el " + fecha);
        }
        if (aperturaPara(p, fecha.getDayOfWeek()) == null
                || cierrePara(p, fecha.getDayOfWeek()) == null) {
            throw new CitaSolapadaException("La peluqueria esta cerrada los " + nombreDia(fecha.getDayOfWeek()));
        }
    }

    // Reglas 3, 4 y 5: mismo dia / misma semana / mismo servicio.
    // Si idCitaExcluir != null, esa cita NO se considera (modo edicion).
    private void validarReglasCliente(Long idCliente, LocalDate fechaNueva, Servicio servicio, Long idCitaExcluir) {
        // Cargar todas las citas activas en la misma semana ISO + el dia.
        LocalDate lunes  = fechaNueva.with(DayOfWeek.MONDAY);
        LocalDate domingo = fechaNueva.with(DayOfWeek.SUNDAY);
        List<Cita> activasSemana = citaRepository.findActivasClienteEnRango(idCliente, lunes, domingo);

        for (Cita c : activasSemana) {
            if (idCitaExcluir != null && c.getId().equals(idCitaExcluir)) continue;
            // Mismo dia exacto.
            if (c.getFechaCita().equals(fechaNueva)) {
                throw new CitaMismoDiaException(detalleDe(c, "CITA_MISMO_DIA"));
            }
            // Misma semana (la lista ya solo contiene esa semana, asi que cualquier cita es de la misma).
            throw new CitaSemanaDuplicadaException(detalleDe(c, "CITA_MISMA_SEMANA"));
        }

        // Mismo servicio activo (en cualquier fecha).
        List<Cita> activasMismoServicio = citaRepository.findActivasClienteServicio(idCliente, servicio.getId());
        for (Cita c : activasMismoServicio) {
            if (idCitaExcluir != null && c.getId().equals(idCitaExcluir)) continue;
            throw new CitaServicioDuplicadoException(detalleDe(c, "CITA_MISMO_SERVICIO"));
        }
    }

    // Regla 6: el empleado debe estar libre en la franja (horario, descanso, otras citas).
    private void validarDisponibilidadEmpleado(Empleado empleado, LocalDate fecha,
                                                LocalTime horaInicio, LocalTime horaFin,
                                                Peluqueria peluqueria, Long idCitaExcluir) {
        // a) Dentro del horario del dia.
        LocalTime apertura = aperturaPara(peluqueria, fecha.getDayOfWeek());
        LocalTime cierre = cierrePara(peluqueria, fecha.getDayOfWeek());
        if (horaInicio.isBefore(apertura) || horaFin.isAfter(cierre)) {
            throw new CitaSolapadaException("La franja queda fuera del horario de apertura");
        }
        // b) Fuera del descanso del empleado.
        Optional<HorarioEmpleado> descansoOpc = horarioEmpleadoRepository.findByIdEmpleado_Id(empleado.getId());
        if (descansoOpc.isPresent()) {
            HorarioEmpleado he = descansoOpc.get();
            LocalTime descansoIni = he.getDescansoInicioHorario();
            LocalTime descansoFin = descansoIni.plusMinutes(he.getDescansoDuracionHorario());
            if (horaInicio.isBefore(descansoFin) && horaFin.isAfter(descansoIni)) {
                throw new CitaSolapadaException("El empleado descansa en esa franja");
            }
        }
        // c) Sin solape con otras citas activas (LOCK PESIMISTA para evitar carreras).
        List<Cita> activas = citaRepository.findActivasEmpleadoFechaParaActualizar(empleado.getId(), fecha);
        for (Cita c : activas) {
            if (idCitaExcluir != null && c.getId().equals(idCitaExcluir)) continue;
            if (horaInicio.isBefore(c.getHoraFinCita()) && horaFin.isAfter(c.getHoraInicioCita())) {
                throw new CitaSolapadaException("El empleado ya tiene una cita en esa franja");
            }
        }
    }

    // ============================================================
    //  FALLBACK "CUALQUIERA DISPONIBLE"
    // ============================================================

    // Devuelve el Empleado que finalmente atendera la cita.
    // Si cualquieraDisponible=false → exige al idEmpleadoElegido.
    // Si cualquieraDisponible=true  → intenta con el elegido; si falla, busca alternativo.
    private Empleado resolverEmpleadoConFallback(Long idEmpleadoElegido, boolean cualquieraDisponible,
                                                  LocalDate fecha, LocalTime horaInicio, LocalTime horaFin,
                                                  Peluqueria peluqueria, Long idCitaExcluir) {

        // Caso 1: el cliente eligio un empleado especifico → solo se usa ese.
        if (idEmpleadoElegido != null && !cualquieraDisponible) {
            return empleadoRepository.findActivoById(idEmpleadoElegido)
                    .orElseThrow(() -> new EmpleadoNoEncontradoException(idEmpleadoElegido));
        }

        // Caso 2: el cliente eligio "Cualquiera" y el frontend resolvio a un id concreto.
        // Intentamos primero con ese (mejor UX: el cliente VE quien le tocara).
        if (idEmpleadoElegido != null) {
            Empleado preferido = empleadoRepository.findActivoById(idEmpleadoElegido).orElse(null);
            if (preferido != null && estaLibreEnFranja(preferido, fecha, horaInicio, horaFin, peluqueria, idCitaExcluir)) {
                return preferido;
            }
            log.info("Empleado preferido {} ocupado; buscando alternativo (fallback Cualquiera)", idEmpleadoElegido);
        }

        // Caso 3: buscar alternativo entre todos los empleados activos, ordenados por menor carga.
        List<Empleado> activos = empleadoRepository.findAllActivos();
        return activos.stream()
                .filter(e -> idEmpleadoElegido == null || !e.getId().equals(idEmpleadoElegido))
                .filter(e -> estaLibreEnFranja(e, fecha, horaInicio, horaFin, peluqueria, idCitaExcluir))
                .min(Comparator
                        .<Empleado>comparingInt(e ->
                                citaRepository.findActivasEmpleadoFecha(e.getId(), fecha).size())
                        .thenComparing(Empleado::getId))
                .orElseThrow(() -> new CitaSolapadaException("No hay ningun empleado disponible en esa franja"));
    }

    // ¿Esta el empleado libre en la franja indicada? Considera horario, descanso y citas (sin lock,
    // se usa solo para descartar candidatos antes del lock pesimista final).
    private boolean estaLibreEnFranja(Empleado empleado, LocalDate fecha,
                                       LocalTime horaInicio, LocalTime horaFin,
                                       Peluqueria peluqueria, Long idCitaExcluir) {
        // Horario del dia.
        LocalTime apertura = aperturaPara(peluqueria, fecha.getDayOfWeek());
        LocalTime cierre   = cierrePara(peluqueria, fecha.getDayOfWeek());
        if (apertura == null || cierre == null) return false;
        if (horaInicio.isBefore(apertura) || horaFin.isAfter(cierre)) return false;
        // Descanso.
        Optional<HorarioEmpleado> descansoOpc = horarioEmpleadoRepository.findByIdEmpleado_Id(empleado.getId());
        if (descansoOpc.isPresent()) {
            HorarioEmpleado he = descansoOpc.get();
            LocalTime descansoIni = he.getDescansoInicioHorario();
            LocalTime descansoFin = descansoIni.plusMinutes(he.getDescansoDuracionHorario());
            if (horaInicio.isBefore(descansoFin) && horaFin.isAfter(descansoIni)) return false;
        }
        // Solape con otras citas activas (sin lock).
        List<Cita> activas = citaRepository.findActivasEmpleadoFecha(empleado.getId(), fecha);
        for (Cita c : activas) {
            if (idCitaExcluir != null && c.getId().equals(idCitaExcluir)) continue;
            if (horaInicio.isBefore(c.getHoraFinCita()) && horaFin.isAfter(c.getHoraInicioCita())) {
                return false;
            }
        }
        return true;
    }

    // ============================================================
    //  HELPERS GENERALES
    // ============================================================

    private Peluqueria cargarPeluqueria() {
        return peluqueriaRepository.findFirstByOrderByIdAsc()
                .orElseThrow(PeluqueriaNoConfiguradaException::new);
    }

    // Devuelve null si el texto es null o blanco; trim() en caso contrario.
    private String textoLimpio(String s) {
        if (s == null) return null;
        String trimmed = s.trim();
        return trimmed.isEmpty() ? null : trimmed;
    }

    // Construye el payload "detalles" para el ApiError de 409. Incluye el nombre del servicio.
    private DetalleCitaExistenteError detalleDe(Cita c, String codigo) {
        return new DetalleCitaExistenteError(
                codigo,
                c.getId(),
                c.getFechaCita(),
                c.getHoraInicioCita(),
                c.getIdServicio().getNombreServicio()
        );
    }

    // Hora de apertura para el dia de la semana correspondiente.
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

    private String nombreDia(DayOfWeek d) {
        return switch (d) {
            case MONDAY    -> "lunes";
            case TUESDAY   -> "martes";
            case WEDNESDAY -> "miercoles";
            case THURSDAY  -> "jueves";
            case FRIDAY    -> "viernes";
            case SATURDAY  -> "sabados";
            case SUNDAY    -> "domingos";
        };
    }
}

// ============================================================================
// CitaClienteService
// ----------------------------------------------------------------------------
// Servicio que aglutina TODA la logica de citas del cliente final autenticado.
// Es el corazon del modulo cliente del backend.
//
// DIAGRAMA DE FLUJO DE UNA RESERVA EXITOSA:
//
//   POST /cliente/citas  ─►  CitaClienteController.reservar(...)
//                             │
//                             ▼
//                  ┌──────────────────────────────────────┐
//                  │ CitaClienteService.reservar(...)     │
//                  │  1) ClienteRepository.findById       │
//                  │  2) ServicioRepository.findActivo    │
//                  │  3) validarAntelacion                │
//                  │  4) validarDiaAbierto                │
//                  │  5) validarReglasCliente (3 reglas)  │
//                  │  6) resolverEmpleadoConFallback      │
//                  │     └─ LOCK PESIMISTA en findActivasEmpleadoFechaParaActualizar
//                  │  7) validarDisponibilidadEmpleado    │
//                  │  8) citaRepository.save              │
//                  │  9) NotificacionService.crearNotificacion (x2)
//                  │ 10) AuditoriaService.registrar       │
//                  └──────────────────────────────────────┘
//                             │
//                             ▼
//                  CitaClienteResponse (con datos completos)
//
// REGLAS DE NEGOCIO DETECTADAS Y SUS EXCEPCIONES:
//
//   ┌──────────────────────────────┬────────────────────────────────────┬─────┐
//   │ Regla                        │ Excepcion                          │ Cod │
//   ├──────────────────────────────┼────────────────────────────────────┼─────┤
//   │ Fecha < HOY o > HOY+30       │ CitaFueraDeAntelacionException     │ 409 │
//   │ Dia festivo / cierre anual   │ CitaSolapadaException              │ 409 │
//   │ Dia sin horario configurado  │ CitaSolapadaException              │ 409 │
//   │ Otra cita activa MISMO DIA   │ CitaMismoDiaException              │ 409 │
//   │ Otra cita activa MISMA SEM   │ CitaSemanaDuplicadaException       │ 409 │
//   │ Otra cita activa MISMO SVC   │ CitaServicioDuplicadoException     │ 409 │
//   │ Solape franja / descanso     │ CitaSolapadaException              │ 409 │
//   │ Cita inexistente / ajena     │ RecursoNoEncontradoException       │ 404 │
//   │ Estado != CONFIRMADA al mod  │ CitaNoModificableException         │ 409 │
//   │ Empleado/servicio inexistente│ Empleado/ServicioNoEncontrado      │ 404 │
//   └──────────────────────────────┴────────────────────────────────────┴─────┘
//
// CONCURRENCIA EN DETALLE:
//
//   citaRepository.findActivasEmpleadoFechaParaActualizar(idEmpleado, fecha)
//     usa @Lock(PESSIMISTIC_WRITE). MySQL ejecuta SELECT ... FOR UPDATE en las
//     filas relevantes. Otras transacciones que llamen al mismo metodo para el
//     mismo empleado+fecha quedan en espera hasta el commit/rollback.
//
//   Combinacion con @Version (lock optimista) en la entidad Cita: si por algun
//   motivo dos transacciones llegan al UPDATE simultaneamente (caso teorico
//   improbable), Hibernate lanza OptimisticLockException y el handler global
//   la trata como 409.
//
// ============================================================================
