import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:kicare_ml_firebase_server1/dataprovider.dart';
import 'package:kicare_ml_firebase_server1/pages/homepage.dart';
import 'package:kicare_ml_firebase_server1/pages/auth_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
      title: 'Kicare App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      // Use StreamBuilder to determine the home screen based on authentication state
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // Check if the user is logged in
          if (snapshot.connectionState == ConnectionState.active) {
            final user = snapshot.data;
            if (user != null) {
              return const MyHomePage(
                  title: 'Demo Kicare App: Server Home Page');
            } else {
              return const AuthScreen(
                  isSignUp: false); // Redirect to sign-in screen
            }
          }

          // Show loading spinner while waiting for connection
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        },
      ),
    );
  }
}
