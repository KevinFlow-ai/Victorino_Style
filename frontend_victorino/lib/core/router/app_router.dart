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
import '../../features/administrador/notificaciones/presentation/enviar_aviso_screen.dart';
import '../../features/administrador/negocio/presentation/negocio_screen.dart';
import '../../features/administrador/servicios/presentation/crear_editar_servicio_screen.dart';
import '../../features/administrador/servicios/presentation/lista_servicios_screen.dart';
import '../../features/administrador/shell/presentation/shell_admin_screen.dart';
import '../../features/cliente/historial/presentation/detalle_cita_screen.dart';
import '../../features/cliente/historial/presentation/historial_screen.dart';
import '../../features/cliente/home/presentation/home_cliente_screen.dart';
import '../../features/cliente/perfil/presentation/perfil_cliente_screen.dart';
import '../../features/cliente/registro/presentation/registro_screen.dart';
import '../../features/cliente/reservar/presentation/pestana_reservar_screen.dart';
import '../../features/cliente/reservar/presentation/wizard_reserva_screen.dart';
import '../../features/cliente/shell/presentation/shell_cliente_screen.dart';
import '../../features/empleado/home/home_empleado.dart';
import '../../features/forgot_password/forgot_password_screen.dart';
import '../../features/login_admin_empleado_cliente/presentation/login_screen.dart';
import '../../features/notificaciones/presentation/bandeja_notificaciones_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';
import '../../shared/providers/sesion_provider.dart';


final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/registro', builder: (_, _) => const RegistroScreen()),
      GoRoute(path: '/forgot-password', builder: (_, __) => const ForgotPasswordEmailScreen()),

      // Panel CLIENTE con bottom nav y 4 ramas independientes.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            ShellClienteScreen(navigationShell: navigationShell),
        branches: [
          // 1) Inicio (Home) — pestaña inicial
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/cliente/inicio',
                builder: (_, _) => const HomeClienteScreen(),
              ),
            ],
          ),
          // 2) Reservar — bloqueo preventivo + wizard como ruta hija
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/cliente/reservar',
                builder: (_, _) => const PestanaReservarScreen(),
                routes: [
                  GoRoute(
                    path: 'wizard',
                    builder: (_, state) {
                      final idServicioStr = state.uri.queryParameters['idServicio'];
                      final idCitaStr = state.uri.queryParameters['idCita'];
                      return WizardReservaScreen(
                        idServicioPreseleccionado:
                            idServicioStr == null ? null : int.tryParse(idServicioStr),
                        idCitaEditar:
                            idCitaStr == null ? null : int.tryParse(idCitaStr),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          // 3) Historial
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/cliente/historial',
                builder: (_, _) => const HistorialScreen(),
                routes: [
                  GoRoute(
                    path: 'detalle/:id',
                    builder: (_, state) => DetalleCitaScreen(
                      idCita: int.parse(state.pathParameters['id']!),
                    ),
                  ),
                ],
              ),
            ],
          ),
          // 4) Perfil
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/cliente/perfil',
                builder: (_, _) => const PerfilClienteScreen(),
              ),
            ],
          ),
        ],
      ),

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
      GoRoute(path: '/admin/notificaciones/enviar', builder: (_, _) => const EnviarAvisoScreen()),

      // Bandeja de notificaciones in-app (accesible desde cualquier rol).
      GoRoute(
        path: '/notificaciones',
        builder: (_, _) => const BandejaNotificacionesScreen(),
      ),
    ],
    redirect: (context, state) {
      final sesion = ref.read(sesionProvider).value;
      final ubicacion = state.matchedLocation;
      final estaEnSplash = ubicacion == '/';
      final estaEnAuth = ubicacion == '/login' ||
          ubicacion == '/registro' ||
          ubicacion == '/forgot-password';
      final hayLogin = sesion != null;

      // El splash nunca redirige: él mismo decide a dónde ir tras intentar refresh.
      if (estaEnSplash) return null;

      // Sin sesión y en ruta protegida → login.
      if (!hayLogin && !estaEnAuth) return '/login';

      // Compatibilidad con la antigua ruta /admin/home → ahora /admin/agenda.
      if (hayLogin && ubicacion == '/admin/home') return '/admin/agenda';
      // Compatibilidad con la antigua ruta /cliente/home → ahora /cliente/inicio.
      if (hayLogin && ubicacion == '/cliente/home') return '/cliente/inicio';

      // Con sesión y en login/registro → home según rol.
      if (hayLogin && estaEnAuth) {
        return switch (sesion.rol) {
          'EMPLEADO' => '/empleado/home',
          'ADMINISTRADOR' => '/admin/agenda',
          _ => '/cliente/inicio',
        };
      }

      // Defensa: cliente/empleado intentando entrar a admin → vuelve a su home real.
      if (hayLogin) {
        final esRutaCliente = ubicacion.startsWith('/cliente');
        final esRutaEmpleado = ubicacion.startsWith('/empleado');
        final esRutaAdmin = ubicacion.startsWith('/admin');
        // /notificaciones es accesible para cualquier rol autenticado.
        final esRutaCompartida = ubicacion.startsWith('/notificaciones');

        final rolPermite = esRutaCompartida || switch (sesion.rol) {
          'CLIENTE' => esRutaCliente,
          'EMPLEADO' => esRutaEmpleado,
          'ADMINISTRADOR' => esRutaAdmin,
          _ => false,
        };

        if (!rolPermite) {
          return switch (sesion.rol) {
            'EMPLEADO' => '/empleado/home',
            'ADMINISTRADOR' => '/admin/agenda',
            _ => '/cliente/inicio',
          };
        }
      }

      return null;
    },
  );
});
