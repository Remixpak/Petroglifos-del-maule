
enum Rol { administrador, investigador }

class Usuario
{
  final String id;
  final String nombre;
  final String correo;
  final String clave;
  final bool isActive;
  final Rol rol;
  final String institucion;

  Usuario({
    required this.id,
    required this.nombre,
    required this.correo,
    required this.clave,
    this.isActive = true,
    required this.rol,
    required this.institucion,
    
  });

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'nombre': nombre,
      'correo': correo,
      'clave': clave,
      'isActive': isActive,
      'rol': rol.name,
      'institucion': institucion,
    };
  }
}