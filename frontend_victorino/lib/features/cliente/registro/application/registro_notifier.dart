// Notifier de la pantalla de registro. Igual que LoginNotifier pero ejecutando
// el caso de uso de registro y devolviendo siempre rol=CLIENTE en éxito.
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/api_exception.dart';
import '../../../../core/errors/failure.dart';
import '../../../../shared/providers/sesion_provider.dart';
import '../../../login_admin_empleado_cliente/application/auth_providers.dart';
import '../../../login_admin_empleado_cliente/domain/repositorios/auth_repositorio.dart';
import '../domain/casos_uso/registrar_cliente.dart';



/*
RESUMEN DEL ARCHIVO
Este archivo define toda la lógica de presentación (capa application) para registrar un cliente usando Riverpod.
Su función es coordinar:

Obtener el caso de uso RegistrarCliente desde un provider.

Exponer un RegistroNotifier, que:

Gestiona el estado asíncrono del registro (AsyncNotifier).

Llama al caso de uso con los datos del formulario.

Maneja errores de validación (ApiException) y errores de servidor.

Si el registro es exitoso, establece la sesión del usuario.

Exponer un provider final (registroNotifierProvider) para que la UI pueda usarlo.

En resumen:
Este archivo conecta la UI con la lógica de negocio del registro, maneja estados de carga/error y establece la sesión cuando el registro es exitoso.


 */
final registrarClienteProvider = Provider<RegistrarCliente>((ref) {
  return RegistrarCliente(ref.read(authRepositorioProvider));
});

class RegistroNotifier extends AsyncNotifier<void> {
  // Notifier que maneja el estado del proceso de registro.
  // Extiende AsyncNotifier<void> porque no devuelve datos, solo estados.

  late final RegistrarCliente _registrar;
  // Campo privado donde guardaremos la instancia del caso de uso.

  @override
  Future<void> build() async {
    // Métoodo que se ejecuta automáticamente al inicializar el notifier.
    _registrar = ref.read(registrarClienteProvider);
    // Obtiene el caso de uso desde el provider.
  }

  // Devuelve true si el registro fue exitoso.
  Future<bool> ejecutar({
    required String nombre,
    required String apellidos,
    String? telefono,
    required String correo,
    required String password,
  }) async {
    state = const AsyncLoading();
    // Cambia el estado a "cargando" para que la UI muestre un spinner.

    try {
      // Llama al caso de uso con los datos del formulario.
      final resultado = await _registrar.ejecutar(DatosRegistro(
        nombre: nombre,
        apellidos: apellidos,
        telefono: telefono,
        correo: correo,
        password: password,
      ));

      // Si el registro fue exitoso, establece la sesión del usuario.
      await ref
          .read(sesionProvider.notifier)
          .establecerSesion(resultado.sesion, resultado.refreshToken, esLoginExplicito: true);

      state = const AsyncData(null);
      // Estado final: operación completada sin errores.

      return true;
      // Indica a la UI que el registro fue exitoso.

    } on ApiException catch (e, st) {
      // Captura errores de validación o errores controlados del backend.
      state = AsyncError(e.failure, st);
      // Actualiza el estado con el error para que la UI lo muestre.
      return false;

    } catch (e, st) {
      // Cualquier otro error inesperado.
      state = AsyncError(const FailureServidor(), st);
      // Error genérico de servidor.
      return false;
    }
  }
}

// Provider que expone el RegistroNotifier a la UI.
final registroNotifierProvider =
AsyncNotifierProvider<RegistroNotifier, void>(RegistroNotifier.new);
// La UI puede usar este provider para ejecutar el registro y observar su estado.
