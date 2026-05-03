package org.victorino_style.entity;

import jakarta.persistence.*;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.annotations.ColumnDefault;
import org.hibernate.annotations.OnDelete;
import org.hibernate.annotations.OnDeleteAction;

import java.time.Instant;

@Getter
@Setter
@Entity
@Table(name = "refresh_token")
public class RefreshToken {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_refresh_token", nullable = false)
    private Long id;

    @NotNull
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @OnDelete(action = OnDeleteAction.CASCADE)
    @JoinColumn(name = "id_usuario", nullable = false)
    private Usuario idUsuario;

    @Size(max = 64)
    @NotNull
    @Column(name = "hash_refresh_token", nullable = false, length = 64)
    private String hashRefreshToken;

    @NotNull
    @ColumnDefault("CURRENT_TIMESTAMP(6)")
    @Column(name = "fecha_emision_refresh_token", nullable = false)
    private Instant fechaEmisionRefreshToken;

    @NotNull
    @Column(name = "fecha_caducidad_refresh_token", nullable = false)
    private Instant fechaCaducidadRefreshToken;

    @NotNull
    @ColumnDefault("0")
    @Column(name = "revocado_refresh_token", nullable = false)
    private Boolean revocadoRefreshToken;


}