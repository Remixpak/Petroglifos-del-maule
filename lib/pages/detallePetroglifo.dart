import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:software_petroglifos/controllers/controladorGestionArqueologica.dart';
import 'package:software_petroglifos/controllers/controladorGeneracionPDF.dart'; 
import 'package:software_petroglifos/models/petroglifo.dart';
import 'package:software_petroglifos/models/fichaTecnica.dart';

/*
  Esta clase es la pantalla que se encarga de renderizar la vista detallada de un petroglifo 
  específico.
*/

class DetallePetroglifo extends StatefulWidget {
  final Petroglifo petroglifo;

  const DetallePetroglifo({super.key, required this.petroglifo});

  @override
  State<DetallePetroglifo> createState() => _DetallePetroglifoState();
}

class _DetallePetroglifoState extends State<DetallePetroglifo> {
  final _controladorNegocio = ControladorGestionArqueologica();
  final _controladorPDF = ControladorGeneracionPDF(); 
  
  FichaTecnica? _fichaTecnica;
  bool _cargandoFicha = true;
  bool _exportandoPDF = false; 

  
  @override
  void initState() {
    super.initState();
    _cargarFichaAsociada();
  }

  /*
    este metodo realiza una consulta a traves del controlador arqueologico para
    recuperar el documento de la ficha tecnica vinculada al identificador del petroglifo actual
  */
  Future<void> _cargarFichaAsociada() async {
    try {
      final ficha = await _controladorNegocio.buscarFicha(widget.petroglifo.id);
      if (mounted) {
        setState(() {
          _fichaTecnica = ficha;
          _cargandoFicha = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _cargandoFicha = false;
        });
      }
    }
  }

  /*
    este metodo coordina el proceso de compilacion y descarga de la ficha
    Modifica el estado local para activar un indicador visual de progreso, llama a las funciones
    del controlador de PDF pasando el ID de la ficha tecnica correspondiente
  */
  Future<void> _procesarExportacionPDF() async {
    if (_fichaTecnica == null) return;

    setState(() {
      _exportandoPDF = true;
    });

    try {
      final futureData = _controladorPDF.generarFichaTecnica(_fichaTecnica!.id);
      await _controladorPDF.descargarPDF(futureData, 'Ficha_Tecnica_${widget.petroglifo.id}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Documento PDF generado y compartido con éxito')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al procesar la exportación del PDF: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _exportandoPDF = false;
        });
      }
    }
  }

  /*
    construlle la pantalla
  */
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.petroglifo.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal.shade700,
        foregroundColor: Colors.white,
        actions: [
          if (!_cargandoFicha && _fichaTecnica != null)
            _exportandoPDF
                ? const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.picture_as_pdf_rounded),
                    tooltip: 'Exportar Ficha a PDF',
                    onPressed: _procesarExportacionPDF,
                  ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Registro Visual (Transformación de Ronald)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal),
            ),
            const SizedBox(height: 10),
            widget.petroglifo.imagenes.isEmpty
                ? Container(
                    height: 180,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text('Sin imágenes registradas', style: TextStyle(color: Colors.grey)),
                    ),
                  )
                : SizedBox(
                    height: 200,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: widget.petroglifo.imagenes.length,
                      itemBuilder: (context, index) {
                        final img = widget.petroglifo.imagenes[index];
                        return Container(
                          margin: const EdgeInsets.only(right: 12),
                          width: 260,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: img.isPrincipal ? Colors.teal.shade400 : Colors.grey.shade300,
                              width: img.isPrincipal ? 2.5 : 1,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: img.url.startsWith('data:image') || !img.url.contains('http')
                                ? Image.memory(
                                    base64Decode(img.url.contains(',') ? img.url.split(',')[1] : img.url),
                                    fit: BoxFit.cover,
                                    errorBuilder: (c, e, s) => const Center(child: Icon(Icons.broken_image)),
                                  )
                                : Image.network(
                                    img.url,
                                    fit: BoxFit.cover,
                                    errorBuilder: (c, e, s) => const Center(child: Icon(Icons.broken_image)),
                                  ),
                          ),
                        );
                      },
                    ),
                  ),
            const SizedBox(height: 24),
            const Text(
              'Ficha Técnica Oficial',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal),
            ),
            const Divider(color: Colors.teal, thickness: 1),
            const SizedBox(height: 8),
            _cargandoFicha
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : _fichaTecnica == null
                    ? Card(
                        color: Colors.amber.shade50,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          side: BorderSide(color: Colors.amber.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 28),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Este petroglifo no cuenta con una Ficha Técnica estructurada asociada.',
                                  style: TextStyle(color: Colors.black87),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _construirItemFicha('ID Documento:', _fichaTecnica!.id),
                              const Divider(),
                              _construirItemFicha('Código de Relación Arqueológica:', _fichaTecnica!.codigoPetroglifo),
                              const Divider(),
                              _construirItemFicha('Motivo del Grabado:', _fichaTecnica!.motivo.name.toUpperCase()),
                              const Divider(),
                              _construirItemFicha('Técnica de Manufactura:', _fichaTecnica!.tecnicaGrabado.name.toUpperCase()),
                              const Divider(),
                              _construirItemFicha('Soporte Geológico (Tipo de Roca):', _fichaTecnica!.tpoRoca.name.toUpperCase()),
                              const Divider(),
                              _construirItemFicha('Descripción Ampliada y Contexto:', _fichaTecnica!.descripcion),
                            ],
                          ),
                        ),
                      ),
            const SizedBox(height: 24),
            const Text(
              'Archivos Multimedia Complementarios',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal),
            ),
            const Divider(color: Colors.teal, thickness: 1),
            widget.petroglifo.archivosMultimedia.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Text('No existen archivos de audio o modelados adicionales para este ítem.',
                        style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
                  )
                : Column(
                    children: widget.petroglifo.archivosMultimedia.map((archivo) {
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        elevation: 1,
                        child: ListTile(
                          leading: const Icon(Icons.audio_file_rounded, color: Colors.blueGrey),
                          title: Text(archivo.nombreArchivo, style: const TextStyle(fontSize: 14)),
                          subtitle: Text('Tipo: ${archivo.tipoArchivo}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.download_rounded),
                            onPressed: () {
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

  /*
    genera un subarbol de widgets optimizado para visualizar de forma
    mas ordenada pares clave-valor correspondientes a los campos de la ficha tecnica.
  */
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