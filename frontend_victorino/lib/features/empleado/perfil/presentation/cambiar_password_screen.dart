import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colores.dart';
import '../application/perfil_empleado_providers.dart';

class CambiarPasswordEmpleadoScreen extends ConsumerStatefulWidget {
  const CambiarPasswordEmpleadoScreen({super.key});

  @override
  ConsumerState<CambiarPasswordEmpleadoScreen> createState() => _CambiarPasswordEmpleadoScreenState();
}

class _CambiarPasswordEmpleadoScreenState extends ConsumerState<CambiarPasswordEmpleadoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _actualController = TextEditingController();
  final _nuevaController = TextEditingController();
  final _confirmarController = TextEditingController();
  bool _obscureActual = true;
  bool _obscureNueva = true;
  bool _obscureConfirmar = true;

  @override
  void dispose() {
    _actualController.dispose();
    _nuevaController.dispose();
    _confirmarController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    await ref.read(cambiarPasswordEmpleadoProvider.notifier).ejecutar(
          actual: _actualController.text,
          nueva: _nuevaController.text,
        );

    final state = ref.read(cambiarPasswordEmpleadoProvider);
    if (!state.hasError) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Contraseña actualizada correctamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${state.error}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(cambiarPasswordEmpleadoProvider);
    final cargando = estado.isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'CAMBIAR CONTRASEÑA',
          style: GoogleFonts.poppins(
            color: AppColors.primary,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textMain, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Asegúrate de elegir una contraseña segura que no uses en otros sitios.',
                style: GoogleFonts.poppins(color: AppColors.textMuted, fontSize: 14),
              ),
              const SizedBox(height: 32),
              
              _FieldLabel(label: 'Contraseña Actual'),
              TextFormField(
                controller: _actualController,
                obscureText: _obscureActual,
                decoration: _inputDecoration(
                  hint: 'Introduce tu contraseña actual',
                  isObscured: _obscureActual,
                  onToggle: () => setState(() => _obscureActual = !_obscureActual),
                ),
                validator: (v) => (v == null || v.isEmpty) ? 'Campo obligatorio' : null,
              ),
              
              const SizedBox(height: 24),
              
              _FieldLabel(label: 'Nueva Contraseña'),
              TextFormField(
                controller: _nuevaController,
                obscureText: _obscureNueva,
                decoration: _inputDecoration(
                  hint: 'Min. 8 carac., Mayús. y Número',
                  isObscured: _obscureNueva,
                  onToggle: () => setState(() => _obscureNueva = !_obscureNueva),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Campo obligatorio';
                  if (v.length < 8) return 'Mínimo 8 caracteres';
                  if (!RegExp(r'[A-Z]').hasMatch(v)) return 'Debe contener al menos una mayúscula';
                  if (!RegExp(r'[0-9]').hasMatch(v)) return 'Debe contener al menos un número';
                  return null;
                },
              ),
              
              const SizedBox(height: 24),
              
              _FieldLabel(label: 'Confirmar Nueva Contraseña'),
              TextFormField(
                controller: _confirmarController,
                obscureText: _obscureConfirmar,
                decoration: _inputDecoration(
                  hint: 'Repite la nueva contraseña',
                  isObscured: _obscureConfirmar,
                  onToggle: () => setState(() => _obscureConfirmar = !_obscureConfirmar),
                ),
                validator: (v) {
                  if (v != _nuevaController.text) return 'Las contraseñas no coinciden';
                  return null;
                },
              ),
              
              const SizedBox(height: 48),
              
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: cargando ? null : _guardar,
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
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          'ACTUALIZAR CONTRASEÑA',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, letterSpacing: 1),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required bool isObscured,
    required VoidCallback onToggle,
  }) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      suffixIcon: IconButton(
        icon: Icon(isObscured ? Icons.visibility_off_outlined : Icons.visibility_outlined, 
                   color: AppColors.textMuted, size: 20),
        onPressed: onToggle,
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: AppColors.textMain,
          letterSpacing: 1,
        ),
      ),
    );
  }
}
