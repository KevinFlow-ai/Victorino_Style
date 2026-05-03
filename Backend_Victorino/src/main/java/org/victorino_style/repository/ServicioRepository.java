package org.victorino_style.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.victorino_style.entity.Servicio;

public interface ServicioRepository extends JpaRepository<Servicio, Long> {
}