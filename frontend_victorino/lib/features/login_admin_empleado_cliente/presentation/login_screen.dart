// Pantalla de login compartida para CLIENTE, EMPLEADO y ADMINISTRADOR.
// Mantiene el mismo diseño visual que la versión inicial (logo, tarjeta con glow,
// fuentes Poppins/Roboto), pero cablea la lógica con Riverpod + GoRouter.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/errors/failure.dart';
import '../../../core/theme/app_colores.dart';
import '../../../shared/widgets/error_snackbar.dart';
import '../application/login_notifier.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  // Form key para validar correo y contraseña antes de llamar al backend.
  final _formKey = GlobalKey<FormState>();

  // Controladores que leen el texto de los campos.
  final _correoCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  // Mostrar/ocultar el contenido de la contraseña.
  bool _passwordVisible = false;

  @override
  void dispose() {
    _correoCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  // Acción del botón "Iniciar sesión": valida formulario, dispara notifier,
  // y según el rol redirige a la home correspondiente.
  Future<void> _intentarLogin() async {
    if (!_formKey.currentState!.validate()) return;

    // Cierra el teclado para que la animación de loading no quede tapada.
    FocusScope.of(context).unfocus();

    final rol = await ref.read(loginNotifierProvider.notifier).ejecutar(
          correo: _correoCtrl.text.trim(),
          password: _passwordCtrl.text,
        );

    if (!mounted) return;

    if (rol == null) {
      // El notifier ya marcó el error en su state. Mostramos el snackbar.
      final state = ref.read(loginNotifierProvider);
      final fallo = state is AsyncError ? state.error as Failure : const FailureServidor();
      mostrarErrorSnackbar(context, fallo);
      return;
    }

    // Login OK → navega al home según rol.
    final ruta = switch (rol) {
      'CLIENTE' => '/cliente/home',
      'EMPLEADO' => '/empleado/home',
      'ADMINISTRADOR' => '/admin/home',
      _ => '/cliente/home',
    };
    context.go(ruta);
  }

  @override
  Widget build(BuildContext context) {
    // Observamos el estado del notifier para pintar el loader.
    final estado = ref.watch(loginNotifierProvider);
    final cargando = estado.isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ── Contenido principal (sin cambios) ──────────────────────────────
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    // Logo superior (mismo que la maqueta original).
                    Center(
                      child: Image.asset(
                        'assets/logos_app/logo_login.png',
                        height: 120,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Tarjeta con efecto glow (idéntica a la versión inicial).
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            blurRadius: 30,
                            spreadRadius: 5,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Bienvenido de nuevo',
                            style: GoogleFonts.poppins(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textMain,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tu mejor versión empieza aquí.',
                            style: GoogleFonts.roboto(
                              fontSize: 14,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Correo electrónico.
                          _buildInputLabel('CORREO ELECTRÓNICO'),
                          const SizedBox(height: 8),
                          _buildTextField(
                            controller: _correoCtrl,
                            hintText: 'nombre@ejemplo.com',
                            prefixIcon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            validator: _validarCorreo,
                          ),

                          const SizedBox(height: 20),

                          // Contraseña con toggle de visibilidad.
                          _buildInputLabel('CONTRASEÑA'),
                          const SizedBox(height: 8),
                          _buildTextField(
                            controller: _passwordCtrl,
                            hintText: '********',
                            prefixIcon: Icons.lock_outline,
                            obscureText: !_passwordVisible,
                            validator: _validarPassword,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _passwordVisible
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: AppColors.textMuted.withValues(alpha: 0.6),
                                size: 22,
                              ),
                              onPressed: () =>
                                  setState(() => _passwordVisible = !_passwordVisible),
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Botón principal con loader integrado.
                          _buildLoginButton(cargando: cargando),

                          const SizedBox(height: 24),

                          // Link a recuperación (lógica fuera de alcance ahora mismo).
                          GestureDetector(
                            onTap: () => context.push('/forgot-password'),
                            child: Text(
                              '¿Olvidaste tu contraseña?',
                              style: GoogleFonts.roboto(
                                fontSize: 14,
                                color: AppColors.textMuted,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),
                          const Divider(color: Color(0xFFEEEEEE)),
                          const SizedBox(height: 24),

                          _buildRegisterLink(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),

          // ── Icono de ajustes del servidor (esquina superior derecha) ────────
          /*Positioned(
            top: 0,
            right: 4,
            child: SafeArea(
              child: Tooltip(
                message: 'Configurar servidor',
                child: IconButton(
                  icon: Icon(
                    Icons.settings_outlined,
                    color: AppColors.textMuted.withValues(alpha: 0.5),
                    size: 24,
                  ),
                  onPressed: () => context.push('/ajustes/servidor'),
                ),
              ),
            ),
          ),


           */

        ],
      ),
    );
  }

  // ===== Validadores =====

  String? _validarCorreo(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'El correo es obligatorio';
    final regex = RegExp(r'^[\w\.\-]+@[\w\-]+\.[\w\.\-]+$');
    if (!regex.hasMatch(v)) return 'Introduce un correo válido';
    return null;
  }

  String? _validarPassword(String? value) {
    if (value == null || value.isEmpty) return 'La contraseña es obligatoria';
    return null;
  }

  // ===== Componentes UI (mismos que la maqueta original) =====

  Widget _buildInputLabel(String label) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        style: GoogleFonts.roboto(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.textMuted.withValues(alpha: 0.8),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      style: GoogleFonts.roboto(fontSize: 16, color: AppColors.textMain),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: GoogleFonts.roboto(
          color: AppColors.textMuted.withValues(alpha: 0.4),
          fontSize: 16,
        ),
        prefixIcon: Icon(
          prefixIcon,
          color: AppColors.textMuted.withValues(alpha: 0.6),
          size: 22,
        ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFFF8F9FB),
        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade100),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade100),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildLoginButton({required bool cargando}) {
    return Container(
      width: double.infinity,
      height: 58,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.4),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: cargando ? null : _intentarLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: cargando
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
              )
            : Text(
                'Iniciar sesión',
                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }

  Widget _buildRegisterLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '¿Aún no tienes cuenta? ',
          style: GoogleFonts.roboto(fontSize: 15, color: AppColors.textMuted),
        ),
        GestureDetector(
          // GoRouter en lugar de Navigator.push.
          onTap: () => context.push('/registro'),
          child: Text(
            'Crear cuenta',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }
}
