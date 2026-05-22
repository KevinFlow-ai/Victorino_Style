-- ======================================================================================
-- ============== SEED TFG VICTORINO STYLE (2025/2026) - VERSION RAILWAY ================
-- ======================================================================================
--
-- Copia de seed.sql preparada para cargarse contra la base de datos por defecto
-- de Railway (normalmente "railway"). La unica diferencia con seed.sql es que
-- NO ejecuta "USE <base>", porque el usuario por defecto de Railway no puede
-- cambiar de schema. Se ejecuta directamente sobre la base ya seleccionada
-- por la conexion (la que abre `railway connect MySQL`).
--
-- Para cargarlo:
--   railway connect MySQL
--   mysql> source schema_railway.sql
--   mysql> source seed_railway.sql
--
-- Datos generados (igual que seed.sql):
--   - 1 peluqueria con horario semanal (lun-vie 10:00-18:00, sab 10:00-16:00)
--   - 3 empleados (1 admin que tambien atiende + 2 peluqueros) con descansos
--   - 4 servicios con duraciones multiplo de 15 min (15, 30, 45, 90)
--   - 15 festivos Madrid 2026 + cierre anual en agosto
--   - 50 clientes (10 demo + 40 con contrasena unica por cliente)
--   - ~1000 citas entre el 01/03/2026 y el 20/06/2026
--   - Notificaciones coherentes por cada cita
--
-- Las credenciales (correo + contrasena en texto plano) estan al final del archivo.
-- ======================================================================================

-- --------------------------------------------------------------------------------------
-- 0. HASHES BCRYPT (cost 10, mismo que el backend)
-- --------------------------------------------------------------------------------------
-- Variables de sesión para no repetir el hash en cada INSERT. Cada hash corresponde
-- a una contraseña en texto plano distinta. Los hashes se han generado fuera de SQL
-- (bcrypt.hashpw cost=10) porque MySQL no puede calcularlos.
--
SET @pwd          := '$2a$10$6pJhA2nQuYkCzldhtuJTi.JFI/DCum8iwkffdaqWTCWs86RjrPTvi'; -- Admin1234!
SET @pwd_emp      := '$2b$10$4g57CPFeIH2RNZztKspIyujXoQ177YRxyRBEgMqqdQpi.v2xUcNIK'; -- Empleado1234!
SET @pwd_cli_demo := '$2b$10$Im4jPnL0q3HOophHADzXDuMIt3OaOeOKjMnktzWPWLj9XJAtnKMWa'; -- Cliente1234!
-- 40 hashes únicos: Cliente20! … Cliente59!  (uno por cliente raso).
SET @pwd_cli_20   := '$2b$10$0SYYE6oUgqYX76lL9i3M8esyM7.eDb/c7P6h3pOaa7V3U.BpTQL0.';
SET @pwd_cli_21   := '$2b$10$K5F3oeAIrM8x8HqhNtwPausRPAvZmwG/QwcJavfPAKWMDMXcsMeg6';
SET @pwd_cli_22   := '$2b$10$UKQFDTah0EDd2xIP4OGKC.DkO4kfJXiXoa6K3k/s7XUoT9w3sIplC';
SET @pwd_cli_23   := '$2b$10$AS1DZq.DC1/rRw5i45NJXOYO5OTGMMLjJB14iA0MjiVApgbEW0D12';
SET @pwd_cli_24   := '$2b$10$LYx9Ct/2gqZepejQtSmewe.k5MibgTz/fF7DrJqrMyyRY.wzPi3pe';
SET @pwd_cli_25   := '$2b$10$2uR.0Ou/mT.S3lf0ysLQyuA6waF0C73ZOvsXIb6uhVD9mzkWEUDi2';
SET @pwd_cli_26   := '$2b$10$oqOMY.Otz9vYQ0JWxmc5jubKAleoMIB0A4L0USij0VYmgEZdf5aXC';
SET @pwd_cli_27   := '$2b$10$dKP5ylWychqLXQl5Rl10veQJiwmcrCjwm60DWDRAqbUVbEPmBNQm2';
SET @pwd_cli_28   := '$2b$10$Oj2FkMHjnjqlgg7LpiERS.jQbse/Om5J8y2mZwT5G1dTnEhupCShq';
SET @pwd_cli_29   := '$2b$10$COozyV5P4hKDk79v8op3k.iqXHyNw2sdhVxrf6JBHNguO7EHaFCn2';
SET @pwd_cli_30   := '$2b$10$Ta9LI3nrUI3d22QyWzkNoOFTXjDXWtXzw5EW9E7LbbevXuhElAkn2';
SET @pwd_cli_31   := '$2b$10$4J2X4ARc0J/cVQvl1Bkj7e1xzKwYJEuQ4fZ7ocvGktZ1zCt/PgoF2';
SET @pwd_cli_32   := '$2b$10$YBIR5gY8sI.n37dzKGLVYu/kzfIdNWAqlFyuLps.5.gNPLnPy5q4a';
SET @pwd_cli_33   := '$2b$10$Rxmhl.SUMUsjI7U6L4V83Ov9cf02D8qHBwpFcTsd7Wg3ZoHBrFE/C';
SET @pwd_cli_34   := '$2b$10$1V66OAQ/qPam9NDRqvQkWuVhxPv3xd/ORoTxGQyd8K8aVjqmk0ByK';
SET @pwd_cli_35   := '$2b$10$69DzThEtB0GLBnlaKo9.aeoCEUDeZhRK1Uc0OZ1qr6/DuTVLOh6R6';
SET @pwd_cli_36   := '$2b$10$QveFreE2Br2wSFy3LkdQjeGwrnsSz61A53zPIjMY40dZjMNFlpmtG';
SET @pwd_cli_37   := '$2b$10$oQrXoXx.wUWOWtQJIKz4ie2vaGZIKt7t61zpEt8sZe01RE/BSYd1e';
SET @pwd_cli_38   := '$2b$10$2FTjMEiBHPHjtTUp7hJyeOsiE6nphFwG1Bld7vt6oulSjAmq5iD6i';
SET @pwd_cli_39   := '$2b$10$/kJBPlEGz5R5PKIHdC88tOr0wJMdlyohvWRfZEP1Oo0Q395kqRFLO';
SET @pwd_cli_40   := '$2b$10$TQKTTD7.HafdbO5botizLOqkTR.07p91vgG3MmUg78swlXdtVJ0pq';
SET @pwd_cli_41   := '$2b$10$QiTQhzL0NFc/82Y2KCuj.uo/B2u0/ApQNvYpL3dbySfzFYvGD0j6q';
SET @pwd_cli_42   := '$2b$10$k/yfwRKqt9uv2G4EcqduMOE8eEB/wE3/vOHkXhGb4BGuzdKRCKC1G';
SET @pwd_cli_43   := '$2b$10$ad8G88a8XS8kUJ5PLCO6TOHtnXYJBZL94Bde2nB2Zkkh.vfIEivRC';
SET @pwd_cli_44   := '$2b$10$8J/NuFxY0aiZE0i/eaeoWeLpH/ur1MgT1EtW4ilo4bA.1ZnhzXJ5e';
SET @pwd_cli_45   := '$2b$10$t/I8P7eT6PU1LrcnJU1P0Olmc6fjGlAaTjTrPonnUrthI.lFtuYdC';
SET @pwd_cli_46   := '$2b$10$FJ2i3TsYrfIHD2dwNETpr.xnNxOIAE2ao.fnWyE.8KfLKY2PuotSC';
SET @pwd_cli_47   := '$2b$10$EKAwIuCt9IirFJIqNw.mN.57K6r60T/fIuMNaNxQZ4azHII0vBE7O';
SET @pwd_cli_48   := '$2b$10$uyyQCWFSt7dqs/SeBq6kNesdW3NykC4spaRNnDYO.WmwYEylveSka';
SET @pwd_cli_49   := '$2b$10$c7buS4XHmzRSOgyhvvwlJeum3pWb5xvj55.W6.64ZB6kjbYsZVOs2';
SET @pwd_cli_50   := '$2b$10$gG/31bC0nckFVBUBSQRTgOAdK2W9nmJVIW/VH3dX03kINjp2A0EwW';
SET @pwd_cli_51   := '$2b$10$KrG8r34dfRiRbdF/pUpuAul.8k67umUBbPLLR5kKVYRIGtDr4yvde';
SET @pwd_cli_52   := '$2b$10$X02R7NMSlwp5xwnAfFv6i.Nil0A4Gxbx4Bon6dnwvoZ1FczuFcm/.';
SET @pwd_cli_53   := '$2b$10$9juQeWGxufJlbdZMxM1xAukTUERsLJsuK6971z1D5Jzzj8fyLIO2q';
SET @pwd_cli_54   := '$2b$10$KkDrL5oVJWgbWKn8wAMefuwOojeKxNfWkl/JXZH9yQR8QjqHb3GQG';
SET @pwd_cli_55   := '$2b$10$uo3nLUwS.ohtBKpPT5gay.kU38vIp6SST4duoA2PYG98VvwB9hLMm';
SET @pwd_cli_56   := '$2b$10$cD/8WOGFZqygFyFJ48/yz.X0Yw6eW93jTpqo0R5drwcgh4tAcSCeO';
SET @pwd_cli_57   := '$2b$10$0En.xqpkk3UDlhsPM9BukuhmNUc03e75kaXD59RnRfISeZetLIWyu';
SET @pwd_cli_58   := '$2b$10$Mi2avVDCGlFX8m.g7CZrRuLNGLu81tFJhKcULxxAEz9o9mz4L9h1y';
SET @pwd_cli_59   := '$2b$10$QEH489a4p3n6P9SQVFKZvux5wCXKI82G9RoaRDkkk3bbL2ZSZK96y';

-- ======================================================================================
-- 1. PELUQUERÍA (singleton)
-- ======================================================================================
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
  '10:00','16:00',  -- Sábado  (jornada reducida)
  NULL, NULL,       -- Domingo cerrado
  '2026-08-01','2026-08-31'  -- Vacaciones anuales (agosto)
);

-- ======================================================================================
-- 2. FESTIVOS 2026 (Comunidad de Madrid) 15 Festivos
-- ======================================================================================
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
(1, '2026-11-02', 'Todos los Santos',              'NACIONAL'),
(1, '2026-11-09', 'Ntra. Sra. de la Almudena',     'LOCAL'),
(1, '2026-12-07', 'Día de la Constitución',        'NACIONAL'),
(1, '2026-12-08', 'Inmaculada Concepción',         'NACIONAL'),
(1, '2026-12-25', 'Navidad',                       'NACIONAL');

-- ======================================================================================
-- 3. EMPLEADOS (jerarquía JOINED: usuario -> empleado -> administrador)
-- ======================================================================================

-- 3.1 Administrador (Victorino) — también es peluquero y atiende citas
INSERT INTO usuario (id_usuario, correo_usuario, contrasena_usuario, rol_usuario)
VALUES (1, 'victorino@admin.com', @pwd, 'ADMINISTRADOR');

INSERT INTO empleado (id_empleado, nombre_empleado, apellidos_empleado, foto_empleado)
VALUES (1, 'Victorino', 'Admin', '/uploads/empleados/admin.png');

INSERT INTO administrador (id_administrador) VALUES (1);

INSERT INTO horario_empleado (id_empleado, descanso_inicio_horario, descanso_duracion_horario)
VALUES (1, '11:30', 30);

-- 3.2 Empleado: Diego Armando Maradona
INSERT INTO usuario (id_usuario, correo_usuario, contrasena_usuario, rol_usuario)
VALUES (2, 'maradona@victorinostyle.com', @pwd_emp, 'EMPLEADO');

INSERT INTO empleado (id_empleado, nombre_empleado, apellidos_empleado, foto_empleado)
VALUES (2, 'Maradona', 'Bukele', '/uploads/empleados/barbero_1.png');

INSERT INTO horario_empleado (id_empleado, descanso_inicio_horario, descanso_duracion_horario)
VALUES (2, '14:00', 30);

-- 3.3 Empleado inventado: Javier Fernández Ortega
INSERT INTO usuario (id_usuario, correo_usuario, contrasena_usuario, rol_usuario)
VALUES (3, 'jerson@victorinostyle.com', @pwd_emp, 'EMPLEADO');

INSERT INTO empleado (id_empleado, nombre_empleado, apellidos_empleado, foto_empleado)
VALUES (3, 'Jerson', 'Audiel Ortega', '/uploads/empleados/barbero_3.png');

INSERT INTO horario_empleado (id_empleado, descanso_inicio_horario, descanso_duracion_horario)
VALUES (3, '16:00', 30);

-- ======================================================================================
-- 4. SERVICIOS (4 totales, duraciones múltiplo de 15 min)
-- ======================================================================================
INSERT INTO servicio (id_servicio, nombre_servicio, descripcion_servicio,
                      duracion_servicio, precio_servicio, foto_servicio) VALUES
(1, 'Corte de pelo',
	'Refresca tu imagen con un corte totalmente personalizado. Incluye lavado y un acabado profesional con peinado para que salgas listo a comerte el mundo.  ',
    
    -- *********** DESCRIPCION ANTIGUA ****************
	-- 'Refresca tu imagen con un corte totalmente personalizado, adaptado a tu forma de rostro y estilo '
    -- 'Incluye lavado y un acabado profesional con peinado para que salgas listo a comerte el mundo.',
    30, 15.00, '/uploads/servicios/f85b25c4-8699-46af-acd3-10d8c6de2757.jpg'),

(2, 'Barba',
	'Perfilado experto con navaja, aceites premium y toalla caliente. '
    'Mantén tu barba afilada, hidratada y con presencia.',
    15, 10.00, '/uploads/servicios/be6f02f2-4969-4d0f-b351-8cf82ce14c6f.jpg'),

(3, 'Tinte de pelo',
	 'Rejuvenece tu look con un color profesional que cubre canas y realza tu estilo. Resultado natural, uniforme y duradero tras un análisis capilar previo.',
	-- *********** DESCRIPCION ANTIGUA ****************
    -- 'Si quieres verte más joven o simplemente renovar tu look, este servicio es para ti. '
    -- 'Aplicamos un color profesional que cubre canas o ajusta el tono. Utilizamos productos de alta calidad y realizamos un análisis capilar previo para garantizar un resultado natural, uniforme y duradero. ',

    90, 35.00, '/uploads/servicios/6e05f56c-07c7-4978-bcd0-b24f262df126.jpg'),

(4, 'Corte de pelo + barba',
	'El combo definitivo: renueva tu estilo con un corte totalmente personalizado y un perfilado de barba.
	Incluye tratamiento de toalla caliente y lavado para conseguir un acabado limpio y fresco.',
    45, 20.00, '/uploads/servicios/servicio_2_corte_clasico.png');

-- ======================================================================================
-- 5. CLIENTES (50 totales, ids 10..59)
-- ======================================================================================
-- Ids 10..19: clientes "demo" → contraseña común Cliente1234!
-- Ids 20..59: clientes "rasos" → contraseña única Cliente{id}!  (Cliente20!, …, Cliente59!)

-- 5.1 Clientes DEMO (10) — contraseña Cliente1234!
INSERT INTO usuario (id_usuario, correo_usuario, contrasena_usuario, rol_usuario) VALUES
(10, 'andres.lozano@gmail.com',     @pwd_cli_demo, 'CLIENTE'),
(11, 'carlos.rodriguez@gmail.com',  @pwd_cli_demo, 'CLIENTE'),
(12, 'miguel.perez@gmail.com',      @pwd_cli_demo, 'CLIENTE'),
(13, 'javier.lopez@gmail.com',      @pwd_cli_demo, 'CLIENTE'),
(14, 'antonio.garcia@gmail.com',    @pwd_cli_demo, 'CLIENTE'),
(15, 'manuel.martinez@gmail.com',   @pwd_cli_demo, 'CLIENTE'),
(16, 'jose.hernandez@gmail.com',    @pwd_cli_demo, 'CLIENTE'),
(17, 'pablo.romero@gmail.com',      @pwd_cli_demo, 'CLIENTE'),
(18, 'david.gomez@gmail.com',       @pwd_cli_demo, 'CLIENTE'),
(19, 'sergio.navarro@gmail.com',    @pwd_cli_demo, 'CLIENTE');

INSERT INTO cliente (id_cliente, nombre_cliente, apellidos_cliente, telefono_cliente) VALUES
(10, 'Andrés',       'Lozano Martín',     '600111222'),
(11, 'Carlos',       'Rodríguez García',   NULL),
(12, 'Miguel Ángel', 'Pérez Ruiz',        '611222333'),
(13, 'Javier',       'López Sánchez',     '622333444'),
(14, 'Antonio',      'García Fernández',   NULL),
(15, 'Manuel',       'Martínez Jiménez',  '633444555'),
(16, 'José',         'Hernández Moreno',  '644555666'),
(17, 'Pablo',        'Romero Álvarez',     NULL),
(18, 'David',        'Gómez Torres',      '655666777'),
(19, 'Sergio',       'Navarro Castro',    '666777888');

-- 5.2 Clientes "rasos" (40) — cada uno con contraseña única Cliente{id}!
INSERT INTO usuario (id_usuario, correo_usuario, contrasena_usuario, rol_usuario) VALUES
(20, 'adrian.molina@gmail.com',      @pwd_cli_20, 'CLIENTE'),
(21, 'alvaro.serrano@gmail.com',     @pwd_cli_21, 'CLIENTE'),
(22, 'angel.gutierrez@gmail.com',    @pwd_cli_22, 'CLIENTE'),
(23, 'bruno.iglesias@gmail.com',     @pwd_cli_23, 'CLIENTE'),
(24, 'daniel.medina@gmail.com',      @pwd_cli_24, 'CLIENTE'),
(25, 'diego.ortega@gmail.com',       @pwd_cli_25, 'CLIENTE'),
(26, 'eduardo.delgado@gmail.com',    @pwd_cli_26, 'CLIENTE'),
(27, 'emilio.rubio@gmail.com',       @pwd_cli_27, 'CLIENTE'),
(28, 'enrique.suarez@gmail.com',     @pwd_cli_28, 'CLIENTE'),
(29, 'fernando.castillo@gmail.com',  @pwd_cli_29, 'CLIENTE'),
(30, 'francisco.ramos@gmail.com',    @pwd_cli_30, 'CLIENTE'),
(31, 'gabriel.dominguez@gmail.com',  @pwd_cli_31, 'CLIENTE'),
(32, 'gonzalo.vazquez@gmail.com',    @pwd_cli_32, 'CLIENTE'),
(33, 'guillermo.gil@gmail.com',      @pwd_cli_33, 'CLIENTE'),
(34, 'hugo.ramirez@gmail.com',       @pwd_cli_34, 'CLIENTE'),
(35, 'ignacio.blanco@gmail.com',     @pwd_cli_35, 'CLIENTE'),
(36, 'ivan.morales@gmail.com',       @pwd_cli_36, 'CLIENTE'),
(37, 'jaime.ortiz@gmail.com',        @pwd_cli_37, 'CLIENTE'),
(38, 'jesus.cano@gmail.com',         @pwd_cli_38, 'CLIENTE'),
(39, 'joaquin.marin@gmail.com',      @pwd_cli_39, 'CLIENTE'),
(40, 'jorge.sanz@gmail.com',         @pwd_cli_40, 'CLIENTE'),
(41, 'juan.crespo@gmail.com',        @pwd_cli_41, 'CLIENTE'),
(42, 'julian.garrido@gmail.com',     @pwd_cli_42, 'CLIENTE'),
(43, 'lorenzo.santos@gmail.com',     @pwd_cli_43, 'CLIENTE'),
(44, 'lucas.peña@gmail.com',         @pwd_cli_44, 'CLIENTE'),
(45, 'luis.bravo@gmail.com',         @pwd_cli_45, 'CLIENTE'),
(46, 'marcos.cabrera@gmail.com',     @pwd_cli_46, 'CLIENTE'),
(47, 'mario.aguilar@gmail.com',      @pwd_cli_47, 'CLIENTE'),
(48, 'martin.flores@gmail.com',      @pwd_cli_48, 'CLIENTE'),
(49, 'mateo.herrera@gmail.com',      @pwd_cli_49, 'CLIENTE'),
(50, 'nicolas.cortes@gmail.com',     @pwd_cli_50, 'CLIENTE'),
(51, 'oscar.cabello@gmail.com',      @pwd_cli_51, 'CLIENTE'),
(52, 'pedro.guerrero@gmail.com',     @pwd_cli_52, 'CLIENTE'),
(53, 'rafael.lara@gmail.com',        @pwd_cli_53, 'CLIENTE'),
(54, 'raul.calvo@gmail.com',         @pwd_cli_54, 'CLIENTE'),
(55, 'rodrigo.vega@gmail.com',       @pwd_cli_55, 'CLIENTE'),
(56, 'ruben.cano2@gmail.com',        @pwd_cli_56, 'CLIENTE'),
(57, 'salvador.parra@gmail.com',     @pwd_cli_57, 'CLIENTE'),
(58, 'santiago.fuentes@gmail.com',   @pwd_cli_58, 'CLIENTE'),
(59, 'tomas.escobar@gmail.com',      @pwd_cli_59, 'CLIENTE');

INSERT INTO cliente (id_cliente, nombre_cliente, apellidos_cliente, telefono_cliente) VALUES
(20, 'Adrián',    'Molina Cano',       '677888999'),
(21, 'Álvaro',    'Serrano Pardo',      NULL),
(22, 'Ángel',     'Gutiérrez León',    '688999000'),
(23, 'Bruno',     'Iglesias Vidal',    '699000111'),
(24, 'Daniel',    'Medina Reyes',       NULL),
(25, 'Diego',     'Ortega Mendoza',    '600222333'),
(26, 'Eduardo',   'Delgado Pascual',    NULL),
(27, 'Emilio',    'Rubio Soto',        '611333444'),
(28, 'Enrique',   'Suárez Núñez',      '622444555'),
(29, 'Fernando',  'Castillo Bueno',     NULL),
(30, 'Francisco', 'Ramos Ferrer',      '633555666'),
(31, 'Gabriel',   'Domínguez Polo',     NULL),
(32, 'Gonzalo',   'Vázquez León',      '644666777'),
(33, 'Guillermo', 'Gil Caballero',     '655777888'),
(34, 'Hugo',      'Ramírez Plaza',      NULL),
(35, 'Ignacio',   'Blanco Carmona',    '666888999'),
(36, 'Iván',      'Morales Esteban',   '677999000'),
(37, 'Jaime',     'Ortiz Bermejo',      NULL),
(38, 'Jesús',     'Cano Aparicio',     '688000111'),
(39, 'Joaquín',   'Marín Soler',       '699111222'),
(40, 'Jorge',     'Sanz Lozano',        NULL),
(41, 'Juan',      'Crespo Vargas',     '600333444'),
(42, 'Julián',    'Garrido Pintor',    '611444555'),
(43, 'Lorenzo',   'Santos Vera',        NULL),
(44, 'Lucas',     'Peña Otero',        '622555666'),
(45, 'Luis',      'Bravo Rivas',       '633666777'),
(46, 'Marcos',    'Cabrera Cordero',    NULL),
(47, 'Mario',     'Aguilar Pastor',    '644777888'),
(48, 'Martín',    'Flores Saavedra',   '655888999'),
(49, 'Mateo',     'Herrera Quintana',   NULL),
(50, 'Nicolás',   'Cortés Mora',       '666999000'),
(51, 'Óscar',     'Cabello Vives',     '677000111'),
(52, 'Pedro',     'Guerrero Salinas',   NULL),
(53, 'Rafael',    'Lara Aranda',       '688111222'),
(54, 'Raúl',      'Calvo Verdú',       '699222333'),
(55, 'Rodrigo',   'Vega Carrillo',      NULL),
(56, 'Rubén',     'Cano Linares',      '600444555'),
(57, 'Salvador',  'Parra Riera',       '611555666'),
(58, 'Santiago',  'Fuentes Roldán',     NULL),
(59, 'Tomás',     'Escobar Tena',      '622666777');

-- ======================================================================================
-- 6. GENERACIÓN MASIVA DE CITAS + NOTIFICACIONES (procedimiento almacenado)
-- ======================================================================================
-- Recorre cada día del 01/03/2026 al 20/06/2026. Para cada día laborable (no
-- domingo, no festivo, no agosto) reparte un número objetivo de citas entre los
-- 3 empleados, respetando descansos y sin solapes.
--
-- Algoritmo por día y empleado:
--   1) Cursor `v_hora` arranca en 10:00.
--   2) Si v_hora cae dentro del descanso → salta al final del descanso.
--   3) Servicio aleatorio (1..4). Duración derivada del servicio (15/30/45/90).
--   4) Si v_hora+duración ≤ cierre y no solapa el descanso, se decide aleatoriamente
--      (RAND() < 0.65) si crear la cita.
--   5) Si se crea: cliente aleatorio (10..59), estado según rango temporal,
--      INSERT cita, INSERT notificaciones según estado. Cursor avanza a hora_fin.
--   6) Si no se crea o el slot no encaja: cursor avanza 15 min.
--
-- Estados:
--   01 mar – 24 may  →  70 % COMPLETADA, 15 % CANC_CLIENTE, 10 % CANC_PELUQUERIA, 5 % NO_PRESENTADO
--   25 may – 20 jun  →  80 % CONFIRMADA, 10 % CANC_CLIENTE, 10 % CANC_PELUQUERIA
--
-- Notificaciones generadas por cada cita:
--   · Siempre:                        CONFIRMACION_RESERVA   (al cliente)
--   · Siempre:                        NUEVA_CITA_EMPLEADO    (al empleado)
--   · Si CANCELADA_CLIENTE:           CANCELACION_CLIENTE    (al empleado)
--   · Si CANCELADA_PELUQUERIA:        CANCELACION_PELUQUERIA (al cliente)
--   · Si COMPLETADA o (CONFIRMADA y fecha ≤ 26/05/2026):
--                                     RECORDATORIO_24H        (al cliente)
-- ======================================================================================

DROP PROCEDURE IF EXISTS generar_citas_demo;
DELIMITER //
CREATE PROCEDURE generar_citas_demo()
BEGIN
  DECLARE v_dia              DATE     DEFAULT '2026-03-01';
  DECLARE v_dow              INT;
  DECLARE v_es_festivo       INT;
  DECLARE v_cierre           TIME;
  DECLARE v_volumen          INT;
  DECLARE v_emp              BIGINT UNSIGNED;
  DECLARE v_descanso_ini     TIME;
  DECLARE v_descanso_fin     TIME;
  DECLARE v_intentos         INT;
  DECLARE v_hora             TIME;
  DECLARE v_servicio_id      BIGINT UNSIGNED;
  DECLARE v_duracion         INT;
  DECLARE v_hora_fin         TIME;
  DECLARE v_cliente_id       BIGINT UNSIGNED;
  DECLARE v_estado           VARCHAR(30);
  DECLARE v_r                DECIMAL(10,4);
  DECLARE v_cita_id          BIGINT UNSIGNED;
  DECLARE v_nota             VARCHAR(350);
  DECLARE v_push             BOOLEAN;
  DECLARE v_fecha_txt        VARCHAR(20);
  DECLARE v_hora_txt         VARCHAR(10);

  WHILE v_dia <= '2026-06-20' DO
    SET v_dow        = DAYOFWEEK(v_dia); -- 1=domingo, 7=sábado
    SET v_es_festivo = (SELECT COUNT(*) FROM festivo WHERE fecha_festivo = v_dia);

    -- Saltar domingos, festivos y el periodo de cierre anual (agosto).
    IF v_dow <> 1
       AND v_es_festivo = 0
       AND NOT (v_dia BETWEEN '2026-08-01' AND '2026-08-31')
    THEN
      SET v_cierre = IF(v_dow = 7, '16:00:00', '18:00:00');

      -- Volumen objetivo total del día (se reparte entre los 3 empleados).
      IF v_dia <= '2026-04-30' THEN
        SET v_volumen = 15 + FLOOR(RAND() * 6);  -- 15..20
      ELSEIF v_dia <= '2026-05-24' THEN
        SET v_volumen = 8  + FLOOR(RAND() * 3);  -- 8..10
      ELSE
        SET v_volumen = 4  + FLOOR(RAND() * 3);  -- 4..6
      END IF;

      -- Push como TRUE para citas pasadas (≤ 14/05/2026, "ya enviadas"),
      -- FALSE para futuras (simula que aún no se han disparado).
      SET v_push = (v_dia <= '2026-05-14'); -- Si la cita es del 14/05/2026 o antes → v_push = TRUE  Las notificaciones aparecen como enviadas. ||| Si la cita es del 15/05/2026 en adelante → v_push = FALSE  Las notificaciones quedan creadas en la tabla, pero NO marcadas como enviadas.
      
      -- SET v_push = TRUE; para enviar todas las notificaciones
      -- SET v_push = (v_dia >= CURDATE()); que solo las futuras se envíen
      -- SET v_push = FALSE; -- que nunca se envíen (solo para pruebas)
      
      -- ---- Bucle por empleado --------------------------------------------------
      SET v_emp = 1;
      WHILE v_emp <= 3 DO
        SELECT descanso_inicio_horario,
               ADDTIME(descanso_inicio_horario, SEC_TO_TIME(descanso_duracion_horario * 60))
          INTO v_descanso_ini, v_descanso_fin
          FROM horario_empleado
          WHERE id_empleado = v_emp;

        SET v_intentos = CEIL(v_volumen / 3);
        SET v_hora     = '10:00:00';

        WHILE v_hora < v_cierre AND v_intentos > 0 DO
          -- Si caemos en pleno descanso, saltamos al final del descanso.
          IF v_hora >= v_descanso_ini AND v_hora < v_descanso_fin THEN
            SET v_hora = v_descanso_fin;
          ELSE
            -- Servicio aleatorio (1..4) y duración asociada.
            SET v_servicio_id = 1 + FLOOR(RAND() * 4);
            SET v_duracion    = CASE v_servicio_id
                                  WHEN 1 THEN 30
                                  WHEN 2 THEN 15
                                  WHEN 3 THEN 90
                                  WHEN 4 THEN 45
                                END;
            SET v_hora_fin    = ADDTIME(v_hora, SEC_TO_TIME(v_duracion * 60));

            -- Validar: cabe en horario y NO solapa el descanso.
            IF v_hora_fin <= v_cierre
               AND NOT (v_hora < v_descanso_fin AND v_hora_fin > v_descanso_ini)
            THEN
              IF RAND() < 0.65 THEN
                -- Cliente aleatorio (10..59).
                SET v_cliente_id = 10 + FLOOR(RAND() * 50);

                -- Estado según rango temporal.
                SET v_r = RAND();
                IF v_dia <= '2026-05-24' THEN
                  IF      v_r < 0.70 THEN SET v_estado = 'COMPLETADA';
                  ELSEIF  v_r < 0.85 THEN SET v_estado = 'CANCELADA_CLIENTE';
                  ELSEIF  v_r < 0.95 THEN SET v_estado = 'CANCELADA_PELUQUERIA';
                  ELSE                     SET v_estado = 'NO_PRESENTADO';
                  END IF;
                ELSE
                  IF      v_r < 0.80 THEN SET v_estado = 'CONFIRMADA';
                  ELSEIF  v_r < 0.90 THEN SET v_estado = 'CANCELADA_CLIENTE';
                  ELSE                     SET v_estado = 'CANCELADA_PELUQUERIA';
                  END IF;
                END IF;

                -- Nota aleatoria (~20% con texto, resto NULL).
                SET v_nota = CASE FLOOR(RAND() * 10)
                              WHEN 0 THEN 'Prefiero tijera antes que máquina'
                              WHEN 1 THEN 'Prefiero un look clásico y sencillo'
                              ELSE NULL
                            END;

                -- Inserto la cita.
                INSERT INTO cita (id_cliente, id_empleado, id_servicio,
                                  fecha_cita, hora_inicio_cita, hora_fin_cita,
                                  estado_cita, nota_cita)
                VALUES (v_cliente_id, v_emp, v_servicio_id,
                        v_dia, v_hora, v_hora_fin,
                        v_estado, v_nota);

                SET v_cita_id   = LAST_INSERT_ID();
                SET v_fecha_txt = DATE_FORMAT(v_dia, '%d/%m/%Y');
                SET v_hora_txt  = TIME_FORMAT(v_hora, '%H:%i');

                -- Notificación 1: confirmación al cliente.
                INSERT INTO notificacion (id_destinatario_notificacion,
                                          id_cita_relacionada_notificacion,
                                          titulo_notificacion, cuerpo_notificacion,
                                          tipo_notificacion, enviada_push_notificacion)
                VALUES (v_cliente_id, v_cita_id,
                        'Reserva confirmada',
                        CONCAT('Tu cita está confirmada para el ', v_fecha_txt,
                               ' a las ', v_hora_txt, '.'),
                        'CONFIRMACION_RESERVA', v_push);

                -- Notificación 2: aviso al empleado.
                INSERT INTO notificacion (id_destinatario_notificacion,
                                          id_cita_relacionada_notificacion,
                                          titulo_notificacion, cuerpo_notificacion,
                                          tipo_notificacion, enviada_push_notificacion)
                VALUES (v_emp, v_cita_id,
                        'Nueva cita asignada',
                        CONCAT('Tienes una nueva cita el ', v_fecha_txt,
                               ' a las ', v_hora_txt, '.'),
                        'NUEVA_CITA_EMPLEADO', v_push);

                -- Notificaciones específicas por estado.
                IF v_estado = 'CANCELADA_CLIENTE' THEN
                  INSERT INTO notificacion (id_destinatario_notificacion,
                                            id_cita_relacionada_notificacion,
                                            titulo_notificacion, cuerpo_notificacion,
                                            tipo_notificacion, enviada_push_notificacion)
                  VALUES (v_emp, v_cita_id,
                          'Cita cancelada por el cliente',
                          CONCAT('La cita del ', v_fecha_txt, ' a las ', v_hora_txt,
                                 ' ha sido cancelada por el cliente.'),
                          'CANCELACION_CLIENTE', v_push);
                ELSEIF v_estado = 'CANCELADA_PELUQUERIA' THEN
                  INSERT INTO notificacion (id_destinatario_notificacion,
                                            id_cita_relacionada_notificacion,
                                            titulo_notificacion, cuerpo_notificacion,
                                            tipo_notificacion, enviada_push_notificacion)
                  VALUES (v_cliente_id, v_cita_id,
                          'Cita cancelada por la peluquería',
                          CONCAT('Lamentamos comunicarte que tu cita del ', v_fecha_txt,
                                 ' a las ', v_hora_txt,
                                 ' ha sido cancelada. Puedes reservar otra cuando quieras.'),
                          'CANCELACION_PELUQUERIA', v_push);
                END IF;

                -- Recordatorio 24h.
                IF v_estado = 'COMPLETADA'
                   OR (v_estado = 'CONFIRMADA' AND v_dia <= '2026-05-26')
                THEN
                  INSERT INTO notificacion (id_destinatario_notificacion,
                                            id_cita_relacionada_notificacion,
                                            titulo_notificacion, cuerpo_notificacion,
                                            tipo_notificacion, enviada_push_notificacion)
                  VALUES (v_cliente_id, v_cita_id,
                          'Recordatorio: tu cita es mañana',
                          CONCAT('No olvides tu cita el ', v_fecha_txt, ' a las ', v_hora_txt, '.'),
                          'RECORDATORIO_24H', v_push);
                END IF;

                -- Avanzo al final de la cita y descuento un intento.
                SET v_hora     = v_hora_fin;
                SET v_intentos = v_intentos - 1;
              ELSE
                -- No se crea cita en este slot: avanzo 15 min.
                SET v_hora = ADDTIME(v_hora, '00:15:00');
              END IF;
            ELSE
              -- El servicio no encaja en el slot: avanzo 15 min.
              SET v_hora = ADDTIME(v_hora, '00:15:00');
            END IF;
          END IF;
        END WHILE;

        SET v_emp = v_emp + 1;
      END WHILE;
    END IF;

    SET v_dia = DATE_ADD(v_dia, INTERVAL 1 DAY);
  END WHILE;
END //
DELIMITER ;

CALL generar_citas_demo();
DROP PROCEDURE generar_citas_demo;

-- ======================================================================================
-- 7. CREDENCIALES DE PRUEBA  (texto plano para facilitar la demo)
-- ======================================================================================
--
-- ─── ADMIN ─────────────────────────────────────────────────────────────
--   victorino@admin.com                  Admin1234!
--
-- ─── EMPLEADOS ─────────────────────────────────────────────────────────
--   maradona@victorinostyle.com          Empleado1234!
--   jerson@victorinostyle.com  Empleado1234!
--
-- ─── 10 CLIENTES DEMO (mismo password) ────────────────────────────────
--   andres.lozano@gmail.com              Cliente1234!
--   carlos.rodriguez@gmail.com           Cliente1234!
--   miguel.perez@gmail.com               Cliente1234!
--   javier.lopez@gmail.com               Cliente1234!
--   antonio.garcia@gmail.com             Cliente1234!
--   manuel.martinez@gmail.com            Cliente1234!
--   jose.hernandez@gmail.com             Cliente1234!
--   pablo.romero@gmail.com               Cliente1234!
--   david.gomez@gmail.com                Cliente1234!
--   sergio.navarro@gmail.com             Cliente1234!
--
-- ─── 40 CLIENTES RASOS (password única "Cliente{id}!") ────────────────
--   adrian.molina@gmail.com              Cliente20!
--   alvaro.serrano@gmail.com             Cliente21!
--   angel.gutierrez@gmail.com            Cliente22!
--   bruno.iglesias@gmail.com             Cliente23!
--   daniel.medina@gmail.com              Cliente24!
--   diego.ortega@gmail.com               Cliente25!
--   eduardo.delgado@gmail.com            Cliente26!
--   emilio.rubio@gmail.com               Cliente27!
--   enrique.suarez@gmail.com             Cliente28!
--   fernando.castillo@gmail.com          Cliente29!
--   francisco.ramos@gmail.com            Cliente30!
--   gabriel.dominguez@gmail.com          Cliente31!
--   gonzalo.vazquez@gmail.com            Cliente32!
--   guillermo.gil@gmail.com              Cliente33!
--   hugo.ramirez@gmail.com               Cliente34!
--   ignacio.blanco@gmail.com             Cliente35!
--   ivan.morales@gmail.com               Cliente36!
--   jaime.ortiz@gmail.com                Cliente37!
--   jesus.cano@gmail.com                 Cliente38!
--   joaquin.marin@gmail.com              Cliente39!
--   jorge.sanz@gmail.com                 Cliente40!
--   juan.crespo@gmail.com                Cliente41!
--   julian.garrido@gmail.com             Cliente42!
--   lorenzo.santos@gmail.com             Cliente43!
--   lucas.peña@gmail.com                 Cliente44!
--   luis.bravo@gmail.com                 Cliente45!
--   marcos.cabrera@gmail.com             Cliente46!
--   mario.aguilar@gmail.com              Cliente47!
--   martin.flores@gmail.com              Cliente48!
--   mateo.herrera@gmail.com              Cliente49!
--   nicolas.cortes@gmail.com             Cliente50!
--   oscar.cabello@gmail.com              Cliente51!
--   pedro.guerrero@gmail.com             Cliente52!
--   rafael.lara@gmail.com                Cliente53!
--   raul.calvo@gmail.com                 Cliente54!
--   rodrigo.vega@gmail.com               Cliente55!
--   ruben.cano2@gmail.com                Cliente56!
--   salvador.parra@gmail.com             Cliente57!
--   santiago.fuentes@gmail.com           Cliente58!
--   tomas.escobar@gmail.com              Cliente59!
--
-- ======================================================================================


















/*

-- ======================================================================================
-- =========================== SEED DATA/DATOS INCICIALES ANTIGUOOOO ANTIGUO ANTIGUO  ===============================
-- ======================================================================================

USE victorino_style_bbdd_tfg_2dam_2025_2026_puig;

-- Hash BCrypt REAL de la contraseña 'Admin1234!'
-- Generado con BCryptPasswordEncoder. Si lo cambias, regenera el hash con la
-- misma utilidad que usa el backend (clase PasswordEncoderConfig).
SET @pwd := '$2a$10$6pJhA2nQuYkCzldhtuJTi.JFI/DCum8iwkffdaqWTCWs86RjrPTvi';

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

-- 2.1 Administrador (Victorino Admin)
-- Por la jerarquía JOINED via @MapsId, un administrador requiere 3 filas:
-- una en usuario, una en empleado (con sus datos visibles) y una en administrador.
-- Login: correo='victorino@admin.com', password='Admin1234!'.
INSERT INTO usuario (id_usuario, correo_usuario, contrasena_usuario, rol_usuario)
VALUES (1, 'victorino@admin.com', @pwd, 'ADMINISTRADOR');

INSERT INTO empleado (id_empleado, nombre_empleado, apellidos_empleado, foto_empleado)
VALUES (1, 'Victorino', 'Admin', '/uploads/empleados/admin.png');

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
 
 */
