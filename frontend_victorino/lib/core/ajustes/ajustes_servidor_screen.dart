// Pantalla de configuración del servidor backend.
// Permite al usuario ver y cambiar la URL del backend sin recompilar la app.
//
// Acceso: icono ⚙️ en la esquina de la pantalla de Login.
// No requiere autenticación: es accesible antes de iniciar sesión.
//
// Flujo:
//   1. Muestra la URL actual (guardada en flutter_secure_storage o la de compilación).
//   2. El usuario edita la URL y pulsa "Guardar".
//   3. Se guarda en storage y se actualiza apiBaseUrlProvider.
//   4. Los providers de Dio se recrean automáticamente con la nueva URL.
//   5. Un botón "Probar conexión" hace un ping simple para verificar que el servidor responde.

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../api/api_url_provider.dart';
import '../theme/app_colores.dart';

class AjustesServidorScreen extends ConsumerStatefulWidget {
  const AjustesServidorScreen({super.key});

  @override
  ConsumerState<AjustesServidorScreen> createState() =>
      _AjustesServidorScreenState();
}

class _AjustesServidorScreenState extends ConsumerState<AjustesServidorScreen> {
  late final TextEditingController _urlCtrl;
  final _formKey = GlobalKey<FormState>();

  // Estados de UI
  bool _guardando = false;
  bool _probando = false;
  _EstadoConexion _estadoConexion = _EstadoConexion.sinProbar;
  String _mensajeConexion = '';

  @override
  void initState() {
    super.initState();
    // Prefillamos con la URL activa en este momento.
    _urlCtrl = TextEditingController(
      text: ref.read(apiBaseUrlProvider),
    );
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    super.dispose();
  }

  // ─── Guardar ────────────────────────────────────────────────────────────────

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    setState(() {
      _guardando = true;
      _estadoConexion = _EstadoConexion.sinProbar;
    });

    final nuevaUrl = _urlCtrl.text.trim();

    // 1) Persiste en storage.
    const storage = FlutterSecureStorage();
    await storage.write(key: kClaveApiUrl, value: nuevaUrl);

    // 2) Actualiza el provider → dioBaseProvider y dioProvider se recrean solos.
    ref.read(apiBaseUrlProvider.notifier).cambiarUrl(nuevaUrl);

    setState(() => _guardando = false);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'URL guardada correctamente',
          style: GoogleFonts.roboto(color: Colors.white),
        ),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ─── Probar conexión ────────────────────────────────────────────────────────

  Future<void> _probarConexion() async {
    final url = _urlCtrl.text.trim();
    if (url.isEmpty) return;
    FocusScope.of(context).unfocus();

    setState(() {
      _probando = true;
      _estadoConexion = _EstadoConexion.sinProbar;
      _mensajeConexion = '';
    });

    // Usamos un Dio sin interceptores para no interferir con la sesión.
    final dio = Dio(
      BaseOptions(
        baseUrl: url,
        connectTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 8),
        validateStatus: (_) => true, // cualquier código HTTP = servidor responde
      ),
    );

    try {
      // Llamamos a /auth/login con body vacío:
      // si el servidor responde (aunque sea 400/401/422) → está vivo.
      final response = await dio.post('/auth/login', data: {});
      final codigo = response.statusCode ?? 0;

      setState(() {
        _estadoConexion = _EstadoConexion.ok;
        _mensajeConexion =
            'Servidor alcanzable (HTTP $codigo). ¡Conexión correcta!';
      });
    } on DioException catch (e) {
      final String msg;
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        msg = 'Tiempo de espera agotado. Verifica la IP y que el servidor esté encendido.';
      } else if (e.type == DioExceptionType.connectionError) {
        msg = 'No se puede conectar. Verifica la IP, el puerto y el firewall del servidor.';
      } else if (e.response != null) {
        // Aunque Dio lance error, si hay respuesta → servidor vivo.
        setState(() {
          _estadoConexion = _EstadoConexion.ok;
          _mensajeConexion =
              'Servidor alcanzable (HTTP ${e.response!.statusCode}). ¡Conexión correcta!';
          _probando = false;
        });
        return;
      } else {
        msg = 'Error: ${e.message ?? 'Desconocido'}';
      }
      setState(() {
        _estadoConexion = _EstadoConexion.error;
        _mensajeConexion = msg;
      });
    } catch (e) {
      setState(() {
        _estadoConexion = _EstadoConexion.error;
        _mensajeConexion = 'Error inesperado: $e';
      });
    } finally {
      setState(() => _probando = false);
    }
  }

  // ─── Validador ──────────────────────────────────────────────────────────────

  String? _validarUrl(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'La URL no puede estar vacía';
    if (!v.startsWith('http://') && !v.startsWith('https://')) {
      return 'La URL debe empezar por http:// o https://';
    }
    return null;
  }

  // ─── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.textMain),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Ajustes del servidor',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textMain,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Descripción ─────────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          color: AppColors.primary, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Introduce la URL del PC donde está corriendo el servidor backend. '
                          'Todos los dispositivos de la red deben usar la misma URL.',
                          style: GoogleFonts.roboto(
                            fontSize: 13,
                            color: AppColors.textMuted,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // ── Campo URL ────────────────────────────────────────────────
                Text(
                  'URL DEL SERVIDOR',
                  style: GoogleFonts.roboto(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted.withValues(alpha: 0.8),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _urlCtrl,
                  validator: _validarUrl,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  keyboardType: TextInputType.url,
                  style: GoogleFonts.roboto(
                    fontSize: 15,
                    color: AppColors.textMain,
                  ),
                  onChanged: (_) {
                    // Limpiar el resultado de la prueba si el usuario edita.
                    if (_estadoConexion != _EstadoConexion.sinProbar) {
                      setState(() => _estadoConexion = _EstadoConexion.sinProbar);
                    }
                  },
                  decoration: InputDecoration(
                    hintText: 'http://192.168.1.100:8080/api/v1',
                    hintStyle: GoogleFonts.roboto(
                      color: AppColors.textMuted.withValues(alpha: 0.4),
                      fontSize: 15,
                    ),
                    prefixIcon: const Icon(Icons.link_rounded,
                        color: AppColors.textMuted, size: 22),
                    filled: true,
                    fillColor: const Color(0xFFF8F9FB),
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 18, horizontal: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide:
                          BorderSide(color: Colors.grey.shade100),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide:
                          BorderSide(color: Colors.grey.shade100),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                          color: AppColors.primary, width: 1.5),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // ── Ejemplos de formato ──────────────────────────────────────
                Text(
                  'Ejemplos:\n'
                  '• Mismo WiFi: http://192.168.1.100:8080/api/v1\n'
                  '• Android emulador: http://10.0.2.2:8080/api/v1',
                  style: GoogleFonts.roboto(
                    fontSize: 12,
                    color: AppColors.textMuted.withValues(alpha: 0.7),
                    height: 1.6,
                  ),
                ),

                const SizedBox(height: 32),

                // ── Botón Probar conexión ────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: (_probando || _guardando) ? null : _probarConexion,
                    icon: _probando
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppColors.primary),
                          )
                        : const Icon(Icons.wifi_tethering_rounded,
                            size: 20),
                    label: Text(
                      _probando ? 'Probando...' : 'Probar conexión',
                      style: GoogleFonts.poppins(
                          fontSize: 15, fontWeight: FontWeight.w500),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),

                // ── Resultado de la prueba ───────────────────────────────────
                if (_estadoConexion != _EstadoConexion.sinProbar) ...[
                  const SizedBox(height: 12),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: _estadoConexion == _EstadoConexion.ok
                          ? Colors.green.shade50
                          : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _estadoConexion == _EstadoConexion.ok
                            ? Colors.green.shade300
                            : Colors.red.shade300,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          _estadoConexion == _EstadoConexion.ok
                              ? Icons.check_circle_outline_rounded
                              : Icons.error_outline_rounded,
                          color: _estadoConexion == _EstadoConexion.ok
                              ? Colors.green.shade700
                              : Colors.red.shade700,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _mensajeConexion,
                            style: GoogleFonts.roboto(
                              fontSize: 13,
                              color: _estadoConexion == _EstadoConexion.ok
                                  ? Colors.green.shade800
                                  : Colors.red.shade800,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // ── Botón Guardar ───────────────────────────────────────────
                Container(
                  width: double.infinity,
                  height: 58,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        blurRadius: 20,
                        spreadRadius: 2,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: (_guardando || _probando) ? null : _guardar,
                    icon: _guardando
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.5, color: Colors.white),
                          )
                        : const Icon(Icons.save_rounded, size: 20),
                    label: Text(
                      _guardando ? 'Guardando...' : 'Guardar URL',
                      style: GoogleFonts.poppins(
                          fontSize: 17, fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ── Nota informativa ─────────────────────────────────────────
                Center(
                  child: Text(
                    'Tras guardar una nueva URL puede ser necesario\niniciar sesión de nuevo.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.roboto(
                      fontSize: 12,
                      color: AppColors.textMuted.withValues(alpha: 0.6),
                      height: 1.5,
                    ),
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _EstadoConexion { sinProbar, ok, error }


