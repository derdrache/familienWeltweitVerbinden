import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../../../functions/translation.dart';
import '../../../services/database.dart';
import '../../../widgets/custom_appbar.dart';
import '../../../widgets/google_autocomplete.dart';
import '../../../global/global_functions.dart' as global_func;
import '../../../widgets/image_upload_box.dart';
import '../../../widgets/layout/custom_snackbar.dart';
import '../../../widgets/layout/custom_text_input.dart';
import 'bulletin_board_details.dart';

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
      customSnackBar(context, AppLocalizations.of(context)!.titelEingeben);
      return false;
    } else if (checkLocation) {
      customSnackBar(context, AppLocalizations.of(context)!.ortEingeben);
      return false;
    } else if (beschreibung) {
      customSnackBar(
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
                  moreLines: 9, maxLength: 650, maxLengthColor: Colors.black45, textInputAction: TextInputAction.newline)));
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
        margin: const EdgeInsets.all(10),
        padding: const EdgeInsets.only(top: 10, bottom: 10),
        decoration: BoxDecoration(
            color: Colors.yellow[200],
            border: Border.all(),
            borderRadius: BorderRadius.circular(4)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
                  setTitle(),
                  setLocation(),
                  setDescription(),
                  imageUploadBox
                ]
        ),
      ),
    );
  }
}
