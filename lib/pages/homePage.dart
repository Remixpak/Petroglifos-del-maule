import 'package:flutter/material.dart';
import 'package:software_petroglifos/controllers/controladorGestionArqueologica.dart';
import 'package:software_petroglifos/models/petroglifo.dart';

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

  // Extraemos la carga a un método propio para mantener limpio el initState
  void _cargarPetroglifos() {
    setState(() {
      _petroglifos = _controlador.listarPetroglifos();
    });
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    
    // Determinamos las columnas de forma responsiva
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
          // Botón extra para refrescar manualmente y probar el flujo de datos
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarPetroglifos,
          )
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
  
  // 1. Declaramos la variable como String estándar (no String?) para evitar nulos
  String imageUrl = '';
  
  try {
    // Si .url llega a ser null, usamos el operador '??' para que caiga en un String vacío
    imageUrl = petroglifo.ObtenerImagenPrincipal().url ?? '';
  } catch (e) {
    imageUrl = ''; // Si el método lanza una excepción, nos aseguramos de que sea un String vacío
  }

  return Card(
    elevation: 4,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Contenedor de la Imagen
        Expanded(
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            // 2. Aquí ya no usamos '!', evaluamos directamente la condición segura
            child: imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 50),
                  )
                : const Icon(Icons.image_not_supported, size: 50),
          ),
        ),
        // Nombre del Petroglifo abajo
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