import 'package:flutter/material.dart';

import '../global/custom_widgets.dart';

class UmcomingUpdatesWindow{
  var context;
  var patchnotesTitle = "Geplante Updates";

  UmcomingUpdatesWindow({this.context});


  _update(title){
    return Container(
      width: 200,
      margin: EdgeInsets.only(left: 10, top: 10),
      child: Text(
        "- " + title,
        style: TextStyle(fontSize: 15),
        maxLines: null,
      )
    );
  }

  openWindow(){
    return CustomWindow(
        context: context,
        title: patchnotesTitle,
        children: [
          _update("Englische Version"),
          _update("IOS Version"),
          _update("Account löschen"),
          _update("Automatischer Standort"),
          _update("Anonyme Anmelden"),
          _update("Events eintragen"),
          _update("Gemeinschaften Eintragen"),
          _update("Layout verbessern"),
          _update("Freunde auf Karte farblich markieren"),
          _update("Mehrere Accounts verbinden"),
          _update("Chat erweiterungen"),
          _update("Chatgruppen"),
          _update("Eventboard"),
        ]
    );
  }

}