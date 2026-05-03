package org.victorino_style.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.victorino_style.entity.Administrador;

public interface AdministradorRepository extends JpaRepository<Administrador, Long> {
}