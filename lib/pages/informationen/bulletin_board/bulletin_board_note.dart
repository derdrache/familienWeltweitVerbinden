import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../../../functions/user_speaks_german.dart';
import '../../../global/global_functions.dart';
import 'bulletin_board_details.dart';

class BulletinBoardCard extends StatefulWidget {
  final Map note;
  final Function? afterPageVisit;

  const BulletinBoardCard({Key? key, required this.note, this.afterPageVisit}) : super(key: key);

  @override
  State<BulletinBoardCard> createState() => _BulletinBoardCardState();
}

class _BulletinBoardCardState extends State<BulletinBoardCard> {
  var ownProfil = Hive.box("secureBox").get("ownProfil");
  String systemLanguage =
      WidgetsBinding.instance.platformDispatcher.locales[0].languageCode;
  late String noteLocation;
  late String noteCountry;
  late bool noteLanguageGerman;
  late bool userSpeakGerman;
  late bool userSpeakEnglish;
  late bool ownNote;

  @override
  void initState() {
    noteLocation = widget.note["location"]["city"];
    noteCountry = widget.note["location"]["countryname"];
    noteLanguageGerman = widget.note["sprache"] == "de";
    userSpeakGerman = getUserSpeaksGerman();
    userSpeakEnglish = ownProfil["sprachen"].contains("Englisch") ||
        ownProfil["sprachen"].contains("english") ||
        systemLanguage == "en";
    super.initState();
    ownNote = widget.note["erstelltVon"] == ownProfil["id"];
  }

  getNoteTitle() {
    String title;

    if (noteLanguageGerman && userSpeakGerman) {
      title = widget.note["titleGer"];
    } else if (!noteLanguageGerman && userSpeakEnglish) {
      title = widget.note["titleEng"];
    } else if (userSpeakGerman) {
      title = widget.note["titleGer"];
    } else {
      title = widget.note["titleEng"];
    }

    if (title.length > 30) {
      return "${title.substring(0, 28)}...";
    } else {
      return title;
    }
  }

  getStringSized(str) {
    if (str.length > 14) {
      return "${str.substring(0, 12)}...";
    } else {
      return str;
    }
  }

  @override
  Widget build(BuildContext context) {
    double noteRotation = widget.note["rotation"] + 0.0;

    return InkWell(
      onTap: () => changePage(context, BulletinBoardDetails(note: widget.note), whenComplete: widget.afterPageVisit),
      child: Stack(
        children: [
          Container(
            margin: const EdgeInsets.all(10),
            padding: const EdgeInsets.all(5),
            width: 110,
            height: 120,
            transform: Matrix4.rotationZ(noteRotation),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: Colors.yellow[200],
              border: Border.all(),
            ),
            child: Center(
                child: Column(
              children: [
                Text(
                  getNoteTitle(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(
                  height: 10,
                ),
                Text(
                  getStringSized(noteLocation),
                  style: const TextStyle(
                      color: Colors.black),
                ),
                if (noteCountry != noteLocation)
                  Text(getStringSized(noteCountry),
                      style: const TextStyle(
                          color: Colors.black))
              ],
            )),
          ),
          if (ownNote)
            Positioned(
                top: 5.0 + widget.note["rotation"] * 100,
                right: 2,
                child: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    radius: 10,
                    child: const Icon(
                      Icons.edit,
                      size: 10,
                      color: Colors.white,
                    )))
        ],
      ),
    );
  }
}
