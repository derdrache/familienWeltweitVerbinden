import 'package:familien_suche/global/custom_widgets.dart';
import 'package:flutter/material.dart';


class PatchnotesWindow{
  var context;
  var patchnotesTitle = "Patchnotes";

  PatchnotesWindow({required this.context});


  _patch(title, inhalt){
    return Container(
      margin: EdgeInsets.only(top: 15, left: 10, right: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.max,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                  fontWeight: FontWeight.bold
              ),
            ),
            SizedBox(width: 10),
            SizedBox(
              width: 200,
              child: Text(
                inhalt,
                maxLines: null,
                style: TextStyle(fontSize: 15),
              ),
            )
          ]
        )
    );
  }

  openWindow(){
    return CustomWindow(
        context: context,
        title: patchnotesTitle,
        children: [
          _patch(patch1["title"], patch1["inhalt"])
        ]
    );
  }

}


var patch1 = {
  "title" : "1.0.0",
  "inhalt": "App veröffentlicht"
};

