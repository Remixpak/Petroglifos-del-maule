import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:software_petroglifos/pages/homePage.dart';

void main() async {
  // 3. Asegura que los canales de comunicación nativos de Flutter estén listos
  WidgetsFlutterBinding.ensureInitialized();

  // 4. Inicializa Firebase con las opciones de configuración de tu proyecto
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 5. Arranca la aplicación normalmente
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Software Petroglifos',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Gestión Arqueológica'),
    );
  }
}