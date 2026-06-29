import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:software_petroglifos/controllers/controladorGestionArqueologica.dart';
import 'package:software_petroglifos/controllers/controladorUsuario.dart'; // <-- IMPORTANTE
import 'package:software_petroglifos/models/petroglifo.dart';
import 'package:software_petroglifos/models/usuario.dart'; // <-- IMPORTANTE
import 'package:software_petroglifos/pages/pantallaSitios.dart';
import 'package:software_petroglifos/pages/formularioRegistro.dart';
import 'package:software_petroglifos/pages/detallePetroglifo.dart';
import 'package:software_petroglifos/pages/pantallaBitacora.dart';
import 'package:software_petroglifos/pages/pantallaReportes.dart';
import 'package:software_petroglifos/pages/panelUsuarios.dart';
import 'package:software_petroglifos/pages/pantallaSugerencia.dart';

class PaginaPrincipal extends StatefulWidget {
  const PaginaPrincipal({super.key, required this.title});
  final String title;

  @override
  State<PaginaPrincipal> createState() => _PaginaPrincipalState();
}

class _PaginaPrincipalState extends State<PaginaPrincipal> {
  final ControladorGestionArqueologica _controlador = ControladorGestionArqueologica();
  final ControladorUsuario _controladorUsuario = ControladorUsuario(); // <-- Instanciado para validar cuenta activa
  final TextEditingController _busquedaController = TextEditingController();

  List<Petroglifo>? _resultadoBusqueda;
  int _indiceActual = 0;

  void _irAPanelUsuario() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PanelUsuarios()),
    );
  }

  void _irALogin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FormularioRegistro("Usuario", tipo: TipoRegistro.usuario)),
    );
  }

  void _irARegistroPetroglifo() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FormularioRegistro("Petroglifo", tipo: TipoRegistro.petroglifo)),
    );
  }

  void _irASitios() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PantallaListarSitios()),
    );
  }

  void _irABitacoras() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PantallaListarBitacoras()),
    );
  }

  void _irAReportes() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PantallaReporte()),
    );
  }

  void _irASugerencias({required bool esUsuarioActivo}) {
    if (esUsuarioActivo) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const PantallaSugerencia()),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const FormularioRegistro("Sugerencia", tipo: TipoRegistro.sugerencia),
        ),
      );
    }
  }
  Future<void> _buscarPetroglifo() async {
  if (_busquedaController.text.trim().isEmpty) {
    setState(() {
      _resultadoBusqueda = null;
    });
    return;
  }

  final resultado = await _controlador.buscarPetroglifosPorNombre(
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
    
    int crossAxisCount = 1;
    if (width > 1200) {
      crossAxisCount = 4; 
    } else if (width > 800) {
      crossAxisCount = 3; 
    } else if (width > 500) {
      crossAxisCount = 2; 
    }

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        final bool tieneSesionAuth = authSnapshot.hasData && authSnapshot.data != null;

        return FutureBuilder<Usuario?>(
          future: tieneSesionAuth 
              ? _controladorUsuario.buscarUsuario(authSnapshot.data!.uid)
              : Future.value(null),
          builder: (context, usuarioSnapshot) {
            
            
            final bool estaLogeadoYActivo = tieneSesionAuth && 
            usuarioSnapshot.data != null && 
            (usuarioSnapshot.data!.isActive == true);

            return Scaffold(
              appBar: AppBar(
                backgroundColor: Theme.of(context).colorScheme.inversePrimary,
                title: Text(widget.title),
                actions: [
                  IconButton(
                    icon: Icon(
                      estaLogeadoYActivo 
                          ? Icons.person_add_alt_1_rounded 
                          : Icons.login_rounded
                    ),
                    tooltip: estaLogeadoYActivo ? 'Panel de Usuario' : 'Iniciar Sesión',
                    onPressed: estaLogeadoYActivo ? _irAPanelUsuario : _irALogin,
                  ),
                ],
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
                              labelText: "Buscar petroglifo",
                              prefixIcon: Icon(Icons.search),
                              border: OutlineInputBorder(),
                            ),
                            onSubmitted: (_) => _buscarPetroglifo(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.search),
                          onPressed: _buscarPetroglifo,
                        ),
                        IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: _limpiarBusqueda,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: StreamBuilder<List<Petroglifo>>(
                      stream: _controlador.listarPetroglifos(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        if (snapshot.hasError) {
                          return Center(child: Text('Error al cargar petroglifos: ${snapshot.error}'));
                        }

                        final petroglifos = _resultadoBusqueda ?? (snapshot.data ?? []);

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
                  ),
                ],
              ),
              bottomNavigationBar: NavigationBar(
                selectedIndex: _indiceActual,
                onDestinationSelected: (int index) {
  if (estaLogeadoYActivo) {
    
    setState(() {
      _indiceActual = index;
    });

    switch (index) {
      case 0:
        _irARegistroPetroglifo();
        break;
      case 1:
        _irASitios();
        break;
      case 2:
        _irABitacoras();
        break;
      case 3:
        _irAReportes();
        break;
      case 4:
        _irASugerencias(esUsuarioActivo: estaLogeadoYActivo);
        break;
    }

    if (index != 4) {
      setState(() => _indiceActual = 0);
    }
  } else {
    
    switch (index) {
      case 0:
        setState(() {
          _indiceActual = 0;
        });
        print("Se mantiene en la pantalla de Inicio pública.");
        break;
      case 1:
        
        _irASugerencias(esUsuarioActivo: estaLogeadoYActivo);
        break;
    }
  }
},
                
                destinations: estaLogeadoYActivo
                    ? const [
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
                          icon: Icon(Icons.assignment_rounded),
                          label: 'Reportes',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.lightbulb_rounded),
                          label: 'Sugerencias',
                        ),
                      ]
                    : const [
                        NavigationDestination(
                          icon: Icon(Icons.home_rounded),
                          label: 'Inicio',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.lightbulb_rounded),
                          label: 'Sugerencias',
                        ),
                      ],
              ),
            );
          },
        );
      },
    );
  }
}