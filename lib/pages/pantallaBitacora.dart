import 'package:flutter/material.dart';
import 'package:software_petroglifos/controllers/controladorGestionArqueologica.dart';
import 'package:software_petroglifos/models/bitacora.dart'; // Asegúrate de importar tu modelo Bitacora
import 'package:software_petroglifos/pages/formularioRegistro.dart';

class PantallaListarBitacoras extends StatefulWidget {
  const PantallaListarBitacoras({super.key});

  @override
  State<PantallaListarBitacoras> createState() => _PantallaListarBitacorasState();
}

class _PantallaListarBitacorasState extends State<PantallaListarBitacoras> {
  final _controlador = ControladorGestionArqueologica();

  void _irARegistroBitacora() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FormularioRegistro("Bitácora", tipo: TipoRegistro.bitacora)),
    );
  }
  void _editarBitacora(Bitacora bitacora) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => FormularioRegistro(
        "",
        tipo: TipoRegistro.bitacora,
        bitacoraEditar: bitacora,
      ),
    ),
  );
}

  // Helper para formatear la fecha y hora de manera legible (Ej: 24/06/2026 14:30)
  String _formatearFecha(DateTime fecha) {
    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    final anio = fecha.year;
    final hora = fecha.hour.toString().padLeft(2, '0');
    final minuto = fecha.minute.toString().padLeft(2, '0');
    return '$dia/$mes/$anio $hora:$minuto';
  }

  @override
  Widget build(BuildContext context) {
    // Ajuste de padding dinámico idéntico al de sitios para monitores o PC
    final double width = MediaQuery.of(context).size.width;
    final double paddingHorizontal = width > 800 ? width * 0.15 : 12.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bitácoras de Terreno'),
      ),
      body: StreamBuilder<List<Bitacora>>(
        // Usamos la colección genérica o el método específico que implementemos en tu controlador
        stream: _controlador.listarBitacoras(), 
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error al cargar bitácoras: ${snapshot.error}'));
          }

          final bitacoras = snapshot.data ?? [];

          if (bitacoras.isEmpty) {
            return const Center(
              child: Text(
                'No hay bitácoras registradas',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: paddingHorizontal, vertical: 12.0),
            itemCount: bitacoras.length,
            itemBuilder: (context, index) {
              final bitacora = bitacoras[index];

              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 12.0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: ExpansionTile(
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.1),
                    leading: const Icon(Icons.book_rounded, color: Colors.brown),
                    
                    // TÍTULO PRINCIPAL: Actividad realizada
                    title: Text(
                      bitacora.actividad,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    // SUBTÍTULO: Fecha de inicio de la jornada
                    subtitle: Text('Inicio: ${_formatearFecha(bitacora.fechaInicio)}'),
                    
                    // CONTENIDO EXTENDIDO DESPLEGABLE
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Divider(),
                            const SizedBox(height: 4),
                            Text(
                              'Fin de la Jornada: ${_formatearFecha(bitacora.fechaFin)}',
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Observaciones de Campo:\n${bitacora.observaciones.isNotEmpty ? bitacora.observaciones : "Sin observaciones registradas."}',
                              style: TextStyle(color: const Color.fromARGB(255, 63, 63, 63)),
                            ),
                            const SizedBox(height: 14),
                            
                            // SUB-LISTA DE PARTICIPANTES (IDs)
                            const Row(
                              children: [
                                Icon(Icons.people_alt_rounded, size: 18, color: Colors.blueGrey),
                                SizedBox(width: 6),
                                Text(
                                  'Participantes del Equipo:',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            
                            bitacora.idParticipantes.isEmpty
                                ? const Padding(
                                    padding: EdgeInsets.only(left: 8.0, top: 4.0),
                                    child: Text(
                                      'No se asociaron IDs de participantes.', 
                                      style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                                    ),
                                  )
                                : Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: bitacora.idParticipantes.map((idParticipante) {
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.person_outline_rounded, size: 16, color: Colors.orange),
                                            const SizedBox(width: 8),
                                            Text(
                                              'ID Investigador: $idParticipante', 
                                              style: const TextStyle(fontSize: 14),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                  const SizedBox(height: 20),

Align(
  alignment: Alignment.centerRight,
  child: ElevatedButton.icon(
    onPressed: () => _editarBitacora(bitacora),
    icon: const Icon(Icons.edit),
    label: const Text("Editar Bitácora"),
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.orange,
      foregroundColor: Colors.white,
    ),
  ),
),
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

      // BOTÓN FLOTANTE PARA REGISTRAR NUEVA BITÁCORA
      floatingActionButton: FloatingActionButton(
        //onPressed: _irARegistroBitacora,
        onPressed: () {
          _irARegistroBitacora();
        },
        tooltip: 'Registrar Nueva Bitácora',
        child: const Icon(Icons.add),
      ),
    );
  }
}