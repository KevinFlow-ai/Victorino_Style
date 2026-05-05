// Configuración central de GoRouter.
//
// Reglas de redirección:
// - / (splash): siempre arranca aquí. Decide adónde ir según refresh + rol.
// - /login y /registro: solo accesibles SIN sesión. Si ya hay sesión, redirige a la home.
// - /cliente/home, /empleado/home: requieren sesión activa con rol acorde.
// - /admin/...: panel administrador. La pestaña inicial es /admin/agenda.
//   Internamente se monta como StatefulShellRoute para que cada pestaña conserve su pila.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/administrador/agenda/presentation/agenda_global_screen.dart';
import '../../features/administrador/agenda/presentation/avisos_screen.dart';
import '../../features/administrador/agenda/presentation/crear_walkin_screen.dart';
import '../../features/administrador/empleados/presentation/crear_editar_empleado_screen.dart';
import '../../features/administrador/empleados/presentation/lista_empleados_screen.dart';
import '../../features/administrador/metricas/presentation/metricas_screen.dart';
import '../../features/administrador/negocio/presentation/negocio_screen.dart';
import '../../features/administrador/servicios/presentation/crear_editar_servicio_screen.dart';
import '../../features/administrador/servicios/presentation/lista_servicios_screen.dart';
import '../../features/administrador/shell/presentation/shell_admin_screen.dart';
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
      GoRoute(path: '/', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/registro', builder: (_, _) => const RegistroScreen()),
      GoRoute(path: '/cliente/home', builder: (_, _) => const HomeCliente()),
      GoRoute(path: '/empleado/home', builder: (_, _) => const HomeEmpleado()),

      // Panel ADMIN con bottom nav y 5 ramas independientes.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            ShellAdminScreen(navigationShell: navigationShell),
        branches: [
          // 1) Agenda — pestaña inicial
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/agenda',
                builder: (_, _) => const AgendaGlobalScreen(),
                routes: [
                  GoRoute(
                    path: 'avisos',
                    parentNavigatorKey: null,
                    builder: (_, _) => const AvisosScreen(),
                  ),
                ],
              ),
            ],
          ),
          // 2) Estadísticas
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/admin/metricas', builder: (_, _) => const MetricasScreen()),
            ],
          ),
          // 3) Empleados
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/empleados',
                builder: (_, _) => const ListaEmpleadosScreen(),
                routes: [
                  GoRoute(
                    path: 'nuevo',
                    builder: (_, _) => const CrearEditarEmpleadoScreen(),
                  ),
                  GoRoute(
                    path: ':id/editar',
                    builder: (_, state) => CrearEditarEmpleadoScreen(
                      idEmpleado: int.parse(state.pathParameters['id']!),
                    ),
                  ),
                ],
              ),
            ],
          ),
          // 4) Servicios
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/servicios',
                builder: (_, _) => const ListaServiciosScreen(),
                routes: [
                  GoRoute(
                    path: 'nuevo',
                    builder: (_, _) => const CrearEditarServicioScreen(),
                  ),
                  GoRoute(
                    path: ':id/editar',
                    builder: (_, state) => CrearEditarServicioScreen(
                      idServicio: int.parse(state.pathParameters['id']!),
                    ),
                  ),
                ],
              ),
            ],
          ),
          // 5) Negocio
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/admin/negocio', builder: (_, _) => const NegocioScreen()),
            ],
          ),
        ],
      ),

      // Rutas auxiliares fuera del shell (modal-like).
      GoRoute(path: '/admin/walk-in', builder: (_, _) => const CrearWalkInScreen()),
      GoRoute(path: '/admin/avisos', builder: (_, _) => const AvisosScreen()),
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

      // Compatibilidad con la antigua ruta /admin/home → ahora /admin/agenda.
      if (hayLogin && ubicacion == '/admin/home') return '/admin/agenda';

      // Con sesión y en login/registro → home según rol.
      if (hayLogin && estaEnAuth) {
        return switch (sesion.rol) {
          'EMPLEADO' => '/empleado/home',
          'ADMINISTRADOR' => '/admin/agenda',
          _ => '/cliente/home',
        };
      }

      // Defensa: cliente/empleado intentando entrar a admin → vuelve a su home real.
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
            'ADMINISTRADOR' => '/admin/agenda',
            _ => '/cliente/home',
          };
        }
      }

      return null;
    },
  );
});
