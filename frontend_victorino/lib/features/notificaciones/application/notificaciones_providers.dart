import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/providers/dio_provider.dart';
import '../data/repositorios/notificaciones_repositorio_impl.dart';
import '../domain/casos_uso/marcar_leida.dart';
import '../domain/casos_uso/obtener_bandeja.dart';
import '../domain/casos_uso/registrar_device_token.dart';
import '../domain/repositorios/notificacion_repositorio.dart';

final notificacionesRepositorioProvider =
Provider<NotificacionesRepositorio>((ref) {
  return NotificacionesRepositorioImpl(dio: ref.read(dioProvider));
});

final obtenerBandejaProvider = Provider<ObtenerBandeja>(
      (ref) => ObtenerBandeja(ref.read(notificacionesRepositorioProvider)),
);

final marcarLeidaProvider = Provider<MarcarLeida>(
      (ref) => MarcarLeida(ref.read(notificacionesRepositorioProvider)),
);

final registrarDeviceTokenProvider = Provider<RegistrarDeviceToken>(
      (ref) => RegistrarDeviceToken(ref.read(notificacionesRepositorioProvider)),
);

