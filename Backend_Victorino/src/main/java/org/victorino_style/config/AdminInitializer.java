package org.victorino_style.config;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;
import org.victorino_style.entity.Administrador;
import org.victorino_style.entity.Empleado;
import org.victorino_style.entity.Usuario;
import org.victorino_style.entity.enums.RolUsuario;
import org.victorino_style.repository.AdministradorRepository;
import org.victorino_style.repository.EmpleadoRepository;
import org.victorino_style.repository.UsuarioRepository;

import java.time.Instant;

// ============================================================================
// AdminInitializer
// ----------------------------------------------------------------------------
// Componente que se ejecuta UNA VEZ al arrancar la aplicación. Su única misión
// es asegurar que existe el administrador de prueba con credenciales conocidas
// para que el equipo pueda entrar a la app de inmediato sin tocar SQL a mano.
//
// Comportamiento:
//   1. Comprueba si existe un usuario con el correo configurado en
//      "victorino.admin-prueba.correo".
//   2. Si EXISTE → no hace nada (idempotente, seguro de re-ejecutar).
//   3. Si NO existe → crea las 3 filas necesarias por la herencia JOINED via
//      @MapsId: usuario → empleado → administrador. La contraseña se hashea
//      con BCryptPasswordEncoder en caliente, garantizando que sea siempre
//      válida con la versión del encoder configurada en PasswordEncoderConfig.
//
// Por qué CommandLineRunner y no @PostConstruct: CommandLineRunner se ejecuta
// cuando el contexto de Spring está completamente arrancado, garantizando que
// las transacciones JPA están disponibles.
//
// Para desactivarlo (por ejemplo en tests automáticos o producción) basta con
// poner en application.properties:
//      victorino.admin-prueba.activo=false
// ============================================================================
@Slf4j
@Component
@RequiredArgsConstructor
public class AdminInitializer implements CommandLineRunner {

    private final UsuarioRepository usuarioRepository;
    private final EmpleadoRepository empleadoRepository;
    private final AdministradorRepository administradorRepository;
    private final PasswordEncoder passwordEncoder;

    // Flag de activación. Por defecto activo en cualquier entorno donde no se
    // especifique lo contrario; para desactivarlo se pone =false en properties.
    @Value("${victorino.admin-prueba.activo:true}")
    private boolean activo;

    // Credenciales del admin de prueba. Configurables sin tocar código.
    @Value("${victorino.admin-prueba.correo:victorino@admin.com}")
    private String correoAdmin;

    @Value("${victorino.admin-prueba.password:Admin1234!}")
    private String passwordAdmin;

    @Value("${victorino.admin-prueba.nombre:Victorino}")
    private String nombreAdmin;

    @Value("${victorino.admin-prueba.apellidos:Admin}")
    private String apellidosAdmin;

    @Value("${victorino.admin-prueba.foto:/uploads/empleados/admin.jpg}")
    private String fotoAdmin;

    @Override
    @Transactional
    public void run(String... args) {
        if (!activo) {
            log.info("AdminInitializer desactivado por configuración (victorino.admin-prueba.activo=false).");
            return;
        }

        // Idempotencia: si el admin ya existe, no hacer nada. Protege también
        // del caso en el que el seed.sql ya creó el admin con el mismo correo.
        if (usuarioRepository.existsByCorreoUsuario(correoAdmin)) {
            log.info("Admin de prueba ya existe ({}). No se hace nada.", correoAdmin);
            return;
        }

        log.info("Creando admin de prueba: {}", correoAdmin);

        // 1) Fila en `usuario` con BCrypt en caliente (siempre válido).
        Usuario usuario = new Usuario();
        usuario.setCorreoUsuario(correoAdmin);
        usuario.setContrasenaUsuario(passwordEncoder.encode(passwordAdmin));
        usuario.setRolUsuario(RolUsuario.ADMINISTRADOR);
        Instant ahora = Instant.now();
        usuario.setFechaCreacionUsuario(ahora);
        usuario.setFechaModificacionUsuario(ahora);
        usuario = usuarioRepository.save(usuario);

        // 2) Fila en `empleado` (id_empleado == id_usuario por @MapsId).
        Empleado empleado = new Empleado();
        empleado.setUsuario(usuario);
        empleado.setNombreEmpleado(nombreAdmin);
        empleado.setApellidosEmpleado(apellidosAdmin);
        empleado.setFotoEmpleado(fotoAdmin);
        empleado.setNoMolestarEmpleado(false);
        empleado = empleadoRepository.save(empleado);

        // 3) Fila en `administrador` (id_administrador == id_empleado por @MapsId).
        Administrador administrador = new Administrador();
        administrador.setEmpleado(empleado);
        administradorRepository.save(administrador);

        log.info("Admin de prueba creado correctamente. " +
                        "Login con correo='{}' password='{}' (idUsuario={})",
                correoAdmin, passwordAdmin, usuario.getId());
    }
}
