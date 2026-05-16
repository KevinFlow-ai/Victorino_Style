// Caso de uso: confirmar la modificación de una cita ya CONFIRMADA desde el wizard
// precargado. Mismas validaciones que crear_cita, más el id de la cita a editar.

import '../../../../../core/errors/api_exception.dart';
import '../../../../../core/errors/failure.dart';
import '../../../shared/domain/entidades/cita_cliente.dart';
import '../../../shared/domain/entidades/datos_reserva.dart';
import '../../../shared/domain/repositorios/citas_cliente_repositorio.dart';

class ModificarCita {
  ModificarCita(this._repositorio);
  final CitasClienteRepositorio _repositorio;

  Future<CitaCliente> ejecutar(int idCita, DatosReserva datos) async {
    if (!datos.esCompleto) {
      throw ApiException(const FailureValidacion(
        'Completa todos los pasos antes de guardar los cambios',
        {},
      ));
    }
    return _repositorio.modificar(idCita, datos);
  }
}
