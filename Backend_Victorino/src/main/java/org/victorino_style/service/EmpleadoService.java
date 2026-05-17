package org.victorino_style.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;
import org.victorino_style.dto.admin.EmpleadoAdminRequest;
import org.victorino_style.dto.admin.EmpleadoAdminResponse;
import org.victorino_style.dto.admin.FotoResponse;
import org.victorino_style.dto.empleado.ConfiguracionEmpleadoRequest;
import org.victorino_style.dto.empleado.PerfilEmpleadoResponse;
import org.victorino_style.entity.Empleado;
import org.victorino_style.entity.Usuario;
import org.victorino_style.entity.enums.RolUsuario;
import org.victorino_style.exception.CorreoDuplicadoException;
import org.victorino_style.exception.EmpleadoNoEncontradoException;
import org.victorino_style.exception.FotoObligatoriaException;
import org.victorino_style.mapper.EmpleadoMapper;
import org.victorino_style.repository.EmpleadoRepository;
import org.victorino_style.repository.UsuarioRepository;

import java.time.Instant;
import java.util.List;
import java.util.Locale;

@Slf4j
@Service
@RequiredArgsConstructor
public class EmpleadoService {

    private final EmpleadoRepository empleadoRepository;
    private final UsuarioRepository usuarioRepository;
    private final PasswordEncoder passwordEncoder;
    private final EmpleadoMapper empleadoMapper;
    private final FileStorageService fileStorageService;
    private final AuditoriaService auditoriaService;

    private static final String CARPETA_FOTOS = "empleados";

    @Transactional(readOnly = true)
    public List<EmpleadoAdminResponse> listar(boolean incluirInactivos) {
        List<Empleado> empleados = incluirInactivos
                ? empleadoRepository.findAllOrderActivosPrimero()
                : empleadoRepository.findAllActivos();
        return empleados.stream().map(empleadoMapper::aRespuesta).toList();
    }

    @Transactional(readOnly = true)
    public EmpleadoAdminResponse obtener(Long idEmpleado) {
        Empleado empleado = empleadoRepository.findActivoById(idEmpleado)
                .orElseThrow(() -> new EmpleadoNoEncontradoException(idEmpleado));
        return empleadoMapper.aRespuesta(empleado);
    }

    @Transactional(readOnly = true)
    public PerfilEmpleadoResponse obtenerPerfil(Long idEmpleado) {
        Empleado empleado = empleadoRepository.findActivoById(idEmpleado)
                .orElseThrow(() -> new EmpleadoNoEncontradoException(idEmpleado));
        return empleadoMapper.aPerfilRespuesta(empleado);
    }

    @Transactional
    public void actualizarConfiguracion(Long idEmpleado, ConfiguracionEmpleadoRequest request) {
        Empleado empleado = empleadoRepository.findActivoById(idEmpleado)
                .orElseThrow(() -> new EmpleadoNoEncontradoException(idEmpleado));

        empleado.setSilencioInicioEmpleado(request.silencioInicio());
        empleado.setSilencioFinEmpleado(request.silencioFin());
        empleado.setNoMolestarEmpleado(request.noMolestar());

        empleadoRepository.save(empleado);
        log.info("Configuración actualizada para empleado ID: {}", idEmpleado);
    }

    @Transactional
    public EmpleadoAdminResponse crear(EmpleadoAdminRequest dto) {
        String correo = dto.correo().trim().toLowerCase(Locale.ROOT);

        if (usuarioRepository.existsByCorreoUsuario(correo)) {
            throw new CorreoDuplicadoException(correo);
        }
        if (dto.passwordProvisional() == null || dto.passwordProvisional().isBlank()) {
            throw new IllegalArgumentException("La contraseña provisional es obligatoria al crear un empleado");
        }

        Usuario usuario = new Usuario();
        usuario.setCorreoUsuario(correo);
        usuario.setContrasenaUsuario(passwordEncoder.encode(dto.passwordProvisional()));
        usuario.setRolUsuario(RolUsuario.EMPLEADO);
        Instant ahora = Instant.now();
        usuario.setFechaCreacionUsuario(ahora);
        usuario.setFechaModificacionUsuario(ahora);
        usuario = usuarioRepository.save(usuario);

        Empleado empleado = new Empleado();
        empleado.setUsuario(usuario);
        empleado.setNombreEmpleado(dto.nombre().trim());
        empleado.setApellidosEmpleado(dto.apellidos().trim());
        empleado.setFotoEmpleado("");
        empleado.setNoMolestarEmpleado(false);
        empleado = empleadoRepository.save(empleado);

        auditoriaService.registrar("CREAR_EMPLEADO", "EMPLEADO", empleado.getId(),
                "Alta de empleado: " + correo);

        log.info("Empleado creado: id={}, correo={}", empleado.getId(), correo);
        return empleadoMapper.aRespuesta(empleado);
    }

    @Transactional
    public EmpleadoAdminResponse editar(Long idEmpleado, EmpleadoAdminRequest dto) {
        Empleado empleado = empleadoRepository.findActivoById(idEmpleado)
                .orElseThrow(() -> new EmpleadoNoEncontradoException(idEmpleado));
        Usuario usuario = empleado.getUsuario();

        String correoNuevo = dto.correo().trim().toLowerCase(Locale.ROOT);
        if (!correoNuevo.equals(usuario.getCorreoUsuario())
                && usuarioRepository.existsByCorreoUsuario(correoNuevo)) {
            throw new CorreoDuplicadoException(correoNuevo);
        }

        empleado.setNombreEmpleado(dto.nombre().trim());
        empleado.setApellidosEmpleado(dto.apellidos().trim());
        usuario.setCorreoUsuario(correoNuevo);
        usuario.setFechaModificacionUsuario(Instant.now());

        if (dto.passwordProvisional() != null && !dto.passwordProvisional().isBlank()) {
            usuario.setContrasenaUsuario(passwordEncoder.encode(dto.passwordProvisional()));
        }

        usuarioRepository.save(usuario);
        empleado = empleadoRepository.save(empleado);

        auditoriaService.registrar("EDITAR_EMPLEADO", "EMPLEADO", empleado.getId(),
                "Edición de empleado: " + correoNuevo);

        return empleadoMapper.aRespuesta(empleado);
    }

    @Transactional
    public void darBaja(Long idEmpleado) {
        Empleado empleado = empleadoRepository.findActivoById(idEmpleado)
                .orElseThrow(() -> new EmpleadoNoEncontradoException(idEmpleado));

        var auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth != null && auth.getName() != null
                && auth.getName().equalsIgnoreCase(empleado.getUsuario().getCorreoUsuario())) {
            throw new IllegalStateException("No puedes darte de baja a ti mismo desde el panel.");
        }

        Usuario usuario = empleado.getUsuario();
        Instant ahora = Instant.now();
        usuario.setFechaEliminacionUsuario(ahora);
        usuario.setFechaModificacionUsuario(ahora);
        usuarioRepository.save(usuario);

        auditoriaService.registrar("BAJA_EMPLEADO", "EMPLEADO", empleado.getId(),
                "Baja lógica del empleado " + usuario.getCorreoUsuario());
        log.info("Empleado dado de baja lógica: id={}", empleado.getId());
    }

    @Transactional
    public FotoResponse subirFoto(Long idEmpleado, MultipartFile archivo) {
        if (archivo == null || archivo.isEmpty()) throw new FotoObligatoriaException();

        Empleado empleado = empleadoRepository.findActivoById(idEmpleado)
                .orElseThrow(() -> new EmpleadoNoEncontradoException(idEmpleado));

        String fotoAnterior = empleado.getFotoEmpleado();
        String url = fileStorageService.reemplazar(archivo, CARPETA_FOTOS, fotoAnterior);

        empleado.setFotoEmpleado(url);
        empleadoRepository.save(empleado);

        auditoriaService.registrar("SUBIR_FOTO_EMPLEADO", "EMPLEADO", empleado.getId(),
                "Subida de foto del empleado " + empleado.getUsuario().getCorreoUsuario());

        return new FotoResponse(url);
    }
}
