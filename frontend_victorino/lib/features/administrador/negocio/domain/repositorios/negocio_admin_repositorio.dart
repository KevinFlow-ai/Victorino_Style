// ============================================================================
// INTRODUCCIÓN
// ============================================================================
//
// Este archivo define el **contrato del repositorio** del dominio "negocio".
//
// En Clean Architecture:
//
//   - Un "contrato" es una interfaz (abstract class en Dart).
//   - Define qué métodos debe implementar un repositorio.
//   - No contiene lógica.
//   - No sabe nada de HTTP, JSON, ni infraestructura.
//   - Solo define "qué se puede hacer", no "cómo se hace".
//
// Esto permite:
//
//   1. Tener varias implementaciones del repositorio si se desea.
//      Por ejemplo:
//         - una implementación HTTP (la que ya tienes)
//         - una implementación falsa para tests
//
//   2. Desacoplar el dominio de la infraestructura.
//      El dominio solo conoce esta interfaz, no la implementación.
//
// DIAGRAMA:
//
//   UI → Notifier → Caso de Uso → Repositorio (INTERFAZ) → RepositorioImpl → API
//
// Los casos de uso dependen de esta interfaz, no de la implementación concreta.
//
// ============================================================================

import '../entidades/horario_peluqueria.dart';

// ============================================================================
// INTERFAZ: NegocioAdminRepositorio
// ============================================================================
//
// Esta interfaz define todas las operaciones que el dominio necesita para
// gestionar la configuración del negocio.
//
// Cada métodoo devuelve entidades del dominio, nunca JSON ni DTOs.
// La implementación concreta (HTTP) se encarga de convertir JSON → Entidad.
//
// ============================================================================

abstract class NegocioAdminRepositorio {
  // --------------------------------------------------------------------------
  // HORARIO SEMANAL
  // --------------------------------------------------------------------------
  //
  // Obtener el horario completo de la peluquería.
  // Actualizar el horario con nuevos valores.
  //
  Future<HorarioPeluqueria> obtenerHorario();
  Future<HorarioPeluqueria> actualizarHorario(HorarioPeluqueria horario);

  // --------------------------------------------------------------------------
  // DESCANSO POR EMPLEADO
  // --------------------------------------------------------------------------
  //
  // Actualizar el descanso de un empleado concreto.
  //
  Future<DescansoEmpleado> actualizarDescanso(
      int idEmpleado, String horaInicio, int duracionMinutos);

  // --------------------------------------------------------------------------
  // FESTIVOS
  // --------------------------------------------------------------------------
  //
  // Listar todos los festivos.
  // Crear un nuevo festivo.
  // Eliminar un festivo por id.
  //
  Future<List<Festivo>> listarFestivos();
  Future<Festivo> crearFestivo(
      String fecha, String descripcion, TipoFestivo tipo);
  Future<void> eliminarFestivo(int id);

  // --------------------------------------------------------------------------
  // CIERRE ANUAL
  // --------------------------------------------------------------------------
  //
  // Obtener el cierre anual actual.
  // Actualizar el cierre anual.
  //
  Future<CierreAnual> obtenerCierreAnual();
  Future<CierreAnual> actualizarCierreAnual(
      String? fechaInicio, String? fechaFin);
}

