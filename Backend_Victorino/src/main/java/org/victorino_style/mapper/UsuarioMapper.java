package org.victorino_style.mapper;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import org.victorino_style.dto.auth.AuthResponse;
import org.victorino_style.entity.Cliente;
import org.victorino_style.entity.Empleado;
import org.victorino_style.entity.Usuario;
import org.victorino_style.entity.enums.RolUsuario;
import org.victorino_style.repository.ClienteRepository;
import org.victorino_style.repository.EmpleadoRepository;

// Convierte un Usuario en AuthResponse resolviendo nombre y foto desde la subtabla
// correcta según el rol. La herencia se hace por shared PK con @MapsId, así que
// cliente.id == usuario.id (y empleado.id == usuario.id).
@Component
@RequiredArgsConstructor
public class UsuarioMapper {

    private final ClienteRepository clienteRepository; // Repositorio para acceder a la tabla cliente.
    private final EmpleadoRepository empleadoRepository; // Repositorio para acceder a la tabla empleado.



    // ------------------------------------------------------------------------
    // Construye la respuesta de autenticación con:
    // - accessToken
    // - refreshToken
    // - rol del usuario
    // - id del usuario
    // - nombre completo (resuelto desde cliente/empleado)
    // - foto (resuelta desde cliente/empleado)
    // ------------------------------------------------------------------------
    public AuthResponse aAuthResponse(Usuario usuario, String accessToken, String refreshToken) {
        // Por defecto, si no se encuentra subtabla (no debería pasar) usamos correo como fallback.
        String nombreCompleto = usuario.getCorreoUsuario();
        String foto = null;

        switch (usuario.getRolUsuario()) { // Selecciona la subtabla según el rol del usuario
            case CLIENTE -> {
                // Busca en la tabla cliente usando el mismo id que usuario (por @MapsId).
                Cliente cliente = clienteRepository.findById(usuario.getId()).orElse(null);


                if (cliente != null) {
                    // Construye el nombre completo y obtiene la foto.
                    nombreCompleto = (cliente.getNombreCliente() + " " + cliente.getApellidosCliente()).trim();
                    foto = cliente.getFotoCliente();
                }
            }
            case EMPLEADO, ADMINISTRADOR -> {
                // Tanto empleados como administradores están en la tabla empleado.
                Empleado empleado = empleadoRepository.findById(usuario.getId()).orElse(null);
                if (empleado != null) {
                    nombreCompleto = (empleado.getNombreEmpleado() + " " + empleado.getApellidosEmpleado()).trim();
                    foto = empleado.getFotoEmpleado();
                }
            }
        }

        // Devuelve el DTO final con todos los datos necesarios para la app.
        return new AuthResponse(
                accessToken,
                refreshToken,
                usuario.getRolUsuario(),
                usuario.getId(),
                nombreCompleto,
                foto
        );
    }

    // ------------------------------------------------------------------------
    // Métodoo auxiliar para obtener el rol en formato Spring Security:
    // "ROLE_CLIENTE", "ROLE_EMPLEADO", "ROLE_ADMINISTRADOR".
    // Útil en filtros, seguridad y tests.
    // ------------------------------------------------------------------------
    public String rolSpringSecurity(RolUsuario rol) {
        return "ROLE_" + rol.name();
    }
}

    // ============================================================================
    // UsuarioMapper
    // ----------------------------------------------------------------------------
    // Esta clase se encarga de **convertir un Usuario en un AuthResponse**, es decir,
    // transformar la entidad base "usuario" en la respuesta que se envía al cliente
    // después del login o registro.
    //
    // ¿POR QUÉ ES NECESARIO ESTE MAPPER?
    // - La tabla "usuario" solo contiene datos comunes (correo, contraseña, rol).
    // - Los datos visibles para el cliente (nombre, apellidos, foto) están en las
    //   subtablas "cliente" o "empleado", dependiendo del rol.
    // - Gracias a la herencia con @MapsId, el id del usuario coincide con el id del
    //   cliente o empleado, permitiendo buscar fácilmente la información adicional.
    //
    // FUNCIONES PRINCIPALES:
    // - Resolver nombre completo y foto según el rol del usuario.
    // - Construir un AuthResponse con tokens + datos del usuario.
    // - Proveer un métodoo auxiliar para obtener el rol en formato Spring Security.
    //
    // ANOTACIONES IMPORTANTES:
    // - @Component → permite inyectar este mapper donde se necesite.
    // - @RequiredArgsConstructor → genera constructor con dependencias final.
    // ============================================================================

