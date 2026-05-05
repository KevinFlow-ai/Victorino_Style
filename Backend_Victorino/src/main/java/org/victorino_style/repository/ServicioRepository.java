package org.victorino_style.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.victorino_style.entity.Servicio;

import java.util.List;
import java.util.Optional;

// Repositorio de la entidad Servicio. Spring Data genera la implementación.
public interface ServicioRepository extends JpaRepository<Servicio, Long> {

    // Devuelve un servicio por id solo si NO ha sido dado de baja lógica.
    Optional<Servicio> findByIdAndFechaEliminacionServicioIsNull(Long id);

    // Lista todos los servicios activos, ordenados por nombre.
    List<Servicio> findByFechaEliminacionServicioIsNullOrderByNombreServicioAsc();

    // Lista todos los servicios (activos + inactivos), ordenados por nombre.
    List<Servicio> findAllByOrderByNombreServicioAsc();

    // Comprueba si ya existe un servicio activo con ese nombre exacto.
    boolean existsByNombreServicioIgnoreCaseAndFechaEliminacionServicioIsNull(String nombreServicio);
}
