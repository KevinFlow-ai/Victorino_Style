// Provider del repositorio de citas del cliente. Lo consumen los notifiers de
// Home, Reservar e Historial. Centralizado aquí para no inyectar Dio en cada
// submódulo por separado.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/providers/dio_provider.dart';
import '../data/repositorios/citas_cliente_repositorio_impl.dart';
import '../domain/repositorios/citas_cliente_repositorio.dart';

final citasClienteRepositorioProvider = Provider<CitasClienteRepositorio>((ref) {
  return CitasClienteRepositorioImpl(dio: ref.read(dioProvider));
});
