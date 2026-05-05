// ============================================================
// ARCHIVO: servicio_admin_repositorio_impl.dart
// CAPA: Data (Datos) — en Clean Architecture
// ============================================================
//
// ¿QUÉ ES ESTE ARCHIVO?
// ─────────────────────
// Este archivo es la IMPLEMENTACIÓN CONCRETA del repositorio.
// Es el que realmente HACE las llamadas HTTP a Spring Boot.
//
// En Clean Architecture hay dos partes del repositorio:
//
//   1. El CONTRATO (interfaz) → servicio_admin_repositorio.dart
//      Solo dice QUÉ se puede hacer (listar, crear, editar...)
//      Vive en la capa de DOMINIO. No sabe nada de HTTP.
//
//   2. La IMPLEMENTACIÓN (este archivo) → ...impl.dart
//      Dice CÓMO se hace (con Dio, HTTP, JSON...)
//      Vive en la capa de DATOS.
//
// Analogía del mundo real:
//   Contrato   = El menú del restaurante (dice qué puedes pedir)
//   Impl       = La cocina (hace realmente la comida)
//
// ============================================================
// DIAGRAMA GENERAL — ¿DÓNDE ENCAJA ESTE ARCHIVO?
// ============================================================
//
//  ┌─────────────────────────────────────────────────────┐
//  │  UI / Pantallas Flutter                             │
//  └────────────────────┬────────────────────────────────┘
//                       │ usa
//  ┌────────────────────▼────────────────────────────────┐
//  │  Provider (Riverpod)                                │
//  └────────────────────┬────────────────────────────────┘
//                       │ usa
//  ┌────────────────────▼────────────────────────────────┐
//  │  Caso de Uso (UseCase)  — capa Domain               │
//  └────────────────────┬────────────────────────────────┘
//                       │ usa el CONTRATO
//  ┌────────────────────▼────────────────────────────────┐
//  │  ServicioAdminRepositorio  (interfaz/contrato)      │
//  │  — capa Domain                                      │
//  └────────────────────┬────────────────────────────────┘
//                       │ implementado por
//  ┌────────────────────▼────────────────────────────────┐
//  │  ServicioAdminRepositorioImpl  ◄── ESTÁS AQUÍ       │
//  │  — capa Data                                        │
//  │  Usa Dio para llamar a Spring Boot via HTTP         │
//  └────────────────────┬────────────────────────────────┘
//                       │ recibe JSON, lo convierte con
//  ┌────────────────────▼────────────────────────────────┐
//  │  ServicioAdminDto  (DTO)                            │
//  │  .fromJson()  →  .aEntidad()                        │
//  └─────────────────────────────────────────────────────┘
//
// ============================================================
// DIAGRAMA HTTP — ¿QUÉ RUTAS LLAMA AL BACKEND?
// ============================================================
//
//  Flutter (este archivo)          Spring Boot (backend)
//  ──────────────────────          ─────────────────────
//  listar()      GET  ──────────►  /api/admin/servicios
//  obtener(id)   GET  ──────────►  /api/admin/servicios/{id}
//  crear()       POST ──────────►  /api/admin/servicios
//  editar(id)    PUT  ──────────►  /api/admin/servicios/{id}
//  darBaja(id)   DELETE ────────►  /api/admin/servicios/{id}
//  subirFoto(id) POST ──────────►  /api/admin/servicios/{id}/foto
//
//  Todas estas rutas están protegidas con JWT.
//  Dio manda el token automáticamente en el header:
//  Authorization: Bearer <token>
//
// ============================================================

// dart:io nos da acceso a la clase "File" (archivos del celular).
// La usamos para subir la foto del servicio.
import 'dart:io';

// Dio es la librería que usamos para hacer llamadas HTTP.
// Es como "fetch" en JavaScript o RestTemplate en Java.
// Se agrega en pubspec.yaml como dependencia.
import 'package:dio/dio.dart';

// ApiEndpoints es una clase con todas las URLs del backend
// escritas en un solo lugar. Así si cambia una URL, solo
// la cambias en un archivo, no en 20 lugares.
import '../../../../../core/api/api_endpoints.dart';

// ApiException es nuestra clase personalizada de error.
// En vez de dejar que Dio lance errores raros, los
// "envolvemos" en ApiException para manejarlos mejor.
import '../../../../../core/errors/api_exception.dart';

// ErrorMapper convierte errores técnicos de Dio/HTTP
// en mensajes entendibles para el usuario.
// Ej: DioException(404) → "Servicio no encontrado"
import '../../../../../core/errors/error_mapper.dart';

// La Entidad de dominio (el objeto limpio del negocio).
import '../../domain/entidades/servicio.dart';

// El CONTRATO que esta clase debe cumplir.
// "implements" significa: "juro que voy a implementar
// todos los métodos que define ese contrato".
import '../../domain/repositorios/servicio_admin_repositorio.dart';

// El DTO que convierte JSON → Entidad.
import '../modelos/servicio_admin_dto.dart';




// ──────────────────────────────────────────────────────────
// CLASE PRINCIPAL
// ──────────────────────────────────────────────────────────
// "implements ServicioAdminRepositorio" significa que esta
// clase PROMETE implementar todos los métodos del contrato.
// Si le falta alguno, Dart lanza un error de compilación.

class ServicioAdminRepositorioImpl implements ServicioAdminRepositorio {
  // ──────────────────────────────────────────────────────
  // CONSTRUCTOR
  // ──────────────────────────────────────────────────────
  // Recibe Dio (el cliente HTTP) desde afuera.
  // Esto se llama INYECCIÓN DE DEPENDENCIAS:
  // en vez de crear Dio aquí dentro, nos lo "pasan"
  // desde afuera. Ventaja: en los tests podemos pasar
  // un Dio FALSO que no hace llamadas reales.
  //
  // ErrorMapper? con "?" significa que es opcional.
  // Si no nos pasan uno, usamos uno por defecto: ErrorMapper()
  //
  // La sintaxis ": dio = dio, errorMapper = ..." es el
  // "initializer list" de Dart, que asigna los campos
  // ANTES de que el constructor termine.
  ServicioAdminRepositorioImpl({required Dio dio, ErrorMapper? errorMapper})
      : _dio = dio,
        _errorMapper = errorMapper ?? const ErrorMapper();

  // Guardamos las dependencias como campos finales.
  // "final" = no se pueden reasignar después.
  final Dio _dio;
  final ErrorMapper _errorMapper;


  // ──────────────────────────────────────────────────────
  // MÉTODOO: listar
  // ──────────────────────────────────────────────────────
  // Obtiene la lista de todos los servicios del backend.
  //
  // @override = estoy implementando este métodoo del contrato.
  //
  // Future<List<Servicio>> = "en el futuro, te daré una lista
  //   de objetos Servicio". Future porque la llamada HTTP
  //   no es instantánea, hay que ESPERAR la respuesta.
  //
  // async = esta función puede usar "await" para esperar.
  //
  // {bool incluirInactivos = false} = parámetro opcional con
  //   valor por defecto false. Si lo llamas sin argumento,
  //   solo trae servicios activos.

  @override
  Future<List<Servicio>> listar({bool incluirInactivos = false}) async {
    try {
      // dio.get hace una petición HTTP GET al backend.
      // <List<dynamic>> le dice a Dio que espere una lista JSON.
      //
      // ApiEndpoints.adminServicios probablemente es algo como:
      //   "/api/admin/servicios"
      //
      // queryParameters agrega parámetros a la URL:
      //   /api/admin/servicios?incluirInactivos=false
      //
      // "await" pausa aquí hasta que Spring Boot responda.
      // Sin await, el código seguiría sin esperar la respuesta.
      final resp = await _dio.get<List<dynamic>>(
        ApiEndpoints.adminServicios,
        queryParameters: {'incluirInactivos': incluirInactivos},
      );
      // resp.data es el cuerpo de la respuesta (el JSON).
      // Si por algún motivo es null, usamos lista vacía (const []).
      final lista = resp.data ?? const [];
      // Aquí convertimos cada elemento JSON de la lista
      // a una Entidad Servicio usando el DTO.
      // .map() recorre cada elemento y lo transforma.
      // .toList() convierte el resultado a una Lista de Dart.
      //
      // Paso a paso:
      //   j          → un Map<String,dynamic> (un objeto JSON)
      //   fromJson   → lo convierte a ServicioAdminDto
      //   .aEntidad()→ lo convierte a Servicio (entidad limpia)
      return lista
          .map((j) => ServicioAdminDto.fromJson(j as Map<String, dynamic>).aEntidad())
          .toList();
    } catch (e) {
      // Si algo falla (sin internet, 500 del server, 401 sin JWT...),
      // capturamos el error, lo mapeamos a un mensaje entendible
      // y lanzamos nuestra excepción personalizada.
      // Así la UI puede mostrar "Sin conexión" en vez de un
      // error técnico incomprensible.
      throw ApiException(_errorMapper.mapear(e));
    }
  }


  // ──────────────────────────────────────────────────────
  // MÉTODOO: obtener
  // ──────────────────────────────────────────────────────
  // Obtiene UN solo servicio por su ID.
  // Future<Servicio> = en el futuro, te daré UN Servicio.
  //
  // ApiEndpoints.adminServicioPorId(id) genera algo como:
  //   "/api/admin/servicios/5"
  @override
  Future<Servicio> obtener(int id) async {
    try {
      // <Map<String, dynamic>> porque esperamos UN objeto JSON,
      // no una lista.
      final resp = await _dio.get<Map<String, dynamic>>(ApiEndpoints.adminServicioPorId(id));
      // resp.data! → el "!" significa "confío en que NO es null".
      // Úsalo solo cuando estés seguro, o puede crashear la app.
      return ServicioAdminDto.fromJson(resp.data!).aEntidad();
    } catch (e) {
      throw ApiException(_errorMapper.mapear(e));
    }
  }


  // ──────────────────────────────────────────────────────
  // MÉTODoO: crear
  // ──────────────────────────────────────────────────────
  // Crea un nuevo servicio en el backend (POST).
  // DatosServicio es un objeto con los campos del formulario
  // (nombre, precio, duración, etc.).
  @override
  Future<Servicio> crear(DatosServicio datos) async {
    try {
      final resp = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.adminServicios,
        data: _aBody(datos),
      );
      return ServicioAdminDto.fromJson(resp.data!).aEntidad();
    } catch (e) {
      throw ApiException(_errorMapper.mapear(e));
    }
  }

  // ──────────────────────────────────────────────────────
  // MÉTODOo: editar
  // ──────────────────────────────────────────────────────
  // Actualiza un servicio existente (PUT).
  // PUT reemplaza el recurso completo (todos los campos).
  // PATCH reemplaza solo los campos que mandas (parcial).
  @override
  Future<Servicio> editar(int id, DatosServicio datos) async {
    try {
      final resp = await _dio.put<Map<String, dynamic>>(
        ApiEndpoints.adminServicioPorId(id),
        data: _aBody(datos),
      );
      return ServicioAdminDto.fromJson(resp.data!).aEntidad();
    } catch (e) {
      throw ApiException(_errorMapper.mapear(e));
    }
  }


  // ──────────────────────────────────────────────────────
  // MÉTODoO: darBaja
  // ──────────────────────────────────────────────────────
  // "Da de baja" un servicio (lo desactiva).
  // Usa DELETE en HTTP.
  //
  // Future<void> = en el futuro termina, pero NO devuelve datos.
  // Solo nos importa saber si funcionó o falló.
  //
  // Nota: en muchos sistemas "DELETE" no borra físicamente
  // de la base de datos. Solo pone activo=false en MySQL.
  // Esto se llama "soft delete" (borrado lógico).
  @override
  Future<void> darBaja(int id) async {
    try {
      await _dio.delete(ApiEndpoints.adminServicioPorId(id));
    } catch (e) {
      throw ApiException(_errorMapper.mapear(e));
    }
  }


  // ──────────────────────────────────────────────────────
  // MÉTODoO: subirFoto
  // ──────────────────────────────────────────────────────
  // Sube una imagen/foto del servicio al servidor.
  // Devuelve la URL donde quedó guardada la foto.
  //
  // File archivo → el archivo de imagen del celular.
  // dart:io.File representa un archivo en el sistema
  // de archivos del dispositivo.
  //
  // Se usa multipart/form-data, que es el formato estándar
  // para subir archivos por HTTP (igual que un formulario
  // HTML con <input type="file">).
  @override
  Future<String> subirFoto(int id, File archivo) async {
    try {
      // FormData es la forma de Dio para enviar archivos.
      // Es como un "sobre" especial para archivos binarios.
      final form = FormData.fromMap({
        // 'archivo' es el nombre del campo que espera Spring Boot.
        // Debe coincidir con el @RequestParam("archivo") en Java.
        'archivo': await MultipartFile.fromFile(
          archivo.path,   // ruta del archivo en el celular
          // .uri.pathSegments.last extrae solo el nombre del archivo.
          // Ejemplo: "/storage/foto.jpg" → "foto.jpg"
          filename: archivo.uri.pathSegments.last,
        ),
      });

      final resp = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.adminServicioFoto(id),
        data: form,
        // Options le dice a Dio el tipo de contenido.
        // "multipart/form-data" es obligatorio para subir archivos.
        options: Options(contentType: 'multipart/form-data'),
      );

      // El backend responde con {"fotoUrl": "https://..."}
      // Extraemos y devolvemos esa URL.
      return resp.data!['fotoUrl'] as String;
    } catch (e) {
      throw ApiException(_errorMapper.mapear(e));
    }
  }

  Map<String, dynamic> _aBody(DatosServicio datos) => {
        'nombre': datos.nombre.trim(),
        'descripcion': datos.descripcion,
        'duracionMinutos': datos.duracionMinutos,
        'precio': datos.precio,
      };
}


// ============================================================
// DIAGRAMA COMPLETO DEL FLUJO — EJEMPLO: LISTAR SERVICIOS
// ============================================================
//
//  Usuario abre pantalla de servicios
//         │
//         ▼
//  ServiciosScreen (Widget Flutter)
//  "ref.watch(serviciosProvider)"
//         │
//         ▼
//  serviciosProvider (Riverpod)
//  llama al caso de uso
//         │
//         ▼
//  ListarServiciosUseCase
//  llama a repositorio.listar()
//         │
//         ▼
//  ServicioAdminRepositorioImpl.listar()   ◄── ESTE ARCHIVO
//  dio.get("/api/admin/servicios?incluirInactivos=false")
//         │
//         │  HTTP GET con JWT en el header
//         ▼
//  Spring Boot (Backend)
//  verifica el JWT con el filtro de seguridad
//  consulta MySQL: SELECT * FROM servicios WHERE activo=true
//         │
//         │  responde con JSON:
//         │  [{"idServicio":1,"nombre":"Corte",...}, ...]
//         ▼
//  ServicioAdminRepositorioImpl.listar()
//  ServicioAdminDto.fromJson(j).aEntidad()  ← convierte cada item
//         │
//         │  devuelve List<Servicio>
//         ▼
//  serviciosProvider actualiza el estado
//         │
//         ▼
//  ServiciosScreen se redibuja con la lista
//
// ============================================================
// GLOSARIO RÁPIDO
// ============================================================
//
//  async/await  → Esperar respuestas sin bloquear la app.
//                 La app sigue funcionando mientras espera.
//
//  Future<T>    → "Promesa" de que vas a recibir un valor T
//                 en algún momento futuro (ej: List<Servicio>).
//
//  try/catch    → "Intenta esto, y si hay error, haz esto otro."
//                 Evita que la app crashee por errores.
//
//  override     → "Estoy implementando este métoodo del contrato."
//
//  Dio          → Librería HTTP para Flutter. Hace GET, POST,
//                 PUT, DELETE al backend Spring Boot.
//
//  JWT          → Token de seguridad. Como un "pase" que Spring
//                 Boot revisa antes de darte los datos.
//                 Se manda en el header de cada petición HTTP.
//
//  FormData     → Formato especial para enviar archivos (fotos)
//                 por HTTP. Como un formulario con archivo adjunto.
//
//  Inyección    → Recibir dependencias (Dio) desde afuera en vez
//  de Depend.     de crearlas adentro. Facilita los tests.
//
//  Soft Delete  → "Borrar" sin borrar de verdad. Solo pone
//                 activo=false en MySQL. El dato sigue en la BD.
// ============================================================