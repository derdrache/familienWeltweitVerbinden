import 'package:familien_suche/global/custom_widgets.dart';
import 'package:flutter/material.dart';


class PatchnotesWindow{
  var context;
  var patchnotesTitle = "Patchnotes";

  PatchnotesWindow({required this.context});


  _patch(patch){
    return Container(
      margin: EdgeInsets.only(top: 15, left: 10, right: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.max,
          children: [
            Text(
              patch["title"],
              style: TextStyle(
                fontSize: 15,
                  fontWeight: FontWeight.bold
              ),
            ),
            SizedBox(width: 10),
            SizedBox(
              width: 200,
              child: Text(
                patch["inhalt"],
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
          _patch(prePatch3),
          _patch(prePatch2),
          _patch(prePatch1),

          //_patch(patch1)
        ]
    );
  }

}

var prePatch1 = {
  "title": "0.9.3",
  "inhalt": "Anzeige von den Patchnotes und geplanten Erweiterungen angepasst"
};

var prePatch2 = {
  "title": "0.10.0",
  "inhalt": "Notification-System wurde eingebaut. Ab jetzt ist es auch möglich zu sehen wie viele ungelesene Chatnachrichten offen sind"
};

var prePatch3 = {
  "title": "0.10.1",
  "inhalt": "- Fehler bei der Freundesliste behoben \n - kritischer Datenbankfehler behoben"
};

var patch1 = {
  "title" : "1.0.0",
  "inhalt": "App veröffentlicht"
};

