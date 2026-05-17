// Providers del submódulo Perfil del cliente.
// - Inyección del repositorio HTTP.
// - Casos de uso.
// - AsyncNotifier del perfil con métodos para editar, foto, pwd, push y eliminar.

import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/providers/dio_provider.dart';
import '../../../../shared/providers/sesion_provider.dart';
import '../data/repositorios/perfil_repositorio_impl.dart';
import '../domain/casos_uso/cambiar_password.dart';
import '../domain/casos_uso/configurar_push.dart';
import '../domain/casos_uso/editar_perfil.dart';
import '../domain/casos_uso/eliminar_cuenta.dart';
import '../domain/casos_uso/obtener_perfil.dart';
import '../domain/casos_uso/subir_foto.dart';
import '../domain/entidades/perfil_cliente.dart';
import '../domain/repositorios/perfil_repositorio.dart';

// ---- inyección -----------------------------------------------------------
final perfilRepositorioProvider = Provider<PerfilRepositorio>((ref) {
  return PerfilRepositorioImpl(dio: ref.read(dioProvider));
});

final obtenerPerfilProvider = Provider(
  (ref) => ObtenerPerfil(ref.read(perfilRepositorioProvider)),
);
final editarPerfilProvider = Provider(
  (ref) => EditarPerfil(ref.read(perfilRepositorioProvider)),
);
final subirFotoPerfilProvider = Provider(
  (ref) => SubirFoto(ref.read(perfilRepositorioProvider)),
);
final cambiarPasswordProvider = Provider(
  (ref) => CambiarPassword(ref.read(perfilRepositorioProvider)),
);
final configurarPushProvider = Provider(
  (ref) => ConfigurarPush(ref.read(perfilRepositorioProvider)),
);
final eliminarCuentaProvider = Provider(
  (ref) => EliminarCuenta(ref.read(perfilRepositorioProvider)),
);

// ---- AsyncNotifier del perfil --------------------------------------------
class PerfilNotifier extends AsyncNotifier<PerfilCliente?> {
  @override
  Future<PerfilCliente?> build() async {
    // Solo se reconstruye cuando cambia el idUsuario (login / logout).
    // .select() evita que una renovación del access token vacíe el perfil.
    final idUsuario = ref.watch(
      sesionProvider.select((s) => s.value?.idUsuario),
    );
    if (idUsuario == null) return null;
    // Leer el rol sin observar — no cambia dentro de una misma sesión.
    final rol = ref.read(sesionProvider).value?.rol;
    if (rol != 'CLIENTE') return null;
    return ref.read(obtenerPerfilProvider).ejecutar();
  }

  Future<void> recargar() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(obtenerPerfilProvider).ejecutar(),
    );
  }

  Future<void> editar(DatosPerfilCliente datos) async {
    final nuevo = await ref.read(editarPerfilProvider).ejecutar(datos);
    state = AsyncData(nuevo);
  }

  Future<void> subirFoto(File archivo) async {
    final actual = state.value;
    if (actual == null) return;
    final rutaNueva = await ref.read(subirFotoPerfilProvider).ejecutar(archivo);
    // Actualización local optimista de la foto.
    state = AsyncData(
      PerfilCliente(
        idCliente: actual.idCliente,
        nombre: actual.nombre,
        apellidos: actual.apellidos,
        correo: actual.correo,
        telefono: actual.telefono,
        fotoUrl: rutaNueva,
        pushActiva: actual.pushActiva,
      ),
    );
  }

  Future<void> cambiarPassword({required String actual, required String nueva}) {
    return ref.read(cambiarPasswordProvider).ejecutar(actual: actual, nueva: nueva);
  }

  Future<void> configurarPush(bool pushActiva) async {
    final actual = state.value;
    if (actual == null) return;
    await ref.read(configurarPushProvider).ejecutar(pushActiva);
    state = AsyncData(
      PerfilCliente(
        idCliente: actual.idCliente,
        nombre: actual.nombre,
        apellidos: actual.apellidos,
        correo: actual.correo,
        telefono: actual.telefono,
        fotoUrl: actual.fotoUrl,
        pushActiva: pushActiva,
      ),
    );
  }

  Future<void> eliminarCuenta(String password) {
    return ref.read(eliminarCuentaProvider).ejecutar(password);
  }
}

final perfilNotifierProvider =
    AsyncNotifierProvider<PerfilNotifier, PerfilCliente?>(PerfilNotifier.new);
