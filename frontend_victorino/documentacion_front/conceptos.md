🧩 DTO (Data Transfer Object)
Un DTO es un objeto usado para transportar datos entre capas o entre la app y el backend.

Para qué sirve
Representa exactamente lo que envía o recibe tu API.
No contiene lógica, solo datos.
Evita mezclar modelos internos con estructuras del backend.

En tu proyecto
AuthResponseDto es un DTO:


AuthResponseDto.fromJson(resp. Data!)
El backend devuelve JSON → tú lo conviertes en un DTO → luego lo transformas en modelos internos (SesionUsuario).

El DTO es el mensajero entre tu API y tu app.



🧩 Provider de Riverpod
Un Provider es una forma de Riverpod de crear y compartir instancias entre capas de la app.

Para qué sirve
    Inyectar dependencias (repositorios, casos de uso, Dio…)
    Mantener una arquitectura limpia sin singletons globales.
    Permitir testear fácilmente.

Ejemplo tuyo

authRepositorioProvider = Provider<AuthRepositorio>((ref) {
final dio = ref.read(dioProvider);
return AuthRepositorioImpl(dio: dio);
});
Aquí Riverpod:

• Crea el repositorio.
• Le inyecta Dio.
• Lo deja disponible para cualquier parte de la app.

 Un Provider es una fábrica controlada por Riverpod.

🧩 Notifier (AsyncNotifier, StateNotifier, etc.)
Un Notifier es una clase que maneja estado + lógica para la UI.

Para qué sirve
• Gestionar estados de carga, éxito y error.
• Ejecutar casos de uso.
• Notificar a la UI cuando algo cambia.

Ejemplo tuyo

class RegistroNotifier extends AsyncNotifier<void> {

Este Notifier:
• Llama al caso de uso RegistrarCliente.
• Cambia el estado a AsyncLoading, AsyncData o AsyncError.
• La UI se actualiza automáticamente.

Un Notifier es el cerebro que conecta la UI con la lógica de negocio.



🧩 Capa de dominio (Casos de uso)
La capa de dominio contiene la lógica de negocio pura.
Aquí no hay HTTP, ni Riverpod, ni Flutter.

Para qué sirve
• Encapsular reglas de negocio.
• Ser independiente de frameworks.
• Ser testeable sin dependencias externas.

Ejemplo tuyo

class IniciarSesion {
Future<ResultadoAuth> ejecutar(Credenciales credenciales) async {
return _repositorio.iniciarSesion(credenciales);
}
}

El caso de uso:
• Recibe datos.
• Aplica validaciones si hace falta.
• Llama al repositorio.
• Devuelve un resultado.

El dominio es el corazón de tu app: reglas, no detalles técnicos.



🧩 Cómo encajan todos juntos (tu arquitectura limpia)
Aquí tienes tu flujo completo:

UI (pantalla)
↓
Notifier (maneja estado)
↓
Caso de uso (dominio)
↓
Repositorio (infraestructura)
↓
Dio (HTTP)
↓
Backend

Ejemplo real de tu app
• La UI llama a registroNotifierProvider.notifier.ejecutar().
• El Notifier llama al caso de uso RegistrarCliente.
• El caso de uso llama al repositorio AuthRepositorioImpl.
• El repositorio usa Dio para hacer la petición HTTP.
• El backend responde.
• El repositorio convierte el DTO en modelos internos.
• El Notifier actualiza el estado.
• La UI se actualiza.