import 'package:familien_suche/widgets/google_autocomplete.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../global/custom_widgets.dart';
import '../../services/database.dart';

class CreateStadtinformationsPage extends StatefulWidget {
  const CreateStadtinformationsPage({Key key}) : super(key: key);

  @override
  _CreateStadtinformationsPageState createState() => _CreateStadtinformationsPageState();
}

class _CreateStadtinformationsPageState extends State<CreateStadtinformationsPage> {
  var ortEingabe = GoogleAutoComplete();
  var titleKontroller = TextEditingController();
  var beschreibungKontroller = TextEditingController();

  checkValidation(){
    if(ortEingabe.getGoogleLocationData() == null){
      customSnackbar(context, AppLocalizations.of(context).stadtEingeben);
      return false;
    }else if(titleKontroller.text.isEmpty){
      customSnackbar(context, AppLocalizations.of(context).titelStadtinformationEingeben);
      return false;
    }else if(beschreibungKontroller.text.isEmpty){
      customSnackbar(context, AppLocalizations.of(context).beschreibungStadtinformationEingeben);
      return false;
    }

    return true;
  }

  save(){
    var ortData = ortEingabe.getGoogleLocationData();
    var titel = titleKontroller.text;
    var beschreibung = beschreibungKontroller.text;

    if(!checkValidation()) return;

    StadtinfoUserDatabase().addNewInformation({
        "ort": ortData["city"],
        "land": ortData["countryname"],
        "latt": ortData["latt"],
        "longt": ortData["longt"],
        "title": titel,
        "information": beschreibung,
      });

    Navigator.pop(context);

  }

  @override
  Widget build(BuildContext context) {
    ortEingabe.hintText = AppLocalizations.of(context).stadtEingeben;

    return Scaffold(
      appBar: customAppBar(
        title: AppLocalizations.of(context).stadtinformationErstellen,
        buttons: [
          IconButton(
              onPressed: () => save(),
              icon: const Icon(Icons.done, color: Colors.green)
          )
        ]
      ),
      body: Column(children: [
        ortEingabe,
        customTextInput(AppLocalizations.of(context).titel, titleKontroller),
        customTextInput(
          AppLocalizations.of(context).beschreibung,beschreibungKontroller,
          moreLines: 6,
          textInputAction: TextInputAction.newline
        ),
      ]),
    );
  }
}
