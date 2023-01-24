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
              children: isGerman
                ? [
                  _patch(patch1100D),
                  _patch(patch194D),
                  _patch(patch193D),
                  _patch(patch192D),
                  _patch(patch191D),
                  _patch(patch183D),
                  _patch(patch182D),
                  _patch(patch181D),
                  _patch(patch180D),
                  _patch(patch172D),
                  _patch(patch171D),
                  _patch(patch170D),
                  _patch(patch162D),
                  _patch(patch161D),
                  _patch(patch160D),
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
                ]
                :[
                  _patch(patch1100E),
                  _patch(patch194E),
                  _patch(patch193E),
                  _patch(patch192E),
                  _patch(patch191E),
                  _patch(patch183E),
                  _patch(patch182E),
                  _patch(patch181E),
                  _patch(patch180E),
                  _patch(patch172E),
                  _patch(patch171E),
                  _patch(patch170E),
                  _patch(patch162E),
                  _patch(patch161E),
                  _patch(patch160E),
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

var patch1100E={
  "title" : "1.10.0 - xx.xx.2023",
  "inhalt": [
  ]
};
var patch1100D={
  "title" : "1.10.0 - xx.xx.2023",
  "inhalt": [
  ]
};

var patch194E={
  "title" : "1.9.4 - 22.01.2023",
  "inhalt": [
    "Registration - White screen after registration process has been fixed",
    "Chat - New message display now disappears immediately after chat visit",
    "Chat - Group notification is now sent correctly",
    "small bug fixes"
  ]
};
var patch194D={
  "title" : "1.9.4 - 22.01.2023",
  "inhalt": [
    "Registrierung - Weißer Bildschirm nach dem Registrierungsprozess wurde behoben",
    "Chat - Neue Nachrichten Anzeige verschwindet jetzt sofort nach Chat besuch",
    "Chat - Gruppennotifikation wird jetzt korrekt gesendet",
    "kleine Fehlerbehebungen"
  ]
};

var patch193E={
  "title" : "1.9.3 - 11.01.2023",
  "inhalt": [
    "Event - commitments now works properly again",
    "Create profile - it is now not possible to create a profile without interest and languages",
    "small bug fixes"
  ]
};
var patch193D={
  "title" : "1.9.3 - 11.01.2023",
  "inhalt": [
    "Event - Zusagen funktioniert jetzt wieder ordentlich",
    "Profil erstellen - es ist nun nicht mehr möglich ein Profil ohne interesse und Sprachen zu erstellen",
    "kleine Fehlerbehebungen"
  ]
};

var patch192E={
  "title" : "1.9.2 - 30.12.2022",
  "inhalt": [
    "News bug fix - The display error in the news page has been fixed",
    "minor bug fixes"
  ]
};
var patch192D={
  "title" : "1.9.2 - 30.12.2022",
  "inhalt": [
    "News Fehlerbehebung - Der Anzeige Fehler in der News Seite wurde behoben",
    "kleine Fehlerbehebungen"
  ]
};

var patch191E={
  "title" : "1.9.1 - 26.12.2022",
  "inhalt": [
    "General - iOS version released",
    "General - Terms of use have been added. Visible when registering, login and creating content",
    "Main Menu - Events and Communities have been consolidated into the new 'Information' menu item. In addition, there is easier access to city and country information in this new menu item",
    "News - performance has been improved",
    "Chat - cities and countries can be linked in chat, like events and communities",
    "Chat - translation error from English to German due to apostrophes has been fixed",
    "Chat - text input is now displayed correctly and clearly even with very long texts",
    "Events - The description is now automatically translated into English or German",
    "Communities - The description is now automatically translated into English or German",
    "Error correction - chat page - message 'No chats available yet', although there are chats",
    "Error correction - Events: accepting and cancelling events led to duplicate entries",
    "Error correction - Automatic location was sometimes displayed in a language other than English or German",
    "many small improvements",
    "many small bug fixes"
  ]
};
var patch191D={
  "title" : "1.9.1 - 26.12.2022",
  "inhalt": [
    "Allgemein - iOS Version veröffentlicht",
    "Allgemein - Nutzungsbedingungen wurden hinzugefügt. Sichtbar beim Registrieren, Anmelden und Inhalte erstellen",
    "Hauptmenü - Events und Gemeinschaften wurden in dem neuen Menüpunkt 'Informationen' zusammengefasst. Zusätzlich gibt es in diesem neuen Menüpunkt einen leichteren Zugriff auf die Stadt- und Landesinformationen",
    "News - Leistung wurde verbessert",
    "Chat - Städte und Länder können, wie Events und Gemeinschaften, im Chat verlinkt werden",
    "Chat - Übersetzungsfehler von Englisch auf Deutsch durch die Apostrophen wurde behoben",
    "Chat - Texteingabe wird nun auch mit sehr langen Texten korrekt und Übersichtlich angezeigt",
    "Events - Die Beschreibung wird jetzt automatisch in Englisch oder Deutsch übersetzt",
    "Gemeinschaften - Die Beschreibung wird jetzt automatisch in Englisch oder Deutsch übersetzt",
    "Fehlerkorrektur - Chatseite - Meldung 'Noch keine Chats vorhanden', obwohl es Chats gibt",
    "Fehlerkorrektur - Events: Zusage und Absage von Events hat zu doppelten einträgen geführt",
    "Fehlerkorrektur - Der Automatische Standort wurde manchmal in einer anderen Sprache als Deutsch oder Englisch ausgegeben",
    "viele kleine Verbesserungen",
    "viele kleine Fehlerbehebungen"
  ]
};

var patch183E={
  "title" : "1.8.3 - 26.11.2022",
  "inhalt": [
    "Fixed bug - location was requested even though automatic location is disabled",
    "Fixed bug - chat group notification and indication that there are new messages are now displayed again"
  ]
};
var patch183D={
  "title" : "1.8.3 - 26.11.2022",
  "inhalt": [
    "Fehler behoben - Der Standort wurde abgefragt, obwohl der automatische Standort deaktiviert ist",
    "Fehler behoben - Chatgruppen Notifikation und Anzeige das es neue Nachrichten gibt, werden nun wieder angezeigt"
  ]
};

var patch182E={
  "title" : "1.8.2 - 24.11.2022",
  "inhalt": [
    "Chatgroups - Clicking on the name now opens the member list. From there there is then the possibility to get into the details view of the event/community/city",
    "Chat - When clicking on the profile picture next to the message, the profile now opens",
    "Bug fixed - When clicking on the chat notification, the chat loads properly",
    "Bug fixed - Messages to new people are now saved and sent again",
    "Bug fixed - leaving chat group works again"
  ]
};
var patch182D={
  "title" : "1.8.2 - 24.11.2022",
  "inhalt": [
    "Chatgruppen - Beim klick auf den Namen geht jetzt die Mitgliederliste auf. Von dort gibt es dann die Möglichkeit in die Detailsansicht vom Event/Community/Stadt zu gelangen",
    "Chat - Beim Klick auf das Profilbild neben der Nachricht, öffnet sich jetzt das Profil",
    "Fehler behoben - Beim Klicken auf die Chatnotifikation, wird der Chat ordentlich geladen",
    "Fehler behoben - Nachrichten an neuen Personen werden jetzt wieder gespeichert und gesendet",
    "Fehler behoben - Chat Gruppe verlassen funktioniert wieder"
  ]
};

var patch181E={
  "title" : "1.8.1 - 20.11.2022",
  "inhalt": [
    "Login - The login error for new users has been fixed",
    "World Map - The database error that caused the world map to crash has been fixed",
    "Profile - profiles with a family profile can be opened again",
    "Chat - small bugs were fixed"
  ]
};
var patch181D={
  "title" : "1.8.1 - 20.11.2022",
  "inhalt": [
    "Login - Der Loginfehler für neue User wurde behoben",
    "Weltkarte - Der Datenbankfehler der zum Absturz der Weltkarte geführt hat wurde behoben",
    "Profil - Profile mit einem Familienprofil können wieder geöffnet werden",
    "Chat - kleine Fehler wurden behoben"
  ]
};

var patch180E={
  "title" : "1.8.0 - 16.11.2022",
  "inhalt": [
    "Chats - chat groups have been added. There are now the following chat groups: cities, events, communities and a world chat. In the groups, each participant can write in their own language, and the other participants can have any language translated into theirs by pressing a button.",
    "Chats - Chat page has been revised to keep it clear despite chat groups",
    "News page - There is now a welcome entry when changing locations",
    "News page - Some improvements have been implemented",
    "City information - user information has been improved",
    "Family profile - The display of the family profile has been improved",
    "many small improvements",
    "many small bug fixes"
  ]
};
var patch180D={
  "title" : "1.8.0 - 16.11.2022",
  "inhalt": [
    "Chats - Chatgruppen wurden eingebaut. Es gibt jetzt folgende Chatgruppen: Städte, Events, Gemeinschaften und einen Worldchat. In den Gruppen kann jeder Teilnehmer in seiner Sprache schreiben, die anderen Teilnehmer können jede Sprache per Knopfdruck in ihre Übersetzen lassen",
    "Chats - Chatseite wurde überarbeitet, damit es trotz Chatgruppen übersichtlich bleibt",
    "Newsseite - Bei Ortwechsel gibt es jetzt einen Willkommenseintrag",
    "Newsseite - Es wurden einige Verbesserungen eingebaut",
    "Stadtinformation - Benutzerinformationen wurden verbessert",
    "Familienprofil - Die Anzeige des Familienprofils wurde verbessert",
    "viele kleine Verbesserungen",
    "viele kleine Fehlerbehebungen"
  ]
};

var patch172E={
  "title" : "1.7.2 - 21.10.2022",
  "inhalt": [
    "Android Notification - Due to an error, the notification was always sent twice",
    "Chat - Error when deleting messages has been fixed",
    "Chat - Long messages when replying are now displayed correctly",
    "Chat Page - Quick edit when long pressing on chat now works correctly",
    "Profile Visited Countries - An error in the input box has been fixed"
  ]
};
var patch172D={
  "title" : "1.7.2 - 21.10.2022",
  "inhalt": [
    "Android Notification - Durch ein Fehler wurde die Notification immer zwei Mal versendet",
    "Chat - Fehler beim Nachrichten löschen wurde behoben",
    "Chat - Lange Nachrichten beim antworten werden nun korrekt angezeigt",
    "Chat Page - Schnell Bearbeitung bei langem drücken auf den Chat funktioniert nun fehlerfrei",
    "Profil besuchte Länder - Ein Fehler in der Eingabebox wurde behoben",
  ]
};

var patch171E={
  "title" : "1.7.1 - 15.10.2022",
  "inhalt": [
    "Fixed chat bug - For the users without chats, the chat page crashed",
  ]
};
var patch171D={
  "title" : "1.7.1 - 15.10.2022",
  "inhalt": [
    "Fehler beim Chat behoben - Bei den Benutzern ohne Chats, ist die Chatseite abgestürzt",
  ]
};

var patch170E={
  "title" : "1.7.0 - 13.10.2022",
  "inhalt": [
    "Chat system has been greatly improved",
    "Profile - Visited countries can be saved again",
    "Profile - Change of location is updated again immediately after the change",
    "Profile - small adjustments in trip planning",
    "News page - crash problems have been fixed (gray screen)",
    "various small improvements",
    "various small bug fixes"
  ]
};
var patch170D={
  "title" : "1.7.0 - 13.10.2022",
  "inhalt": [
    "Chatsystem wurde stark verbessert",
    "Profil - Besuchte Länder kann wieder gespeichert werden",
    "Profil - Nach dem ändern der Location, wird die Veränderung wieder sofort sichtbar",
    "Profil - kleine Änderungen bei der Reiseplanung",
    "News page - Absturzprobleme wurden behoben (grauer Bildschirm)",
    "verschiedene kleine Verbesserungen",
    "verschiedene kleine Fehlerbehebungen"
  ]
};

var patch162E={
  "title" : "1.6.2 - 16.09.2022",
  "inhalt": [
    "optimizations to decrease server crashes"
  ]
};
var patch162D={
  "title" : "1.6.2 - 16.09.2022",
  "inhalt": [
    "Optimierungen um Serverabstürze zu vermindern"
  ]
};

var patch161E={
  "title" : "1.6.1 - 06.09.2022",
  "inhalt": [
    "The error when creating communities has been fixed",
    "The incorrect display of communities was corrected",
    "Newspage now works without errors",
    "Change of location is now properly saved in the database again"
  ]
};
var patch161D={
  "title" : "1.6.1 - 06.09.2022",
  "inhalt": [
    "Der Fehler beim Gemeinschaften erstellen wurde behoben",
    "Die Fehlerhafte Anzeige der Gemeinschaften wurde korrigiert"
    "Newspage funktioniert jetzt ohne Fehler",
    "Ortswechsel wird jetzt wieder ordentlich in der Datenbank gespeichert"
  ]
};

var patch160E={
  "title" : "1.6.0 - 31.08.2022",
  "inhalt": [
    "News Page has been added",
    "Third party events/communities can be created and will be clearly visible at the event/community",
    "Bug fix - Event and community description can be changed again",
    "Performance improvement - World map in web version on smartphones has been slightly improved from performance",
    "various small improvements",
    "various small bug fixes"
  ]
};
var patch160D={
  "title" : "1.6.0 - 31.08.2022",
  "inhalt": [
    "News Page wurde hinzugefügt",
    "Events / Gemeinschaften von dritten können erstellt werden und werden beim jeweiligen Event / Gemeinschaft gut sichtbar angezeigt",
    "Fehlerbehebung - Event- und Gemeinschaftsbeschreibung kann wieder geändert werden",
    "Leistungsverbesserung - Die Weltkarte in der Web Version auf Smartphones wurde von der Leistung etwas verbessert",
    "verschiedene kleine Verbesserungen",
    "verschiedene kleine Fehlerbehebungen"
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
    "Erweiterung Gemeinschaften - Es ist jetzt möglich Gemeinschaften zu erstellen und auf der Weltkarte oder im extra Reiter zu suchen",
    "Familienprofil - Unter Einstellungen und dann oben rechts bei den 3 Punkten, gibt es "
        "jetzt die Möglichkeit ins Familienprofil zu gelangen. Dort kann das Profil aktiviert werden, "
        "bestimmt werden welches das Hauptprofil ist und weitere Familienmitglieder hinzugefügt werden.",
    "Allgemein - Es ist jetzt möglich eigene Bilder hochzuladen",
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
    "Erweiterung Reiseplanung - Es ist jetzt möglich unter Settings seine Reiseplanung einzutragen. Die Weltkarte kann nun, per Klick auf das Uhr-Icon, anzeigen welche Familien sich wo in einem bestimmten Zeitraum aufhalten werden",
    "Android - Neuer Freund Notifikation führt jetzt beim klick direkt zum Profil",
    "Android - Start der App wurde stark beschleunigt (ausgenommen der erste Start nach dem installieren der App)",
    "Android - Externe Verlinkungen funktionieren nun bei Android 10 oder höher",
    "Allgemein - Benutzer können jetzt gemeldet werden",
    "Allgemein - Benutzer können jetzt geblockt werden. Geblockte Benutzer können dich auf der Weltkarte nicht mehr sehen",
    "Registrierung - Im Login Bildschirm gibt es jetzt die Möglichkeit sich die Bestätigungsmail noch einmal senden zu lassen, falls diese nicht angekommen ist",
    "Weltkarte - die 0er Marker wurden gegen i-Marker ausgetauscht, damit besser klar wird, dass dort keine Familien zu sehen sind",
    "Weltkarte - Das Icon zum wechseln auf die Events zeigt jetzt an ob es neue Events gibt",
    "Profil anzeigen - Im Anzeige Profil von anderen Familien wird jetzt grob angezeigt, wann diese zuletzt Online waren",
    "Chat - Nachrichten Eingabebox wurde vergrößert",
    "Events - Es ist ist möglich sich für ein wiederholendes Event als 'immer zusagen' zu markieren",
    "Weltkarte - Filtersystem wurde komplett überarbeitet",
    "Privatsphäre Einstellung - Für den genauen Standort gibt es jetzt Möglichkeiten für wen es angezeigt wird",
    "Profil - Es gibt jetzt ein Feld um seine besuchten Länder einzutragen. Dieses Feld wird gleichzeitig auch automatisch durch die Reiseplanung gefüllt, nachdem die Aufenthaltszeit abgelaufen ist"
    "Profil - Sprachen wurde um 'Polnisch' und 'Niederländisch' erweitert",
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
    "Weltkarte - Fehler der zum Crash führt wurde behoben",
    "Weltkarte - Zoomstufe erweitert. Es kann jetzt tiefer in die Weltkarte reingezoomt werden, um die Familien mit genauen Standort zu sehen",
    "Automatischer Standort - Es wurde ein Fehler behoben der auf der Weltkarte zu falschen Einträgen geführt hat",
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
    "Weltkarte - Stadtinformationen wurden eingebaut. Teile deine Informationen über die Stadt mit anderen",
    "Weltkarte - Es wurden neue Buttons eingebaut um Freunde und Events auf der Karte anzuzeigen",
    "Weltkarte - Die Weltkarte kann jetzt auch nach Städten gefiltert werden",
    "Weltkarte Fehlerbehebung - Der Filter funktioniert jetzt auch bei der ersten Eingabe",
    "Settings - Es gibt jetzt die Möglichkeit den Standort automatisch updaten zu lassen",
    "Profil Sprachen Erweiterung - Italienisch, Portugiesisch, Japanisch und Türkisch können jetzt ausgewählt werden",
    "Profil Erweiterung - Neues Feld: 'Verkaufen / Tauschen / Verschenken'",
    "Button zum Accountlöschen in Settings -> Privatspähre und Sicherheit eingebaut",
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
    "Allgemein - Kleine Fehler beim Profilbild ändern behoben",
    "Allgemein - Profilbild in groß wird nun korrekt angezeigt",
    "Web Version - Ladebildschirm hinzugefügt",
    "Weltkarte - Anzeige der Markerpunkte ist nun korrekt",
    "Weltkarte - Menu wird nun besser sortiert",
    "Profil - Neue Information 'Auf Reise' eingefügt",
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
    "Allgemein - Profilbilder wurden eingefügt. Unter Settings kann ein Link von einem beliebigen Bild eingefügt werden.",
    "Allgemein - Es wurde eine schwere Sicherheitslücke geschlossen",
    "Allgemein - Geschwindigkeit der App wurde weiter verbessert",
    "Android - Es wurde eine 'Kein-Internet'- Anzeige eingebaut",
    "Weltkarte - Länder wurden auf der niedrigsten Zoomstufe stärker zusammengefasst",
    "Weltkarte - Zoom in beim klick auf einen Markerpunkt wurde entfernt",
    "Weltkarte - Die Größe des Menüs kann jetzt nach belieben verändert werden",
    "Chats - Die Nachrichten Eingabebox passt sich jetzt dem Text an",
    "Events - Es ist jetzt auch möglich mehrtägige Events zu erstellen",
    "Events - Der Fehler bei der Auswahl der Zeitzone wurde behoben",
    "Profil - Es stehen mehr Sprachen zur Auswahl zur Verfügung ( Verändert nichts an der Anzeigesprache der App)",
    "Profil inaktiv - Bei einer Inaktivität von mehr als einen Monat, wird eine "
        "Standort-noch-aktuell Notification versendet(Ausnahme sind Benutzer mit "
        "der Reise Art 'Fester Standort'. Ab 3 Monaten wird das Profil für "
        "andere sichtbar als inaktiv angezeigt. Ab 6 Monaten wird das Profil "
        "nicht mehr auf der Weltkarte angezeigt.Der Inaktivzähler wird mit dem "
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




