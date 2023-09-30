import 'dart:convert';
import 'dart:ui';
import 'dart:io';

import 'package:familien_suche/global/encryption.dart';
import 'package:familien_suche/widgets/custom_appbar.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../global/profil_sprachen.dart';
import '../../services/notification.dart' as notifications;
import '../../global/global_functions.dart' as global_functions;
import '../../global/global_functions.dart';
import '../../widgets/children_birthdate_picker.dart';
import '../../widgets/google_autocomplete.dart';
import '../../global/variablen.dart' as global_variablen;
import '../../services/database.dart';
import '../../widgets/layout/custom_dropdown_button.dart';
import '../../widgets/layout/custom_multi_select.dart';
import '../../widgets/layout/custom_snackbar.dart';
import '../../widgets/layout/custom_text_input.dart';
import '../start_page.dart';
import 'login_page.dart';

class CreateProfilPage extends StatefulWidget {
  const CreateProfilPage({Key? key}) : super(key: key);

  @override
  State<CreateProfilPage> createState() => _CreateProfilPageState();
}

class _CreateProfilPageState extends State<CreateProfilPage> {
  final _formKey = GlobalKey<FormState>();
  var userNameKontroller = TextEditingController();
  var aboutusKontroller = TextEditingController();
  var ortAuswahlBox = GoogleAutoComplete();
  var isGerman = kIsWeb
      ? PlatformDispatcher.instance.locale.languageCode == "de"
      : Platform.localeName == "de_DE";
  late CustomMultiTextForm sprachenAuswahlBox,interessenAuswahlBox;
  late CustomDropdownButton reiseArtenAuswahlBox;
  var childrenAgePickerBox = ChildrenBirthdatePickerBox();
  bool isLoading = false;

  @override
  void initState() {
    sprachenAuswahlBox = CustomMultiTextForm(
        auswahlList: isGerman
            ? ProfilSprachen().getAllGermanLanguages()
            : ProfilSprachen().getAllEnglishLanguages());

    reiseArtenAuswahlBox = CustomDropdownButton(
      items: isGerman
          ? global_variablen.reisearten
          : global_variablen.reiseartenEnglisch,
    );

    interessenAuswahlBox = CustomMultiTextForm(
        auswahlList: isGerman
            ? global_variablen.interessenListe
            : global_variablen.interessenListeEnglisch);

    refreshHiveMeetups();

    super.initState();
  }

  changeLoading() {
    if (isLoading) {
      isLoading = false;
    } else {
      isLoading = true;
    }

    setState(() {});
  }

  saveFunction() async {

    changeLoading();

    if (!_formKey.currentState!.validate()) {
      changeLoading();
      return;
    }

    var userName = userNameKontroller.text;
    userName = userName.replaceAll("'", "''");
    bool userExist =
        await ProfilDatabase().getData("id", "WHERE name = '$userName'") !=
            false;

    if (userExist && context.mounted) {
      customSnackBar(
          context, AppLocalizations.of(context)!.benutzerNamevergeben);
      changeLoading();
      return;
    }

    if (checkAllValidation(userExist, userName)) {
      var userID = FirebaseAuth.instance.currentUser?.uid;
      var email = FirebaseAuth.instance.currentUser?.email;
      var children = childrenAgePickerBox.getDates();
      var ortMapData = ortAuswahlBox.getGoogleLocationData();

      if (ortMapData["city"] == null && context.mounted) {
        customSnackBar(context, AppLocalizations.of(context)!.ortEingeben);
        changeLoading();
        return;
      }

      var data = {
        "id": userID,
        "email": encrypt(email!),
        "name": userName,
        "ort": ortMapData["city"],
        "interessen": interessenAuswahlBox.getSelected(),
        "kinder": children,
        "land": ortMapData["countryname"],
        "longt": ortMapData["longt"],
        "latt": ortMapData["latt"],
        "reiseart": reiseArtenAuswahlBox.getSelected(),
        "sprachen": sprachenAuswahlBox.getSelected(),
        "token": !kIsWeb ? await FirebaseMessaging.instance.getToken() : null,
        "lastLogin": DateTime.now().toString(),
        "aboutme": aboutusKontroller.text,
        "besuchteLaender":[ortMapData["countryname"]]
      };

      await ProfilDatabase().addNewProfil(data);

      await refreshHiveProfils();

      await NewsPageDatabase().addNewNews({
        "typ": "ortswechsel",
        "information": json.encode(ortMapData),
      });
      await refreshHiveNewsPage();

      notifications.prepareNewLocationNotification();

      if(context.mounted) global_functions.changePageForever(context, StartPage());

      additionalDatabaseOperations(ortMapData, userID);
    }

    changeLoading();
  }


  additionalDatabaseOperations(ortMapData, userId) async {
    StadtinfoDatabase().addFamiliesInCity(ortMapData, userId);

    await refreshHiveChats();
    await refreshHiveMeetups();
  }

  childrenInputValidation() {
    bool allFilled = true;

    childrenAgePickerBox.getDates().forEach((date) {
      if (date == null) {
        allFilled = false;
      }
    });
    return allFilled;
  }

  checkAllValidation(userExist, userName) {
    bool hasError = false;
    String errorString =
        "${AppLocalizations.of(context)!.bitteEingabeKorrigieren}\n";

    if (userExist) {
      errorString +=
          "- ${AppLocalizations.of(context)!.usernameInVerwendung}\n";
    }else if (reiseArtenAuswahlBox.getSelected().isEmpty) {
      errorString +=
          "- ${AppLocalizations.of(context)!.reiseartAuswaehlen}\n";
    } else if (sprachenAuswahlBox.getSelected().isEmpty) {
      errorString +=
          "- ${AppLocalizations.of(context)!.spracheAuswaehlen}\n";
    } else if (interessenAuswahlBox.getSelected().isEmpty) {
      errorString +=
          "- ${AppLocalizations.of(context)!.interessenAuswaehlen}\n";
    }else if (childrenAgePickerBox.getDates().length == 0 ||
        !childrenInputValidation()) {
      errorString +=
          "- ${AppLocalizations.of(context)!.geburtsdatumEingeben}\n";
    }else if (userName.length > 40) {
      errorString += "- ${AppLocalizations.of(context)!.usernameZuLang}";
    }


    if (errorString.length > 29) {
      hasError = true;

      customSnackBar(context, errorString);
    }

    return !hasError;
  }

  @override
  Widget build(BuildContext context) {
    sprachenAuswahlBox.hintText =
        AppLocalizations.of(context)!.spracheAuswaehlen;
    reiseArtenAuswahlBox.hintText =
        AppLocalizations.of(context)!.artDerReiseAuswaehlen;
    interessenAuswahlBox.hintText =
        AppLocalizations.of(context)!.interessenAuswaehlen;
    ortAuswahlBox.hintText = AppLocalizations.of(context)!.aktuellenOrtEingeben;

    return Scaffold(
      appBar: CustomAppBar(
        title: AppLocalizations.of(context)!.profilErstellen,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 35),
          onPressed: () {
            changePage(context, const LoginPage());
          },
        ),
        buttons: [
          isLoading
              ? const CircularProgressIndicator()
              : IconButton(
                  onPressed: () => saveFunction(),
                  tooltip: AppLocalizations.of(context)!.tooltipEingabeBestaetigen,
                  icon: const Icon(
                    Icons.done,
                    size: 30,
                  ),
                )
        ],
      ),
      body: Form(
        key: _formKey,
        child: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(dragDevices: {
            PointerDeviceKind.touch,
            PointerDeviceKind.mouse,
          }),
          child: ListView(
            children: [
              CustomTextInput(AppLocalizations.of(context)!.benutzername,
                  userNameKontroller,
                  validator: global_functions.checkValidatorEmpty(context)),
              Align(
                  child: Container(
                      margin: const EdgeInsets.only(left: 5, right: 5),
                      child: ortAuswahlBox)),
              reiseArtenAuswahlBox,
              sprachenAuswahlBox,
              interessenAuswahlBox,
              Align(
                child: Container(
                    width: 600,
                    padding: const EdgeInsets.all(10),
                    child: Text(
                      AppLocalizations.of(context)!.anzahlUndAlterKinder,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    )),
              ),
              childrenAgePickerBox,
              CustomTextInput(
                  "${AppLocalizations.of(context)!.aboutusHintText} *optional*",
                  aboutusKontroller,
                  moreLines: 4),
              Container(
                margin:
                    const EdgeInsets.only(top: 10, bottom: 5, right: 15, left: 15),
                child: FloatingActionButton.extended(
                    onPressed: () => saveFunction(), label: Text(AppLocalizations.of(context)!.profilErstellen)),
              )
            ],
          ),
        ),
      ),
    );
  }
}
