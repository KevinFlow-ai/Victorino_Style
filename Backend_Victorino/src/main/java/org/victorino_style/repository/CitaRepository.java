package org.victorino_style.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.victorino_style.entity.Cita;

public interface CitaRepository extends JpaRepository<Cita, Long> {
}