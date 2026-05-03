package org.victorino_style.entity;

import jakarta.persistence.*;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.annotations.ColumnDefault;

import java.time.Instant;

@Getter
@Setter
@Entity
@Table(name = "cliente_invitado")
public class ClienteInvitado {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_cliente_invitado", nullable = false)
    private Long id;

    @Size(max = 100)
    @NotNull
    @Column(name = "nombre_cliente_invitado", nullable = false, length = 100)
    private String nombreClienteInvitado;

    @Size(max = 150)
    @NotNull
    @Column(name = "apellidos_cliente_invitado", nullable = false, length = 150)
    private String apellidosClienteInvitado;

    @Size(max = 20)
    @Column(name = "telefono_cliente_invitado", length = 20)
    private String telefonoClienteInvitado;

    @NotNull
    @ColumnDefault("CURRENT_TIMESTAMP(6)")
    @Column(name = "fecha_creacion_cliente_invitado", nullable = false)
    private Instant fechaCreacionClienteInvitado;


}