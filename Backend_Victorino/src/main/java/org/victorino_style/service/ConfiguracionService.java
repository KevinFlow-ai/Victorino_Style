package org.victorino_style.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.victorino_style.dto.admin.CierreAnualRequest;
import org.victorino_style.dto.admin.CierreAnualResponse;
import org.victorino_style.dto.admin.ConfiguracionCorreoRequest;
import org.victorino_style.dto.admin.ConfiguracionCorreoResponse;
import org.victorino_style.dto.admin.DescansoRequest;
import org.victorino_style.dto.admin.DescansoResponse;
import org.victorino_style.dto.admin.FestivoRequest;
import org.victorino_style.dto.admin.FestivoResponse;
import org.victorino_style.dto.admin.HorarioPeluqueriaRequest;
import org.victorino_style.dto.admin.HorarioPeluqueriaResponse;
import org.victorino_style.entity.Empleado;
import org.victorino_style.entity.Festivo;
import org.victorino_style.entity.HorarioEmpleado;
import org.victorino_style.entity.Peluqueria;
import org.victorino_style.exception.EmpleadoNoEncontradoException;
import org.victorino_style.exception.FestivoDuplicadoException;
import org.victorino_style.exception.PeluqueriaNoConfiguradaException;
import org.victorino_style.exception.RecursoNoEncontradoException;
import org.victorino_style.mapper.FestivoMapper;
import org.victorino_style.mapper.HorarioMapper;
import org.victorino_style.repository.EmpleadoRepository;
import org.victorino_style.repository.FestivoRepository;
import org.victorino_style.repository.HorarioEmpleadoRepository;
import org.victorino_style.repository.PeluqueriaRepository;

import java.util.List;

// Servicio del dominio CONFIGURACIÓN del negocio: horario semanal, descansos por empleado,
// festivos puntuales y cierre anual. Todos los endpoints viven bajo /admin/...
@Slf4j
@Service // Marca la clase como un "servicio" dentro de la arquitectura de la aplicación.
@RequiredArgsConstructor
public class ConfiguracionService {

    private final PeluqueriaRepository peluqueriaRepository;
    private final HorarioEmpleadoRepository horarioEmpleadoRepository;
    private final EmpleadoRepository empleadoRepository;
    private final FestivoRepository festivoRepository;
    private final HorarioMapper horarioMapper;
    private final FestivoMapper festivoMapper;
    private final AuditoriaService auditoriaService;

    // ============================================================
    //  HORARIO SEMANAL DE LA PELUQUERÍA
    // ============================================================

    // Obtiene el horario semanal del singleton `peluqueria`.
    @Transactional(readOnly = true)
    public HorarioPeluqueriaResponse obtenerHorario() {
        Peluqueria p = obtenerPeluqueria();
        return horarioMapper.aRespuestaHorario(p);
    }

    // Actualiza el horario semanal. Cualquier par (apertura, cierre) puede ser null
    // para indicar día cerrado. Si solo uno de los dos es null, también lo aceptamos
    // (la lógica de reserva interpretará el día como cerrado).
    @Transactional
    public HorarioPeluqueriaResponse actualizarHorario(HorarioPeluqueriaRequest dto) {
        Peluqueria p = obtenerPeluqueria();
        p.setAperturaLunes(dto.aperturaLunes());     p.setCierreLunes(dto.cierreLunes());
        p.setAperturaMartes(dto.aperturaMartes());   p.setCierreMartes(dto.cierreMartes());
        p.setAperturaMiercoles(dto.aperturaMiercoles()); p.setCierreMiercoles(dto.cierreMiercoles());
        p.setAperturaJueves(dto.aperturaJueves());   p.setCierreJueves(dto.cierreJueves());
        p.setAperturaViernes(dto.aperturaViernes()); p.setCierreViernes(dto.cierreViernes());
        p.setAperturaSabado(dto.aperturaSabado());   p.setCierreSabado(dto.cierreSabado());
        p.setAperturaDomingo(dto.aperturaDomingo()); p.setCierreDomingo(dto.cierreDomingo());
        p = peluqueriaRepository.save(p);

        auditoriaService.registrar("EDITAR_HORARIO", "PELUQUERIA", p.getId(),
                "Actualización del horario semanal");
        return horarioMapper.aRespuestaHorario(p);
    }

    // ============================================================
    //  DESCANSO FIJO DIARIO POR EMPLEADO
    // ============================================================

    // Crea o actualiza la fila de horario_empleado para un empleado concreto.
    @Transactional
    public DescansoResponse actualizarDescanso(Long idEmpleado, DescansoRequest dto) {
        Empleado empleado = empleadoRepository.findActivoById(idEmpleado)
                .orElseThrow(() -> new EmpleadoNoEncontradoException(idEmpleado));

        HorarioEmpleado horario = horarioEmpleadoRepository
                .findByIdEmpleado_Id(idEmpleado)
                .orElseGet(() -> {
                    HorarioEmpleado nuevo = new HorarioEmpleado();
                    nuevo.setIdEmpleado(empleado);
                    return nuevo;
                });

        horario.setDescansoInicioHorario(dto.horaInicio());
        horario.setDescansoDuracionHorario(dto.duracionMinutos());
        horario = horarioEmpleadoRepository.save(horario);

        auditoriaService.registrar("EDITAR_DESCANSO", "HORARIO_EMPLEADO", horario.getId(),
                "Descanso del empleado " + idEmpleado + ": "
                        + dto.horaInicio() + " (" + dto.duracionMinutos() + " min)");

        return horarioMapper.aRespuestaDescanso(horario);
    }

    // ============================================================
    //  FESTIVOS PUNTUALES
    // ============================================================

    // Lista todos los festivos cronológicamente.
    @Transactional(readOnly = true)
    public List<FestivoResponse> listarFestivos() {
        return festivoRepository.findAllByOrderByFechaFestivoAsc().stream()
                .map(festivoMapper::aRespuesta).toList();
    }

    // Añade un festivo. Lanza FestivoDuplicadoException si la fecha ya existe.
    @Transactional
    public FestivoResponse crearFestivo(FestivoRequest dto) {
        if (festivoRepository.existsByFechaFestivo(dto.fecha())) {
            throw new FestivoDuplicadoException(dto.fecha());
        }
        Peluqueria p = obtenerPeluqueria();

        Festivo f = new Festivo();
        f.setIdPeluqueria(p);
        f.setFechaFestivo(dto.fecha());
        f.setDescripcionFestivo(dto.descripcion().trim());
        f.setTipoFestivo(dto.tipo().name());
        f = festivoRepository.save(f);

        auditoriaService.registrar("CREAR_FESTIVO", "FESTIVO", f.getId(),
                "Festivo añadido: " + dto.fecha() + " " + dto.descripcion());
        return festivoMapper.aRespuesta(f);
    }

    // Elimina un festivo por id. Si no existe, 404.
    @Transactional
    public void eliminarFestivo(Long id) {
        Festivo f = festivoRepository.findById(id)
                .orElseThrow(() -> new RecursoNoEncontradoException("Festivo no encontrado con id " + id));
        festivoRepository.delete(f);

        auditoriaService.registrar("ELIMINAR_FESTIVO", "FESTIVO", id,
                "Festivo eliminado: " + f.getFechaFestivo());
    }

    // ============================================================
    //  CIERRE ANUAL
    // ============================================================

    @Transactional(readOnly = true)
    public CierreAnualResponse obtenerCierreAnual() {
        return horarioMapper.aRespuestaCierreAnual(obtenerPeluqueria());
    }

    @Transactional
    public CierreAnualResponse actualizarCierreAnual(CierreAnualRequest dto) {
        // Valida coherencia: si ambas fechas están informadas, fin >= inicio.
        if (dto.fechaInicio() != null && dto.fechaFin() != null
                && dto.fechaFin().isBefore(dto.fechaInicio())) {
            throw new IllegalArgumentException("La fecha fin del cierre anual debe ser igual o posterior al inicio.");
        }
        Peluqueria p = obtenerPeluqueria();
        p.setCierreAnualInicio(dto.fechaInicio());
        p.setCierreAnualFin(dto.fechaFin());
        p = peluqueriaRepository.save(p);

        auditoriaService.registrar("EDITAR_CIERRE_ANUAL", "PELUQUERIA", p.getId(),
                "Cierre anual: " + dto.fechaInicio() + " a " + dto.fechaFin());
        return horarioMapper.aRespuestaCierreAnual(p);
    }

    // ============================================================
    //  CONFIGURACIÓN DE CORREO (SMTP DINÁMICO)
    // ============================================================

    /**
     * Devuelve la configuración SMTP guardada en BD.
     * Si no hay configuración guardada, devuelve {@code configurado=false}.
     * La contraseña nunca se expone.
     */
    @Transactional(readOnly = true)
    public ConfiguracionCorreoResponse obtenerConfigCorreo() {
        Peluqueria p = obtenerPeluqueria();
        boolean tiene = p.getSmtpHost() != null && !p.getSmtpHost().isBlank();
        return new ConfiguracionCorreoResponse(
                tiene ? p.getSmtpHost() : null,
                tiene ? p.getSmtpPort() : null,
                tiene ? p.getSmtpUser() : null,
                p.isSmtpSsl(),
                tiene
        );
    }

    /**
     * Guarda o actualiza la configuración SMTP en la BD.
     * A partir de ese momento {@code MailService} usará estos datos
     * en lugar de los de {@code application.properties}.
     */
    @Transactional
    public ConfiguracionCorreoResponse actualizarConfigCorreo(ConfiguracionCorreoRequest dto) {
        Peluqueria p = obtenerPeluqueria();
        p.setSmtpHost(dto.host().trim());
        p.setSmtpPort(dto.port());
        p.setSmtpUser(dto.user().trim());
        p.setSmtpPassword(dto.password());
        p.setSmtpSsl(dto.ssl());
        p = peluqueriaRepository.save(p);

        auditoriaService.registrar("EDITAR_CONFIG_CORREO", "PELUQUERIA", p.getId(),
                "SMTP → " + dto.host() + ":" + dto.port() + " user=" + dto.user());

        return new ConfiguracionCorreoResponse(
                p.getSmtpHost(), p.getSmtpPort(), p.getSmtpUser(), p.isSmtpSsl(), true);
    }

    // ============================================================
    //  HELPERS
    // ============================================================

    // Devuelve el singleton `peluqueria` o lanza PeluqueriaNoConfiguradaException.
    private Peluqueria obtenerPeluqueria() {
        return peluqueriaRepository.findFirstByOrderByIdAsc()
                .orElseThrow(PeluqueriaNoConfiguradaException::new);
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