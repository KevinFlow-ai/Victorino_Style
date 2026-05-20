import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/errors/failure.dart';
import '../../../core/theme/app_colores.dart';
import 'otp_screen.dart';
import 'application/forgot_password_notifier.dart';

class ForgotPasswordEmailScreen extends ConsumerStatefulWidget {
  const ForgotPasswordEmailScreen({super.key});

  @override
  ConsumerState<ForgotPasswordEmailScreen> createState() => _ForgotPasswordEmailScreenState();
}

class _ForgotPasswordEmailScreenState extends ConsumerState<ForgotPasswordEmailScreen> {
  final TextEditingController _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool isValidEmail(String email) {
    final regex = RegExp(
      r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+.[A-Za-z]{2,}$',
    );

    return regex.hasMatch(email);
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      final success = await ref
          .read(forgotPasswordNotifierProvider.notifier)
          .enviarCodigo(_emailController.text.trim());

      if (success && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const OtpVerificationScreen()),
        );
      } else if (mounted) {
        final state = ref.read(forgotPasswordNotifierProvider);
        state.status.whenOrNull(
          error: (error, _) {
            final mensaje = error is Failure ? error.mensaje : 'Error inesperado';
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(mensaje), backgroundColor: Colors.red),
            );
          },
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(forgotPasswordNotifierProvider.select((s) => s.status));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _customAppBar(context, 'Victorino Style'),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              const Text(
                'Recuperar\nContraseña',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMain,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Introduce tu correo electrónico para recibir un código de verificación.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 16),
              ),
              const SizedBox(height: 40),
              const Text(
                'CORREO ELECTRÓNICO',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMuted,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'ejemplo@gmail.com',
                  hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
                  prefixIcon: const Icon(Icons.email_outlined, color: AppColors.textMuted, size: 20),
                  filled: true,
                  fillColor: AppColors.textMuted.withOpacity(0.08),
                  contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Introduce un correo válido';
                  }
                  if (!isValidEmail(value)) {
                    return 'Introduce un correo válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              _primaryButton(
                context, 
                status is AsyncLoading ? 'Enviando...' : 'Enviar Código', 
                status is AsyncLoading ? null : _submit
              ),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _customAppBar(BuildContext context, String title) {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.primary, size: 20),
        onPressed: () => context.pop(),
      ),
      title: Text(
        title,
        style: const TextStyle(color: AppColors.textMain, fontSize: 18, fontWeight: FontWeight.bold),
      ),
      centerTitle: true,
    );
  }

  Widget _primaryButton(BuildContext context, String text, VoidCallback? onPressed) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: onPressed == null ? [] : [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: onPressed == null ? Colors.grey : AppColors.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: Text(
          text,
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
