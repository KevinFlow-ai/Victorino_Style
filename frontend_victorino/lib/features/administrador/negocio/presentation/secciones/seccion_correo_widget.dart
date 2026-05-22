// Sección "Configuración de correo (SMTP)" del panel Negocio.
// Permite al administrador configurar el servidor de envío de correos:
// Gmail, Outlook/Hotmail, educaMadrid o cualquier proveedor personalizado.
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/api/api_endpoints.dart';
import '../../../../../core/errors/api_exception.dart';
import '../../../../../core/theme/app_colores.dart';
import '../../../../../shared/providers/dio_provider.dart';
import '../../application/negocio_providers.dart';

class SeccionCorreoWidget extends ConsumerStatefulWidget {
  const SeccionCorreoWidget({super.key});

  @override
  ConsumerState<SeccionCorreoWidget> createState() => _SeccionCorreoWidgetState();
}

class _SeccionCorreoWidgetState extends ConsumerState<SeccionCorreoWidget> {
  final _formKey = GlobalKey<FormState>();

  final _hostCtrl = TextEditingController();
  final _portCtrl = TextEditingController();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  bool _ssl = false;
  bool _ocultarPass = true;
  bool _inicializado = false;
  bool _guardando = false;
  bool _probando = false;

  // ---- Presets de proveedores comunes ----
  static const _presets = [
    _Preset('Gmail',           'smtp.gmail.com',        587, false),
    _Preset('Outlook/Hotmail', 'smtp.office365.com',    587, false),
    _Preset('Yahoo',           'smtp.mail.yahoo.com',   587, false),
    _Preset('educaMadrid',     'smtp.educa.madrid.org', 587, false),
    _Preset('Personalizado',   '',                        0, false),
  ];

  @override
  void initState() {
    super.initState();
    // Escuchar cambios en el puerto para sincronizar el toggle SSL automáticamente
    _portCtrl.addListener(_sincronizarSslConPuerto);
  }

  /// Cuando el usuario escribe un puerto conocido, ajusta el toggle SSL.
  /// • 587 → STARTTLS → SSL OFF
  /// • 465 → SSL directo → SSL ON
  void _sincronizarSslConPuerto() {
    final p = int.tryParse(_portCtrl.text.trim());
    if (p == null) return;
    if (p == 587 && _ssl) {
      setState(() => _ssl = false);
    } else if (p == 465 && !_ssl) {
      setState(() => _ssl = true);
    }
  }

  @override
  void dispose() {
    _portCtrl.removeListener(_sincronizarSslConPuerto);
    _hostCtrl.dispose();
    _portCtrl.dispose();
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _aplicarPreset(_Preset p) {
    setState(() {
      _hostCtrl.text = p.host;
      _portCtrl.text = p.port > 0 ? '${p.port}' : '';
      _ssl = p.ssl;
    });
  }

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(configCorreoNotifierProvider);

    return _Card(
      titulo: 'Configuración de correo',
      icono: Icons.email_outlined,
      child: estado.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => Text('Error: $e',
            style: const TextStyle(color: Colors.red)),
        data: (config) {
          // Rellenar campos solo la primera vez que llegan datos del servidor
          if (!_inicializado) {
            _hostCtrl.text = config.host ?? '';
            _portCtrl.text = config.port != null ? '${config.port}' : '587';
            _userCtrl.text = config.user ?? '';
            _ssl = config.ssl;
            _inicializado = true;
          }

          return Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ---- Estado actual ----
                if (config.configurado)
                  _ChipEstado(
                    label: 'Configurado: ${config.user}',
                    color: Colors.green.shade700,
                  )
                else
                  _ChipEstado(
                    label: 'Usando configuración por defecto',
                    color: AppColors.textMuted,
                  ),

                const SizedBox(height: 12),

                // ---- Presets ----
                const Text('Seleccionar proveedor:',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: _presets
                      .map((p) => ActionChip(
                            label: Text(p.nombre,
                                style: const TextStyle(fontSize: 12)),
                            onPressed: () => _aplicarPreset(p),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 0),
                          ))
                      .toList(),
                ),

                const SizedBox(height: 14),

                // ---- Host ----
                TextFormField(
                  controller: _hostCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Servidor SMTP (host)',
                    hintText: 'smtp.gmail.com',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Obligatorio' : null,
                ),
                const SizedBox(height: 10),

                // ---- Puerto + SSL ----
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _portCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Puerto',
                          hintText: '587',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Obligatorio';
                          final n = int.tryParse(v.trim());
                          if (n == null || n < 1 || n > 65535) {
                            return '1–65535';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('SSL directo',
                            style: TextStyle(
                                fontSize: 12, color: AppColors.textMuted)),
                        Text(
                          _ssl ? '(puerto 465)' : '(puerto 587)',
                          style: TextStyle(
                              fontSize: 10,
                              color: _ssl ? Colors.green.shade700 : AppColors.textMuted),
                        ),
                        Switch(
                          value: _ssl,
                          onChanged: (v) => setState(() {
                            _ssl = v;
                            if (v && _portCtrl.text == '587') {
                              _portCtrl.text = '465';
                            } else if (!v && _portCtrl.text == '465') {
                              _portCtrl.text = '587';
                            }
                          }),
                          activeThumbColor: AppColors.primary,
                        ),
                      ],
                    ),
                  ],
                ),

                // ---- ADVERTENCIA combinación incoherente ----
                Builder(builder: (_) {
                  final puerto = int.tryParse(_portCtrl.text.trim());
                  final combinacionMala = puerto != null &&
                      ((_ssl && puerto == 587) || (!_ssl && puerto == 465));
                  if (!combinacionMala) return const SizedBox.shrink();
                  return Container(
                    margin: const EdgeInsets.only(top: 6),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade300),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded,
                            color: Colors.orange.shade700, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _ssl
                                ? 'Puerto 587 + SSL directo no es compatible. '
                                    'Usa puerto 465 para SSL directo, o desactiva SSL para usar STARTTLS (587).'
                                : 'Puerto 465 normalmente requiere SSL directo activado.',
                            style: TextStyle(
                                fontSize: 12, color: Colors.orange.shade800),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 10),

                // ---- Usuario (remitente) ----
                TextFormField(
                  controller: _userCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Correo remitente',
                    hintText: 'peluqueria@gmail.com',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Obligatorio' : null,
                ),
                const SizedBox(height: 10),

                // ---- Contraseña ----
                // ---- Nota App Password (Gmail/educaMadrid) ----
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(fontSize: 12, color: Colors.blue.shade900),
                            children: const [
                              TextSpan(
                                text: 'Gmail/educaMadrid: ',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              TextSpan(
                                text: 'NO uses tu contraseña normal. '
                                    'Ve a tu cuenta Google → Seguridad → '
                                    'Verificación en dos pasos → Contraseñas de aplicación. '
                                    'Genera una (16 caracteres) y pégala aquí.',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                TextFormField(
                  controller: _passCtrl,
                  obscureText: _ocultarPass,
                  decoration: InputDecoration(
                    labelText: config.configurado
                        ? 'Nueva contraseña (dejar vacío para no cambiar)'
                        : 'Contraseña / App Password',
                    border: const OutlineInputBorder(),
                    isDense: true,
                    suffixIcon: IconButton(
                      icon: Icon(_ocultarPass
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () =>
                          setState(() => _ocultarPass = !_ocultarPass),
                    ),
                  ),
                  // Si ya hay config, la contraseña es opcional (mantiene la anterior)
                  validator: (v) {
                    if (!config.configurado &&
                        (v == null || v.trim().isEmpty)) {
                      return 'Obligatorio la primera vez';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 14),

                // ---- Botón guardar + botón probar ----
                // Wrap (en lugar de Row) para que en pantallas estrechas
                // los botones pasen a la siguiente línea sin desbordarse.
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    // Botón "Probar envío" — solo habilitado si ya hay config guardada
                    if (config.configurado)
                      OutlinedButton.icon(
                        onPressed: (_probando || _guardando) ? null : _probar,
                        icon: const Icon(Icons.send_outlined, size: 18),
                        label: Text(_probando ? 'Enviando...' : 'Probar envío'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                        ),
                      ),
                    FilledButton.icon(
                      onPressed: _guardando ? null : _guardar,
                      icon: const Icon(Icons.save_outlined, size: 18),
                      label: Text(_guardando ? 'Guardando...' : 'Guardar correo'),
                      style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Muestra el error SMTP en un diálogo para que el admin pueda leer el mensaje completo.
  void _mostrarErrorSmtp(BuildContext context, String msg) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Row(children: [
          Icon(Icons.error_outline, color: Colors.red),
          SizedBox(width: 8),
          Text('Error al enviar correo', style: TextStyle(fontSize: 16)),
        ]),
        content: SingleChildScrollView(
          child: Text(msg, style: const TextStyle(fontSize: 13)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Future<void> _probar() async {
    setState(() => _probando = true);
    try {
      final dio = ref.read(dioProvider);
      await dio.post<Map<String, dynamic>>(ApiEndpoints.adminCorreoProbar);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Correo de prueba enviado. Revisa tu bandeja de entrada.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } on ApiException catch (e) {
      final msg = e.failure.mensaje;
      if (mounted) {
        _mostrarErrorSmtp(context, msg);
      }
    } catch (e) {
      // DioException u otro error
      String msg = e.toString();
      if (e is DioException && e.response?.data is Map) {
        msg = (e.response!.data as Map)['message']?.toString() ?? msg;
      }
      if (mounted) {
        _mostrarErrorSmtp(context, msg);
      }
    } finally {
      if (mounted) setState(() => _probando = false);
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    // Si la contraseña está vacía y ya había una configurada,
    // necesitamos la contraseña actual — pedirla al usuario no es viable aquí,
    // así que informamos de que debe introducirla siempre.
    final pass = _passCtrl.text.trim();
    if (pass.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor introduce la contraseña para guardar'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    setState(() => _guardando = true);
    try {
      await ref.read(configCorreoNotifierProvider.notifier).guardar(
            _hostCtrl.text.trim(),
            int.parse(_portCtrl.text.trim()),
            _userCtrl.text.trim(),
            pass,
            _ssl,
          );
      _passCtrl.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Configuración de correo guardada'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }
}

// ---------------------------------------------------------------------------

class _Preset {
  const _Preset(this.nombre, this.host, this.port, this.ssl);
  final String nombre;
  final String host;
  final int port;
  final bool ssl;
}

class _ChipEstado extends StatelessWidget {
  const _ChipEstado({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(label,
          style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.titulo, required this.icono, required this.child});
  final String titulo;
  final IconData icono;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icono, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(titulo,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 16)),
          ]),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}



