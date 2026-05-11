// Pantalla para que el administrador envíe un AVISO_GENERAL a cualquier usuario.
// Usa el endpoint POST /api/v1/notificaciones/aviso-general (requiere rol ADMINISTRADOR).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/api/api_endpoints.dart';
import '../../../../core/theme/app_colores.dart';
import '../../../../shared/providers/dio_provider.dart';

class EnviarAvisoScreen extends ConsumerStatefulWidget {
  const EnviarAvisoScreen({super.key});

  @override
  ConsumerState<EnviarAvisoScreen> createState() => _EnviarAvisoScreenState();
}

class _EnviarAvisoScreenState extends ConsumerState<EnviarAvisoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _tituloController = TextEditingController();
  final _cuerpoController = TextEditingController();

  bool _enviando = false;
  String? _mensajeResultado;
  bool _envioCorrecto = false;

  @override
  void dispose() {
    _idController.dispose();
    _tituloController.dispose();
    _cuerpoController.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _enviando = true;
      _mensajeResultado = null;
    });

    try {
      final dio = ref.read(dioProvider);
      await dio.post<void>(
        ApiEndpoints.notificacionesAvisoGeneral,
        data: {
          'idDestinatario': int.parse(_idController.text.trim()),
          'titulo': _tituloController.text.trim(),
          'cuerpo': _cuerpoController.text.trim(),
        },
      );

      setState(() {
        _envioCorrecto = true;
        _mensajeResultado =
        'Aviso enviado correctamente al usuario con ID ${_idController.text.trim()}.';
        // Limpiar campos tras envío exitoso.
        _idController.clear();
        _tituloController.clear();
        _cuerpoController.clear();
      });
    } catch (e) {
      setState(() {
        _envioCorrecto = false;
        _mensajeResultado = 'Error al enviar el aviso: $e';
      });
    } finally {
      setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          'Enviar aviso general',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            color: AppColors.textMain,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Descripción del formulario.
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.accentGlow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Escribe el ID del destinatario (idUsuario), un título y el cuerpo del mensaje. '
                            'La notificación aparecerá en la bandeja del usuario y se enviará '
                            'por push si tiene tokens FCM registrados.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.primary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Campo ID del destinatario.
              TextFormField(
                controller: _idController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'ID del destinatario',
                  hintText: 'Ej: 1 (admin), 2 (empleado), 3 (cliente)…',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Campo obligatorio';
                  if (int.tryParse(v.trim()) == null) return 'Debe ser un número entero';
                  if (int.parse(v.trim()) <= 0) return 'El ID debe ser mayor que 0';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Campo título.
              TextFormField(
                controller: _tituloController,
                decoration: InputDecoration(
                  labelText: 'Título',
                  hintText: 'Ej: Aviso importante de Victorino Style',
                  prefixIcon: const Icon(Icons.title_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  counterText: '',
                ),
                maxLength: 250,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Campo obligatorio';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Campo cuerpo.
              TextFormField(
                controller: _cuerpoController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Mensaje',
                  hintText: 'Escribe el cuerpo del aviso…',
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(bottom: 60),
                    child: Icon(Icons.message_outlined),
                  ),
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  counterText: '',
                ),
                maxLength: 500,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Campo obligatorio';
                  return null;
                },
              ),
              const SizedBox(height: 28),

              // Botón de envío.
              FilledButton.icon(
                onPressed: _enviando ? null : _enviar,
                icon: _enviando
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Icon(Icons.send_rounded),
                label: Text(
                  _enviando ? 'Enviando…' : 'Enviar aviso',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              // Resultado del envío.
              if (_mensajeResultado != null) ...[
                const SizedBox(height: 20),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _envioCorrecto
                        ? Colors.green.shade50
                        : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _envioCorrecto
                          ? Colors.green.shade300
                          : Colors.red.shade300,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        _envioCorrecto
                            ? Icons.check_circle_outline
                            : Icons.error_outline,
                        color: _envioCorrecto
                            ? Colors.green.shade700
                            : Colors.red.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _mensajeResultado!,
                          style: TextStyle(
                            color: _envioCorrecto
                                ? Colors.green.shade800
                                : Colors.red.shade800,
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

