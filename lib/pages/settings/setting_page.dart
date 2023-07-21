import 'dart:io';
import 'dart:ui';

import 'package:familien_suche/pages/chat/chat_details.dart';
import 'package:familien_suche/pages/settings/change_reiseplanung.dart';
import 'package:familien_suche/widgets/custom_appbar.dart';
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
import 'package:share_plus/share_plus.dart';

import '../../global/style.dart' as style;
import '../../global/global_functions.dart' as global_func;
import '../../global/global_functions.dart';
import '../../global/profil_sprachen.dart';
import '../../global/variablen.dart' as global_variablen;
import '../../global/custom_widgets.dart';
import '../../widgets/ChildrenBirthdatePicker.dart';
import '../../widgets/profil_image.dart';
import '../../windows/patchnotes.dart';
import '../login_register_page/login_page.dart';
import 'change_aufreise.dart';
import 'change_besuchte_laender.dart';
import 'change_children.dart';
import 'change_social_media.dart';
import 'family_profil.dart';
import 'privacy_security_page.dart';
import 'feedback_page.dart';
import 'change_city.dart';
import 'change_reiseart.dart';
import 'change_name.dart';
import 'change_email.dart';

var borderColor = Colors.grey[200];
double globalPadding = 30;
double fontSize = 20;
var userID = FirebaseAuth.instance.currentUser!.uid;
var userProfil;

class SettingPage extends StatefulWidget {
  const SettingPage({Key? key}) : super(key: key);

  @override
  _SettingPageState createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> with WidgetsBindingObserver {
  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    userProfil = Hive.box("secureBox").get("ownProfil");

    return Scaffold(
      body: SafeArea(
          child: Container(
        margin: const EdgeInsets.only(top: 10),
        child: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(dragDevices: {
            PointerDeviceKind.touch,
            PointerDeviceKind.mouse,
          }),
          child:
              ListView(padding: EdgeInsets.zero, shrinkWrap: true, children: [
            _NameSection(refresh: () => setState(() {})),
            _ProfilSection(
              afterChange: () => setState(() {}),
            ),
            const _SettingSection(),
            const _SupportInformation()
          ]),
        ),
      )),
    );
  }
}

class _NameSection extends StatelessWidget {
  Function refresh;
  var textColor = Colors.black;

  _NameSection({Key? key, required this.refresh}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    userProfil = Hive.box("secureBox").get("ownProfil");

    openSettingWindow() async {
      return showMenu(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(style.roundedCorners),
            ),
          ),
          context: context,
          position: const RelativeRect.fromLTRB(100, 0, 0, 100),
          items: [
            PopupMenuItem(
                child: TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => ChangeNamePage(
                                oldName: userProfil["name"],
                              ))).then((_) =>refresh()
                      );
                    },
                    child: Text(AppLocalizations.of(context)!.nameAendern,
                        style: TextStyle(color: textColor)))),
            PopupMenuItem(
                child: TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => ChangeEmailPage())).then((_)=>refresh());
                    },
                    child: Text(AppLocalizations.of(context)!.emailAendern,
                        style: TextStyle(color: textColor)))),
            PopupMenuItem(
                child: TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      global_func.changePage(context, ChangePasswortPage());
                    },
                    child: Text(AppLocalizations.of(context)!.passwortVeraendern,
                        style: TextStyle(color: textColor)))),
            PopupMenuItem(
                child: TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      global_func.changePage(
                          context, const FamilieProfilPage());
                    },
                    child: Text(AppLocalizations.of(context)!.familyProfil,
                        style: TextStyle(color: textColor)))),
            PopupMenuItem(
                child: TextButton(
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                      global_func.changePageForever(context, LoginPage());
                    },
                    child: Text(AppLocalizations.of(context)!.abmelden,
                        style: TextStyle(color: textColor)))),
          ]);
    }

    return Container(
        width: double.maxFinite,
        padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
        decoration: BoxDecoration(
            border: Border(bottom: BorderSide(width: 10, color: borderColor!))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              InkWell(onTap: ()=> openSettingWindow(), child: Icon(Icons.more_vert, color: textColor)),
            ],
          ),
          Row(
            children: [
              ProfilImage(userProfil, changeable: true, fullScreenWindow: true),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  userProfil["name"],
                  style: const TextStyle(fontSize: 28),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(userProfil["email"]),
        ]));
  }
}

//ignore: must_be_immutable
class _ProfilSection extends StatelessWidget {
  var kinderAgeBox = ChildrenBirthdatePickerBox();
  var interessenInputBox =
      CustomMultiTextForm(auswahlList: global_variablen.interessenListe);
  var reiseArtInput = CustomDropDownButton(items: global_variablen.reisearten);
  var sprachenInputBox = CustomMultiTextForm(auswahlList: []);
  final bool spracheIstDeutsch = kIsWeb
      ? window.locale.languageCode == "de"
      : Platform.localeName == "de_DE";
  final Function afterChange;

  void setData() async {
    List childrenAgeTimestamp = [];

    userProfil["kinder"].sort();

    userProfil["kinder"].forEach((kind) {
      var changeTimeStamp = global_func.ChangeTimeStamp(kind);
      childrenAgeTimestamp.add(changeTimeStamp.intoDate());
    });

    kinderAgeBox.setSelected(childrenAgeTimestamp);

    interessenInputBox.selected = List<String>.from(spracheIstDeutsch
        ? global_func.changeEnglishToGerman(userProfil["interessen"])
        : global_func.changeGermanToEnglish(userProfil["interessen"]));

    reiseArtInput.selected = spracheIstDeutsch
        ? global_func.changeEnglishToGerman(userProfil["reiseart"])
        : global_func.changeGermanToEnglish(userProfil["reiseart"]);

    sprachenInputBox.selected = List<String>.from(spracheIstDeutsch
        ? ProfilSprachen().translateLanguageList(englishList: userProfil["sprachen"])
        : ProfilSprachen().translateLanguageList(germanList: userProfil["sprachen"]));
  }

  _ProfilSection({Key? key, required this.afterChange}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var reisePlanung = userProfil["reisePlanung"];
    List<String> besuchteLaender =
        List<String>.from(userProfil["besuchteLaender"] ?? []);
    var headLineColor = Theme.of(context).colorScheme.primary;

    setData();

    profilThemeContainer(haupttext, beschreibung, page) {
      double screenWidth = MediaQuery.of(context).size.width;
      double containerPadding = 5;

      return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () =>
            Navigator.push(context, MaterialPageRoute(builder: (_) => page))
                .whenComplete(() => afterChange()),
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

    createAufreiseText() {
      String text = AppLocalizations.of(context)!.nein;
      String? seit = userProfil["aufreiseSeit"];
      String? bis = userProfil["aufreiseBis"];

      if (seit == null) return AppLocalizations.of(context)!.nein;

      text = seit.split(" ")[0].split("-").take(2).toList().reversed.join("-");

      if (bis == null) {
        text += " - offen";
      } else {
        text += " - " +
            bis.split(" ")[0].split("-").take(2).toList().reversed.join("-");
      }

      return text;
    }



    return Container(
        width: double.maxFinite,
        padding:
            const EdgeInsets.only(top: 10, bottom: 15, left: 15, right: 15),
        decoration: BoxDecoration(
            border: Border(bottom: BorderSide(width: 10, color: borderColor!))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text("Profil",
                  style: TextStyle(
                      color: headLineColor,
                      fontSize: fontSize + 4,
                      fontWeight: FontWeight.bold)),
              const Expanded(child: SizedBox.shrink()),
              const Icon(Icons.arrow_downward),
              Text(AppLocalizations.of(context)!.antippenZumAendern,
                  style: const TextStyle(color: Colors.grey, fontSize: 14)),
              const Icon(Icons.arrow_downward),
              const Expanded(child: SizedBox()),
              GestureDetector(
                  onTap: () {
                    global_func.changePage(
                        context, ShowProfilPage(profil: userProfil));
                  },
                  child: const Icon(
                    Icons.preview,
                    size: 40,
                  ))
            ]),
            const SizedBox(height: 5),
            Wrap(
              children: [
                profilThemeContainer(
                    userProfil["ort"],
                    AppLocalizations.of(context)!.aktuelleOrt,
                    const ChangeLocationPage()),
                profilThemeContainer(
                    reiseArtInput.getSelected(),
                    AppLocalizations.of(context)!.artDerReise,
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
                    AppLocalizations.of(context)!.alterDerKinder,
                    ChangeChildrenPage(
                      childrenBirthdatePickerBox: kinderAgeBox,
                    )),
                profilThemeContainer(
                    interessenInputBox.getSelected() == null
                        ? ""
                        : interessenInputBox.getSelected().join(", "),
                    AppLocalizations.of(context)!.interessen,
                    ChangeInteressenPage(
                      selected: interessenInputBox.getSelected(),
                      isGerman: spracheIstDeutsch,
                    )),
                profilThemeContainer(
                    sprachenInputBox.getSelected() == null
                        ? ""
                        : sprachenInputBox.getSelected().join(", "),
                    AppLocalizations.of(context)!.sprachen,
                    ChangeSprachenPage(
                      selected: sprachenInputBox.getSelected(),
                      isGerman: spracheIstDeutsch,
                    )),
                profilThemeContainer(
                    userProfil["aboutme"],
                    AppLocalizations.of(context)!.ueberMich,
                    ChangeAboutmePage(oldText: userProfil["aboutme"])),
                profilThemeContainer(
                    createAufreiseText(),
                    AppLocalizations.of(context)!.aufReise,
                    ChangeAufreisePage(
                        aufreiseSeit: userProfil["aufreiseSeit"] == null
                            ? null
                            : DateTime.parse(userProfil["aufreiseSeit"]),
                        aufreiseBis: userProfil["aufreiseBis"] == null
                            ? null
                            : DateTime.parse(userProfil["aufreiseBis"]),
                        isGerman: spracheIstDeutsch)),
                profilThemeContainer(
                    reisePlanung.length.toString(),
                    AppLocalizations.of(context)!.reisePlanung,
                    ChangeReiseplanungPage(
                        reiseplanung: reisePlanung,
                        isGerman: spracheIstDeutsch)),
                profilThemeContainer(
                    besuchteLaender.length.toString(),
                    AppLocalizations.of(context)!.besuchteLaender,
                    ChangeBesuchteLaenderPage(
                        selected: besuchteLaender,
                        isGerman: spracheIstDeutsch)),
                profilThemeContainer(
                    userProfil["socialMediaLinks"].isEmpty
                        ? "0"
                        : userProfil["socialMediaLinks"].length.toString(),
                    "Social Media Links",
                    const ChangeSocialMediaLinks()),
              ],
            ),
          ],
        ));
  }
}

class _SettingSection extends StatelessWidget {
  const _SettingSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var headLineColor = Theme.of(context).colorScheme.primary;

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

    return Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(context)!.einstellungen,
                style: TextStyle(
                    color: headLineColor,
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            settingThemeContainer(
                AppLocalizations.of(context)!.privatsphaereSicherheit,
                Icons.lock,
                () => global_func.changePage(
                    context, const PrivacySecurityPage())),
            const SizedBox(height: 20),
            settingThemeContainer(
                AppLocalizations.of(context)!.benachrichtigungen,
                Icons.notifications,
                () => global_func.changePage(
                    context, const NotificationsOptionsPage())),
          ],
        ));
  }
}

class _SupportInformation extends StatelessWidget {
  const _SupportInformation({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var headLineColor = Theme.of(context).colorScheme.primary;

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

    aboutAppWindow() async {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();

      showDialog(
          context: context,
          builder: (BuildContext buildContext) {
            return CustomAlertDialog(
              title: "families worldwide app",
              children: [
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Text("App Version: ",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(packageInfo.version),
                  ],
                ),
                const SizedBox(height: 10),
                InkWell(
                  onTap: () => openURL(
                      "https://github.com/derdrache/familienWeltweitVerbinden"),
                  child: const Row(
                    children: [
                      Text("Open Source: ",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(
                        "Github Repo",
                        style: TextStyle(
                          decoration: TextDecoration.underline,
                          color: Colors.blue,
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                const Row(
                  children: [
                    Text("Framework:  ",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text("Flutter"),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Text("Icons: ",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text("created by Freepik - Flaticon"),
                  ],
                ),
                const SizedBox(height: 20),
                Text(AppLocalizations.of(context)!.aboutAppText)
              ],
            );
          });
    }

    return Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(context)!.appInformation,
                style: TextStyle(
                    color: headLineColor,
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            settingThemeContainer("Feedback", Icons.feedback,
                () => global_func.changePage(context, FeedbackPage())),
            const SizedBox(height: 20),
            settingThemeContainer(
                "Support Chat",
                Icons.chat,
                () => global_func.changePage(
                    context,
                    ChatDetailsPage(
                        isChatgroup: true, connectedWith: "</support=1"))),
            const SizedBox(height: 20),
            settingThemeContainer("Patch Notes", Icons.format_list_bulleted,
                () => PatchnotesWindow(context: context).openWindow()),
            const SizedBox(height: 20),
            settingThemeContainer(
                AppLocalizations.of(context)!.mitFreundenTeilen,
                Icons.share,
                () => Share.share(AppLocalizations.of(context)!.teilenLinkText +
                    '\nhttps://families-worldwide.com/\n\nAndroid:\nhttps://play.google.com/store/apps/details?id=dominik.familien_suche\n\niOS:\nhttps://apps.apple.com/app/families-worldwide/id6444735167')),
            const SizedBox(height: 20),
            settingThemeContainer(
                AppLocalizations.of(context)!.spenden, Icons.favorite,
                () async {
              var url =
                  Uri.parse("https://www.paypal.com/paypalme/DominikMast");

              await launchUrl(url, mode: LaunchMode.inAppWebView);
            }),
            const SizedBox(height: 20),
            settingThemeContainer(AppLocalizations.of(context)!.ueber,
                Icons.info, () => aboutAppWindow()),
          ],
        ));
  }
}
