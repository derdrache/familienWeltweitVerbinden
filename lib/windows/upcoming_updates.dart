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
          _update("IOS Version / Web Version"),
          _update("Mehrere Accounts verbinden"),
          _update("Automatischer Standort"),
          _update("Nutzer blockieren"),
          _update("Events planen"),
          _update("Reiseplanung"),
          _update("Gemeinschaften Eintragen"),
          _update("Freunde auf Karte farblich markieren"),
          _update("Chatgruppen"),
          _update("Eventboard"),
          _update("Anonyme Anmelden"),
          _update("Chat erweiterungen"),
          _update("Account löschen"),
          _update("Layout verbessern"),
        ]
    );
  }

}