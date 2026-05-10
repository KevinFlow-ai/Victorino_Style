package org.victorino_style.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;
import org.victorino_style.entity.Auditoria;
import org.victorino_style.entity.Usuario;
import org.victorino_style.repository.AuditoriaRepository;
import org.victorino_style.repository.UsuarioRepository;

import java.time.Instant;

// Servicio de auditoría. Centraliza la inserción de filas en la tabla `auditoria`
// para registrar todas las acciones sensibles del administrador.


@Slf4j // generar automáticamente un logger llamado "log" dentro de la clase.
@Service // Marca la clase como un "servicio" dentro de la arquitectura de la aplicación.
@RequiredArgsConstructor
public class AuditoriaService {

    private final AuditoriaRepository auditoriaRepository;
    private final UsuarioRepository usuarioRepository;

    // ------------------------------------------------------------------------
    // Registra una acción en la tabla `auditoria`.
    //
    // Se ejecuta en una transacción independiente (REQUIRES_NEW) para que el
    // commit/rollback de la lógica de negocio NO arrastre la auditoría.
    //
    // Parámetros:
    // - accion:     verbo ("CREAR_EMPLEADO", "BAJA_SERVICIO", ...).
    // - entidad:    tipo de entidad afectada ("EMPLEADO", "SERVICIO", "CITA", ...).
    // - idEntidad:  id de la fila afectada. Puede ser null para acciones globales.
    // - detalle:    texto libre con contexto. Recortado a 1000 caracteres.
    // ------------------------------------------------------------------------
    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public void registrar(String accion, String entidad, Long idEntidad, String detalle) {
        Usuario ejecutor = obtenerUsuarioEjecutor();
        if (ejecutor == null) {
            log.debug("No hay usuario en contexto: se omite auditoría de {} {}", accion, entidad);
            return;
        }

        Auditoria fila = new Auditoria();
        fila.setIdUsuarioEjecutorAuditoria(ejecutor);
        fila.setAccionAuditoria(recortar(accion, 90));
        fila.setEntidadAuditoria(recortar(entidad, 80));
        fila.setIdEntidadAuditoria(idEntidad);
        fila.setDetalleAuditoria(recortar(detalle, 1000));
        fila.setFechaAuditoria(Instant.now());
        auditoriaRepository.save(fila);
    }

    // Obtiene el Usuario actual desde Spring Security.
    //
    // El JwtAuthenticationFilter pone el ID del usuario (no el correo) como
    // principal. Parseamos a Long y buscamos por id. Si no es numérico o el
    // usuario no existe, devolvemos null y la auditoría se omite silenciosamente.
    private Usuario obtenerUsuarioEjecutor() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null || !auth.isAuthenticated() || auth.getName() == null) return null;
        try {
            long idUsuario = Long.parseLong(auth.getName());
            return usuarioRepository.findById(idUsuario).orElse(null);
        } catch (NumberFormatException ex) {
            return null;
        }
    }

    // Recorta una cadena al máximo permitido por la columna BD.
    private String recortar(String texto, int max) {
        if (texto == null) return null;
        return texto.length() > max ? texto.substring(0, max) : texto;
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

