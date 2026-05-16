// Caso de uso: confirmar la reserva en el Paso 4 del wizard.
// Valida defensivamente que el estado del wizard esté completo antes de llamar al backend.

import '../../../../../core/errors/api_exception.dart';
import '../../../../../core/errors/failure.dart';
import '../../../shared/domain/entidades/cita_cliente.dart';
import '../../../shared/domain/entidades/datos_reserva.dart';
import '../../../shared/domain/repositorios/citas_cliente_repositorio.dart';

class CrearCita {
  CrearCita(this._repositorio);
  final CitasClienteRepositorio _repositorio;

  Future<CitaCliente> ejecutar(DatosReserva datos) async {
    if (!datos.esCompleto) {
      // Si llegamos aquí es porque el frontend no validó bien. Mensaje genérico.
      throw ApiException(const FailureValidacion(
        'Completa todos los pasos antes de confirmar la reserva',
        {},
      ));
    }
    return _repositorio.reservar(datos);
  }
}
