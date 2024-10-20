import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:familien_suche/widgets/windowConfirmCancelBar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:translator/translator.dart';
import 'package:carousel_slider/carousel_slider.dart';

import '../../../../global/global_functions.dart' as global_func;
import '../../../../global/style.dart' as style;
import '../../../../functions/user_speaks_german.dart';
import '../../../../global/style.dart';
import '../../../../services/database.dart';
import '../../../../widgets/automatic_translation_notice.dart';
import '../../../../widgets/image_upload_box.dart';
import '../../../../widgets/layout/custom_snackbar.dart';
import '../../../../widgets/layout/custom_text_input.dart';
import '../../../../widgets/text_with_hyperlink_detection.dart';
import '../../../../windows/custom_popup_menu.dart';
import '../../../../windows/dialog_window.dart';
import '../../../../windows/image_fullscreen.dart';
import '../../../show_profil.dart';

class InsiderInformationPage extends StatefulWidget {
  final Map location;
  final int? insiderInfoId;

  const InsiderInformationPage(
      {Key? key, required this.location, this.insiderInfoId})
      : super(key: key);

  @override
  State<InsiderInformationPage> createState() => _InsiderInformationPageState();
}

class _InsiderInformationPageState extends State<InsiderInformationPage> {
  final String userId = FirebaseAuth.instance.currentUser!.uid;
  final translator = GoogleTranslator();
  late List usersCityInformation;
  late List usersCityInformationOriginal = [];
  String systemLanguage =
      WidgetsBinding.instance.platformDispatcher.locales[0].languageCode;
  late bool userSpeakGerman;
  int initalPage = 0;
  CarouselSliderController carouselController = CarouselSliderController();
  DateTime now = DateTime.now();
  DateFormat formatter = DateFormat('yyyy-MM-dd');


  @override
  void initState() {
    userSpeakGerman = getUserSpeaksGerman();
    usersCityInformation = getCityUserInfoFromHive(widget.location["ort"]);
    usersCityInformation = sortInformation(usersCityInformation);
    usersCityInformation.asMap().forEach((index, element) {
      if (element["id"] == widget.insiderInfoId) {
        initalPage = index;
      }
      usersCityInformationOriginal.add(null);
    });

    super.initState();
  }

  addInformationWindow() {
    var titleTextKontroller = TextEditingController();
    var informationTextKontroller = TextEditingController();
    var imageUploadBox = ImageUploadBox(
      imageKategorie: "information",
    );

    showDialog(
        context: context,
        builder: (BuildContext buildContext) {
          return CustomAlertDialog(
              title:
                  AppLocalizations.of(context)!.insiderInformationHinzufuegen,
              children: [
                CustomTextInput(
                  AppLocalizations.of(context)!.titel,
                  titleTextKontroller,
                  hintText: AppLocalizations.of(context)!.titelEingeben,
                ),
                const SizedBox(height: 10),
                CustomTextInput(
                  AppLocalizations.of(context)!.beschreibung,
                  informationTextKontroller,
                  moreLines: 7,
                  textInputAction: TextInputAction.newline,
                  hintText: AppLocalizations.of(context)!.beschreibungEingeben,
                ),
                const SizedBox(height: 5),
                imageUploadBox,
                WindowConfirmCancelBar(
                    confirmTitle: AppLocalizations.of(context)!.speichern,
                    onConfirm: () {
                      Navigator.pop(context);
                      saveNewInformation(
                          title: titleTextKontroller.text,
                          inhalt: informationTextKontroller.text,
                          images: imageUploadBox.getImages());
                    }),
                const SizedBox(height: 20)
              ]);
        });
  }

  saveNewInformation({title, inhalt, images}) async {
    String titleGer, informationGer, titleEng, informationEng;

    if (title.isEmpty) {
      customSnackBar(
          context, AppLocalizations.of(context)!.titelStadtinformationEingeben);
      return;
    } else if (title.length > 100) {
      customSnackBar(context, AppLocalizations.of(context)!.titleZuLang);
      return;
    } else if (title.isEmpty) {
      customSnackBar(context,
          AppLocalizations.of(context)!.beschreibungStadtinformationEingeben);
      return;
    }

    Map newUserInformation = {
      "id": -1,
      "locationId": widget.location["id"],
      "ort": widget.location["ort"],
      "sprache": "auto",
      "titleGer": title,
      "informationGer": inhalt,
      "titleEng": title,
      "informationEng": inhalt,
      "erstelltAm": formatter.format(now),
      "erstelltVon": userId,
      "thumbUp": [],
      "thumbDown": [],
      "images": images
    };

    setState(() {
      usersCityInformation.add(newUserInformation);
      initalPage = usersCityInformation.length - 1;
      usersCityInformationOriginal.add(null);
    });

    carouselController.jumpToPage(usersCityInformation.length - 1);

    var languageCheck = await translator.translate(inhalt);
    var languageCode = languageCheck.sourceLanguage.code;
    if (languageCode == "auto") languageCode = "en";

    if (languageCode == "en") {
      titleEng = title;
      informationEng = inhalt;
      var titleTranslation =
          await translator.translate(title, from: "en", to: "de");
      titleGer = titleTranslation.toString();
      var informationTranslation =
          await translator.translate(inhalt, from: "en", to: "de");
      informationGer = informationTranslation.toString();
    } else {
      titleGer = title;
      informationGer = inhalt;
      titleEng = "";
      informationEng = "";
      var titleTranslation =
          await translator.translate(title, from: "de", to: "en");
      titleEng = titleTranslation.toString();
      var informationTranslation =
          await translator.translate(inhalt, from: "de", to: "en");
      informationEng = informationTranslation.toString();
    }

    newUserInformation["sprache"] = languageCode;
    newUserInformation["titleGer"] = titleGer;
    newUserInformation["informationGer"] = informationGer;
    newUserInformation["titleEng"] = titleEng;
    newUserInformation["informationEng"] = informationEng;

    var secureBox = Hive.box("secureBox");
    var allInformations = secureBox.get("stadtinfoUser");
    allInformations.add(newUserInformation);
    secureBox.put("stadtinfoUser", allInformations);

    StadtinfoUserDatabase().addNewInformation(Map.of(newUserInformation));
  }

  setThumbUp(index) {
    var infoId = usersCityInformation[index]["id"];

    if (usersCityInformation[index]["thumbUp"].contains(userId)) {
      usersCityInformation[index]["thumbUp"].remove(userId);

      StadtinfoUserDatabase().update(
          "thumbUp = JSON_REMOVE(thumbUp, JSON_UNQUOTE(JSON_SEARCH(thumbUp, 'one', '$userId')))",
          "WHERE id ='$infoId'");
    } else {
      bool hasThumbDown =
          usersCityInformation[index]["thumbDown"].contains(userId);
      usersCityInformation[index]["thumbUp"].add(userId);
      usersCityInformation[index]["thumbDown"].remove(userId);
      String sqlStatement =
          "thumbUp = JSON_ARRAY_APPEND(thumbUp, '\$', '$userId')";
      if (hasThumbDown) {
        sqlStatement +=
            ",thumbDown = JSON_REMOVE(thumbDown, JSON_UNQUOTE(JSON_SEARCH(thumbDown, 'one', '$userId')))";
      }

      StadtinfoUserDatabase().update(sqlStatement, "WHERE id ='$infoId'");
    }
    setState(() {});
  }

  setThumbDown(index) {
    var infoId = usersCityInformation[index]["id"];

    if (usersCityInformation[index]["thumbDown"].contains(userId)) {
      usersCityInformation[index]["thumbDown"].remove(userId);

      StadtinfoUserDatabase().update(
          "thumbDown = JSON_REMOVE(thumbDown, JSON_UNQUOTE(JSON_SEARCH(thumbDown, 'one', '$userId')))",
          "WHERE id ='$infoId'");
    } else {
      usersCityInformation[index]["thumbDown"].add(userId);
      usersCityInformation[index]["thumbUp"].remove(userId);

      StadtinfoUserDatabase().update(
          "thumbUp = JSON_REMOVE(thumbUp, JSON_UNQUOTE(JSON_SEARCH(thumbUp, 'one', '$userId'))), thumbDown = JSON_ARRAY_APPEND(thumbDown, '\$', '$userId')",
          "WHERE id ='$infoId'");
    }

    setState(() {});
  }

  sortInformation(data) {
    data.sort((a, b) => (b["thumbUp"].length - b["thumbDown"].length)
        .compareTo(a["thumbUp"].length - a["thumbDown"].length) as int);
    return data;
  }

  changeInformationDialog(information, index) {
    var informationData = getInsiderInfoText(information, index);
    var titleTextKontroller =
        TextEditingController(text: informationData["title"]);
    var informationTextKontroller =
        TextEditingController(text: informationData["information"]);
    var imageUploadBox = ImageUploadBox(
      uploadedImages: information["images"],
      imageKategorie: "information",
    );

    Future<void>.delayed(
        const Duration(),
        () => showDialog(
            context: context,
            builder: (BuildContext buildContext) {
              return CustomAlertDialog(
                  title: AppLocalizations.of(context)!.informationAendern,
                  children: [
                    CustomTextInput(AppLocalizations.of(context)!.titel,
                        titleTextKontroller),
                    const SizedBox(height: 10),
                    CustomTextInput(AppLocalizations.of(context)!.beschreibung,
                        informationTextKontroller,
                        moreLines: 12,
                        textInputAction: TextInputAction.newline),
                    const SizedBox(height: 5),
                    imageUploadBox,
                    const SizedBox(height: 5),
                    WindowConfirmCancelBar(
                      confirmTitle: AppLocalizations.of(context)!.speichern,
                      onConfirm: () {
                        Navigator.pop(context);
                        changeInsiderInformation(
                          id: information["id"],
                          newTitle: titleTextKontroller.text,
                          images: imageUploadBox.getImages(),
                          newInformation: informationTextKontroller.text);
                      }),
                    const SizedBox(height: 20)
                  ]);
            }));
  }

  changeInsiderInformation({id, newTitle, newInformation, images}) async {
    newTitle = newTitle.trim();
    newInformation = newInformation.trim();

    if (newTitle.isEmpty) {
      customSnackBar(
          context, AppLocalizations.of(context)!.titelStadtinformationEingeben);
      return;
    } else if (newTitle.length > 100) {
      customSnackBar(context, AppLocalizations.of(context)!.titleZuLang);
      return;
    } else if (newInformation.isEmpty) {
      customSnackBar(context,
          AppLocalizations.of(context)!.beschreibungStadtinformationEingeben);
      return;
    }

    for (var i = 0; i < usersCityInformation.length; i++) {
      if (usersCityInformation[i]["id"] == id) {
        usersCityInformation[i]["titleGer"] = newTitle;
        usersCityInformation[i]["informationGer"] = newInformation;
        usersCityInformation[i]["titleEng"] = newTitle;
        usersCityInformation[i]["informationEng"] = newInformation;
        usersCityInformation[i]["images"] = images;
        usersCityInformation[i]["erstelltAm"] = formatter.format(now);
        break;
      }
    }

    updateDatabase(id, newTitle, newInformation, images);

    setState(() {});
  }

  updateDatabase(id, newTitle, newInformation, images) async {
    String titleGer, informationGer, titleEng, informationEng;

    var languageCheck = await translator.translate(newInformation);
    var languageCode = languageCheck.sourceLanguage.code;
    if (languageCode == "auto") languageCode = "en";

    if (languageCode == "en") {
      titleEng = newTitle;
      informationEng = newInformation;
      var titleTranslation =
          await translator.translate(newTitle, from: "en", to: "de");
      titleGer = titleTranslation.toString();
      var informationTranslation =
          await translator.translate(newInformation, from: "en", to: "de");
      informationGer = informationTranslation.toString();
    } else {
      titleGer = newTitle;
      informationGer = newInformation;
      titleEng = "";
      informationEng = "";
      var titleTranslation =
          await translator.translate(newTitle, from: "de", to: "en");
      titleEng = titleTranslation.toString();
      var informationTranslation =
          await translator.translate(newInformation, from: "de", to: "en");
      informationEng = informationTranslation.toString();
    }

    var secureBox = Hive.box("secureBox");
    var allInformations = secureBox.get("stadtinfoUser");

    for (var i = 0; i < allInformations.length; i++) {
      if (allInformations[i]["id"] == id) {
        allInformations[i]["sprache"] = languageCode;
        allInformations[i]["titleGer"] = titleGer;
        allInformations[i]["informationGer"] = informationGer;
        allInformations[i]["titleEng"] = titleEng;
        allInformations[i]["informationEng"] = informationEng;
        allInformations[i]["images"] = images;
        allInformations[i]["erstelltAm"] = formatter.format(now);
        break;
      }
    }
    secureBox.put("stadtinfoUser", allInformations);

    titleGer = titleGer.replaceAll("'", "''");
    informationGer = informationGer.replaceAll("'", "''");
    titleEng = titleEng.replaceAll("'", "''");
    informationEng = informationEng.replaceAll("'", "''");

    await StadtinfoUserDatabase().update(
        "sprache ='$languageCode',  "
            "titleGer = '$titleGer', "
            "informationGer = '$informationGer',"
            "titleEng = '$titleEng',"
            "informationEng = '$informationEng',"
            "images = '${jsonEncode(images)}',"
            "erstelltAm = '${formatter.format(now)}'",
        "WHERE id ='$id'");
  }

  copyInformationDialog(information) {
    var informationText = userSpeakGerman
        ? information["informationGer"]
        : information["informationGer"];

    Clipboard.setData(ClipboardData(text: informationText));

    customSnackBar(context, AppLocalizations.of(context)!.informationKopiert,
        color: Colors.green);
  }

  deleteInformationDialog(information) async {
    Future<void>.delayed(
        const Duration(),
        () => showDialog(
            context: context,
            builder: (BuildContext context) {
              return CustomAlertDialog(
                title: AppLocalizations.of(context)!.informationLoeschen,
                children: [
                  const SizedBox(height: 10),
                  Center(
                      child: Text(AppLocalizations.of(context)!
                          .informationWirklichLoeschen)),
                  WindowConfirmCancelBar(
                    onConfirm: () {
                      StadtinfoUserDatabase().delete(information["id"]);

                      var secureBox = Hive.box("secureBox");
                      var allInformations = secureBox.get("stadtinfoUser");
                      allInformations.remove(information);
                      secureBox.put("stadtinfoUser", allInformations);

                      setState(() {
                        usersCityInformation.remove(information);
                      });
                    },
                  )
                ],
              );
            }));
  }

  reportInformationDialog(information) {
    var reportTextKontroller = TextEditingController();

    Future<void>.delayed(
        const Duration(),
        () => showDialog(
            context: context,
            builder: (BuildContext buildContext) {
              return CustomAlertDialog(
                  title: AppLocalizations.of(context)!.informationMelden,
                  children: [
                    CustomTextInput("", reportTextKontroller,
                        moreLines: 10,
                        hintText: AppLocalizations.of(context)!
                            .informationMeldenFrage),
                    Container(
                      margin:
                          const EdgeInsets.only(left: 30, top: 10, right: 30),
                      child: FloatingActionButton.extended(
                          onPressed: () {
                            Navigator.pop(context);
                            ReportsDatabase().add(
                                userId,
                                "Melde Information id: ${information["id"]}",
                                reportTextKontroller.text);
                          },
                          label: Text(AppLocalizations.of(context)!.senden)),
                    )
                  ]);
            }));
  }

  getInsiderInfoText(information, index) {
    String showTitle = "";
    String showInformation = "";
    var ownlanguages = Hive.box("secureBox").get("ownProfil")["sprachen"];
    var informationLanguage = information["sprache"] == "de"
        ? ["Deutsch", "german"]
        : ["Englisch", "english"];

    bool canSpeakInformationLanguage =
        information["sprache"] == systemLanguage ||
            ownlanguages.contains(informationLanguage[0]) ||
            ownlanguages.contains(informationLanguage[1]);
    if (information["erstelltVon"] == userId) {
      usersCityInformationOriginal[index] = true;
    } else if (usersCityInformationOriginal[index] == null) {
      canSpeakInformationLanguage
          ? usersCityInformationOriginal[index] = true
          : usersCityInformationOriginal[index] = false;
    }

    if (information["titleGer"].isEmpty) {
      return {
        "title": information["titleEng"],
        "information": information["informationEng"],
        "translated": false,
        "speaksInformationLanguage": canSpeakInformationLanguage
      };
    }
    if (information["titleEng"].isEmpty) {
      return {
        "title": information["titleGer"],
        "information": information["informationGer"],
        "translated": false,
        "speaksInformationLanguage": canSpeakInformationLanguage
      };
    }

    String originalTitle = informationLanguage[0] == "Deutsch"
        ? information["titleGer"]
        : information["titleEng"];
    String originalInformation = informationLanguage[0] == "Deutsch"
        ? information["informationGer"]
        : information["informationEng"];
    String translationTitle = informationLanguage[0] == "Deutsch"
        ? information["titleEng"]
        : information["titleGer"];
    String translationInformation = informationLanguage[0] == "Deutsch"
        ? information["informationEng"]
        : information["informationGer"];

    if (usersCityInformationOriginal[index]) {
      showTitle = originalTitle;
      showInformation = originalInformation;
    } else {
      showTitle = translationTitle;
      showInformation = translationInformation;
    }

    return {
      "title": showTitle,
      "information": showInformation,
      "translated": !usersCityInformationOriginal[index],
      "speaksInformationLanguage": canSpeakInformationLanguage
    };
  }

  showOriginalInformation(index) {
    usersCityInformationOriginal[index] = !usersCityInformationOriginal[index];
  }

  @override
  Widget build(BuildContext context) {
    double viewportFraction = 1 - (MediaQuery. of(context). size. width / 250 * 0.1);

    openInformationMenu(information, index, positionDetails) async {
      bool canChange = information["erstelltVon"] == userId;
      usersCityInformation = getCityUserInfoFromHive(widget.location["ort"]);

      final offset = positionDetails.globalPosition;

      await showMenu(
          context: context,
          position: RelativeRect.fromLTRB(
            offset.dx,
            offset.dy,
            MediaQuery.of(context).size.width - offset.dx,
            MediaQuery.of(context).size.height - offset.dy,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(style.roundedCorners),
          ),
          items: [
            PopupMenuItem(
              child: Text(AppLocalizations.of(context)!.bearbeiten),
              onTap: () {
                changeInformationDialog(information, index);
              },
            ),
            PopupMenuItem(
              child: Text(AppLocalizations.of(context)!.kopieren),
              onTap: () {
                copyInformationDialog(information);
              },
            ),
            PopupMenuItem(
              child: Text(AppLocalizations.of(context)!.melden),
              onTap: () {
                reportInformationDialog(information);
              },
            ),
            if (canChange) PopupMenuItem(
              child: Text(AppLocalizations.of(context)!.loeschen),
              onTap: () {
                deleteInformationDialog(information);
              },
            ),
          ]);
    }

    insiderInfoBox(information, index) {
      information["index"] = index;
      Map informationText = getInsiderInfoText(information, index);
      String showTitle = informationText["title"];
      String showInformation = informationText["information"];
      bool translated = informationText["translated"];
      var creatorProfil =
          getProfilFromHive(profilId: information["erstelltVon"]);
      String creatorName = creatorProfil == null ? "" : creatorProfil["name"];
      List informationImages = information["images"];

      return Container(
        margin: const EdgeInsets.only(top: 20, bottom: 70, right: 5, left: 5),
        width: webWidth,
        child: Card(
          elevation: 15,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(style.roundedCorners),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 5, bottom: 20),
                width: double.infinity,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Padding(
                          padding: const EdgeInsets.only(left: 10, right: 10),
                          child: Text(
                            " #${index + 1} - $showTitle",
                            maxLines: 2,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18),
                          )),
                    ),
                    GestureDetector(
                      onTapDown: (details) => openInformationMenu(information, index, details),
                      //onTap: () => openInformationMenu(information, index),
                      child: const Icon(
                        Icons.more_horiz,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 5)
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(left: 10, right: 10),
                  child: SingleChildScrollView(
                    child: TextWithHyperlinkDetection(
                      text: showInformation,
                      fontsize: 16,
                    ),
                  ),
                ),
              ),
              AutomaticTranslationNotice(translated: translated),
              if (informationImages.isNotEmpty)
                Container(
                  alignment: Alignment.center,
                  margin: const EdgeInsets.all(10),
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 20,
                    runSpacing: 10,
                    children: [
                      for (var image in informationImages)
                        InkWell(
                          onTap: () => ImageFullscreen(context, image),
                          child: Card(
                            elevation: 12,
                            child: CachedNetworkImage(
                              imageUrl: image,
                              width: 110,
                              height: 100,
                            ),
                          ),
                        )
                    ],
                  ),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const SizedBox(width: 10,),
                  InkWell(
                    onTap: () => setThumbUp(index),
                    child: Container(
                      margin: const EdgeInsets.only(left: 5, right: 5),
                      child: Icon(
                        Icons.thumb_up_alt_outlined,
                        size: 24,
                        color: information["thumbUp"].contains(userId)
                            ? Colors.green
                            : Colors.grey,
                      ),
                    ),
                  ),
                  const SizedBox(width: 5,),
                  Text(
                    (information["thumbUp"].length -
                            information["thumbDown"].length)
                        .toString(),
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(width: 5,),
                  InkWell(
                    onTap: () => setThumbDown(index),
                    child: Container(
                      margin: const EdgeInsets.only(
                        left: 5,
                      ),
                      child: Icon(Icons.thumb_down_alt_outlined,
                          size: 24,
                          color: information["thumbDown"].contains(userId)
                              ? Colors.red
                              : Colors.grey),
                    ),
                  ),
                  Expanded(
                      child: Center(
                    child: information["erstelltVon"] != userId &&
                            !informationText["speaksInformationLanguage"]
                        ? TextButton(
                            style: TextButton.styleFrom(
                              shape: const StadiumBorder(),
                            ),
                            onPressed: () {
                              showOriginalInformation(index);
                              setState(() {});
                            },
                            child: Text(
                              "Original",
                              style: TextStyle(
                                  fontSize: 18,
                                  color:
                                      Theme.of(context).colorScheme.secondary,
                                  decoration: translated
                                      ? TextDecoration.lineThrough
                                      : null),
                            ))
                        : const SizedBox.shrink(),
                  )),
                  GestureDetector(
                    onTap: () => creatorProfil == null
                        ? null
                        : global_func.changePage(
                            context,
                            ShowProfilPage(
                              profil: creatorProfil,
                            )),
                    child: SizedBox(
                      width: 130,
                      child: Column(
                        children: [
                          if (creatorName.isNotEmpty)
                            Text(
                              "$creatorName ",
                              maxLines: 1,
                              overflow: TextOverflow.fade,
                              style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold),
                            ),
                          Text(
                              information["erstelltAm"]
                                  .split("-")
                                  .reversed
                                  .join("-"),
                              style: const TextStyle(color: Colors.black))
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 5)
                ],
              ),
              const SizedBox(
                height: 5,
              )
            ],
          ),
        ),
      );
    }

    createInfoList() {
      List<Widget> userCityInfo = [];

      for (var i = 0; i < usersCityInformation.length; i++) {
        userCityInfo.add(insiderInfoBox(usersCityInformation[i], i));
      }

      if (userCityInfo.isEmpty) {
        userCityInfo.add(Container(
          height: 500,
          padding: const EdgeInsets.all(10),
          child: Center(
            child: Text(
              AppLocalizations.of(context)!.keineInsiderInformation,
              style: const TextStyle(color: Colors.grey, fontSize: 20),
            ),
          ),
        ));
      }

      return userCityInfo;
    }


    return SafeArea(
      child: Scaffold(
        body: CarouselSlider(
          carouselController: carouselController,
          options: CarouselOptions(
              height: double.infinity,
              initialPage: initalPage,
              viewportFraction: viewportFraction,
              enableInfiniteScroll: false),
          items: createInfoList().map((card) {
            return Builder(
              builder: (BuildContext context) {
                return card;
              },
            );
          }).toList(),
        ),
        floatingActionButton: FloatingActionButton(
            heroTag: "create Stadtinformation",
            child: const Icon(Icons.create),
            onPressed: () => addInformationWindow()),
      ),
    );
  }
}
