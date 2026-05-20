// Notifier de la pantalla de login.
//
// Estado: AsyncValue<void>. La sesión real vive en sesionProvider; aquí solo
// gestionamos el "loading / error" del proceso de iniciar sesión.
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/api_exception.dart';
import '../../../core/errors/failure.dart';
import '../../../shared/providers/sesion_provider.dart';
import '../domain/entidades/credenciales.dart';
import 'auth_providers.dart';

class LoginNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {
    // Estado inicial: nada hecho aún.
    // No capturamos _iniciarSesion aquí para que cada llamada a ejecutar()
    // obtenga siempre el caso de uso con la URL más reciente.
  }

  // Devuelve el rol tras un login exitoso para que la UI sepa adónde redirigir.
  // En caso de error, deja state en AsyncError(Failure) y devuelve null.
  Future<String?> ejecutar({required String correo, required String password}) async {
    // Obtenemos el caso de uso en el momento de la llamada: así, si el usuario
    // cambió la URL en Ajustes justo antes de pulsar "Iniciar sesión", el login
    // usa el Dio con la URL correcta (no el que se capturó al crear el notifier).
    final iniciarSesion = ref.read(iniciarSesionProvider);

    state = const AsyncLoading();
    try {
      final resultado = await iniciarSesion.ejecutar(
        Credenciales(correo: correo, password: password),
      );
      // Persistimos el refresh y actualizamos sesión global.
      // esLoginExplicito=true → el backend enviará la notificación de bienvenida.

      await ref
          .read(sesionProvider.notifier)
          .establecerSesion(resultado.sesion, resultado.refreshToken, esLoginExplicito: true);

      state = const AsyncData(null);
      return resultado.sesion.rol;
    } on ApiException catch (e, st) {
      state = AsyncError(e.failure, st);
      return null;
    } catch (e, st) {
      state = AsyncError(const FailureServidor(), st);
      return null;
    }
  }
}

final loginNotifierProvider =
    AsyncNotifierProvider<LoginNotifier, void>(LoginNotifier.new);
