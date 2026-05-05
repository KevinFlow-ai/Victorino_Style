// ============================================================
// ARCHIVO: crear_servicio.dart
// CAPA: Domain (Dominio) — en Clean Architecture
// ============================================================
//
// ¿QUÉ ES ESTE ARCHIVO?
// ─────────────────────
// Este archivo define un CASO DE USO (Use Case).
//
// Un Caso de Uso representa UNA acción concreta que el
// usuario o el admin puede hacer en el sistema.
// En este caso: "Crear un nuevo servicio".
//
// Es la capa MÁS IMPORTANTE de Clean Architecture porque
// contiene las REGLAS DE NEGOCIO.
// "Reglas de negocio" = las reglas del mundo real que tu
// app debe respetar. Ej: "el precio no puede ser 0".
//
// ¿Qué NO hace un Caso de Uso?
//   ✗ No sabe que existe Dio o HTTP
//   ✗ No sabe que existe Flutter o widgets
//   ✗ No sabe que existe MySQL
//   Solo sabe: "estos son los pasos para crear un servicio"
//
// ============================================================
// DIAGRAMA — LUGAR EN CLEAN ARCHITECTURE
// ============================================================
//
//  ┌─────────────────────────────────────────┐
//  │  UI (Pantallas / Widgets Flutter)       │  ← Capa Presentación
//  └───────────────────┬─────────────────────┘
//                      │ llama a
//  ┌───────────────────▼─────────────────────┐
//  │  Provider (Riverpod)                    │  ← Capa Presentación
//  └───────────────────┬─────────────────────┘
//                      │ llama a
//  ┌───────────────────▼─────────────────────┐
//  │  CrearServicio (este archivo)           │  ← Capa Dominio ★
//  │  Caso de Uso                            │
//  │  Valida reglas de negocio               │
//  └───────────────────┬─────────────────────┘
//                      │ llama a (si pasa validación)
//  ┌───────────────────▼─────────────────────┐
//  │  ServicioAdminRepositorio (contrato)    │  ← Capa Dominio
//  └───────────────────┬─────────────────────┘
//                      │ implementado por
//  ┌───────────────────▼─────────────────────┐
//  │  ServicioAdminRepositorioImpl           │  ← Capa Datos
//  │  Llama a Spring Boot via HTTP (Dio)     │
//  └───────────────────┬─────────────────────┘
//                      │ consulta
//  ┌───────────────────▼─────────────────────┐
//  │  MySQL  (base de datos)                 │  ← Infraestructura
//  │  tabla: servicios                       │
//  └─────────────────────────────────────────┘
//
// ============================================================
// DIAGRAMA — FLUJO COMPLETO AL CREAR UN SERVICIO
// ============================================================
//
//  Admin llena el formulario en Flutter
//         │
//         ▼
//  Provider llama: crearServicio.ejecutar(datos)
//         │
//         ▼
//  CrearServicio.ejecutar(datos)   ← ESTE ARCHIVO
//         │
//         ├─── ¿nombre vacío, duración < 5, precio <= 0?
//         │         │
//         │         ▼ SÍ → lanza ApiException(FailureValidacion)
//         │                La UI muestra el mensaje de error.
//         │                NUNCA llega al servidor. ✓
//         │
//         ▼ NO (datos válidos)
//  repositorio.crear(datos)
//         │
//         ▼
//  HTTP POST a Spring Boot
//  /api/admin/servicios  con JWT
//         │
//         ▼
//  Spring Boot valida el JWT, guarda en MySQL,
//  devuelve JSON con el servicio creado
//         │
//         ▼
//  RepositorioImpl convierte JSON → DTO → Entidad Servicio
//         │
//         ▼
//  Provider actualiza el estado
//         │
//         ▼
//  Pantalla Flutter se redibuja con el nuevo servicio ✓
//
// ============================================================

// ApiException es nuestra clase de error personalizada.
// La lanzamos cuando algo sale mal (validación o HTTP).
import '../../../../../core/errors/api_exception.dart';

// Failure representa los tipos de error de negocio.
// FailureValidacion es el tipo específico para cuando
// los datos del formulario no cumplen las reglas.
import '../../../../../core/errors/failure.dart';

// La entidad Servicio: el objeto limpio del dominio.
// Es lo que devolvemos cuando todo sale bien.
import '../entidades/servicio.dart';

// El CONTRATO del repositorio. Este caso de uso solo conoce
// el contrato, no sabe qué implementación hay detrás.
// Esto permite cambiar de Dio a GraphQL o lo que sea
// sin tocar este archivo. Eso es Clean Architecture.
import '../repositorios/servicio_admin_repositorio.dart';

// ──────────────────────────────────────────────────────────
// CLASE: CrearServicio
// ──────────────────────────────────────────────────────────
// Por convención, los casos de uso se nombran como
// VERBOS en infinitivo: Crear, Listar, Editar, Eliminar...
// Un caso de uso = una acción = una clase = un métoodo "ejecutar".

class CrearServicio {
  // ──────────────────────────────────────────────────────
  // CONSTRUCTOR
  // ──────────────────────────────────────────────────────
  // Recibe el repositorio por INYECCIÓN DE DEPENDENCIAS.
  // El "_" antes del nombre significa que es PRIVADO:
  // solo se puede usar dentro de esta clase.
  //
  CrearServicio(this._repositorio);

  final ServicioAdminRepositorio _repositorio;

  // ──────────────────────────────────────────────────────
  // MÉTODdO: ejecutar
  // ──────────────────────────────────────────────────────
  // Por convención, el métoodo principal de un caso de uso
  // se llama "ejecutar" (o "call" en algunos estilos).
  // Recibe los datos del formulario y devuelve el Servicio
  // recién creado (o lanza un error si algo falla).
  //
  // Future<Servicio> = en el futuro te devuelvo un Servicio.
  //
  // Nota: este métodoo NO tiene "async" aunque devuelve Future.
  // Eso está bien porque simplemente RETORNA el Future que
  // devuelve repositorio.crear(). No necesita await aquí.
  // Es como pasar el "sobre" sin abrirlo.
  //
  // Si hubiera lógica después del await, SÍ necesitaría async.

  Future<Servicio> ejecutar(DatosServicio datos) {
    // ──────────────────────────────────────────────────
    // VALIDACIÓN DE REGLAS DE NEGOCIO
    // ──────────────────────────────────────────────────
    // Antes de ir al servidor, validamos los datos aquí.
    // Esto se llama "fail fast" (fallar rápido):
    // si los datos son malos, paramos YA, sin gastar
    // una llamada HTTP innecesaria al backend.
    //
    // Las 3 reglas que se validan:
    //   1. nombre no puede estar vacío
    //      .trim() elimina espacios → "   " sería vacío
    //   2. duración mínima de 5 minutos
    //   3. precio debe ser mayor que 0
    //
    // Si CUALQUIERA de las 3 falla → lanzamos excepción.
    // El "||" es OR lógico: si UNA condición es verdadera,
    // entra al if.
    if (datos.nombre.trim().isEmpty || datos.duracionMinutos < 5
        || datos.precio <= 0) {

      // Lanzamos ApiException con un FailureValidacion dentro.
      // FailureValidacion es un tipo de error que dice:
      // "los datos del formulario son inválidos".
      //
      // Primer argumento: mensaje para el usuario.
      // Segundo argumento: {} mapa de errores por campo
      //   (por ahora vacío, pero podría ser:
      //    {'nombre': 'requerido', 'precio': 'debe ser > 0'})
      //
      // "throw" lanza la excepción y DETIENE la ejecución.
      // El código de abajo NO se ejecutará si entra aquí.
      throw ApiException(const FailureValidacion(
        'Revisa nombre, duración (mín. 5 min) y precio (mayor que 0)', {},
      ));
    }
    return _repositorio.crear(datos);
  }
}


// ============================================================
// CONCEPTO CLAVE: ¿POR QUÉ VALIDAR AQUÍ Y NO EN LA UI?
// ============================================================
//
//  Se podría validar directamente en el formulario de Flutter,
//  pero hacerlo en el Caso de Uso tiene ventajas:
//
//  1. CENTRALIZADO: si la regla cambia (ej: mínimo 10 min),
//     solo cambias UN lugar, no todos los formularios.
//
//  2. REUTILIZABLE: si en el futuro hay otra pantalla que
//     crea servicios (ej: importación masiva), también
//     pasa por aquí y se valida igual.
//
//  3. TESTEABLE: puedes probar las reglas de negocio sin
//     abrir ninguna pantalla. Solo creas el caso de uso,
//     le pasas datos malos y verificas que lanza el error.
//
//  La UI puede tener validación VISUAL (mostrar rojo en el campo),
//  pero la validación de NEGOCIO vive en el Caso de Uso.
//
// ============================================================
// GLOSARIO DE ESTE ARCHIVO
// ============================================================
//
//  Caso de Uso    → Una acción del sistema. Un archivo = una acción.
//  Failure        → Clase que representa un error de negocio.
//  FailureValidacion → Tipo específico: datos del formulario inválidos.
//  ApiException   → Envuelve el Failure para lanzarlo como excepción.
//  throw          → Lanza una excepción. Para la ejecución.
//  DatosServicio  → Objeto con los campos que llegan del formulario.
//  Future<T>      → Promesa de un valor T que llegará luego.
//  this._repo     → "Guarda el parámetro en el campo _repositorio".
// ============================================================