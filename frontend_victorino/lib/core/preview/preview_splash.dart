import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/api/api_endpoints.dart';
import '../../../../core/api/dio_cliente.dart';
import '../../../../core/theme/app_colores.dart';
import '../../../../shared/modelos/sesion_usuario.dart';
import '../../../../shared/providers/secure_storage_provider.dart';
import '../../../../shared/providers/sesion_provider.dart';

/// ---------------------------------------------------------------------------
///  WIDGET PRINCIPAL DEL SPLASH
/// ---------------------------------------------------------------------------
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _restaurarSesion());
  }

  @override
  Widget build(BuildContext context) {
    return const SplashLayout(); // UI separada
  }

  /// -------------------------------------------------------------------------
  ///  INTENTAR RESTAURAR SESIÓN
  /// -------------------------------------------------------------------------
  Future<void> _restaurarSesion() async {
    final storage = ref.read(secureStorageProvider);

    final refresh = await storage.leerRefreshToken();
    final idUsuario = await storage.leerIdUsuario();
    final rol = await storage.leerRol();

    // Delay estético
    await Future.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;

    // No hay sesión → login
    if (refresh == null || idUsuario == null || rol == null) {
      context.go('/login');
      return;
    }

    try {
      final dio = DioCliente.crear();
      final resp = await dio.post<Map<String, dynamic>>(
        ApiEndpoints.authRefresh,
        data: {'refreshToken': refresh},
      );

      final nuevoAccess = resp.data?['accessToken'] as String?;
      if (nuevoAccess == null) throw Exception('refresh sin token');

      final sesion = SesionUsuario(
        idUsuario: idUsuario,
        rol: rol,
        nombreCompleto: '',
        accessToken: nuevoAccess,
      );

      await ref.read(sesionProvider.notifier).establecerSesion(sesion, refresh);

      if (!mounted) return;

      final ruta = switch (rol) {
        'EMPLEADO' => '/empleado/home',
        'ADMINISTRADOR' => '/admin/home',
        _ => '/cliente/home',
      };

      context.go(ruta);
    } catch (_) {
      await storage.limpiarSesion();
      if (!mounted) return;
      context.go('/login');
    }
  }
}

/// ---------------------------------------------------------------------------
///  UI DEL SPLASH (SIN LÓGICA) → permite hacer PREVIEW
/// ---------------------------------------------------------------------------
class SplashLayout extends StatelessWidget {
  const SplashLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/logos_app/logo_app1.png', height: 200),
            const SizedBox(height: 24),
            Text(
              'Victorino Style',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textMain,
              ),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}




