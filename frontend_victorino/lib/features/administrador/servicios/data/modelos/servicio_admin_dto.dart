// ============================================================
// ARCHIVO: servicio_admin_dto.dart
// CAPA: Data (Datos) — en Clean Architecture
// ============================================================
//
// ¿QUÉ ES ESTE ARCHIVO?
// ─────────────────────
// Este archivo define un "DTO" (Data Transfer Object).
// Un DTO es simplemente un "molde" que sirve para RECIBIR
// datos que vienen de AFUERA (en este caso, del backend
// hecho en Spring Boot) y convertirlos a algo que Flutter
// pueda usar.
//
// Piénsalo así:
//   El backend te manda un paquete (JSON).
//   Este DTO es el "desempacador" que sabe cómo abrir ese
//   paquete y organizar su contenido.
//
// ¿QUÉ ES JSON?
// ─────────────
// JSON es el formato que usan las apps para comunicarse.
// Se ve así (lo que manda Spring Boot):
//
//   {
//     "idServicio": 1,
//     "nombre": "Corte de cabello",
//     "descripcion": "Corte moderno",
//     "duracionMinutos": 30,
//     "precio": 15.50,
//     "fotoUrl": "https://...",
//     "activo": true
//   }
//
// ¿QUÉ ES "ServicioAdminResponse" (el espejo en Java)?
// ─────────────────────────────────────────────────────
// En el backend (Spring Boot), existe una clase llamada
// ServicioAdminResponse que tiene exactamente los mismos
// campos. Son "espejos" uno del otro.
// Flutter recibe el JSON → este DTO lo convierte a Dart.
//
// ============================================================
// DIAGRAMA DE CÓMO FLUYEN LOS DATOS (de atrás hacia adelante)
// ============================================================
//
//  ┌─────────────┐    HTTP (JSON)    ┌──────────────────────┐
//  │  Spring Boot │ ──────────────►  │  ServicioAdminDto    │
//  │  (Backend)   │                  │  (este archivo)      │
//  │              │                  │  .fromJson(json)     │
//  │  Clase Java: │                  └──────────┬───────────┘
//  │  Servicio    │                             │
//  │  AdminResp.. │                             │ .aEntidad()
//  └─────────────┘                             ▼
//                                   ┌──────────────────────┐
//                                   │  Servicio            │
//                                   │  (Entidad de dominio)│
//                                   │  servicio.dart       │
//                                   └──────────┬───────────┘
//                                             │
//                                             │ lo usa
//                                             ▼
//                                   ┌──────────────────────┐
//                                   │  UI / Pantallas      │
//                                   │  Flutter (Widgets)   │
//                                   └──────────────────────┘
//
// ============================================================
// DIAGRAMA DE CLEAN ARCHITECTURE (las capas de tu app)
// ============================================================
//
//  ┌──────────────────────────────────────────────┐
//  │  CAPA PRESENTACIÓN (UI)                      │
//  │  Pantallas, Widgets, Providers (Riverpod)    │
//  │  Lo que el usuario VE                        │
//  └───────────────────┬──────────────────────────┘
//                      │ usa
//  ┌───────────────────▼──────────────────────────┐
//  │  CAPA DOMINIO (Domain)                       │
//  │  Entidades (Servicio), Casos de uso,         │
//  │  Repositorios (interfaces/contratos)         │
//  │  El CORAZÓN de la app, no sabe nada de HTTP  │
//  └───────────────────┬──────────────────────────┘
//                      │ implementado por
//  ┌───────────────────▼──────────────────────────┐
//  │  CAPA DATOS (Data)  ◄── ESTÁS AQUÍ           │
//  │  DTOs, Repositorios concretos,               │
//  │  llamadas HTTP, base de datos                │
//  │  Habla con Spring Boot y MySQL               │
//  └──────────────────────────────────────────────┘
//
// ============================================================

// Importamos el archivo donde está definida la Entidad "Servicio".
// Una ENTIDAD es el objeto "puro" de tu dominio, sin basura
// de HTTP ni JSON. Solo tiene los datos del negocio.
import '../../domain/entidades/servicio.dart';

// Definimos la clase DTO.
// "class" en Dart es como una plantilla/molde para crear objetos.
class ServicioAdminDto {

  // ──────────────────────────────────────────────
  // CONSTRUCTOR
  // ──────────────────────────────────────────────
  // El "constructor" es lo que se llama cuando quieres
  // CREAR un objeto de este tipo.
  // "required" significa que ese campo ES OBLIGATORIO,
  // no puedes crear el objeto sin darlo.
  // Los que NO tienen "required" son OPCIONALES (pueden ser null).
  // "const" significa que si los valores no cambian, Dart
  // puede optimizar la memoria reutilizando el objeto.
  const ServicioAdminDto({
    required this.idServicio,       // ID único del servicio en MySQL
    required this.nombre,           // Nombre del servicio (ej: "Corte")
    required this.duracionMinutos,  // Cuánto dura en minutos
    required this.precio,           // Precio del servicio
    required this.fotoUrl,          // URL de la foto (en Firebase Storage, por ej.)
    required this.activo,           // ¿Está activo o desactivado?
    this.descripcion,               // Descripción (opcional, puede no venir)
  });

  // ──────────────────────────────────────────────
  // CAMPOS (atributos del objeto)
  // ──────────────────────────────────────────────
  // "final" significa que una vez asignado, NO se puede cambiar.
  // Esto es bueno porque los DTOs solo son para LEER datos,
  // no para modificarlos.

  final int idServicio;       // Número entero (int): 1, 2, 3...
  final String nombre;        // Texto (String): "Corte de cabello"
  final String? descripcion;  // El "?" significa que PUEDE ser null
  // (el backend puede no mandar descripción)
  final int duracionMinutos;  // Número entero: 30, 60, 90...
  final num precio;           // Número (num acepta int o double): 15.50
  final String fotoUrl;       // URL como texto: "https://..."
  final bool activo;          // Verdadero/Falso (true/false)

  // ──────────────────────────────────────────────
  // MÉTODOO DE FÁBRICA: fromJson
  // ──────────────────────────────────────────────
  // "factory" es un tipo especial de constructor que te permite
  // controlar CÓMO se crea el objeto.
  //
  // Este métodoo recibe el JSON del backend (como un Map de Dart)
  // y crea un ServicioAdminDto con esos datos.
  //
  // Map<String, dynamic> es como un diccionario:
  //   clave (String) → valor (cualquier tipo: int, String, bool...)
  //   Ejemplo: json['nombre'] te da "Corte de cabello"
  //
  // ¿CUÁNDO SE LLAMA?
  // Cuando tu repositorio recibe la respuesta HTTP de Spring Boot
  // y necesita convertir el JSON a un objeto Dart.
  factory ServicioAdminDto.fromJson(Map<String, dynamic> json) {
    return ServicioAdminDto(
      // (json['idServicio'] as num).toInt()
      // ────────────────────────────────────
      // json['idServicio'] extrae el valor con clave "idServicio"
      // "as num" le dice a Dart: "confía en mí, esto es un número"
      // .toInt() lo convierte a entero (por si viene como 1.0)
      idServicio: (json['idServicio'] as num).toInt(),

      // json['nombre'] as String
      // ────────────────────────
      // Extrae el texto. "as String" confirma que es texto.
      nombre: json['nombre'] as String,

      // json['descripcion'] as String?
      // ───────────────────────────────
      // El "?" al final significa que aceptamos null.
      // Si el backend no manda "descripcion", será null. ¡No hay error!
      descripcion: json['descripcion'] as String?,

      duracionMinutos: (json['duracionMinutos'] as num).toInt(),

      precio: json['precio'] as num,

      // (json['fotoUrl'] as String?) ?? ''
      // ────────────────────────────────────
      // El "??" es el operador "si es null, usa esto otro".
      // Si fotoUrl no viene o es null → usamos '' (texto vacío).
      // Así evitamos crashes por valores nulos.
      fotoUrl: (json['fotoUrl'] as String?) ?? '',

      activo: json['activo'] as bool,
    );
  }

  // ──────────────────────────────────────────────
  // MÉTODOO: aEntidad()
  // ──────────────────────────────────────────────
  // Este es el métoddo más IMPORTANTE del DTO.
  // Su trabajo es CONVERTIR el DTO (capa de datos)
  // a una ENTIDAD (capa de dominio).
  //
  // ¿Por qué hacemos esto?
  // ──────────────────────
  // En Clean Architecture, la capa de DOMINIO NO SABE
  // que existe HTTP, JSON, ni Spring Boot.
  // La entidad "Servicio" es un objeto limpio del negocio.
  // Este métodoo hace esa "traducción".
  //
  // Es como traducir de inglés a español:
  //   ServicioAdminDto (inglés/HTTP) → Servicio (español/dominio)
  //
  // La flecha "=>" es una función corta de una sola línea.
  // Es igual a escribir: { return Servicio(...); }
  Servicio aEntidad() => Servicio(
    id: idServicio,
    nombre: nombre,
    descripcion: descripcion,
    duracionMinutos: duracionMinutos,
    precio: precio,
    fotoUrl: fotoUrl,
    activo: activo,
  );
}

// ============================================================
// RESUMEN PARA NOVATOS — ¿QUÉ HACE ESTE ARCHIVO?
// ============================================================
//
//  1. Define la "forma" de los datos que llegan del backend.
//  2. Sabe cómo leer un JSON y convertirlo a un objeto Dart
//     (fromJson).
//  3. Sabe cómo convertirse a una Entidad de dominio
//     (aEntidad).
//
// ============================================================
// PREGUNTAS FRECUENTES
// ============================================================
//
//  ¿Qué es un Future?
//  ──────────────────
//  Un Future es una "promesa" de que algo va a pasar en el
//  futuro (como esperar la respuesta del servidor).
//  Ejemplo: cuando haces una llamada HTTP, no tienes la
//  respuesta de inmediato. Un Future te dice "cuando llegue
//  te aviso". Se usa con async/await.
//
//  ¿Qué es async/await?
//  ─────────────────────
//  async marca una función que puede "pausarse" a esperar.
//  await dice "espera aquí hasta que el Future termine".
//  Ejemplo:
//    Future<List<Servicio>> obtenerServicios() async {
//      final respuesta = await http.get(url); // espera la HTTP
//      return respuesta.data.map((j) => ServicioAdminDto.fromJson(j)
//                              .aEntidad()).toList();
//    }
//
//  ¿Qué es un State (estado)?
//  ───────────────────────────
//  El "estado" es la información que tiene una pantalla en
//  un momento dado. Por ejemplo: ¿está cargando? ¿hay error?
//  ¿ya llegaron los datos? Riverpod maneja esto con providers.
//
//  ¿Qué es un Provider?
//  ─────────────────────
//  Un Provider (de Riverpod) es un "proveedor de datos".
//  Guarda el estado y notifica a los widgets cuando cambia.
//  Así los widgets se redibujan solos cuando hay nuevos datos.
//
//  ¿Qué es providerOverride?
//  ──────────────────────────
//  Es cuando en los TESTS reemplazas un provider real por uno
//  falso. Útil para probar sin necesitar el servidor real.
//
// ============================================================
// RELACIÓN CON LOS OTROS ARCHIVOS DE TU APP
// ============================================================
//
//  servicio_admin_dto.dart  (ESTE ARCHIVO — capa Data)
//       │
//       │ usa (importa)
//       ▼
//  servicio.dart            (Entidad — capa Domain)
//       ▲
//       │ también usa
//  servicio_repository_impl.dart  (Repositorio concreto — Data)
//       │ implementa
//  servicio_repository.dart       (Contrato/interfaz — Domain)
//       ▲
//       │ usa
//  obtener_servicios_usecase.dart (Caso de uso — Domain)
//       ▲
//       │ usa
//  servicios_provider.dart        (Provider — Presentation)
//       ▲
//       │ escucha
//  servicios_screen.dart          (Widget/UI — Presentation)
//
// ============================================================
// RELACIÓN CON MYSQL Y SPRING BOOT
// ============================================================
//
//  MySQL (Base de datos)
//    tabla: servicios
//    columnas: id_servicio, nombre, descripcion,
//              duracion_minutos, precio, foto_url, activo
//         │
//         │ consulta SQL
//         ▼
//  Spring Boot (Backend Java)
//    Lee la tabla y crea ServicioAdminResponse.java
//    Lo convierte a JSON y lo manda por HTTP
//         │
//         │ HTTP GET /api/servicios   (con JWT en el header)
//         ▼
//  Flutter (este archivo)
//    ServicioAdminDto.fromJson(json) — desempaca el JSON
//    .aEntidad()                     — lo convierte a Servicio
//         │
//         ▼
//  Pantalla Flutter muestra la lista de servicios
//
// JWT: es el "ticket de acceso". Spring Boot lo verifica
// antes de responder. Sin el token válido, la petición falla.
// Firebase/FCM: cuando el admin activa/desactiva un servicio,
// podrías mandar una notificación push a los usuarios.



    /*

    En resumen con palabras simples:
    Este archivo es el "traductor" entre tu backend de Spring Boot y tu app Flutter.
    Spring Boot manda datos en formato JSON (como un diccionario), y este DTO
    sabe cómo leerlo (fromJson) y convertirlo a un objeto limpio que tu app
    entiende (aEntidad). Vive en la capa de Datos de tu arquitectura limpia,
    y su único trabajo es ese: recibir, desempacar y convertir. No hace
    cálculos, no llama al servidor, solo traduce.
     */





// ============================================================