import 'dart:convert'; // Para decodificar Base64 si fuese necesario
import 'package:flutter/material.dart';
import 'package:software_petroglifos/controllers/controladorGestionArqueologica.dart';
import 'package:software_petroglifos/models/petroglifo.dart';
import 'package:software_petroglifos/pages/pantallaSitios.dart';

import 'package:software_petroglifos/pages/formularioRegistro.dart';
import 'package:software_petroglifos/pages/detallePetroglifo.dart';
import 'package:software_petroglifos/pages/pantallaBitacora.dart';
import 'package:software_petroglifos/pages/pantallaReportes.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final ControladorGestionArqueologica _controlador = ControladorGestionArqueologica();
  
  // Controla cuál botón de la barra inferior está seleccionado (0: Petroglifos por defecto)
  int _indiceActual = 0;

  void _irARegistroUsuario() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FormularioRegistro("Usuario", tipo: TipoRegistro.usuario)),
    );
    print("Navegando a la pantalla de registro de usuarios...");
  }

  void _irARegistroPetroglifo() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FormularioRegistro("Petroglifo", tipo: TipoRegistro.petroglifo)),
    ).then((_) {
      setState(() => _indiceActual = 0);
    });
    print("Navegando a la pantalla de registro de petroglifos...");
  }

  // ==========================================
  // MÉTODOS DE NAVEGACIÓN PARA LA BARRA INFERIOR
  // ==========================================

  void _irASitios() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PantallaListarSitios()),
    ).then((_) {
      // Al volver, restauramos el índice en 0 (Petroglifos) para mantener la consistencia visual
      setState(() => _indiceActual = 0);
    });
    print("Navegando a la pantalla de Sitios Arqueológicos...");
  }

  void _irABitacoras() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PantallaListarBitacoras()),
    ).then((_) {
      setState(() => _indiceActual = 0);
    });
    print("Navegando a la pantalla de Bitácoras...");
  }

  void _irAReportes() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PantallaReporte()),
    ).then((_) {
      setState(() => _indiceActual = 0);
    });
    print("Navegando a la pantalla de  Reportes Técnicos...");
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    
    int crossAxisCount = 1;
    if (width > 1200) {
      crossAxisCount = 4; 
    } else if (width > 800) {
      crossAxisCount = 3; 
    } else if (width > 500) {
      crossAxisCount = 2; 
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_rounded),
            tooltip: 'Registrar Usuario',
            //onPressed: _irARegistroUsuario,
            onPressed: () {
              _irARegistroUsuario();
            },
          ),
        ],
      ),
      
      body: StreamBuilder<List<Petroglifo>>(
        stream: _controlador.listarPetroglifos(), // Escucha Firestore en tiempo real
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error al cargar petroglifos: ${snapshot.error}'));
          }

          final petroglifos = snapshot.data ?? [];

          if (petroglifos.isEmpty) {
            return const Center(
              child: Text(
                'No hay registros',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(12.0),
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 12.0,
                mainAxisSpacing: 12.0,
                childAspectRatio: 0.85, 
              ),
              itemCount: petroglifos.length,
              itemBuilder: (context, index) {
                final petroglifo = petroglifos[index];
                String imageUrl = '';
                bool esBase64 = false;
                
                try {
                  final imgPrincipal = petroglifo.obtenerImagenPrincipal();
                  imageUrl = imgPrincipal.url; 
                  esBase64 = !imageUrl.startsWith('http');
                } catch (e) {
                  imageUrl = ''; 
                }

                return Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      print("Navegando al detalle del petroglifo con ID: ${petroglifo.id}");
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DetallePetroglifo(petroglifo: petroglifo),
                        ),
                      );
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                            child: imageUrl.isNotEmpty
                                ? (esBase64 
                                    ? Image.memory(
                                        base64Decode(imageUrl),
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 50),
                                      )
                                    : Image.network(
                                        imageUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 50),
                                      ))
                                : const Icon(Icons.image_not_supported, size: 50),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          key: ValueKey(petroglifo.id),
                          child: Text(
                            petroglifo.nombre,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indiceActual,
        onDestinationSelected: (int index) {
          setState(() {
            _indiceActual = index;
          });

          switch (index) {
            case 0:
              _irARegistroPetroglifo(); // Ahora el índice 0 abre directamente el formulario de registro solicitado
              break;
            case 1:
              _irASitios();
              break;
            case 2:
              _irABitacoras();
              break;
            case 3:
              _irAReportes(); // Nueva sección de reportes técnicos
              break;
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.landscape_rounded),
            label: 'Petroglifos',
          ),
          NavigationDestination(
            icon: Icon(Icons.place_rounded),
            label: 'Sitios',
          ),
          NavigationDestination(
            icon: Icon(Icons.book_rounded),
            label: 'Bitácoras',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_rounded), // Ícono representativo para reportes
            label: 'Reportes',
          ),
        ],
      ),
    );
  }
}