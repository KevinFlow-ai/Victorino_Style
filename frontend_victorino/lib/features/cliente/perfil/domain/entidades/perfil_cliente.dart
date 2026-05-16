// ============================================================================
// PerfilCliente — entidad de dominio
// ----------------------------------------------------------------------------
// Datos del cliente autenticado tal y como los muestra la pantalla Perfil.
// Espejo del DTO PerfilClienteResponse del backend.
// ============================================================================

class PerfilCliente {
  const PerfilCliente({
    required this.idCliente,
    required this.nombre,
    required this.apellidos,
    required this.correo,
    required this.pushActiva,
    this.telefono,
    this.fotoUrl,
  });

  final int idCliente;
  final String nombre;
  final String apellidos;
  final String correo;
  final String? telefono;
  // Ruta relativa de la foto. Null si el cliente nunca subió foto.
  final String? fotoUrl;
  // Preferencia de notificaciones push (in-app SIEMPRE se reciben, push solo si true).
  final bool pushActiva;

  String get nombreCompleto => '$nombre $apellidos'.trim();
}

// Datos editables del perfil: nombre, apellidos, correo y teléfono.
// La foto, la contraseña y la preferencia de push viajan por endpoints aparte.
class DatosPerfilCliente {
  const DatosPerfilCliente({
    required this.nombre,
    required this.apellidos,
    required this.correo,
    this.telefono,
  });

  final String nombre;
  final String apellidos;
  final String correo;
  final String? telefono;
}
