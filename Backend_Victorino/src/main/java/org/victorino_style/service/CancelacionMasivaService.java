package org.victorino_style.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;
import org.victorino_style.dto.admin.CancelacionMasivaResponse;
import org.victorino_style.entity.Cita;
import org.victorino_style.entity.Empleado;
import org.victorino_style.entity.enums.EstadoCita;
import org.victorino_style.entity.enums.TipoNotificacion;
import org.victorino_style.exception.EmpleadoNoEncontradoException;
import org.victorino_style.exception.NoCitasFuturasCancelablesException;
import org.victorino_style.repository.CitaRepository;
import org.victorino_style.repository.EmpleadoRepository;

import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

// Servicio especializado en la cancelación masiva de las citas futuras de un empleado.
//
// Por qué un servicio aparte:
// - La operación cancela MUCHAS citas (potencialmente decenas) y hace una llamada de
//   notificación por cada una. Si un cliente no se puede notificar, no queremos que se
//   revierta toda la operación.
// - Para conseguirlo, cada cancelación se ejecuta en su PROPIA transacción
//   (`@Transactional(propagation = REQUIRES_NEW)`) sobre un métodoo público.
// - El métodoo "padre" se queda sin transacción y se limita a iterar.


@Slf4j // generar automáticamente un logger llamado "log" dentro de la clase.
@Service
@RequiredArgsConstructor
public class CancelacionMasivaService {

    private final CitaRepository citaRepository;
    private final EmpleadoRepository empleadoRepository;
    private final NotificacionService notificacionService;
    private final AuditoriaService auditoriaService;

    // ------------------------------------------------------------------------
    // Cancela todas las citas futuras CONFIRMADAS del empleado dado.
    // ------------------------------------------------------------------------
    public CancelacionMasivaResponse cancelarFuturasDelEmpleado(Long idEmpleado) {
        Empleado empleado = empleadoRepository.findActivoById(idEmpleado)
                .orElseThrow(() -> new EmpleadoNoEncontradoException(idEmpleado));

        // Carga inicial sin lock para conocer cuántas hay (se cargarán con lock al cancelar).
        List<Cita> citas = citaRepository.findCitasFuturasParaCancelar(
                idEmpleado, LocalDate.now(), LocalTime.now());

        if (citas.isEmpty()) {
            throw new NoCitasFuturasCancelablesException(idEmpleado);
        }

        int canceladas = 0;
        int omitidas = 0;
        Set<Long> clientesNotificados = new HashSet<>();

        for (Cita c : citas) {
            try {
                // Cada cita se cancela en una transacción independiente.
                Long idCliente = cancelarUnaCita(c.getId());
                canceladas++;
                if (idCliente != null) clientesNotificados.add(idCliente);
            } catch (Exception ex) {
                // Una cita que falle (p.ej. ya cancelada en otra ventana) NO debe abortar el lote.
                log.warn("No se pudo cancelar la cita id={}: {}", c.getId(), ex.getMessage());
                omitidas++;
            }
        }

        auditoriaService.registrar(
                "CANCELACION_MASIVA", "EMPLEADO", idEmpleado,
                "Canceladas " + canceladas + " citas futuras del empleado "
                        + empleado.getUsuario().getCorreoUsuario());

        log.info("Cancelación masiva: empleado={}, canceladas={}, clientesNotificados={}, omitidas={}",
                idEmpleado, canceladas, clientesNotificados.size(), omitidas);

        return new CancelacionMasivaResponse(
                empleado.getId(),
                empleado.getNombreEmpleado() + " " + empleado.getApellidosEmpleado(),
                canceladas,
                clientesNotificados.size(),
                omitidas);
    }

    // ------------------------------------------------------------------------
    // Cancela UNA cita por id en su propia transacción y notifica al cliente.
    //
    // Es público para que Spring envuelva el métoodo con el proxy transaccional.
    // Devuelve el id del cliente notificado (null si la cita era de un invitado
    // sin usuario asociado, en cuyo caso no se puede notificar).
    // ------------------------------------------------------------------------
    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public Long cancelarUnaCita(Long idCita) {
        Cita cita = citaRepository.findByIdParaActualizar(idCita)
                .orElseThrow(() -> new IllegalStateException("Cita ya inexistente: " + idCita));

        // Solo cancelamos si sigue CONFIRMADA. Si ya estaba en otro estado terminal, omitimos.
        if (cita.getEstadoCita() != EstadoCita.CONFIRMADA) {
            throw new IllegalStateException("La cita " + idCita + " ya no es CONFIRMADA");
        }

        cita.setEstadoCita(EstadoCita.CANCELADA_PELUQUERIA);
        cita.setFechaModificacionCita(Instant.now());
        citaRepository.save(cita);

        // Notifica al cliente registrado (si lo hay). Los walk-in/invitados no tienen Usuario.
        if (cita.getIdCliente() != null) {
            notificacionService.crearNotificacion(
                    cita.getIdCliente().getUsuario(),
                    cita,
                    TipoNotificacion.CANCELACION_PELUQUERIA,
                    "Tu cita ha sido cancelada",
                    "Tu cita del " + cita.getFechaCita() + " a las "
                            + cita.getHoraInicioCita() + " ha sido cancelada por la peluquería. "
                            + "Por favor, reserva una nueva cuando quieras.");
            return cita.getIdCliente().getId();
        }
        return null;
    }
}

// ============================================================================
// CancelacionMasivaService
// ----------------------------------------------------------------------------
// Implementa la operación crítica de "baja médica / ausencia imprevista":
// cancelar TODAS las citas futuras CONFIRMADAS de un empleado y notificar
// a cada cliente afectado.
//
// CONCURRENCIA Y AISLAMIENTO:
// - Cada cita se carga con LOCK PESIMISTA y se cancela en su PROPIA
//   transacción (REQUIRES_NEW). Esto garantiza que:
//      * Si una transacción falla, el resto continúa.
//      * No hay condición de carrera con otra cancelación simultánea
//        (cliente que cancela en paralelo, etc.).
//
// AUDITORÍA:
// - Se registra una única fila de tipo CANCELACION_MASIVA con el resumen.
//   Cada notificación ya queda trazada en su propia tabla.
// ============================================================================



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