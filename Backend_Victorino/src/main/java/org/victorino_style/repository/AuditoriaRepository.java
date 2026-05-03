package org.victorino_style.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.victorino_style.entity.Auditoria;

public interface AuditoriaRepository extends JpaRepository<Auditoria, Long> {
}