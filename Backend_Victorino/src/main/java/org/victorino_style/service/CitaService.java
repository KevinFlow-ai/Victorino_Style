package org.victorino_style.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.victorino_style.dto.admin.AvisoClienteResponse;
import org.victorino_style.dto.admin.CitaAdminResponse;
import org.victorino_style.dto.admin.HistorialClienteResponse;
import org.victorino_style.dto.admin.WalkInRequest;
import org.victorino_style.entity.Cita;
import org.victorino_style.entity.Cliente;
import org.victorino_style.entity.ClienteInvitado;
import org.victorino_style.entity.Empleado;
import org.victorino_style.entity.Servicio;
import org.victorino_style.entity.enums.EstadoCita;
import org.victorino_style.entity.enums.TipoNotificacion;
import org.victorino_style.exception.CitaSolapadaException;
import org.victorino_style.exception.EmpleadoNoEncontradoException;
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

// NOTIFICACIONES (los metodos reservar/cancelarPorCliente para el cliente final
// se movieron al nuevo CitaClienteService en el modulo cliente).


import java.time.DayOfWeek;
import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.ArrayList;
import java.util.List;

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
            long count = (Long) fila[4];
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
    private LocalTime aperturaPara(org.victorino_style.entity.Peluqueria p, DayOfWeek d) {
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

    private LocalTime cierrePara(org.victorino_style.entity.Peluqueria p, DayOfWeek d) {
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