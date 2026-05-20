// Providers del submódulo "negocio": horario, descansos, festivos, cierre anual, correo.
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/providers/dio_provider.dart';
import '../data/repositorios/negocio_admin_repositorio_impl.dart';
import '../domain/casos_uso/casos_uso_negocio.dart';
import '../domain/entidades/horario_peluqueria.dart';
import '../domain/repositorios/negocio_admin_repositorio.dart';


// ============================================================================
// EXPLICACIÓN GENERAL PARA NOVATOS
// ============================================================================
//
// Este archivo pertenece a una arquitectura llamada "Clean Architecture".
// Clean Architecture divide tu app en capas para que todoo esté ordenado:
//
//   ┌──────────────────────────┐
//   │        PRESENTACIÓN      │  <-- Widgets, UI, Notifiers
//   └──────────────────────────┘
//   ┌──────────────────────────┐
//   │        APLICACIÓN        │  <-- Providers, lógica de estado
//   └──────────────────────────┘
//   ┌──────────────────────────┐
//   │         DOMINIO          │  <-- Entidades, Casos de Uso
//   └──────────────────────────┘
//   ┌──────────────────────────┐
//   │          DATA            │  <-- Repositorios, API, BD
//   └──────────────────────────┘
//
// Este archivo está en la capa de APLICACIÓN.
// Aquí conectamos:
//   - Los casos de uso (DOMINIO)
//   - Con los repositorios (DATA)
//   - Y los exponemos a la UI mediante Riverpod.
//
// ============================================================================
// CONCEPTOS BÁSICOS PARA NOVATOS
// ============================================================================
//
// PROVIDER:
//   Es como una "caja" que guarda algo que otras partes de la app pueden usar.
//
// FUTURE:
//   Es algo que va a tardar un poco en obtenerse (por ejemplo, pedir datos a internet).
//
// STATE:
//   Es el "estado actual" de algo. Puede ser cargando, con datos o con error.
//
// ASYNC:
//   Significa que algo se hace "mientras tanto", sin bloquear la app.
//
// AsyncNotifier:
//   Es una clase especial de Riverpod que maneja estados asíncronos (Future).
//
// AsyncValue:
//   Representa el estado de una operación asíncrona:
//     - AsyncLoading() → está cargando
//     - AsyncData() → tiene datos
//     - AsyncError() → hubo un error
//
// ============================================================================
// DIAGRAMA DE FLUJO DE ESTE ARCHIVO
// ============================================================================
//
//   UI (pantalla) ───► Notifier ───► Caso de Uso ───► Repositorio ───► API
//
// Ejemplo:
//   Pantalla pide horario
//       ↓
//   HorarioNotifier.build()
//       ↓
//   ObtenerHorario.ejecutar()
//       ↓
//   Repositorio.getHorario()
//       ↓
//   API (Dio)
//


// ============================================================================
// PROVIDER DEL REPOSITORIO
// ============================================================================
//
// Aquí creamos el repositorio que se conecta con la API.
// El repositorio necesita "dio", que es el cliente HTTP para hacer peticiones.
//
// ref.read(dioProvider) → obtiene el cliente HTTP
//
final negocioRepositorioProvider = Provider<NegocioAdminRepositorio>((ref) {
  return NegocioAdminRepositorioImpl(dio: ref.read(dioProvider));
});

// ============================================================================
// PROVIDERS DE CASOS DE USO
// ============================================================================
//
// Cada caso de uso es una acción concreta del negocio:
//   - obtener horario
//   - actualizar horario
//   - obtener festivos
//   - etc.
//
// Cada provider crea una instancia del caso de uso y le pasa el repositorio.
//
final obtenerHorarioProvider =
Provider((ref) => ObtenerHorario(ref.read(negocioRepositorioProvider)));

final actualizarHorarioProvider =
Provider((ref) => ActualizarHorario(ref.read(negocioRepositorioProvider)));

final actualizarDescansoProvider =
Provider((ref) => ActualizarDescanso(ref.read(negocioRepositorioProvider)));

final obtenerFestivosProvider =
Provider((ref) => ObtenerFestivos(ref.read(negocioRepositorioProvider)));

final crearFestivoProvider =
Provider((ref) => CrearFestivo(ref.read(negocioRepositorioProvider)));

final eliminarFestivoProvider =
Provider((ref) => EliminarFestivo(ref.read(negocioRepositorioProvider)));

final obtenerCierreAnualProvider =
Provider((ref) => ObtenerCierreAnual(ref.read(negocioRepositorioProvider)));

final actualizarCierreAnualProvider =
Provider((ref) => ActualizarCierreAnual(ref.read(negocioRepositorioProvider)));

final obtenerConfigCorreoProvider =
Provider((ref) => ObtenerConfigCorreo(ref.read(negocioRepositorioProvider)));

final actualizarConfigCorreoProvider =
Provider((ref) => ActualizarConfigCorreo(ref.read(negocioRepositorioProvider)));

// ============================================================================
// NOTIFIER PARA HORARIO
// ============================================================================
//
// Un AsyncNotifier maneja estados asíncronos.
// build() se ejecuta automáticamente cuando la UI necesita los datos.
//
// state = AsyncLoading() → indica que está cargando
// AsyncValue.guard() → ejecuta algo y captura errores automáticamente
//
class HorarioNotifier extends AsyncNotifier<HorarioPeluqueria> {
  @override
  Future<HorarioPeluqueria> build() =>
      ref.read(obtenerHorarioProvider).ejecutar();

  Future<void> guardar(HorarioPeluqueria h) async {
    state = const AsyncLoading(); // indica que está guardando
    state = await AsyncValue.guard(
          () => ref.read(actualizarHorarioProvider).ejecutar(h),
    );
  }
}

// Provider que expone el Notifier a la UI
final horarioNotifierProvider =
AsyncNotifierProvider<HorarioNotifier, HorarioPeluqueria>(
    HorarioNotifier.new);

// ============================================================================
// NOTIFIER PARA FESTIVOS
// ============================================================================
class FestivosNotifier extends AsyncNotifier<List<Festivo>> {
  @override
  Future<List<Festivo>> build() =>
      ref.read(obtenerFestivosProvider).ejecutar();

  Future<void> recargar() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
          () => ref.read(obtenerFestivosProvider).ejecutar(),
    );
  }
}

final festivosNotifierProvider =
AsyncNotifierProvider<FestivosNotifier, List<Festivo>>(FestivosNotifier.new);

// ============================================================================
// NOTIFIER PARA CIERRE ANUAL
// ============================================================================
class CierreAnualNotifier extends AsyncNotifier<CierreAnual> {
  @override
  Future<CierreAnual> build() =>
      ref.read(obtenerCierreAnualProvider).ejecutar();

  Future<void> guardar(String? inicio, String? fin) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
          () => ref.read(actualizarCierreAnualProvider).ejecutar(inicio, fin),
    );
  }
}

final cierreAnualNotifierProvider =
AsyncNotifierProvider<CierreAnualNotifier, CierreAnual>(
    CierreAnualNotifier.new);

// ============================================================================
// NOTIFIER PARA CONFIGURACIÓN DE CORREO
// ============================================================================
class ConfigCorreoNotifier extends AsyncNotifier<ConfiguracionCorreo> {
  @override
  Future<ConfiguracionCorreo> build() =>
      ref.read(obtenerConfigCorreoProvider).ejecutar();

  Future<void> guardar(
      String host, int port, String user, String password, bool ssl) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
          () => ref.read(actualizarConfigCorreoProvider)
              .ejecutar(host, port, user, password, ssl),
    );
  }
}

final configCorreoNotifierProvider =
AsyncNotifierProvider<ConfigCorreoNotifier, ConfiguracionCorreo>(
    ConfigCorreoNotifier.new);

