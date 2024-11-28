import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:kicare_ml_firebase_server1/dataprovider.dart';
import 'package:kicare_ml_firebase_server1/homepage.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding
      .ensureInitialized(); // Ensures binding for async initialization
  await Firebase.initializeApp(); // Initialize Firebase
  runApp(
    // Wrap MyApp with ChangeNotifierProvider to provide DataProvider to the widget tree
    ChangeNotifierProvider(
      create: (context) => DataProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo GA App Server Home Page'),
    );
  }
}
