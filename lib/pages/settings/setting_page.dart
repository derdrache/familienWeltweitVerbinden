import 'package:familien_suche/pages/settings/changePasswort.dart';
import 'package:familien_suche/pages/settings/change_aboutme.dart';
import 'package:familien_suche/pages/settings/change_interessen.dart';
import 'package:familien_suche/pages/settings/change_sprachen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/link.dart';

import '../../services/database.dart';
import '../../global/global_functions.dart' as global_functions;
import '../../global/variablen.dart' as global_variablen;
import '../../global/custom_widgets.dart';
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
  const SettingPage({Key? key}) : super(key: key);

  @override
  _SettingPageState createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  double globalPadding = 30;
  double fontSize = 20;
  var borderColor = Colors.grey[200]!;
  var userID = FirebaseAuth.instance.currentUser!.uid;
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
    interessenInputBox.selected = userProfil["interessen"];
    kinderAgeBox.setSelected(childrenAgeTimestamp);
    bioTextKontroller.text = userProfil["aboutme"];
    reiseArtInput.selected = userProfil["reiseart"];
    sprachenInputBox.selected = userProfil["sprachen"];

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
                  child: Text("Name ändern", style: TextStyle(color: textColor)))
          ),
          PopupMenuItem(
              child: TextButton(
                  onPressed: () {
                    global_functions.changePage(context, ChangeEmailPage());
                  },
                  child: Text("Email ändern", style: TextStyle(color: textColor))
              )
          ),
          PopupMenuItem(
              child: TextButton(
                  onPressed: () {
                    global_functions.changePage(context, ChangePasswortPage());
                  },
                  child: Text("Passwort ändern", style: TextStyle(color: textColor)))
          ),
          PopupMenuItem(
              child: TextButton(
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                    global_functions.changePage(context, const LoginPage());
                  },
                  child: Text("Abmelden", style: TextStyle(color: textColor)))
          ),
        ]
    );
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double containerPadding = 5;
    var headLineColor = Theme.of(context).colorScheme.primary;


    profilThemeContainer(haupttext, beschreibung, page){
      return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => global_functions.changePage(context, page),
        child: Container(
            padding: EdgeInsets.only(top: containerPadding, bottom: containerPadding),
            width: width /2 -20,
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

    menuBar(){
      return  customAppBar(
          title: "",
          elevation: 0.0,
          button: TextButton(
            style: ButtonStyle(
                shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    )
                )
            ),
            child: const Icon(Icons.more_vert, color: Colors.black),
            onPressed: () => openSettingWindow(),
          )
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

    profilContainer(){
      return Container(
          width: double.maxFinite,
          padding: const EdgeInsets.all(20),
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
                const Text("Antippen, um Einträge zu ändern",
                    style: TextStyle(color: Colors.grey, fontSize: 14)
                ),
                const Expanded(child: SizedBox()),
              ]),
              const SizedBox(height: 5),
              Wrap(
                children: [
                  profilThemeContainer(ortKontroller.text, "Aktuelle Stadt",
                      ChangeCityPage(userId: userID)),
                  profilThemeContainer(reiseArtInput.getSelected(), "Art der Reise",
                      ChangeReiseartPage(userId: userID, oldInput: reiseArtInput.getSelected())
                  ),
                  profilThemeContainer(kinderAgeBox.getDates(years: true)  == null? "":
                  kinderAgeBox.getDates(years: true).join(" , "),
                      "Alter der Kinder", ChangeChildrenPage(
                        userId: userID, childrenBirthdatePickerBox: kinderAgeBox,
                      )),
                  profilThemeContainer(
                      interessenInputBox.getSelected() == null? "" :
                      interessenInputBox.getSelected().join(" , "),
                      "Interessen", ChangeInteressenPage(userId: userID,)),
                  profilThemeContainer(
                      sprachenInputBox.getSelected() == null? "":
                      sprachenInputBox.getSelected().join(" , "),
                      "Sprachen", ChangeSprachenPage(userId: userID))
                ],
              ),
              profilThemeContainer(bioTextKontroller.text== ""? " ": bioTextKontroller.text,
                  "Über mich",
                  ChangeAboutmePage(userId: userID, bioTextKontroller: bioTextKontroller)
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
              Text("Einstellungen",
                  style: TextStyle(
                      color: headLineColor,
                      fontSize: fontSize,
                      fontWeight: FontWeight.bold
                  )
              ),
              const SizedBox(height: 20),
              settingThemeContainer("Privatsphäre und Sicherheit", Icons.lock,
                      () => global_functions.changePage(
                          context, PrivacySecurityPage(profil: userProfil)
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
              Text("App Informationen",
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
              settingThemeContainer("Geplante Erweiterungen", Icons.task,
                  () => UmcomingUpdatesWindow(context: context).openWindow()
              ),
              /*
              SizedBox(height: 20),
              settingThemeContainer("Über das Projekt", Icons.description,
                  () => AboutProject(context: context).openWindow()
              ),

               */
              const SizedBox(height: 20),
              Link(
                target: LinkTarget.blank,
                uri: Uri.parse("https://www.paypal.com/paypalme/DominikMast"),
                builder: (context, followLink) => GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: followLink,
                  child: Row(
                    children: const [
                      Icon(Icons.card_giftcard),
                      SizedBox(width: 20),
                      Text("Spenden")
                    ],
                  ),
                ),
              )
            ],
          )
      );
    }


    return Padding(
        padding: const EdgeInsets.only(top: 5),
        child: StreamBuilder(
          stream: ProfilDatabase().getProfilStream(userID),
          builder: (
          BuildContext context,
          AsyncSnapshot snapshot,
          ){
            if(snapshot.hasData){
              userProfil = snapshot.data.snapshot.value;

              getAndSetDataFromDB();

              return ListView(
                  children: [
                    menuBar(),
                    nameContainer(),
                    profilContainer(),
                    settingContainer(),
                    aboutAppContainer()
                  ]
              );
            }
            return const SizedBox.shrink();
          })

    );
  }
}

