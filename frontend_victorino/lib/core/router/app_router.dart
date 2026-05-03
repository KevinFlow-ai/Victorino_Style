// Configuración central de GoRouter.
//
// Reglas de redirección:
// - / (splash): siempre arranca aquí. Decide adónde ir según refresh + rol.
// - /login y /registro: solo accesibles SIN sesión. Si ya hay sesión, redirige a la home.
// - /cliente/home, /empleado/home, /admin/home: requieren sesión activa con rol acorde.
//   Si no hay sesión → /login. Si hay sesión con rol distinto → home del rol real.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/administrador/home/home_admin.dart';
import '../../features/cliente/home/home_cliente.dart';
import '../../features/cliente/registro/presentation/registro_screen.dart';
import '../../features/empleado/home/home_empleado.dart';
import '../../features/login_admin_empleado_cliente/presentation/login_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';
import '../../shared/providers/sesion_provider.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/registro', builder: (_, __) => const RegistroScreen()),
      GoRoute(path: '/cliente/home', builder: (_, __) => const HomeCliente()),
      GoRoute(path: '/empleado/home', builder: (_, __) => const HomeEmpleado()),
      GoRoute(path: '/admin/home', builder: (_, __) => const HomeAdmin()),
    ],
    redirect: (context, state) {
      final sesion = ref.read(sesionProvider).value;
      final ubicacion = state.matchedLocation;
      final estaEnSplash = ubicacion == '/';
      final estaEnAuth = ubicacion == '/login' || ubicacion == '/registro';
      final hayLogin = sesion != null;

      // El splash nunca redirige: él mismo decide a dónde ir tras intentar refresh.
      if (estaEnSplash) return null;

      // Sin sesión y en ruta protegida → login.
      if (!hayLogin && !estaEnAuth) return '/login';

      // Con sesión y en login/registro → home según rol.
      if (hayLogin && estaEnAuth) {
        return switch (sesion.rol) {
          'EMPLEADO' => '/empleado/home',
          'ADMINISTRADOR' => '/admin/home',
          _ => '/cliente/home',
        };
      }

      // Defensa: cliente intentando entrar a admin home → vuelve a su home real.
      if (hayLogin) {
        final esRutaCliente = ubicacion.startsWith('/cliente');
        final esRutaEmpleado = ubicacion.startsWith('/empleado');
        final esRutaAdmin = ubicacion.startsWith('/admin');

        final rolPermite = switch (sesion.rol) {
          'CLIENTE' => esRutaCliente,
          'EMPLEADO' => esRutaEmpleado,
          'ADMINISTRADOR' => esRutaAdmin,
          _ => false,
        };

        if (!rolPermite) {
          return switch (sesion.rol) {
            'EMPLEADO' => '/empleado/home',
            'ADMINISTRADOR' => '/admin/home',
            _ => '/cliente/home',
          };
        }
      }

      return null;
    },
  );
});
