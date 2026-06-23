enum EstadoAcceso { publico, privado }

class Sitio {
  final String id;
  final String nombre;
  final String codigoInterno;
  final String comuna;
  final String descripcion;
  final EstadoAcceso estadoAcceso;
  final double latitud;
  final double longitud;
  final List<String> petroglifosIds; 

  Sitio({
    required this.id,
    required this.nombre,
    required this.codigoInterno,
    required this.comuna,
    required this.descripcion,
    required this.estadoAcceso,
    required this.latitud,
    required this.longitud,
    List<String>? petroglifosIds,
  }) : petroglifosIds = petroglifosIds ?? [];

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