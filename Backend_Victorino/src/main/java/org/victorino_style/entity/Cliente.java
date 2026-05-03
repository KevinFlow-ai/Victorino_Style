package org.victorino_style.entity;

import jakarta.persistence.*;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.annotations.ColumnDefault;
import org.hibernate.annotations.OnDelete;
import org.hibernate.annotations.OnDeleteAction;

@Getter
@Setter
@Entity
@Table(name = "cliente")
public class Cliente {
    @Id
    @Column(name = "id_cliente", nullable = false)
    private Long id;

    @MapsId
    @OneToOne(fetch = FetchType.LAZY, optional = false)
    @OnDelete(action = OnDeleteAction.CASCADE)
    @JoinColumn(name = "id_cliente", nullable = false)
    private Usuario usuario;

    @Size(max = 100)
    @NotNull
    @Column(name = "nombre_cliente", nullable = false, length = 100)
    private String nombreCliente;

    @Size(max = 150)
    @NotNull
    @Column(name = "apellidos_cliente", nullable = false, length = 150)
    private String apellidosCliente;

    @Size(max = 20)
    @Column(name = "telefono_cliente", length = 20)
    private String telefonoCliente;

    @Size(max = 255)
    @Column(name = "foto_cliente")
    private String fotoCliente;

    @NotNull
    @ColumnDefault("1")
    @Column(name = "push_activa_cliente", nullable = false)
    private Boolean pushActivaCliente;


}