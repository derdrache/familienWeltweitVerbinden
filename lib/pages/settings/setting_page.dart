import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/link.dart';

import '../../services/database.dart';
import '../../services/locationsService.dart';
import '../../global/global_functions.dart' as globalFunctions;
import '../../global/variablen.dart' as globalVariablen;
import '../../global/custom_widgets.dart';
import '../../windows/change_profil_window.dart';
import '../login_register_page/login_page.dart';
import 'package:familien_suche/pages/settings/privacy_security_page.dart';
import 'feedback_page.dart';


class SettingPage extends StatefulWidget {
  const SettingPage({Key? key}) : super(key: key);

  @override
  _SettingPageState createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  double globalPadding = 30;
  double fontSize = 16;
  var borderColor = Colors.grey[200]!;
  var userID = FirebaseAuth.instance.currentUser!.uid;
  var userProfil;
  var nameTextKontroller = TextEditingController();
  var kinderAgeBox = ChildrenBirthdatePickerBox();
  var interessenInputBox = CustomMultiTextForm(
      auswahlList: globalVariablen.interessenListe);
  var bioTextKontroller = TextEditingController();
  var emailTextKontroller = TextEditingController();
  var passwortTextKontroller1 = TextEditingController();
  var passwortTextKontroller2 = TextEditingController();
  var passwortCheckKontroller = TextEditingController();
  var reiseArtInput = CustomDropDownButton(items: globalVariablen.reisearten);
  var sprachenInputBox = CustomMultiTextForm(
      auswahlList: globalVariablen.sprachenListe);
  var ortKontroller = TextEditingController();
  String beschreibungStadt = "Aktuelle Stadt";
  String beschreibungReise  = "Art der Reise";
  String beschreibungKinder = "Alter der Kinder";
  String beschreibungInteressen = "Interessen";
  String beschreibungSprachen = "Sprachen";
  String beschreibungBio = "Über mich";
  String beschreibungName = "Name ändern";
  String beschreibungEmail = "Email ändern";
  String beschreibungPasswort = "Passwort ändern";
  String beschreibungFeedback = "Feedback geben";

  @override
  void initState() {

    getAndSetDataFromDB();


    super.initState();
  }


  getProfilFromDatabase() async {
    emailTextKontroller.text = FirebaseAuth.instance.currentUser!.email!;
    nameTextKontroller.text = FirebaseAuth.instance.currentUser!.displayName!;
    userProfil = await ProfilDatabaseKontroller().getProfil(userID);
  }

  void getAndSetDataFromDB() async {
    List childrenAgeTimestamp = [];
    try{
      await getProfilFromDatabase();
      List childrenDataYears = [];

      userProfil["kinder"].forEach((kind){
        var changeTimeStamp = globalFunctions.timeStampToAllDict(kind);
        childrenDataYears.add(changeTimeStamp["years"]);
        childrenAgeTimestamp.add(changeTimeStamp["date"]);
      });

      setState(() {
        nameTextKontroller.text = userProfil["name"];
        emailTextKontroller.text = userProfil["email"];
        ortKontroller.text = userProfil["ort"];
        interessenInputBox.selected = userProfil["interessen"];
        kinderAgeBox.setSelected(childrenAgeTimestamp);
        bioTextKontroller.text = userProfil["aboutme"];
        reiseArtInput.selected = userProfil["reiseart"];
        sprachenInputBox.selected = userProfil["sprachen"];
      });
    } catch (error){
      print("Problem mit dem User finden");
    }


  }

  pushLocationDataToDB(locationData) async {

    var locationDict = {
      "ort": locationData["city"],
      "longt": double.parse(locationData["longt"]),
      "latt": double.parse(locationData["latt"]),
      "land": locationData["countryname"]
    };

    ProfilDatabaseKontroller().updateProfil(
        userID, locationDict
    );
  }

  userLogin(passwort) async {
    var loginUser;

    try {
      loginUser = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: userProfil["email"],
          password: passwort
      );
    } on FirebaseAuthException catch  (e) {
      loginUser = null;
    }

    return loginUser;
  }

  validAndSave(beschreibung) async{
    String errorMessage = "";

    if(beschreibung == beschreibungStadt){
      errorMessage = changeStadt();
    }else if(beschreibung == beschreibungReise){
      errorMessage = changeReiseart();
    }else if(beschreibung == beschreibungKinder){
      errorMessage = changeKinderAge();
    }else if(beschreibung == beschreibungInteressen){
      errorMessage = changeInteressen();
    }else if(beschreibung == beschreibungSprachen){
      errorMessage = changeSprachen();
    }else if(beschreibung == beschreibungBio){
      if(bioTextKontroller.text != userProfil["aboutme"]){
        ProfilDatabaseKontroller().updateProfil(
            userID, {"aboutme": bioTextKontroller.text});
      }
    }else if(beschreibung == beschreibungName){

      errorMessage = await changeName();
    } else if (beschreibung == beschreibungEmail){
      errorMessage = await changeEmail();
    } else if (beschreibung == beschreibungPasswort){
      errorMessage = await changePasswort();
    }

    if(errorMessage.isEmpty){
      setState(() {});
      Navigator.of(context, rootNavigator: true).pop();
    } else{
      customSnackbar(context, errorMessage);
    }


  }

  changeStadt() async {
    var errorMessage = "";

    if(ortKontroller.text == ""){
      errorMessage += "Neue Stadt eingeben";
    } else if (ortKontroller.text != userProfil["ort"]){
      var locationData = await LocationService().getLocationData(ortKontroller.text);

      if (locationData != null){
        pushLocationDataToDB(locationData);
      } else {
        errorMessage += "Stadt nicht gefunden";
      }

    }

    return errorMessage;
  }

  changeReiseart(){
    var errorMessage = "";

    if(reiseArtInput.getSelected() == null || reiseArtInput.getSelected().isEmpty){
      errorMessage = "neue Reiseart eingeben";
    } else if(reiseArtInput.getSelected() != userProfil["reiseart"] ){
      ProfilDatabaseKontroller().updateProfil(
          userID, {"reiseart": reiseArtInput.getSelected()}
      );
    }

    return errorMessage;
  }

  changeKinderAge(){
    var errorMessage = "";
    bool allFilled = true;

    for(var kindAge in kinderAgeBox.getDates()){
      if (kindAge == null){
        allFilled = false;
      }
    }

    if(!allFilled || kinderAgeBox.getDates().isEmpty){
      errorMessage = "Geburtsdaten eingeben";
    } else if (kinderAgeBox.getDates() != userProfil["kinder"]){
      ProfilDatabaseKontroller().updateProfil(
          userID, {"kinder": kinderAgeBox.getDates()}
      );
    }

    return errorMessage;
  }

  changeInteressen(){
    var errorMessage = "";

    if(interessenInputBox.getSelected() == null || interessenInputBox.getSelected().isEmpty){
      errorMessage = "neue interessen eingeben";
    } else if(interessenInputBox.getSelected() != userProfil["interessen"]){
      ProfilDatabaseKontroller().updateProfil(
          userID, {"interessen": interessenInputBox.getSelected()}
      );
    }
    return errorMessage;
  }

  changeSprachen(){
    var errorMessage = "";

    if(sprachenInputBox.getSelected() == null || sprachenInputBox.getSelected().isEmpty){
      errorMessage = "Sprache eingeben";
    } else if(sprachenInputBox.getSelected() != userProfil["sprachen"]){
      ProfilDatabaseKontroller().updateProfil(
          userID, {"sprachen": sprachenInputBox.getSelected()}
      );
    }
    return errorMessage;
  }

  changeName() async{
    var errorMessage = "";
    var userProfil = await ProfilDatabaseKontroller().getProfil(nameTextKontroller.text);

    if(nameTextKontroller.text == null || nameTextKontroller.text == ""){
      errorMessage = "Neuen Namen eingeben";
    } else{
      if(userProfil == null){
        ProfilDatabaseKontroller().updateProfilName(
            userID, userProfil["name"],
            nameTextKontroller.text
        );
      } else {
        errorMessage += "- Name schon vorhanden";
      }
    }
    return errorMessage;

  }

  changeEmail() async {
    var errorString = "";

    if(passwortTextKontroller1.text != "" && emailTextKontroller.text != ""){
      bool emailIsValid = RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
          .hasMatch(emailTextKontroller.text);
      var emailInUse = await ProfilDatabaseKontroller()
          .getProfilIDFromEmail(emailTextKontroller.text);

      if (emailInUse != null){
        errorString += "- Email wird schon verwendet";
      } else if (emailIsValid){
        var loginUser = await userLogin(passwortTextKontroller1);

        if(loginUser != null){
          return "";
        } else{
          errorString += "falsches Passwort";
        }
      } else {
        errorString += "- ungültige Email";
      }
    } else{
      if(passwortTextKontroller1.text == ""){
        errorString += "- Passwort eingeben \n";
      }
      if(emailTextKontroller.text == ""){
        errorString += "- Email eingeben \n";
      }
    }

    if(errorString == ""){
      FirebaseAuth.instance.currentUser?.updateEmail(emailTextKontroller.text);
      ProfilDatabaseKontroller().updateProfil(
          userID, {"email":emailTextKontroller.text }
      );

    }

    return errorString;
  }

  changePasswort() async {
    var errorMessage = "";
    var newPasswort = passwortTextKontroller1.text;
    var newPasswortCheck = passwortTextKontroller2.text;
    var oldPasswort = passwortCheckKontroller.text;

    if(newPasswort != "" && newPasswortCheck != "" && oldPasswort != "" &&
        newPasswort != oldPasswort){
      if (newPasswort == newPasswortCheck ){
        try{
          var loginTest = await userLogin(passwortCheckKontroller.text);

          if (loginTest != null){
            await FirebaseAuth.instance.currentUser?.updatePassword(passwortTextKontroller1.text);
          } else {
            errorMessage += "- Altes Passwort ist falsch";
          }

        } catch (error){
          errorMessage += "- Neues Passwort ist zu schwach";
        }

      } else{
        errorMessage += "- Passwort bestätigung stimmt nicht mit dem neuen Passwort überein";
      }
    }else{
      if (newPasswort == "" || newPasswort == oldPasswort){
        errorMessage += "- neues Passwort eingeben \n";
      }
      if(newPasswortCheck == ""){ errorMessage += "- neues Passwort bestätigen \n"; }
      if(oldPasswort == ""){errorMessage += "- altes Passwort eingeben"; }

    }
    return errorMessage;
  }


  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double containerPadding = 5;


    profilThemeContainer(haupttext, beschreibung, changeWidget){
      return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => profilChangeWindow(context, beschreibung, changeWidget,
          () => validAndSave(beschreibung),
        ),
        child: Container(
            padding: EdgeInsets.only(top: containerPadding, bottom: containerPadding),
            width: width /2 -20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                haupttext == ""? CircularProgressIndicator() : Text(
                  haupttext,
                  overflow: TextOverflow.ellipsis,
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

    emailChangeWindow(){
      emailTextKontroller.text = "";
      passwortTextKontroller1.text = "";

      return Column(
        children: [
          customTextInput(beschreibungEmail,emailTextKontroller),
          SizedBox(height: 15),
          customTextInput("Passwort bestätigen",passwortTextKontroller1, passwort: true)
        ],
      );
    }

    passwortChangeWindow(){
      passwortTextKontroller1.text = "";
      passwortTextKontroller2.text = "";
      passwortCheckKontroller.text = "";

      return Column(
        children: [
          customTextInput("Neues Passwort eingeben", passwortTextKontroller1,
              passwort: true),
          SizedBox(height: 15),
          customTextInput("Neues Passwort wiederholen", passwortTextKontroller2,
              passwort: true),
          SizedBox(height: 15),
          customTextInput("Altes Passwort eingeben", passwortCheckKontroller,
              passwort: true)
        ],
      );
    }

    menuBar(){

      openSettingWindow()async {
        var textColor = Colors.black;
        nameTextKontroller.text = "";

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
                      onPressed: () => profilChangeWindow(context, beschreibungName,
                          customTextInput(beschreibungName,nameTextKontroller),
                              () => validAndSave(beschreibungName)),
                      child: Text(beschreibungName, style: TextStyle(color: textColor)))
              ),
              PopupMenuItem(
                  child: TextButton(
                      onPressed: () => profilChangeWindow(context, beschreibungEmail,
                          emailChangeWindow(),
                          () => validAndSave(beschreibungEmail)
                      ),
                      child: Text(beschreibungEmail, style: TextStyle(color: textColor))
                  )
              ),
              PopupMenuItem(
                  child: TextButton(
                      onPressed: () => profilChangeWindow(context, beschreibungPasswort,
                          passwortChangeWindow(),
                              () => validAndSave(beschreibungPasswort)),
                      child: Text(beschreibungPasswort, style: TextStyle(color: textColor)))
              ),
              PopupMenuItem(
                  child: TextButton(
                      onPressed: () {
                        FirebaseAuth.instance.signOut();
                        globalFunctions.changePage(context, LoginPage());
                      },
                      child: Text("Abmelden", style: TextStyle(color: textColor)))
              ),
            ]
        );
      }

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
            child: Icon(Icons.more_vert, color: Colors.black),
            onPressed: () => openSettingWindow(),
          )
      );
    }

    nameContainer(){
      return Container(
          width: double.maxFinite,
          padding: EdgeInsets.only(left: 10, right: 10, bottom: 10),
          decoration: BoxDecoration(
              border: Border(bottom: BorderSide(width: 10, color: borderColor))
          ),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nameTextKontroller.text,
                  style: TextStyle(fontSize: 30),
                ),
                Text(emailTextKontroller.text)
              ]
          )
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
              Row(children: [
                Text("Profil",
                    style: TextStyle(color: Colors.blue, fontSize: fontSize)
                ),
                Expanded(child: SizedBox()),
                Text("Antippen, um Einträge zu ändern",style: TextStyle(color: Colors.grey, fontSize: 14)),
                Expanded(child: SizedBox()),
              ]),
              SizedBox(height: 5),
              Wrap(
                children: [
                  profilThemeContainer(ortKontroller.text, beschreibungStadt ,
                      customTextInput("", ortKontroller)),
                  profilThemeContainer(reiseArtInput.getSelected(), beschreibungReise, reiseArtInput),
                  profilThemeContainer(kinderAgeBox.getDates(years: true)  == null? "":
                  kinderAgeBox.getDates(years: true).join(" , "),
                      beschreibungKinder, kinderAgeBox),
                  profilThemeContainer(
                      interessenInputBox.getSelected() == null? "" :
                      interessenInputBox.getSelected().join(" , "),
                      beschreibungInteressen,interessenInputBox),
                  profilThemeContainer(
                      sprachenInputBox.getSelected() == null? "":
                      sprachenInputBox.getSelected().join(" , "),
                      beschreibungSprachen, sprachenInputBox)
                ],
              ),
              profilThemeContainer(bioTextKontroller.text== ""? " ": bioTextKontroller.text,
                  beschreibungBio,
                  customTextInput("über mich", bioTextKontroller, moreLines: 10)
              )
            ],
          )
      );
    }

    settingThemeContainer(title, icon, function){
      return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: function,
        child: Container(
            child: Row(
              children: [
                Icon(icon),
                SizedBox(width: 20),
                Text(title)
              ],
            )
        ),
      );
    }

    settingContainer(){

      return Container(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Einstellungen",
                  style: TextStyle(color: Colors.blue, fontSize: fontSize)),
              SizedBox(height: 20),
              settingThemeContainer("Privatsphäre und Sicherheit", Icons.lock,
                      () => globalFunctions.changePage(
                          context, PrivacySecurityPage(profil: userProfil)
                      )
              ),
            ],
          )
      );
    }

    aboutAppContainer(){

      themeContainer(title, icon, url){
        return Link(
          target: LinkTarget.blank,
          uri: Uri.parse(url),
          builder: (context, followLink) => GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: followLink,
            child: Container(
                child: Row(
                  children: [
                    Icon(icon),
                    SizedBox(width: 20),
                    Text(title)
                  ],
                )
            ),
          ),
        );
      }

      return Container(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("App Informationen",
                  style: TextStyle(color: Colors.blue, fontSize: fontSize)),
              SizedBox(height: 20),
              settingThemeContainer("Feedback", Icons.feedback,
                      () => globalFunctions.changePage(
                      context, FeedbackPage(profil: userProfil)
                  )
              ),
              SizedBox(height: 20),
              themeContainer("Patch Notes", Icons.format_list_bulleted,
                  "https://docs.google.com/document/d/1Mjexik9-MqgpKDNkkosBLZ7cQGtvnexcM_MKMi0XGqw/edit?usp=sharing"),
              SizedBox(height: 20),
              themeContainer("Geplante Erweiterungen", Icons.task,
                  "https://docs.google.com/spreadsheets/d/1bnxfdw-MsaKHWSxtpxIm7rmbyd3N-dvqmCSNdkixAeU/edit?usp=sharing"),
              SizedBox(height: 20),
              //themeContainer("Über das Projekt", Icons.description, ""),
              //SizedBox(height: 20),
              themeContainer("Spenden", Icons.card_giftcard,
                  "https://www.paypal.com/paypalme/DominikMast"),
            ],
          )
      );
    }


    return Padding(
        padding: const EdgeInsets.only(top: 5),
        child: ListView(
            children: [
              menuBar(),
              nameContainer(),
              profilContainer(),
              settingContainer(),
              aboutAppContainer()
          ]
        )
    );
  }
}
