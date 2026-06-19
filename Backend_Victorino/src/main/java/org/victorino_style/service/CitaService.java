package org.victorino_style.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.victorino_style.dto.admin.*;
import org.victorino_style.entity.*; // Importamos todas las entidades (incluye Peluqueria y Usuario)
import org.victorino_style.entity.enums.EstadoCita;
import org.victorino_style.entity.enums.TipoNotificacion;
import org.victorino_style.exception.CitaSolapadaException;
import org.victorino_style.exception.EmpleadoNoEncontradoException;
import org.victorino_style.exception.PasswordIncorrectaException;
import org.victorino_style.exception.RecursoNoEncontradoException;
import org.victorino_style.exception.ServicioNoEncontradoException;
import org.victorino_style.mapper.CitaMapper;
import org.victorino_style.repository.CitaRepository;
import org.victorino_style.repository.ClienteInvitadoRepository;
import org.victorino_style.repository.ClienteRepository;
import org.victorino_style.repository.EmpleadoRepository;
import org.victorino_style.repository.FestivoRepository;
import org.victorino_style.repository.HorarioEmpleadoRepository;
import org.victorino_style.repository.PeluqueriaRepository;
import org.victorino_style.repository.ServicioRepository;
import org.victorino_style.repository.UsuarioRepository;

import java.time.*; // Importamos java.time.* para incluir Period, LocalDate, LocalTime, etc.
import java.util.ArrayList;
import java.util.List;

// NOTIFICACIONES (los metodos reservar/cancelarPorCliente para el cliente final
// se movieron al nuevo CitaClienteService en el modulo cliente).


// Servicio del dominio CITA enfocado al panel del administrador.
//
// Aglutina:
// - Lectura de la agenda global con filtros (fecha, empleado, estado).
// - Historial completo de un cliente.
// - Creación de citas walk-in (cliente registrado o invitado, validando disponibilidad).
// - Avisos informativos sobre clientes con cancelaciones recientes.
@Slf4j // generar automáticamente un logger llamado "log" dentro de la clase.
@Service
@RequiredArgsConstructor
public class CitaService {

    private final CitaRepository citaRepository;
    private final EmpleadoRepository empleadoRepository;
    private final ServicioRepository servicioRepository;
    private final ClienteRepository clienteRepository;
    private final ClienteInvitadoRepository clienteInvitadoRepository;
    private final PeluqueriaRepository peluqueriaRepository;
    private final FestivoRepository festivoRepository;
    private final HorarioEmpleadoRepository horarioEmpleadoRepository;
    private final NotificacionService notificacionService;
    private final AuditoriaService auditoriaService;
    private final CitaMapper citaMapper;
    private final PasswordEncoder passwordEncoder;
    private final UsuarioRepository usuarioRepository;

    // Umbral de cancelaciones recientes a partir del cual el cliente aparece en avisos.
    @Value("${victorino.avisos.umbral-cancelaciones:3}")
    private int umbralCancelaciones;

    // ============================================================
    //  AGENDA GLOBAL
    // ============================================================

    @Transactional(readOnly = true)
    public List<CitaAdminResponse> agendaGlobal(LocalDate desde, LocalDate hasta,
                                                Long idEmpleado, EstadoCita estado) {
        return citaRepository.buscarAgenda(desde, hasta, idEmpleado, estado)
                .stream().map(citaMapper::aRespuesta).toList();
    }

    // ============================================================
    //  HISTORIAL DE CLIENTE
    // ============================================================

    @Transactional(readOnly = true)
    public HistorialClienteResponse historialCliente(Long idCliente) {
        Cliente cliente = clienteRepository.findById(idCliente)
                .orElseThrow(() -> new RecursoNoEncontradoException("Cliente no encontrado con id " + idCliente));

        List<CitaAdminResponse> citas = citaRepository
                .findByIdCliente_IdOrderByFechaCitaDescHoraInicioCitaDesc(idCliente)
                .stream().map(citaMapper::aRespuesta).toList();

        return new HistorialClienteResponse(
                cliente.getId(),
                cliente.getNombreCliente() + " " + cliente.getApellidosCliente(),
                cliente.getUsuario().getCorreoUsuario(),
                cliente.getTelefonoCliente(),
                cliente.getFotoCliente(),
                cliente.getUsuario().getFechaEliminacionUsuario() == null,
                citas.size(),
                citas
        );
    }

    @Transactional(readOnly = true)
    public HistorialClienteResponse historialClienteConEmpleado(Long idCliente, Long idEmpleado) {
        Cliente cliente = clienteRepository.findById(idCliente)
                .orElseThrow(() -> new RecursoNoEncontradoException("Cliente no encontrado con id " + idCliente));

        empleadoRepository.findById(idEmpleado)
                .orElseThrow(() -> new RecursoNoEncontradoException("Empleado no encontrado con id " + idEmpleado));

        List<CitaAdminResponse> citas = citaRepository
                .findByIdCliente_IdAndIdEmpleado_IdOrderByFechaCitaDescHoraInicioCitaDesc(idCliente, idEmpleado)
                .stream().map(citaMapper::aRespuesta).toList();

        return new HistorialClienteResponse(
                cliente.getId(),
                cliente.getNombreCliente() + " " + cliente.getApellidosCliente(),
                cliente.getUsuario().getCorreoUsuario(),
                cliente.getTelefonoCliente(),
                cliente.getFotoCliente(),
                cliente.getUsuario().getFechaEliminacionUsuario() == null,
                citas.size(),
                citas
        );
    }



    // ============================================================
    //  WALK-IN
    // ============================================================

    @Transactional
    public CitaAdminResponse crearWalkIn(WalkInRequest dto) {
        // 1) Carga referencias.
        Empleado empleado = empleadoRepository.findActivoById(dto.idEmpleado())
                .orElseThrow(() -> new EmpleadoNoEncontradoException(dto.idEmpleado()));
        Servicio servicio = servicioRepository.findByIdAndFechaEliminacionServicioIsNull(dto.idServicio())
                .orElseThrow(() -> new ServicioNoEncontradoException(dto.idServicio()));

        // 2) Calcula hora_fin = hora_inicio + duracion del servicio.
        LocalTime horaFin = dto.horaInicio().plusMinutes(servicio.getDuracionServicio());

        // 3) Valida disponibilidad: día abierto, no festivo, no cierre anual,
        //    fuera de descanso del empleado, sin solape con otra cita.
        validarDisponibilidad(empleado, dto.fecha(), dto.horaInicio(), horaFin);

        // 4) Construye la cita.
        Cita cita = new Cita();
        cita.setIdEmpleado(empleado);
        cita.setIdServicio(servicio);
        cita.setFechaCita(dto.fecha());
        cita.setHoraInicioCita(dto.horaInicio());
        cita.setHoraFinCita(horaFin);
        cita.setEstadoCita(EstadoCita.CONFIRMADA);
        cita.setNotaCita(dto.nota());
        Instant ahora = Instant.now();
        cita.setFechaCreacionCita(ahora);
        cita.setFechaModificacionCita(ahora);
        cita.setVersionCita(0L);

        // 5) Resuelve identidad (XOR cliente / invitado).
        if (dto.idCliente() != null) {
            Cliente cliente = clienteRepository.findById(dto.idCliente())
                    .orElseThrow(() -> new RecursoNoEncontradoException(
                            "Cliente no encontrado con id " + dto.idCliente()));
            cita.setIdCliente(cliente);
        } else {
            ClienteInvitado invitado = new ClienteInvitado();
            invitado.setNombreClienteInvitado(dto.nombreInvitado().trim());
            invitado.setApellidosClienteInvitado(dto.apellidosInvitado().trim());
            invitado.setTelefonoClienteInvitado(
                    dto.telefonoInvitado() == null || dto.telefonoInvitado().isBlank()
                            ? null : dto.telefonoInvitado().trim());
            invitado.setFechaCreacionClienteInvitado(ahora);
            invitado = clienteInvitadoRepository.save(invitado);
            cita.setIdClienteInvitado(invitado);
        }

        cita = citaRepository.save(cita);

        // 6) Notifica al empleado por la nueva cita.
        notificacionService.crearNotificacion(
                empleado.getUsuario(), cita, TipoNotificacion.NUEVA_CITA_EMPLEADO,
                "Nueva cita asignada",
                "Tienes una cita el " + dto.fecha() + " a las " + dto.horaInicio()
                        + " (" + servicio.getNombreServicio() + ")");

        auditoriaService.registrar("WALK_IN_CREADO", "CITA", cita.getId(),
                "Walk-in creado por admin para empleado " + empleado.getId()
                        + " el " + dto.fecha() + " " + dto.horaInicio());

        log.info("Cita walk-in creada: id={}, empleado={}, fecha={}, hora={}",
                cita.getId(), empleado.getId(), dto.fecha(), dto.horaInicio());

        return citaMapper.aRespuesta(cita);
    }

    // ============================================================
    //  MARCAR NO PRESENTADO
    // ============================================================

    @Transactional
    public void marcarNoPresentado(Long idCita) {
        // 1) Busca la cita.
        Cita cita = citaRepository.findById(idCita)
                .orElseThrow(() -> new RecursoNoEncontradoException("Cita no encontrada con id " + idCita));

        // 2) Cambia el estado y actualiza fecha de modificación.
        cita.setEstadoCita(EstadoCita.NO_PRESENTADO);
        cita.setFechaModificacionCita(Instant.now());

        // 3) Guarda los cambios.
        citaRepository.save(cita);

        // 4) Auditoría.
        auditoriaService.registrar("CITA_NO_PRESENTADO", "CITA", cita.getId(),
                "Cita marcada como no presentado por el personal");

        log.info("Cita marcada como NO ASISTIÓ: id={}", idCita);
    }

    // ============================================================
    //  AVISOS DE CANCELACIONES FRECUENTES
    // ============================================================

    @Transactional(readOnly = true)
    public List<AvisoClienteResponse> avisosCancelacionesFrecuentes() {
        LocalDate fechaCorte = LocalDate.now().minusDays(30);
        List<Object[]> filas = citaRepository.avisosCancelacionesFrecuentes(fechaCorte, umbralCancelaciones);

        List<AvisoClienteResponse> avisos = new ArrayList<>(filas.size());
        for (Object[] fila : filas) {
            Long idCliente = (Long) fila[0];
            String nombre = (String) fila[1];
            String apellidos = (String) fila[2];
            String correo = (String) fila[3];
            long count = ((Number) fila[4]).longValue();
            avisos.add(new AvisoClienteResponse(idCliente, nombre + " " + apellidos, correo, count));
        }
        return avisos;
    }

    // ============================================================
    //  VALIDACIÓN DE DISPONIBILIDAD (helper)
    // ============================================================

    private void validarDisponibilidad(Empleado empleado, LocalDate fecha,
                                       LocalTime horaInicio, LocalTime horaFin) {
        // 1) Festivo concreto.
        if (festivoRepository.existsByFechaFestivo(fecha)) {
            throw new CitaSolapadaException("La peluquería está cerrada (festivo) el " + fecha);
        }
        // 2) Cierre anual.
        peluqueriaRepository.findFirstByOrderByIdAsc().ifPresent(p -> {
            LocalDate ini = p.getCierreAnualInicio();
            LocalDate fin = p.getCierreAnualFin();
            if (ini != null && fin != null
                    && !fecha.isBefore(ini) && !fecha.isAfter(fin)) {
                throw new CitaSolapadaException("La peluquería está cerrada (vacaciones) el " + fecha);
            }
        });
        // 3) Horario de apertura para el día de la semana.
        peluqueriaRepository.findFirstByOrderByIdAsc().ifPresent(p -> {
            LocalTime apertura = aperturaPara(p, fecha.getDayOfWeek());
            LocalTime cierre = cierrePara(p, fecha.getDayOfWeek());
            if (apertura == null || cierre == null) {
                throw new CitaSolapadaException("La peluquería está cerrada ese día.");
            }
            if (horaInicio.isBefore(apertura) || horaFin.isAfter(cierre)) {
                throw new CitaSolapadaException("La franja queda fuera del horario de apertura.");
            }
        });
        // 4) Descanso del empleado.
        horarioEmpleadoRepository.findByIdEmpleado_Id(empleado.getId()).ifPresent(he -> {
            LocalTime ini = he.getDescansoInicioHorario();
            LocalTime fin = ini.plusMinutes(he.getDescansoDuracionHorario());
            // Solapa si la cita comienza antes de fin del descanso y termina después del inicio.
            if (horaInicio.isBefore(fin) && horaFin.isAfter(ini)) {
                throw new CitaSolapadaException("El empleado descansa en esa franja.");
            }
        });
        // 5) Solape con otras citas activas.
        long solapes = citaRepository.contarSolapes(empleado.getId(), fecha, horaInicio, horaFin);
        if (solapes > 0) {
            throw new CitaSolapadaException("El empleado ya tiene una cita en esa franja.");
        }
    }

    // Devuelve la hora de apertura del día indicado.
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

    // ============================================================
    //  PERFIL EMPLEADO: ESTADÍSTICAS Y SEGURIDAD
    // ============================================================

    // ---- NUEVO: Lógica del Perfil con manejo de nulos ----
    @Transactional(readOnly = true)
    public EmpleadoPerfilResumenDTO obtenerResumenPerfilPorId(Long id) {
        // 1. Buscamos al empleado directamente por ID
        Empleado empleado = empleadoRepository.findActivoById(id)
                .orElseThrow(() -> new RecursoNoEncontradoException("Empleado no encontrado"));

        // 2. Contamos citas con estado COMPLETADA
        long completadas = citaRepository.countByIdEmpleado_IdAndEstadoCita(
                empleado.getId(),
                EstadoCita.COMPLETADA
        );

        // 3. Calculamos la experiencia desde que se creó su usuario
        LocalDate inicio = empleado.getUsuario().getFechaCreacionUsuario()
                .atZone(ZoneId.systemDefault())
                .toLocalDate();

        Period periodo = Period.between(inicio, LocalDate.now());

        String experiencia;
        if (periodo.getYears() == 0 && periodo.getMonths() == 0) {
            experiencia = "Menos de 1 mes";
        } else if (periodo.getYears() == 0) {
            experiencia = periodo.getMonths() + (periodo.getMonths() == 1 ? " mes" : " meses");
        } else {
            experiencia = String.format("%d años y %d meses", periodo.getYears(), periodo.getMonths());
        }

        return new EmpleadoPerfilResumenDTO(
                empleado.getId(),
                empleado.getNombreEmpleado() + " " + empleado.getApellidosEmpleado(),
                empleado.getFotoEmpleado(),
                completadas,
                experiencia
        );
    }

    @Transactional
    public void actualizarPasswordPorId(Long id, String vieja, String nueva) {
        // Buscamos al empleado por ID directamente
        Empleado empleado = empleadoRepository.findActivoById(id)
                .orElseThrow(() -> new RecursoNoEncontradoException("Empleado no encontrado"));

        Usuario usuario = empleado.getUsuario();

        if (!passwordEncoder.matches(vieja, usuario.getContrasenaUsuario())) {
            throw new PasswordIncorrectaException();
        }

        usuario.setContrasenaUsuario(passwordEncoder.encode(nueva));
        usuario.setFechaModificacionUsuario(Instant.now());

        usuarioRepository.save(usuario);

        auditoriaService.registrar(
                "CAMBIAR_PASSWORD_EMPLEADO",
                "USUARIO",
                usuario.getId(),
                "Cambio de contraseña del empleado " + usuario.getCorreoUsuario()
        );

        log.info("Contraseña actualizada para el empleado id={}", empleado.getId());
    }


}
