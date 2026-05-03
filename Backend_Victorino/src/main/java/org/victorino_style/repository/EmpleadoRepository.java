package org.victorino_style.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.victorino_style.entity.Empleado;

public interface EmpleadoRepository extends JpaRepository<Empleado, Long> {
}