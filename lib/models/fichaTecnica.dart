
enum MotivoPetroglifo { zoomorfo, antropomorfo, geometrico, mixto, indeterminado }
enum TecnicaGrabado { percusion, incision, raspado, mixto }
enum TipoRoca { basalto, granito, andesita, arenisca, otra }

class FichaTecnica {
  final String _id;
  final String _codigoPetroglifo;
  final String _descripcion;
  final MotivoPetroglifo _motivo;
  final TecnicaGrabado _tecnicaGrabado;
  final TipoRoca _tpoRoca;

  String get id => _id;
  String get codigoPetroglifo => _codigoPetroglifo;
  String get descripcion => _descripcion;
  MotivoPetroglifo get motivo => _motivo;
  TecnicaGrabado get tecnicaGrabado => _tecnicaGrabado;
  TipoRoca get tpoRoca => _tpoRoca;

  FichaTecnica({
    required this._id,
    required this._codigoPetroglifo,
    required this._descripcion,
    required this._motivo,
    required this._tecnicaGrabado,
    required this._tpoRoca,
  });
  
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'codigoPetroglifo': codigoPetroglifo,
      'descripcion': descripcion,
      'motivo': motivo.name,         
      'tecnicaGrabado': tecnicaGrabado.name,
      'tpoRoca': tpoRoca.name,
    };
  }
}