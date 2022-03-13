import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:familien_suche/global/custom_widgets.dart';
import 'package:flutter/material.dart';



class PatchnotesWindow{
  var context;
  var patchnotesTitle = "Patchnotes";
  var isGerman = kIsWeb ? window.locale.languageCode == "de" : Platform.localeName == "de_DE";

  PatchnotesWindow({this.context});


  _patch(patch){
    List<Widget> patchList = [];

    for(var inhalt in patch["inhalt"]){
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
        children:

        isGerman ? [
          _patch(patch113D),
          _patch(patch112D),
          _patch(patch111D),
          _patch(patch110D),
          _patch(patch101D),
          _patch(patch1D),
        ] :
        [
          _patch(patch113E),
          _patch(patch112E),
          _patch(patch111E),
          _patch(patch110E),
          _patch(patch101E),
          _patch(patch1E),
        ]
    );
  }

}

var patch113E= {
  "title": "1.1.3",
  "inhalt": [
    "The age query from the children now only asks for the year",
    "Notification work on Android again",
    "Map - On the lowest zoom level the countries are summarized for a better overview. It will be improved with a later update.",
    "Map - One's location is shown on the map with a flag",
    "Map Filter - Filter has been limited to 3",
    "Map Filter - It is possible to filter by country",
    "Chat - User search for new chat now works with autocomplete",
    "Location input - Input now works with autocomplete",
    "Label change - 'city' => 'town'",
    "Web - Autologin set",
    "Web - Map is properly updated when using the mouse wheel",
    "Web - Tab icon added",
    "The length from the username was limited to 40 characters",
    "The map back zoom button now goes back in single steps",
    "The apostrophe can now be used in the user name",
    "When entering the location, there is now a ! for more information",
    "Login/Registration - The bug with the space before and after the email has been fixed",
    "various small changes",
    "various small bug fixes"
  ]
};
var patch113D= {
  "title": "1.1.3",
  "inhalt": [
    "Bei der Altersabfrage von den Kindern wird nur noch das Jahr abgefragt",
    "Notification funktionieren auf Android wieder",
    "Karte - Auf der niedrigsten Zoomstufe werden die Länder zur besseren Übersicht zusammengefasst. Mit einem späteren Update wird es noch verbessert.",
    "Karte - Der eigene Standort wird auf der Karte mit einer Fahne angezeigt",
    "Karte Filter - Filter wurde auf 3 beschränkt",
    "Karte Filter - Es kann nach Ländern gefiltert werden",
    "Chat - Benutzersuche für neuen Chat funktioniert jetzt mit Autocomplete",
    "Ort Eingabe - Die Eingabe funktioniert jetzt mit Autocomplete",
    "Bezeichnungsänderung - 'Stadt' => 'Ort'",
    "Web - Autologin eingestellt",
    "Web - Die Karte wird bei der Benutzung des Mausrads ordentlich upgedatet",
    "Web - Tab Icon eingebaut",
    "Die Länge vom Benutzernamen wurde auf 40 Zeichen beschränkt",
    "Der Karten Zurück-Zoom-Button geht jetzt in einzelnen Schritten zurück",
    "Beim Benutzernmen kann jetzt auch das Apostroph benutzt werden",
    "Bei der Eingabe vom Ort gibt es jetzt ein ! für mehr Information",
    "Login/Registrierung - Der Fehler mit dem Leerzeichen vor und nach der Email wurde behoben",
    "verschiedene kleine Änderungen",
    "verschiedene kleine Fehlerbehebungen"
  ]
};


var patch112E= {
  "title": "1.1.2",
  "inhalt": [
    "final preparations for release"
]
};
var patch112D= {
  "title": "1.1.2",
  "inhalt": [
    "letzte Vorbereitungen für die Veröffentlichung"
  ]
};


var patch111E={
  "title": "1.1.1",
  "inhalt": [
    "Adjustments for the web version",
    "Added travel type 'Car/Accommodations'",
    "Added interest 'Worldschooling'",
    "The map now has a full zoom out button",
    "Clicking on a map marker automatically zooms in to the next level",
    "Contact opportunity is only displayed if the user has shared an opportunity",
    "various translation errors have been fixed",
    "various small bugs have been fixed"
  ]
};
var patch111D = {
  "title": "1.1.1",
  "inhalt": [
    "Anpassungen für die Web Version",
    "Reiseart 'Auto/Unterkünfte' hinzugefügt",
    "Interesse 'Worldschooling' hinzugefügt",
    "Die Karte hat jetzt einen komplett Raus-Zoom-Button",
    "Beim Klick auf eine Karten Markierung wird in automatisch in die nächste Ebene reingezoomt",
    "Kontakt-Möglichkeit wird nur angezeigt, wenn der Benutzer eine Möglichkeit freigegeben hat",
    "verschiedene Übersetzungsfehler wurden behoben",
    "verschiedene kleine Fehler wurden behoben",
  ]
};

var patch110E = {
  "title": "1.1.0",
  "inhalt": [
    "Added English version - The language will be taken from the mobile language",
    "Age of children is only queried with month/year",
    "The map's search bar has been revised, users can now also be searched for",
    "When tapping on the chat notification, the chat now opens",
    "When chatting with a person, the profile of the respective person can now be opened by tapping on the name",
    "Message input field now enlarges automatically",
    "Map rotation is no longer possible",
    "Add/remove friend now has a confirmation message",
    "Under Settings there is now a button for the profile preview",
    "When opening a new chat group, the display of the friends list has been revised",
    "New layout: Login",
    "Bug fixed: In the chat you can scroll again",
    "Various small bugs and adjustments"
  ]
};
var patch110D = {
  "title": "1.1.0",
  "inhalt": [
    "Englische Version hinzugefügt - Die Sprache wird von der Handysprache übernommen",
    "Alter der Kinder wird nur noch mit Monat/Jahr abgefragt",
    "Suchleiste der Karte wurde überarbeitet, es können jetzt auch User gesucht werden",
    "Beim Antippen der Chatnotification, öffnet sich nun der Chat",
    "Beim Chat mit einer Person kann nun das Profil der jeweiligen Person durch ein antippen auf den Namen geöffnet werden",
    "Nachricht Eingabefeld vergrößert sich nun automatisch",
    "Drehung der Karte ist nicht mehr möglich",
    "Bei Freund hinzufügen/entfernen gibt es jetzt eine Bestätigungsmeldung",
    "Unter Settings gibt es nun ein Button für die Profil Vorschau",
    "Bei neuer Chatgruppe eröffnen wurde die Anzeige der Freundesliste überarbeitet",
    "Neues Layout: Login",
    "Fehler behoben: Im Chat kann wieder gescrollt werden",
    "Verschiedene kleine Fehler und Anpassungen"
  ]
};

var patch101E = {
  "title" : "1.0.1",
  "inhalt" : [
    "Notifications can be disabled under Settings",
    "The family overview when clicking on a map point has been changed",
    "Profile changes under Setting has been adjusted",
    "Setting/profile about me got more space",
    "Fixed logout bug",
    "Fixed map bug: some countries were throwing an error",
    "General code improvements"
  ]

};
var patch101D = {
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

var patch1E = {
  "title" : "1.0.0",
  "inhalt": ["App released"]
};
var patch1D = {
  "title" : "1.0.0",
  "inhalt": ["App veröffentlicht"]
};




