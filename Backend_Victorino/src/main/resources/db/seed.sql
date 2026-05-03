-- ======================================================================================
-- =========================== SEED DATA/DATOS INCICIALES ===============================
-- ======================================================================================

USE victorino_style_bbdd_tfg_2dam_2025_2026_puig;

-- Hash BCrypt de la contraseña 'Admin1234!'
SET @pwd := '$2a$10$eK3VjRyMvrq8Q3J0K8e4d.q5n6gF2w9YcXfE3zU1p8KxE6w0V.aGy';

-- =====================================================================
-- 1. Peluquería (singleton)
-- =====================================================================
INSERT INTO peluqueria (
  id_peluqueria, nombre_peluqueria,
  apertura_lunes, cierre_lunes,
  apertura_martes, cierre_martes,
  apertura_miercoles, cierre_miercoles,
  apertura_jueves, cierre_jueves,
  apertura_viernes, cierre_viernes,
  apertura_sabado, cierre_sabado,
  apertura_domingo, cierre_domingo,
  cierre_anual_inicio, cierre_anual_fin
) VALUES (
  1, 'Victorino Style',
  '10:00','18:00',  -- Lunes
  '10:00','18:00',  -- Martes
  '10:00','18:00',  -- Miércoles
  '10:00','18:00',  -- Jueves
  '10:00','18:00',  -- Viernes
  '10:00','18:00',  -- Sábado
  NULL, NULL,       -- Domingo cerrado
  '2026-08-01','2026-08-31' -- Vaciones en agosto para todos los empleados
);


-- =====================================================================
-- 2. Usuarios (jerarquía JOINED) 1 admin y dos empleados
-- =====================================================================

-- 2.1 Administrador
INSERT INTO usuario (id_usuario, correo_usuario, contrasena_usuario, rol_usuario)
VALUES (1, 'victorino@admin.com', @pwd, 'ADMINISTRADOR');

-- 2.2 Empleado Leonardo
INSERT INTO empleado (id_empleado, nombre_empleado, apellidos_empleado, foto_empleado)
VALUES (1, 'Leonardo', 'García López', '/uploads/empleados/barbero_1.png');

INSERT INTO administrador (id_administrador) VALUES (1);
INSERT INTO horario_empleado (id_empleado, descanso_inicio_horario, descanso_duracion_horario)
VALUES (1, '11:30', 30);

-- 2.3 Empleado Vito Corleone
INSERT INTO usuario (id_usuario, correo_usuario, contrasena_usuario, rol_usuario)
VALUES (2, 'Corleone@victorinostyle.com', @pwd, 'EMPLEADO');
INSERT INTO empleado (id_empleado, nombre_empleado, apellidos_empleado, foto_empleado)
VALUES (2, 'Vito', 'Corleone', '/uploads/empleados/barbero_1.png');
INSERT INTO horario_empleado (id_empleado, descanso_inicio_horario, descanso_duracion_horario)
VALUES (2, '14:00', 30);



-- =====================================================================
-- 3. Catálogo de servicios
-- =====================================================================
INSERT INTO servicio (id_servicio, nombre_servicio, descripcion_servicio,
                      duracion_servicio, precio_servicio, foto_servicio) VALUES
(1, 'Corte clásico',      'Corte clásico con laterales pulidos y parte superior texturizada para un estilo fresco y actual',       30, 15.00, '/uploads/servicios/servicio_2_corte_clasico.png'),
(2, 'Corte + barba',      'Corte y perfilado completo de barba.',        45, 20.00, '/uploads/servicios/servicio_1_barba.png');

-- =====================================================================
-- 4. Festivos 2026 (Comunidad de Madrid) + cierre vacacional
-- =====================================================================
INSERT INTO festivo (id_peluqueria, fecha_festivo, descripcion_festivo, tipo_festivo) VALUES
(1, '2026-01-01', 'Año Nuevo',                     'NACIONAL'),
(1, '2026-01-06', 'Epifanía del Señor',            'NACIONAL'),
(1, '2026-04-02', 'Jueves Santo',                  'AUTONOMICO'),
(1, '2026-04-03', 'Viernes Santo',                 'NACIONAL'),
(1, '2026-05-01', 'Día del trabajador',            'NACIONAL'),
(1, '2026-05-02', 'Día de la Comunidad de Madrid', 'AUTONOMICO'),
(1, '2026-05-15', 'San Isidro Labrador',           'LOCAL'),
(1, '2026-07-25', 'Santiago Apóstol',              'AUTONOMICO'),
(1, '2026-08-15', 'Asunción de la Virgen',         'NACIONAL'),
(1, '2026-10-12', 'Fiesta Nacional de España',     'NACIONAL'),
(1, '2026-11-02', 'Todos los Santos', 'NACIONAL'),
(1, '2026-11-09', 'Ntra. Sra. de la Almudena',     'LOCAL'),
(1, '2026-12-07', 'Día de la Constitución', 'NACIONAL'),
(1, '2026-12-08', 'Inmaculada Concepción',         'NACIONAL'),
(1, '2026-12-25', 'Navidad',                       'NACIONAL');
 
-- =====================================================================
-- 5. Dos clientes de ejemplo
-- =====================================================================

INSERT INTO usuario (id_usuario, correo_usuario, contrasena_usuario, rol_usuario)
VALUES (10, 'andres.lozano@gmail.com', @pwd, 'CLIENTE');

INSERT INTO cliente (id_cliente, nombre_cliente, apellidos_cliente, telefono_cliente)
VALUES (10, 'Andrés', 'Lozano Martín', '600333444');

 
INSERT INTO usuario (id_usuario, correo_usuario, contrasena_usuario, rol_usuario)
VALUES (11, 'carlos.rodriguez@gmail.com', @pwd, 'CLIENTE');
INSERT INTO cliente (id_cliente, nombre_cliente, apellidos_cliente, telefono_cliente)
VALUES (11, 'Carlos', 'Rodríguez García', '600333444');
 
-- =====================================================================
-- 6. Una cita de ejemplo (opcional, facilita la demo)

-- =====================================================================
INSERT INTO cita (id_cliente, id_empleado, id_servicio,
                  fecha_cita, hora_inicio_cita, hora_fin_cita, estado_cita, nota_cita)
VALUES (10, 2, 1, '2026-05-15', '10:00', '10:30', 'CONFIRMADA',
        'Prefiere tijera antes que máquina');
 