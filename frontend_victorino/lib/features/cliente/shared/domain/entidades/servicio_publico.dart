// ============================================================================
// ServicioPublico — entidad de dominio
// ----------------------------------------------------------------------------
// Espejo del DTO `ServicioPublicoResponse` del backend (catálogo público).
// Es la entidad que ve el cliente al elegir servicio en el Paso 1 del wizard.
// Más ligera que `Servicio` del admin: NO expone fechas de auditoría ni flag activo.
// ============================================================================

class ServicioPublico {
  const ServicioPublico({
    required this.idServicio,
    required this.nombre,
    required this.duracionMinutos,
    required this.precio,
    required this.fotoUrl,
    this.descripcion,
  });

  final int idServicio;
  final String nombre;
  final String? descripcion;
  final int duracionMinutos;
  final num precio;
  // Ruta relativa: combinar con ApiEndpoints.urlImagen() para URL absoluta.
  final String fotoUrl;
}
