import 'package:familien_suche/global/custom_widgets.dart';
import 'package:flutter/material.dart';

class AboutProject{
  var context;
  var title = "Über das Projekt";

  AboutProject({required this.context});


  openWindow(){
    return CustomWindow(
        context: context,
        title: title,
        children: [
          SizedBox(height: 10),
          Center(child: Text(inhalt))
        ]
    );
  }

}

var inhalt = "Diese App soll Familien, dir ihr Land verlassen haben, dabei helfen"
    " sich mit anderen Familien zu vernetzen und auszutauschen. ";