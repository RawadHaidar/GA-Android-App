import 'package:flutter/material.dart';
import 'package:kicare_ml_firebase_server1/activity_ml_data_widget.dart';
import 'package:kicare_ml_firebase_server1/authScreen.dart';
import 'package:kicare_ml_firebase_server1/dataprovider.dart';
import 'package:provider/provider.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    final dataProvider = Provider.of<DataProvider>(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AuthScreen(isSignUp: false),
                ),
              );
            },
            icon: const Icon(Icons.login, color: Colors.white),
            label: const Text('Sign In', style: TextStyle(color: Colors.white)),
          ),
          TextButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AuthScreen(isSignUp: true),
                ),
              );
            },
            icon: const Icon(Icons.person_add, color: Colors.white),
            label: const Text('Sign Up', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'ML Device Data Output',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Displaying real-time data fetched from the device at the specified IP address.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[700],
                    ),
              ),
              const SizedBox(height: 16),
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                child: Container(
                  // height: 1000,
                  width: double.infinity,
                  padding: const EdgeInsets.all(16.0),
                  child: ActivityMlDataWidget(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
