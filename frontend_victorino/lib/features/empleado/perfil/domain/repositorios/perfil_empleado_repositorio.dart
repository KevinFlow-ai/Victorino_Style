import '../entidades/perfil_resumen_empleado.dart';

abstract class PerfilEmpleadoRepositorio {
  // Obtiene el resumen del perfil (citas completadas, experiencia, etc.)
  // Pasamos el id para que sea más robusto que depender solo del token Principal
  Future<PerfilResumenEmpleado> obtenerResumen(int idEmpleado);

  // Cambia la contraseña del empleado
  Future<void> cambiarPassword({required String actual, required String nueva});
}
