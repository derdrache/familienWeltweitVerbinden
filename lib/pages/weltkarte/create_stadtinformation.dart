import 'package:familien_suche/widgets/google_autocomplete.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hive/hive.dart';

import '../../global/custom_widgets.dart';
import '../../services/database.dart';
import '../../services/translation.dart';
import '../../widgets/custom_appbar.dart';

class CreateStadtinformationsPage extends StatefulWidget {
  const CreateStadtinformationsPage({Key key}) : super(key: key);

  @override
  _CreateStadtinformationsPageState createState() =>
      _CreateStadtinformationsPageState();
}

class _CreateStadtinformationsPageState
    extends State<CreateStadtinformationsPage> {
  var ortEingabe = GoogleAutoComplete();
  var titleKontroller = TextEditingController();
  var beschreibungKontroller = TextEditingController();
  var onLoading = false;

  checkValidation() {
    if (ortEingabe.getGoogleLocationData() == null) {
      customSnackbar(context, AppLocalizations.of(context).stadtEingeben);
      return false;
    } else if (titleKontroller.text.isEmpty) {
      customSnackbar(
          context, AppLocalizations.of(context).titelStadtinformationEingeben);
      return false;
    } else if (titleKontroller.text.length > 100) {
      customSnackbar(context, AppLocalizations.of(context).titleZuLang);
      return false;
    } else if (beschreibungKontroller.text.isEmpty) {
      customSnackbar(context,
          AppLocalizations.of(context).beschreibungStadtinformationEingeben);
      return false;
    }

    return true;
  }

  save() async {
    setState(() {
      onLoading = true;
    });

    var ortData = ortEingabe.getGoogleLocationData();

    var titel = titleKontroller.text;
    var beschreibung = beschreibungKontroller.text;
    String titleGer, informationGer, titleEng, informationEng;

    if (!checkValidation()) {
      setState(() {
        onLoading = false;
      });
      return;
    }

    var textLanguage = await TranslationServices().getLanguage(titel);

    if (textLanguage == "en") {
      titleEng = titel;
      informationEng = beschreibung;
      titleGer =
          await TranslationServices().getTextTranslation(titel, "en", "de");
      informationEng = await TranslationServices()
          .getTextTranslation(beschreibung, "en", "de");
    } else {
      titleGer = titel;
      informationGer = beschreibung;
      titleEng = "";
      informationEng = "";
      titleEng =
          await TranslationServices().getTextTranslation(titel, "de", "en");
      informationEng = await TranslationServices()
          .getTextTranslation(beschreibung, "de", "en");
    }

    StadtinfoDatabase().addNewCity(ortData);

    StadtinfoUserDatabase().addNewInformation({
      "ort": ortData["city"],
      "land": ortData["countryname"],
      "latt": ortData["latt"],
      "longt": ortData["longt"],
      "sprache": textLanguage,
      "titleGer": titleGer,
      "informationGer": informationGer,
      "titleEng": titleEng,
      "informationEng": informationEng,
    });

    var stadtinfoUser =
        StadtinfoUserDatabase().getData("*", "", returnList: true);
    Hive.box("stadtinfoUserBox").put("list", stadtinfoUser);

    Navigator.pop(context);
    customSnackbar(
        context, AppLocalizations.of(context).insiderInformationEingetragen, color: Colors.green);
  }

  @override
  Widget build(BuildContext context) {
    ortEingabe.hintText = AppLocalizations.of(context).stadtEingeben;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: CustomAppBar(
        title: AppLocalizations.of(context).stadtinformationErstellen,
        buttons: [
          if(!onLoading) IconButton(onPressed: () => save(), icon: const Icon(Icons.save)),
          if(onLoading) Container(
              width: 30,
              padding: const EdgeInsets.only(top:20, right: 10, bottom: 20),
              child: const CircularProgressIndicator(
                color: Colors.white,
              ))
        ],
      ),
      body: Column(children: [
        ortEingabe,
        customTextInput(AppLocalizations.of(context).titel, titleKontroller),
        customTextInput(
            AppLocalizations.of(context).beschreibung, beschreibungKontroller,
            moreLines: 10, textInputAction: TextInputAction.newline),
      ]),
    );
  }
}
