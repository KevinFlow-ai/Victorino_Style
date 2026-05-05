import '../entidades/servicio.dart';
import '../repositorios/servicio_admin_repositorio.dart';


// ============================================================
// ARCHIVO: editar_servicio.dart
// CAPA: Domain (Dominio) — en Clean Architecture
// ============================================================
//
// ¿QUÉ HACE ESTE ARCHIVO?
// ────────────────────────
// Es el Caso de Uso para EDITAR un servicio existente.
// Su única responsabilidad: decirle al repositorio
// que actualice un servicio con nuevos datos.
//
// Es el hermano pequeño de CrearServicio.
// La diferencia principal:
//   Crear  → no necesita ID, crea algo nuevo
//   Editar → necesita el ID del servicio a modificar
//
// ¿Por qué es tan corto?
// ──────────────────────
// Porque este caso de uso no tiene reglas de negocio propias.
// No valida nada (a diferencia de CrearServicio).
// Solo delega al repositorio directamente.
//
// ¿Está bien que sea tan corto?
// ──────────────────────────────
// Sí. En el futuro podrías agregar validaciones aquí
// sin tocar nada más. Por ejemplo:
//   - "No se puede editar un servicio si tiene citas pendientes"
//   - "El nombre no puede repetirse"
// Esas reglas irían aquí, no en la UI ni en el repositorio.
//
// ============================================================
// DIAGRAMA — FLUJO AL EDITAR UN SERVICIO
// ============================================================
//
//  Admin modifica el formulario en Flutter
//         │
//         ▼
//  Provider llama: editarServicio.ejecutar(id, datos)
//         │
//         ▼
//  EditarServicio.ejecutar(id, datos)  ← ESTE ARCHIVO
//  (sin validaciones por ahora, delega directo)
//         │
//         ▼
//  repositorio.editar(id, datos)
//         │
//         ▼
//  HTTP PUT /api/admin/servicios/{id}  con JWT
//         │
//         ▼
//  Spring Boot actualiza en MySQL
//  UPDATE servicios SET nombre=?, precio=?, ...
//  WHERE id_servicio = {id}
//         │
//         ▼
//  Devuelve JSON con el servicio actualizado
//         │
//         ▼
//  DTO → Entidad Servicio → Provider → Pantalla se redibuja ✓
//
// ============================================================
// COMPARATIVA: CREAR vs EDITAR
// ============================================================
//
//              CrearServicio       EditarServicio
//  HTTP verb:  POST                PUT
//  URL:        /servicios          /servicios/{id}
//  ID:         No necesita         Sí necesita (para saber cuál)
//  Valida:     Sí (nombre,precio)  No (por ahora)
//  MySQL:      INSERT              UPDATE
//
// ============================================================
class EditarServicio {
  EditarServicio(this._repositorio);
  final ServicioAdminRepositorio _repositorio;

  // ──────────────────────────────────────────────────────
  // MÉToODO: ejecutar
  // ──────────────────────────────────────────────────────
  // Recibe:
  //   int id          → el ID del servicio a editar (de MySQL)
  //   DatosServicio   → los nuevos datos del formulario
  //
  // Devuelve:
  //   Future<Servicio> → el servicio ya actualizado
  //
  // La sintaxis "=>" en una clase se llama "expression body".
  // Es una forma corta de escribir una función de una sola línea.
  //
  // Esto:
  //   Future<Servicio> ejecutar(int id, DatosServicio datos) =>
  //       repositorio.editar(id, datos);
  //
  // Es EXACTAMENTE igual a esto:
  //   Future<Servicio> ejecutar(int id, DatosServicio datos) {
  //     return repositorio.editar(id, datos);
  //   }
  //
  // También nota que NO tiene "async" porque simplemente
  // retorna el Future del repositorio sin hacer nada más.
  // No necesita await. Es como pasar una pelota sin abrirla.
  Future<Servicio> ejecutar(int id, DatosServicio datos) =>
      _repositorio.editar(id, datos);
}

// ============================================================
// REFLEXIÓN: ¿CUÁNDO AGREGARLE VALIDACIONES A ESTE CASO DE USO?
// ============================================================
//
//  Ahora mismo no valida nada. Pero imagina que en el futuro
//  el negocio dice: "no se puede cambiar el precio de un
//  servicio si hay citas pagadas pendientes".
//
//  Esa regla iría AQUÍ, no en la pantalla ni en el servidor.
//  Quedaría así:
//
//    Future<Servicio> ejecutar(int id, DatosServicio datos) async {
//      final citasPendientes = await _citasRepo.contarPendientes(id);
//      if (citasPendientes > 0 && datos.precio != servicioActual.precio) {
//        throw ApiException(const FailureValidacion(
//          'No puedes cambiar el precio con citas pendientes', {},
//        ));
//      }
//      return _repositorio.editar(id, datos);
//    }
//
//  Eso es la belleza del Caso de Uso: crece con el negocio
//  sin romper nada más.
//
// ============================================================
// RESUMEN PARA NOVATOS
// ============================================================
//
//  Este archivo hace UNA cosa: editar un servicio.
//  Por ahora no tiene reglas propias, pero el lugar
//  está reservado para cuando las necesite.
//  Tiene el mismo bug de _repositorio que CrearServicio.
//  Son solo 3 líneas útiles, y eso está perfectamente bien.
// ============================================================