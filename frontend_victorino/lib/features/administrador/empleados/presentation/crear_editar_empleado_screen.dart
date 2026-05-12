// Pantalla para crear o editar un empleado.
//
// Si `idEmpleado` es null → modo CREAR.
// Si tiene valor → modo EDITAR (la pwd queda opcional).
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/api/api_endpoints.dart';
import '../../../../core/errors/api_exception.dart';
import '../../../../core/theme/app_colores.dart';
import '../../../../core/widgets_compartidos/selector_imagen.dart';
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
  // URL relativa de la foto que ya tiene el empleado en el backend.
  // Se usa para mostrar la foto actual al entrar en modo edición; si el admin
  // elige una foto nueva (`_foto != null`), prevalece la nueva sobre la URL.
  String _fotoUrlActual = '';
  bool _enviando = false;
  bool _cargando = false;

  @override
  void initState() {
    super.initState();
    if (widget.esEdicion) _cargarEmpleado();

    // 🔥 Listener para actualizar validación dinámica
    _password.addListener(() => setState(() {}));
    _correo.addListener(() => setState(() {}));
  }

  // 🔥 VALIDACIÓN DINÁMICA CONTRASEÑA
  bool get _tieneLongitud =>
      _password.text.trim().length >= 8 && _password.text.trim().length <= 72;

  bool get _tieneMayuscula =>
      RegExp(r'[A-Z]').hasMatch(_password.text);

  bool get _tieneNumero =>
      RegExp(r'[0-9]').hasMatch(_password.text);

  bool get _passwordValida =>
      _tieneLongitud && _tieneMayuscula && _tieneNumero;

  Widget _requisitosPassword() {
    if (_password.text.isEmpty) return const SizedBox();
    if (_passwordValida) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _itemRegla("Entre 8 y 72 caracteres", _tieneLongitud),
        _itemRegla("Al menos una mayúscula", _tieneMayuscula),
        _itemRegla("Al menos un número", _tieneNumero),
        const SizedBox(height: 12),
      ],
    );
  }








  // 🔥 VALIDACIÓN DINÁMICA CORREO
  bool get _correoNoVacio => _correo.text.trim().isNotEmpty;

  bool get _correoFormatoValido {
    final email = _correo.text.trim();
    final regex = RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[a-zA-Z]{2,7}$');
    return regex.hasMatch(email);
  }

  bool get _correoValido => _correoNoVacio && _correoFormatoValido;

  Widget _requisitosCorreo() {
    if (_correo.text.isEmpty) return const SizedBox();
    if (_correoValido) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _itemRegla("El correo no puede estar vacío", _correoNoVacio),
        _itemRegla("Formato válido (ej: usuario@dominio.com)", _correoFormatoValido),
        const SizedBox(height: 12),
      ],
    );
  }

  // 🔥 Widget reutilizable
  Widget _itemRegla(String texto, bool ok) {
    return Row(
      children: [
        Icon(
          ok ? Icons.check_circle : Icons.radio_button_unchecked,
          color: ok ? Colors.green : Colors.grey,
          size: 18,
        ),
        const SizedBox(width: 6),
        Text(
          texto,
          style: TextStyle(
            fontSize: 13,
            color: ok ? Colors.green : Colors.grey,
          ),
        ),
      ],
    );
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
      _fotoUrlActual = emp.fotoUrl;
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
    // Usa el helper compartido: bottom sheet (galería/cámara) + recorte CIRCULAR
    // obligatorio (avatar). Devuelve null si el usuario cancela.
    final foto = await SelectorImagen.elegirYRecortar(
      context: context,
      formaCircular: true,
    );
    if (foto != null) setState(() => _foto = foto);
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
      // Invalida el listado global de empleados para que CUALQUIER pantalla
      // que lo esté observando (lista, agenda, walk-in…) se actualice con
      // la nueva foto/nombre sin necesidad de pull-to-refresh manual.
      ref.invalidate(empleadosAdminNotifierProvider);
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
                    child: SizedBox(
                      width: 120,   // 👈 tamaño del avatar
                      height: 120,  // 👈 cuadrado = círculo perfecto
                      child: Stack(
                        alignment: Alignment.center,   // 👈 centra todoO
                        children: [
                          ClipOval(
                            // Prioridad de qué se muestra:
                            // 1) foto local recién recortada → Image.file
                            // 2) foto que ya tiene el empleado en el backend (modo editar) → Image.network
                            // 3) sin foto → icono cámara como placeholder
                            child: _foto != null
                                ? Image.file(
                                    _foto!,
                                    width: 120,
                                    height: 120,
                                    fit: BoxFit.cover,
                                  )
                                : (_fotoUrlActual.isNotEmpty
                                    ? Image.network(
                                        ApiEndpoints.urlImagen(_fotoUrlActual),
                                        width: 120,
                                        height: 120,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, _, _) => Container(
                                          width: 120,
                                          height: 120,
                                          color: AppColors.accentGlow,
                                          child: const Icon(
                                            Icons.camera_alt,
                                            color: AppColors.primary,
                                            size: 50,
                                          ),
                                        ),
                                      )
                                    : Container(
                                        width: 120, // 👈 tamaño fijo
                                        height: 120, // 👈 tamaño fijo
                                        color: AppColors.accentGlow,
                                        child: const Icon(
                                          Icons.camera_alt,
                                          color: AppColors.primary,
                                          size: 50,
                                        ),
                                      )),
                          ),

                          // Borde elegante (opcional)
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 3,
                                ),
                                /*
                                Para cambiar el borde la imagen. OPCIÓN 1

                                border: Border.all(
                                  color: Color(0xFFA98CFF), // tu púrpura pastel
                                  width: 3,
                                ),

                                      Para cambiar el borde la imagen. OPCIÓN 2
                                    border: Border.all(color: Colors.white, width: 3),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black26,
                                        blurRadius: 6,
                                        spreadRadius: 1,
                                      ),
                                    ],



                                 */
                              ),
                            ),
                          ),
                        ],
                      ),
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
                  _requisitosCorreo(),

                  // 🔥 Campo contraseña + validación dinámica
                  _campo(
                    widget.esEdicion ? 'Nueva contraseña (opcional)' : 'Contraseña provisional',
                    _password,
                    requerido: !widget.esEdicion,
                    obscure: true,
              esPassword: true,
            ),
            _requisitosPassword(),

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

  Widget _campo(
      String label,
      TextEditingController c, {
        bool requerido = false,
        bool obscure = false,
        bool esPassword = false,
        TextInputType? teclado,
      }) {
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
          if (!requerido && (v == null || v.isEmpty)) return null;

          if (v == null || v.trim().isEmpty) return 'Campo obligatorio';

          if (label == 'Correo') {
            final email = v.trim();
            final regex = RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[a-zA-Z]{2,7}$');
            if (!regex.hasMatch(email)) return 'Correo inválido';
          }

          if (esPassword) {
            if (v.length < 8 || v.length > 72) {
              return 'Debe tener entre 8 y 72 caracteres';
            }
            if (!RegExp(r'[A-Z]').hasMatch(v)) {
              return 'Debe incluir al menos una mayúscula';
            }
            if (!RegExp(r'[0-9]').hasMatch(v)) {
              return 'Debe incluir al menos un número';
            }
          }

          return null;
        },
      ),
    );
  }
}
