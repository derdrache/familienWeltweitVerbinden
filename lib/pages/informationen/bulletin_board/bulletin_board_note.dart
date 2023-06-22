import 'package:familien_suche/global/global_functions.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'dart:math';

import 'bulletin_board_details.dart';

class BulletinBoardCard extends StatefulWidget {
  Map note;

  BulletinBoardCard({Key? key, required this.note});

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

@override
  void initState() {
  noteLocation = widget.note["location"]["city"];
  noteCountry = widget.note["location"]["countryname"];
  noteLanguageGerman = widget.note["beschreibungGer"].contains("Dies ist eine automatische Übersetzung");
  userSpeakGerman = ownProfil["sprachen"].contains("Deutsch")
      || ownProfil["sprachen"].contains("german") || systemLanguage == "de";
    userSpeakEnglish = ownProfil["sprachen"].contains("Englisch")
      || ownProfil["sprachen"].contains("english") || systemLanguage == "en";
    super.initState();
  }

  double getRandomRange() {
    Random random = new Random();
    int randomNumber = random.nextInt(11);
    int changedNumber = 0;

    if(randomNumber < 5){
      changedNumber = randomNumber * -1;
    }else{
      changedNumber =  randomNumber - 5;
    }

    return changedNumber / 100;
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
      child: Container(
        margin: EdgeInsets.all(10),
        padding: EdgeInsets.all(5),
        width: 110,
        height: 120,
        transform: Matrix4.rotationZ(getRandomRange()),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          color: Colors.yellow[200],
          border: Border.all(),
        ),
        child: Center(child: Column(
          children: [
            Text(getNoteTitle(), textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold),),
            SizedBox(height: 5,),
            Text("Location:"),
            Text(getStringSized(noteLocation)),
            Text(getStringSized(noteCountry))
          ],
        )),
      ),
    );
  }
}
