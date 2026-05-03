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
@Table(name = "auditoria")
public class Auditoria {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_auditoria", nullable = false)
    private Long id;

    @NotNull
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "id_usuario_ejecutor_auditoria", nullable = false)
    private Usuario idUsuarioEjecutorAuditoria;

    @Size(max = 90)
    @NotNull
    @Column(name = "accion_auditoria", nullable = false, length = 90)
    private String accionAuditoria;

    @Size(max = 80)
    @NotNull
    @Column(name = "entidad_auditoria", nullable = false, length = 80)
    private String entidadAuditoria;

    @Column(name = "id_entidad_auditoria")
    private Long idEntidadAuditoria;

    @Size(max = 1000)
    @Column(name = "detalle_auditoria", length = 1000)
    private String detalleAuditoria;

    @NotNull
    @ColumnDefault("CURRENT_TIMESTAMP(6)")
    @Column(name = "fecha_auditoria", nullable = false)
    private Instant fechaAuditoria;


}