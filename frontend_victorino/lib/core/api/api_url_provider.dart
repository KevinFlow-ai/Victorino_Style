// Provider que mantiene la URL base del backend en tiempo de ejecución.
//
// Flujo de inicialización:
//   main.dart lee flutter_secure_storage ANTES de runApp.
//   Si hay URL guardada → llama a setUrlInicial(url) antes de ProviderScope.
//   ApiUrlNotifier.build() devuelve _urlInicial, que ya tiene el valor correcto.
//
// Flujo de cambio:
//   AjustesServidorScreen llama a ref.read(apiBaseUrlProvider.notifier).cambiarUrl(url).
//   dioBaseProvider y dioProvider observan este provider y se recrean solos.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_endpoints.dart';

/// Clave de flutter_secure_storage compartida entre main.dart y AjustesServidorScreen.
const kClaveApiUrl = 'victorino_api_base_url';

// Valor inicial de la URL. main.dart lo sobreescribe antes de crear el ProviderScope.
String _urlInicial = ApiEndpoints.baseUrl;

/// Llamar desde main.dart ANTES de runApp si hay una URL guardada en disco.
void setUrlInicial(String url) {
  _urlInicial = url;
  // Sincronizamos también ApiEndpoints para que urlImagen() use la URL correcta
  // desde el primer frame, antes de que el ProviderScope arranque.
  ApiEndpoints.actualizarBaseUrl(url);
}

/// Notifier para la URL base del backend.
class ApiUrlNotifier extends Notifier<String> {
  @override
  String build() => _urlInicial;

  /// Actualiza la URL en memoria. La persistencia en disco la hace AjustesServidorScreen.
  void cambiarUrl(String nuevaUrl) {
    // Sincronizamos ApiEndpoints para que urlImagen() use la nueva URL inmediatamente.
    ApiEndpoints.actualizarBaseUrl(nuevaUrl);
    state = nuevaUrl;
  }
}

/// URL base activa del backend. Persiste entre sesiones y es reactiva:
/// dioBaseProvider y dioProvider se recrean automáticamente cuando cambia.
final apiBaseUrlProvider = NotifierProvider<ApiUrlNotifier, String>(
  ApiUrlNotifier.new,
);
