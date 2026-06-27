
enum Rol { administrador, investigador }

class Usuario
{
  final String _id;
  final String _nombre;
  final String _correo;
  final String _clave;
  final bool _isActive;
  final Rol _rol;
  final String _institucion;

  Usuario({
    required this._id,
    required this._nombre,
    required this._correo,
    required this._clave,
    this._isActive = true,
    required this._rol,
    required this._institucion,
    
  });

  String get id => _id;
  String get nombre => _nombre;
  String get correo => _correo;
  String get clave => _clave;
  bool get isActive => _isActive;
  Rol get rol => _rol;
  String get institucion => _institucion;


  Map<String, dynamic> toFirestore() {
    return {
      'id': _id,
      'nombre': _nombre,
      'correo': _correo,
      'clave': _clave,
      'isActive': _isActive,
      'rol': _rol.name,
      'institucion': _institucion,
    };
  }
}