// ============================================================================
// Providers del catálogo público (servicios + empleados)
// ----------------------------------------------------------------------------
// El Home, el wizard y otras pantallas del cliente consumen estos providers
// para listar servicios y empleados. Se recarga al abrir el Home y al hacer
// pull-to-refresh: así los cambios del admin se reflejan en tiempo real.
// ============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/providers/dio_provider.dart';
import '../data/repositorios/catalogo_repositorio_impl.dart';
import '../domain/casos_uso/obtener_catalogo.dart';
import '../domain/entidades/empleado_publico.dart';
import '../domain/entidades/servicio_publico.dart';
import '../domain/repositorios/catalogo_repositorio.dart';

// Inyección del repositorio HTTP.
final catalogoRepositorioProvider = Provider<CatalogoRepositorio>((ref) {
  return CatalogoRepositorioImpl(dio: ref.read(dioProvider));
});

// Casos de uso: la UI los llama directamente desde los notifiers / providers.
final obtenerServiciosProvider = Provider<ObtenerServicios>(
  (ref) => ObtenerServicios(ref.read(catalogoRepositorioProvider)),
);

final obtenerEmpleadosPublicosProvider = Provider<ObtenerEmpleadosPublicos>(
  (ref) => ObtenerEmpleadosPublicos(ref.read(catalogoRepositorioProvider)),
);

// FutureProvider del listado de servicios. Se invalida con `ref.invalidate(...)`.
final serviciosCatalogoProvider = FutureProvider<List<ServicioPublico>>((ref) {
  return ref.read(obtenerServiciosProvider).ejecutar();
});

// FutureProvider del listado de empleados.
final empleadosCatalogoProvider = FutureProvider<List<EmpleadoPublico>>((ref) {
  return ref.read(obtenerEmpleadosPublicosProvider).ejecutar();
});
