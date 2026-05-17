import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entidades/notificacion.dart';
import '../domain/casos_uso/marcar_leida.dart';
import '../domain/casos_uso/obtener_bandeja.dart';
import 'notificaciones_providers.dart';
import '../../../shared/providers/sesion_provider.dart';

// AsyncNotifier que gestiona la bandeja de notificaciones in-app.
// Expone métodos para recargar y marcar como leída sin recargar toda la lista.
class NotificacionesNotifier extends AsyncNotifier<List<Notificacion>> {
  // NO son late final: Riverpod puede llamar a build() varias veces sobre la
  // misma instancia del notifier (p.ej. al cambiar de pestaña y volver).
  // Con late final, el segundo intento de asignación lanzaría LateInitializationError.
  ObtenerBandeja? _obtenerBandeja;
  MarcarLeida? _marcarLeida;

  @override
  Future<List<Notificacion>> build() async {
    // Reasignación segura en cada llamada a build().
    _obtenerBandeja = ref.read(obtenerBandejaProvider);
    _marcarLeida = ref.read(marcarLeidaProvider);

    // Solo se reconstruye cuando cambia el idUsuario (login / logout).
    // Usar .select() evita que una renovación del access token (actualizarAccessToken)
    // vacíe la bandeja, ya que el token cambia pero el idUsuario sigue siendo el mismo.
    final idUsuario = ref.watch(
      sesionProvider.select((s) => s.value?.idUsuario),
    );
    if (idUsuario == null) return const [];
    // El JWT se envía automáticamente; el backend extrae el idUsuario del token.
    return _obtenerBandeja!.ejecutar();
  }

  /// Recarga la bandeja completa del backend.
  /// Útil para pull-to-refresh o para recargar tras recibir una notificación push.
  Future<void> recargar() async {
    final sesion = ref.read(sesionProvider).value;
    if (sesion == null) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _obtenerBandeja!.ejecutar());
  }

  /// Marca la notificación como leída localmente (optimistic update) y
  /// la confirma en el backend. Si el backend falla, revierte el estado.
  Future<void> marcarComoLeida(int idNotificacion) async {
    final listaActual = state.value;
    if (listaActual == null) return;

    // Actualización optimista: marcamos como leída de inmediato.
    state = AsyncData(listaActual.map((n) {
      if (n.id == idNotificacion) return n.copyWith(fechaLectura: DateTime.now());
      return n;
    }).toList());

    try {
      await _marcarLeida!.ejecutar(idNotificacion);
    } catch (_) {
      // Si falla, revertimos al estado anterior.
      state = AsyncData(listaActual);
    }
  }

  /// Número de notificaciones no leídas. Útil para mostrar badge en el icono.
  int get noLeidas =>
      state.value?.where((n) => !n.esLeida).length ?? 0;
}

final notificacionesNotifierProvider =
AsyncNotifierProvider<NotificacionesNotifier, List<Notificacion>>(
  NotificacionesNotifier.new,
);

