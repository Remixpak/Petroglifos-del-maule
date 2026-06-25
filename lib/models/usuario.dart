
enum Rol { administrador, investigador }

class Usuario
{
  final String id;
  final String nombre;
  final String correo;
  final String clave;
  final bool estado;//Eliminar
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

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'nombre': nombre,
      'correo': correo,
      'clave': clave,
      'estado': estado,
      'rol': rol.name,
      'institucion': institucion,
    };
  }
}