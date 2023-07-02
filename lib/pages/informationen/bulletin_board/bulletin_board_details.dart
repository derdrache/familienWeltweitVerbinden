import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:familien_suche/functions/user_speaks_german.dart';
import 'package:familien_suche/global/global_functions.dart';
import 'package:familien_suche/pages/chat/chat_details.dart';
import 'package:familien_suche/pages/informationen/location/location_Information.dart';
import 'package:familien_suche/pages/show_profil.dart';
import 'package:familien_suche/services/database.dart';
import 'package:familien_suche/widgets/custom_appbar.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../../functions/translation.dart';
import '../../../functions/upload_and_save_image.dart';
import '../../../global/custom_widgets.dart';
import '../../../widgets/dialogWindow.dart';
import '../../../widgets/google_autocomplete.dart';

class BulletinBoardDetails extends StatefulWidget {
  Map note;

  BulletinBoardDetails({Key? key, required this.note});

  @override
  State<BulletinBoardDetails> createState() => _BulletinBoardDetailsState();
}

class _BulletinBoardDetailsState extends State<BulletinBoardDetails> {
  var ownProfil = Hive.box("secureBox").get("ownProfil");
  String systemLanguage =
      WidgetsBinding.instance.platformDispatcher.locales[0].languageCode;
  bool changeNote = false;
  late TextEditingController titleKontroller;
  late var ortAuswahlBox;
  late TextEditingController descriptionKontroller;
  late List noteImages;
  late bool isNoteOwner = false;

  updateNote() {
    saveTitle();
    saveLocation();
    saveDescription();
    saveImages();
  }

  saveTitle() {
    String newTitle = titleKontroller.text;

    if (newTitle.isEmpty ||
        newTitle == widget.note["titleGer"] ||
        newTitle == widget.note["titleEng"]) return;

    widget.note["titleGer"] = newTitle;
    widget.note["titleEng"] = newTitle;

    saveTitleDB(newTitle);
  }

  saveTitleDB(newTitle) async {
    var translationData = await translation(newTitle);
    String newTitleGer = translationData["ger"].replaceAll("'", "''");
    String newTitleEng = translationData["eng"].replaceAll("'", "''");

    BulletinBoardDatabase().update(
        "titleGer = '$newTitleGer', titleEng = '$newTitleEng'",
        "WHERE id = '${widget.note["id"]}'");
  }

  saveLocation() {
    Map newLocation = ortAuswahlBox.getGoogleLocationData();

    if (newLocation["city"] == null ||
        newLocation["city"] == widget.note["location"]["city"]) return;

    widget.note["location"] = newLocation;

    BulletinBoardDatabase().update("location = '${json.encode(newLocation)}'",
        "WHERE id = '${widget.note["id"]}'");
  }

  saveDescription() {
    String newDescription = descriptionKontroller.text;

    if (newDescription.isEmpty ||
        newDescription == widget.note["titleGer"] ||
        newDescription == widget.note["titleEng"]) return;

    widget.note["beschreibungGer"] = newDescription;
    widget.note["beschreibungEng"] = newDescription;

    saveDescriptionDB(newDescription);
  }

  saveDescriptionDB(newDescription) async {
    var translationData = await translation(newDescription);
    String newDescriptionGer = translationData["ger"].replaceAll("'", "''");
    String newDescriptionEng = translationData["eng"].replaceAll("'", "''");

    BulletinBoardDatabase().update(
        "beschreibungGer = '$newDescriptionGer', beschreibungEng = '$newDescriptionEng'",
        "WHERE id = '${widget.note["id"]}'");
  }

  saveImages() {
    List uploadedImages = noteImages.whereType<String>().toList();

    widget.note["bilder"] = uploadedImages;

    BulletinBoardDatabase().update("bilder = '${json.encode(uploadedImages)}'",
        "WHERE id = '${widget.note["id"]}'");
  }

  uploadImage() async {
    var imageList =
        await uploadAndSaveImage(context, "notes", folder: "notes/");

    for (var i = 0; i < widget.note["images"].length; i++) {
      if (widget.note["images"][i] == null) {
        widget.note["images"][i] = imageList[0];
        break;
      }
    }

    setState(() {});
  }

  deleteImage(image) {
    DbDeleteImage(image);

    widget.note["bilder"].removeWhere((element) => element == image);
  }

  deleteNote() {
    BulletinBoardDatabase().delete(widget.note["id"]);
    var allBulletinNotes = Hive.box('secureBox').get("bulletinBoardNotes");
    allBulletinNotes.removeWhere((note) => note["id"] == widget.note["id"]);

    for (var image in widget.note["bilder"]) {
      DbDeleteImage(image);
    }
  }

  @override
  Widget build(BuildContext context) {
    isNoteOwner = ownProfil["id"] == widget.note["erstelltVon"];
    bool noteLanguageGerman = widget.note["beschreibungGer"]
        .contains("Dies ist eine automatische Übersetzung");
    bool userSpeakGerman = getUserSpeaksGerman();
    bool userSpeakEnglish = ownProfil["sprachen"].contains("Englisch") ||
        ownProfil["sprachen"].contains("english") ||
        systemLanguage == "en";

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

    showTitle() {
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

      titleKontroller = TextEditingController(text: title);

      return Container(
          margin:
              const EdgeInsets.only(top: 10, bottom: 10, right: 20, left: 20),
          child: !changeNote
              ? Text(
                  title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 22),
                )
              : customTextInput("", titleKontroller, maxLength: 45));
    }

    showLocation() {
      String hintText = widget.note["location"]["city"];
      if (widget.note["location"]["city"] !=
          widget.note["location"]["countryname"]) {
        hintText += " / " + widget.note["location"]["countryname"];
      }
      bool isWorldwide = widget.note["location"]["city"] ==
          AppLocalizations.of(context)!.weltweit;

      ortAuswahlBox = GoogleAutoComplete(
        margin: const EdgeInsets.only(left: 10, right: 10),
        withOwnLocation: true,
        hintText: hintText,
      );

      return Container(
        margin: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 10),
        child: !changeNote
            ? Row(
                children: [
                  Text("${AppLocalizations.of(context)!.ort} ",
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  InkWell(
                    onTap: isWorldwide
                        ? null
                        : () => changePage(
                            context,
                            LocationInformationPage(
                              ortName: widget.note["location"]["city"],
                            )),
                    child: isWorldwide
                        ? Text(hintText)
                        : Text(
                            hintText,
                            style:
                                TextStyle(decoration: TextDecoration.underline),
                          ),
                  )
                ],
              )
            : ortAuswahlBox,
      );
    }

    showDescription() {
      String description;

      if (noteLanguageGerman && userSpeakGerman) {
        description = widget.note["beschreibungGer"];
      } else if (!noteLanguageGerman && userSpeakEnglish) {
        description = widget.note["beschreibungEng"];
      } else if (userSpeakGerman) {
        description = widget.note["beschreibungGer"];
      } else {
        description = widget.note["beschreibungEng"];
      }

      descriptionKontroller = TextEditingController(text: description);

      return Container(
          margin:
              const EdgeInsets.only(top: 15, left: 20, right: 20, bottom: 10),
          child: !changeNote
              ? Align(alignment: Alignment.topLeft, child: Text(description))
              : Column(
                  children: [
                    customTextInput("", descriptionKontroller,
                        moreLines: 10,
                        maxLength: 650,
                        textInputAction: TextInputAction.newline),
                  ],
                ));
    }

    showImages() {
      noteImages = List.of(widget.note["bilder"]);

      if (changeNote) {
        int NumberImages = noteImages.length;

        for (var i = NumberImages; i < 4; i++) {
          noteImages.add(null);
        }
      }

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
                          decoration: BoxDecoration(
                              border: Border.all(), color: Colors.white),
                          child: image != null
                              ? CachedNetworkImage(imageUrl: image,)
                              : IconButton(
                                  onPressed: () => uploadImage(),
                                  icon: const Icon(Icons.upload)),
                        ),
                        if (image != null && changeNote)
                          Positioned(
                            top: 0,
                            right: 0,
                            child: InkWell(
                              onTap: () {
                                deleteImage(image);
                                setState(() {});
                              },
                              child: const CircleAvatar(
                                  radius: 12.0,
                                  backgroundColor: Colors.red,
                                  child: Icon(Icons.close,
                                      color: Colors.white, size: 18)),
                            ),
                          )
                      ],
                    ),
                  ))
              .toList(),
        ),
      );
    }

    deleteWindow() {
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return CustomAlertDialog(
              title: AppLocalizations.of(context)!.bulletinNoteLoeschen,
              height: 120,
              actions: [
                TextButton(
                  child: const Text("Ok"),
                  onPressed: () async {
                    deleteNote();
                    Navigator.pop(context);
                  },
                ),
                TextButton(
                  child: Text(AppLocalizations.of(context)!.abbrechen),
                  onPressed: () => Navigator.pop(context),
                )
              ],
              children: [
                Center(
                    child: Text(AppLocalizations.of(context)!
                        .communityWirklichLoeschen))
              ],
            );
          });
    }

    return Scaffold(
      appBar: CustomAppBar(
        title: AppLocalizations.of(context)!.note,
        buttons: [
          if (!isNoteOwner)
            IconButton(
                onPressed: () => changePage(
                    context,
                    ShowProfilPage(
                        profil: getProfilFromHive(
                            profilId: widget.note["erstelltVon"]))),
                icon: Icon(Icons.account_circle)),
          if (!isNoteOwner)
            IconButton(
                onPressed: () => changePage(
                    context,
                    ChatDetailsPage(
                      chatPartnerId: widget.note["erstelltVon"],
                    )),
                icon: Icon(Icons.chat)),
          if (!changeNote && isNoteOwner)
            IconButton(
                onPressed: () => setState(() {
                      changeNote = true;
                    }),
                icon: Icon(Icons.edit)),
          if (changeNote && isNoteOwner)
            IconButton(
                onPressed: () {
                  updateNote();
                  setState(() {
                    changeNote = false;
                  });
                },
                icon: Icon(Icons.done)),
          IconButton(
              onPressed: () {
                deleteWindow();
              },
              icon: Icon(Icons.delete))
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
            showTitle(),
            showLocation(),
            Expanded(child: showDescription()),
            showImages()
          ],
        ),
      ),
    );
  }
}