// DTO espejo del AuthResponse del backend (Java record).
// Solo se usa en la capa data: la capa domain no lo conoce.
class AuthResponseDto {
  const AuthResponseDto({
    required this.accessToken,
    required this.refreshToken,
    required this.rol,
    required this.idUsuario,
    required this.nombreCompleto,
    this.foto,
  });

  final String accessToken;
  final String refreshToken;
  final String rol;
  final int idUsuario;
  final String nombreCompleto;
  final String? foto;

  factory AuthResponseDto.fromJson(Map<String, dynamic> json) {
    return AuthResponseDto(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      rol: json['rol'] as String,
      idUsuario: (json['idUsuario'] as num).toInt(),
      nombreCompleto: (json['nombreCompleto'] as String?) ?? '',
      foto: json['foto'] as String?,
    );
  }
}
