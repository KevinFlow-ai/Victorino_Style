// Contrato del repositorio de empleados. La capa data lo implementa contra HTTP;
// los casos de uso solo conocen este contrato.
import 'dart:io';

import '../entidades/empleado.dart';



// ============================================================================
// CONTRATO DEL REPOSITORIO DE EMPLEADOS
// ============================================================================
//
// En Clean Architecture, un "repositorio" es una abstracción (una interfaz)
// que define qué operaciones se pueden hacer con un conjunto de datos.
//
// Este archivo NO contiene lógica real. Solo define QUÉ métodos deben existir.
// La capa data (por ejemplo, HTTP con Dio) será la que implemente estos métodos.
//
// Los casos de uso (como CrearEmpleado, EditarEmpleado, etc.) dependen de este
// contrato, no de la implementación concreta. Esto permite:
//   - cambiar la fuente de datos sin tocar la lógica del negocio,
//   - hacer tests más fáciles,
//   - mantener el código más limpio y desacoplado.
//
// Este repositorio administra empleados del panel de administración.
// ============================================================================










// ---------------------------------------------------------------------------
// Clase abstracta EmpleadoAdminRepositorio
// ---------------------------------------------------------------------------
// Define todas las operaciones que se pueden realizar sobre empleados.
// La implementación real estará en la capa data (por ejemplo, usando HTTP).
// ---------------------------------------------------------------------------
abstract class EmpleadoAdminRepositorio {

  // -------------------------------------------------------------------------
  // LISTAR EMPLEADOS
  // Devuelve una lista de empleados.
  // Si incluirInactivos = true, también devuelve los empleados dados de baja.
  // -------------------------------------------------------------------------
  Future<List<Empleado>> listar({bool incluirInactivos = false});

  // -------------------------------------------------------------------------
  // OBTENER DETALLE DE UN EMPLEADO
  // Devuelve un empleado activo por su ID.
  // -------------------------------------------------------------------------
  Future<Empleado> obtener(int id);

  // -------------------------------------------------------------------------
  // CREAR EMPLEADO
  // Da de alta un nuevo empleado.
  // Nota: normalmente después de crearlo se sube la foto en otro paso.
  // -------------------------------------------------------------------------
  Future<Empleado> crear(DatosEmpleado datos);

  // -------------------------------------------------------------------------
  // EDITAR EMPLEADO
  // Actualiza los datos del empleado.
  // La contraseña solo se cambia si llega un valor no nulo y no vacío.
  // -------------------------------------------------------------------------
  Future<Empleado> editar(int id, DatosEmpleado datos);

  // -------------------------------------------------------------------------
  // DAR DE BAJA (BAJA LÓGICA)
  // No borra el empleado físicamente, solo lo marca como inactivo.
  // -------------------------------------------------------------------------
  Future<void> darBaja(int id);

  // -------------------------------------------------------------------------
  // SUBIR FOTO DEL EMPLEADO
  // Sube o reemplaza la foto del empleado.
  // Devuelve la URL relativa de la nueva imagen.
  // -------------------------------------------------------------------------
  Future<String> subirFoto(int id, File archivo);

  // -------------------------------------------------------------------------
  // CANCELAR TODAS LAS CITAS FUTURAS DEL EMPLEADO
  // Devuelve un resumen con cuántas citas fueron canceladas.
  // -------------------------------------------------------------------------
  Future<ResumenCancelacionMasiva> cancelarCitasFuturas(int id);
}