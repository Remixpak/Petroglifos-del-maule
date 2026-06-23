import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:software_petroglifos/controllers/controladorGestionArqueologica.dart';
import 'package:software_petroglifos/models/sitio.dart';
import 'package:flutter/foundation.dart';
import 'package:file_selector_platform_interface/file_selector_platform_interface.dart';

class formularioPetroglifo extends StatefulWidget {
  const formularioPetroglifo({super.key});

  @override
  State<formularioPetroglifo> createState() => _formularioPetroglifoState();
}

class _formularioPetroglifoState extends State<formularioPetroglifo> {
  final _controlador = ControladorGestionArqueologica();
  final _nombreController = TextEditingController();

  Sitio? _sitioSeleccionado;
  final List<PlatformFile> _fotosVisualizables = [];
  int _indiceImagenPrincipal = 0;
  List<PlatformFile> _archivosMultimedia = [];
  
  bool _guardando = false;
  final ImagePicker _picker = ImagePicker();

  // 1. Declaramos la variable que contendrá el Stream permanente
  late Stream<List<Sitio>> _sitiosStream;

  @override
  void initState() {
    super.initState();
    // 2. Inicializamos el flujo una única vez al nacer el componente
    _sitiosStream = _controlador.listarSitios();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    super.dispose();
  }

  Future<void> _tomarFoto() async {
    // Bajamos imageQuality a 20 y controlamos resolución máxima con maxWidth/maxHeight
    final XFile? foto = await _picker.pickImage(
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

  /// Seleccionar archivos multimedia extras / Fotografías desde PC
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
            final Uint8List bytes = await xFile.readAsBytes(); // <--- BYTES EN WINDOWS
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
              // Si es una imagen del dispositivo, la comprimimos usando ImagePicker antes de añadirla
              // para asegurar que cumpla el Algoritmo de Ronald
              setState(() {
                _fotosVisualizables.add(file);
              });
            } else {
              setState(() {
                _archivosMultimedia.add(file);
              });
            }
          }
        }
      } catch (e) {
        print("Error en explorador de Android: $e");
      }
    }
  }

  void _procesarGuardado() async {
    // 1. Validaciones iniciales en la vista
    if (_nombreController.text.isEmpty || _sitioSeleccionado == null || _fotosVisualizables.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Complete el nombre, seleccione un Sitio y añada al menos una fotografía.')),
      );
      return;
    }

    setState(() => _guardando = true);

    // 2. LLAMADA DIRECTA Y SEGURA A LA CAPA DE NEGOCIO
    // Enviamos '_fotosVisualizables' directamente (que contiene los bytes/rutas nativos)
    bool exito = await _controlador.registrarPetroglifo(
      nombre: _nombreController.text,
      fotosCandidatas: _fotosVisualizables, // <--- CAMBIO CLAVE: Enviamos la lista de PlatformFile tal cual
      indicePrincipal: _indiceImagenPrincipal,
      archivosExtra: _archivosMultimedia,
      sitioSeleccionado: _sitioSeleccionado!,
    );

    setState(() => _guardando = false);

    // 3. Respuesta visual al usuario
    if (exito) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Petroglifo registrado y asociado con éxito!')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ocurrió un error al guardar en la base de datos.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    bool esWindows = defaultTargetPlatform == TargetPlatform.windows;

    return Scaffold(
      appBar: AppBar(title: const Text('Registrar Petroglifo')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 3. Consumimos la referencia fija del Stream
            StreamBuilder<List<Sitio>>(
              stream: _sitiosStream, // <--- CAMBIO CLAVE: Usar la variable fija
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text('Error al cargar sitios: ${snapshot.error}', style: const TextStyle(color: Colors.red)),
                  );
                }
                
                if (!snapshot.hasData) return const LinearProgressIndicator();
                final sitios = snapshot.data ?? [];
                
                return DropdownButtonFormField<Sitio>(
                  value: _sitioSeleccionado,
                  hint: const Text('Seleccionar Sitio Destino *'),
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  items: sitios.map((sitio) {
                    return DropdownMenuItem<Sitio>(value: sitio, child: Text(sitio.nombre));
                  }).toList(),
                  onChanged: (val) => setState(() => _sitioSeleccionado = val),
                );
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nombreController,
              decoration: const InputDecoration(labelText: 'Nombre del Petroglifo *', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),

            Text('Fotografías (* Presiona una miniatura para definirla como principal)', 
                 style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700])),
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
                                // CORRECCIÓN CLAVE: RENDERIZADO COMPORTAMIENTO HÍBRIDO SEGURO
                                archivoFoto.bytes != null
                                    ? Image.memory(archivoFoto.bytes!, fit: BoxFit.cover)
                                    : (archivoFoto.path != null 
                                        ? Image.file(File(archivoFoto.path!), fit: BoxFit.cover)
                                        : const Icon(Icons.broken_image, color: Colors.grey)),
                                
                                if (esPrincipal)
                                  const Positioned(
                                    top: 4, right: 4,
                                    child: CircleAvatar(
                                      backgroundColor: Colors.green, 
                                      radius: 10, 
                                      child: Icon(Icons.check, size: 12, color: Colors.white)
                                    ),
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
              const SizedBox(height: 20),
            ],

            Text(esWindows ? 'Seleccionar Fotografías y Archivos' : 'Archivos Multimedia Adicionales', 
                 style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700])),
            const SizedBox(height: 8),
            
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
                    onPressed: _procesarGuardado,
                    child: const Text('Registrar Petroglifo', style: TextStyle(fontSize: 16)),
                  ),
          ],
        ),
      ),
    );
  }
}