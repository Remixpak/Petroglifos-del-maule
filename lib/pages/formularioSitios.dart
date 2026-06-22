import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:software_petroglifos/controllers/controladorGestionArqueologica.dart';
import 'package:software_petroglifos/models/sitio.dart';

class PantallaRegistroSitio extends StatefulWidget {
  const PantallaRegistroSitio({super.key});

  @override
  State<PantallaRegistroSitio> createState() => _PantallaRegistroSitioState();
}

class _PantallaRegistroSitioState extends State<PantallaRegistroSitio> {
  final _controlador = ControladorGestionArqueologica();

  // Controladores de texto
  final _nombreController = TextEditingController();
  final _codigoController = TextEditingController();
  final _comunaController = TextEditingController();
  final _descripcionController = TextEditingController();

  // Variables de Estado
  EstadoAcceso _accesoSeleccionado = EstadoAcceso.publico;
  double? _latitud;
  double? _longitud;

  bool _obteniendoGps = false;
  bool _guardandoDatos = false;

  @override
  void dispose() {
    _nombreController.dispose();
    _codigoController.dispose();
    _comunaController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  // Función asíncrona para obtener coordenadas reales usando Geolocator
  Future<void> _obtenerCoordenadasGps() async {
    setState(() => _obteniendoGps = true);
    try {
      bool servicioHabilitado;
      LocationPermission permiso;

      // 1. Verificar si el GPS físico del dispositivo está encendido
      servicioHabilitado = await Geolocator.isLocationServiceEnabled();
      if (!servicioHabilitado) {
        throw 'El servicio de ubicación (GPS) está desactivado en el dispositivo.';
      }

      // 2. Verificar y solicitar los permisos del sistema operativo
      permiso = await Geolocator.checkPermission();
      if (permiso == LocationPermission.denied) {
        permiso = await Geolocator.requestPermission();
        if (permiso == LocationPermission.denied) {
          throw 'Los permisos de ubicación fueron denegados.';
        }
      }

      if (permiso == LocationPermission.deniedForever) {
        throw 'Los permisos de ubicación están denegados permanentemente en la configuración.';
      }

      // 3. Capturar la posición actual del dispositivo móvil
      Position posicion = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      setState(() {
        _latitud = posicion.latitude;
        _longitud = posicion.longitude;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error de Ubicación: $e')),
      );
    } finally {
      setState(() => _obteniendoGps = false);
    }
  }

  void _registrarSitio() async {
    if (_nombreController.text.isEmpty || _codigoController.text.isEmpty || _latitud == null || _longitud == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, complete los datos obligatorios y capture las coordenadas GPS.')),
      );
      return;
    }

    setState(() => _guardandoDatos = true);

    bool exito = await _controlador.registrarSitio(
      nombre: _nombreController.text,
      codigoInterno: _codigoController.text,
      comuna: _comunaController.text,
      descripcion: _descripcionController.text,
      estadoAcceso: _accesoSeleccionado,
      latitud: _latitud!,
      longitud: _longitud!,
    );

    setState(() => _guardandoDatos = false);

    if (exito) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Sitio Arqueológico registrado con éxito!')),
      );
      Navigator.pop(context); // Regresa a la pantalla principal
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al procesar el registro en la base de datos.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final double paddingHorizontal = width > 600 ? width * 0.20 : 16.0;

    return Scaffold(
      appBar: AppBar(title: const Text('Registrar Nuevo Sitio')),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: paddingHorizontal, vertical: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _nombreController,
                  decoration: const InputDecoration(labelText: 'Nombre del Sitio *', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _codigoController,
                  decoration: const InputDecoration(labelText: 'Código Interno (Ej: ST-01) *', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _comunaController,
                  decoration: const InputDecoration(labelText: 'Comuna', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _descripcionController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Descripción del Entorno', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<EstadoAcceso>(
                  value: _accesoSeleccionado,
                  decoration: const InputDecoration(labelText: 'Estado de Acceso', border: OutlineInputBorder()),
                  items: EstadoAcceso.values.map((EstadoAcceso estado) {
                    return DropdownMenuItem<EstadoAcceso>(value: estado, child: Text(estado.name));
                  }).toList(),
                  onChanged: (val) => setState(() => _accesoSeleccionado = val!),
                ),
                const SizedBox(height: 20),
                
                // PANEL GEOGRÁFICO (GPS)
                Card(
                  color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text(
                          _latitud != null && _longitud != null
                              ? 'Coordenadas: ($_latitud, $_longitud)'
                              : 'Ubicación Satelital no capturada *',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _latitud != null ? Colors.green : Colors.red,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _obteniendoGps
                            ? const CircularProgressIndicator()
                            : ElevatedButton.icon(
                                icon: const Icon(Icons.location_searching_rounded),
                                label: const Text('Obtener Coordenadas GPS'),
                                onPressed: _obtenerCoordenadasGps,
                              ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                
                _guardandoDatos
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
                        onPressed: _registrarSitio,
                        child: const Text('Guardar Sitio Arqueológico', style: TextStyle(fontSize: 16)),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}