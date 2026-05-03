// Entidad de dominio: par correo + contraseña que envía el formulario de login.
// Es inmutable y vive solo en la capa de dominio (no se serializa nunca tal cual).
class Credenciales {
  const Credenciales({
    required this.correo,
    required this.password,
  });

  final String correo;
  final String password;
}
