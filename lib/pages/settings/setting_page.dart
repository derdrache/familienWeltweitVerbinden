import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:familien_suche/pages/settings/changePasswort.dart';
import 'package:familien_suche/pages/settings/change_aboutme.dart';
import 'package:familien_suche/pages/settings/change_interessen.dart';
import 'package:familien_suche/pages/settings/change_sprachen.dart';
import 'package:familien_suche/pages/settings/notifications_option.dart';
import 'package:familien_suche/pages/show_profil.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/link.dart' as url_luncher;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';


import '../../services/database.dart';
import '../../global/global_functions.dart' as global_functions;
import '../../global/variablen.dart' as global_variablen;
import '../../global/custom_widgets.dart';
import '../../services/locationsService.dart';
import '../../windows/upcoming_updates.dart';
import '../../windows/patchnotes.dart';
import '../login_register_page/login_page.dart';
import 'change_children.dart';
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
  var spracheIstDeutsch = kIsWeb ? window.locale.languageCode == "de" : Platform.localeName == "de_DE";
  var borderColor = Colors.grey[200];
  var userID = FirebaseAuth.instance.currentUser.uid;
  var userProfil;
  var nameTextKontroller = TextEditingController();
  var kinderAgeBox = ChildrenBirthdatePickerBox();
  var interessenInputBox = CustomMultiTextForm(
      auswahlList: global_variablen.interessenListe);
  var bioTextKontroller = TextEditingController();
  var emailTextKontroller = TextEditingController();
  var emailNewTextKontroller = TextEditingController();
  var passwortTextKontroller1 = TextEditingController();
  var passwortTextKontroller2 = TextEditingController();
  var passwortCheckKontroller = TextEditingController();
  var reiseArtInput = CustomDropDownButton(items: global_variablen.reisearten);
  var sprachenInputBox = CustomMultiTextForm(
      auswahlList: global_variablen.sprachenListe);
  var ortKontroller = TextEditingController();



  void getAndSetDataFromDB() async {
    List childrenAgeTimestamp = [];

    List childrenDataYears = [];

    userProfil["kinder"].forEach((kind){
      var changeTimeStamp = global_functions.ChangeTimeStamp(kind);
      childrenDataYears.add(changeTimeStamp.intoYears());
      childrenAgeTimestamp.add(changeTimeStamp.intoDate());
    });

    nameTextKontroller.text = userProfil["name"];
    emailTextKontroller.text = userProfil["email"];
    ortKontroller.text = userProfil["ort"];
    interessenInputBox.selected = spracheIstDeutsch ?
        global_variablen.changeEnglishToGerman(userProfil["interessen"]):
        global_variablen.changeGermanToEnglish(userProfil["interessen"]);
    kinderAgeBox.setSelected(childrenAgeTimestamp);
    bioTextKontroller.text = userProfil["aboutme"];
    reiseArtInput.selected = spracheIstDeutsch ?
        global_variablen.changeEnglishToGerman(userProfil["reiseart"]):
        global_variablen.changeGermanToEnglish(userProfil["reiseart"]);;
    sprachenInputBox.selected = spracheIstDeutsch ?
        global_variablen.changeEnglishToGerman(userProfil["sprachen"]):
        global_variablen.changeGermanToEnglish(userProfil["sprachen"]);;

    }

  openSettingWindow()async {
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
                    global_functions.changePage(context, ChangeNamePage(
                        userId: userID,
                        nameKontroller: nameTextKontroller)
                    );
                  },
                  child: Text(AppLocalizations.of(context).nameAendern, style: TextStyle(color: textColor)))
          ),
          PopupMenuItem(
              child: TextButton(
                  onPressed: () {
                    global_functions.changePage(context, ChangeEmailPage());
                  },
                  child: Text(AppLocalizations.of(context).emailAendern, style: TextStyle(color: textColor))
              )
          ),
          PopupMenuItem(
              child: TextButton(
                  onPressed: () {
                    global_functions.changePage(context, ChangePasswortPage());
                  },
                  child: Text(AppLocalizations.of(context).passwortVeraendern, style: TextStyle(color: textColor)))
          ),
          PopupMenuItem(
              child: TextButton(
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                    setState(() {});
                    global_functions.changePageForever(context, const LoginPage());
                  },
                  child: Text(AppLocalizations.of(context).abmelden, style: TextStyle(color: textColor)))
          ),
        ]
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double containerPadding = 5;
    var headLineColor = Theme.of(context).colorScheme.primary;


    menuBar(){
      return customAppBar(
          title: "",
          elevation: 0.0,
          buttons: [TextButton(
            style: ButtonStyle(
                shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    )
                )
            ),
            child: const Icon(Icons.more_vert, color: Colors.black),
            onPressed: () => openSettingWindow(),
          )]
      );
    }

    nameContainer(){
      return Container(
          width: double.maxFinite,
          padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
          decoration: BoxDecoration(
              border: Border(bottom: BorderSide(width: 10, color: borderColor))
          ),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nameTextKontroller.text,
                  style: const TextStyle(fontSize: 30),
                ),
                const SizedBox(height: 5),
                Text(emailTextKontroller.text)
              ]
          )
      );
    }

    profilThemeContainer(haupttext, beschreibung, page,[fullWidth = false]){
      return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => global_functions.changePage(context, page),
        child: Container(
            padding: EdgeInsets.only(top: containerPadding, bottom: containerPadding),
            width: fullWidth ? screenWidth :screenWidth /2 -20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                haupttext == ""? const CircularProgressIndicator() : Text(
                  haupttext,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: fontSize-4),
                ),
                const SizedBox(height: 3),
                Text(beschreibung,
                  style: TextStyle(color: Colors.grey, fontSize: fontSize-6.0),
                ),
              ],
            )
        ),
      );
    }

    profilContainer(){
      return Container(
          width: double.maxFinite,
          padding: const EdgeInsets.only(top:10, bottom: 15, left:15, right: 15),
          decoration: BoxDecoration(
              border: Border(bottom: BorderSide(width: 10, color: borderColor))
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text("Profil",
                    style: TextStyle(
                      color: headLineColor,
                      fontSize: fontSize,
                      fontWeight: FontWeight.bold
                    )
                ),
                const Expanded(child: SizedBox.shrink()),
                Text(AppLocalizations.of(context).antippenZumAendern,
                    style: const TextStyle(color: Colors.grey, fontSize: 14)
                ),
                const Expanded(child: SizedBox()),
                GestureDetector(
                  onTap: () {
                    global_functions.changePage(
                        context,
                        ShowProfilPage(profil: userProfil, ownProfil: true)
                    );
                  },
                  child: Icon(Icons.preview, size: 35,)
                )
              ]),
              const SizedBox(height: 5),
              Wrap(
                children: [
                  profilThemeContainer(
                      ortKontroller.text, AppLocalizations.of(context).aktuelleStadt,
                      ChangeCityPage(userId: userID)),
                  profilThemeContainer(reiseArtInput.getSelected(), AppLocalizations.of(context).artDerReise,
                      ChangeReiseartPage(
                        userId: userID,
                        oldInput: reiseArtInput.getSelected(),
                        isGerman: spracheIstDeutsch,
                      )
                  ),
                  profilThemeContainer(kinderAgeBox.getDates(years: true)  == null? "":
                  kinderAgeBox.getDates(years: true).join(", "),
                      AppLocalizations.of(context).alterDerKinder, ChangeChildrenPage(
                        userId: userID, childrenBirthdatePickerBox: kinderAgeBox,
                      )),
                  profilThemeContainer(
                      interessenInputBox.getSelected() == null? "" :
                      interessenInputBox.getSelected().join(", "),
                      AppLocalizations.of(context).interessen,
                      ChangeInteressenPage(
                        userId: userID,
                        selected: interessenInputBox.getSelected(),
                        isGerman: spracheIstDeutsch,
                      )
                  ),
                  profilThemeContainer(
                      sprachenInputBox.getSelected() == null? "":
                      sprachenInputBox.getSelected().join(", "),
                      AppLocalizations.of(context).sprachen,
                      ChangeSprachenPage(
                        userId: userID,
                        selected: sprachenInputBox.getSelected(),
                        isGerman: spracheIstDeutsch,
                      )

                  )

                ],
              ),
              profilThemeContainer(bioTextKontroller.text== ""? " ": bioTextKontroller.text,
                  AppLocalizations.of(context).ueberMich,
                ChangeAboutmePage(userId: userID, bioTextKontroller: bioTextKontroller),
                true
              )
            ],
          )
      );
    }

    settingThemeContainer(title, icon, function){
      return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: function,
        child: Row(
          children: [
            Icon(icon),
            const SizedBox(width: 20),
            Text(title, style: TextStyle(fontSize: fontSize-4),)
          ],
        ),
      );
    }

    settingContainer(){
      return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppLocalizations.of(context).einstellungen,
                  style: TextStyle(
                      color: headLineColor,
                      fontSize: fontSize,
                      fontWeight: FontWeight.bold
                  )
              ),
              const SizedBox(height: 20),
              settingThemeContainer(AppLocalizations.of(context).privatsphaereSicherheit, Icons.lock,
                      () => global_functions.changePage(
                          context, PrivacySecurityPage(profil: userProfil)
                      )
              ),
              if(!kIsWeb) const SizedBox(height: 20),
              if(!kIsWeb) settingThemeContainer(AppLocalizations.of(context).benachrichtigungen, Icons.notifications,
                      () => global_functions.changePage(
                      context, NotificationsOptionsPage(profil: userProfil)
                  )
              ),
            ],
          )
      );
    }

    aboutAppContainer(){
      return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppLocalizations.of(context).appInformation,
                  style: TextStyle(
                      color: headLineColor,
                      fontSize: fontSize,
                    fontWeight: FontWeight.bold
                  )
              ),
              const SizedBox(height: 20),
              settingThemeContainer("Feedback", Icons.feedback,
                      () => global_functions.changePage(
                      context, FeedbackPage()
                  )
              ),
              const SizedBox(height: 20),
              settingThemeContainer("Patch Notes", Icons.format_list_bulleted,
                  () => PatchnotesWindow(context: context).openWindow()
               ),
              const SizedBox(height: 20),
              settingThemeContainer(AppLocalizations.of(context).geplanteErweiterungen, Icons.update,
                  () => UmcomingUpdatesWindow(context: context).openWindow()
              ),
              /*
              SizedBox(height: 20),
              settingThemeContainer("Über das Projekt", Icons.description,
                  () => AboutProject(context: context).openWindow()
              ),

               */

              const SizedBox(height: 20),
              url_luncher.Link(
                target: url_luncher.LinkTarget.blank,
                uri: Uri.parse("https://www.paypal.com/paypalme/DominikMast"),
                builder: (context, followLink) => GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: followLink,
                  child: Row(
                    children: [
                      const Icon(Icons.card_giftcard),
                      const SizedBox(width: 20),
                      Text(AppLocalizations.of(context).spenden, style: TextStyle(fontSize: fontSize-4))
                    ],
                  ),
                ),
              )
            ],
          )
      );
    }


    return FutureBuilder(
          future: ProfilDatabase().getProfil("id", userID),
          builder: (
          BuildContext context,
          AsyncSnapshot snapshot,
          ){
            if(snapshot.hasData){
              userProfil = snapshot.data;

              getAndSetDataFromDB();

              return ScrollConfiguration(
                behavior: ScrollConfiguration.of(context).copyWith(dragDevices: {
                  PointerDeviceKind.touch,
                  PointerDeviceKind.mouse,
                }),
                child: ListView(
                      children: [
                        menuBar(),
                        nameContainer(),
                        profilContainer(),
                        settingContainer(),
                        aboutAppContainer(),
                      ]
                ),
              );
            }
            return const SizedBox.shrink();
          });
  }
}

