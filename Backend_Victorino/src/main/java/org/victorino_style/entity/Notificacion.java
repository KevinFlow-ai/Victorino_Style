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
@Table(name = "notificacion")
public class Notificacion {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_notificacion", nullable = false)
    private Long id;

    @NotNull
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @OnDelete(action = OnDeleteAction.CASCADE)
    @JoinColumn(name = "id_destinatario_notificacion", nullable = false)
    private Usuario idDestinatarioNotificacion;

    @ManyToOne(fetch = FetchType.LAZY)
    @OnDelete(action = OnDeleteAction.SET_NULL)
    @JoinColumn(name = "id_cita_relacionada_notificacion")
    private Cita idCitaRelacionadaNotificacion;

    @Size(max = 250)
    @NotNull
    @Column(name = "titulo_notificacion", nullable = false, length = 250)
    private String tituloNotificacion;

    @Size(max = 500)
    @NotNull
    @Column(name = "cuerpo_notificacion", nullable = false, length = 500)
    private String cuerpoNotificacion;

    @NotNull
    @Lob
    @Column(name = "tipo_notificacion", nullable = false)
    private String tipoNotificacion;

    @NotNull
    @ColumnDefault("0")
    @Column(name = "enviada_push_notificacion", nullable = false)
    private Boolean enviadaPushNotificacion;

    @NotNull
    @ColumnDefault("CURRENT_TIMESTAMP(6)")
    @Column(name = "fecha_creacion_notificacion", nullable = false)
    private Instant fechaCreacionNotificacion;

    @Column(name = "fecha_lectura_notificacion")
    private Instant fechaLecturaNotificacion;


}