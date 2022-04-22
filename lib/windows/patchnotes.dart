import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../widgets/dialogWindow.dart';



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
    showDialog(
        context: context,
        builder: (BuildContext buildContext){
          return CustomAlertDialog(
              title: patchnotesTitle,
              children:

              isGerman ? [
                _patch(patch122D),
                _patch(patch121D),
                _patch(patch120D),
                _patch(patch113D),
                _patch(patch112D),
                _patch(patch111D),
                _patch(patch110D),
                _patch(patch101D),
                _patch(patch1D),
              ] :
              [
                _patch(patch122E),
                _patch(patch121E),
                _patch(patch120E),
                _patch(patch113E),
                _patch(patch112E),
                _patch(patch111E),
                _patch(patch110E),
                _patch(patch101E),
                _patch(patch1E),
              ]
          );
        });

  }

}

var patchVorlage={
  "title" : "",
  "inhalt": [

  ]
};

var patch122E={
  "title" : "1.2.2",
  "inhalt": [
    "General - profile pictures have been inserted. A link from any picture can be inserted under Settings.",
    "General - A serious security vulnerability has been closed",
    "General - Speed of the app has been further improved",
    "General - A 'no internet' indicator has been added",
    "World Map - Countries have been grouped together more at the lowest zoom level",
    "World Map - The size of the menu can now be resized as desired",
    "Chats - The message input box now adapts to the text",
    "Events - It is now possible to create multi-day events",
    "Events - The time zone selection bug has been fixed",
    "Profile - More languages are available for selection ( Does not change the display language of the app)",
    "Profile inactive - If inactive for more than a month, a "
        "Location-still-updated notification will be sent(exception are users with "
        "of the travel type 'Fixed location'. After 3 months the profile will be "
        "will be visible to others as inactive. After 6 months the profile "
        "will no longer be displayed on the world map.\n\nThe inactive counter will be reset with the "
        "visit in the app is reset.",
    "Profile - The hint text of 'about us' was adjusted.",
    "various small improvements were added",
    "various small bugs have been fixed",
  ]
};
var patch122D={
  "title" : "1.2.2",
  "inhalt": [
    "Allgemein - Profilbilder wurden eingefügt. Unter Settings kann ein Link von einem beliebigen Bild eingefügt werden.",
    "Allgemein - Es wurde eine schwere Sicherheitslücke geschlossen",
    "Allgemein - Geschwindigkeit der App wurde weiter verbessert",
    "Allgemein - Es wurde eine 'Kein-Internet'- Anzeige eingebaut",
    "Weltkarte - Länder wurden auf der niedrigsten Zoomstufe stärker zusammengefasst",
    "Weltkarte - Die Größe des Menüs kann jetzt nach belieben verändert werden",
    "Chats - Die Nachrichten Eingabebox passt sich jetzt dem Text an",
    "Events - Es ist jetzt auch möglich mehrtägige Events zu erstellen",
    "Events - Der Fehler bei der Auswahl der Zeitzone wurde behoben",
    "Profil - Es stehen mehr Sprachen zur Auswahl zur Verfügung ( Verändert nichts an der Anzeigesprache der App)",
    "Profil inaktiv - Bei einer Inaktivität von mehr als einen Monat, wird eine "
        "Standort-noch-aktuell Notification versendet(Ausnahme sind Benutzer mit "
        "der Reise Art 'Fester Standort'. Ab 3 Monaten wird das Profil für "
        "andere sichtbar als inaktiv angezeigt. Ab 6 Monaten wird das Profil "
        "nicht mehr auf der Weltkarte angezeigt.\n\nDer Inaktivzähler wird mit dem "
        "Besuch in der App zurück gesetzt.",
    "Profil - Der Hinttext von 'über uns' wurde angepasst.",
    "verschiedene kleine Verbesserungen wurden hinzugefügt",
    "verschiedene kleine Fehler wurden behoben",
  ]
};

var patch121E={
  "title" : "1.2.1",
  "inhalt": [
    "Bug fixes from patch 1.2.0"
  ]
};
var patch121D={
  "title" : "1.2.1",
  "inhalt": [
    "Fehlerbehebungen aus Patch 1.2.0"
  ]
};


var patch120E={
  "title" : "1.2.0",
  "inhalt": [
    "General - Events have been implemented",
    "General - App speed greatly improved",
    "Web Version - Email Notification has been implemented",
    "Web Version - Bug fixes under some browsers (e.g. Safari)",
    "Login / Registration - When creating a profile, there is now the possibility to enter 'About us' directly",
    "World map - The information menu got a new layout",
    "World Map - Improvement of the zoom out button",
    "World Map - The number on the markers has been limited to 99",
    "Chat - Fixed the display of the wrong time",
    "Settings - Donation link should now work again on Android version 10+",
    "Settings - The app version can now be displayed in the app (Settings => About)",
    "various small changes",
    "various small bugs have been fixed",
  ]
};

var patch120D={
  "title" : "1.2.0",
  "inhalt": [
    "Allgemein - Events wurden eingebaut",
    "Allgemein - Geschwindigkeit der App stark verbessert",
    "Web Version - Email Notification wurde eingebaut",
    "Web Version - Fehlerbehebung unter manchen Browsern (z.B. Safari)",
    "Login / Registrierung - Beim Profil erstellen gibt es jetzt die Möglichkeit direkt 'Über uns' einzutragen",
    "Login / Registrierung - Google Login wurde hinzugefügt",
    "Weltkarte - Das Informationsmenu hat ein neues Layout bekommen",
    "Weltkarte - Verbesserung des Raus-Zoom-Buttons",
    "Weltkarte - Die Nummer auf den Markierungen wurde auf 99 beschränkt",
    "Chat - Die Anzeige der falschen Uhrzeit wurde behoben"
    "Settings - Der Spendenlink müsste jetzt bei Android Version 10+ wieder funktionieren",
    "Settings - Die App Version kann jetzt in der App angezeigt werden (Settings => About)",
    "verschiedene kleine Änderungen",
    "verschiedene kleine Fehler wurden behoben",
  ]
};

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
    "Web - Autologin set and manually selectable",
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
    "Web - Autologin eingestellt und manuell wählbar",
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




