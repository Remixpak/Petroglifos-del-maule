import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:file_selector_platform_interface/file_selector_platform_interface.dart';


// Importaciones de tus modelos y controladores del proyecto
import 'package:software_petroglifos/controllers/controladorGestionArqueologica.dart';
import 'package:software_petroglifos/controllers/controladorUsuario.dart';
import 'package:software_petroglifos/controllers/controladorSugerencias.dart';
import 'package:software_petroglifos/models/bitacora.dart';
import 'package:software_petroglifos/models/fichaTecnica.dart';
import 'package:software_petroglifos/models/sitio.dart';
import 'package:software_petroglifos/models/usuario.dart';
import 'package:software_petroglifos/pages/homePage.dart';

// =========================================================================
// ENUM: TIPOS DE REGISTRO CENTRALIZADOS
// =========================================================================
enum TipoRegistro {
  petroglifo,
  sitio,
  usuario,
  bitacora,
  reporte,
  sugerencia,
}

class FormularioRegistro extends StatefulWidget {
  final TipoRegistro tipo;

  final Sitio? sitioEditar;
  final Bitacora? bitacoraEditar;
  final Usuario? usuarioEditar;
  

  const FormularioRegistro(
    String s,{
    super.key,
    required this.tipo,
    this.sitioEditar,
    this.bitacoraEditar,
    this.usuarioEditar
  });


  @override
  State<FormularioRegistro> createState() => _FormularioRegistroState();
}

class _FormularioRegistroState extends State<FormularioRegistro> {
  //=========================================================================
  //controladores
  //=========================================================================
  final _controladorNegocio = ControladorGestionArqueologica();
  final _controladorUsuario = ControladorUsuario();
  bool _guardando = false;

  //=========================================================================
  //variables petroglifo
  //=========================================================================
  final _nombrePetroglifoController = TextEditingController();
  Sitio? _sitioSeleccionado;
  final List<PlatformFile> _fotosVisualizables = [];
  int _indiceImagenPrincipal = 0;
  List<PlatformFile> _archivosMultimedia = [];
  final ImagePicker _imagePicker = ImagePicker();
  late Stream<List<Sitio>> _sitiosStream;
  final _descripcionFichaController = TextEditingController();
  MotivoPetroglifo _motivoSeleccionado = MotivoPetroglifo.indeterminado;
  TecnicaGrabado _tecnicaSeleccionada = TecnicaGrabado.percusion;
  TipoRoca _rocaSeleccionada = TipoRoca.basalto;

  //=========================================================================
  //variables sitio
  //=========================================================================
  final _nombreSitioController = TextEditingController();
  final _codigoSitioController = TextEditingController();
  final _comunaSitioController = TextEditingController();
  final _descripcionSitioController = TextEditingController();
  EstadoAcceso _accesoSeleccionado = EstadoAcceso.publico;
  double? _latitud;
  double? _longitud;
  bool _obteniendoGps = false;

  //=========================================================================
  //variables usuario
  //=========================================================================
  bool _esLogin = true;
  bool _esAdmin = false;
  bool _cargandoRol = true; 
  Rol _rolSeleccionado = Rol.investigador;
  final _nombreController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _rolController = TextEditingController();
  final _institucionController = TextEditingController();

  // =========================================================================
  //variables bitacora
  // =========================================================================
  final _actividadBitacoraController = TextEditingController();
  final _observacionesBitacoraController = TextEditingController();
  DateTime _fechaInicioBitacora = DateTime.now();
  DateTime _fechaFinBitacora = DateTime.now();
  List<String?> _participantesBitacora = [null];
  //================================================================
  //variables reporte
  //================================================================
  DateTime _rangoFechaReporte = DateTime.now();
  bool _buscandoBitacoras = false;
  //================================================================
  //variables sugerencia
  //================================================================
  final _descripcionSugerenciaController = TextEditingController();
  final _controladorSugerencia = Controladorsugerencias();
  
  bool get _modoEdicionSitio => widget.sitioEditar != null;

  bool get _modoEdicionBitacora => widget.bitacoraEditar != null;

  @override
void initState() {
  super.initState();

  _verificarSiEsAdmin();

  if(widget.tipo == TipoRegistro.petroglifo){
      _sitiosStream = _controladorNegocio.listarSitios();
  }

  if(widget.sitioEditar != null){
      _cargarSitio(widget.sitioEditar!);
  }

  if(widget.bitacoraEditar != null){
      _cargarBitacora(widget.bitacoraEditar!);
  }

  if (widget.usuarioEditar != null) {
  _cargarUsuario(widget.usuarioEditar!);
}
}


  @override
  void dispose() {
    // Limpieza absoluta de todos los controladores de texto del sistema
    _nombrePetroglifoController.dispose();
    _descripcionFichaController.dispose();
    _nombreSitioController.dispose();
    _codigoSitioController.dispose();
    _comunaSitioController.dispose();
    _descripcionSitioController.dispose();
    _nombreController.dispose();
    _emailController.dispose();
    _actividadBitacoraController.dispose();
    _observacionesBitacoraController.dispose();
    _passwordController.dispose();
    _rolController.dispose();
    _institucionController.dispose();
    super.dispose();
  }

  //=========================================================================
  //funciones de petroglifos
  //=========================================================================
  Future<void> _tomarFoto() async {
    final XFile? foto = await _imagePicker.pickImage(
      source: ImageSource.camera, 
      imageQuality: 20, 
      maxWidth: 800,   
      maxHeight: 800,  
    );
    if (foto != null) {
      final int size = await foto.length();
      final Uint8List bytes = await foto.readAsBytes(); 
      setState(() {
        _fotosVisualizables.add(PlatformFile(
          name: foto.name,
          path: foto.path,
          size: size,
          bytes: bytes, 
        ));
      });
    }
  }

  Future<void> _seleccionarArchivosExtra() async {
    if (defaultTargetPlatform == TargetPlatform.windows) {
      try {
        final XTypeGroup typeGroup = XTypeGroup(
          label: 'Imágenes',
          extensions: <String>['jpg', 'jpeg', 'png'], 
        );
        final List<XFile> archivosSeleccionados = await FileSelectorPlatform.instance.openFiles(
          acceptedTypeGroups: <XTypeGroup>[typeGroup], 
        );
        if (archivosSeleccionados.isNotEmpty) {
          for (var xFile in archivosSeleccionados) {
            final Uint8List bytes = await xFile.readAsBytes();
            setState(() {
              _fotosVisualizables.add(PlatformFile(
                name: xFile.name,
                path: xFile.path,
                size: 0, 
                bytes: bytes,
              ));
            });
          }
        }
      } catch (e) {
        print("Error en explorador de Windows: $e");
      }
    } else {
      try {
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          allowMultiple: true,
          type: FileType.any,
          withData: true, 
        );
        if (result != null) {
          for (var file in result.files) {
            if (file.extension == 'jpg' || file.extension == 'jpeg' || file.extension == 'png') {
              setState(() => _fotosVisualizables.add(file));
            } else {
              setState(() => _archivosMultimedia.add(file));
            }
          }
        }
      } catch (e) {
        print("Error en explorador de Android: $e");
      }
    }
  }

  void _procesarGuardadoPetroglifo() async {
    if (_nombrePetroglifoController.text.isEmpty || 
        _sitioSeleccionado == null || 
        _fotosVisualizables.isEmpty || 
        _descripcionFichaController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Complete los campos obligatorios (*) del Petroglifo y su Ficha.')),
      );
      return;
    }

    setState(() => _guardando = true);

    bool exito = await _controladorNegocio.registrarPetroglifo(
      nombre: _nombrePetroglifoController.text,
      fotosCandidatas: _fotosVisualizables,
      indicePrincipal: _indiceImagenPrincipal,
      archivosExtra: _archivosMultimedia,
      sitioSeleccionado: _sitioSeleccionado!,
      descripcionFicha: _descripcionFichaController.text,
      motivoFicha: _motivoSeleccionado,
      tecnicaFicha: _tecnicaSeleccionada,
      rocaFicha: _rocaSeleccionada,
    );

    setState(() => _guardando = false);
    if (exito) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Petroglifo y Ficha Técnica vinculados con éxito!')),
      );
      Navigator.pop(context);
    }
  }

  //=========================================================================
  //funciones de sitios
  //=========================================================================
  Future<void> _obtenerCoordenadasGps() async {
    setState(() => _obteniendoGps = true);
    try {
      bool servicioHabilitado = await Geolocator.isLocationServiceEnabled();
      if (!servicioHabilitado) throw 'El GPS del dispositivo está desactivado.';

      LocationPermission permiso = await Geolocator.checkPermission();
      if (permiso == LocationPermission.denied) {
        permiso = await Geolocator.requestPermission();
        if (permiso == LocationPermission.denied) throw 'Permisos denegados.';
      }
      if (permiso == LocationPermission.deniedForever) throw 'Permisos denegados permanentemente.';

      Position posicion = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      setState(() {
        _latitud = posicion.latitude;
        _longitud = posicion.longitude;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error GPS: $e')));
    } finally {
      setState(() => _obteniendoGps = false);
    }
  }

  void _procesarGuardadoSitio() async {
    if (_nombreSitioController.text.isEmpty || _codigoSitioController.text.isEmpty || _latitud == null || _longitud == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Complete los datos obligatorios y capture el GPS.')),
      );
      return;
    }
    setState(() => _guardando = true);
    bool exito = await _controladorNegocio.registrarSitio(
      nombre: _nombreSitioController.text,
      codigoInterno: _codigoSitioController.text,
      comuna: _comunaSitioController.text,
      descripcion: _descripcionSitioController.text,
      estadoAcceso: _accesoSeleccionado,
      latitud: _latitud!,
      longitud: _longitud!,
    );
    setState(() => _guardando = false);
    if (exito) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('¡Sitio registrado con éxito!')));
      Navigator.pop(context);
    }
  }

  void _cargarSitio(Sitio sitio){

    _nombreSitioController.text = sitio.nombre;

    _codigoSitioController.text = sitio.codigoInterno;

    _comunaSitioController.text = sitio.comuna;

    _descripcionSitioController.text = sitio.descripcion;

    _accesoSeleccionado = sitio.estadoAcceso;

    _latitud = sitio.latitud;

    _longitud = sitio.longitud;
}

  Future<void> _procesarEdicionSitio() async {

    Sitio sitioActualizado = Sitio(

        id: widget.sitioEditar!.id,

        nombre: _nombreSitioController.text,

        codigoInterno: _codigoSitioController.text,

        comuna: _comunaSitioController.text,

        descripcion: _descripcionSitioController.text,

        estadoAcceso: _accesoSeleccionado,

        latitud: _latitud!,

        longitud: _longitud!,

        petroglifosIds: widget.sitioEditar!.petroglifosIds,
    );

    bool exito =
        await _controladorNegocio.actualizarSitio(
            sitio: sitioActualizado,
        );
        if (!mounted) return;

if (exito) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Sitio actualizado correctamente.'),
      backgroundColor: Colors.green,
    ),
  );

  Navigator.pop(context);
} else {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Ocurrió un error al actualizar el sitio.'),
      backgroundColor: Colors.red,
    ),
  );
}
}

  //=========================================================================
  //funciones de usuario
  //=========================================================================
  void _procesarGuardadoUsuario() async {

    // === SECCIÓN DE PRINTS PARA DEPURACIÓN ===
  print('=============================================');
  print('DEBUG REGISTRO INVESTIGADOR:');
  print('Email: "${_emailController.text}" (Largo: ${_emailController.text.length})');
  print('Password: "${_passwordController.text}" (Largo: ${_passwordController.text.length})');
  print('Nombre: "${_nombreController.text}" (Largo: ${_nombreController.text.length})');
  print('Institución: "${_institucionController.text}" (Largo: ${_institucionController.text.length})');
  print('Rol Seleccionado (Enum): $_rolSeleccionado');
  print('=============================================');
  if (_nombreController.text.trim().isEmpty || 
      _emailController.text.trim().isEmpty ||
      _passwordController.text.trim().isEmpty ||
      _institucionController.text.trim().isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Por favor, completa todos los campos del investigador.')),
    );
    return;
  }

  setState(() => _guardando = true);

  try {
    // Delegamos la creación de la UserCredential y la escritura en Firestore al controlador
    bool registroExitoso = await _controladorUsuario.registrarUsuario(
      nombre: _nombreController.text.trim(),
      correo: _emailController.text.trim(),
      clave: _passwordController.text.trim(),
      rol: _rolSeleccionado,
      institucion: _institucionController.text.trim(), 
    );

    if (registroExitoso) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Investigador registrado correctamente en el sistema!')),
      );
      
      // Limpiamos los campos específicos de registro para dejar el formulario listo
      _nombreController.clear();
      _rolController.clear();
      _institucionController.clear();
      
      // Opcional: regresar a la vista de login tras registrar exitosamente
      setState(() => _esLogin = true);
    } else {
      throw Exception('El controlador no pudo completar el registro.');
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error al registrar usuario: $e')),
    );
  } finally {
    setState(() => _guardando = false);
  }
}

  void _procesarLogin() async {
  setState(() => _guardando = true);

  try {
    // Invocamos al método de autenticación del controlador
    // Recuerda que este método debe llamar internamente a: FirebaseAuth.instance.signInWithEmailAndPassword
    bool loginExitoso = await _controladorUsuario.iniciarSesion(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );

    if (loginExitoso) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Bienvenido al sistema! Acceso concedido.')),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const MyHomePage(title: 'Sistema de Gestión Petroglifos'),
        ),
      );
    } else {
      throw Exception('Credenciales incorrectas o usuario no registrado.');
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error al iniciar sesión: $e')),
    );
  } finally {
    setState(() => _guardando = false);
  }
}

  void _procesarAutenticacion() {
  // Validaciones rápidas antes de disparar Firebase
  if (_emailController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Por favor, rellena el correo y la contraseña.')),
    );
    return;
  }

  // Bifurcamos el flujo según la pantalla activa
  if (_esLogin) {
    _procesarLogin();
  } else {
    _procesarGuardadoUsuario();
  }
}

  Future<void> _verificarSiEsAdmin() async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return; // <--- Validación de seguridad
      setState(() {
        _esAdmin = false;
        _esLogin = true;
        _cargandoRol = false;
      });
      return;
    }

    // Esperamos la respuesta de la base de datos
    final usuarioAnclado = await _controladorUsuario.buscarUsuario(user.uid);

    if (!mounted) return; // <--- Doble seguridad después de un await pesado

    if (usuarioAnclado != null) {
      // Usamos .name si es un Enum, o lowercase directo si contiene texto
      final String rolStr = usuarioAnclado.rol.toString().toLowerCase();

      setState(() {
        // CORRECCIÓN: Validamos de forma flexible si contiene la palabra 'administrador' o 'admin'
        _esAdmin = rolStr.contains('administrador') || rolStr.contains('admin');
        
        // REGLA: Si es admin -> muestra registro (_esLogin = false)
        // Si NO es admin -> fuerza login (_esLogin = true)
        _esLogin = !_esAdmin; 
      });
    } else {
      setState(() {
        _esAdmin = false;
        _esLogin = true;
      });
    }
  } catch (e) {
    print('Error al verificar privilegios de administrador: $e');
  } finally {
    // El bloque finally siempre se ejecuta, también necesita protección
    if (mounted) {
      setState(() => _cargandoRol = false);
    }
  }
}

  void _cargarUsuario(Usuario usuario) {

  _nombreController.text = usuario.nombre;

  _emailController.text = usuario.correo;

  _passwordController.text = usuario.clave;

  _institucionController.text = usuario.institucion;

  _rolSeleccionado = usuario.rol;
}

  Future<void> _procesarEdicionUsuario() async {

  final usuarioActualizado = Usuario(
    id: widget.usuarioEditar!.id,

    nombre: _nombreController.text.trim(),

    correo: _emailController.text.trim(),

    clave:  _passwordController.text.trim(),

    institucion: _institucionController.text.trim(),

    rol: _rolSeleccionado,

    // cualquier otro atributo que ya tenga tu modelo
  );

  final exito = await _controladorUsuario.actualizarUsuario(
    usuario: usuarioActualizado,
  );

  if (!mounted) return;

  if (exito) {

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Usuario actualizado correctamente.'),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.pop(context);

  } else {

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ocurrió un error al actualizar el usuario.'),
        backgroundColor: Colors.red,
      ),
    );

  }
}

  //=========================================================================
  //funciones de bitacoras
  //=========================================================================
  Future<void> _seleccionarFechaHoraBitacora(BuildContext context, bool esInicio) async {
    final DateTime? fechaPicked = await showDatePicker(
      context: context,
      initialDate: esInicio ? _fechaInicioBitacora : _fechaFinBitacora,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (fechaPicked != null) {
      final TimeOfDay? horaPicked = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(esInicio ? _fechaInicioBitacora : _fechaFinBitacora),
      );
      if (horaPicked != null) {
        setState(() {
          final DateTime fechaCompleta = DateTime(
            fechaPicked.year,
            fechaPicked.month,
            fechaPicked.day,
            horaPicked.hour,
            horaPicked.minute,
          );
          if (esInicio) {
            _fechaInicioBitacora = fechaCompleta;
          } else {
            _fechaFinBitacora = fechaCompleta;
          }
        });
      }
    }
  }

  void _procesarGuardadoBitacora() async {
  if (_actividadBitacoraController.text.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor, introduce la actividad.')));
    return;
  }

  List<String> participantesValidos = _participantesBitacora
      .where((id) => id != null)
      .cast<String>()
      .toList();

  if (participantesValidos.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Debe seleccionar al menos el participante obligatorio.')));
    return;
  }

  if (_fechaFinBitacora.isBefore(_fechaInicioBitacora)) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('La fecha de fin no puede ser anterior a la de inicio.')));
    return;
  }

  setState(() => _guardando = true);

  try {
    // 1. Generamos un ID único localmente si tu arquitectura lo requiere, 
    // o bien puedes usar un ID aleatorio compatible con tu base de datos.
    String nuevoIdBitacora = 'bit_${DateTime.now().millisecondsSinceEpoch}';

    // 2. LLAMADA CENTRALIZADA: Guardamos invocando al controlador de negocio
    bool guardadoExitoso = await _controladorNegocio.registrarBitacora(
      id: nuevoIdBitacora,
      fechaInicio: _fechaInicioBitacora,
      fechaFin: _fechaFinBitacora,
      idParticipantes: participantesValidos,
      actividad: _actividadBitacoraController.text,
      observaciones: _observacionesBitacoraController.text,
    );

    if (guardadoExitoso) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('¡Bitácora registrada con éxito!')));
      Navigator.pop(context);
    } else {
      throw Exception('El controlador no pudo persistir la bitácora.');
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al guardar bitácora: $e')));
  } finally {
    setState(() => _guardando = false);
  }
}

  Future<void> _procesarEdicionBitacora() async {
  
  final List<String> participantesActualizados = _participantesBitacora
      .where((id) => id != null)
      .cast<String>()
      .toList();

  final bitacoraActualizada = Bitacora(
    id: widget.bitacoraEditar!.id,
    fechaInicio: _fechaInicioBitacora!,
    fechaFin: _fechaFinBitacora!,
    actividad: _actividadBitacoraController.text.trim(),
    observaciones: _observacionesBitacoraController.text.trim(),
    idParticipantes: participantesActualizados,
  );

  final exito = await _controladorNegocio.actualizarBitacora(
    bitacora: bitacoraActualizada,
  );

  if (!mounted) return;

  if (exito) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Bitácora actualizada correctamente.'),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.pop(context);
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ocurrió un error al actualizar la bitácora.'),
        backgroundColor: Colors.red,
      ),
    );
  }
}
  void _cargarBitacora(Bitacora bitacora){

    _fechaInicioBitacora = bitacora.fechaInicio;

    _fechaFinBitacora = bitacora.fechaFin;

    _actividadBitacoraController.text =
        bitacora.actividad;

    _observacionesBitacoraController.text =
        bitacora.observaciones;

    _participantesBitacora =
        List<String?>.from(bitacora.idParticipantes);
}
  //=========================================================================
  //funciones de reporte
  //=========================================================================
  Future<void> _seleccionarFechaReporte(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _rangoFechaReporte,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _rangoFechaReporte) {
      setState(() {
        _rangoFechaReporte = picked;
      });
    }
  }

  void _procesarGuardadoReporteTecnico() async {
  setState(() {
    _guardando = true;
    _buscandoBitacoras = true;
  });

  try {
    // 1. Buscamos las bitácoras por fecha límite usando el controlador de negocio
    final bitacorasFiltradas = await _controladorNegocio.obtenerBitacorasPorFecha(_rangoFechaReporte);
    
    // Extraemos únicamente los IDs en una lista de Strings
    List<String> idsBitacorasEncontradas = bitacorasFiltradas.map((b) => b.id).toList();

    if (idsBitacorasEncontradas.isEmpty) {
      setState(() {
        _guardando = false;
        _buscandoBitacoras = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se encontraron bitácoras iniciadas en o antes de la fecha seleccionada. RECHAZADO.')),
      );
      return;
    }

    setState(() => _buscandoBitacoras = false);
    String nuevoIdReporte = 'rep_${DateTime.now().millisecondsSinceEpoch}';


    bool guardadoExitoso = await _controladorNegocio.registrarReporte(
      id: nuevoIdReporte,
      fechaGeneracion: DateTime.now(),
      rangoFecha: _rangoFechaReporte,
      idBitacoras: idsBitacorasEncontradas,
    );

    if (guardadoExitoso) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('¡Reporte generado con éxito! Vinculadas ${idsBitacorasEncontradas.length} bitácoras.')),
      );
      Navigator.pop(context);
    } else {
      throw Exception('El controlador no pudo guardar el documento.');
    }

  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error al generar Reporte Técnico: $e')),
    );
  } finally {
    setState(() {
      _guardando = false;
      _buscandoBitacoras = false;
    });
  }
}

  //=========================================================================
  //funciones sugerencias
  //=========================================================================
  void _procesarGuardadoSugerencia() async {
    if (_descripcionSugerenciaController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, ingrese una descripción para la sugerencia.')),
      );
      return;
    }

    setState(() => _guardando = true);

    // Generamos un ID único simple basado en el timestamp actual
    String idUnico = "SUG-${DateTime.now().millisecondsSinceEpoch}";

    bool exito = await _controladorSugerencia.registrarSugerencia(
      id: idUnico,
      descripcion: _descripcionSugerenciaController.text,
      fecha: DateTime.now(), // Fecha actual del envío
      estado: false,         // Por defecto inicia como falsa/pendiente de revisión
    );

    setState(() => _guardando = false);

    if (exito) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Sugerencia registrada con éxito! Gracias por su aporte.')),
      );
      _descripcionSugerenciaController.clear(); // Limpiamos el buffer
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hubo un error al guardar la sugerencia.')),
      );
    }
  }
  //=========================================================================
  //formularios 
  //=========================================================================

  Widget _construirFormularioPetroglifo() {
    bool esWindows = defaultTargetPlatform == TargetPlatform.windows;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StreamBuilder<List<Sitio>>(
          stream: _sitiosStream,
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const LinearProgressIndicator();
            return DropdownButtonFormField<Sitio>(
              value: _sitioSeleccionado,
              hint: const Text('Seleccionar Sitio Destino *'),
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: (snapshot.data ?? []).map((sitio) {
                return DropdownMenuItem<Sitio>(value: sitio, child: Text(sitio.nombre));
              }).toList(),
              onChanged: (val) => setState(() => _sitioSeleccionado = val),
            );
          },
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _nombrePetroglifoController,
          decoration: const InputDecoration(labelText: 'Nombre del Petroglifo *', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 28),
        const Row(
          children: [
            Icon(Icons.analytics_outlined, color: Colors.brown),
            SizedBox(width: 8),
            Text('Ficha Técnica Arqueológica', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.brown)),
          ],
        ),
        const Divider(color: Colors.brown, thickness: 1.2),
        const SizedBox(height: 10),
        TextField(
          controller: _descripcionFichaController,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Descripción de Símbolos / Observaciones *', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<MotivoPetroglifo>(
          value: _motivoSeleccionado,
          decoration: const InputDecoration(labelText: 'Motivo del Grabado', border: OutlineInputBorder()),
          items: MotivoPetroglifo.values.map((motivo) {
            return DropdownMenuItem(value: motivo, child: Text(motivo.name.toUpperCase()));
          }).toList(),
          onChanged: (val) => setState(() => _motivoSeleccionado = val!),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<TecnicaGrabado>(
          value: _tecnicaSeleccionada,
          decoration: const InputDecoration(labelText: 'Técnica de Manufactura', border: OutlineInputBorder()),
          items: TecnicaGrabado.values.map((tecnica) {
            return DropdownMenuItem(value: tecnica, child: Text(tecnica.name.toUpperCase()));
          }).toList(),
          onChanged: (val) => setState(() => _tecnicaSeleccionada = val!),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<TipoRoca>(
          value: _rocaSeleccionada,
          decoration: const InputDecoration(labelText: 'Tipo de Roca / Soporte', border: OutlineInputBorder()),
          items: TipoRoca.values.map((roca) {
            return DropdownMenuItem(value: roca, child: Text(roca.name.toUpperCase()));
          }).toList(),
          onChanged: (val) => setState(() => _rocaSeleccionada = val!),
        ),
        const SizedBox(height: 20),
        Text('Fotografías (* Presione miniatura para definir principal)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.brown)),
        const SizedBox(height: 8),
        Container(
          height: 120,
          decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
          child: _fotosVisualizables.isEmpty
              ? const Center(child: Text('Sin fotos capturadas o importadas.'))
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _fotosVisualizables.length,
                  itemBuilder: (context, idx) {
                    bool esPrincipal = idx == _indiceImagenPrincipal;
                    final archivoFoto = _fotosVisualizables[idx];
                    return GestureDetector(
                      onTap: () => setState(() => _indiceImagenPrincipal = idx),
                      child: Container(
                        margin: const EdgeInsets.all(8.0),
                        width: 100,
                        decoration: BoxDecoration(
                          border: Border.all(color: esPrincipal ? Colors.green : Colors.transparent, width: 3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            archivoFoto.bytes != null
                                ? Image.memory(archivoFoto.bytes!, fit: BoxFit.cover)
                                : (archivoFoto.path != null 
                                    ? Image.file(File(archivoFoto.path!), fit: BoxFit.cover)
                                    : const Icon(Icons.broken_image)),
                            if (esPrincipal)
                              const Positioned(
                                top: 4, right: 4,
                                child: CircleAvatar(backgroundColor: Colors.green, radius: 10, child: Icon(Icons.check, size: 12, color: Colors.white)),
                              )
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        const SizedBox(height: 8),
        if (!esWindows) ...[
          ElevatedButton.icon(
            onPressed: _tomarFoto,
            icon: const Icon(Icons.camera_alt_rounded),
            label: const Text('Tomar Fotografía de Campo'),
          ),
          const SizedBox(height: 12),
        ],
        ..._archivosMultimedia.map((file) => Card(
              child: ListTile(
                leading: const Icon(Icons.insert_drive_file_rounded),
                title: Text(file.name),
                subtitle: Text('${(file.size / 1024).toStringAsFixed(2)} KB'),
              ),
            )),
        ElevatedButton.icon(
          onPressed: _seleccionarArchivosExtra,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade200, foregroundColor: Colors.black87),
          icon: Icon(esWindows ? Icons.add_photo_alternate_rounded : Icons.attach_file_rounded),
          label: Text(esWindows ? 'Buscar Fotos en el Equipo' : 'Adjuntar Documentos/Audios'),
        ),
        const SizedBox(height: 40),
        _guardando
            ? const Center(child: CircularProgressIndicator())
            : ElevatedButton(
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16), backgroundColor: Colors.brown, foregroundColor: Colors.white),
                onPressed: _procesarGuardadoPetroglifo,
                child: const Text('Registrar Petroglifo', style: TextStyle(fontSize: 16)),
              ),
      ],
    );
  }

  Widget _construirFormularioSitio() {
    final double width = MediaQuery.of(context).size.width;
    final double paddingHorizontal = width > 600 ? width * 0.15 : 0.0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: paddingHorizontal),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _nombreSitioController,
            decoration: const InputDecoration(labelText: 'Nombre del Sitio *', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _codigoSitioController,
            decoration: const InputDecoration(labelText: 'Código Interno (Ej: ST-01) *', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _comunaSitioController,
            decoration: const InputDecoration(labelText: 'Comuna', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descripcionSitioController,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Descripción del Entorno', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<EstadoAcceso>(
            value: _accesoSeleccionado,
            decoration: const InputDecoration(labelText: 'Estado de Acceso', border: OutlineInputBorder()),
            items: EstadoAcceso.values.map((estado) => DropdownMenuItem(value: estado, child: Text(estado.name))).toList(),
            onChanged: (val) => setState(() => _accesoSeleccionado = val!),
          ),
          const SizedBox(height: 20),
          Card(
            color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.4),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    _latitud != null && _longitud != null ? 'Coordenadas: ($_latitud, $_longitud)' : 'Ubicación Satelital no capturada *',
                    style: TextStyle(fontWeight: FontWeight.bold, color: _latitud != null ? Colors.green : Colors.red),
                  ),
                  const SizedBox(height: 12),
                  _obteniendoGps
                      ? const CircularProgressIndicator()
                      : ElevatedButton.icon(
                          icon: const Icon(Icons.location_searching_rounded),
                          label: const Text('Obtener Coordenadas GPS'),
                          onPressed: _obtenerCoordenadasGps,
                        ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),
          _guardando
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton(
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
                  onPressed: _modoEdicionSitio
                      ? _procesarEdicionSitio
                      : _procesarGuardadoSitio,
                  child: const Text('Guardar Sitio Arqueológico', style: TextStyle(fontSize: 16)),
                ),
        ],
      ),
    );
  }

  Widget _construirFormularioBitacora() {
    return StreamBuilder<List<Usuario>>(
      stream: _controladorUsuario.listarUsuarios(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No hay usuarios registrados en el sistema para asignar.'));
        }

        List<Usuario> listaUsuarios = snapshot.data!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              title: const Text('Fecha/Hora Inicio'),
              subtitle: Text(_fechaInicioBitacora.toString().substring(0, 16)),
              trailing: const Icon(Icons.calendar_today_rounded),
              onTap: () => _seleccionarFechaHoraBitacora(context, true),
            ),
            ListTile(
              title: const Text('Fecha/Hora Fin'),
              subtitle: Text(_fechaFinBitacora.toString().substring(0, 16)),
              trailing: const Icon(Icons.calendar_today_rounded),
              onTap: () => _seleccionarFechaHoraBitacora(context, false),
            ),
            const SizedBox(height: 16),
            const Text(
              'Participantes del Proyecto',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 8),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _participantesBitacora.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _participantesBitacora[index],
                          decoration: InputDecoration(
                            labelText: index == 0 ? 'Participante Obligatorio *' : 'Participante Adicional',
                            border: const OutlineInputBorder(),
                          ),
                          items: listaUsuarios.map((user) {
                            return DropdownMenuItem<String>(
                              value: user.id,
                              child: Text(user.nombre),
                            );
                          }).toList(),
                          onChanged: (String? nuevoId) {
                            setState(() => _participantesBitacora[index] = nuevoId);
                          },
                        ),
                      ),
                      if (index > 0)
                        IconButton(
                          icon: const Icon(Icons.remove_circle, color: Colors.red),
                          onPressed: () {
                            setState(() => _participantesBitacora.removeAt(index));
                          },
                        )
                    ],
                  ),
                );
              },
            ),

            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Agregar Participante'),
                onPressed: () {
                  setState(() => _participantesBitacora.add(null));
                },
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _actividadBitacoraController,
              decoration: const InputDecoration(labelText: 'Actividad Realizada *', border: OutlineInputBorder()),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _observacionesBitacoraController,
              decoration: const InputDecoration(labelText: 'Observaciones', border: OutlineInputBorder()),
              maxLines: 3,
            ),
            const SizedBox(height: 30),
            _guardando
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16), 
                      backgroundColor: Colors.teal, 
                      foregroundColor: Colors.white
                    ),
                    onPressed: _modoEdicionBitacora? _procesarEdicionBitacora: _procesarGuardadoBitacora,
                    child: const Text('Guardar Bitácora', style: TextStyle(fontSize: 16)),
                  ),
          ],
        );
      },
    );
  }

  Widget _construirFormularioReporteTecnico() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Generación Automatizada de Reporte Técnico',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.indigo),
        ),
        const SizedBox(height: 8),
        const Text(
          'El sistema recopilará automáticamente todas las bitácoras cuya fecha de inicio sea anterior o igual al límite seleccionado.',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 20),
        Card(
          elevation: 2,
          child: ListTile(
            leading: const Icon(Icons.date_range_rounded, color: Colors.indigo),
            title: const Text('Fecha Límite de Búsqueda (≤)'),
            subtitle: Text(
              "${_rangoFechaReporte.day}/${_rangoFechaReporte.month}/${_rangoFechaReporte.year}",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            trailing: const Icon(Icons.edit),
            onTap: () => _seleccionarFechaReporte(context),
          ),
        ),
        const SizedBox(height: 40),
        _guardando
            ? Column(
                children: [
                  const CircularProgressIndicator(color: Colors.indigo),
                  const SizedBox(height: 12),
                  Text(
                    _buscandoBitacoras ? 'Consultando bitácoras en Firestore...' : 'Escribiendo reporte...',
                    style: const TextStyle(fontStyle: FontStyle.italic),
                  )
                ],
              )
            : ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.assignment_turned_in_rounded),
                onPressed: 
                 _procesarGuardadoReporteTecnico,
                label: const Text('Compilar y Registrar Reporte', style: TextStyle(fontSize: 16)),
              ),
      ],
    );
  }

  Widget _construirFormularioAutenticacion() {
  // Instancia del controlador de usuario (asegúrate de tenerla definida o impórtala)
  final ControladorUsuario _controladorUsuario = ControladorUsuario();

  if (_cargandoRol) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24.0),
        child: CircularProgressIndicator(color: Colors.indigo),
      ),
    );
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        _esLogin ? 'Acceso al Sistema' : 'Registro de Nuevo Investigador',
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.indigo),
      ),
      const SizedBox(height: 8),
      Text(
        _esLogin 
            ? 'Introduce tus credenciales institucionales para acceder.' 
            : 'Completa todos los campos para dar de alta un nuevo perfil arqueológico en el sistema.',
        style: const TextStyle(color: Colors.grey),
      ),
      const SizedBox(height: 20),

      // ================= CAMPOS COMUNES =================
      Card(
        elevation: 2,
        margin: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: _emailController,
          decoration: const InputDecoration(
            labelText: 'Correo Electrónico',
            prefixIcon: Icon(Icons.email_rounded, color: Colors.indigo),
            border: InputBorder.none,
            contentPadding: EdgeInsets.all(16),
          ),
          keyboardType: TextInputType.emailAddress,
        ),
      ),
      Card(
        elevation: 2,
        margin: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: _passwordController,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Contraseña',
            prefixIcon: Icon(Icons.lock_rounded, color: Colors.indigo),
            border: InputBorder.none,
            contentPadding: EdgeInsets.all(16),
          ),
        ),
      ),
      
      // ================= CAMPOS DE REGISTRO =================
      if (!_esLogin) ...[
        Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          child: TextFormField(
            controller: _nombreController,
            decoration: const InputDecoration(
              labelText: 'Nombre Completo',
              prefixIcon: Icon(Icons.person_rounded, color: Colors.indigo),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(16),
            ),
          ),
        ),
        Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: DropdownButtonFormField<Rol>(
              value: _rolSeleccionado,
              decoration: const InputDecoration(
                labelText: 'Rol / Cargo del Usuario',
                prefixIcon: Icon(Icons.badge_rounded, color: Colors.indigo),
                border: InputBorder.none,
              ),
              items: const [
                DropdownMenuItem(
                  value: Rol.investigador, 
                  child: Text('Investigador / Arqueólogo'),
                ),
                DropdownMenuItem(
                  value: Rol.administrador, 
                  child: Text('Administrador de Sistema'),
                ),
              ],
              onChanged: (nuevoValor) {
                if (nuevoValor != null) {
                  setState(() {
                    _rolSeleccionado = nuevoValor;
                  });
                }
              },
            ),
          ),
        ),
        Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          child: TextFormField(
            controller: _institucionController,
            decoration: const InputDecoration(
              labelText: 'Institución / Universidad',
              prefixIcon: Icon(Icons.account_balance_rounded, color: Colors.indigo),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(16),
            ),
          ),
        ),
      ],

      const SizedBox(height: 40),

      // ================= BOTÓN PRINCIPAL / ESTADO DE CARGA =================
      _guardando
          ? Column(
              children: [
                const CircularProgressIndicator(color: Colors.indigo),
                const SizedBox(height: 12),
                Text(
                  _esLogin ? 'Iniciando sesión...' : 'Registrando credenciales en la base de datos...',
                  style: const TextStyle(fontStyle: FontStyle.italic),
                )
              ],
            )
          : ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
              ),
              icon: Icon(_esLogin ? Icons.login_rounded : Icons.person_add_alt_1_rounded),
              onPressed: widget.usuarioEditar != null? _procesarEdicionUsuario: _procesarGuardadoUsuario,
              label: Text(_esLogin ? 'Iniciar Sesión' : 'Registrar Investigador', style: const TextStyle(fontSize: 16)),
            ),

      const SizedBox(height: 16),

      // ================= ENLACE DINÁMICO (Conmuta Login/Registro) =================
      if (_esAdmin)
        TextButton(
          onPressed: () {
            setState(() {
              _esLogin = !_esLogin;
            });
          },
          child: Text(
            _esLogin ? '¿Eres Administrador? Registra un usuario aquí' : 'Volver al Inicio de Sesión',
            style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold),
          ),
        ),

      // ================= NUEVO: BOTÓN CERRAR SESIÓN =================
      // Si el usuario ya está autenticado (por ejemplo, en la vista de registro del administrador),
      // añadimos un botón secundario limpio para salir del sistema.
      if (!_esLogin || FirebaseAuth.instance.currentUser != null) ...[
        const Divider(height: 32), // Línea divisoria elegante
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.all(16),
            side: const BorderSide(color: Colors.redAccent),
            foregroundColor: Colors.redAccent,
          ),
          icon: const Icon(Icons.logout_rounded),
          label: const Text('Cerrar Sesión Activa', style: TextStyle(fontSize: 16)),
          onPressed: () async {
            // Mostrar un indicador de carga rápido en consola o UI si fuese necesario
            bool exito = await _controladorUsuario.cerrarSesion();
            if (exito && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Sesión cerrada correctamente.'),
                  backgroundColor: Colors.green,
                ),
              );
              // Forzamos el cambio visual a la pantalla de login por defecto si queda ahí pegado
              setState(() {
                _esLogin = true;
              });
            }
          },
        ),
      ],
    ],
  );
}

  Widget _construirFormularioSugerencia() {
    final double width = MediaQuery.of(context).size.width;
    final double paddingHorizontal = width > 600 ? width * 0.15 : 0.0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: paddingHorizontal),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Buzón de Sugerencias de descubrimiento',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Describa cualquier posible ubicación de petroglifo.',
            style: TextStyle(fontSize: 13, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _descripcionSugerenciaController,
            maxLines: 6,
            maxLength: 500,
            decoration: const InputDecoration(
              labelText: 'Descripción detallada de la sugerencia *',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
              hintText: 'Ej: En calabozos hay una piedra extraña con lo que parece ser pintura blanca',
            ),
          ),
          const SizedBox(height: 30),
          _guardando
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
                  icon: const Icon(Icons.send_rounded),
                  label: const Text('Enviar Sugerencia', style: TextStyle(fontSize: 16)),
                  onPressed: _procesarGuardadoSugerencia,
                ),
        ],
      ),
    );
  }

  //=========================================================================
  //selectro de titulo
  //=========================================================================
  String _obtenerTituloAppBar() {
    switch (widget.tipo) {
      case TipoRegistro.petroglifo: return 'Registrar Petroglifo';
      case TipoRegistro.sitio: return 'Registrar Sitio Arqueológico';
      case TipoRegistro.usuario: return 'Registrar Nuevo Usuario';
      case TipoRegistro.bitacora: return 'Nueva Entrada de Bitácora';
      case TipoRegistro.reporte: return 'Generar Reporte';
      case TipoRegistro.sugerencia: return 'Generar Sugenercia';
    }
  }

  //=========================================================================
  //selector de interfaz
  //=========================================================================
  Widget _seleccionarCuerpoFormulario() {
    switch (widget.tipo) {
      case TipoRegistro.petroglifo: return _construirFormularioPetroglifo();
      case TipoRegistro.sitio: return _construirFormularioSitio();
      case TipoRegistro.usuario: return _construirFormularioAutenticacion();
      case TipoRegistro.bitacora: return _construirFormularioBitacora();
      case TipoRegistro.reporte: return _construirFormularioReporteTecnico();
      case TipoRegistro.sugerencia: return _construirFormularioSugerencia();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_obtenerTituloAppBar())),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: _seleccionarCuerpoFormulario(),
      ),
    );
  }
}