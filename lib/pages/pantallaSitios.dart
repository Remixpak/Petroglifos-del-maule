import 'package:flutter/material.dart';
import 'package:software_petroglifos/controllers/controladorGestionArqueologica.dart';
import 'package:software_petroglifos/models/sitio.dart';
import 'package:software_petroglifos/pages/formularioRegistro.dart';

class PantallaListarSitios extends StatefulWidget {
  const PantallaListarSitios({super.key});

  @override
  State<PantallaListarSitios> createState() => _PantallaListarSitiosState();
}

class _PantallaListarSitiosState extends State<PantallaListarSitios> {
  final _controlador = ControladorGestionArqueologica();
  final TextEditingController _busquedaController = TextEditingController();

  List<Sitio>? _resultadoBusqueda;
  void _irARegistroSitio() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FormularioRegistro("Sitio", tipo: TipoRegistro.sitio)),
    );
  }
  void _editarSitio(Sitio sitio) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => FormularioRegistro(
        "",
        tipo: TipoRegistro.sitio,
        sitioEditar: sitio,
        ),
      ),
    );
  }

  Future<void> _buscarSitio() async {
  if (_busquedaController.text.trim().isEmpty) {
    setState(() {
      _resultadoBusqueda = null;
    });
    return;
  }

  final resultado = await _controlador.buscarSitiosPorCodigoInterno(
    _busquedaController.text,
  );

  setState(() {
    _resultadoBusqueda = resultado;
  });
}
void _limpiarBusqueda() {
  _busquedaController.clear();

  setState(() {
    _resultadoBusqueda = null;
  });
}

  @override
  Widget build(BuildContext context) {
    
    final double width = MediaQuery.of(context).size.width;
    final double paddingHorizontal = width > 800 ? width * 0.15 : 12.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sitios Arqueológicos'),
      ),
      body: Column(
  children: [

    Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [

          Expanded(
            child: TextField(
              controller: _busquedaController,
              decoration: const InputDecoration(
                labelText: 'Buscar por código interno',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onSubmitted: (_) => _buscarSitio(),
            ),
          ),

          const SizedBox(width: 8),

          IconButton(
            onPressed: _buscarSitio,
            icon: const Icon(Icons.search),
          ),

          IconButton(
            onPressed: _limpiarBusqueda,
            icon: const Icon(Icons.clear),
          ),
        ],
      ),
    ),

    Expanded(
      child: StreamBuilder<List<Sitio>>(
        stream: _controlador.listarSitios(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error al cargar sitios: ${snapshot.error}'));
          }

          final sitios = _resultadoBusqueda ?? (snapshot.data ?? []);

          if (sitios.isEmpty) {
  return Center(
    child: Text(
      _resultadoBusqueda != null
          ? 'No se encontró ningún sitio con ese código.'
          : 'No hay sitios registrados',
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}

          return ListView.builder(
  padding: EdgeInsets.symmetric(horizontal: paddingHorizontal, vertical: 12.0),
  itemCount: sitios.length,
  itemBuilder: (context, index) { 
    final sitio = sitios[index];
              
             
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
                            
                            
                            if (!esPrivado) ...[
                              Text('Coordenadas GPS: ${sitio.latitud}, ${sitio.longitud}'),
                            ] else ...[
                              const Text(
                                'Coordenadas GPS: Protegidas (Sitio Privado)',
                                style: TextStyle(color: Colors.red, fontStyle: FontStyle.italic),
                              ),
                            ],
                            
                            const SizedBox(height: 14),
                            
                           
                            const Text(
                              'Petroglifos Asociados:',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey),
                            ),
                            const SizedBox(height: 6),
                            
                            
                            sitio.petroglifosIds.isEmpty
                                ? const Padding(
                                    padding: EdgeInsets.only(left: 8.0, top: 4.0),
                                    child: Text('Ningún petroglifo asociado aún.', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
                                  )
                                : Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    
                                    children: sitio.petroglifosIds.map((idPetroglifo) {
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.blur_on_rounded, size: 16, color: Colors.orange),
                                            const SizedBox(width: 8),
                                            
                                            Text('ID Petroglifo: $idPetroglifo', style: const TextStyle(fontSize: 14)),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                  const SizedBox(height: 20),

Align(
  alignment: Alignment.centerRight,
  child: ElevatedButton.icon(
    icon: const Icon(Icons.edit),
    label: const Text("Editar Sitio"),
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.orange,
      foregroundColor: Colors.white,
    ),
    onPressed: () => _editarSitio(sitio),
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
    ),
  ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _irARegistroSitio,
        tooltip: 'Registrar Nuevo Sitio',
        child: const Icon(Icons.add),
      ),
    );
  }
}