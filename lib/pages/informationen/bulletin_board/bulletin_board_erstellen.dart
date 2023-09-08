import 'dart:math';

import 'package:familien_suche/pages/informationen/bulletin_board/bulletin_board_details.dart';
import 'package:familien_suche/services/database.dart';
import 'package:familien_suche/widgets/custom_appbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../../../functions/translation.dart';
import '../../../widgets/google_autocomplete.dart';
import 'package:familien_suche/global/global_functions.dart' as global_func;

import '../../../widgets/image_upload_box.dart';
import '../../../widgets/layout/custom_snackbar.dart';
import '../../../widgets/layout/custom_text_input.dart';

class BulletonBoardCreate extends StatefulWidget {
  const BulletonBoardCreate({Key? key}) : super(key: key);

  @override
  State<BulletonBoardCreate> createState() => _BulletonBoardCreateState();
}

class _BulletonBoardCreateState extends State<BulletonBoardCreate> {
  bool isCreating = true;
  TextEditingController titleKontroller = TextEditingController();
  TextEditingController descriptionKontroller = TextEditingController();
  var ortAuswahlBox = GoogleAutoComplete(
      margin: const EdgeInsets.only(top: 5, bottom: 5, left: 30, right: 30),
      borderColor: Colors.black,
      withOwnLocation: true,withWorldwideLocation: true);
  var imageUploadBox = ImageUploadBox(imageKategorie: "note",);

  double getRandomRange() {
    Random random = Random();
    int randomNumber = random.nextInt(11);
    int changedNumber = 0;

    if(randomNumber < 5){
      changedNumber = randomNumber * -1;
    }else{
      changedNumber =  randomNumber - 5;
    }

    return changedNumber / 100;
  }

  saveNote() {
    String userId = Hive.box("secureBox").get("ownProfil")["id"];
    bool allFilled = checkValidation();
    List uploadedImages = imageUploadBox.getImages();

    if (!allFilled) return;

    var noteId = const Uuid().v4();

    Map newNote = {
      "id": noteId,
      "titleGer": titleKontroller.text,
      "titleEng": titleKontroller.text,
      "beschreibungGer": descriptionKontroller.text,
      "beschreibungEng": descriptionKontroller.text,
      "location": ortAuswahlBox.getGoogleLocationData(),
      "bilder": uploadedImages,
      "erstelltVon": userId,
      "erstelltAm": DateTime.now().toString(),
      "sprache": "",
      "rotation": getRandomRange()
    };

    var allBulletinBoardNotes =
        Hive.box('secureBox').get("bulletinBoardNotes") ?? [];
    allBulletinBoardNotes.add(newNote);

    saveInDB(newNote);

    return newNote;
  }

  saveInDB(newNote) async {
    var titleTranslationData = await translation(titleKontroller.text);
    var descriptionTranslationData = await translation(descriptionKontroller.text, withTranslationNotice: true);

    newNote["titleGer"] = titleTranslationData["ger"];
    newNote["titleEng"] = titleTranslationData["eng"];
    newNote["beschreibungGer"] = descriptionTranslationData["ger"];
    newNote["beschreibungEng"] = descriptionTranslationData["eng"];
    newNote["sprache"] = descriptionTranslationData["language"];

    await BulletinBoardDatabase().addNewNote(Map.of(newNote));
  }

  checkValidation() {
    bool checkTitle = titleKontroller.text.isEmpty;
    bool checkLocation = ortAuswahlBox.getGoogleLocationData()["city"] == null;
    bool beschreibung = descriptionKontroller.text.isEmpty;

    if (checkTitle) {
      customSnackbar(context, AppLocalizations.of(context)!.titelEingeben);
      return false;
    } else if (checkLocation) {
      customSnackbar(context, AppLocalizations.of(context)!.ortEingeben);
      return false;
    } else if (beschreibung) {
      customSnackbar(
          context, AppLocalizations.of(context)!.beschreibungEingeben);
      return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    ortAuswahlBox.hintText = "Ort Eingeben";

    setTitle() {
      return Center(
          child: Container(
              margin: const EdgeInsets.only(left: 20, right: 20, top: 5, bottom: 5),
              child: CustomTextInput("Titel einfügen", titleKontroller, borderColor: Colors.black,
                  maxLength: 45, maxLengthColor: Colors.black45
                    )));
    }

    setLocation() {
      return ortAuswahlBox;
    }

    setDescription() {
      return Center(
          child: Container(
              width: 700,
              margin: const EdgeInsets.only(left: 20, right: 20, top: 5, bottom: 5),
              child: CustomTextInput(
                  "Beschreibung einfügen", descriptionKontroller,
                  borderColor: Colors.black,
                  moreLines: 10, maxLength: 650, maxLengthColor: Colors.black45, textInputAction: TextInputAction.newline)));
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: CustomAppBar(
        title: AppLocalizations.of(context)!.tooltipNotizErstellen,
        buttons: [
          IconButton(
              onPressed: () {
                Map? newNote = saveNote();
                if(newNote == null) return;

                Navigator.pop(context);
                global_func.changePage(
                    context, BulletinBoardDetails(note: newNote));
              },
              tooltip: AppLocalizations.of(context)!.tooltipEingabeBestaetigen,
              icon: const Icon(Icons.done, size: 30))
        ],
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
                  setTitle(),
                  setLocation(),
                  setDescription(),
                  const Expanded(child: SizedBox.shrink()),
                  imageUploadBox
                ]
        ),
      ),
    );
  }
}
