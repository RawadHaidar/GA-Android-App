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
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AuthScreen(isSignUp: false),
                ),
              );
            },
            child: const Text('Sign In', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AuthScreen(isSignUp: true),
                ),
              );
            },
            child: const Text('Sign Up', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        // Wrap the body content in a scroll view
        child: Padding(
          padding:
              const EdgeInsets.all(16.0), // Optional padding around the content
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text('ML model output data below:'),
              ActivityMlDataWidget(),
              if (dataProvider.errorMessage != null)
                Text(
                  dataProvider.errorMessage!,
                  style: const TextStyle(
                      color: Colors.red, fontWeight: FontWeight.bold),
                )
            ],
          ),
        ),
      ),
    );
  }
}
