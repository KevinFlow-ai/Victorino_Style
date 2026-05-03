// Excepción que envuelve un Failure para poder lanzarse desde el repositorio
// y atraparse en el caso de uso o en el notifier.
//
// La UI no la ve directamente: los Notifier la convierten en AsyncError(Failure).
import 'failure.dart';
// Importa la clase Failure, que contiene la información del error (mensaje, detalles, etc.).


/*
Un Failure es un objeto que representa un error de dominio, es decir, una forma estructurada y
tipada de describir qué salió mal sin depender directamente de excepciones del sistema o mensajes sueltos.

¿Qué es exactamente un Failure?
En términos prácticos:
Es una clase que contiene información sobre un error: mensaje código detalles stacktrace (a veces)
Se usa para transportar errores de forma controlada entre capas (repositorio → caso de uso → UI).
Evita lanzar excepciones genéricas y permite manejar errores de forma predecible.


*****RESUMEN DEL ARCHIVO****
Este archivo define la clase ApiException, una excepción personalizada que se usa en la capa de datos y dominio para envolver un Failure.

Su propósito es:

Permitir que los repositorios lancen errores de forma controlada.

Transportar un objeto Failure con información detallada del error.

Ser capturada por los casos de uso o notifiers, que luego transforman esta excepción en un estado de error para la UI.

Evitar que la UI tenga que manejar excepciones directamente; solo recibe Failure.

En resumen:
ApiException es un contenedor seguro para errores de backend o validación, que permite mantener una arquitectura limpia y desacoplada.
 */

class ApiException implements Exception {
  // Declara una excepción personalizada que implementa la interfaz Exception.

  ApiException(this.failure);
  // Constructor que recibe un Failure y lo almacena.
  // Esto permite transportar información detallada del error.

  final Failure failure;
  // Campo que guarda el Failure asociado a esta excepción.

  @override
  String toString() => 'ApiException(${failure.mensaje})';
// Sobrescribe toString() para mostrar un mensaje legible en logs o debugging.
// Muestra el mensaje del Failure incluido.
}
