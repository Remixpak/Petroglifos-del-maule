enum EstadoAcceso { publico, privado }

class Sitio {
  final String _id;
  final String _nombre;
  final String _codigoInterno;
  final String _comuna;
  final String _descripcion;
  final EstadoAcceso _estadoAcceso;
  final double _latitud;
  final double _longitud;
  final List<String> _petroglifosIds;

  List<String> get petroglifosIds => _petroglifosIds;
  String get id => _id;
  String get nombre => _nombre;
  String get codigoInterno => _codigoInterno;
  String get comuna => _comuna;
  String get descripcion => _descripcion;
  EstadoAcceso get estadoAcceso => _estadoAcceso;
  double get latitud => _latitud;
  double get longitud => _longitud;

  Sitio({
    required this._id,
    required this._nombre,
    required this._codigoInterno,
    required this._comuna,
    required this._descripcion,
    required this._estadoAcceso,
    required this._latitud,
    required this._longitud,
    List<String>? petroglifosIds,
  }) : _petroglifosIds = petroglifosIds ?? [];

  void AgregarPetroglifo(String petroglifoId) {
    if (!petroglifosIds.contains(petroglifoId)) {
      petroglifosIds.add(petroglifoId);
    }
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'nombre': nombre,
      'codigoInterno': codigoInterno,
      'comuna': comuna,
      'descripcion': descripcion,
      'estadoAcceso': estadoAcceso.name,
      'latitud': latitud,
      'longitud': longitud,
      'petroglifosIds': petroglifosIds,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Sitio && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}