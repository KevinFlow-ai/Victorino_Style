// Modelo de dominio que representa una sesión activa.
// Inmutable: si cambia algo se crea una copia con copyWith.
class SesionUsuario {
  const SesionUsuario({
    required this.idUsuario,
    required this.rol,
    required this.nombreCompleto,
    required this.accessToken,
    this.foto,
  });

  final int idUsuario;

  // CLIENTE | EMPLEADO | ADMINISTRADOR (string para no acoplar a backend).
  final String rol;
  final String nombreCompleto;

  // URL relativa devuelta por el backend (ej: /uploads/cliente/xxx.jpg). Puede ser null.
  final String? foto;

  // Vive solo en memoria, jamás se persiste.
  final String accessToken;

  SesionUsuario copyWith({
    int? idUsuario,
    String? rol,
    String? nombreCompleto,
    String? foto,
    String? accessToken,
  }) {
    return SesionUsuario(
      idUsuario: idUsuario ?? this.idUsuario,
      rol: rol ?? this.rol,
      nombreCompleto: nombreCompleto ?? this.nombreCompleto,
      foto: foto ?? this.foto,
      accessToken: accessToken ?? this.accessToken,
    );
  }
}
