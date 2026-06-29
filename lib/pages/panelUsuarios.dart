import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; 
import 'package:software_petroglifos/controllers/controladorUsuario.dart'; 
import 'package:software_petroglifos/models/usuario.dart'; 
import 'package:software_petroglifos/pages/formularioRegistro.dart';

class PanelUsuarios extends StatefulWidget {
  const PanelUsuarios({super.key});

  @override
  State<PanelUsuarios> createState() => _PanelUsuariosState();
}

class _PanelUsuariosState extends State<PanelUsuarios> {
  final _controladorUsuario = ControladorUsuario(); 

  void _irARegistroUsuario() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const FormularioRegistro("Usuario", tipo: TipoRegistro.usuario),
      ),
    );
  }

  void _editarUsuario(Usuario usuario) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => FormularioRegistro(
        "",
        tipo: TipoRegistro.usuario,
        usuarioEditar: usuario,
      ),
    ),
  );
}

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
            title: const Text('Gestión de Investigadores'),
          ),
          body: StreamBuilder<List<Usuario>>(
            stream: _controladorUsuario.listarUsuarios(), 
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error al cargar usuarios: ${snapshot.error}'));
              }

              final usuarios = snapshot.data ?? [];

              if (usuarios.isEmpty) {
                return const Center(
                  child: Text(
                    'No hay investigadores registrados',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                );
              }

              return ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: paddingHorizontal, vertical: 12.0),
                itemCount: usuarios.length,
                itemBuilder: (context, index) {
                  final usuarioLista = usuarios[index];
                  bool cuentaActiva = usuarioLista.isActive; 

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
                              backgroundColor: cuentaActiva ? Colors.indigo : Colors.grey,
                              child: const Icon(Icons.person_rounded, color: Colors.white),
                            ),
                            title: Text(
                              usuarioLista.nombre,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            subtitle: Text('Rol: ${usuarioLista.rol.toString().split('.').last}'),
                            
                            children: [
                              Padding(
  padding: const EdgeInsets.all(16.0),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Divider(),
      const SizedBox(height: 4),
      Text('Correo Institucional: ${usuarioLista.correo}'),
      const SizedBox(height: 6),
      Text(
        'Institución: ${usuarioLista.institucion.isNotEmpty ? usuarioLista.institucion : "No especificada"}',
      ),
      const SizedBox(height: 12),

      if (esUsuarioActualAdmin) ...[
        Container(
          decoration: BoxDecoration(
            color: cuentaActiva
                ? Colors.green.withOpacity(0.08)
                : Colors.red.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: SwitchListTile(
            activeColor: Colors.green,
            inactiveTrackColor: Colors.red.withOpacity(0.2),
            inactiveThumbColor: Colors.red,
            title: Text(
              cuentaActiva
                  ? 'Cuenta Activa'
                  : 'Cuenta Desactivada (Sin Acceso)',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: cuentaActiva ? Colors.green : Colors.red,
              ),
            ),
            subtitle: Text(
              'Permitir acceso a ${usuarioLista.nombre} al software.',
            ),
            value: cuentaActiva,
            onChanged: (bool nuevoEstado) {
              setStateLocal(() {
                cuentaActiva = nuevoEstado;
              });

              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  behavior: SnackBarBehavior.floating,
                  content: Text(
                    nuevoEstado
                        ? 'Activando cuenta de: ${usuarioLista.nombre}'
                        : 'Desactivando cuenta de: ${usuarioLista.nombre}',
                  ),
                  action: SnackBarAction(
                    label: 'OK',
                    onPressed: () {},
                  ),
                ),
              );

              _controladorUsuario.cambiarEstadoCuenta(
                usuarioLista.id,
                nuevoEstado,
              );
            },
          ),
        ),
      ] else ...[
        Row(
          children: [
            Icon(
              cuentaActiva
                  ? Icons.check_circle_outline_rounded
                  : Icons.remove_circle_outline_rounded,
              color: cuentaActiva ? Colors.green : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              cuentaActiva
                  ? 'Estado de cuenta: Activa'
                  : 'Estado de cuenta: Inactiva',
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: cuentaActiva
                    ? Colors.green.shade700
                    : Colors.grey,
              ),
            ),
          ],
        ),
      ],

      const SizedBox(height: 20),

      if (esUsuarioActualAdmin)
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            onPressed: () => _editarUsuario(usuarioLista),
            icon: const Icon(Icons.edit),
            label: const Text("Editar Usuario"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          ),
        ),
    ],
  ),
),
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
          floatingActionButton: FloatingActionButton(
            onPressed: _irARegistroUsuario,
            tooltip: 'Registrar Nuevo Investigador',
            child: const Icon(Icons.person_add_rounded),
          ),
        );
      },
    );
  }
}