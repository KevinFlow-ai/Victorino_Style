// ============================================================
// ARCHIVO: servicio.dart
// CAPA: Domain (Dominio) — en Clean Architecture
// ============================================================
//
// ¿QUÉ ES ESTE ARCHIVO?
// ─────────────────────
// Este archivo define las ENTIDADES del dominio de servicios.
// Una entidad es el objeto más puro e importante de tu app:
// representa algo del mundo real (un Servicio del negocio).
//
// Regla de oro: este archivo NO importa nada de Flutter,
// Dio, HTTP, MySQL, ni ninguna librería externa.
// Es Dart puro. Puede existir sin internet, sin base de datos,
// sin pantallas. Es completamente independiente.
//
// En este archivo hay DOS clases:
//   1. Servicio      → representa un servicio YA existente
//                      (tiene id, viene de la BD)
//   2. DatosServicio → representa los datos de un formulario
//                      para CREAR o EDITAR un servicio
//                      (no tiene id, la foto va aparte)
//
// ============================================================
// DIAGRAMA — LUGAR EN CLEAN ARCHITECTURE
// ============================================================
//
//  ┌─────────────────────────────────────────────────────┐
//  │  CAPA PRESENTACIÓN                                  │
//  │  Pantallas, Widgets, Providers                      │
//  │  Usan "Servicio" para mostrar datos en pantalla     │
//  └───────────────────────┬─────────────────────────────┘
//                          │ usa
//  ┌───────────────────────▼─────────────────────────────┐
//  │  CAPA DOMINIO  ◄── ESTÁS AQUÍ                       │
//  │                                                     │
//  │  ┌─────────────┐   ┌──────────────────┐            │
//  │  │  Servicio   │   │  DatosServicio   │            │
//  │  │  (entidad)  │   │  (datos form)    │            │
//  │  └─────────────┘   └──────────────────┘            │
//  │                                                     │
//  │  Casos de Uso usan ambas clases                     │
//  │  Repositorio (contrato) las usa como parámetros     │
//  └───────────────────────┬─────────────────────────────┘
//                          │ convierte a/desde
//  ┌───────────────────────▼─────────────────────────────┐
//  │  CAPA DATOS                                         │
//  │  ServicioAdminDto.aEntidad() → devuelve Servicio    │
//  │  _aBody(DatosServicio)       → convierte a JSON     │
//  └───────────────────────┬─────────────────────────────┘
//                          │
//  ┌───────────────────────▼─────────────────────────────┐
//  │  Spring Boot + MySQL                                │
//  └─────────────────────────────────────────────────────┘
//
// ============================================================
// DIAGRAMA — CUÁNDO SE USA CADA CLASE
// ============================================================
//
//  ┌──────────────────┐         ┌──────────────────────┐
//  │   DatosServicio  │         │      Servicio        │
//  │  (formulario)    │         │   (ya existe en BD)  │
//  └────────┬─────────┘         └──────────┬───────────┘
//           │ se usa en                    │ se usa en
//           ▼                              ▼
//   CrearServicio.ejecutar()      listar() → muestra lista
//   EditarServicio.ejecutar()     obtener() → muestra detalle
//   _aBody() → se convierte       Pantallas muestran sus campos
//   a JSON para el POST/PUT
//
//  Flujo típico:
//  Usuario llena formulario
//       ↓ crea DatosServicio
//  Caso de Uso valida y manda al repo
//       ↓ backend procesa y responde
//  DTO convierte JSON a Servicio
//       ↓ pantalla muestra el Servicio creado/editado
//
// ============================================================

// ──────────────────────────────────────────────────────────
// CLASE 1: Servicio
// ──────────────────────────────────────────────────────────
// Representa UN servicio completo tal como existe en el sistema.
// Viene de la base de datos (tiene "id" asignado por MySQL).
//
// "const" en el constructor significa que si todos los
// valores son constantes en tiempo de compilación, Dart
// puede crear el objeto una sola vez y reutilizarlo.
// Ahorra memoria.
class Servicio {
  const Servicio({
    required this.id,               // ID único en MySQL (AUTO_INCREMENT)
    required this.nombre,           // "Corte de cabello"
    required this.duracionMinutos,  // 30
    required this.precio,           // 15.50
    required this.fotoUrl,          // "https://..."
    required this.activo,           // true o false
    this.descripcion,               // opcional, puede ser null
  });

  // "final" = una vez asignado no cambia.
  // Las entidades son INMUTABLES por diseño.
  // Si quieres "cambiar" un servicio, creas uno nuevo con
  // los valores modificados, no modificas este.
  // Esto evita bugs difíciles de encontrar.

  final int id;
  // El ID lo asigna MySQL automáticamente (AUTO_INCREMENT).
  // En la tabla: id_servicio INT PRIMARY KEY AUTO_INCREMENT

  final String nombre;
  // Texto del nombre del servicio.
  // En MySQL: nombre VARCHAR(100) NOT NULL

  final String? descripcion;
  // El "?" significa que puede ser null (opcional).
  // En MySQL: descripcion TEXT NULL
  // Si el admin no pone descripción, este campo es null.

  final int duracionMinutos;
  // Duración entera en minutos: 30, 45, 60, 90...
  // En MySQL: duracion_minutos INT NOT NULL

  // ── NOTA IMPORTANTE SOBRE EL PRECIO ──────────────────
  // "num" en Dart es el tipo padre de "int" y "double".
  // Es decir: num puede ser un entero (15) o decimal (15.50).
  //
  // ¿Por qué num y no double?
  // El comentario original lo explica bien:
  // Para evitar depender de librerías especiales de decimales
  // (como "decimal" package). La UI se encarga de formatearlo
  // con NumberFormat para mostrar "15,50 €".
  //
  // En MySQL: precio DECIMAL(10,2) NOT NULL
  // En JSON:  "precio": 15.50  → llega como num en Dart
  final num precio;

  final String fotoUrl;
  // URL completa de la foto. Puede ser:
  //   - URL de Firebase Storage: "https://firebasestorage..."
  //   - URL de tu servidor: "https://tuserver.com/fotos/1.jpg"
  //   - String vacío "" si no tiene foto (ver DTO: ?? '')
  // En MySQL: foto_url VARCHAR(500)

  final bool activo;
// true  = servicio visible y disponible para reservar
// false = servicio "dado de baja" (soft delete)
//         sigue en MySQL pero no se muestra a clientes
// En MySQL: activo TINYINT(1) DEFAULT 1
}

// ──────────────────────────────────────────────────────────
// CLASE 2: DatosServicio
// ──────────────────────────────────────────────────────────
// Representa los datos que el admin ingresa en el formulario
// para CREAR un servicio nuevo o EDITAR uno existente.
//
// ¿Por qué existe esta clase separada de Servicio?
// ────────────────────────────────────────────────
// Porque cuando creas o editas un servicio:
//   ✗ No mandas el "id" (MySQL lo asigna, o ya lo tienes en la URL)
//   ✗ No mandas "activo" (no se cambia en el form de crear/editar)
//   ✗ No mandas "fotoUrl" (la foto se sube por separado, multipart)
//
// Si usaras Servicio directamente, tendrías que inventar
// valores falsos para esos campos. Eso es sucio y propenso a errores.
// DatosServicio tiene EXACTAMENTE los campos del formulario, ni más ni menos.
//
// En Spring Boot existe el equivalente: probablemente
// una clase "CrearServicioRequest" o "ServicioRequest" Java.
class DatosServicio {
  const DatosServicio({
    required this.nombre,
    required this.duracionMinutos,
    required this.precio,
    this.descripcion,   // opcional, puede no rellenarse
  });

  final String nombre;
  final String? descripcion;
  final int duracionMinutos;
  final num precio;

// Nota: NO tiene "id"      → lo maneja la URL (/servicios/{id})
// Nota: NO tiene "activo"  → se maneja con darBaja() aparte
// Nota: NO tiene "fotoUrl" → se sube con subirFoto() aparte
}

// ============================================================
// COMPARATIVA: Servicio vs DatosServicio
// ============================================================
//
//  Campo            Servicio     DatosServicio   ¿Por qué?
//  ─────────────────────────────────────────────────────────
//  id               ✓            ✗    MySQL lo asigna / va en URL
//  nombre           ✓            ✓    Siempre necesario
//  descripcion      ✓ (null?)    ✓ (null?)  Opcional en ambos
//  duracionMinutos  ✓            ✓    Siempre necesario
//  precio           ✓            ✓    Siempre necesario
//  fotoUrl          ✓            ✗    Va por multipart aparte
//  activo           ✓            ✗    Se maneja con darBaja()
//
// ============================================================
// TABLA MySQL QUE REPRESENTA ESTA ENTIDAD
// ============================================================
//
//  CREATE TABLE servicios (
//    id_servicio       INT          PRIMARY KEY AUTO_INCREMENT,
//    nombre            VARCHAR(100) NOT NULL,
//    descripcion       TEXT         NULL,
//    duracion_minutos  INT          NOT NULL,
//    precio            DECIMAL(10,2) NOT NULL,
//    foto_url          VARCHAR(500)  NULL,
//    activo            TINYINT(1)   NOT NULL DEFAULT 1
//  );
//
//  Los nombres de columna en MySQL usan snake_case (guión bajo).
//  Los nombres en Dart usan camelCase (mayúscula interna).
//  El DTO (fromJson) hace la traducción entre ambos.
//
// ============================================================
// GLOSARIO RÁPIDO
// ============================================================
//
//  Entidad     → Objeto del mundo real representado en código.
//                El corazón de tu dominio.
//
//  Inmutable   → No se puede modificar después de crearse.
//                "final" en Dart garantiza esto.
//                Para "cambiar" un objeto inmutable, creas uno nuevo.
//
//  null        → Ausencia de valor. String? puede ser null.
//                String sin "?" NUNCA puede ser null (Dart lo garantiza).
//                Esto se llama "null safety" y evita muchos crashes.
//
//  num         → Tipo en Dart que acepta tanto int como double.
//                Útil para precios que pueden ser 15 o 15.50.
//
//  const       → El objeto se crea en tiempo de compilación,
//                no en tiempo de ejecución. Más eficiente.
//                Solo funciona si todos los valores son constantes.
//
//  Soft delete → Borrado lógico. El campo "activo = false"
//                hace que el servicio "desaparezca" para los
//                clientes sin borrarlo realmente de MySQL.
//                Así puedes recuperarlo si fue un error.
// ============================================================