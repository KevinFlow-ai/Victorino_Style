// Splash que intenta restaurar la sesión usando el refresh token guardado.
// Si lo consigue, el redirect del router lleva a la home del rol.
// Si falla o no hay refresh, redirige a /login.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/api/api_endpoints.dart';
import '../../../core/api/dio_cliente.dart';
import '../../../core/theme/app_colores.dart';
import '../../../shared/modelos/sesion_usuario.dart';
import '../../../shared/providers/secure_storage_provider.dart';
import '../../../shared/providers/sesion_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Ejecutamos la restauración después del primer frame.
    // Esto asegura que context y ref estén listos.
    WidgetsBinding.instance.addPostFrameCallback((_) => _intentarRestaurar());
  }

  Future<void> _intentarRestaurar() async {
    final storage = ref.read(secureStorageProvider); // Leemos el almacenamiento seguro (refresh, id, rol).
    final refresh = await storage.leerRefreshToken();
    final idUsuario = await storage.leerIdUsuario();
    final rol = await storage.leerRol();

    // Pequeño delay estético para que el splash sea visible.
    await Future.delayed(const Duration(milliseconds: 700));

    if (!mounted) return;

    // Sin sesión persistida → directo a login.
    if (refresh == null || idUsuario == null || rol == null) {
      context.go('/login');
      return;
    }

    // Hay refresh: pedimos un access nuevo y reconstruimos la sesión en memoria.
    try {
      final dio = DioCliente.crear(); // Cliente HTTP temporal solo para el refresh
      final resp = await dio.post<Map<String, dynamic>>(
        ApiEndpoints.authRefresh,
        data: {'refreshToken': refresh},
      );
      final nuevoAccess = resp.data?['accessToken'] as String?;
      if (nuevoAccess == null) throw Exception('refresh sin token');

      // Construimos una sesión mínima. nombre/foto se rellenarán cuando el
      // usuario navegue a su perfil o la home las pida al backend.
      final sesion = SesionUsuario(
        idUsuario: idUsuario,
        rol: rol,
        nombreCompleto: '',
        accessToken: nuevoAccess,
      );
      // Guardamos la sesión en memoria (Riverpod)
      await ref.read(sesionProvider.notifier).establecerSesion(sesion, refresh);

      // Redirigimos según el rol.
      if (!mounted) return;
      final ruta = switch (rol) {
        'EMPLEADO' => '/empleado/home',
        'ADMINISTRADOR' => '/admin/home',
        _ => '/cliente/home',
      };
      context.go(ruta);
    } catch (_) {
      // Si el refresh falla → limpiamos sesión y vamos al login.
      await storage.limpiarSesion();
      if (!mounted) return;
      context.go('/login');
    }
  }

  @override // UI del splash: logo, nombre de la app y spinner.
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/logos_app/logo_login.png', height: 140),
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


/*

Este archivo es muy importante porque controla el arranque de la app y decide
si el usuario debe ir al login o directamente a su home.

RESUMEN DEL ARCHIVO
Este archivo define la pantalla SplashScreen, cuya responsabilidad es:

1. Restaurar sesión al abrir la app
Lee del almacenamiento seguro (SecureStorage) los datos persistidos:
• refresh token
• idUsuario
• rol

 2. Decidir si hay sesión válida
• Si falta alguno → ir al login.
• Si existe refresh token → pedir un nuevo access token al backend.

 3. Reconstruir la sesión en memoria
• Crea un SesionUsuario mínimo.
• Llama al sesionProvider.notifier para establecer la sesión.

 4. Redirigir según el rol
• CLIENTE → /cliente/home
• EMPLEADO → /empleado/home
• ADMINISTRADOR → /admin/home

 5. Mostrar un splash visual mientras todoo esto ocurre


Relación dentro de tu arquitectura
SplashScreen (UI)
   ↓
SecureStorage (infraestructura local)
   ↓
Dio → Backend (refresh)
   ↓
SesionNotifier (estado global)
   ↓
Router (GoRouter)

 */