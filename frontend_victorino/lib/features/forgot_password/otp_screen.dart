import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colores.dart';
import 'new_password_screen.dart';
import 'application/forgot_password_notifier.dart';

class OtpVerificationScreen extends ConsumerStatefulWidget {
  const OtpVerificationScreen({super.key});

  @override
  ConsumerState<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController(text: ''));
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  @override
  void dispose() {
    for (var c in _controllers) c.dispose();
    for (var f in _focusNodes) f.dispose();
    super.dispose();
  }

  void _onChanged(String value, int index) {
    setState(() {});

    if (value.length > 1) {
      String digitsOnly = value.replaceAll(RegExp(r'[^0-9]'), '');
      for (int i = 0; i < 6; i++) {
        if (i < digitsOnly.length) _controllers[i].text = digitsOnly[i];
      }
      FocusScope.of(context).unfocus();
      return;
    }

    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  String get _code => _controllers.map((e) => e.text).join();

  void _verifyOtp() async {
    final success = await ref
        .read(forgotPasswordNotifierProvider.notifier)
        .verificarCodigo(_code);

    if (success && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const NewPasswordScreen()),
      );
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
      appBar: _customAppBar(context, 'Victorino Style'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),
            const Text('Verificar Código',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.textMain)),
            const SizedBox(height: 16),
            const Text('Hemos enviado un código a tu correo. Por favor, introdúcelo debajo.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 16)),
            const SizedBox(height: 40),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              children: List.generate(6, (index) => _otpBox(index)),
            ),
            const SizedBox(height: 40),
            _primaryButton(
                context,
                status is AsyncLoading ? 'Verificando...' : 'Verificar',
                _code.length == 6 && status is! AsyncLoading ? _verifyOtp : null),
            const SizedBox(height: 24),
            Center(
              child: GestureDetector(
                onTap: () {
                  final email = ref.read(forgotPasswordNotifierProvider).email;
                  ref.read(forgotPasswordNotifierProvider.notifier).enviarCodigo(email);
                },
                child: const Text.rich(
                  TextSpan(
                    text: '¿No recibiste nada? ',
                    style: TextStyle(color: AppColors.textMuted),
                    children: [
                      TextSpan(
                          text: 'Reenviar código',
                          style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _otpBox(int index) {
    return SizedBox(
      width: 48,
      height: 56,
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
        ],
        textAlign: TextAlign.center,
        maxLength: 1,
        enableInteractiveSelection: false,
        cursorColor: AppColors.primary,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
        onChanged: (value) => _onChanged(value, index),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.zero,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
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
        onPressed: () => Navigator.maybePop(context),
      ),
      title: Text(title,
          style: const TextStyle(color: AppColors.textMain, fontSize: 18, fontWeight: FontWeight.bold)),
      centerTitle: true,
    );
  }

  Widget _primaryButton(BuildContext context, String text, VoidCallback? onPressed) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: onPressed == null
            ? []
            : [
                BoxShadow(
                    color: AppColors.primary.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
              ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: onPressed == null ? Colors.grey.shade300 : AppColors.primary,
          disabledBackgroundColor: Colors.grey.shade300,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: Text(
          text,
          style: TextStyle(
              color: onPressed == null ? Colors.grey.shade600 : Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
