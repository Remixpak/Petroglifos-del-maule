import 'package:software_petroglifos/models/imagen.dart';
import 'package:software_petroglifos/models/petroglifo.dart';
class ControladorGestionArqueologica {
  //
  List<Petroglifo> listarPetroglifos() {
    // Retorna una lista vacía para probar el mensaje de "no hay registros"
    // O retorna datos simulados:
    return [
      Petroglifo(
        id: '1',
        nombre: 'Petroglifo del Sol',
        //fichaTecnica: FichaTecnica(),
         imagenes: [
          imagen(id: 'a1', url: 'https://picsum.photos/200', isPrincipal: true, nombreArchivo: '', tipoArchivo: '', rutaArchivo: '')
        ], //fichaTecnica: null,
      ),
      Petroglifo(
        id: '2',
        nombre: 'Piedra de las Tazas',
        //fichaTecnica: FichaTecnica(),
         imagenes: [
          imagen(id: 'a2', url: 'https://picsum.photos/201', isPrincipal: true, nombreArchivo: '', tipoArchivo: '', rutaArchivo: '')
        ], //fichaTecnica: null,
      ),
    ];
  }
}