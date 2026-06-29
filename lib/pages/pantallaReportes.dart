import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; 
import 'package:software_petroglifos/controllers/controladorGestionArqueologica.dart';
import 'package:software_petroglifos/controllers/controladorUsuario.dart';
import 'package:software_petroglifos/controllers/controladorGeneracionPDF.dart'; // <-- NUEVO IMPORT
import 'package:software_petroglifos/models/reporteTecnico.dart';
import 'package:software_petroglifos/models/bitacora.dart'; 
import 'package:software_petroglifos/pages/formularioRegistro.dart';

class PantallaReporte extends StatefulWidget {
  const PantallaReporte({super.key});

  @override
  State<PantallaReporte> createState() => _PantallaReporteState();
}

class _PantallaReporteState extends State<PantallaReporte> {
  final _controlador = ControladorGestionArqueologica();
  final _controladorUsuario = ControladorUsuario();
  final _controladorPDF = ControladorGeneracionPDF();

  final Map<String, bool> _exportandoPDFs = {};

  void _irARegistroReporte() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const FormularioRegistro("Reporte Técnico", tipo: TipoRegistro.reporte),
      ),
    );
  }

  Future<void> _descargarReportePDF(ReporteTecnico reporte) async {
    setState(() => _exportandoPDFs[reporte.id] = true);

    try {
      
      await _controladorPDF.descargarPDF(
        _controladorPDF.generarReporteTecnico(reporte.id),
        "Reporte_Tecnico_${reporte.id}",
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reporte exportado a PDF de manera exitosa.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al procesar el reporte: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _exportandoPDFs[reporte.id] = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final double paddingHorizontal = width > 800 ? width * 0.15 : 12.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes Técnicos'),
      ),
      body: StreamBuilder<List<ReporteTecnico>>(
        stream: _controlador.listarReportes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error al cargar reportes: ${snapshot.error}'));
          }

          final reportes = snapshot.data ?? [];

          if (reportes.isEmpty) {
            return const Center(
              child: Text(
                'No hay reportes registrados',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: paddingHorizontal, vertical: 12.0),
            itemCount: reportes.length,
            itemBuilder: (context, index) {
              final reporte = reportes[index];
              
              final String fechaGenFormateada = DateFormat('dd/MM/yyyy HH:mm').format(reporte.fechaGeneracion);
              final String rangoFormateado = DateFormat('dd/MM/yyyy').format(reporte.rangoFecha);
              
              bool estaDescargando = _exportandoPDFs[reporte.id] ?? false;

              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 12.0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: ExpansionTile(
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.1),
                    leading: const Icon(Icons.assignment_rounded, color: Colors.blueGrey),
                    title: Text(
                      'Reporte Técnico - $fechaGenFormateada',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    subtitle: Text('Rango de cobertura: $rangoFormateado'),
                    
                    trailing: estaDescargando
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          )
                        : IconButton(
                            icon: const Icon(Icons.picture_as_pdf_rounded, color: Colors.brown),
                            tooltip: 'Descargar Documento PDF',
                            onPressed: () => _descargarReportePDF(reporte),
                          ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Divider(),
                            const SizedBox(height: 4),
                            Text('ID del Reporte: ${reporte.id}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                            const SizedBox(height: 12),
                            
                            Row(
                              children: [
                                const Icon(Icons.book_rounded, size: 18, color: Colors.brown),
                                const SizedBox(width: 6),
                                Text(
                                  'Bitácoras Incluidas (${reporte.idBitacoras.length}):',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            
                            if (reporte.idBitacoras.isEmpty)
                              const Padding(
                                padding: EdgeInsets.only(left: 8.0),
                                child: Text('No hay bitácoras asociadas a este reporte.', style: TextStyle(fontStyle: FontStyle.italic)),
                              )
                            else
                              ...reporte.idBitacoras.map((idBitacora) {
                              
                                return FutureBuilder<Bitacora?>( 
                                  future: _controlador.buscarBitacora(idBitacora), 
                                  builder: (context, bitacoraSnapshot) {
                                    if (bitacoraSnapshot.connectionState == ConnectionState.waiting) {
                                      return const Padding(
                                        padding: EdgeInsets.symmetric(vertical: 8.0),
                                        child: LinearProgressIndicator(),
                                      );
                                    }

                                    if (bitacoraSnapshot.hasError || !bitacoraSnapshot.hasData || bitacoraSnapshot.data == null) {
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                                        child: Text('Error al cargar la bitácora: $idBitacora', style: const TextStyle(color: Colors.red, fontSize: 12)),
                                      );
                                    }

                                    final bitacora = bitacoraSnapshot.data!;

                                    return Container(
                                      width: double.infinity,
                                      margin: const EdgeInsets.only(bottom: 8.0),
                                      padding: const EdgeInsets.all(12.0),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.withOpacity(0.06),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.grey.withOpacity(0.2)),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Actividad: ${bitacora.actividad}', 
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)
                                          ),
                                          const SizedBox(height: 4),
                                          
                                          if (bitacora.idParticipantes.isEmpty)
                                            const Text(
                                              'Participantes: Sin asignar',
                                              style: TextStyle(fontSize: 13, color: Colors.grey),
                                            )
                                          else
                                            FutureBuilder<List<String>>(
                                              future: Future.wait(
                                                bitacora.idParticipantes.map((id) async {
                                                  final usuario = await _controladorUsuario.buscarUsuario(id);
                                                  return usuario?.nombre ?? id;
                                                }),
                                              ),
                                              builder: (context, nombresSnapshot) {
                                                if (nombresSnapshot.connectionState == ConnectionState.waiting) {
                                                  return const Text(
                                                    'Cargando participantes...',
                                                    style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: Colors.grey),
                                                  );
                                                }

                                                final nombres = nombresSnapshot.data ?? bitacora.idParticipantes;
                                                
                                                return Text(
                                                  'Participantes: ${nombres.join(", ")}',
                                                  style: TextStyle(fontSize: 13, color: Colors.grey[800]),
                                                );
                                              },
                                            ),
                                            
                                          const SizedBox(height: 4),
                                          Text(
                                            'Observaciones: ${bitacora.observaciones.isNotEmpty ? bitacora.observaciones : "Sin observaciones"}',
                                            style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                );
                              }).toList(),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _irARegistroReporte,
        tooltip: 'Generar Nuevo Reporte',
        child: const Icon(Icons.add),
      ),
    );
  }
}