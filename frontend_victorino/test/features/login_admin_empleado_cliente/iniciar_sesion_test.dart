// Tests del caso de uso IniciarSesion. Mockean el AuthRepositorio con mocktail.
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_victorino/core/errors/api_exception.dart';
import 'package:frontend_victorino/core/errors/failure.dart';
import 'package:frontend_victorino/features/login_admin_empleado_cliente/domain/casos_uso/iniciar_sesion.dart';
import 'package:frontend_victorino/features/login_admin_empleado_cliente/domain/entidades/credenciales.dart';
import 'package:frontend_victorino/features/login_admin_empleado_cliente/domain/repositorios/auth_repositorio.dart';
import 'package:frontend_victorino/shared/modelos/sesion_usuario.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepositorio extends Mock implements AuthRepositorio {}

void main() {
  late _MockAuthRepositorio repo;
  late IniciarSesion casoUso;

  setUpAll(() {
    registerFallbackValue(const Credenciales(correo: 'a@b.es', password: 'x'));
  });

  setUp(() {
    repo = _MockAuthRepositorio();
    casoUso = IniciarSesion(repo);
  });

  test('correo vacío lanza ApiException(FailureValidacion)', () async {
    expect(
      () => casoUso.ejecutar(const Credenciales(correo: '', password: 'Abcd1234')),
      throwsA(isA<ApiException>().having(
        (e) => e.failure,
        'failure',
        isA<FailureValidacion>(),
      )),
    );
  });

  test('login OK devuelve ResultadoAuth con sesión y refresh', () async {
    final credenciales = const Credenciales(correo: 'ana@victorino.es', password: 'Abcd1234');
    final resultado = ResultadoAuth(
      sesion: const SesionUsuario(
        idUsuario: 7,
        rol: 'CLIENTE',
        nombreCompleto: 'Ana García',
        accessToken: 'access',
      ),
      refreshToken: 'refresh',
    );
    when(() => repo.iniciarSesion(any())).thenAnswer((_) async => resultado);

    final r = await casoUso.ejecutar(credenciales);

    expect(r.sesion.idUsuario, 7);
    expect(r.sesion.rol, 'CLIENTE');
    expect(r.refreshToken, 'refresh');
    verify(() => repo.iniciarSesion(credenciales)).called(1);
  });

  test('credenciales inválidas → propaga ApiException(FailureCredenciales)', () async {
    when(() => repo.iniciarSesion(any())).thenThrow(
      ApiException(const FailureCredenciales()),
    );

    expect(
      () => casoUso.ejecutar(const Credenciales(correo: 'x@x.es', password: 'Abcd1234')),
      throwsA(isA<ApiException>().having(
        (e) => e.failure,
        'failure',
        isA<FailureCredenciales>(),
      )),
    );
  });

  test('sin red → propaga ApiException(FailureRed)', () async {
    when(() => repo.iniciarSesion(any())).thenThrow(
      ApiException(const FailureRed()),
    );

    expect(
      () => casoUso.ejecutar(const Credenciales(correo: 'a@b.es', password: 'Abcd1234')),
      throwsA(isA<ApiException>().having(
        (e) => e.failure,
        'failure',
        isA<FailureRed>(),
      )),
    );
  });
}
