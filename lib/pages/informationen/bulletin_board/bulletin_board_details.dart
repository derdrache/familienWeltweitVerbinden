import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:familien_suche/global/style.dart';
import 'package:familien_suche/widgets/strike_through_icon.dart';
import 'package:familien_suche/widgets/windowConfirmCancelBar.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../../functions/translation.dart';
import '../../../functions/upload_and_save_image.dart';
import '../../../functions/user_speaks_german.dart';
import '../../../global/global_functions.dart';
import '../../../services/database.dart';
import '../../../widgets/automatic_translation_notice.dart';
import '../../../widgets/custom_appbar.dart';
import '../../../widgets/layout/ownIconButton.dart';
import '../../../windows/custom_popup_menu.dart';
import '../../../windows/dialog_window.dart';
import '../../../widgets/google_autocomplete.dart';
import '../../../widgets/layout/custom_text_input.dart';
import '../../../windows/image_fullscreen.dart';
import '../../chat/chat_details.dart';
import '../../show_profil.dart';
import '../../start_page.dart';
import '../location/location_details/information_main.dart';
import 'bulletin_board_page.dart';

class BulletinBoardDetails extends StatefulWidget {
  final Map note;

  const BulletinBoardDetails({Key? key, required this.note}) : super(key: key);

  @override
  State<BulletinBoardDetails> createState() => _BulletinBoardDetailsState();
}

class _BulletinBoardDetailsState extends State<BulletinBoardDetails> {
  var ownProfil = Hive.box("secureBox").get("ownProfil");
  String systemLanguage =
      WidgetsBinding.instance.platformDispatcher.locales[0].languageCode;
  bool changeNote = false;
  late TextEditingController titleKontroller;
  late GoogleAutoComplete ortAuswahlBox;
  late TextEditingController descriptionKontroller;
  late List noteImages;
  late bool isNoteOwner = false;
  late bool showOriginalText = false;
  late bool showOnlyOriginal = false;
  late Map originalText = {"title": "", "description": ""};
  late Map translatedText = {"title": "", "description": ""};
  late Map? creatorProfil;

  checkAndSetTextVariations() {
    bool noteLanguageGerman = widget.note["sprache"] == "de";
    bool userSpeakGerman = getUserSpeaksGerman();
    bool userSpeakEnglish = ownProfil["sprachen"].contains("Englisch") ||
        ownProfil["sprachen"].contains("english") ||
        systemLanguage == "en";
    bool bothGerman = noteLanguageGerman && userSpeakGerman;
    bool bothEnglish = !noteLanguageGerman && userSpeakEnglish;

    if (bothGerman || bothEnglish || isNoteOwner) {
      showOriginalText = true;
      showOnlyOriginal = true;
    }

    if (noteLanguageGerman) {
      originalText["title"] = widget.note["titleGer"];
      originalText["description"] = widget.note["beschreibungGer"];
      translatedText["title"] = widget.note["titleEng"];
      translatedText["description"] = widget.note["beschreibungEng"];
    } else {
      originalText["title"] = widget.note["titleEng"];
      originalText["description"] = widget.note["beschreibungEng"];
      translatedText["title"] = widget.note["titleGer"];
      translatedText["description"] = widget.note["beschreibungGer"];
    }
  }

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

    widget.note["bilder"].add(imageList[0]);

    setState(() {});
  }

  deleteImage(image) {
    dbDeleteImage(image);

    widget.note["bilder"].removeWhere((element) => element == image);
  }

  deleteNote() {
    BulletinBoardDatabase().delete(widget.note["id"]);
    var allBulletinNotes = Hive.box('secureBox').get("bulletinBoardNotes");
    allBulletinNotes.removeWhere((note) => note["id"] == widget.note["id"]);

    for (var image in widget.note["bilder"]) {
      dbDeleteImage(image);
    }
  }

  changeNoteLanguage() {
    setState(() {
      showOriginalText = !showOriginalText;
    });
  }

  @override
  void initState() {
    isNoteOwner = ownProfil["id"] == widget.note["erstelltVon"];
    creatorProfil =
        getProfilFromHive(profilId: widget.note["erstelltVon"]) ?? {};

    checkAndSetTextVariations();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    showTitle() {
      String title;

      if (showOriginalText) {
        title = originalText["title"];
      } else {
        title = translatedText["title"];
      }

      titleKontroller = TextEditingController(text: title);

      return Container(
          margin:
              const EdgeInsets.only(top: 10, bottom: 10, right: 20, left: 20),
          child: !changeNote
              ? Text(
                  title,
                  style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 22),
                )
              : CustomTextInput("", titleKontroller, maxLength: 45));
    }

    showLocation() {
      String locationText = widget.note["location"]["city"];
      if (widget.note["location"]["city"] !=
          widget.note["location"]["countryname"]) {
        locationText += " / ${widget.note["location"]["countryname"]}";
      }
      bool isWorldwide = widget.note["location"]["city"] == "worldwide" ||
          widget.note["location"]["city"] == "Weltweit";
      ortAuswahlBox = GoogleAutoComplete(
        margin: const EdgeInsets.only(left: 10, right: 10),
        withOwnLocation: true,
        withWorldwideLocation: true,
        hintText: locationText,
      );

      return Container(
        margin: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 10),
        child: !changeNote
            ? Row(
                children: [
                  Text("${AppLocalizations.of(context)!.ort} ",
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.black)),
                  InkWell(
                    onTap: isWorldwide
                        ? null
                        : () => changePage(
                            context,
                            LocationInformationPage(
                              ortName: widget.note["location"]["city"],
                              ortLatt: widget.note["location"]["latt"],
                            )),
                    child: Text(
                      locationText,
                      style: TextStyle(
                          color: Colors.black,
                          decoration:
                              isWorldwide ? null : TextDecoration.underline),
                    ),
                  )
                ],
              )
            : ortAuswahlBox,
      );
    }

    showDescription() {
      String description;

      if (showOriginalText) {
        description = originalText["description"];
      } else {
        description = translatedText["description"];
      }

      descriptionKontroller = TextEditingController(text: description);

      return Container(
          margin:
              const EdgeInsets.only(top: 15, left: 20, right: 20, bottom: 10),
          child: !changeNote
              ? Align(
                  alignment: Alignment.topLeft,
                  child: Text(
                    description,
                    style: const TextStyle(color: Colors.black),
                  ))
              : Column(
                  children: [
                    CustomTextInput("", descriptionKontroller,
                        moreLines: 10,
                        maxLength: 650,
                        textInputAction: TextInputAction.newline),
                  ],
                ));
    }

    showImages() {
      noteImages = List.of(widget.note["bilder"]);

      if (changeNote) {
        int numberImages = noteImages.length;

        for (var i = numberImages; i < 4; i++) {
          noteImages.add(null);
        }
      }

      if(noteImages.isEmpty) return SizedBox.shrink();

      return Container(
        margin: const EdgeInsets.only(left: 0, right: 0, top: 20, bottom: 10),
        child: Wrap(
          children: noteImages
              .map<Widget>((image) => InkWell(
                    onTap: () => ImageFullscreen(context, image),
                    child: Stack(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          margin: const EdgeInsets.all(5),
                          child: Card(
                            elevation: 12,
                            child: image != null
                                ? CachedNetworkImage(
                                    imageUrl: image,
                                  )
                                : IconButton(
                                    onPressed: () => uploadImage(),
                                    icon: const Icon(Icons.upload)),
                          ),
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

    bottomBar() {
      return Center(
        child: Container(
          margin: const EdgeInsets.all(10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              InkWell(
                  onTap: () {
                    if (creatorProfil!.isEmpty) return;
                    changePage(context, ShowProfilPage(profil: creatorProfil!));
                  },
                  child: Text(
                      creatorProfil!["name"] ??
                          AppLocalizations.of(context)!.geloeschterUser,
                      style: TextStyle(
                        color: creatorProfil!["name"] != null
                            ? Theme.of(context).colorScheme.secondary
                            : Colors.red,
                      )))
            ],
          ),
        ),
      );
    }

    deleteWindow() {
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return CustomAlertDialog(
              title: AppLocalizations.of(context)!.bulletinNoteLoeschen,
              children: [
                Center(
                    child: Text(AppLocalizations.of(context)!
                        .communityWirklichLoeschen)),
                WindowConfirmCancelBar(
                  confirmTitle:
                      AppLocalizations.of(context)!.bulletinNoteLoeschen,
                  onConfirm: () async {
                    deleteNote();
                    changePage(
                        context,
                        StartPage(
                          selectedIndex: 2,
                        ));
                    changePage(context, const BulletinBoardPage());
                  },
                )
              ],
            );
          });
    }

    changeLanguageDialog() {
      return SimpleDialogOption(
        child: Row(
          children: [
            showOriginalText ?  Icon(Icons.translate ): StrikeThroughIcon(child: Icon(Icons.translate)),
            SizedBox(width: 10),
            Text(AppLocalizations.of(context)!.tooltipSpracheWechseln),
          ],
        ),
        onPressed: () {
          Navigator.pop(context);
          changeNoteLanguage();
        },
      );
    }

    reportNoteWindow() {
      TextEditingController reportController = TextEditingController();

      showDialog(
          context: context,
          builder: (BuildContext buildContext) {
            return CustomAlertDialog(
                title: AppLocalizations.of(context)!.noteMelden,
                children: [
                  CustomTextInput(
                      AppLocalizations.of(context)!.noteMeldenFrage,
                      reportController,
                      moreLines: 10),
                  Container(
                    margin: const EdgeInsets.only(left: 30, top: 10, right: 30),
                    child: FloatingActionButton.extended(
                        onPressed: () {
                          Navigator.pop(context);
                          ReportsDatabase().add(
                              userId,
                              "Melde Note id: ${widget.note["id"]}",
                              reportController.text);
                        },
                        label: Text(AppLocalizations.of(context)!.senden)),
                  )
                ]);
          });
    }

    reportNoteDialog(){
      return SimpleDialogOption(
        child: Row(
          children: [
            const Icon(Icons.report),
            SizedBox(width: 10),
            Text(AppLocalizations.of(context)!.melden),
          ],
        ),
        onPressed: (){
          Navigator.pop(context);
          reportNoteWindow();
        }
      );
    }

    changeNoteDialog() {
      return SimpleDialogOption(
        child: Row(
          children: [
            const Icon(Icons.edit),
            SizedBox(width: 10),
            Text(AppLocalizations.of(context)!.tooltipNotizBearbeiten),
          ],
        ),
        onPressed: () => setState(() {
          changeNote = true;
        }),
      );
    }

    deleteNoteDialog(){
      return SimpleDialogOption(
        child: Row(
          children: [
            const Icon(Icons.done),
            SizedBox(width: 10),
            Text(AppLocalizations.of(context)!.loeschen),
          ],
        ),
          onPressed: () {
            deleteWindow();
          }
      );
    }

    moreMenu() {
      CustomPopupMenu(context, children: [
        if (!showOnlyOriginal) changeLanguageDialog(),
        if (!changeNote && isNoteOwner) changeNoteDialog(),
        if (!isNoteOwner) reportNoteDialog(),
        if (isNoteOwner) deleteNoteDialog()
      ]);
    }



    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: CustomAppBar(
        title: AppLocalizations.of(context)!.note,
        buttons: [
          OwnIconButton(
            icon: Icons.more_vert,
            tooltipText: AppLocalizations.of(context)!.tooltipMehrOptionen,
            onPressed: () => moreMenu(),
          ),
          if (changeNote && isNoteOwner)
            IconButton(
                onPressed: () {
                  updateNote();
                  setState(() {
                    changeNote = false;
                  });
                },
                tooltip:
                    AppLocalizations.of(context)!.tooltipEingabeBestaetigen,
                icon: const Icon(Icons.done)),
        ],
      ),
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(20),
          width: webWidth,
          decoration: BoxDecoration(
              color: Colors.yellow[200],
              border: Border.all(),
              borderRadius: BorderRadius.circular(4)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              showTitle(),
              showLocation(),
              showDescription(),
              AutomaticTranslationNotice(
                translated: !showOriginalText,
              ),
              const SizedBox(height: 20),
              showImages(),
              bottomBar()
            ],
          ),
        ),
      ),
    );
  }
}
