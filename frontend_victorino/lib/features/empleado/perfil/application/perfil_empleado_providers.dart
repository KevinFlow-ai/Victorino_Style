import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/providers/sesion_provider.dart';
import '../../../../shared/providers/dio_provider.dart';
import '../../../administrador/agenda/domain/entidades/cita.dart';
import '../data/repositorios/perfil_empleado_repositorio_impl.dart';
import '../domain/entidades/perfil_resumen_empleado.dart';
import '../domain/repositorios/perfil_empleado_repositorio.dart';

final perfilEmpleadoRepositorioProvider = Provider<PerfilEmpleadoRepositorio>((ref) {
  return PerfilEmpleadoRepositorioImpl(dio: ref.read(dioProvider));
});

/// Notifier para manejar el resumen del perfil del empleado.
class PerfilEmpleadoResumenNotifier extends AsyncNotifier<PerfilResumenEmpleado> {
  @override
  Future<PerfilResumenEmpleado> build() async {
    final sesion = ref.watch(sesionProvider).value;
    if (sesion == null) throw Exception('No hay sesión activa');
    return ref.read(perfilEmpleadoRepositorioProvider).obtenerResumen(sesion.idUsuario);
  }

  Future<void> recargar() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => build());
  }
}

final perfilEmpleadoResumenProvider =
    AsyncNotifierProvider<PerfilEmpleadoResumenNotifier, PerfilResumenEmpleado>(
        PerfilEmpleadoResumenNotifier.new);

/// Provider para el historial de un cliente con el empleado actual.
final historialClienteConEmpleadoProvider =
    FutureProvider.family<HistorialCliente, int>((ref, idCliente) async {
  final sesion = ref.watch(sesionProvider).value;
  if (sesion == null) throw Exception('No hay sesión activa');
  
  return ref
      .read(perfilEmpleadoRepositorioProvider)
      .obtenerHistorialClienteConEmpleado(idCliente, sesion.idUsuario);
});

/// Datos de descanso del empleado autenticado.
/// Los consume la agenda del empleado para pintar la franja gris del descanso.
final descansoEmpleadoProvider =
    FutureProvider<({String? horaDescanso, int? duracionDescansoMinutos})>(
        (ref) async {
  final sesion = ref.watch(sesionProvider).value;
  if (sesion == null) {
    return (horaDescanso: null, duracionDescansoMinutos: null);
  }
  return ref.read(perfilEmpleadoRepositorioProvider).obtenerDescanso();
});

/// Notifier para el proceso de cambio de contraseña.
class CambiarPasswordEmpleadoNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {
    return;
  }

  Future<void> ejecutar({required String actual, required String nueva}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() =>
        ref.read(perfilEmpleadoRepositorioProvider).cambiarPassword(actual: actual, nueva: nueva));
  }
}

final cambiarPasswordEmpleadoProvider =
    AsyncNotifierProvider<CambiarPasswordEmpleadoNotifier, void>(
        CambiarPasswordEmpleadoNotifier.new);
