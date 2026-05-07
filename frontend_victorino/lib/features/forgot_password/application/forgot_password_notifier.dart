import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../login_admin_empleado_cliente/application/auth_providers.dart';
import '../../../core/errors/api_exception.dart';
import '../../../core/errors/failure.dart';

class ForgotPasswordState {
  final String email;
  final String code;
  final AsyncValue<void> status;

  ForgotPasswordState({
    this.email = '',
    this.code = '',
    this.status = const AsyncData(null),
  });

  ForgotPasswordState copyWith({
    String? email,
    String? code,
    AsyncValue<void>? status,
  }) {
    return ForgotPasswordState(
      email: email ?? this.email,
      code: code ?? this.code,
      status: status ?? this.status,
    );
  }
}

class ForgotPasswordNotifier extends Notifier<ForgotPasswordState> {
  @override
  ForgotPasswordState build() {
    return ForgotPasswordState();
  }

  Future<bool> enviarCodigo(String email) async {
    final repositorio = ref.read(authRepositorioProvider);
    state = state.copyWith(status: const AsyncLoading(), email: email);
    try {
      await repositorio.enviarCodigoRecuperacion(email);
      state = state.copyWith(status: const AsyncData(null));
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(status: AsyncError(e.failure, StackTrace.current));
      return false;
    } catch (e) {
      state = state.copyWith(status: AsyncError(const FailureServidor(), StackTrace.current));
      return false;
    }
  }

  Future<bool> verificarCodigo(String code) async {
    final repositorio = ref.read(authRepositorioProvider);
    state = state.copyWith(status: const AsyncLoading(), code: code);
    try {
      await repositorio.verificarCodigoOtp(state.email, code);
      state = state.copyWith(status: const AsyncData(null));
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(status: AsyncError(e.failure, StackTrace.current));
      return false;
    } catch (e) {
      state = state.copyWith(status: AsyncError(const FailureServidor(), StackTrace.current));
      return false;
    }
  }

  Future<bool> restablecerContrasena(String nuevaPassword) async {
    final repositorio = ref.read(authRepositorioProvider);
    state = state.copyWith(status: const AsyncLoading());
    try {
      await repositorio.restablecerContrasena(state.email, state.code, nuevaPassword);
      state = state.copyWith(status: const AsyncData(null));
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(status: AsyncError(e.failure, StackTrace.current));
      return false;
    } catch (e) {
      state = state.copyWith(status: AsyncError(const FailureServidor(), StackTrace.current));
      return false;
    }
  }
}

final forgotPasswordNotifierProvider =
    NotifierProvider<ForgotPasswordNotifier, ForgotPasswordState>(() {
  return ForgotPasswordNotifier();
});
