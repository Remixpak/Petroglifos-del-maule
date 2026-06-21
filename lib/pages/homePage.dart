import 'package:flutter/material.dart';
import 'package:software_petroglifos/controllers/controladorGestionArqueologica.dart';
import 'package:software_petroglifos/models/petroglifo.dart';
import 'package:software_petroglifos/pages/PantallaDeRegistro.dart';

/*
Este archivo es el de la pagina principal, se conecta al controlador de gestion
arqueologica para listar todos los petroglifos del sistema.
(REVISAR ESTO PARA MAS ADELANTE)
deberia tener conexión con la pagina de detalles del petroglifo, y con la pagina de agregar nuevo petroglifo.
*/

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final ControladorGestionArqueologica _controlador = ControladorGestionArqueologica();
  List<Petroglifo> _petroglifos = [];

  @override
  void initState() {
    super.initState();
    _cargarPetroglifos();
  }

  void _cargarPetroglifos() {
    setState(() {
      _petroglifos = _controlador.listarPetroglifos();
    });
  }

  // Método encargado de gestionar la navegación hacia el registro de usuarios
  void _irARegistroUsuario() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PantallaRegistro()),
    );
    
    
    // Print temporal para verificar en consola que el botón funciona al presionarlo
    print("Navegando a la pantalla de registro de usuarios...");
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
          // NUEVO: Botón para ir al registro de usuarios
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_rounded),
            tooltip: 'Registrar Usuario',
            onPressed: _irARegistroUsuario, // Llama al método con el cuerpo comentado
          ),
          // Botón para refrescar manualmente
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refrescar',
            onPressed: _cargarPetroglifos,
          ),
        ],
      ),
      body: _petroglifos.isEmpty
          ? const Center(
              child: Text(
                'No hay registros',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(12.0),
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 12.0,
                  mainAxisSpacing: 12.0,
                  childAspectRatio: 0.85, 
                ),
                itemCount: _petroglifos.length,
                itemBuilder: (context, index) {
                  final petroglifo = _petroglifos[index];
                  String imageUrl = '';
                  
                  try {
                    imageUrl = petroglifo.ObtenerImagenPrincipal().url ?? '';
                  } catch (e) {
                    imageUrl = ''; 
                  }

                  return Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                            child: imageUrl.isNotEmpty
                                ? Image.network(
                                    imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 50),
                                  )
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
                  );
                },
              ),
            ),
    );
  }
}