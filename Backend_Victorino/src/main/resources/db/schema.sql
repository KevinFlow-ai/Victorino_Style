-- =====================================================================
-- VICTORINO STYLE — SCRIPT COMPLETO (SCHEMA + SEED(datos inciales)
-- MySQL 8.0.x version de mysql
-- Motor InnoDB 
-- Charset utf8mb4 Los datos que envías están codificados en UTF-8 multibyte, es la codificación recomendada porque soporta todos los caracteres Unicode, incluidos emojis.
-- =====================================================================

-- 			************************************ CONCEPTOS NUEVOS PARA ENTENDER LA BASE DE DATOS ****************************************************
-- Tipo DATETIME(6) → guarda fecha y hora con microsegundos. Ejemplo 2026-05-02 21:57:12.345678
-- DEFAULT CURRENT_TIMESTAMP(6) Cuando se crea el registro por primera vez, esta columna se llena automáticamente con la fecha y hora actual.
-- ON UPDATE CURRENT_TIMESTAMP(6) Cada vez que se hace  un UPDATE a la fila, MySQL actualiza esta columna automáticamente con la fecha y hora del momento de la modificación.

-- Índices (INDEX) Los índices sirven para acelerar búsquedas y filtros. No cambian los datos, pero hacen que las consultas sean mucho más rápidas
-- Ejemplo: INDEX idx_cita_empleado_fecha (id_empleado, fecha_cita)
-- PARA QUE SIRVE: Optimiza consultas como: 
-- SELECT * FROM cita WHERE id_empleado = 12 AND fecha_cita = '2026-05-03';

-- BIGINT → permite millones de usuarios sin problemas || UNSIGNED → solo números positivos, es decir un número grande, sin valores negativos.


-- 			************************************ CONCEPTOS NUEVOS PARA ENTENDER LA BASE DE DATOS ****************************************************






DROP DATABASE IF EXISTS victorino_style_bbdd_tfg_2dam_2025_2026_puig;   -- Descomentar para reset
CREATE DATABASE IF NOT EXISTS victorino_style_bbdd_tfg_2dam_2025_2026_puig
  DEFAULT CHARACTER SET utf8mb4 -- sporta todos los caracteres Unicode, incluidos emojis 
  DEFAULT COLLATE utf8mb4_unicode_ci; -- unicode → usa reglas Unicode para ordenar y comparar. ci → case insensitive (no distingue entre mayúsculas y minúsculas).

USE victorino_style_bbdd_tfg_2dam_2025_2026_puig;

SET NAMES utf8mb4;
SET time_zone = 'SYSTEM';
SET FOREIGN_KEY_CHECKS = 0; -- ESTO CUANDO SE TERMINE LA BBDD PONER 1 Desactiva temporalmente la comprobación de claves foráneas. Esto permite: *Borrar tablas con relaciones sin que MySQL se queje 
-- 																									      *Insertar datos sin respetar el orden de dependencias
-- 
-- ============================================================
-- TABLA: usuario
-- ============================================================
DROP TABLE IF EXISTS usuario;
CREATE TABLE usuario (
  id_usuario BIGINT UNSIGNED NOT NULL AUTO_INCREMENT, --  BIGINT → permite millones de usuarios sin problemas || UNSIGNED → solo números positivos
  correo_usuario VARCHAR(254) NOT NULL,
  contrasena_usuario CHAR(60) NOT NULL COMMENT 'BCrypt hash', -- Guarda el hash Bcrypt, no la contraseña real || Bcrypt siempre genera cadenas de 60 caracteres 
  rol_usuario ENUM('CLIENTE','EMPLEADO','ADMINISTRADOR') NOT NULL, -- Solo permite uno de esos tres valores
  fecha_creacion_usuario DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6), -- (6) → precisión de microsegundos
  fecha_modificacion_usuario DATETIME(6) NOT NULL -- Se actualiza sola cada vez que se modifica el registro Muy útil para auditoría
      DEFAULT CURRENT_TIMESTAMP(6)
      ON UPDATE CURRENT_TIMESTAMP(6),
  fecha_eliminacion_usuario DATETIME(6) NULL COMMENT 'soft-delete', -- Si tiene fecha, significa que está “eliminado” pero no borrado físicamente || Permite recuperar usuarios o mantener historial 
  PRIMARY KEY (id_usuario),
  UNIQUE KEY uk_usuario_correo (correo_usuario) -- Crea un índice único llamado uk_usuario_correo. No puede haber dos usuarios con el mismo correo. Si intentas insertar un correo repetido, MySQL dará error.
) ENGINE=InnoDB;  -- Indica que la tabla usará el motor InnoDB. Esto permite Transacciones, Llaves foráneas, Integridad referencial

-- ============================================================
-- TABLA: cliente
-- ============================================================
DROP TABLE IF EXISTS cliente;
CREATE TABLE cliente (
  id_cliente BIGINT UNSIGNED NOT NULL,
  nombre_cliente VARCHAR(100) NOT NULL,
  apellidos_cliente VARCHAR(150) NOT NULL,
  telefono_cliente VARCHAR(20) NULL,
  foto_cliente VARCHAR(255) NULL, -- para guardar la ruta
  push_activa_cliente BOOLEAN NOT NULL DEFAULT TRUE, -- Crea una columna booleana (TRUE/FALSE). DEFAULT TRUE → si no se especifica nada al insertar un cliente, se asigna TRUE automáticamente.
  -- Esto suele significar que las notificaciones push están activas por defecto.
  PRIMARY KEY (id_cliente),
  CONSTRAINT fk_cliente_usuario  -- nombre que le das a la restricción
  FOREIGN KEY (id_cliente) REFERENCES usuario(id_usuario) ON DELETE CASCADE -- Declara que id_cliente es una clave foránea. Significa que cada cliente debe existir también en la tabla usuario, en la columna id_usuario. 
  -- En otras palabras: un cliente es un usuario. ON DELETE CASCADE →  Si se elimina un usuario en la tabla usuario, automáticamente se elimina el cliente asociado en esta tabla.
) ENGINE=InnoDB;

-- ============================================================
-- TABLA: empleado
-- ============================================================
DROP TABLE IF EXISTS empleado;
CREATE TABLE empleado (
  id_empleado BIGINT UNSIGNED NOT NULL,
  nombre_empleado VARCHAR(100) NOT NULL,
  apellidos_empleado VARCHAR(150) NOT NULL,
  foto_empleado VARCHAR(255) NOT NULL, -- Esta es para guardar la ruta de la foto del empleado. NOT NULL significa que es obligatorio que cada empleado tenga una foto 
  silencio_inicio_empleado TIME NULL, -- Guarda una hora (formato HH:MM:SS).
  silencio_fin_empleado TIME NULL,
  no_molestar_empleado BOOLEAN NOT NULL DEFAULT FALSE, -- Es un valor booleano (TRUE/FALSE).
  PRIMARY KEY (id_empleado),
  CONSTRAINT fk_empleado_usuario -- Es el nombre que le das a la restricción de clave foránea.
    FOREIGN KEY (id_empleado) REFERENCES usuario(id_usuario) -- Declara que id_empleado debe existir en la tabla usuario, en la columna id_usuario. Esto significa que todo empleado es también un usuario.
    ON DELETE CASCADE -- Si se elimina un usuario en la tabla usuario, automáticamente se elimina el empleado asociado.
) ENGINE=InnoDB;

-- ============================================================
-- TABLA: administrador
-- ============================================================
DROP TABLE IF EXISTS administrador;
CREATE TABLE administrador (
  id_administrador BIGINT UNSIGNED NOT NULL, -- BIGINT UNSIGNED → un número grande, sin valores negativos.
  PRIMARY KEY (id_administrador),
  CONSTRAINT fk_admin_empleado
    FOREIGN KEY (id_administrador) REFERENCES empleado(id_empleado) -- Significa que cada administrador debe existir primero como empleado.En otras palabras: Un administrador es un empleado, 
    ON DELETE CASCADE
    -- RESUMEN No tiene datos propios (solo el ID). Su ID debe existir en la tabla empleado. Si borras un empleado, se borra su administrador. usuario → empleado → administrador

) ENGINE=InnoDB;

-- ============================================================
-- TABLA: cliente_invitado
-- ============================================================
DROP TABLE IF EXISTS cliente_invitado;
CREATE TABLE cliente_invitado (
  id_cliente_invitado BIGINT UNSIGNED NOT NULL AUTO_INCREMENT, -- BIGINT UNSIGNED → un número grande, sin valores negativos.
  nombre_cliente_invitado VARCHAR(100) NOT NULL,
  apellidos_cliente_invitado VARCHAR(150) NOT NULL,
  telefono_cliente_invitado VARCHAR(20) NULL,
  fecha_creacion_cliente_invitado DATETIME(6) NOT NULL -- guarda fecha y hora con microsegundos, y que por defecto se llena automáticamente con la fecha y hora actual cuando se inserta un registro.
      DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (id_cliente_invitado)
) ENGINE=InnoDB;

-- ============================================================
-- TABLA: servicio
-- ============================================================
DROP TABLE IF EXISTS servicio;
CREATE TABLE servicio (
  id_servicio BIGINT UNSIGNED NOT NULL AUTO_INCREMENT, --  -- BIGINT UNSIGNED → un número grande, sin valores negativos.
  nombre_servicio VARCHAR(150) NOT NULL, 
  descripcion_servicio VARCHAR(500) NULL,
  duracion_servicio SMALLINT UNSIGNED NOT NULL COMMENT 'minutos', -- Duración del servicio en minutos. SMALLINT UNSIGNED: valores entre 0 y 65535
  precio_servicio DECIMAL(10,2) NOT NULL, -- Formato: hasta 10 dígitos en total, 2 decimales. Ejemplo: 99999999.99
  foto_servicio VARCHAR(255) NOT NULL, -- Ruta o nombre de la imagen del servicio.
  fecha_creacion_servicio DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6), -- Fecha y hora de creación. Incluye microsegundos. Se asigna automáticamente al crear el registro.
  fecha_modificacion_servicio DATETIME(6) NOT NULL
      DEFAULT CURRENT_TIMESTAMP(6)
      ON UPDATE CURRENT_TIMESTAMP(6),
  fecha_eliminacion_servicio DATETIME(6) NULL COMMENT 'soft-delete',
  PRIMARY KEY (id_servicio),
  CONSTRAINT chk_servicio_duracion CHECK (duracion_servicio BETWEEN 5 AND 480), -- a duración debe estar entre 5 minutos y 8 horas.
  CONSTRAINT chk_servicio_precio CHECK (precio_servicio >= 0) -- El precio no puede ser negativo.
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

  cierre_anual_inicio DATE NULL, -- Inicio de las vacaciones
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
  descanso_inicio_horario TIME NOT NULL, -- Representa la hora en la que empieza el descanso
  descanso_duracion_horario SMALLINT UNSIGNED NOT NULL DEFAULT 30, -- Tipo SMALLINT UNSIGNED → número entero entre 0 y 65535. DEFAULT 30 → si no se especifica nada, se asignan 30 minutos.
  PRIMARY KEY (id_horario_empleado),
  UNIQUE KEY uk_horario_empleado (id_empleado),
  CONSTRAINT fk_horario_empleado
    FOREIGN KEY (id_empleado) REFERENCES empleado(id_empleado)
    ON DELETE CASCADE,
  CONSTRAINT chk_descanso_duracion
    CHECK (descanso_duracion_horario BETWEEN 10 AND 120) -- Obliga a que descanso_duracion_horario tenga un valor entre 10 y 120 minutos.Si intentas insertar o actualizar un valor fuera de ese rango, MySQL rechaza la operación.
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
-- TABLA: cita (núcleo del sistema) La tabla cita incorpora la restricción XOR entre id_cliente e id_cliente_invitado mediante 
-- una CHECK CONSTRAINT que exige que exactamente uno de los dos sea no-nulo.
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
  fecha_modificacion_cita DATETIME(6) NOT NULL -- DATETIME(6) → guarda fecha y hora con microsegundos.  Ejemplo 2026-05-02 21:57:12.345678
      DEFAULT CURRENT_TIMESTAMP(6) -- Cuando se crea el registro por primera vez, esta columna se llena automáticamente con la fecha y hora actual.
      ON UPDATE CURRENT_TIMESTAMP(6), -- Cada vez que se hace un UPDATE a la fila, MySQL actualiza esta columna automáticamente con la fecha y hora del momento de la modificación.
  PRIMARY KEY (id_cita),

  CONSTRAINT fk_cita_cliente -- Es el nombre que le das a la restricción.
    FOREIGN KEY (id_cliente) REFERENCES cliente(id_cliente) -- La columna id_cliente en la tabla cita debe existir en la tabla cliente. No puedes crear una cita para un cliente que no exista.
    ON DELETE RESTRICT, --  Es una restriccion que Impide que se borre un cliente si tiene citas asociadas. ya que Conecta una cita con un cliente.

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
  
  -- QUE SIGNIFICA ESTO: Esa restricción CHECK implementa una regla lógica muy importante: 
  -- solo uno de los dos campos puede tener valor, pero nunca ambos al mismo tiempo. Es 
  -- una especie de “XOR” (exclusivo) aplicado a claves foráneas.
  
  -- Interpretación:
  -- 	Una cita debe pertenecer a un cliente registrado O a un cliente invitado.
  -- 	Pero noo puede pertenecer a ambos al mismo tiempo.
  -- 	Y tampoco puede quedar sin ninguno de los dos
  
 --  ¿Por qué se usa esto?
-- Porque en tu modelo tienes dos tipos de clientes:
-- Cliente normal → id_cliente
-- Cliente invitado → id_cliente_invitado
-- Y una cita debe estar asociada a uno u otro, pero nunca a los dos.


  
  
  ),

  CONSTRAINT chk_cita_horas CHECK (hora_fin_cita > hora_inicio_cita), -- Valida que la hora de fin de la cita sea mayor que la hora de inicio. Esto evita Citas con duración cero. Citas que terminan antes de empezar
  
  -- Los índices sirven para acelerar búsquedas y filtros. No cambian los datos, pero hacen que las consultas sean mucho más rápidas.
  INDEX idx_cita_empleado_fecha (id_empleado, fecha_cita),  -- Optimiza consultas como: SELECT * FROM cita WHERE id_empleado = 12 AND fecha_cita = '2026-05-03'; Ideal para agendas de empleados.
  INDEX idx_cita_cliente_fecha (id_cliente, fecha_cita), -- para ver el historial de citas de un cliente.
  INDEX idx_cita_estado_fecha (estado_cita, fecha_cita) -- Optimiza consultas como: SELECT * FROM cita WHERE estado_cita = 'pendiente' ORDER BY fecha_cita; útil para el admin donde se listan citas por estado: confirmadas, canceladas...
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
      'NUEVA_CITA_EMPLEADO','CONTRASENA_ACTUALIZADA',
      'AVISO_GENERAL'
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
      

--  Crea un índice que combina dos columnas: id_destinatario_notificacion y fecha_creacion_notificacion
-- Esto sirve para Buscar todas las notificaciones de un usuario rápidamente. Ordenarlas por fecha rapido Filtrar por rangos de fechas de forma eficiente.
  INDEX idx_notificacion_dest_fecha
    (id_destinatario_notificacion, fecha_creacion_notificacion)
) ENGINE=InnoDB;




-- ============================================================
-- TABLA: auditoria
-- ============================================================
DROP TABLE IF EXISTS auditoria;
-- -- esta tabla permiten registrar, monitorear y analizar lo que ocurre dentro de la base de datos: quién hizo qué, cuándo y cómo.
-- Saber qué usuario hizo una acción. Saber qué datos se modificaron. Saber cuándo ocurrió. Saber desde dónde se hizo (IP, aplicación, etc., según el sistema).
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

-- Crea un índice que combina dos columnas: fecha_auditoria entidad_auditoria
  INDEX idx_auditoria_fecha_entidad (fecha_auditoria, entidad_auditoria)
) ENGINE=InnoDB;

-- ============================================================
-- TABLA: refresh_token
-- ============================================================
DROP TABLE IF EXISTS refresh_token;
CREATE TABLE refresh_token (
  id_refresh_token BIGINT UNSIGNED NOT NULL AUTO_INCREMENT, -- Identificador único del token. Se genera automáticamente.
  id_usuario BIGINT UNSIGNED NOT NULL, -- Relaciona el token con un usuario específico.
  hash_refresh_token CHAR(64) NOT NULL COMMENT 'SHA-256 hex', -- Guarda el hash SHA‑256 del refresh token. No se guarda el token en texto plano
  fecha_emision_refresh_token DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6), -- Fecha y hora exacta en que se emitió el token. Se asigna automáticamente al crearse.
  fecha_caducidad_refresh_token DATETIME(6) NOT NULL,
  revocado_refresh_token BOOLEAN NOT NULL DEFAULT FALSE,
  PRIMARY KEY (id_refresh_token),

  UNIQUE KEY uk_refresh_token_hash (hash_refresh_token), -- Garantiza que no existan dos tokens con el mismo hash. para evitar duplicados

  CONSTRAINT fk_refresh_usuario
    FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario) -- Cada token pertenece a un usuario existente.
    ON DELETE CASCADE, -- Si se elimina el usuario, todos sus tokens se eliminan automáticamente.

-- Este indice permite Buscar tokens activos de un usuario. Verificar si un usuario tiene un token válido.
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

