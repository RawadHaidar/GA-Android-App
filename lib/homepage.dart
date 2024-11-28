import 'package:flutter/material.dart';
import 'package:kicare_ml_firebase_server1/activity_ml_data_widget.dart';
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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('ML model output data below:'),
            ActivityMlDataWidget(),
          ],
        ),
      ),
      floatingActionButton: Consumer<DataProvider>(
        builder: (context, dataProvider, child) {
          return FloatingActionButton(
            onPressed: () {
              if (dataProvider.isGenerating) {
                dataProvider.stopGeneratingData();
              } else {
                dataProvider.startGeneratingData();
              }
            },
            child: Icon(
                dataProvider.isGenerating ? Icons.pause : Icons.play_arrow),
          );
        },
      ),
    );
  }
}
