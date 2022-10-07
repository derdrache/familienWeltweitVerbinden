import 'dart:io';
import 'dart:ui';

import 'package:familien_suche/pages/settings/change_reiseplanung.dart';
import 'package:familien_suche/widgets/dialogWindow.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:familien_suche/pages/settings/changePasswort.dart';
import 'package:familien_suche/pages/settings/change_aboutme.dart';
import 'package:familien_suche/pages/settings/change_interessen.dart';
import 'package:familien_suche/pages/settings/change_sprachen.dart';
import 'package:familien_suche/pages/settings/notifications_option.dart';
import 'package:familien_suche/pages/show_profil.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive/hive.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../global/global_functions.dart' as global_func;
import '../../global/variablen.dart' as global_variablen;
import '../../global/custom_widgets.dart';
import '../../widgets/ChildrenBirthdatePicker.dart';
import '../../widgets/profil_image.dart';
import '../../windows/upcoming_updates.dart';
import '../../windows/patchnotes.dart';
import '../login_register_page/login_page.dart';
import 'change_aufreise.dart';
import 'change_besuchte_laender.dart';
import 'change_children.dart';
import 'change_trade.dart';
import 'family_profil.dart';
import 'privacy_security_page.dart';
import 'feedback_page.dart';
import 'change_city.dart';
import 'change_reiseart.dart';
import 'change_name.dart';
import 'change_email.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({Key key}) : super(key: key);

  @override
  _SettingPageState createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  double globalPadding = 30;
  double fontSize = 20;
  var spracheIstDeutsch = kIsWeb
      ? window.locale.languageCode == "de"
      : Platform.localeName == "de_DE";
  var borderColor = Colors.grey[200];
  var userID = FirebaseAuth.instance.currentUser.uid;
  var userProfil = Hive.box("secureBox").get("ownProfil");
  var kinderAgeBox = ChildrenBirthdatePickerBox();
  var interessenInputBox =
      CustomMultiTextForm(auswahlList: global_variablen.interessenListe);
  var reiseArtInput = CustomDropDownButton(items: global_variablen.reisearten);
  var sprachenInputBox =
      CustomMultiTextForm(auswahlList: global_variablen.sprachenListe);

  @override
  void initState() {
    setData();

    super.initState();
  }


  void setData() async {
    List childrenAgeTimestamp = [];

    userProfil["kinder"].forEach((kind) {
      var changeTimeStamp = global_func.ChangeTimeStamp(kind);
      childrenAgeTimestamp.add(changeTimeStamp.intoDate());
    });

    interessenInputBox.selected = List<String>.from(spracheIstDeutsch
        ? global_func.changeEnglishToGerman(userProfil["interessen"])
        : global_func.changeGermanToEnglish(userProfil["interessen"]));

    kinderAgeBox.setSelected(childrenAgeTimestamp);

    reiseArtInput.selected = spracheIstDeutsch
        ? global_func.changeEnglishToGerman(userProfil["reiseart"])
        : global_func.changeGermanToEnglish(userProfil["reiseart"]);

    sprachenInputBox.selected = List<String>.from(spracheIstDeutsch
        ? global_func.changeEnglishToGerman(userProfil["sprachen"])
        : global_func.changeGermanToEnglish(userProfil["sprachen"]));
  }

  openSettingWindow() async {
    var textColor = Colors.black;

    return showMenu(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(5.0),
          ),
        ),
        context: context,
        position: const RelativeRect.fromLTRB(100, 0, 0, 100),
        items: [
          PopupMenuItem(
              child: TextButton(
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => ChangeNamePage(
                                  oldName: userProfil["name"],
                                ))).whenComplete(() => setState(() {}));
                  },
                  child: Text(AppLocalizations.of(context).nameAendern,
                      style: TextStyle(color: textColor)))),
          PopupMenuItem(
              child: TextButton(
                  onPressed: () {
                    Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => ChangeEmailPage()))
                        .whenComplete(() => setState(() {}));
                  },
                  child: Text(AppLocalizations.of(context).emailAendern,
                      style: TextStyle(color: textColor)))),
          PopupMenuItem(
              child: TextButton(
                  onPressed: () {
                    global_func.changePage(context, ChangePasswortPage());
                  },
                  child: Text(AppLocalizations.of(context).passwortVeraendern,
                      style: TextStyle(color: textColor)))),
          PopupMenuItem(
              child: TextButton(
                  onPressed: () {
                    global_func.changePage(context, const FamilieProfilPage());
                  },
                  child: Text(AppLocalizations.of(context).familyProfil,
                      style: TextStyle(color: textColor)))),

          PopupMenuItem(
              child: TextButton(
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                    global_func.changePageForever(
                        context, const LoginPage());
                  },
                  child: Text(AppLocalizations.of(context).abmelden,
                      style: TextStyle(color: textColor)))),
        ]);
  }

  aboutAppWindow() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();

    showDialog(
        context: context,
        builder: (BuildContext buildContext) {
          return CustomAlertDialog(
            title: "families worldwide app",
            children: [
              const SizedBox(height: 20),
              Text("Version: " + packageInfo.version),
              const SizedBox(height: 20)
            ],
          );
        });
  }

  createAufreiseText() {
    String text = "";
    String seit = userProfil["aufreiseSeit"];
    String bis = userProfil["aufreiseBis"];

    if (seit == null) return " ";
    text = seit.split(" ")[0].split("-").take(2).toList().reversed.join("-");

    if (bis == null) {
      text += " - offen";
    } else {
      text += " - " +
          bis.split(" ")[0].split("-").take(2).toList().reversed.join("-");
    }

    return text;
  }

  @override
  Widget build(BuildContext context) {
    var headLineColor = Theme.of(context).colorScheme.primary;
    userProfil = Hive.box("secureBox").get("ownProfil");

    menuBar() {
      return SizedBox(
          height: 70,
          child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                TextButton(
                  style: ButtonStyle(
                      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ))),
                  child: const Icon(Icons.more_vert, color: Colors.black),
                  onPressed: () => openSettingWindow(),
                )
              ]));
    }

    nameContainer() {
      return Container(
          width: double.maxFinite,
          padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
          decoration: BoxDecoration(
              border:
                  Border(bottom: BorderSide(width: 10, color: borderColor))),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(
              children: [
                ProfilImage(userProfil,
                    changeable: true, fullScreenWindow: true),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    userProfil["name"],
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(userProfil["email"])
          ]));
    }

    profilThemeContainer(haupttext, beschreibung, page) {
      double screenWidth = MediaQuery.of(context).size.width;
      double containerPadding = 5;

      return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () =>
            Navigator.push(context, MaterialPageRoute(builder: (_) => page))
                .whenComplete(() => setState(() {})),
        child: Container(
            padding: EdgeInsets.only(
                top: containerPadding, bottom: containerPadding, right: 10),
            width: screenWidth / 2 - 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  haupttext,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                  style: TextStyle(fontSize: fontSize - 4),
                ),
                const SizedBox(height: 3),
                Text(
                  beschreibung,
                  style:
                      TextStyle(color: Colors.grey, fontSize: fontSize - 6.0),
                ),
              ],
            )),
      );
    }

    profilContainer() {
      var reisePlanung = userProfil["reisePlanung"];
      List<String> besuchteLaender = List<String>.from(userProfil["besuchteLaender"] ?? []);

      return Container(
          width: double.maxFinite,
          padding:
              const EdgeInsets.only(top: 10, bottom: 15, left: 15, right: 15),
          decoration: BoxDecoration(
              border:
                  Border(bottom: BorderSide(width: 10, color: borderColor))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text("Profil",
                    style: TextStyle(
                        color: headLineColor,
                        fontSize: fontSize,
                        fontWeight: FontWeight.bold)),
                const Expanded(child: SizedBox.shrink()),
                Text(AppLocalizations.of(context).antippenZumAendern,
                    style: const TextStyle(color: Colors.grey, fontSize: 14)),
                const Expanded(child: SizedBox()),
                GestureDetector(
                    onTap: () {
                      global_func.changePage(context,
                          ShowProfilPage(profil: userProfil, ownProfil: true));
                    },
                    child: const Icon(
                      Icons.preview,
                      size: 35,
                    ))
              ]),
              const SizedBox(height: 5),
              Wrap(
                children: [
                  profilThemeContainer(
                      userProfil["ort"],
                      AppLocalizations.of(context).aktuelleOrt,
                      ChangeCityPage()),
                  profilThemeContainer(
                      reiseArtInput.getSelected(),
                      AppLocalizations.of(context).artDerReise,
                      ChangeReiseartPage(
                        oldInput: reiseArtInput.getSelected(),
                        isGerman: spracheIstDeutsch,
                      )),
                  profilThemeContainer(
                      kinderAgeBox.getDates(years: true) == null
                          ? ""
                          : kinderAgeBox
                              .getDates(years: true)
                              .reversed
                              .join(", "),
                      AppLocalizations.of(context).alterDerKinder,
                      ChangeChildrenPage(
                        childrenBirthdatePickerBox: kinderAgeBox,
                      )),
                  profilThemeContainer(
                      interessenInputBox.getSelected() == null
                          ? ""
                          : interessenInputBox.getSelected().join(", "),
                      AppLocalizations.of(context).interessen,
                      ChangeInteressenPage(
                        selected: interessenInputBox.getSelected(),
                        isGerman: spracheIstDeutsch,
                      )),
                  profilThemeContainer(
                      sprachenInputBox.getSelected() == null
                          ? ""
                          : sprachenInputBox.getSelected().join(", "),
                      AppLocalizations.of(context).sprachen,
                      ChangeSprachenPage(
                        selected: sprachenInputBox.getSelected(),
                        isGerman: spracheIstDeutsch,
                      )),
                  profilThemeContainer(
                      createAufreiseText(),
                      AppLocalizations.of(context).aufReise,
                      ChangeAufreisePage(
                          aufreiseSeit: userProfil["aufreiseSeit"] == null
                              ? null
                              : DateTime.parse(userProfil["aufreiseSeit"]),
                          aufreiseBis: userProfil["aufreiseBis"] == null
                              ? null
                              : DateTime.parse(userProfil["aufreiseBis"]),
                          isGerman: spracheIstDeutsch)),
                  profilThemeContainer(
                      userProfil["aboutme"],
                      AppLocalizations.of(context).ueberMich,
                      ChangeAboutmePage(oldText: userProfil["aboutme"])),
                  profilThemeContainer(
                      userProfil["tradeNotize"],
                      AppLocalizations.of(context).verkaufenTauschenSchenken,
                      ChangeTradePage(oldText: userProfil["tradeNotize"])),
                  profilThemeContainer(
                      reisePlanung.length.toString(),
                      AppLocalizations.of(context).reisePlanung,
                      ChangeReiseplanungPage(
                          reiseplanung: reisePlanung,
                          isGerman: spracheIstDeutsch)),
                  profilThemeContainer(
                      besuchteLaender.length.toString(),
                      AppLocalizations.of(context).besuchteLaender,
                      ChangeBesuchteLaenderPage(
                          selected: besuchteLaender,
                          isGerman: spracheIstDeutsch)),
                ],
              ),
            ],
          ));
    }

    settingThemeContainer(title, icon, function, {color = Colors.black}) {
      return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: function,
        child: Row(
          children: [
            Icon(icon),
            const SizedBox(width: 20),
            Text(
              title,
              style: TextStyle(fontSize: fontSize - 4, color: color),
            )
          ],
        ),
      );
    }

    settingContainer() {
      return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppLocalizations.of(context).einstellungen,
                  style: TextStyle(
                      color: headLineColor,
                      fontSize: fontSize,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              settingThemeContainer(
                  AppLocalizations.of(context).privatsphaereSicherheit,
                  Icons.lock,
                  () => global_func.changePage(
                      context, PrivacySecurityPage(profil: userProfil))),
              const SizedBox(height: 20),
              settingThemeContainer(
                  AppLocalizations.of(context).benachrichtigungen,
                  Icons.notifications,
                  () => global_func.changePage(
                      context, NotificationsOptionsPage(profil: userProfil))),
            ],
          ));
    }

    aboutAppContainer() {
      return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppLocalizations.of(context).appInformation,
                  style: TextStyle(
                      color: headLineColor,
                      fontSize: fontSize,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              settingThemeContainer("Feedback", Icons.feedback,
                  () => global_func.changePage(context, FeedbackPage())),
              const SizedBox(height: 20),
              settingThemeContainer("Patch Notes", Icons.format_list_bulleted,
                  () => PatchnotesWindow(context: context).openWindow()),
              const SizedBox(height: 20),
              settingThemeContainer(
                  AppLocalizations.of(context).geplanteErweiterungen,
                  Icons.update,
                  () => UmcomingUpdatesWindow(context: context).openWindow()),
              /*
              SizedBox(height: 20),
              settingThemeContainer("Über das Projekt", Icons.description,
                  () => AboutProject(context: context).openWindow()
              ),

               */

              const SizedBox(height: 20),
              settingThemeContainer(
                  AppLocalizations.of(context).spenden, Icons.card_giftcard,
                  () async {
                const url = "https://www.paypal.com/paypalme/DominikMast";

                await launch(url);
              }),
              const SizedBox(height: 20),
              settingThemeContainer(AppLocalizations.of(context).ueber,
                  Icons.info, () => aboutAppWindow()),
            ],
          ));
    }

    return Column(
      children: [
        menuBar(),
        Expanded(
          child: ScrollConfiguration(
            behavior:
            ScrollConfiguration.of(context).copyWith(dragDevices: {
              PointerDeviceKind.touch,
              PointerDeviceKind.mouse,
            }),
            child: ListView(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                children: [
                  nameContainer(),
                  profilContainer(),
                  settingContainer(),
                  aboutAppContainer(),
                ]),
          ),
        )
      ],
    );
  }
}
