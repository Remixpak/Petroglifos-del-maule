import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

// Importaciones de tus modelos y controladores
import 'package:software_petroglifos/controllers/controladorGestionArqueologica.dart';
import 'package:software_petroglifos/models/petroglifo.dart';
import 'package:software_petroglifos/models/fichaTecnica.dart';

class DetallePetroglifo extends StatefulWidget {
  final Petroglifo petroglifo;

  const DetallePetroglifo({super.key, required this.petroglifo});

  @override
  State<DetallePetroglifo> createState() => _DetallePetroglifoState();
}

class _DetallePetroglifoState extends State<DetallePetroglifo> {
  final _controladorNegocio = ControladorGestionArqueologica();
  
  FichaTecnica? _fichaTecnica;
  bool _cargandoFicha = true;

  @override
  void initState() {
    super.initState();
    _cargarFichaAsociada();
  }

  Future<void> _cargarFichaAsociada() async {
    try {
      final ficha = await _controladorNegocio.buscarFicha(widget.petroglifo.id);
      setState(() {
        _fichaTecnica = ficha;
        _cargandoFicha = false;
      });
    } catch (e) {
      setState(() => _cargandoFicha = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detalle: ${widget.petroglifo.id}'),
        backgroundColor: Colors.brown.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ==========================================
            // SECCIÓN 1: IDENTIFICACIÓN GENERAL
            // ==========================================
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.petroglifo.nombre,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.brown),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Código de Registro: ${widget.petroglifo.id}',
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ==========================================
            // SECCIÓN 2: GALERÍA DE FOTOS (BASE64 / LOCAL)
            // ==========================================
            const Text(
              'Registro Fotográfico de Campo',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: widget.petroglifo.imagenes.isEmpty
                  ? const Center(child: Text('Este petroglifo no registra fotografías.'))
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: widget.petroglifo.imagenes.length,
                      itemBuilder: (context, index) {
                        final img = widget.petroglifo.imagenes[index];
                        
                        // Determinamos si es la imagen principal para destacarla visualmente
                        bool esPrincipal = img.isPrincipal;

                        return Container(
                          margin: const EdgeInsets.all(8.0),
                          width: 160,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: esPrincipal ? Colors.green : Colors.grey.shade300, 
                              width: esPrincipal ? 3 : 1
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                // Decodificación del Algoritmo de Ronald (Base64) o lectura de URL
                                img.url.isNotEmpty
                                    ? Image.memory(base64Decode(img.url), fit: BoxFit.cover)
                                    : const Icon(Icons.broken_image, size: 40),
                                
                                if (esPrincipal)
                                  Positioned(
                                    bottom: 4,
                                    left: 4,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      color: Colors.green,
                                      child: const Text(
                                        'PRINCIPAL',
                                        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 20),

            // ==========================================
            // SECCIÓN 3: FICHA TÉCNICA ASOCIADA (ASÍNCRONA)
            // ==========================================
            const Row(
              children: [
                Icon(Icons.assignment_rounded, color: Colors.brown),
                SizedBox(width: 8),
                Text('Ficha Técnica Vinculada', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.brown)),
              ],
            ),
            const Divider(color: Colors.brown),
            
            _cargandoFicha
                ? const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator()))
                : _fichaTecnica == null
                    ? const Card(
                        color: Colors.amberAccent,
                        child: Padding(
                          padding: EdgeInsets.all(12.0),
                          child: Text('Advertencia: No se encontró una ficha técnica registrada para este código.'),
                        ),
                      )
                    : Card(
                        elevation: 1,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _construirItemFicha('Descripción Arqueológica:', _fichaTecnica!.descripcion),
                              const Divider(),
                              _construirItemFicha('Motivo del Grabado:', _fichaTecnica!.motivo.name.toUpperCase()),
                              const Divider(),
                              _construirItemFicha('Técnica de Manufactura:', _fichaTecnica!.tecnicaGrabado.name.toUpperCase()),
                              const Divider(),
                              _construirItemFicha('Soporte Lítico (Roca):', _fichaTecnica!.tpoRoca.name.toUpperCase()),
                            ],
                          ),
                        ),
                      ),
            const SizedBox(height: 20),

            // ==========================================
            // SECCIÓN 4: ARCHIVOS MULTIMEDIA ADICIONALES
            // ==========================================
            const Text(
              'Documentos y Archivos de Audio Adjuntos',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            widget.petroglifo.archivosMultimedia.isEmpty
                ? Text('No hay archivos multimedia adicionales.', style: TextStyle(color: Colors.grey.shade600, fontSize: 13))
                : Column(
                    children: widget.petroglifo.archivosMultimedia.map((archivo) {
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          leading: const Icon(Icons.audio_file_rounded, color: Colors.blueGrey),
                          title: Text(archivo.nombreArchivo, style: const TextStyle(fontSize: 14)),
                          subtitle: Text('Tipo: ${archivo.tipoArchivo}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.download_rounded),
                            onPressed: () {
                              // Aquí puedes implementar la apertura o descarga del archivo físico en caché
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Ruta de archivo: ${archivo.rutaArchivo}')),
                              );
                            },
                          ),
                        ),
                      );
                    }).toList(),
                  ),
          ],
        ),
      ),
    );
  }

  // Widget auxiliar para mantener limpio el diseño de la Ficha Técnica
  Widget _construirItemFicha(String titulo, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            valor.isEmpty ? 'No especificado' : valor,
            style: TextStyle(color: Colors.grey.shade800, fontSize: 15),
          ),
        ],
      ),
    );
  }
}