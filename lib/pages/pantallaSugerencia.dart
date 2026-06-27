import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:software_petroglifos/controllers/controladorUsuario.dart';
import 'package:software_petroglifos/controllers/controladorSugerencias.dart'; // <-- Tu nuevo controlador
import 'package:software_petroglifos/models/usuario.dart';


class PantallaSugerencia extends StatefulWidget {
  const PantallaSugerencia({super.key});

  @override
  State<PantallaSugerencia> createState() => _PantallaSugerenciaState();
}

class _PantallaSugerenciaState extends State<PantallaSugerencia> {
  final _controladorUsuario = ControladorUsuario();
  final _controladorSugerencia = Controladorsugerencias();


  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final double paddingHorizontal = width > 800 ? width * 0.15 : 12.0;
    final String? uidUsuarioActual = FirebaseAuth.instance.currentUser?.uid;

    return FutureBuilder<Usuario?>(
      future: uidUsuarioActual != null 
          ? _controladorUsuario.buscarUsuario(uidUsuarioActual) 
          : Future.value(null),
      builder: (context, usuarioActualSnapshot) {
        
        if (usuarioActualSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: Colors.indigo)),
          );
        }

        final Usuario? usuarioActual = usuarioActualSnapshot.data;
        final bool esUsuarioActualAdmin = usuarioActual?.rol == Rol.administrador;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Buzón de Sugerencias'),
          ),
          body: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _controladorSugerencia.listarSugerencias(), 
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error al cargar sugerencias: ${snapshot.error}'));
              }

              final sugerencias = snapshot.data ?? [];

              if (sugerencias.isEmpty) {
                return const Center(
                  child: Text(
                    'No hay sugerencias registradas',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                );
              }

              return ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: paddingHorizontal, vertical: 12.0),
                itemCount: sugerencias.length,
                itemBuilder: (context, index) {
                  final sugerencia = sugerencias[index];
                  final String idSugerencia = sugerencia['id'];
                  final String descripcion = sugerencia['descripcion'];
                  final DateTime fecha = sugerencia['fecha'];
                  bool estaAprobada = sugerencia['estado']; 

                  final String fechaFormateada = DateFormat('dd/MM/yyyy HH:mm').format(fecha);

                  return Card(
                    elevation: 3,
                    margin: const EdgeInsets.only(bottom: 12.0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: StatefulBuilder(
                        builder: (context, setStateLocal) {
                          return ExpansionTile(
                            backgroundColor: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.1),
                            leading: CircleAvatar(
                              backgroundColor: estaAprobada ? Colors.green : Colors.amber,
                              child: Icon(
                                estaAprobada ? Icons.verified_rounded : Icons.pending_actions_rounded, 
                                color: Colors.white
                              ),
                            ),
                            title: Text(
                              descripcion,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            subtitle: Text('Enviado el: $fechaFormateada'),
                            
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Divider(),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Detalle de la propuesta:',
                                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 13),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      descripcion,
                                      style: const TextStyle(fontSize: 14, height: 1.4),
                                    ),
                                    const SizedBox(height: 12),
                                    Text('ID Registro: $idSugerencia', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                    const SizedBox(height: 12),
                                    
                                    // Bloque interactivo de control de estados condicional por Rol
                                    if (esUsuarioActualAdmin) ...[
                                      Container(
                                        decoration: BoxDecoration(
                                          color: estaAprobada 
                                              ? Colors.green.withOpacity(0.08) 
                                              : Colors.amber.withOpacity(0.08),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: SwitchListTile(
                                          activeColor: Colors.green,
                                          inactiveTrackColor: Colors.amber.withOpacity(0.2),
                                          inactiveThumbColor: Colors.amber,
                                          title: Text(
                                            estaAprobada ? 'Sugerencia Aprobada' : 'Estado: Pendiente de Revisión',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: estaAprobada ? Colors.green : Colors.amber.shade800,
                                            ),
                                          ),
                                          subtitle: const Text('Cambiar la validación técnica del requerimiento.'),
                                          value: estaAprobada,
                                          onChanged: (bool nuevoEstado) {
                                            setStateLocal(() {
                                              estaAprobada = nuevoEstado;
                                            });

                                            ScaffoldMessenger.of(context).clearSnackBars();
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                behavior: SnackBarBehavior.floating,
                                                content: Text(
                                                  nuevoEstado
                                                      ? 'Marcando propuesta como APROBADA.'
                                                      : 'Marcando propuesta como PENDIENTE.',
                                                ),
                                              ),
                                            );

                                            // Ejecuta la actualización sobre el documento de la colección 'sugerencias'
                                            _controladorUsuario.cambiarEstadoCuenta(idSugerencia, nuevoEstado); 
                                            // NOTA TÉCNICA INTERNA: Si implementas un método específico, reemplaza la línea anterior por:
                                            // _controladorSugerencia.cambiarEstadoSugerencia(idSugerencia, nuevoEstado);
                                          },
                                        ),
                                      ),
                                    ] else ...[
                                      // Vista de solo lectura para arqueólogos o investigadores regulares
                                      Row(
                                        children: [
                                          Icon(
                                            estaAprobada ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                                            color: estaAprobada ? Colors.green : Colors.amber.shade700,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            estaAprobada ? 'Estatus: Revisado y Aprobado' : 'Estatus: Pendiente de análisis técnico',
                                            style: TextStyle(
                                              fontStyle: FontStyle.italic,
                                              color: estaAprobada ? Colors.green.shade700 : Colors.amber.shade800,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              )
                            ],
                          );
                        },
                      ),
                    ),
                  );
                },
              );
            },
          ),
          
        );
      },
    );
  }
}