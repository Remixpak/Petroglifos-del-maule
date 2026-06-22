import 'package:flutter/material.dart';
import 'package:software_petroglifos/controllers/controladorGestionArqueologica.dart';
import 'package:software_petroglifos/models/sitio.dart';
import 'package:software_petroglifos/pages/formularioSitios.dart'; // Ajusta la ruta real

class PantallaListarSitios extends StatefulWidget {
  const PantallaListarSitios({super.key});

  @override
  State<PantallaListarSitios> createState() => _PantallaListarSitiosState();
}

class _PantallaListarSitiosState extends State<PantallaListarSitios> {
  final _controlador = ControladorGestionArqueologica();

  void _irARegistroSitio() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PantallaRegistroSitio()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Ajuste de padding para que en PC no se pegue totalmente a los bordes del monitor
    final double width = MediaQuery.of(context).size.width;
    final double paddingHorizontal = width > 800 ? width * 0.15 : 12.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sitios Arqueológicos'),
      ),
      body: StreamBuilder<List<Sitio>>(
        stream: _controlador.listarSitios(), // Escucha la BD en tiempo real
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error al cargar sitios: ${snapshot.error}'));
          }

          final sitios = snapshot.data ?? [];

          if (sitios.isEmpty) {
            return const Center(
              child: Text(
                'No hay sitios registrados',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            );
          }

          return ListView.builder(
  padding: EdgeInsets.symmetric(horizontal: paddingHorizontal, vertical: 12.0),
  itemCount: sitios.length,
  itemBuilder: (context, index) { 
    final sitio = sitios[index];
              
              // Verificamos si las coordenadas deben protegerse
              final bool esPrivado = sitio.estadoAcceso == EstadoAcceso.privado;

              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 12.0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: ExpansionTile(
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.1),
                    leading: const Icon(Icons.place_rounded, color: Colors.brown),
                    // TÍTULO PRINCIPAL DE LA TARJETA
                    title: Text(
                      sitio.nombre,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    subtitle: Text('Código: ${sitio.codigoInterno}'),
                    
                    // CONTENIDO QUE SE DESPLIEGA AL APRETAR LA TARJETA
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Divider(),
                            const SizedBox(height: 4),
                            Text('Comuna: ${sitio.comuna.isNotEmpty ? sitio.comuna : "No especificada"}'),
                            const SizedBox(height: 6),
                            Text('Descripción: ${sitio.descripcion.isNotEmpty ? sitio.descripcion : "Sin descripción"}'),
                            const SizedBox(height: 6),
                            Text('Acceso: ${sitio.estadoAcceso.name}'),
                            const SizedBox(height: 6),
                            
                            // Muestra las coordenadas solo si el acceso NO es privado
                            if (!esPrivado) ...[
                              Text('Coordenadas GPS: ${sitio.latitud}, ${sitio.longitud}'),
                            ] else ...[
                              const Text(
                                'Coordenadas GPS: Protegidas (Sitio Privado)',
                                style: TextStyle(color: Colors.red, fontStyle: FontStyle.italic),
                              ),
                            ],
                            
                            const SizedBox(height: 14),
                            
                            // SUB-LISTA DE PETROGLIFOS ASOCIADOS
                            const Text(
                              'Petroglifos Asociados:',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey),
                            ),
                            const SizedBox(height: 6),
                            
                            //  MODIFICADO: Ahora evalúa 'sitio.petroglifosIds' en lugar del viejo 'sitio.petroglifos'
                            sitio.petroglifosIds.isEmpty
                                ? const Padding(
                                    padding: EdgeInsets.only(left: 8.0, top: 4.0),
                                    child: Text('Ningún petroglifo asociado aún.', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
                                  )
                                : Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    //  MODIFICADO: Mapea la lista de IDs (Strings) directamente
                                    children: sitio.petroglifosIds.map((idPetroglifo) {
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.blur_on_rounded, size: 16, color: Colors.orange),
                                            const SizedBox(width: 8),
                                            // Como solo tenemos el ID guardado en la relación del Sitio, 
                                            // mostramos el ID o un texto identificador corto por ahora.
                                            Text('ID Petroglifo: $idPetroglifo', style: const TextStyle(fontSize: 14)),
                                          ],
                                        ),
                                      );
                                    }).toList(),
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

      // BOTÓN FLOTANTE EN LA ESQUINA INFERIOR DERECHA
      floatingActionButton: FloatingActionButton(
        onPressed: _irARegistroSitio,
        tooltip: 'Registrar Nuevo Sitio',
        child: const Icon(Icons.add),
      ),
    );
  }
}