import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entidades/notificacion.dart';
import '../domain/casos_uso/marcar_leida.dart';
import '../domain/casos_uso/obtener_bandeja.dart';
import 'notificaciones_providers.dart';
import '../../../shared/providers/sesion_provider.dart';

// Esto es un AsyncNotifier que lo que hace es gestionar la bandeja de notificaciones in-app.
// También lo que hace es exponer métodos para recargar y marcar como leída sin recargar toda la lista.
class NotificacionesNotifier extends AsyncNotifier<List<Notificacion>> {
  late final ObtenerBandeja _obtenerBandeja;
  late final MarcarLeida _marcarLeida;

  @override
  Future<List<Notificacion>> build() async {
    _obtenerBandeja = ref.read(obtenerBandejaProvider);
    _marcarLeida    = ref.read(marcarLeidaProvider);

    final sesion = ref.watch(sesionProvider).value;
    if (sesion == null) return const [];
    // Aquí lo que se hace es que el JWT se envíe automáticamente; y el backend extrae el idUsuario del token.
    return _obtenerBandeja.ejecutar();
  }

  /// Esto lo que hace es racargar la bandeja completa del backend. Se puede usar para pull-to-refresh o para recargar tras marcar como leída.
  Future<void> recargar() async {
    final sesion = ref.read(sesionProvider).value;
    if (sesion == null) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _obtenerBandeja.ejecutar());
  }

  /// Esto lo que hace es que se marque la notificación como leída localmente (optimistic update) y
  /// se confirme en el backend. Si el backend falla, se revierte esto.
  Future<void> marcarComoLeida(int idNotificacion) async {
    final listaActual = state.value;
    if (listaActual == null) return;

    // Esto sirve para hacer una actualización de la fecha de lectura a ahora.
    state = AsyncData(listaActual.map((n) {
      if (n.id == idNotificacion) return n.copyWith(fechaLectura: DateTime.now());
      return n;
    }).toList());

    try {
      await _marcarLeida.ejecutar(idNotificacion);
    } catch (_) {
      // Si esto falla, revertimos al estado anterior.
      state = AsyncData(listaActual);
    }
  }

  /// Aquí se maneja el número de notificaciones no leídas, que se puede mostrar como badge en el icono de notificaciones.
  int get noLeidas =>
      state.value?.where((n) => !n.esLeida).length ?? 0;
}

final notificacionesNotifierProvider =
AsyncNotifierProvider<NotificacionesNotifier, List<Notificacion>>(
  NotificacionesNotifier.new,
);

