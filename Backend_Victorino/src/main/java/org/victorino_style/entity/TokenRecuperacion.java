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
@Table(name = "token_recuperacion")
public class TokenRecuperacion {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_token_recuperacion", nullable = false)
    private Long id;

    @NotNull
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @OnDelete(action = OnDeleteAction.CASCADE)
    @JoinColumn(name = "id_usuario", nullable = false)
    private Usuario idUsuario;

    @Size(max = 6)
    @NotNull
    @Column(name = "codigo_token_recuperacion", nullable = false, length = 6)
    private String codigoTokenRecuperacion;

    @NotNull
    @ColumnDefault("CURRENT_TIMESTAMP(6)")
    @Column(name = "fecha_emision_token_recuperacion", nullable = false)
    private Instant fechaEmisionTokenRecuperacion;

    @NotNull
    @Column(name = "fecha_caducidad_token_recuperacion", nullable = false)
    private Instant fechaCaducidadTokenRecuperacion;

    @NotNull
    @ColumnDefault("0")
    @Column(name = "usado_token_recuperacion", nullable = false)
    private Boolean usadoTokenRecuperacion;


}