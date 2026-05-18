import '../../../../administrador/agenda/domain/entidades/cita.dart';
import '../entidades/perfil_resumen_empleado.dart';

abstract class PerfilEmpleadoRepositorio {
  // Obtiene el resumen del perfil (citas completadas, experiencia, etc.)
  Future<PerfilResumenEmpleado> obtenerResumen(int idEmpleado);

  // Cambia la contraseña del empleado
  Future<void> cambiarPassword({required String actual, required String nueva});

  // Obtiene el historial de un cliente específico con un empleado específico
  Future<HistorialCliente> obtenerHistorialClienteConEmpleado(int idCliente, int idEmpleado);
}
