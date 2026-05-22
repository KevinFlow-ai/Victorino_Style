-- =====================================================================
-- VICTORINO STYLE - SCHEMA PARA RAILWAY (15 TABLAS)
-- MySQL 8.0.x  ·  Motor InnoDB  ·  Charset utf8mb4
-- =====================================================================
--
-- Este archivo es la version del schema preparada para cargarse contra la
-- base de datos que Railway provisiona automaticamente con el plugin MySQL
-- (normalmente llamada "railway"). Se diferencia de schema.sql en que NO
-- crea la base de datos ni hace USE, porque el usuario por defecto de
-- Railway no tiene permiso para crear bases ni cambiar de schema.
--
-- Para cargarlo en Railway:
--   1) railway login
--   2) railway link  (en la carpeta Backend_Victorino/src/main/resources/db)
--   3) railway connect MySQL
--      mysql> source schema_railway.sql
--      mysql> source seed_railway.sql
--
-- =====================================================================

SET NAMES utf8mb4;
SET time_zone = 'SYSTEM';
SET FOREIGN_KEY_CHECKS = 0;

-- ============================================================
-- TABLA: usuario
-- ============================================================
DROP TABLE IF EXISTS usuario;
CREATE TABLE usuario (
  id_usuario BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  correo_usuario VARCHAR(254) NOT NULL,
  contrasena_usuario CHAR(60) NOT NULL COMMENT 'BCrypt hash',
  rol_usuario ENUM('CLIENTE','EMPLEADO','ADMINISTRADOR') NOT NULL,
  fecha_creacion_usuario DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  fecha_modificacion_usuario DATETIME(6) NOT NULL
      DEFAULT CURRENT_TIMESTAMP(6)
      ON UPDATE CURRENT_TIMESTAMP(6),
  fecha_eliminacion_usuario DATETIME(6) NULL COMMENT 'soft-delete',
  PRIMARY KEY (id_usuario),
  UNIQUE KEY uk_usuario_correo (correo_usuario)
) ENGINE=InnoDB;

-- ============================================================
-- TABLA: cliente
-- ============================================================
DROP TABLE IF EXISTS cliente;
CREATE TABLE cliente (
  id_cliente BIGINT UNSIGNED NOT NULL,
  nombre_cliente VARCHAR(100) NOT NULL,
  apellidos_cliente VARCHAR(150) NOT NULL,
  telefono_cliente VARCHAR(20) NULL,
  foto_cliente VARCHAR(255) NULL,
  push_activa_cliente BOOLEAN NOT NULL DEFAULT TRUE,
  PRIMARY KEY (id_cliente),
  CONSTRAINT fk_cliente_usuario
    FOREIGN KEY (id_cliente) REFERENCES usuario(id_usuario) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ============================================================
-- TABLA: empleado
-- ============================================================
DROP TABLE IF EXISTS empleado;
CREATE TABLE empleado (
  id_empleado BIGINT UNSIGNED NOT NULL,
  nombre_empleado VARCHAR(100) NOT NULL,
  apellidos_empleado VARCHAR(150) NOT NULL,
  foto_empleado VARCHAR(255) NOT NULL,
  silencio_inicio_empleado TIME NULL,
  silencio_fin_empleado TIME NULL,
  no_molestar_empleado BOOLEAN NOT NULL DEFAULT FALSE,
  PRIMARY KEY (id_empleado),
  CONSTRAINT fk_empleado_usuario
    FOREIGN KEY (id_empleado) REFERENCES usuario(id_usuario)
    ON DELETE CASCADE
) ENGINE=InnoDB;

-- ============================================================
-- TABLA: administrador
-- ============================================================
DROP TABLE IF EXISTS administrador;
CREATE TABLE administrador (
  id_administrador BIGINT UNSIGNED NOT NULL,
  PRIMARY KEY (id_administrador),
  CONSTRAINT fk_admin_empleado
    FOREIGN KEY (id_administrador) REFERENCES empleado(id_empleado)
    ON DELETE CASCADE
) ENGINE=InnoDB;

-- ============================================================
-- TABLA: cliente_invitado
-- ============================================================
DROP TABLE IF EXISTS cliente_invitado;
CREATE TABLE cliente_invitado (
  id_cliente_invitado BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  nombre_cliente_invitado VARCHAR(100) NOT NULL,
  apellidos_cliente_invitado VARCHAR(150) NOT NULL,
  telefono_cliente_invitado VARCHAR(20) NULL,
  fecha_creacion_cliente_invitado DATETIME(6) NOT NULL
      DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (id_cliente_invitado)
) ENGINE=InnoDB;

-- ============================================================
-- TABLA: servicio
-- ============================================================
DROP TABLE IF EXISTS servicio;
CREATE TABLE servicio (
  id_servicio BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  nombre_servicio VARCHAR(150) NOT NULL,
  descripcion_servicio VARCHAR(500) NULL,
  duracion_servicio SMALLINT UNSIGNED NOT NULL COMMENT 'minutos',
  precio_servicio DECIMAL(10,2) NOT NULL,
  foto_servicio VARCHAR(255) NOT NULL,
  fecha_creacion_servicio DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  fecha_modificacion_servicio DATETIME(6) NOT NULL
      DEFAULT CURRENT_TIMESTAMP(6)
      ON UPDATE CURRENT_TIMESTAMP(6),
  fecha_eliminacion_servicio DATETIME(6) NULL COMMENT 'soft-delete',
  PRIMARY KEY (id_servicio),
  CONSTRAINT chk_servicio_duracion CHECK (duracion_servicio BETWEEN 5 AND 480),
  CONSTRAINT chk_servicio_precio CHECK (precio_servicio >= 0)
) ENGINE=InnoDB;

-- ============================================================
-- TABLA: peluqueria
-- ============================================================
DROP TABLE IF EXISTS peluqueria;
CREATE TABLE peluqueria (
  id_peluqueria BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  nombre_peluqueria VARCHAR(180) NOT NULL,

  apertura_lunes TIME NULL, cierre_lunes TIME NULL,
  apertura_martes TIME NULL, cierre_martes TIME NULL,
  apertura_miercoles TIME NULL, cierre_miercoles TIME NULL,
  apertura_jueves TIME NULL, cierre_jueves TIME NULL,
  apertura_viernes TIME NULL, cierre_viernes TIME NULL,
  apertura_sabado TIME NULL, cierre_sabado TIME NULL,
  apertura_domingo TIME NULL, cierre_domingo TIME NULL,

  cierre_anual_inicio DATE NULL,
  cierre_anual_fin DATE NULL,

  PRIMARY KEY (id_peluqueria)
) ENGINE=InnoDB;

-- ============================================================
-- TABLA: horario_empleado
-- ============================================================
DROP TABLE IF EXISTS horario_empleado;
CREATE TABLE horario_empleado (
  id_horario_empleado BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  id_empleado BIGINT UNSIGNED NOT NULL,
  descanso_inicio_horario TIME NOT NULL,
  descanso_duracion_horario SMALLINT UNSIGNED NOT NULL DEFAULT 30,
  PRIMARY KEY (id_horario_empleado),
  UNIQUE KEY uk_horario_empleado (id_empleado),
  CONSTRAINT fk_horario_empleado
    FOREIGN KEY (id_empleado) REFERENCES empleado(id_empleado)
    ON DELETE CASCADE,
  CONSTRAINT chk_descanso_duracion
    CHECK (descanso_duracion_horario BETWEEN 10 AND 120)
) ENGINE=InnoDB;

-- ============================================================
-- TABLA: festivo
-- ============================================================
DROP TABLE IF EXISTS festivo;
CREATE TABLE festivo (
  id_festivo BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  id_peluqueria BIGINT UNSIGNED NOT NULL,
  fecha_festivo DATE NOT NULL,
  descripcion_festivo VARCHAR(150) NOT NULL,
  tipo_festivo ENUM('NACIONAL','AUTONOMICO','LOCAL','VACACIONES','MANTENIMIENTO') NOT NULL,
  PRIMARY KEY (id_festivo),
  UNIQUE KEY uk_festivo_fecha (fecha_festivo),
  CONSTRAINT fk_festivo_peluqueria
    FOREIGN KEY (id_peluqueria) REFERENCES peluqueria(id_peluqueria)
    ON DELETE CASCADE
) ENGINE=InnoDB;

-- ============================================================
-- TABLA: cita
-- ============================================================
DROP TABLE IF EXISTS cita;
CREATE TABLE cita (
  id_cita BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  id_cliente BIGINT UNSIGNED NULL,
  id_cliente_invitado BIGINT UNSIGNED NULL,
  id_empleado BIGINT UNSIGNED NOT NULL,
  id_servicio BIGINT UNSIGNED NOT NULL,
  fecha_cita DATE NOT NULL,
  hora_inicio_cita TIME NOT NULL,
  hora_fin_cita TIME NOT NULL,
  estado_cita ENUM('CONFIRMADA','EN_PROCESO','COMPLETADA',
                   'CANCELADA_CLIENTE','CANCELADA_PELUQUERIA',
                   'NO_PRESENTADO') NOT NULL DEFAULT 'CONFIRMADA',
  nota_cita VARCHAR(350) NULL,
  fecha_creacion_cita DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  fecha_modificacion_cita DATETIME(6) NOT NULL
      DEFAULT CURRENT_TIMESTAMP(6)
      ON UPDATE CURRENT_TIMESTAMP(6),
  version_cita BIGINT UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (id_cita),

  CONSTRAINT fk_cita_cliente
    FOREIGN KEY (id_cliente) REFERENCES cliente(id_cliente)
    ON DELETE RESTRICT,

  CONSTRAINT fk_cita_invitado
    FOREIGN KEY (id_cliente_invitado)
      REFERENCES cliente_invitado(id_cliente_invitado)
    ON DELETE RESTRICT,

  CONSTRAINT fk_cita_empleado
    FOREIGN KEY (id_empleado) REFERENCES empleado(id_empleado)
    ON DELETE RESTRICT,

  CONSTRAINT fk_cita_servicio
    FOREIGN KEY (id_servicio) REFERENCES servicio(id_servicio)
    ON DELETE RESTRICT,

  CONSTRAINT chk_cita_cliente_xor CHECK (
    (id_cliente IS NOT NULL AND id_cliente_invitado IS NULL) OR
    (id_cliente IS NULL AND id_cliente_invitado IS NOT NULL)
  ),

  CONSTRAINT chk_cita_horas CHECK (hora_fin_cita > hora_inicio_cita),

  INDEX idx_cita_empleado_fecha (id_empleado, fecha_cita),
  INDEX idx_cita_cliente_fecha (id_cliente, fecha_cita),
  INDEX idx_cita_estado_fecha (estado_cita, fecha_cita)
) ENGINE=InnoDB;

-- ============================================================
-- TABLA: notificacion
-- ============================================================
DROP TABLE IF EXISTS notificacion;
CREATE TABLE notificacion (
  id_notificacion BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  id_destinatario_notificacion BIGINT UNSIGNED NOT NULL,
  id_cita_relacionada_notificacion BIGINT UNSIGNED NULL,
  titulo_notificacion VARCHAR(250) NOT NULL,
  cuerpo_notificacion VARCHAR(500) NOT NULL,
  tipo_notificacion ENUM(
      'CONFIRMACION_RESERVA','RECORDATORIO_24H',
      'CANCELACION_CLIENTE','CANCELACION_PELUQUERIA',
      'NUEVA_CITA_EMPLEADO','MODIFICACION_CITA',
      'CONTRASENA_ACTUALIZADA','AVISO_GENERAL'
  ) NOT NULL,
  enviada_push_notificacion BOOLEAN NOT NULL DEFAULT FALSE,
  fecha_creacion_notificacion DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  fecha_lectura_notificacion DATETIME(6) NULL,
  PRIMARY KEY (id_notificacion),

  CONSTRAINT fk_notificacion_usuario
    FOREIGN KEY (id_destinatario_notificacion)
      REFERENCES usuario(id_usuario)
      ON DELETE CASCADE,

  CONSTRAINT fk_notificacion_cita
    FOREIGN KEY (id_cita_relacionada_notificacion)
      REFERENCES cita(id_cita)
      ON DELETE SET NULL,

  INDEX idx_notificacion_dest_fecha
    (id_destinatario_notificacion, fecha_creacion_notificacion)
) ENGINE=InnoDB;

-- ============================================================
-- TABLA: auditoria
-- ============================================================
DROP TABLE IF EXISTS auditoria;
CREATE TABLE auditoria (
  id_auditoria BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  id_usuario_ejecutor_auditoria BIGINT UNSIGNED NOT NULL,
  accion_auditoria VARCHAR(90) NOT NULL,
  entidad_auditoria VARCHAR(80) NOT NULL,
  id_entidad_auditoria BIGINT UNSIGNED NULL,
  detalle_auditoria VARCHAR(1000) NULL,
  fecha_auditoria DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (id_auditoria),

  CONSTRAINT fk_auditoria_usuario
    FOREIGN KEY (id_usuario_ejecutor_auditoria)
      REFERENCES usuario(id_usuario)
      ON DELETE RESTRICT,

  INDEX idx_auditoria_fecha_entidad (fecha_auditoria, entidad_auditoria)
) ENGINE=InnoDB;

-- ============================================================
-- TABLA: refresh_token
-- ============================================================
DROP TABLE IF EXISTS refresh_token;
CREATE TABLE refresh_token (
  id_refresh_token BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  id_usuario BIGINT UNSIGNED NOT NULL,
  hash_refresh_token CHAR(64) NOT NULL COMMENT 'SHA-256 hex',
  fecha_emision_refresh_token DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  fecha_caducidad_refresh_token DATETIME(6) NOT NULL,
  revocado_refresh_token BOOLEAN NOT NULL DEFAULT FALSE,
  PRIMARY KEY (id_refresh_token),

  UNIQUE KEY uk_refresh_token_hash (hash_refresh_token),

  CONSTRAINT fk_refresh_usuario
    FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario)
    ON DELETE CASCADE,

  INDEX idx_refresh_usuario_activa (id_usuario, revocado_refresh_token)
) ENGINE=InnoDB;

-- ============================================================
-- TABLA: token_recuperacion
-- ============================================================
DROP TABLE IF EXISTS token_recuperacion;
CREATE TABLE token_recuperacion (
  id_token_recuperacion BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  id_usuario BIGINT UNSIGNED NOT NULL,
  codigo_token_recuperacion CHAR(6) NOT NULL,
  fecha_emision_token_recuperacion DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  fecha_caducidad_token_recuperacion DATETIME(6) NOT NULL,
  usado_token_recuperacion BOOLEAN NOT NULL DEFAULT FALSE,
  PRIMARY KEY (id_token_recuperacion),

  CONSTRAINT fk_token_rec_usuario
    FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario)
    ON DELETE CASCADE,

  INDEX idx_token_rec_usuario (id_usuario, usado_token_recuperacion)
) ENGINE=InnoDB;

-- ============================================================
-- TABLA: device_token_fcm
-- ============================================================
DROP TABLE IF EXISTS device_token_fcm;
CREATE TABLE device_token_fcm (
  id_device_token_fcm BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  id_usuario BIGINT UNSIGNED NOT NULL,
  token_fcm VARCHAR(300) NOT NULL,
  plataforma_fcm ENUM('ANDROID','IOS','WEB') NOT NULL,
  fecha_alta_fcm DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (id_device_token_fcm),

  UNIQUE KEY uk_fcm_token (token_fcm),

  CONSTRAINT fk_fcm_usuario
    FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario)
    ON DELETE CASCADE
) ENGINE=InnoDB;

SET FOREIGN_KEY_CHECKS = 1;
