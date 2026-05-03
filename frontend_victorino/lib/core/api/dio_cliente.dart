// Fábrica del cliente Dio configurado con baseUrl, timeouts y headers JSON.
// La inyección de los interceptores se hace en el provider para mantener este
// archivo libre de dependencias de Riverpod.
import 'package:dio/dio.dart';

import 'api_endpoints.dart';

/*
  Dio es una librería de Dart/Flutter para hacer peticiones HTTP, muy usada porque es más potente y flexible que http (la librería básica).
Piensa en Dio como un cliente HTTP avanzado que te permite:
  - Hacer peticiones GET, POST, PUT, DELETE, etc.
  - Manejar interceptores (para logs, tokens, refresco de sesión…).
  - Configurar timeouts, headers, baseUrl.
  - Cancelar peticiones.
  - Manejar errores de forma más completa.
  - Subir y descargar archivos con progreso.



  RESUMEN DEL ARCHIVO (explicación al comienzo)
Este archivo define la clase DioCliente, cuya única responsabilidad es crear y configurar una instancia de Dio lista para hacer peticiones HTTP a tu backend.

Su propósito es:
- Centralizar la configuración de red (timeouts, baseUrl, headers, tipo de respuesta).
- Asegurar que todas las peticiones usen la misma configuración.
- Definir reglas de validación de estado HTTP para que solo se consideren exitosas las respuestas 2xx.
- Evitar duplicar configuración en cada repositorio.

En resumen:
Este archivo crea un cliente HTTP estándar, consistente y seguro para toda la app.
 */


class DioCliente {
  const DioCliente._();
  // Constructor privado: evita que alguien instancie esta clase.
  // Solo se usa como contenedor estático.

  // Construye un Dio listo para usarse.
  static Dio crear() {
    return Dio(
      BaseOptions(
        // URL base de la API. Todas las rutas se construirán a partir de aquí.
        baseUrl: ApiEndpoints.baseUrl,

        // Tiempo máximo para establecer conexión con el servidor.
        connectTimeout: const Duration(seconds: 10),

        // Tiempo máximo para recibir la respuesta completa.
        receiveTimeout: const Duration(seconds: 15),

        // Tiempo máximo para enviar datos (por ejemplo, subir archivos).
        sendTimeout: const Duration(seconds: 10),

        // Indica que esperamos respuestas en formato JSON.
        responseType: ResponseType.json,

        // Tipo de contenido que enviamos por defecto.
        contentType: 'application/json',

        // Cabeceras comunes para todas las peticiones.
        headers: const {
          'Accept': 'application/json',
        },

        // Aceptamos solo códigos 2xx como éxito.
        // Cualquier otro código hará que Dio lance un error automáticamente.
        validateStatus: (s) => s != null && s >= 200 && s < 300,
      ),
    );
  }
}

