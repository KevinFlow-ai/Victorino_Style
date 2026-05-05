// Pantalla para crear o editar un empleado.
//
// Si `idEmpleado` es null → modo CREAR.
// Si tiene valor → modo EDITAR (la pwd queda opcional).
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/errors/api_exception.dart';
import '../../../../core/theme/app_colores.dart';
import '../application/empleados_providers.dart';
import '../domain/entidades/empleado.dart';

class CrearEditarEmpleadoScreen extends ConsumerStatefulWidget {
  const CrearEditarEmpleadoScreen({super.key, this.idEmpleado});
  final int? idEmpleado;

  bool get esEdicion => idEmpleado != null;

  @override
  ConsumerState<CrearEditarEmpleadoScreen> createState() => _CrearEditarEmpleadoScreenState();
}

class _CrearEditarEmpleadoScreenState extends ConsumerState<CrearEditarEmpleadoScreen> {
  final _form = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _apellidos = TextEditingController();
  final _telefono = TextEditingController();
  final _correo = TextEditingController();
  final _password = TextEditingController();
  File? _foto;
  bool _enviando = false;
  bool _cargando = false;

  @override
  void initState() {
    super.initState();
    if (widget.esEdicion) _cargarEmpleado();
  }

  Future<void> _cargarEmpleado() async {
    setState(() => _cargando = true);
    try {
      final emp = await ref
          .read(empleadoRepositorioProvider)
          .obtener(widget.idEmpleado!);
      _nombre.text = emp.nombre;
      _apellidos.text = emp.apellidos;
      _correo.text = emp.correo;
      _telefono.text = emp.telefono ?? '';
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  void dispose() {
    _nombre.dispose();
    _apellidos.dispose();
    _telefono.dispose();
    _correo.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _elegirFoto() async {
    final picker = ImagePicker();
    final fichero = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (fichero != null) setState(() => _foto = File(fichero.path));
  }

  Future<void> _guardar() async {
    if (!_form.currentState!.validate()) return;
    if (!widget.esEdicion && _foto == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La foto es obligatoria al crear un empleado')),
      );
      return;
    }
    setState(() => _enviando = true);
    try {
      final datos = DatosEmpleado(
        nombre: _nombre.text,
        apellidos: _apellidos.text,
        correo: _correo.text,
        telefono: _telefono.text.trim().isEmpty ? null : _telefono.text,
        passwordProvisional: _password.text.trim().isEmpty ? null : _password.text,
      );
      Empleado guardado;
      if (widget.esEdicion) {
        guardado = await ref.read(editarEmpleadoProvider).ejecutar(widget.idEmpleado!, datos);
      } else {
        guardado = await ref.read(crearEmpleadoProvider).ejecutar(datos);
      }
      if (_foto != null) {
        await ref.read(subirFotoEmpleadoProvider).ejecutar(guardado.id, _foto!);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.esEdicion ? 'Empleado actualizado' : 'Empleado creado')),
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
          const SnackBar(content: Text('No se pudo guardar el empleado')),
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
        title: Text(widget.esEdicion ? 'Editar empleado' : 'Nuevo empleado',
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
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: AppColors.accentGlow,
                      backgroundImage: _foto != null ? FileImage(_foto!) : null,
                      child: _foto == null
                          ? const Icon(Icons.camera_alt, color: AppColors.primary, size: 32)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      widget.esEdicion
                          ? 'Toca para sustituir la foto (opcional)'
                          : 'Toca para añadir foto (obligatorio)',
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _campo('Nombre', _nombre, requerido: true),
                  _campo('Apellidos', _apellidos, requerido: true),
                  _campo('Teléfono (opcional)', _telefono, teclado: TextInputType.phone),
                  _campo('Correo', _correo, requerido: true, teclado: TextInputType.emailAddress),
                  _campo(
                    widget.esEdicion ? 'Nueva contraseña (opcional)' : 'Contraseña provisional',
                    _password,
                    requerido: !widget.esEdicion,
                    obscure: true,
                  ),
                  const SizedBox(height: 24),
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
                        : Text(widget.esEdicion ? 'Guardar cambios' : 'Crear empleado'),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _campo(String label, TextEditingController c,
      {bool requerido = false, bool obscure = false, TextInputType? teclado}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c,
        obscureText: obscure,
        keyboardType: teclado,
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
