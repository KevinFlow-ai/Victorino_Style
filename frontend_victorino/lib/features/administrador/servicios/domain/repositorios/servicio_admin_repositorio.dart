// ============================================================
// ARCHIVO: servicio_admin_repositorio.dart
// CAPA: Domain (Dominio) — en Clean Architecture
// ============================================================
//
// ¿QUÉ ES ESTE ARCHIVO?
// ─────────────────────
// Este archivo define el CONTRATO del repositorio.
// Un contrato es una lista de PROMESAS:
//   "quien implemente esto, DEBE saber hacer estas cosas"
//
// En Dart, un contrato se hace con "abstract class".
// En Java (Spring Boot) sería una "interface".
// Son exactamente el mismo concepto.
//
// Este archivo dice QUÉ se puede hacer con los servicios,
// pero NO dice CÓMO. El CÓMO lo define la implementación:
//   ServicioAdminRepositorioImpl (capa de datos).
//
// ============================================================
// ANALOGÍA DEL MUNDO REAL
// ============================================================
//
//  Imagina que contratas a un empleado para un trabajo.
//  Le das un contrato que dice:
//    "Debes saber:
//      - Listar servicios
//      - Obtener un servicio por ID
//      - Crear un servicio
//      - Editar un servicio
//      - Dar de baja un servicio
//      - Subir una foto"
//
//  El contrato NO dice cómo hacerlo.
//  El empleado (impl) decide si usa Dio, GraphQL, una BD local...
//  Lo que importa es que CUMPLE el contrato.
//
//  Contrato   = este archivo   (abstract class)
//  Empleado   = ServicioAdminRepositorioImpl (con Dio+HTTP)
//  Empleado 2 = ServicioAdminRepositorioFake (para tests, sin HTTP)
//
// ============================================================
// DIAGRAMA — POR QUÉ SEPARARLOS EN DOS ARCHIVOS
// ============================================================
//
//  ┌─────────────────────────────────────────────────────────┐
//  │  CAPA DOMINIO                                           │
//  │                                                         │
//  │  CrearServicio ──────► ServicioAdminRepositorio         │
//  │  (caso de uso)         (este archivo, el CONTRATO)      │
//  │                         "sé que existe listar(), crear()│
//  │                          pero no sé cómo funcionan"     │
//  └───────────────────────────────┬─────────────────────────┘
//                                  │ implementado por
//  ┌───────────────────────────────▼─────────────────────────┐
//  │  CAPA DATOS                                             │
//  │                                                         │
//  │  ServicioAdminRepositorioImpl                           │
//  │  "yo sé CÓMO: uso Dio, HTTP, JSON, Spring Boot"         │
//  └─────────────────────────────────────────────────────────┘
//
//  La capa Dominio SOLO conoce el contrato.
//  Nunca importa la implementación directamente.
//  Esto se llama "Dependency Inversion" (la D de SOLID).
//
// ============================================================
// DIAGRAMA — EL PODER DE TENER UN CONTRATO
// ============================================================
//
//  El mismo contrato puede tener MÚLTIPLES implementaciones:
//
//  ServicioAdminRepositorio (contrato)
//         ▲               ▲               ▲
//         │               │               │
//  ...Impl (Dio)    ...Fake (tests)   ...Local (cache)
//  Llama a         Devuelve datos     Guarda en SQLite
//  Spring Boot     inventados         del celular
//
//  Los casos de uso y providers NO cambian nada.
//  Solo cambias qué implementación se inyecta (Riverpod hace esto).
//  Eso es Clean Architecture en acción.
//
// ============================================================

// dart:io para File (subir fotos).
// Esta es la única dependencia externa permitida aquí
// porque File es parte del SDK de Dart, no una librería
// de terceros como Dio.
import 'dart:io';

// Importamos las entidades del propio dominio.
// El contrato solo habla en términos de entidades puras.
// Nunca importa DTOs ni clases de la capa de datos.
import '../entidades/servicio.dart';

// "abstract class" define una clase abstracta.
// "Abstracta" significa que NO se puede instanciar directamente.
// No puedes hacer: ServicioAdminRepositorio()  ← ERROR
// Solo puedes usarla como tipo y como base para implementarla.
abstract class ServicioAdminRepositorio {

  // ────────────────────────────────────────────────────
  // MÉTOoDO 1: listar
  // ────────────────────────────────────────────────────
  // Obtiene todos los servicios.
  // {bool incluirInactivos = false} → parámetro nombrado
  // con valor por defecto. Por defecto solo trae activos.
  //
  // No tiene cuerpo {} porque es abstracto.
  // Solo declara la firma: "esto debe existir y devolver esto".
  Future<List<Servicio>> listar({bool incluirInactivos = false});

  // ────────────────────────────────────────────────────
  // MÉTODoO 2: obtener
  // ────────────────────────────────────────────────────
  // Obtiene UN servicio por su ID de MySQL.
  // Si no existe, la implementación lanzará ApiException.
  Future<Servicio> obtener(int id);

  // ────────────────────────────────────────────────────
  // MÉTODoO 3: crear
  // ────────────────────────────────────────────────────
  // Crea un servicio nuevo en el backend.
  // Recibe DatosServicio (los campos del formulario).
  // Devuelve el Servicio creado (ya con id asignado por MySQL).
  Future<Servicio> crear(DatosServicio datos);

  // ────────────────────────────────────────────────────
  // MÉTODoO 4: editar
  // ────────────────────────────────────────────────────
  // Actualiza un servicio existente.
  // Necesita el id (para saber cuál) y los nuevos datos.
  // Devuelve el Servicio con los datos actualizados.
  Future<Servicio> editar(int id, DatosServicio datos);

  // ────────────────────────────────────────────────────
  // MÉTODoO 5: darBaja
  // ────────────────────────────────────────────────────
  // Desactiva un servicio (soft delete: activo = false).
  // Future<void> = solo nos importa si funcionó o no.
  // No devuelve datos.
  Future<void> darBaja(int id);

  // ────────────────────────────────────────────────────
  // MÉTODOo 6: subirFoto
  // ────────────────────────────────────────────────────
  // Sube la foto de un servicio al servidor.
  // Devuelve Future<String>: la URL pública de la foto.
  // La foto va separada del resto de datos (multipart).
  Future<String> subirFoto(int id, File archivo);
}

// ============================================================
// RESUMEN VISUAL DE TODOS LOS ARCHIVOS QUE HAN VISTO
// ============================================================
//
//  CAPA DOMINIO (no sabe nada de HTTP ni Flutter widgets)
//  ┌──────────────────────────────────────────────────────┐
//  │                                                      │
//  │  servicio.dart                                       │
//  │  ├── class Servicio          (entidad completa)      │
//  │  └── class DatosServicio     (datos del formulario)  │
//  │                                                      │
//  │  servicio_admin_repositorio.dart  ◄── ESTE ARCHIVO   │
//  │  └── abstract class ServicioAdminRepositorio         │
//  │       ├── listar()                                   │
//  │       ├── obtener()                                  │
//  │       ├── crear()                                    │
//  │       ├── editar()                                   │
//  │       ├── darBaja()                                  │
//  │       └── subirFoto()                                │
//  │                                                      │
//  │  casos_de_uso/                                       │
//  │  ├── crear_servicio.dart    (valida + llama crear)   │
//  │  ├── editar_servicio.dart   (llama editar)           │
//  │  └── subir_foto_servicio.dart (llama subirFoto)      │
//  │                                                      │
//  └──────────────────────────────────────────────────────┘
//
//  CAPA DATOS (sabe de HTTP, Dio, JSON)
//  ┌──────────────────────────────────────────────────────┐
//  │                                                      │
//  │  servicio_admin_dto.dart                             │
//  │  └── class ServicioAdminDto                          │
//  │       ├── fromJson()   JSON → DTO                    │
//  │       └── aEntidad()   DTO  → Servicio               │
//  │                                                      │
//  │  servicio_admin_repositorio_impl.dart                │
//  │  └── class ServicioAdminRepositorioImpl              │
//  │       implements ServicioAdminRepositorio            │
//  │       (implementa los 6 métodos del contrato con Dio)│
//  │                                                      │
//  └──────────────────────────────────────────────────────┘
//
// ============================================================
// TABLA: ¿QUÉ MÉTODOO HACE QUÉ EN CADA CAPA?
// ============================================================
//
//  Acción       Contrato      Impl (HTTP)        Spring Boot
//  ──────────── ────────────  ─────────────────  ──────────────────
//  listar()     declara       GET /servicios      SELECT WHERE activo
//  obtener()    declara       GET /servicios/{id} SELECT WHERE id=?
//  crear()      declara       POST /servicios     INSERT INTO
//  editar()     declara       PUT /servicios/{id} UPDATE SET
//  darBaja()    declara       DELETE /serv/{id}   UPDATE activo=false
//  subirFoto()  declara       POST /serv/{id}/foto guarda archivo
//
// ============================================================
// CONCEPTOS CLAVE PARA RECORDAR
// ============================================================
//
//  abstract class → define un contrato, no se puede instanciar.
//                   En Java sería "interface".
//
//  implements     → "juro que implementaré todos estos métodos".
//                   Si falta uno, Dart da error de compilación.
//
//  Dependency     → El dominio depende del contrato (abstracto),
//  Inversion        no de la implementación concreta.
//                   "Depende de abstracciones, no de detalles."
//
//  Testabilidad   → Con el contrato puedes crear un repositorio
//                   FALSO para tests que devuelva datos inventados
//                   sin necesitar internet ni Spring Boot.
// ============================================================