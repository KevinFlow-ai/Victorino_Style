// Providers del submódulo empleados: repositorio + casos de uso + AsyncNotifier
// del listado.
// -----------------------------------------------------------------------------
// Este archivo configura toda la capa de presentación del módulo "empleados":
// - Inyección del repositorio (HTTP)
// - Providers de casos de uso (crear, editar, dar de baja, subir foto…)
// - Un AsyncNotifier que carga y gestiona la lista de empleados

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/providers/dio_provider.dart';
import '../data/repositorios/empleado_admin_repositorio_impl.dart';
import '../domain/casos_uso/cancelar_citas_masivo.dart';
import '../domain/casos_uso/crear_empleado.dart';
import '../domain/casos_uso/dar_baja_empleado.dart';
import '../domain/casos_uso/editar_empleado.dart';
import '../domain/casos_uso/obtener_empleados.dart';
import '../domain/casos_uso/subir_foto_empleado.dart';
import '../domain/entidades/empleado.dart';
import '../domain/repositorios/empleado_admin_repositorio.dart';


// ============================================================================
// Providers de inyección
// ============================================================================

// Repositorio HTTP que habla con el backend usando Dio.
// La UI nunca usa directamente el repositorio: siempre pasa por casos de uso.
final empleadoRepositorioProvider = Provider<EmpleadoAdminRepositorio>((ref) {
  return EmpleadoAdminRepositorioImpl(dio: ref.read(dioProvider));
});

// Cada provider crea un caso de uso y le inyecta el repositorio.

final obtenerEmpleadosProvider = Provider<ObtenerEmpleados>(
      (ref) => ObtenerEmpleados(ref.read(empleadoRepositorioProvider)),
);

final crearEmpleadoProvider = Provider<CrearEmpleado>(
      (ref) => CrearEmpleado(ref.read(empleadoRepositorioProvider)),
);

final editarEmpleadoProvider = Provider<EditarEmpleado>(
      (ref) => EditarEmpleado(ref.read(empleadoRepositorioProvider)),
);

final darBajaEmpleadoProvider = Provider<DarBajaEmpleado>(
      (ref) => DarBajaEmpleado(ref.read(empleadoRepositorioProvider)),
);

final subirFotoEmpleadoProvider = Provider<SubirFotoEmpleado>(
      (ref) => SubirFotoEmpleado(ref.read(empleadoRepositorioProvider)),
);

final cancelarCitasMasivoProvider = Provider<CancelarCitasMasivo>(
      (ref) => CancelarCitasMasivo(ref.read(empleadoRepositorioProvider)),
);


// ============================================================================
// AsyncNotifier del listado
// ============================================================================

// Este notifier controla el estado de la lista de empleados.
// Es reactivo y asíncrono porque carga datos desde el backend.
class EmpleadosAdminNotifier extends AsyncNotifier<List<Empleado>> {
  // Flag interno: si se deben incluir empleados inactivos en el listado.
  bool _incluirInactivos = false;

  bool get incluirInactivos => _incluirInactivos;

  @override
  Future<List<Empleado>> build() async {
    // Carga inicial de empleados.
    return ref.read(obtenerEmpleadosProvider)
        .ejecutar(incluirInactivos: _incluirInactivos);
  }

  // Recarga la lista de empleados.
  // Se usa después de crear, editar, dar de baja o subir foto.
  Future<void> recargar() async {
    state = const AsyncLoading(); // muestra loading en la UI
    state = await AsyncValue.guard(() =>
        ref.read(obtenerEmpleadosProvider)
            .ejecutar(incluirInactivos: _incluirInactivos),
    );
  }

  // Cambia el flag "incluir inactivos" y recarga la lista.
  Future<void> alternarInactivos(bool valor) async {
    _incluirInactivos = valor;
    await recargar();
  }
}

// Provider del AsyncNotifier.
// La UI lo usa para obtener la lista de empleados y reaccionar a cambios.
final empleadosAdminNotifierProvider =
AsyncNotifierProvider<EmpleadosAdminNotifier, List<Empleado>>(
  EmpleadosAdminNotifier.new,
);
