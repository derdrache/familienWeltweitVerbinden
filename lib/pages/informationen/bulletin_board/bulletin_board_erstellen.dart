import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:familien_suche/pages/informationen/bulletin_board/bulletin_board_details.dart';
import 'package:familien_suche/services/database.dart';
import 'package:familien_suche/widgets/custom_appbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../../../functions/translation.dart';
import '../../../functions/upload_and_save_image.dart';
import '../../../global/custom_widgets.dart';
import '../../../widgets/dialogWindow.dart';
import '../../../widgets/google_autocomplete.dart';
import 'package:familien_suche/global/global_functions.dart' as global_func;

class BulletonBoardCreate extends StatefulWidget {
  const BulletonBoardCreate({Key? key});

  @override
  State<BulletonBoardCreate> createState() => _BulletonBoardCreateState();
}

class _BulletonBoardCreateState extends State<BulletonBoardCreate> {
  bool isCreating = true;
  TextEditingController titleKontroller = TextEditingController();
  TextEditingController descriptionKontroller = TextEditingController();
  var ortAuswahlBox = GoogleAutoComplete(
      margin: const EdgeInsets.only(top: 5, bottom: 5, left: 30, right: 30),
      withOwnLocation: true,withWorldwideLocation: true);
  List images = [null, null, null, null];

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

  saveNote() {
    String userId = Hive.box("secureBox").get("ownProfil")["id"];
    bool allFilled = checkValidation();
    List uploadedImages = images.whereType<String>().toList();

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

    saveInDB(newNote);

    var allBulletinBoardNotes =
        Hive.box('secureBox').get("bulletinBoardNotes") ?? [];
    allBulletinBoardNotes.add(newNote);

    return newNote;
  }

  saveInDB(newNote) async {
    var titleTranslationData = await translation(titleKontroller.text);
    var descriptionTranslationData = await translation(descriptionKontroller.text, withTranslationNotice: true);

    newNote["titleGer"] = titleTranslationData["ger"];
    newNote["titleEng"] = titleTranslationData["eng"];
    newNote["beschreibungGer"] = descriptionTranslationData["ger"];
    newNote["beschreibungEng"] = descriptionTranslationData["eng"];

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

  uploadImage() async {
    var imageList =
        await uploadAndSaveImage(context, "notes", folder: "notes/");

    for (var i = 0; i < images.length; i++) {
      if (images[i] == null) {
        images[i] = imageList[0];
        break;
      }
    }

    setState(() {});
  }

  deleteImage(index) {
    DbDeleteImage(images[index]);

    setState(() {
      images[index] = null;
    });


  }

  imageFullscreen(image) {
    showDialog(
        context: context,
        builder: (BuildContext buildContext) {
          return CustomAlertDialog(
            windowPadding: const EdgeInsets.all(30),
            children: [CachedNetworkImage(imageUrl: image,)],
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    ortAuswahlBox.hintText = "Ort Eingeben";

    setTitle() {
      return Center(
          child: Container(
              margin: const EdgeInsets.only(left: 20, right: 20, top: 5, bottom: 5),
              child: customTextInput("Titel einfügen", titleKontroller,
                  maxLength: 45)));
    }

    setLocation() {
      return ortAuswahlBox;
    }

    setDescription() {
      return Center(
          child: Container(
              width: 700,
              margin: const EdgeInsets.only(left: 20, right: 20, top: 5, bottom: 5),
              child: customTextInput(
                  "Beschreibung einfügen", descriptionKontroller,
                  moreLines: 12, maxLength: 650, textInputAction: TextInputAction.newline)));
    }

    setImages() {
      List<Widget> imageWidgets = [];

      images.asMap().forEach((index, value) {
        imageWidgets.add(InkWell(
          onTap: value == null
              ? () => uploadImage()
              : () => imageFullscreen(value),
          child: Stack(
            children: [
              Container(
                margin: const EdgeInsets.all(5),
                width: 80,
                height: 80,
                decoration:
                    BoxDecoration(border: Border.all(), color: Colors.white),
                child: value == null
                    ? IconButton(
                        onPressed: () => uploadImage(),
                        icon: const Icon(Icons.upload))
                    : CachedNetworkImage(imageUrl: value,),
              ),
              if (value != null)
                Positioned(
                  top: 0,
                  right: 0,
                  child: InkWell(
                    onTap: () => deleteImage(index),
                    child: const CircleAvatar(
                        radius: 12.0,
                        backgroundColor: Colors.red,
                        child:
                            Icon(Icons.close, color: Colors.white, size: 18)),
                  ),
                )
            ],
          ),
        ));
      });

      return Container(
        margin: const EdgeInsets.all(5),
        child: Wrap(children: imageWidgets),
      );
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: CustomAppBar(
        title: "Notiz erstellen",
        buttons: [
          IconButton(
              onPressed: () {
                Map? newNote = saveNote();
                if(newNote == null) return;

                Navigator.pop(context);
                global_func.changePage(
                    context, BulletinBoardDetails(note: newNote));
              },
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
                  setImages()
                ]
        ),
      ),
    );
  }
}
