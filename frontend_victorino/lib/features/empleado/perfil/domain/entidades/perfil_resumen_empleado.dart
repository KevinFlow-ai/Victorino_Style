class PerfilResumenEmpleado {
  final int id;
  final String nombreCompleto;
  final String? fotoUrl;
  final int citasCompletadas;
  final String tiempoExperiencia;

  PerfilResumenEmpleado({
    required this.id,
    required this.nombreCompleto,
    this.fotoUrl,
    required this.citasCompletadas,
    required this.tiempoExperiencia,
  });
}
