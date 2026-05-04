package org.victorino_style.entity;

import jakarta.persistence.*;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.annotations.ColumnDefault;
import org.victorino_style.entity.enums.RolUsuario;

import java.time.Instant;

@Getter
@Setter
@Entity
@Table(name = "usuario")
public class Usuario {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_usuario", nullable = false)
    private Long id;

    @Size(max = 254)
    @NotNull
    @Column(name = "correo_usuario", nullable = false, length = 254)
    private String correoUsuario;

    @Size(max = 60)
    @NotNull
    @Column(name = "contrasena_usuario", nullable = false, length = 60)
    private String contrasenaUsuario;

    // Mapeo del ENUM de MySQL a una enumeración Java type-safe.
    @NotNull
    @Enumerated(EnumType.STRING)
    @Column(name = "rol_usuario", nullable = false,
            columnDefinition = "ENUM('CLIENTE','EMPLEADO','ADMINISTRADOR')")
    private RolUsuario rolUsuario;

    @NotNull
    @ColumnDefault("CURRENT_TIMESTAMP(6)")
    @Column(name = "fecha_creacion_usuario", nullable = false)
    private Instant fechaCreacionUsuario;

    @NotNull
    @ColumnDefault("CURRENT_TIMESTAMP(6)")
    @Column(name = "fecha_modificacion_usuario", nullable = false)
    private Instant fechaModificacionUsuario;

    @Column(name = "fecha_eliminacion_usuario")
    private Instant fechaEliminacionUsuario;


}