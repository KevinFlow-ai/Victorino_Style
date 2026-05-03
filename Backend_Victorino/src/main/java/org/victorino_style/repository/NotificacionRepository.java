package org.victorino_style.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.victorino_style.entity.Notificacion;

public interface NotificacionRepository extends JpaRepository<Notificacion, Long> {
}