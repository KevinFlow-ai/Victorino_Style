// Wrapper sobre flutter_secure_storage para guardar/leer datos sensibles de la sesión.
//
// Qué se guarda y dónde:
// - refresh_token : única credencial persistente. NUNCA en SharedPreferences.
// - id_usuario    : para que el router pueda decidir antes de pedir al backend.
// - rol           : permite redirigir a la home correcta sin esperar al refresh.
//
// El access token NO se guarda aquí: vive solo en memoria (Riverpod). Si el usuario
// reinicia la app, se obtiene uno nuevo llamando a /auth/refresh.
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  SecureStorage(this._storage);

  // Implementación inyectada para poder mockearla en tests.
  final FlutterSecureStorage _storage;

  // Claves de almacenamiento. Se centralizan aquí para evitar errores de tipeo.
  static const _claveRefresh = 'victorino_refresh_token';
  static const _claveIdUsuario = 'victorino_id_usuario';
  static const _claveRol = 'victorino_rol';
  // Estas claves se usan para leer/escribir valores en el almacenamiento seguro.

  // Guarda el bloque completo tras un login/registro o tras un refresh exitoso.
  Future<void> guardarSesion({
    required String refreshToken,
    required int idUsuario,
    required String rol,
  }) async {
    await _storage.write(key: _claveRefresh, value: refreshToken);
    await _storage.write(key: _claveIdUsuario, value: idUsuario.toString()); // Guarda el ID del usuario como string
    await _storage.write(key: _claveRol, value: rol); // Guarda el rol del usuario.
  }

  // Devuelve el refresh token o null si no hay sesión guardada.
  Future<String?> leerRefreshToken() => _storage.read(key: _claveRefresh); // Métoodo directo: lee el valor asociado a la clave del refresh token.

  // Devuelve el id del usuario en BD (parseado a int) o null.
  Future<int?> leerIdUsuario() async {
    final crudo = await _storage.read(key: _claveIdUsuario);
    // Lee el valor como string.

    return crudo == null ? null : int.tryParse(crudo);
    // Si es null → no hay sesión.
    // Si existe → intenta convertirlo a int.
  }

  // Devuelve el rol guardado (CLIENTE, EMPLEADO, ADMINISTRADOR) o null.
  Future<String?> leerRol() => _storage.read(key: _claveRol);
  // Lee el rol directamente desde el almacenamiento seguro.

  // Borra los tres campos. Se invoca al hacer logout o cuando el refresh falla.
  Future<void> limpiarSesion() async {
    await _storage.delete(key: _claveRefresh);
    await _storage.delete(key: _claveIdUsuario);
    await _storage.delete(key: _claveRol);
  }

  // Atajo: ¿hay datos persistidos suficientes para considerar que existe sesión?
  Future<bool> haySesionPersistida() async {
    final refresh = await leerRefreshToken();
    return refresh != null && refresh.isNotEmpty;
  }
}

/*

RESUMEN DEL ARCHIVO
Este archivo define la clase SecureStorage, un wrapper sobre flutter_secure_storage
que se encarga de guardar, leer y borrar datos sensibles de la sesión del usuario.

Su propósito es:

1) Guardar de forma segura:
  refresh_token → única credencial persistente.
  id_usuario → para que el router decida si hay sesión antes de llamar al backend.
  rol → para redirigir al usuario a su home correcta sin esperar al refresh.

2)No guardar nunca el access token, ya que:
  vive solo en memoria (Riverpod),
  se renueva al reiniciar la app mediante /auth/refresh.

3) Proveer métodos simples para:
  guardar sesión,
  leer datos individuales,
  borrar sesión,
  comprobar si existe sesión persistida.

En resumen:
   Esta clase centraliza y protege toda la información sensible de sesión, usando almacenamiento seguro cifrado.




Un wrapper, en este contexto, es una clase que envuelve otra librería para darle una
interfaz más simple, controlada y adaptada a las necesidades de tu aplicación.

¿Qué significa “wrapper” según tu descripción?
En tu archivo, SecureStorage actúa como un wrapper sobre flutter_secure_storage.
Eso quiere decir:
  No usas directamente flutter_secure_storage en toda la app.
  En su lugar, creas una capa intermedia (el wrapper) que:
    centraliza la lógica,
    impone reglas de seguridad,
    expone solo los métodos que tú quieres permitir.

En resumen claro:
Un wrapper es una capa protectora y simplificadora.
En tu caso:

SecureStorage es una clase que envuelve flutter_secure_storage para manejar
 de forma segura y consistente toda la información persistente de la sesión del usuario.
 */