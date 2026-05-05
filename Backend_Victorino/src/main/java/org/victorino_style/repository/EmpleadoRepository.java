package org.victorino_style.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.victorino_style.entity.Empleado;

import java.util.List;
import java.util.Optional;

// Repositorio de la entidad Empleado. Spring Data genera la implementación.
// Empleado hereda de Usuario (JOINED): id_empleado == id_usuario.
public interface EmpleadoRepository extends JpaRepository<Empleado, Long> {

    // ------------------------------------------------------------------------
    // Devuelve un empleado por id solo si su usuario está activo (sin soft-delete).
    // Lo usa el panel de admin para evitar editar a empleados ya dados de baja.
    // ------------------------------------------------------------------------
    @Query("""
           SELECT e FROM Empleado e
           WHERE e.id = :id AND e.usuario.fechaEliminacionUsuario IS NULL
           """)
    Optional<Empleado> findActivoById(Long id);





    // ------------------------------------------------------------------------
    // Devuelve todos los empleados activos, ordenados por nombre.
    // ------------------------------------------------------------------------
    @Query("""
           SELECT e FROM Empleado e
           WHERE e.usuario.fechaEliminacionUsuario IS NULL
           ORDER BY e.nombreEmpleado ASC, e.apellidosEmpleado ASC
           """)
    List<Empleado> findAllActivos();
    // ------------------------------------------------------------------------
    // findAllActivos()
    // ------------------------------------------------------------------------
    // Devuelve TODOS los empleados activos (sin soft-delete),
    // ordenados por nombre y apellidos.
    //
    // ¿Para qué sirve?
    //   → Para mostrar en el panel admin solo empleados vigentes.
    //   → Para listarlos en combos, asignaciones, etc.




    // ------------------------------------------------------------------------
    // Devuelve TODOS los empleados (activos + inactivos), ordenados por nombre.
    // El panel admin lo usa cuando marca el flag `?incluirInactivos=true`.
    // ------------------------------------------------------------------------
    @Query("""
           SELECT e FROM Empleado e
           ORDER BY e.usuario.fechaEliminacionUsuario ASC NULLS FIRST,
                    e.nombreEmpleado ASC, e.apellidosEmpleado ASC
           """)
    List<Empleado> findAllOrderActivosPrimero();
}



    // ------------------------------------------------------------------------
    // findActivoById(Long id)
    // ------------------------------------------------------------------------
    // Este métodoo devuelve un empleado SOLO si está "activo".
    //
    // ¿Qué significa activo?
    //   → Que su usuario asociado NO tiene fechaEliminacionUsuario.
    //     (Es decir, no ha sido dado de baja mediante soft-delete).
    //
    // ¿Por qué se hace esto?
    //   → El panel de administración no debe permitir editar empleados
    //     que ya están desactivados. Así se evita modificar registros
    //     que deberían considerarse "históricos".
    //
    // La consulta:
    //   SELECT e FROM Empleado e
    //   WHERE e.id = :id AND e.usuario.fechaEliminacionUsuario IS NULL
    //
    // Devuelve Optional<Empleado> porque puede existir o no.
    // ------------------------------------------------------------------------