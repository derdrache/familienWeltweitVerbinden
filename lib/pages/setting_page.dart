import 'package:familien_suche/global/variablen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/database.dart';
import '../global/global_functions.dart' as globalFunctions;
import '../services/database.dart';
import '../windows/change_profil_window.dart';
import '../global/custom_widgets.dart';
import '../global/variablen.dart' as globalVariablen;


class SettingPage extends StatefulWidget {
  const SettingPage({Key? key}) : super(key: key);

  @override
  _SettingPageState createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  double globalPadding = 30;
  double fontSize = 16;
  var borderColor = Colors.grey[200]!;
  var profilName = "";
  var profilOrt = "";
  var profilKinder = [];
  var profilInteressen = [];
  var interessenInputBox = CustomMultiTextForm(
      auswahlList: globalVariablen.interessenListe);
  var profilBio = "";
  var profilEmail = "";
  var profilReiseart = "";
  var reiseArtInput = CustomDropDownButton(items: globalVariablen.reisearten);
  var profilSprachen = [];
  var sprachenInputBox = CustomMultiTextForm(
      auswahlList: globalVariablen.sprachenListe);
  var ortKontroller = TextEditingController();


  @override
  void initState() {
    // TODO: implement initState

    reiseArtInput = CustomDropDownButton(
      items: globalVariablen.reisearten,
      selected: profilReiseart,
    );



    getAndSetDataFromDB();


    super.initState();
  }




  nameContainer(){
    return Container(
      width: double.maxFinite,
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(width: 10, color: borderColor))
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            profilName,
            style: TextStyle(fontSize: 30),
          ),
          Text(profilEmail)
        ]
      )
    );
  }

  settingContainer(){

    themeContainer(title, icon){
      return Container(
        child: Row(
          children: [
            Icon(icon),
            SizedBox(width: 20),
            Text(title)
          ],
        )
      );
      return Text(title);
    }

    return Container(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Einstellungen",
                style: TextStyle(color: Colors.blue, fontSize: fontSize)),
            SizedBox(height: 20),
            themeContainer("Privatsphäre und Sicherheit", Icons.lock),//Email anzeigen, Passwort ändern
            SizedBox(height: 20),

          ],
        )
    );
  }

  getProfilFromDatabase() async {
    var userEmail = FirebaseAuth.instance.currentUser!.email;
    var docID = await dbGetProfilDocumentID(userEmail);
    var profil = await dbGetProfil(docID);

    return profil;
  }

  void getAndSetDataFromDB() async {
    try{
      var userProfil = await getProfilFromDatabase();
      List childrenDataYears = [];

      userProfil["kinder"].forEach((kind){
        var timestampToYears = globalFunctions.timeStampToAllDict(kind)["years"];
        childrenDataYears.add(timestampToYears);
      });

      setState(() {
        profilName = userProfil["name"];
        profilEmail = userProfil["email"];
        profilOrt = userProfil["ort"];
        profilInteressen = userProfil["interessen"];
        profilKinder = childrenDataYears;
        profilBio = userProfil["aboutme"];
        profilReiseart = userProfil["reiseart"];
        profilSprachen = userProfil["sprachen"];

        ortKontroller.text = profilOrt;
        reiseArtInput = CustomDropDownButton(
          items: globalVariablen.reisearten,
          selected: profilReiseart,
        );
        sprachenInputBox = CustomMultiTextForm(
          auswahlList: globalVariablen.sprachenListe,
          selected: profilSprachen,
        );
        interessenInputBox = CustomMultiTextForm(
          auswahlList: globalVariablen.interessenListe,
          selected: profilInteressen,
        );
      });

    } catch (error){
      print("Problem mit dem User finden");
    }

  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double containerPadding = 5;

    themeContainer(haupttext, beschreibung, changeWidget){
      return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => profilChangeWindow(context, beschreibung, changeWidget),
        child: Container(
            padding: EdgeInsets.only(top: containerPadding, bottom: containerPadding),
            width: width /2 -20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(haupttext,
                  style: TextStyle(fontSize: fontSize),
                ),
                SizedBox(height: 3),
                Text(beschreibung,
                  style: TextStyle(color: Colors.grey, fontSize: fontSize-2.0),
                ),
              ],
            )
        ),
      );
    }

    profilContainer(){
      return Container(
          width: double.maxFinite,
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
              border: Border(bottom: BorderSide(width: 10, color: borderColor))
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Profil",
                  style: TextStyle(color: Colors.blue, fontSize: fontSize)
              ),
              SizedBox(height: 5),
              Wrap(
                children: [
                  themeContainer(profilOrt, "Aktuelle Stadt", customTextfield("", ortKontroller)),
                  themeContainer(profilReiseart, "Art der Reise", reiseArtInput),
                  themeContainer(profilKinder.join(" , "), "Alter der Kinder", Container()),
                  themeContainer(profilInteressen.join(" , "), "Interessen",Container()),
                  themeContainer(profilSprachen.join(" , "), "Sprachen", sprachenInputBox)
                ],

              ),
              themeContainer(profilBio, "Über mich", Container())
            ],
          )
      );
    }

    menuBar(){

      openSettingWindow()async {
        var textColor = Colors.black;

        return showMenu(
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(
                Radius.circular(5.0),
              ),
            ),
            context: context,
            position: RelativeRect.fromLTRB(100, 0, 0, 100),
            items: [
              PopupMenuItem(
                  child: TextButton(
                    onPressed: null,
                    child: Text("Name ändern", style: TextStyle(color: textColor)))
              ),
              PopupMenuItem(
                  child: TextButton(
                      onPressed: null,
                      child: Text("Email ändern", style: TextStyle(color: textColor)))
              ),
              PopupMenuItem(
                  child: TextButton(
                      onPressed: null,
                      child: Text("Passwort ändern", style: TextStyle(color: textColor)))
              ),
              PopupMenuItem(
                  child: TextButton(
                      onPressed: null,
                      child: Text("Abmelden", style: TextStyle(color: textColor)))
              ),
            ]
        );
      }

      return Container(
        child: Row(
          children: [
            Expanded(child: SizedBox()),
            TextButton(
              style: ButtonStyle(
                  shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      )
                  )
              ),
              child: Icon(Icons.more_vert, color: Colors.black),
              onPressed: () => openSettingWindow(),
            )
          ],
        ),
      );
    }




    return Padding(
        padding: const EdgeInsets.only(top: 25),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              menuBar(),
              nameContainer(),
              profilContainer(),
              settingContainer()
          ]
        )
    );
  }
}
