import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:file_selector_platform_interface/file_selector_platform_interface.dart';

// Importaciones de tus modelos y controladores del proyecto
import 'package:software_petroglifos/controllers/controladorGestionArqueologica.dart';
import 'package:software_petroglifos/models/sitio.dart';

// =========================================================================
// ENUM: TIPOS DE REGISTRO CENTRALIZADOS
// =========================================================================
enum TipoRegistro {
  petroglifo,
  sitio,
  usuario,
  // 📝 PASO 1 PARA EXTENDER (Ej: Bitácora): Añade el nuevo identificador aquí
  // bitacora,
}

class FormularioRegistro extends StatefulWidget {
  final TipoRegistro tipo;

  const FormularioRegistro(String s, {super.key, required this.tipo});

  @override
  State<FormularioRegistro> createState() => _FormularioRegistroState();
}

class _FormularioRegistroState extends State<FormularioRegistro> {
  // =========================================================================
  // PROPIEDADES GLOBALES Y CONTROLADORES GENERALES
  // =========================================================================
  final _controladorNegocio = ControladorGestionArqueologica();
  bool _guardando = false;

  // =========================================================================
  // ESTADO ESPECÍFICO: SECCIÓN PETROGLIFOS
  // =========================================================================
  final _nombrePetroglifoController = TextEditingController();
  Sitio? _sitioSeleccionado;
  final List<PlatformFile> _fotosVisualizables = [];
  int _indiceImagenPrincipal = 0;
  List<PlatformFile> _archivosMultimedia = [];
  final ImagePicker _imagePicker = ImagePicker();
  late Stream<List<Sitio>> _sitiosStream;

  // =========================================================================
  // ESTADO ESPECÍFICO: SECCIÓN SITIOS ARQUEOLÓGICOS
  // =========================================================================
  final _nombreSitioController = TextEditingController();
  final _codigoSitioController = TextEditingController();
  final _comunaSitioController = TextEditingController();
  final _descripcionSitioController = TextEditingController();
  EstadoAcceso _accesoSeleccionado = EstadoAcceso.publico;
  double? _latitud;
  double? _longitud;
  bool _obteniendoGps = false;

  // =========================================================================
  // ESTADO ESPECÍFICO: SECCIÓN USUARIOS
  // =========================================================================
  final _nombreUserController = TextEditingController();
  final _emailUserController = TextEditingController();

  // =========================================================================
  // 📝 PASO 2 PARA EXTENDER (Ej: Bitácora): Agrega aquí tus controladores de texto o variables de estado futuros
  // final _detalleBitacoraController = TextEditingController();
  // =========================================================================

  @override
  void initState() {
    super.initState();
    // Inicializamos el stream de sitios únicamente si vamos a registrar un petroglifo
    if (widget.tipo == TipoRegistro.petroglifo) {
      _sitiosStream = _controladorNegocio.listarSitios();
    }
  }

  @override
  void dispose() {
    // Limpieza absoluta de todos los controladores de texto del sistema
    _nombrePetroglifoController.dispose();
    _nombreSitioController.dispose();
    _codigoSitioController.dispose();
    _comunaSitioController.dispose();
    _descripcionSitioController.dispose();
    _nombreUserController.dispose();
    _emailUserController.dispose();
    super.dispose();
  }

  // =========================================================================
  // LÓGICA DE NEGOCIO Y FUNCIONES: SECCIÓN PETROGLIFOS
  // =========================================================================
  Future<void> _tomarFoto() async {
    final XFile? foto = await _imagePicker.pickImage(
      source: ImageSource.camera, 
      imageQuality: 20, 
      maxWidth: 800,   
      maxHeight: 800,  
    );
    if (foto != null) {
      final int size = await foto.length();
      final Uint8List bytes = await foto.readAsBytes(); 
      setState(() {
        _fotosVisualizables.add(PlatformFile(
          name: foto.name,
          path: foto.path,
          size: size,
          bytes: bytes, 
        ));
      });
    }
  }

  Future<void> _seleccionarArchivosExtra() async {
    if (defaultTargetPlatform == TargetPlatform.windows) {
      try {
        final XTypeGroup typeGroup = XTypeGroup(
          label: 'Imágenes',
          extensions: <String>['jpg', 'jpeg', 'png'], 
        );
        final List<XFile> archivosSeleccionados = await FileSelectorPlatform.instance.openFiles(
          acceptedTypeGroups: <XTypeGroup>[typeGroup], 
        );
        if (archivosSeleccionados.isNotEmpty) {
          for (var xFile in archivosSeleccionados) {
            final Uint8List bytes = await xFile.readAsBytes();
            setState(() {
              _fotosVisualizables.add(PlatformFile(
                name: xFile.name,
                path: xFile.path,
                size: 0, 
                bytes: bytes,
              ));
            });
          }
        }
      } catch (e) {
        print("Error en explorador de Windows: $e");
      }
    } else {
      try {
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          allowMultiple: true,
          type: FileType.any,
          withData: true, 
        );
        if (result != null) {
          for (var file in result.files) {
            if (file.extension == 'jpg' || file.extension == 'jpeg' || file.extension == 'png') {
              setState(() => _fotosVisualizables.add(file));
            } else {
              setState(() => _archivosMultimedia.add(file));
            }
          }
        }
      } catch (e) {
        print("Error en explorador de Android: $e");
      }
    }
  }

  void _procesarGuardadoPetroglifo() async {
    if (_nombrePetroglifoController.text.isEmpty || _sitioSeleccionado == null || _fotosVisualizables.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Complete los campos obligatorios (*).')),
      );
      return;
    }
    setState(() => _guardando = true);
    bool exito = await _controladorNegocio.registrarPetroglifo(
      nombre: _nombrePetroglifoController.text,
      fotosCandidatas: _fotosVisualizables,
      indicePrincipal: _indiceImagenPrincipal,
      archivosExtra: _archivosMultimedia,
      sitioSeleccionado: _sitioSeleccionado!,
    );
    setState(() => _guardando = false);
    if (exito) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('¡Petroglifo registrado con éxito!')));
      Navigator.pop(context);
    }
  }

  // =========================================================================
  // LÓGICA DE NEGOCIO Y FUNCIONES: SECCIÓN SITIOS ARQUEOLÓGICOS
  // =========================================================================
  Future<void> _obtenerCoordenadasGps() async {
    setState(() => _obteniendoGps = true);
    try {
      bool servicioHabilitado = await Geolocator.isLocationServiceEnabled();
      if (!servicioHabilitado) throw 'El GPS del dispositivo está desactivado.';

      LocationPermission permiso = await Geolocator.checkPermission();
      if (permiso == LocationPermission.denied) {
        permiso = await Geolocator.requestPermission();
        if (permiso == LocationPermission.denied) throw 'Permisos denegados.';
      }
      if (permiso == LocationPermission.deniedForever) throw 'Permisos denegados permanentemente.';

      Position posicion = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      setState(() {
        _latitud = posicion.latitude;
        _longitud = posicion.longitude;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error GPS: $e')));
    } finally {
      setState(() => _obteniendoGps = false);
    }
  }

  void _procesarGuardadoSitio() async {
    if (_nombreSitioController.text.isEmpty || _codigoSitioController.text.isEmpty || _latitud == null || _longitud == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Complete los datos obligatorios y capture el GPS.')),
      );
      return;
    }
    setState(() => _guardando = true);
    bool exito = await _controladorNegocio.registrarSitio(
      nombre: _nombreSitioController.text,
      codigoInterno: _codigoSitioController.text,
      comuna: _comunaSitioController.text,
      descripcion: _descripcionSitioController.text,
      estadoAcceso: _accesoSeleccionado,
      latitud: _latitud!,
      longitud: _longitud!,
    );
    setState(() => _guardando = false);
    if (exito) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('¡Sitio registrado con éxito!')));
      Navigator.pop(context);
    }
  }

  // =========================================================================
  // LÓGICA DE NEGOCIO Y FUNCIONES: SECCIÓN USUARIOS
  // =========================================================================
  void _procesarGuardadoUsuario() {
    if (_nombreUserController.text.isEmpty || _emailUserController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Complete los campos obligatorios.')));
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Funcionalidad de usuario lista en backend.')));
    Navigator.pop(context);
  }

  // =========================================================================
  // PANTALLAS DE DISEÑO INDEPENDIENTES (CONSTRUIDAS POR MÉTODO)
  // =========================================================================

  // -------------------------------------------------------------------------
  // DISEÑO: VISTA FORMULARIO PETROGLIFO
  // -------------------------------------------------------------------------
  Widget _construirFormularioPetroglifo() {
    bool esWindows = defaultTargetPlatform == TargetPlatform.windows;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StreamBuilder<List<Sitio>>(
          stream: _sitiosStream,
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const LinearProgressIndicator();
            return DropdownButtonFormField<Sitio>(
              value: _sitioSeleccionado,
              hint: const Text('Seleccionar Sitio Destino *'),
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: (snapshot.data ?? []).map((sitio) {
                return DropdownMenuItem<Sitio>(value: sitio, child: Text(sitio.nombre));
              }).toList(),
              onChanged: (val) => setState(() => _sitioSeleccionado = val),
            );
          },
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _nombrePetroglifoController,
          decoration: const InputDecoration(labelText: 'Nombre del Petroglifo *', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 20),
        Text('Fotografías (* Presione miniatura para definir principal)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700])),
        const SizedBox(height: 8),
        Container(
          height: 120,
          decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
          child: _fotosVisualizables.isEmpty
              ? const Center(child: Text('Sin fotos capturadas o importadas.'))
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _fotosVisualizables.length,
                  itemBuilder: (context, idx) {
                    bool esPrincipal = idx == _indiceImagenPrincipal;
                    final archivoFoto = _fotosVisualizables[idx];
                    return GestureDetector(
                      onTap: () => setState(() => _indiceImagenPrincipal = idx),
                      child: Container(
                        margin: const EdgeInsets.all(8.0),
                        width: 100,
                        decoration: BoxDecoration(
                          border: Border.all(color: esPrincipal ? Colors.green : Colors.transparent, width: 3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            archivoFoto.bytes != null
                                ? Image.memory(archivoFoto.bytes!, fit: BoxFit.cover)
                                : (archivoFoto.path != null 
                                    ? Image.file(File(archivoFoto.path!), fit: BoxFit.cover)
                                    : const Icon(Icons.broken_image)),
                            if (esPrincipal)
                              const Positioned(
                                top: 4, right: 4,
                                child: CircleAvatar(backgroundColor: Colors.green, radius: 10, child: Icon(Icons.check, size: 12, color: Colors.white)),
                              )
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        const SizedBox(height: 8),
        if (!esWindows) ...[
          ElevatedButton.icon(
            onPressed: _tomarFoto,
            icon: const Icon(Icons.camera_alt_rounded),
            label: const Text('Tomar Fotografía de Campo'),
          ),
          const SizedBox(height: 12),
        ],
        ..._archivosMultimedia.map((file) => Card(
              child: ListTile(
                leading: const Icon(Icons.insert_drive_file_rounded),
                title: Text(file.name),
                subtitle: Text('${(file.size / 1024).toStringAsFixed(2)} KB'),
              ),
            )),
        ElevatedButton.icon(
          onPressed: _seleccionarArchivosExtra,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade200, foregroundColor: Colors.black87),
          icon: Icon(esWindows ? Icons.add_photo_alternate_rounded : Icons.attach_file_rounded),
          label: Text(esWindows ? 'Buscar Fotos en el Equipo' : 'Adjuntar Documentos/Audios'),
        ),
        const SizedBox(height: 40),
        _guardando
            ? const Center(child: CircularProgressIndicator())
            : ElevatedButton(
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16), backgroundColor: Colors.brown, foregroundColor: Colors.white),
                onPressed: _procesarGuardadoPetroglifo,
                child: const Text('Registrar Petroglifo', style: TextStyle(fontSize: 16)),
              ),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // DISEÑO: VISTA FORMULARIO SITIO ARQUEOLÓGICO
  // -------------------------------------------------------------------------
  Widget _construirFormularioSitio() {
    final double width = MediaQuery.of(context).size.width;
    final double paddingHorizontal = width > 600 ? width * 0.15 : 0.0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: paddingHorizontal),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _nombreSitioController,
            decoration: const InputDecoration(labelText: 'Nombre del Sitio *', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _codigoSitioController,
            decoration: const InputDecoration(labelText: 'Código Interno (Ej: ST-01) *', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _comunaSitioController,
            decoration: const InputDecoration(labelText: 'Comuna', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descripcionSitioController,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Descripción del Entorno', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<EstadoAcceso>(
            value: _accesoSeleccionado,
            decoration: const InputDecoration(labelText: 'Estado de Acceso', border: OutlineInputBorder()),
            items: EstadoAcceso.values.map((estado) => DropdownMenuItem(value: estado, child: Text(estado.name))).toList(),
            onChanged: (val) => setState(() => _accesoSeleccionado = val!),
          ),
          const SizedBox(height: 20),
          Card(
            color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.4),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    _latitud != null && _longitud != null ? 'Coordenadas: ($_latitud, $_longitud)' : 'Ubicación Satelital no capturada *',
                    style: TextStyle(fontWeight: FontWeight.bold, color: _latitud != null ? Colors.green : Colors.red),
                  ),
                  const SizedBox(height: 12),
                  _obteniendoGps
                      ? const CircularProgressIndicator()
                      : ElevatedButton.icon(
                          icon: const Icon(Icons.location_searching_rounded),
                          label: const Text('Obtener Coordenadas GPS'),
                          onPressed: _obtenerCoordenadasGps,
                        ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),
          _guardando
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton(
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
                  onPressed: _procesarGuardadoSitio,
                  child: const Text('Guardar Sitio Arqueológico', style: TextStyle(fontSize: 16)),
                ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // DISEÑO: VISTA FORMULARIO USUARIO
  // -------------------------------------------------------------------------
  Widget _construirFormularioUsuario() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _nombreUserController,
          decoration: const InputDecoration(labelText: 'Nombre Completo *', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _emailUserController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'Correo Electrónico *', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 30),
        _guardando
            ? const Center(child: CircularProgressIndicator())
            : ElevatedButton(
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16), backgroundColor: Colors.blueGrey, foregroundColor: Colors.white),
                onPressed: _procesarGuardadoUsuario,
                child: const Text('Guardar Usuario', style: TextStyle(fontSize: 16)),
              ),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // 📝 PASO 4 PARA EXTENDER (Ej: Bitácora): Agrega aquí el diseño de la vista futura
  // -------------------------------------------------------------------------
  /*
  Widget _construirFormularioBitacora() {
    return Column(
      children: [
        TextField(controller: _detalleBitacoraController, decoration: InputDecoration(labelText: 'Nota de bitácora')),
        ElevatedButton(onPressed: () {}, child: Text('Guardar Bitácora'))
      ],
    );
  }
  */

  // =========================================================================
  // SELECTOR CENTRALIZADO DEL TÍTULO DE LA VISTA
  // =========================================================================
  String _obtenerTituloAppBar() {
    switch (widget.tipo) {
      case TipoRegistro.petroglifo: return 'Registrar Petroglifo';
      case TipoRegistro.sitio: return 'Registrar Sitio Arqueológico';
      case TipoRegistro.usuario: return 'Registrar Nuevo Usuario';
      // case TipoRegistro.bitacora: return 'Nueva Entrada de Bitácora';
    }
  }

  // =========================================================================
  // SELECTOR CENTRALIZADO DE LA INTERFAZ ACTIVA
  // =========================================================================
  Widget _seleccionarCuerpoFormulario() {
    switch (widget.tipo) {
      case TipoRegistro.petroglifo: return _construirFormularioPetroglifo();
      case TipoRegistro.sitio: return _construirFormularioSitio();
      case TipoRegistro.usuario: return _construirFormularioUsuario();
      // case TipoRegistro.bitacora: return _construirFormularioBitacora();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_obtenerTituloAppBar())),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: _seleccionarCuerpoFormulario(),
      ),
    );
  }
}

// =========================================================================
// 📝 GUÍA DE EXTENSIÓN GLOBAL (EJ: AGREGAR BITÁCORA)
// =========================================================================
/*
  Si necesitas agregar un formulario para una nueva entidad como una "Bitácora", realiza estos pasos:

  1. Ve al enum 'TipoRegistro' arriba y añade la opción: 'bitacora,'.
  2. En el estado de la clase ('_FormularioRegistroState'), declara los controladores específicos si se necesitan (ej: _detalleBitacoraController).
  3. Crea la función que procese los datos y llame al controlador (ej: _procesarGuardadoBitacora()).
  4. Crea la estructura visual abajo mediante una nueva función de tipo Widget (ej: _construirFormularioBitacora()).
  5. Vincula el caso en los métodos selectores '_obtenerTituloAppBar()' y '_seleccionarCuerpoFormulario()'.
*/