import 'package:familien_suche/windows/about_project.dart';
import 'package:flutter/material.dart';

class BoardPage extends StatefulWidget{
  _BoardPageState createState() => _BoardPageState();
}

class _BoardPageState extends State<BoardPage>{


  Widget build(BuildContext context){
    return Scaffold(
      body: FloatingActionButton(
        onPressed: AboutProject(context: context).openWindow(),
      )

      );
  }
}
