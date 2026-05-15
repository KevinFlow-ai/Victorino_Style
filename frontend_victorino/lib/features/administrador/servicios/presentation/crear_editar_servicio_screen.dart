import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/api/api_endpoints.dart';
import '../../../../core/errors/api_exception.dart';
import '../../../../core/theme/app_colores.dart';
import '../../../../core/widgets_compartidos/selector_imagen.dart';
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
  double? _aspectRatio; // ⭐ relación de aspecto real del recorte local
  // URL relativa de la foto que ya tiene el servicio en el backend.
  // Si el admin elige una foto nueva (`_foto != null`), prevalece la nueva.
  String _fotoUrlActual = '';
  // Aspect ratio REAL de la imagen remota (la guardada en el servidor).
  // Se calcula al cargar `_fotoUrlActual`. Mientras es null, mostramos un
  // contenedor con relación cuadrada como fallback.
  double? _aspectRatioRemoto;

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
      _fotoUrlActual = s.fotoUrl;
      // Dispara el cálculo del aspect ratio real de la imagen remota.
      // No espera al resultado: en cuanto la imagen se descargue, hace setState
      // con el ratio y la UI vuelve a renderizar con el AR correcto.
      if (_fotoUrlActual.isNotEmpty) {
        _calcularAspectRatioRemoto(ApiEndpoints.urlImagen(_fotoUrlActual));
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _elegirFoto() async {
    final foto = await SelectorImagen.elegirYRecortar(
      context: context,
      formaCircular: false, // ⭐ rectangular
    );

    if (foto != null) {
      final ratio = await _obtenerAspectRatio(foto);

      setState(() {
        _foto = foto;
        _aspectRatio = ratio;
      });
    }
  }

  // ⭐ Obtiene la relación de aspecto REAL del recorte
  Future<double> _obtenerAspectRatio(File file) async {
    final bytes = await file.readAsBytes();

    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;

    return image.width / image.height;
  }

  // Descarga la imagen remota con NetworkImage y, en cuanto Flutter conoce
  // sus dimensiones, calcula el aspect ratio y refresca la UI. Así, al editar,
  // la foto guardada se muestra respetando el ratio con el que fue recortada
  // (1:1, 16:9, 4:3, etc.).
  void _calcularAspectRatioRemoto(String url) {
    final imageProvider = NetworkImage(url);
    final stream = imageProvider.resolve(ImageConfiguration.empty);
    late ImageStreamListener listener;
    listener = ImageStreamListener(
      (info, _) {
        if (mounted) {
          setState(() {
            _aspectRatioRemoto = info.image.width / info.image.height;
          });
        }
        stream.removeListener(listener);
      },
      onError: (_, _) => stream.removeListener(listener),
    );
    stream.addListener(listener);
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
            // ⭐ FOTO DEL SERVICIO
            // Prioridad de qué se muestra:
            // 1) foto local recién recortada → Image.file con AspectRatio del recorte
            // 2) foto que ya tiene el servicio en el backend (modo editar) → Image.network
            // 3) sin foto → placeholder con icono add_a_photo
            GestureDetector(
              onTap: _enviando ? null : _elegirFoto,
              child: _foto != null
                  ? AspectRatio(
                      aspectRatio: _aspectRatio ?? 1,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(_foto!, fit: BoxFit.cover),
                      ),
                    )
                  : (_fotoUrlActual.isNotEmpty
                      // Cuando ya conocemos el aspect ratio real (lo calcula
                      // _calcularAspectRatioRemoto al cargar la imagen), envolvemos
                      // la imagen en AspectRatio para que se muestre con el ratio
                      // exacto con el que se recortó (1:1, 16:9, 4:3, etc.).
                      // Si todavía está cargando, dejamos un placeholder cuadrado
                      // (1:1) para evitar saltos visuales.
                      ? AspectRatio(
                          aspectRatio: _aspectRatioRemoto ?? 1,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              ApiEndpoints.urlImagen(_fotoUrlActual),
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Container(
                                decoration: BoxDecoration(
                                  color: AppColors.accentGlow,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Center(
                                  child: Icon(Icons.broken_image,
                                      color: AppColors.primary, size: 40),
                                ),
                              ),
                            ),
                          ),
                        )
                      : Container(
                          height: 180,
                          decoration: BoxDecoration(
                            color: AppColors.accentGlow,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Icon(Icons.add_a_photo,
                                color: AppColors.primary, size: 40),
                          ),
                        )),
            ),

            const SizedBox(height: 22),

            _campo('Nombre del servicio', _nombre, requerido: true),
            _campo('Descripción (opcional)', _descripcion, maxLines: 7),

            Row(
              children: [
                Expanded(
                  child: _campo('Duración (min)', _duracion,
                      requerido: true,
                      teclado: TextInputType.number),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _campo('Precio (€)', _precio,
                      requerido: true,
                      teclado: TextInputType.number),
                ),
              ],
            ),

            const SizedBox(height: 16),

            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding:
                const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _enviando ? null : _guardar,
              child: _enviando
                  ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
                  : Text(widget.esEdicion
                  ? 'Guardar cambios'
                  : 'Crear servicio'),
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
          // labelStyle: const TextStyle(fontSize: 15), // Tamaño del label
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
