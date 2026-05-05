DELETE FROM administrador WHERE id_administrador = 1;
DELETE FROM empleado WHERE id_empleado = 1;
DELETE FROM usuario WHERE id_usuario = 1;

-- Hash REAL de 'Admin1234!' (generado con BCryptPasswordEncoder cost=10)
SET @pwd_admin := '$2a$10$6pJhA2nQuYkCzldhtuJTi.JFI/DCum8iwkffdaqWTCWs86RjrPTvi';

-- 1. Fila en usuario
INSERT INTO usuario (id_usuario, correo_usuario, contrasena_usuario, rol_usuario)
VALUES (1, 'victorino@admin.com', @pwd_admin, 'ADMINISTRADOR');

-- 2. Fila en empleado (id_empleado == id_usuario por @MapsId)
INSERT INTO empleado (id_empleado, nombre_empleado, apellidos_empleado,
                      foto_empleado, no_molestar_empleado)
VALUES (1, 'Victorino', 'Admin', '/uploads/empleados/admin.jpg', 0);

-- 3. Fila en administrador (id_administrador == id_empleado por @MapsId)
INSERT INTO administrador (id_administrador) VALUES (1);