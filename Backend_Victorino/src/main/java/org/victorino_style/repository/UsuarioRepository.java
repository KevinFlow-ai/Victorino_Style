package org.victorino_style.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.victorino_style.entity.Usuario;

public interface UsuarioRepository extends JpaRepository<Usuario, Long> {
}