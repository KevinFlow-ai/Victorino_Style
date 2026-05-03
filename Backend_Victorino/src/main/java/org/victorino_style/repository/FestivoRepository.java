package org.victorino_style.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.victorino_style.entity.Festivo;

public interface FestivoRepository extends JpaRepository<Festivo, Long> {
}