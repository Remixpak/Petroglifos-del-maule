import 'package:flutter/material.dart';
import 'package:software_petroglifos/controllers/ControladorRegistroLogin.dart';
import 'package:software_petroglifos/models/usuario.dart'; // Ajusta a tu modelo

class PantallaRegistro extends StatefulWidget {
  const PantallaRegistro({super.key});

  @override
  State<PantallaRegistro> createState() => _PantallaRegistroState();
}

class _PantallaRegistroState extends State<PantallaRegistro> {
  final Controladorregistrologin _controlador = Controladorregistrologin();

  // Controladores para capturar los textos
  final _nombreController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _institucionController = TextEditingController();

  // Variable para el Dropdown (Por defecto Investigador)
  Rol _rolSeleccionado = Rol.Investigador;
  
  bool _estaCargando = false;

  @override
  void dispose() {
    // Es una buena práctica liberar los controladores de texto de la memoria
    _nombreController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _institucionController.dispose();
    super.dispose();
  }

  void _ejecutarRegistro() async {
    // Validación simple
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty || _nombreController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, rellena los campos obligatorios')),
      );
      return;
    }

    setState(() => _estaCargando = true);

    bool exito = await _controlador.registrarUsuario(
      nombre: _nombreController.text,
      correo: _emailController.text,
      clave: _passwordController.text,
      rol: _rolSeleccionado,
      institucion: _institucionController.text,
    );

    setState(() => _estaCargando = false);

    if (exito) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Usuario registrado con éxito!')),
      );
      // Opcional: Volver a la pantalla anterior si todo sale bien
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hubo un error al registrar el usuario')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calculamos el ancho para que el formulario no se vea gigante en PC
    final double width = MediaQuery.of(context).size.width;
    final double paddingHorizontal = width > 600 ? width * 0.25 : 16.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro de Usuario'),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: paddingHorizontal, vertical: 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _nombreController,
                  decoration: const InputDecoration(labelText: 'Nombre Completo', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Contraseña', border: OutlineInputBorder()),
                  obscureText: true,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _institucionController,
                  decoration: const InputDecoration(labelText: 'Institución / Universidad', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                
                // Dropdown para seleccionar el Rol de forma segura
                DropdownButtonFormField<Rol>(
                  value: _rolSeleccionado,
                  decoration: const InputDecoration(labelText: 'Rol del Sistema', border: OutlineInputBorder()),
                  items: Rol.values.map((Rol rol) {
                    return DropdownMenuItem<Rol>(
                      value: rol,
                      child: Text(rol.name), // Muestra 'Administrador' o 'Investigador'
                    );
                  }).toList(),
                  onChanged: (Rol? nuevoRol) {
                    if (nuevoRol != null) {
                      setState(() {
                        _rolSeleccionado = nuevoRol;
                      });
                    }
                  },
                ),
                const SizedBox(height: 24),
                
                _estaCargando
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
                        onPressed: _ejecutarRegistro,
                        child: const Text('Registrar', style: TextStyle(fontSize: 16)),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}