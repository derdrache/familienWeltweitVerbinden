import 'package:familien_suche/pages/weltkarte/stadtinformation.dart';
import 'package:familien_suche/widgets/google_autocomplete.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hive/hive.dart';

import '../../global/custom_widgets.dart';
import '../../global/global_functions.dart';
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
    //var ortData = ortEingabe.getGoogleLocationData();

    var ortData = {
      "city": "Puerto Morelos",
      "countryname": "Mexico",
      "longt": -86.8755342,
      "latt": 20.8478084,
    };

    var titel = titleKontroller.text;
    var beschreibung = beschreibungKontroller.text;
    String titleGer, informationGer, titleEng, informationEng;


    if (!checkValidation()) return;

    
    var textLanguage = await TranslationServices().getLanguage(titel);

    if(textLanguage == "en"){
      titleEng = titel;
      informationEng = beschreibung;
      titleGer = await TranslationServices().getTextTranslation(titel, "en", "de");
      informationEng = await TranslationServices().getTextTranslation(beschreibung, "en", "de");
    } else{
      titleGer =titel;
      informationGer = beschreibung;
      titleEng = "";
      informationEng = "";
      titleEng = await TranslationServices().getTextTranslation(titel, "de", "en");
      informationEng = await TranslationServices().getTextTranslation(beschreibung, "de", "en");
    }


    await StadtinfoUserDatabase().addNewInformation({
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
        await StadtinfoUserDatabase().getData("*", "", returnList: true);
    Hive.box("stadtinfoUserBox").put("list", stadtinfoUser);



    Navigator.pop(context);

    changePage(
        context,
        StadtinformationsPage(ortName: ortData["city"])
    );
  }

  @override
  Widget build(BuildContext context) {
    ortEingabe.hintText = AppLocalizations.of(context).stadtEingeben;

    return Scaffold(
      appBar: CustomAppBar(
          title: AppLocalizations.of(context).stadtinformationErstellen,
          buttons: [
            IconButton(
                onPressed: () => save(),
                icon: const Icon(Icons.done, color: Colors.green))
          ]),
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
