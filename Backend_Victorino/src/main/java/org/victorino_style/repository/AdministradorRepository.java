package org.victorino_style.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.victorino_style.entity.Administrador;

// Repositorio de Administradores. Hereda de Empleado (JOINED): id_administrador == id_empleado.
public interface AdministradorRepository extends JpaRepository<Administrador, Long> {

    // Indica si un empleado dado es también administrador (existe fila en `administrador`).
    // Lo usa EmpleadoMapper para activar el flag esAdministrador en la respuesta.
    boolean existsById(Long idEmpleado);
}
