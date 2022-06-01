import 'package:familien_suche/pages/weltkarte/stadtinformation.dart';
import 'package:familien_suche/widgets/google_autocomplete.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';

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
    var ortData = ortEingabe.getGoogleLocationData();
    String titel = titleKontroller.text;
    String beschreibung = beschreibungKontroller.text;
    DateTime now = DateTime.now();
    DateFormat formatter = DateFormat('yyyy-MM-dd');
    String nowFormatted = formatter.format(now);
    String titleGer, informationGer, titleEng, informationEng;

    setState(() {
      onLoading = true;
    });

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
      informationGer = await TranslationServices()
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

    await StadtinfoDatabase().addNewCity(ortData);
    var stadtInfo =
        await StadtinfoDatabase().getData("*", "", returnList: true);
    Hive.box("secureBox").put("stadtinfo", stadtInfo);

    var newUserInformation = {
      "ort": ortData["city"],
      "sprache": textLanguage,
      "titleGer": titleGer,
      "informationGer": informationGer,
      "titleEng": titleEng,
      "informationEng": informationEng,
      "erstelltAm": nowFormatted,
      "thumbUp": [],
      "thumbDown": []
    };

    StadtinfoUserDatabase().addNewInformation(newUserInformation);

    var secureBox =Hive.box("secureBox");
    var allInformations = secureBox.get("stadtinfoUser");
    allInformations.add(newUserInformation);
    secureBox.put("stadtinfoUser", allInformations);

    Navigator.pop(context);
    changePage(context, StadtinformationsPage(ortName: ortData["city"]));
  }

  @override
  Widget build(BuildContext context) {
    ortEingabe.hintText = AppLocalizations.of(context).stadtEingeben;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: CustomAppBar(
        title: AppLocalizations.of(context).stadtinformationErstellen,
        buttons: [
          if (!onLoading)
            IconButton(onPressed: () => save(), icon: const Icon(Icons.done)),
          if (onLoading)
            Container(
                width: 30,
                padding: const EdgeInsets.only(top: 20, right: 10, bottom: 20),
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
