// Helpers centralizados de invalidación de providers del cliente.
//
// Existen para que cada mutación (crear/modificar/cancelar cita, etc.) no tenga
// que recordar qué providers refrescar. Llamando a `invalidarCitasCliente(ref)`
// tras cualquier cambio en citas, todas las vistas que las muestren se recargarán
// automáticamente la próxima vez que se lean.
//
// También se invocan desde el shell al cambiar de pestaña y al volver del
// background, para garantizar que el cliente siempre vea datos frescos sin
// pull-to-refresh manual.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../notificaciones/application/notificaciones_notifier.dart';
import '../../historial/application/historial_providers.dart';
import '../../home/application/home_providers.dart';
import '../../perfil/application/perfil_providers.dart';
import 'catalogo_provider.dart';

// Invalida todo lo que depende de las citas del cliente: próxima cita en el
// Home y la lista del Historial. Llamar tras crear, modificar o cancelar.
void invalidarCitasCliente(WidgetRef ref) {
  ref.invalidate(proximaCitaProvider);
  ref.invalidate(historialNotifierProvider);
}

// Invalida los providers que alimentan una pestaña concreta del shell del
// cliente. Se llama desde el shell al cambiar de pestaña y al volver del
// background, para que la pantalla siempre muestre datos frescos.
void invalidarTabCliente(WidgetRef ref, int indice) {
  switch (indice) {
    case 0: // Inicio
      ref.invalidate(proximaCitaProvider);
      ref.invalidate(notificacionesNotifierProvider);
      ref.invalidate(serviciosCatalogoProvider);
      ref.invalidate(empleadosCatalogoProvider);
      break;
    case 1: // Reservar
      ref.invalidate(proximaCitaProvider);
      break;
    case 2: // Historial
      ref.invalidate(historialNotifierProvider);
      break;
    case 3: // Perfil
      ref.invalidate(perfilNotifierProvider);
      break;
  }
}
