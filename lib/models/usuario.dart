
enum Rol { Administrador, Investigador }

class Usuario
{
  final String id;
  final String nombre;
  final String correo;
  final String clave;
  final bool estado;
  final Rol rol;
  final String institucion;
  Usuario({
    required this.id,
    required this.nombre,
    required this.correo,
    required this.clave,
    required this.estado,
    required this.rol,
    required this.institucion,
  });
}