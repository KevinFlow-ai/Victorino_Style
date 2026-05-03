package org.victorino_style.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.victorino_style.entity.DeviceTokenFcm;

public interface DeviceTokenFcmRepository extends JpaRepository<DeviceTokenFcm, Long> {
}