import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/errors/api_exception.dart';
import '../../../../core/theme/app_colores.dart';
import '../application/servicios_providers.dart';
import '../domain/entidades/servicio.dart';

class CrearEditarServicioScreen extends ConsumerStatefulWidget {
  const CrearEditarServicioScreen({super.key, this.idServicio});
  final int? idServicio;

  bool get esEdicion => idServicio != null;

  @override
  ConsumerState<CrearEditarServicioScreen> createState() => _CrearEditarServicioScreenState();
}

class _CrearEditarServicioScreenState extends ConsumerState<CrearEditarServicioScreen> {
  final _form = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _descripcion = TextEditingController();
  final _duracion = TextEditingController(text: '30');
  final _precio = TextEditingController();
  File? _foto;
  bool _enviando = false;
  bool _cargando = false;

  @override
  void initState() {
    super.initState();
    if (widget.esEdicion) _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    try {
      final s = await ref.read(servicioRepositorioProvider).obtener(widget.idServicio!);
      _nombre.text = s.nombre;
      _descripcion.text = s.descripcion ?? '';
      _duracion.text = s.duracionMinutos.toString();
      _precio.text = s.precio.toString();
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _elegirFoto() async {
    final f = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (f != null) setState(() => _foto = File(f.path));
  }

  Future<void> _guardar() async {
    if (!_form.currentState!.validate()) return;
    if (!widget.esEdicion && _foto == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La foto es obligatoria al crear un servicio')),
      );
      return;
    }
    setState(() => _enviando = true);
    try {
      final datos = DatosServicio(
        nombre: _nombre.text,
        descripcion: _descripcion.text.trim().isEmpty ? null : _descripcion.text,
        duracionMinutos: int.parse(_duracion.text.trim()),
        precio: num.parse(_precio.text.trim().replaceAll(',', '.')),
      );
      Servicio guardado;
      if (widget.esEdicion) {
        guardado = await ref.read(editarServicioProvider).ejecutar(widget.idServicio!, datos);
      } else {
        guardado = await ref.read(crearServicioProvider).ejecutar(datos);
      }
      if (_foto != null) {
        await ref.read(subirFotoServicioProvider).ejecutar(guardado.id, _foto!);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.esEdicion ? 'Servicio actualizado' : 'Servicio creado')),
        );
        context.pop();
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.failure.mensaje)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo guardar el servicio')),
        );
      }
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(widget.esEdicion ? 'Editar servicio' : 'Nuevo servicio',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: AppColors.textMain)),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _form,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  GestureDetector(
                    onTap: _enviando ? null : _elegirFoto,
                    child: Container(
                      height: 180,
                      decoration: BoxDecoration(
                        color: AppColors.accentGlow,
                        borderRadius: BorderRadius.circular(12),
                        image: _foto != null
                            ? DecorationImage(image: FileImage(_foto!), fit: BoxFit.cover)
                            : null,
                      ),
                      child: _foto == null
                          ? const Center(child: Icon(Icons.add_a_photo, color: AppColors.primary, size: 40))
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _campo('Nombre del servicio', _nombre, requerido: true),
                  _campo('Descripción (opcional)', _descripcion, maxLines: 3),
                  Row(
                    children: [
                      Expanded(
                        child: _campo('Duración (min)', _duracion,
                            requerido: true, teclado: TextInputType.number),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _campo('Precio (€)', _precio,
                            requerido: true, teclado: TextInputType.number),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _enviando ? null : _guardar,
                    child: _enviando
                        ? const SizedBox(
                            height: 20, width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(widget.esEdicion ? 'Guardar cambios' : 'Crear servicio'),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _campo(String label, TextEditingController c,
      {bool requerido = false, int maxLines = 1, TextInputType? teclado}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c,
        keyboardType: teclado,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: AppColors.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        validator: (v) {
          if (!requerido) return null;
          if (v == null || v.trim().isEmpty) return 'Campo obligatorio';
          return null;
        },
      ),
    );
  }
}
