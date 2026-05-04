package org.victorino_style.repository;

import org.springframework.data.jpa.repository.JpaRepository; // JpaRepository proporciona CRUD completo y paginación sin escribir código.
import org.victorino_style.entity.Usuario;

import java.util.Optional;

// Repositorio de la entidad Usuario. Spring Data genera la implementación.
public interface UsuarioRepository extends JpaRepository<Usuario, Long> {


    // ------------------------------------------------------------------------
    // Busca un usuario por su correo, siempre que NO esté eliminado.
    //
    // Se usa en:
    // - /auth/login → para autenticar al usuario.
    //
    // La condición "fechaEliminacionUsuarioIsNull" garantiza que solo se
    // consideren usuarios activos (soft delete).
    //
    // Devuelve Optional<Usuario> para manejar el caso de no encontrado.
    // ------------------------------------------------------------------------
    Optional<Usuario> findByCorreoUsuarioAndFechaEliminacionUsuarioIsNull(String correoUsuario);






    // ------------------------------------------------------------------------
    // Comprueba si un correo ya está registrado.
    //
    // Se usa en:
    // - /auth/registro → para lanzar CorreoDuplicadoException (HTTP 409).
    //
    // Devuelve true si existe un usuario con ese correo, false si no.
    // ------------------------------------------------------------------------
    boolean existsByCorreoUsuario(String correoUsuario);
}



    // ============================================================================
    // UsuarioRepository
    // ----------------------------------------------------------------------------
    // Este repositorio gestiona el acceso a la tabla **usuario** en la base de datos.
    // Spring Data JPA genera automáticamente toda la implementación, por lo que
    // solo necesitas definir la interfaz y los métodos de consulta.
    //
    // ¿PARA QUÉ SIRVE ESTE REPOSITORIO?
    // - Buscar usuarios por correo durante el login.
    // - Verificar si un correo ya está registrado durante el registro.
    // - Acceder a usuarios por ID para lógica interna.
    //
    // FUNCIONES PRINCIPALES:
    // 1. findByCorreoUsuarioAndFechaEliminacionUsuarioIsNull()
    //      → Busca un usuario activo (no eliminado) por su correo.
    // 2. existsByCorreoUsuario()
    //      → Comprueba si un correo ya está registrado.
    //
    // NOTAS IMPORTANTES:
    // - La columna fechaEliminacionUsuario se usa para "soft delete". Si no es null,
    //   significa que el usuario está eliminado y no debe poder iniciar sesión.
    // - Optional<Usuario> evita NullPointerException y obliga a manejar el caso
    //   de usuario no encontrado.
    // ============================================================================