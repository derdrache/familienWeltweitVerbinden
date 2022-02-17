import 'package:familien_suche/global/custom_widgets.dart';
import 'package:flutter/material.dart';


class PatchnotesWindow{
  var context;
  var patchnotesTitle = "Patchnotes";

  PatchnotesWindow({required this.context});


  _patch(patch){
    List<Widget> patchList = [];

    for(var inhalt in patch["inhalt"]){
      print(inhalt);

      patchList.add(SizedBox(height: 10));
      patchList.add(Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("- "),
          Flexible(
              child: Text(inhalt,overflow: TextOverflow.visible,))
        ],
      ));
    }

    return Container(
      margin: EdgeInsets.only(top: 15, left: 10, right: 5, bottom: 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              patch["title"],
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold
              ),
            ),
            SizedBox(width: 10),
            ...patchList
          ],
        )
    );
  }

  openWindow(){
    return CustomWindow(
        context: context,
        title: patchnotesTitle,
        children: [

          _patch(patch101),
          _patch(patch1),
        ]
    );
  }

}

var patch110 = {
  "title": "1.1.0",
  "inhalt": [
    "Englische Version hinzugefügt - Die Sprache wird von der Handysprache übernommen",
  ]
};

var patch101 = {
  "title" : "1.0.1",
  "inhalt" : [
    "Notifications können unter Settings deaktiviert werden",
    "Die Familienübersicht bei klick auf einen Kartenpunkt wurde verändert",
    "Profil Änderungen unter Setting wurde angepasst",
    "Setting/Profil über mich hat mehr Platz bekommen",
    "Fehler bei Abmelden behoben",
    "Kartenfehler behoben: Manche Länder haben ein Fehler ausgelöst",
    "Allgemeine Codeverbesserungen"
  ]

};

var patch1 = {
  "title" : "1.0.0",
  "inhalt": ["App veröffentlicht"]
};




