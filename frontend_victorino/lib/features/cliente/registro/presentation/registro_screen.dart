// Pantalla de registro de cliente. Conserva el diseño visual de la maqueta
// inicial y añade validaciones, llamada al notifier y redirección por rol.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/theme/app_colores.dart';
import '../../../../shared/widgets/error_snackbar.dart';
import '../application/registro_notifier.dart';

class RegistroScreen extends ConsumerStatefulWidget {
  const RegistroScreen({super.key});

  @override
  ConsumerState<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends ConsumerState<RegistroScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _apellidosCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _correoCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  bool _passwordVisible = false;
  bool _aceptaRgpd = false;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _apellidosCtrl.dispose();
    _telefonoCtrl.dispose();
    _correoCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _intentarRegistrar() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_aceptaRgpd) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes aceptar la política de privacidad')),
      );
      return;
    }

    FocusScope.of(context).unfocus();

    final ok = await ref.read(registroNotifierProvider.notifier).ejecutar(
          nombre: _nombreCtrl.text,
          apellidos: _apellidosCtrl.text,
          telefono: _telefonoCtrl.text.trim().isEmpty ? null : _telefonoCtrl.text,
          correo: _correoCtrl.text,
          password: _passwordCtrl.text,
        );

    if (!mounted) return;

    if (!ok) {
      final state = ref.read(registroNotifierProvider);
      final fallo = state is AsyncError ? state.error as Failure : const FailureServidor();
      mostrarErrorSnackbar(context, fallo);
      return;
    }

    // Tras registrarse, el cliente queda logueado: vamos directo a su home.
    context.go('/cliente/home');
  }

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(registroNotifierProvider);
    final cargando = estado.isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                Text(
                  'Victorino Style',
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMain,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Crea tu perfil para empezar a reservar',
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 32),

                _label('NOMBRE'),
                const SizedBox(height: 8),
                _campo(
                  controller: _nombreCtrl,
                  hintText: 'Ej. Kevin',
                  prefixIcon: Icons.person_outline,
                  validator: (v) => v == null || v.trim().isEmpty ? 'Nombre obligatorio' : null,
                ),

                const SizedBox(height: 20),
                _label('APELLIDOS'),
                const SizedBox(height: 8),
                _campo(
                  controller: _apellidosCtrl,
                  hintText: 'Ej. Flores',
                  prefixIcon: Icons.badge_outlined,
                  validator: (v) => v == null || v.trim().isEmpty ? 'Apellidos obligatorios' : null,
                ),

                const SizedBox(height: 20),
                _label('TELÉFONO (opcional)'),
                const SizedBox(height: 8),
                _campo(
                  controller: _telefonoCtrl,
                  hintText: '+34 600 000 000',
                  prefixIcon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),

                const SizedBox(height: 20),
                _label('CORREO ELECTRÓNICO'),
                const SizedBox(height: 8),
                _campo(
                  controller: _correoCtrl,
                  hintText: 'nombre@ejemplo.com',
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    final s = v?.trim() ?? '';
                    if (s.isEmpty) return 'Correo obligatorio';
                    final regex = RegExp(r'^[\w\.\-]+@[\w\-]+\.[\w\.\-]+$');
                    if (!regex.hasMatch(s)) return 'Correo no válido';
                    return null;
                  },
                ),

                const SizedBox(height: 20),
                _label('CONTRASEÑA'),
                const SizedBox(height: 8),
                _campo(
                  controller: _passwordCtrl,
                  hintText: '........',
                  prefixIcon: Icons.lock_outline,
                  obscureText: !_passwordVisible,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Contraseña obligatoria';
                    final regex = RegExp(r'^(?=.*[A-Z])(?=.*\d).{8,72}$');
                    if (!regex.hasMatch(v)) {
                      return 'Mín. 8 caracteres, 1 mayúscula y 1 número';
                    }
                    return null;
                  },
                  suffixIcon: IconButton(
                    icon: Icon(
                      _passwordVisible
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppColors.textMuted.withValues(alpha: 0.6),
                      size: 22,
                    ),
                    onPressed: () => setState(() => _passwordVisible = !_passwordVisible),
                  ),
                ),

                const SizedBox(height: 20),
                _label('CONFIRMAR CONTRASEÑA'),
                const SizedBox(height: 8),
                _campo(
                  controller: _confirmPasswordCtrl,
                  hintText: '........',
                  prefixIcon: Icons.lock_outline,
                  obscureText: !_passwordVisible,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Repite la contraseña';
                    if (v != _passwordCtrl.text) return 'Las contraseñas no coinciden';
                    return null;
                  },
                ),

                const SizedBox(height: 20),
                Row(
                  children: [
                    Checkbox(
                      value: _aceptaRgpd,
                      activeColor: AppColors.primary,
                      onChanged: (v) => setState(() => _aceptaRgpd = v ?? false),
                    ),
                    Expanded(
                      child: Text(
                        'Acepto la política de privacidad y el tratamiento de mis datos según el RGPD.',
                        style: GoogleFonts.roboto(
                          fontSize: 13,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
                _botonRegistrar(cargando: cargando),

                const SizedBox(height: 32),
                _linkLogin(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String label) => Align(
        alignment: Alignment.centerLeft,
        child: Text(
          label,
          style: GoogleFonts.roboto(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textMuted.withValues(alpha: 0.8),
            letterSpacing: 0.5,
          ),
        ),
      );

  Widget _campo({
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
          color: AppColors.textMuted.withValues(alpha: 0.5),
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
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }

  Widget _botonRegistrar({required bool cargando}) {
    return Container(
      width: double.infinity,
      height: 58,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: cargando ? null : _intentarRegistrar,
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
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Crear cuenta',
                    style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, size: 20),
                ],
              ),
      ),
    );
  }

  Widget _linkLogin() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '¿Ya tienes una cuenta? ',
          style: GoogleFonts.roboto(fontSize: 15, color: AppColors.textMuted),
        ),
        GestureDetector(
          onTap: () => context.go('/login'),
          child: Text(
            'Iniciar sesión',
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
