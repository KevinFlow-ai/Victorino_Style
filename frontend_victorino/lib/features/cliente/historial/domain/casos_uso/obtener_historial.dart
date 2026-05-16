// Caso de uso: listar todas las citas del cliente (o filtradas por estado).
// Es el alimento de la pantalla Historial.

import '../../../shared/domain/entidades/cita_cliente.dart';
import '../../../shared/domain/entidades/estado_cita.dart';
import '../../../shared/domain/repositorios/citas_cliente_repositorio.dart';

class ObtenerHistorial {
  ObtenerHistorial(this._repositorio);
  final CitasClienteRepositorio _repositorio;

  // Si estado es null, devuelve TODAS las citas del cliente.
  // Si llega un estado concreto, el backend lo filtra (ej. solo CANCELADAS).
  Future<List<CitaCliente>> ejecutar({EstadoCita? estado}) {
    return _repositorio.listarMisCitas(estado: estado);
  }
}
