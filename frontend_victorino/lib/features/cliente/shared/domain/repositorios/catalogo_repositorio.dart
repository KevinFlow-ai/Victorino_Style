// Contrato del repositorio del catálogo público (servicios + empleados).
// La UI obtiene servicios/empleados solo a través de este contrato.

import '../entidades/empleado_publico.dart';
import '../entidades/servicio_publico.dart';

abstract class CatalogoRepositorio {
  // Lista de servicios activos (alfabéticamente). Filtra los dados de baja.
  Future<List<ServicioPublico>> obtenerServicios();

  // Lista de empleados activos. Filtra los dados de baja del usuario.
  Future<List<EmpleadoPublico>> obtenerEmpleados();
}
