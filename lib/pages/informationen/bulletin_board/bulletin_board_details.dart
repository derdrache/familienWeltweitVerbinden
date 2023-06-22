import 'package:familien_suche/widgets/custom_appbar.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../../../widgets/dialogWindow.dart';

class BulletinBoardDetails extends StatelessWidget {
  Map note;
  var ownProfil = Hive.box("secureBox").get("ownProfil");
  String systemLanguage =
      WidgetsBinding.instance.platformDispatcher.locales[0].languageCode;

  BulletinBoardDetails({Key? key, required this.note});


  @override
  Widget build(BuildContext context) {
    bool noteLanguageGerman = note["beschreibungGer"].contains("Dies ist eine automatische Übersetzung");
    bool userSpeakGerman = ownProfil["sprachen"].contains("Deutsch")
        || ownProfil["sprachen"].contains("german") || systemLanguage == "de";
    bool userSpeakEnglish = ownProfil["sprachen"].contains("Englisch")
        || ownProfil["sprachen"].contains("english") || systemLanguage == "en";


    imageFullscreen(image) {
      showDialog(
          context: context,
          builder: (BuildContext buildContext) {
            return CustomAlertDialog(
              windowPadding: const EdgeInsets.all(30),
              children: [Image.network(image)],
            );
          });
    }

    showTitle() {
      String title;

      if(noteLanguageGerman && userSpeakGerman){
        title = note["titleGer"];
      }else if (!noteLanguageGerman && userSpeakEnglish){
        title = note["titleEng"];
      }else if(userSpeakGerman){
        title = note["titleGer"];
      }else{
        title = note["titleEng"];
      }

      return Container(
          margin: const EdgeInsets.only(top: 10, bottom: 10, right: 20, left: 20),
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
          ));
    }

    showBasicInformation(title, body) {
      return Container(
        margin: const EdgeInsets.only(left: 20, right: 20, top: 5, bottom: 5),
        child: Row(
          children: [
            Text("$title: ", style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(body)
          ],
        ),
      );
    }

    showDescription() {
      String description;

      if(noteLanguageGerman && userSpeakGerman){
        description = note["beschreibungGer"];
      }else if (!noteLanguageGerman && userSpeakEnglish){
        description = note["beschreibungEng"];
      }else if(userSpeakGerman){
        description = note["beschreibungGer"];
      }else{
        description = note["beschreibungEng"];
      }

      return Container(
          margin: const EdgeInsets.only(top: 15, left: 20, right: 20, bottom: 10),
          child: Text(description));
    }

    showImages() {
      List noteImages = note["bilder"];

      return Container(
        margin: const EdgeInsets.all(5),
        child: Wrap(
          children: noteImages
              .map<Widget>((image) => InkWell(
            onTap: () => imageFullscreen(image),
            child: Stack(
              children: [
                Container(
                  margin: const EdgeInsets.all(5),
                  width: 80,
                  height: 80,
                  decoration:
                  BoxDecoration(border: Border.all(), color: Colors.white),
                  child: Image.network(image),
                ),
              ],
            ),
          ))
              .toList(),
        ),
      );
    }



    return Scaffold(
      appBar: CustomAppBar(
        title: "test",
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        margin: const EdgeInsets.all(10),
        decoration: BoxDecoration(
            color: Colors.yellow[200],
            border: Border.all(),
            borderRadius: BorderRadius.circular(4)),
        child: Column(
          children: [
            showTitle(),
            showBasicInformation("Ort", note["location"]["city"] + " / " + note["location"]["countryname"]),
            showDescription(),
            const Expanded(child: SizedBox.shrink()),
            showImages()
          ],
        ),
      ),
    );
  }
}
