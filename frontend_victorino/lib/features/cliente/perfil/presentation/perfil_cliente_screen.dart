// Pantalla principal del Perfil del cliente.
// Contiene 3 secciones: Datos personales, Seguridad y Cuenta.
// La configuración de notificaciones push vive en la campana del Home
// (bottom_sheet_notificaciones), no aquí.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/api/api_endpoints.dart';
import '../../../../core/errors/api_exception.dart';
import '../../../../core/theme/app_colores.dart';
import '../../../../core/widgets_compartidos/selector_imagen.dart';
import '../../../../shared/modelos/sesion_usuario.dart';
import '../../../../shared/providers/sesion_provider.dart';
import '../application/perfil_providers.dart';
import '../domain/entidades/perfil_cliente.dart';
import 'widgets/dialogo_eliminar_cuenta.dart';

class PerfilClienteScreen extends ConsumerWidget {
  const PerfilClienteScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Cuando la sesión se cierra desde esta pantalla (botón "Cerrar sesión"
    // o "Eliminar mi cuenta"), navegamos al login ANTES de que el rebuild
    // pinte "Sin perfil cargado". Se dispara solo cuando antes había sesión
    // y ahora ya no la hay (transición true → false).
    ref.listen<AsyncValue<SesionUsuario?>>(sesionProvider, (prev, next) {
      final habiaSesion = prev?.value != null;
      final hayAhora = next.value != null;
      if (habiaSesion && !hayAhora && context.mounted) {
        context.go('/login');
      }
    });
    final perfilAsync = ref.watch(perfilNotifierProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mi perfil'),
        automaticallyImplyLeading: false,
      ),
      body: perfilAsync.when(
        data: (perfil) {
          if (perfil == null) {
            return const Center(child: Text('Sin perfil cargado'));
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(perfilNotifierProvider.notifier).recargar(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 12),
              children: [
                _CabeceraPerfil(perfil: perfil),
                const SizedBox(height: 16),
                _SeccionDatosPersonales(perfil: perfil),
                const Divider(height: 24),
                const _SeccionSeguridad(),
                const Divider(height: 24),
                const _SeccionCuenta(),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('No se pudo cargar el perfil: $e',
                style: const TextStyle(color: AppColors.textMuted)),
          ),
        ),
      ),
    );
  }
}

// ============================================================
//  CABECERA — foto circular + nombre + correo
// ============================================================
class _CabeceraPerfil extends ConsumerWidget {
  const _CabeceraPerfil({required this.perfil});
  final PerfilCliente perfil;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: () async {
              final archivo = await SelectorImagen.elegirYRecortar(
                context: context,
                formaCircular: true,
              );
              if (archivo != null) {
                try {
                  await ref
                      .read(perfilNotifierProvider.notifier)
                      .subirFoto(archivo);
                } catch (_) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('No se pudo subir la foto')),
                    );
                  }
                }
              }
            },
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: AppColors.accentGlow,
                  backgroundImage: perfil.fotoUrl == null || perfil.fotoUrl!.isEmpty
                      ? null
                      : NetworkImage(ApiEndpoints.urlImagen(perfil.fotoUrl)),
                  child: perfil.fotoUrl == null || perfil.fotoUrl!.isEmpty
                      ? Text(
                          perfil.nombre.isEmpty
                              ? '?'
                              : perfil.nombre.substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                          ),
                        )
                      : null,
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt,
                        color: Colors.white, size: 16),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(perfil.nombreCompleto,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w700)),
          Text(perfil.correo,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
        ],
      ),
    );
  }
}

// ============================================================
//  SECCIÓN — datos personales (editable)
// ============================================================
class _SeccionDatosPersonales extends ConsumerStatefulWidget {
  const _SeccionDatosPersonales({required this.perfil});
  final PerfilCliente perfil;

  @override
  ConsumerState<_SeccionDatosPersonales> createState() => _SeccionDatosPersonalesState();
}

class _SeccionDatosPersonalesState extends ConsumerState<_SeccionDatosPersonales> {
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _apellidosCtrl;
  late final TextEditingController _correoCtrl;
  late final TextEditingController _telCtrl;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController(text: widget.perfil.nombre);
    _apellidosCtrl = TextEditingController(text: widget.perfil.apellidos);
    _correoCtrl = TextEditingController(text: widget.perfil.correo);
    _telCtrl = TextEditingController(text: widget.perfil.telefono ?? '');
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _apellidosCtrl.dispose();
    _correoCtrl.dispose();
    _telCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    setState(() => _guardando = true);
    try {
      await ref.read(perfilNotifierProvider.notifier).editar(
            DatosPerfilCliente(
              nombre: _nombreCtrl.text,
              apellidos: _apellidosCtrl.text,
              correo: _correoCtrl.text,
              telefono: _telCtrl.text,
            ),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Datos actualizados')),
        );
      }
    } on ApiException catch (ex) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ex.failure.mensaje)),
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _Seccion(
      titulo: 'Datos personales',
      child: Column(
        children: [
          TextField(
            controller: _nombreCtrl,
            decoration: const InputDecoration(labelText: 'Nombre'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _apellidosCtrl,
            decoration: const InputDecoration(labelText: 'Apellidos'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _correoCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Correo'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _telCtrl,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Teléfono (opcional)'),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              icon: const Icon(Icons.save_rounded),
              label: const Text('Guardar cambios'),
              onPressed: _guardando ? null : _guardar,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
//  SECCIÓN — seguridad (cambio de contraseña)
// ============================================================
class _SeccionSeguridad extends ConsumerStatefulWidget {
  const _SeccionSeguridad();

  @override
  ConsumerState<_SeccionSeguridad> createState() => _SeccionSeguridadState();
}

class _SeccionSeguridadState extends ConsumerState<_SeccionSeguridad> {
  final _actual = TextEditingController();
  final _nueva = TextEditingController();
  final _repetir = TextEditingController();
  bool _guardando = false;

  @override
  void dispose() {
    _actual.dispose();
    _nueva.dispose();
    _repetir.dispose();
    super.dispose();
  }

  Future<void> _cambiar() async {
    if (_nueva.text != _repetir.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Las contraseñas nuevas no coinciden')),
      );
      return;
    }
    setState(() => _guardando = true);
    try {
      await ref.read(perfilNotifierProvider.notifier).cambiarPassword(
            actual: _actual.text,
            nueva: _nueva.text,
          );
      if (mounted) {
        _actual.clear();
        _nueva.clear();
        _repetir.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contraseña actualizada')),
        );
      }
    } on ApiException catch (ex) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ex.failure.mensaje)),
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _Seccion(
      titulo: 'Seguridad',
      child: Column(
        children: [
          TextField(
            controller: _actual,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Contraseña actual'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _nueva,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Nueva contraseña'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _repetir,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Repite la nueva contraseña'),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.lock_reset),
              label: const Text('Cambiar contraseña'),
              onPressed: _guardando ? null : _cambiar,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
//  SECCIÓN — cuenta (cerrar sesión / eliminar cuenta)
// ============================================================
class _SeccionCuenta extends ConsumerWidget {
  const _SeccionCuenta();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _Seccion(
      titulo: 'Cuenta',
      child: Column(
        children: [
          OutlinedButton.icon(
            icon: const Icon(Icons.logout),
            label: const Text('Cerrar sesión'),
            onPressed: () async {
              await ref.read(sesionProvider.notifier).cerrarSesion();
              if (context.mounted) context.go('/login');
            },
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.delete_outline),
            label: const Text('Eliminar mi cuenta'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
            ),
            onPressed: () async {
              final pwd = await mostrarDialogoEliminarCuenta(context);
              if (pwd == null || !context.mounted) return;
              try {
                await ref
                    .read(perfilNotifierProvider.notifier)
                    .eliminarCuenta(pwd);
                await ref.read(sesionProvider.notifier).cerrarSesion();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Tu cuenta ha sido eliminada')),
                  );
                  context.go('/login');
                }
              } on ApiException catch (ex) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(ex.failure.mensaje)),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }
}

// ============================================================
//  Helper visual: card de sección
// ============================================================
class _Seccion extends StatelessWidget {
  const _Seccion({required this.titulo, required this.child});
  final String titulo;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accentGlow),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
