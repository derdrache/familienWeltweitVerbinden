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
      patchList.add(const SizedBox(height: 10));
      patchList.add(Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("- "),
          Flexible(
              child: Text(inhalt,overflow: TextOverflow.visible,))
        ],
      ));
    }

    return Container(
      margin: const EdgeInsets.only(top: 15, left: 10, right: 5, bottom: 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              patch["title"],
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold
              ),
            ),
            const SizedBox(width: 10),
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
                _patch(patch150D),
                _patch(patch141D),
                _patch(patch140D),
                _patch(patch131D),
                _patch(patch130D),
                _patch(patch123D),
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
                _patch(patch150E),
                _patch(patch141E),
                _patch(patch140E),
                _patch(patch131E),
                _patch(patch130E),
                _patch(patch123E),
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

var patch150E={
  "title" : "1.5.0 - 01.08.2022",
  "inhalt": [
    "Expansion Communities - It is now possible to create communities and search them on the world map or in the extra tab",
    "Family Profile - Under Settings and then on the top right by the 3 dots, there is "
        "now the possibility to enter the family profile. There you can activate the profile, "
        "be determined which is the main profile and add more family members.",
    "General - It is now possible to upload your own pictures",
    "General - The errors with an apostrophe in the name have been fixed",
    "World map - profiles are now correctly displayed at the smallest zoom level",
    "Online event - time conversion bug has been fixed",
    "Profile / event description - description texts are now copyable and links are automatically transform into hyperlinks.",
    "Profile - Interests has been expanded to include 'Montessori, Waldorf, Nonviolent Communication, Minimalism, Frugalism, Vegan, Sugar Free, and Gluten Free'",
    "various small bug fixes",
    "various small improvements"
  ]
};
var patch150D={
  "title" : "1.5.0 - 01.08.2022",
  "inhalt": [
    "Erweiterung Gemeinschaften - Es ist jetzt m??glich Gemeinschaften zu erstellen und auf der Weltkarte oder im extra Reiter zu suchen",
    "Familienprofil - Unter Einstellungen und dann oben rechts bei den 3 Punkten, gibt es "
        "jetzt die M??glichkeit ins Familienprofil zu gelangen. Dort kann das Profil aktiviert werden, "
        "bestimmt werden welches das Hauptprofil ist und weitere Familienmitglieder hinzugef??gt werden.",
    "Allgemein - Es ist jetzt m??glich eigene Bilder hochzuladen",
    "Allgemein - Die Fehler mit einem Apostroph im Namen wurden behoben",
    "Weltkarte - Profile werden nun korrekt auf der kleinsten Zoomstufe angezeigt",
    "Online Event - Fehler bei der Zeitumrechnung wurde behoben",
    "Profil- / Eventbeschreibung - Die Beschreibungstexte sind nun kopierbar und die Links werden automatisch "
        "in Hyperlinks verwandelt.",
    "Profil - Interessen wurde um 'Montessori, Waldorf, Gewaltfreie Kommunikation, Minimalismus, Frugalismus, Vegan, Zuckerfrei und Glutenfrei' erweitert",
    "verschiedene kleine Fehlerbehebungen",
    "verschiedene kleine Verbesserungen"
  ]
};

var patch141E={
  "title" : "1.4.1 - 27.06.2022",
  "inhalt": [
    "A profile creation bug has been fixed",
    "various small bug fixes"
  ]
};
var patch141D={
  "title" : "1.4.1 - 27.06.2022",
  "inhalt": [
    "Ein Fehler beim Profil erstellen wurde behoben",
    "verschiedene kleine Fehlerbehebungen"
  ]
};

var patch140E={
  "title" : "1.4.0 - 26.06.2022",
  "inhalt": [
    "Expansion Travel Planning - It is now possible to enter your travel plans under Settings. The world map can now show, by clicking on the clock icon, which families will be where in a certain period of time",
    "Android - New friend notification now goes directly to the profile when clicked",
    "Android - App startup has been greatly accelerated (except the first startup after installing the app)",
    "Android - External linking now works on Android 10 or higher",
    "General - Users can now be reported",
    "General - Users can now be blocked. Blocked users can no longer see you on the world map",
    "Registration - In the login screen there is now the possibility to have the confirmation mail sent again if it did not arrive",
    "World map - the 0 markers have been replaced with i markers to make it clearer that there are no families there",
    "World Map - The icon to switch to the events now shows if there are new events",
    "Show Profile - The display profile of other families now roughly shows when they were last online",
    "Chat - Messages input box has been enlarged",
    "Events - It is possible to mark yourself as 'always agree' for a repeating event",
    "World map - filter system has been completely revised",
    "Privacy setting - For the exact location there are now options for whom it will be displayed",
    "Profile - There is now a field to enter your visited countries. At the same time, this field is also automatically filled by Trip Planning after the stay time has expired."
    "Profile - Languages has been extended by 'Polish' and 'Dutch'",
    "Profile - Interests has been extended by 'online meetings'",
    "Automatic location - Automatic location can no longer be activated for trip type 'Fixed location'",
    "various small style adjustments",
    "various small bug fixes",
    "various small improvements"
  ]
};
var patch140D={
  "title" : "1.4.0 - 26.06.2022",
  "inhalt": [
    "Erweiterung Reiseplanung - Es ist jetzt m??glich unter Settings seine Reiseplanung einzutragen. Die Weltkarte kann nun, per Klick auf das Uhr-Icon, anzeigen welche Familien sich wo in einem bestimmten Zeitraum aufhalten werden",
    "Android - Neuer Freund Notifikation f??hrt jetzt beim klick direkt zum Profil",
    "Android - Start der App wurde stark beschleunigt (ausgenommen der erste Start nach dem installieren der App)",
    "Android - Externe Verlinkungen funktionieren nun bei Android 10 oder h??her",
    "Allgemein - Benutzer k??nnen jetzt gemeldet werden",
    "Allgemein - Benutzer k??nnen jetzt geblockt werden. Geblockte Benutzer k??nnen dich auf der Weltkarte nicht mehr sehen",
    "Registrierung - Im Login Bildschirm gibt es jetzt die M??glichkeit sich die Best??tigungsmail noch einmal senden zu lassen, falls diese nicht angekommen ist",
    "Weltkarte - die 0er Marker wurden gegen i-Marker ausgetauscht, damit besser klar wird, dass dort keine Familien zu sehen sind",
    "Weltkarte - Das Icon zum wechseln auf die Events zeigt jetzt an ob es neue Events gibt",
    "Profil anzeigen - Im Anzeige Profil von anderen Familien wird jetzt grob angezeigt, wann diese zuletzt Online waren",
    "Chat - Nachrichten Eingabebox wurde vergr????ert",
    "Events - Es ist ist m??glich sich f??r ein wiederholendes Event als 'immer zusagen' zu markieren",
    "Weltkarte - Filtersystem wurde komplett ??berarbeitet",
    "Privatsph??re Einstellung - F??r den genauen Standort gibt es jetzt M??glichkeiten f??r wen es angezeigt wird",
    "Profil - Es gibt jetzt ein Feld um seine besuchten L??nder einzutragen. Dieses Feld wird gleichzeitig auch automatisch durch die Reiseplanung gef??llt, nachdem die Aufenthaltszeit abgelaufen ist"
    "Profil - Sprachen wurde um 'Polnisch' und 'Niederl??ndisch' erweitert",
    "Profil - Interessen wurde um 'online Treffen' erweitert",
    "Automatischer Standort - Automatischer Standort kann nicht mehr bei Reiseart 'Fester Standort' aktiviert werden",
    "verschiedene kleine Style-Anpassungen",
    "verschiedene kleine Fehlerbehebungen",
    "verschiedene kleine Verbesserungen"
  ]
};

var patch131E={
  "title" : "1.3.1 - 27.05.2022",
  "inhalt": [
    "World map - bug that leads to crash has been fixed",
    "World map - zoom level extended. It is now possible to zoom deeper into the world map to see the families with exact location",
    "Automatic location - fixed a bug that caused incorrect entries on the world map",
    "City information - city insider information now shows the correct date",
    "City Information - fixed a bug with the automatic entry in 'visited by'"
  ]
};
var patch131D={
  "title" : "1.3.1 - 27.05.2022",
  "inhalt": [
    "Weltkarte - Fehler der zum Crash f??hrt wurde behoben",
    "Weltkarte - Zoomstufe erweitert. Es kann jetzt tiefer in die Weltkarte reingezoomt werden, um die Familien mit genauen Standort zu sehen",
    "Automatischer Standort - Es wurde ein Fehler behoben der auf der Weltkarte zu falschen Eintr??gen gef??hrt hat",
    "Stadtinformationen - Stadt Insider-Information zeigt jetzt das richtige Datum",
    "Stadtinformationen - Fehler beim automatischen Eintrag in 'besucht von' wurde behoben"
  ]
};

var patch130E={
  "title" : "1.3.0 - 21.05.2022",
  "inhalt": [
    "World map - city information has been implemented.\nShare your information about the city with others"
    "World Map - new buttons have been added to show friends and events on the map",
    "World Map - the world map can now be filtered by city",
    "World map bug fix - filtering now works on first entry",
    "Settings - there is now an option to have the location updated automatically",
    "Profile languages extension - Italian, Portuguese, Japanese and Turkish can now be selected",
    "Profile extension - new tab: 'sell / trade / give away'",
    "Button to delete account added in Settings -> Privacy and Security",
    "various small style adjustments",
    "various small bug fixes",
    "various small improvements"
  ]
};
var patch130D={
  "title" : "1.3.0 - 21.05.2022",
  "inhalt": [
    "Weltkarte - Stadtinformationen wurden eingebaut. Teile deine Informationen ??ber die Stadt mit anderen",
    "Weltkarte - Es wurden neue Buttons eingebaut um Freunde und Events auf der Karte anzuzeigen",
    "Weltkarte - Die Weltkarte kann jetzt auch nach St??dten gefiltert werden",
    "Weltkarte Fehlerbehebung - Der Filter funktioniert jetzt auch bei der ersten Eingabe",
    "Settings - Es gibt jetzt die M??glichkeit den Standort automatisch updaten zu lassen",
    "Profil Sprachen Erweiterung - Italienisch, Portugiesisch, Japanisch und T??rkisch k??nnen jetzt ausgew??hlt werden",
    "Profil Erweiterung - Neues Feld: 'Verkaufen / Tauschen / Verschenken'",
    "Button zum Accountl??schen in Settings -> Privatsp??hre und Sicherheit eingebaut",
    "verschiedene kleine Style-Anpassungen",
    "verschiedene kleine Fehlerbehebungen",
    "verschiedene kleine Verbesserungen"
  ]
};

var patch123E={
  "title" : "1.2.3 - 31.03.2022",
  "inhalt": [
    "General - Fixed minor bugs when changing profile picture",
    "General - Profile picture in large is now displayed correctly",
    "Web - Loading screen added",
    "World map - Display of marker points is now correct",
    "World map - menu is now sorted better",
    "Profile - New information 'On trip' added",
    "Profile - interests selection was expanded"

  ]
};
var patch123D={
  "title" : "1.2.3 - 31.03.2022",
  "inhalt": [
    "Allgemein - Kleine Fehler beim Profilbild ??ndern behoben",
    "Allgemein - Profilbild in gro?? wird nun korrekt angezeigt",
    "Web Version - Ladebildschirm hinzugef??gt",
    "Weltkarte - Anzeige der Markerpunkte ist nun korrekt",
    "Weltkarte - Menu wird nun besser sortiert",
    "Profil - Neue Information 'Auf Reise' eingef??gt",
    "Profil - Interessen Auswahl wurde erweitert"
  ]
};

var patch122E={
  "title" : "1.2.2",
  "inhalt": [
    "General - profile pictures have been inserted. A link from any picture can be inserted under Settings.",
    "General - A serious security vulnerability has been closed",
    "General - Speed of the app has been further improved",
    "Android - A 'no internet' indicator has been added",
    "World Map - Countries have been grouped together more at the lowest zoom level",
    "World map - zoom in when clicking on a marker point has been removed",
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
    "Allgemein - Profilbilder wurden eingef??gt. Unter Settings kann ein Link von einem beliebigen Bild eingef??gt werden.",
    "Allgemein - Es wurde eine schwere Sicherheitsl??cke geschlossen",
    "Allgemein - Geschwindigkeit der App wurde weiter verbessert",
    "Android - Es wurde eine 'Kein-Internet'- Anzeige eingebaut",
    "Weltkarte - L??nder wurden auf der niedrigsten Zoomstufe st??rker zusammengefasst",
    "Weltkarte - Zoom in beim klick auf einen Markerpunkt wurde entfernt",
    "Weltkarte - Die Gr????e des Men??s kann jetzt nach belieben ver??ndert werden",
    "Chats - Die Nachrichten Eingabebox passt sich jetzt dem Text an",
    "Events - Es ist jetzt auch m??glich mehrt??gige Events zu erstellen",
    "Events - Der Fehler bei der Auswahl der Zeitzone wurde behoben",
    "Profil - Es stehen mehr Sprachen zur Auswahl zur Verf??gung ( Ver??ndert nichts an der Anzeigesprache der App)",
    "Profil inaktiv - Bei einer Inaktivit??t von mehr als einen Monat, wird eine "
        "Standort-noch-aktuell Notification versendet(Ausnahme sind Benutzer mit "
        "der Reise Art 'Fester Standort'. Ab 3 Monaten wird das Profil f??r "
        "andere sichtbar als inaktiv angezeigt. Ab 6 Monaten wird das Profil "
        "nicht mehr auf der Weltkarte angezeigt.Der Inaktivz??hler wird mit dem "
        "Besuch in der App zur??ck gesetzt.",
    "Profil - Der Hinttext von '??ber uns' wurde angepasst.",
    "verschiedene kleine Verbesserungen wurden hinzugef??gt",
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
    "Login / Registrierung - Beim Profil erstellen gibt es jetzt die M??glichkeit direkt '??ber uns' einzutragen",
    "Login / Registrierung - Google Login wurde hinzugef??gt",
    "Weltkarte - Das Informationsmenu hat ein neues Layout bekommen",
    "Weltkarte - Verbesserung des Raus-Zoom-Buttons",
    "Weltkarte - Die Nummer auf den Markierungen wurde auf 99 beschr??nkt",
    "Chat - Die Anzeige der falschen Uhrzeit wurde behoben"
    "Settings - Der Spendenlink m??sste jetzt bei Android Version 10+ wieder funktionieren",
    "Settings - Die App Version kann jetzt in der App angezeigt werden (Settings => About)",
    "verschiedene kleine ??nderungen",
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
    "Karte - Auf der niedrigsten Zoomstufe werden die L??nder zur besseren ??bersicht zusammengefasst. Mit einem sp??teren Update wird es noch verbessert.",
    "Karte - Der eigene Standort wird auf der Karte mit einer Fahne angezeigt",
    "Karte Filter - Filter wurde auf 3 beschr??nkt",
    "Karte Filter - Es kann nach L??ndern gefiltert werden",
    "Chat - Benutzersuche f??r neuen Chat funktioniert jetzt mit Autocomplete",
    "Ort Eingabe - Die Eingabe funktioniert jetzt mit Autocomplete",
    "Bezeichnungs??nderung - 'Stadt' => 'Ort'",
    "Web - Autologin eingestellt und manuell w??hlbar",
    "Web - Die Karte wird bei der Benutzung des Mausrads ordentlich upgedatet",
    "Web - Tab Icon eingebaut",
    "Die L??nge vom Benutzernamen wurde auf 40 Zeichen beschr??nkt",
    "Der Karten Zur??ck-Zoom-Button geht jetzt in einzelnen Schritten zur??ck",
    "Beim Benutzernmen kann jetzt auch das Apostroph benutzt werden",
    "Bei der Eingabe vom Ort gibt es jetzt ein ! f??r mehr Information",
    "Login/Registrierung - Der Fehler mit dem Leerzeichen vor und nach der Email wurde behoben",
    "verschiedene kleine ??nderungen",
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
    "letzte Vorbereitungen f??r die Ver??ffentlichung"
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
    "Anpassungen f??r die Web Version",
    "Reiseart 'Auto/Unterk??nfte' hinzugef??gt",
    "Interesse 'Worldschooling' hinzugef??gt",
    "Die Karte hat jetzt einen komplett Raus-Zoom-Button",
    "Beim Klick auf eine Karten Markierung wird in automatisch in die n??chste Ebene reingezoomt",
    "Kontakt-M??glichkeit wird nur angezeigt, wenn der Benutzer eine M??glichkeit freigegeben hat",
    "verschiedene ??bersetzungsfehler wurden behoben",
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
    "Englische Version hinzugef??gt - Die Sprache wird von der Handysprache ??bernommen",
    "Alter der Kinder wird nur noch mit Monat/Jahr abgefragt",
    "Suchleiste der Karte wurde ??berarbeitet, es k??nnen jetzt auch User gesucht werden",
    "Beim Antippen der Chatnotification, ??ffnet sich nun der Chat",
    "Beim Chat mit einer Person kann nun das Profil der jeweiligen Person durch ein antippen auf den Namen ge??ffnet werden",
    "Nachricht Eingabefeld vergr????ert sich nun automatisch",
    "Drehung der Karte ist nicht mehr m??glich",
    "Bei Freund hinzuf??gen/entfernen gibt es jetzt eine Best??tigungsmeldung",
    "Unter Settings gibt es nun ein Button f??r die Profil Vorschau",
    "Bei neuer Chatgruppe er??ffnen wurde die Anzeige der Freundesliste ??berarbeitet",
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
    "Notifications k??nnen unter Settings deaktiviert werden",
    "Die Familien??bersicht bei klick auf einen Kartenpunkt wurde ver??ndert",
    "Profil ??nderungen unter Setting wurde angepasst",
    "Setting/Profil ??ber mich hat mehr Platz bekommen",
    "Fehler bei Abmelden behoben",
    "Kartenfehler behoben: Manche L??nder haben ein Fehler ausgel??st",
    "Allgemeine Codeverbesserungen"
  ]

};

var patch1E = {
  "title" : "1.0.0",
  "inhalt": ["App released"]
};
var patch1D = {
  "title" : "1.0.0",
  "inhalt": ["App ver??ffentlicht"]
};




