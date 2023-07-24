import 'package:familien_suche/functions/user_speaks_german.dart';
import 'package:familien_suche/global/global_functions.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import 'bulletin_board_details.dart';

class BulletinBoardCard extends StatefulWidget {
  final Map note;

  const BulletinBoardCard({Key? key, required this.note});

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
  noteLanguageGerman = widget.note["beschreibungEng"].contains("This is an automatic translation");
  userSpeakGerman = getUserSpeaksGerman();
    userSpeakEnglish = ownProfil["sprachen"].contains("Englisch")
      || ownProfil["sprachen"].contains("english") || systemLanguage == "en";
    super.initState();
    ownNote = widget.note["erstelltVon"] == ownProfil["id"];
  }

  getNoteTitle(){
    String title;

    if(noteLanguageGerman && userSpeakGerman){
      title = widget.note["titleGer"];
    }else if (!noteLanguageGerman && userSpeakEnglish){
      title = widget.note["titleEng"];
    }else if(userSpeakGerman){
      title = widget.note["titleGer"];
    }else{
      title = widget.note["titleEng"];
    }

    if(title.length > 30){
      return "${title.substring(0,28)}...";
    }else{
      return title;
    }
  }

  getStringSized(str){
    if(str.length > 14){
      return "${str.substring(0,12)}...";
    }else{
      return str;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => changePage(context, BulletinBoardDetails(note: widget.note)),
      child: Stack(
        children: [
          Container(
            margin: EdgeInsets.all(10),
            padding: EdgeInsets.all(5),
            width: 110,
            height: 110,
            transform: Matrix4.rotationZ(widget.note["rotation"]),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: Colors.yellow[200],
              border: Border.all(),
            ),
            child: Center(child: Column(
              children: [
                Text(getNoteTitle(), textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold),),
                SizedBox(height: 10,),
                Text(getStringSized(noteLocation)),
                if(noteCountry != noteLocation) Text(getStringSized(noteCountry))
              ],
            )),
          ),
          if(ownNote) Positioned(
              top: 5.0 + widget.note["rotation"]*100, right: 2,
              child: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  radius: 10,
                  child: Icon(Icons.edit, size: 10, color: Colors.white,
                  )
              )
          )
        ],
      ),
    );
  }
}
