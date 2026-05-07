import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colores.dart';
import 'application/forgot_password_notifier.dart';

class NewPasswordScreen extends ConsumerStatefulWidget {
  const NewPasswordScreen({super.key});

  @override
  ConsumerState<NewPasswordScreen> createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends ConsumerState<NewPasswordScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  // Variables de estado para las nuevas validaciones
  bool _hasEightChars = false;
  bool _hasUppercase = false;
  bool _hasNumber = false;
  bool _passwordsMatch = false;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_validatePassword);
    _confirmController.addListener(_validatePassword);
  }

  void _validatePassword() {
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    setState(() {
      // 1. Mínimo 8 caracteres
      _hasEightChars = password.length >= 8;

      // 2. Al menos una mayúscula
      _hasUppercase = password.contains(RegExp(r'[A-Z]'));

      // 3. Al menos un número
      _hasNumber = password.contains(RegExp(r'[0-9]'));

      // 4. Coincidencia de contraseñas
      _passwordsMatch = password.isNotEmpty && password == confirm;
    });
  }

  // El botón solo se activa si se cumplen los 4 checks
  bool get _isButtonEnabled =>
      _hasEightChars && _hasUppercase && _hasNumber && _passwordsMatch;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _submit() async {
    final success = await ref
        .read(forgotPasswordNotifierProvider.notifier)
        .restablecerContrasena(_passwordController.text);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Contraseña restablecida con éxito'),
          backgroundColor: Colors.green,
        ),
      );
      // Volver al login. Ajustar la ruta según corresponda.
      context.go('/login'); 
    } else if (mounted) {
      final state = ref.read(forgotPasswordNotifierProvider);
      state.status.whenOrNull(
        error: (error, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error.toString()), backgroundColor: Colors.red),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(forgotPasswordNotifierProvider.select((s) => s.status));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _customAppBar(context, 'Nueva Contraseña'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),
            const Center(
              child: Text(
                'Nueva Contraseña',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textMain),
              ),
            ),
            const SizedBox(height: 8),
            const Center(
              child: Text(
                'Crea una nueva contraseña segura para tu cuenta',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted, fontSize: 15),
              ),
            ),
            const SizedBox(height: 40),
            _passwordField('Nueva Contraseña', _passwordController),
            const SizedBox(height: 24),
            _passwordField('Confirmar Contraseña', _confirmController),
            const SizedBox(height: 24),

            // Requisitos visuales actualizados
            _requirementRow(_hasEightChars, 'Mínimo 8 caracteres'),
            _requirementRow(_hasUppercase, 'Al menos una mayúscula'),
            _requirementRow(_hasNumber, 'Al menos un número'),
            _requirementRow(_passwordsMatch, 'Las contraseñas coinciden'),

            const SizedBox(height: 40),

            _primaryButtonWithIcon(
              status is AsyncLoading ? 'Restableciendo...' : 'Restablecer Contraseña',
              Icons.lock_outline,
              _isButtonEnabled && status is! AsyncLoading ? _submit : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _passwordField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMain)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: true,
          decoration: InputDecoration(
            hintText: '••••••••',
            hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
            suffixIcon: const Icon(Icons.visibility_outlined, color: AppColors.textMuted, size: 20),
            filled: true,
            fillColor: AppColors.textMuted.withOpacity(0.08),
            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }

  Widget _requirementRow(bool met, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        children: [
          Icon(
            met ? Icons.check_circle : Icons.radio_button_unchecked,
            color: met ? const Color(0xFF4CAF50) : AppColors.textMuted.withOpacity(0.5),
            size: 20,
          ),
          const SizedBox(width: 10),
          Text(
            text,
            style: TextStyle(
                color: met ? const Color(0xFF4CAF50) : AppColors.textMuted,
                fontSize: 14
            ),
          ),
        ],
      ),
    );
  }

  Widget _primaryButtonWithIcon(String text, IconData icon, VoidCallback? onPressed) {
    bool isEnabled = onPressed != null;

    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: isEnabled ? [
          BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
        ] : [],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isEnabled ? AppColors.primary : Colors.grey.shade400,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(text, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(width: 12),
            Icon(icon, color: Colors.white, size: 20),
          ],
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
        onPressed: () => Navigator.maybePop(context),
      ),
      title: Text(title, style: const TextStyle(color: AppColors.textMain, fontSize: 18, fontWeight: FontWeight.bold)),
      centerTitle: true,
    );
  }
}
