package org.victorino_style.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.victorino_style.entity.Cliente;

public interface ClienteRepository extends JpaRepository<Cliente, Long> {
}