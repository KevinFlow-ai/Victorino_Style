// Providers del submódulo métricas.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../shared/providers/dio_provider.dart';
import '../data/repositorios/metricas_repositorio_impl.dart';
import '../domain/casos_uso/obtener_metricas.dart';
import '../domain/entidades/metricas_resumen.dart';
import '../domain/repositorios/metricas_repositorio.dart';

// ============================================================================
// EXPLICACIÓN
// ============================================================================
//
// Este archivo usa algo llamado "Riverpod", que es una herramienta que ayuda
// a organizar datos y lógica en una app Flutter. No necesitas saber Flutter,
// solo imagina que Riverpod es como un sistema que guarda información y la
// actualiza cuando hace falta.
//
// Piensa en Providers como "cajas" que guardan cosas.
// Piensa en Notifiers como "cajas inteligentes" que pueden cambiar su contenido.
// Piensa en AsyncNotifier como "cajas inteligentes que tardan en llenarse"
// porque tienen que pedir datos a internet.
//
// ============================================================================
// 1. Provider del repositorio de métricas
// ============================================================================
//
// Aquí creamos una caja (Provider) que sabe cómo obtener datos desde internet.
// Para eso usa algo llamado "Dio", que es simplemente una herramienta para
// hacer peticiones HTTP (pedir datos a un servidor).
//
// metricasRepositorioProvider = caja que contiene un objeto que sabe pedir
// métricas al servidor.
//
final metricasRepositorioProvider = Provider<MetricasRepositorio>(
      (ref) => MetricasRepositorioImpl(dio: ref.read(dioProvider)),
);

// ============================================================================
// 2. Provider del caso de uso "obtener métricas"
// ============================================================================
//
// Aquí creamos otra caja que contiene una función especial llamada
// "ObtenerMetricas". Esa función sabe cómo pedir las métricas usando el
// repositorio anterior.
//
final obtenerMetricasProvider = Provider(
      (ref) => ObtenerMetricas(ref.read(metricasRepositorioProvider)),
);

// ============================================================================
// 3. Clase para guardar un rango de fechas
// ============================================================================
//
// Esta clase solo guarda dos fechas: una de inicio y otra de fin.
// Es como una cajita que dice: "quiero datos desde esta fecha hasta esta otra".
//
class RangoFechas {
  const RangoFechas({required this.inicio, required this.fin});
  final DateTime inicio;
  final DateTime fin;
}

// ============================================================================
// 4. Notifier para manejar el rango de fechas
// ============================================================================
//
// Un Notifier es una caja inteligente que puede cambiar su contenido.
// Aquí guardamos el rango de fechas que el administrador selecciona.
//
// Cuando la app inicia, ponemos un rango por defecto:
// - inicio: hace 2 meses
// - fin: hoy
//
// Y tenemos un método "establecer" para cambiar ese rango.
//
class RangoFechasNotifier extends Notifier<RangoFechas> {
  @override
  RangoFechas build() => RangoFechas(
    inicio: DateTime(DateTime.now().year, DateTime.now().month - 2, 1),
    fin: DateTime.now(),
  );

  void establecer(RangoFechas nuevo) => state = nuevo;
}

// Esta es la caja que contiene el rango de fechas actual.
final rangoFechasProvider =
NotifierProvider<RangoFechasNotifier, RangoFechas>(RangoFechasNotifier.new);

// ============================================================================
// 5. AsyncNotifier para cargar métricas desde internet
// ============================================================================
//
// Aquí viene lo más importante.
//
// MetricasNotifier es una caja inteligente que:
// - tarda en llenarse (porque pide datos a internet)
// - guarda un objeto llamado "MetricasResumen"
//
// Cuando se crea (build), hace lo siguiente:
// 1. Mira el rango de fechas seleccionado.
// 2. Llama al caso de uso "obtener métricas".
// 3. Devuelve las métricas obtenidas.
//
// También tiene un métodoo "recargar" que vuelve a pedir los datos.
//
// AsyncNotifier funciona así:
// - state = AsyncLoading() → significa "estoy cargando"
// - state = AsyncData(...) → significa "ya tengo los datos"
// - state = AsyncError(...) → significa "hubo un error"
//
class MetricasNotifier extends AsyncNotifier<MetricasResumen> {
  @override
  Future<MetricasResumen> build() async {
    // Obtenemos el rango de fechas actual
    final r = ref.watch(rangoFechasProvider);

    // Pedimos las métricas al servidor usando las fechas formateadas
    return ref.read(obtenerMetricasProvider).ejecutar(
      fechaInicio: DateFormat('yyyy-MM-dd').format(r.inicio),
      fechaFin: DateFormat('yyyy-MM-dd').format(r.fin),
    );
  }

  // Métodoo para volver a cargar los datos manualmente
  Future<void> recargar() async {
    // Indicamos que estamos cargando
    state = const AsyncLoading();

    // Intentamos obtener los datos otra vez
    state = await AsyncValue.guard(() async {
      final r = ref.read(rangoFechasProvider);
      return ref.read(obtenerMetricasProvider).ejecutar(
        fechaInicio: DateFormat('yyyy-MM-dd').format(r.inicio),
        fechaFin: DateFormat('yyyy-MM-dd').format(r.fin),
      );
    });
  }
}

// ============================================================================
// 6. Provider final que expone el AsyncNotifier
// ============================================================================
//
// Esta es la caja final que la app usará para leer las métricas.
// Cuando alguien la lea, Riverpod ejecutará el AsyncNotifier y traerá los datos.
//
final metricasNotifierProvider =
AsyncNotifierProvider<MetricasNotifier, MetricasResumen>(MetricasNotifier.new);

