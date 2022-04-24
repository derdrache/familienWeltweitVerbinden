import 'package:flutter/material.dart';
import '../../global/custom_widgets.dart';
import '../../widgets/google_autocomplete.dart';
import '../../services/database.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ChangeCityPage extends StatefulWidget {
  var userId;

  ChangeCityPage({Key key, this.userId}) : super(key: key);

  @override
  _ChangeCityPageState createState() => _ChangeCityPageState();
}

class _ChangeCityPageState extends State<ChangeCityPage> {
  var ortChangeKontroller = TextEditingController();
  var suggestedCities = [];
  List<Widget> suggestedCitiesList = [];
  int selectedIndex = -1;
  var locationData = {};
  var autoComplete = GoogleAutoComplete();

  @override
  void initState() {
    super.initState();
  }

  pushLocationDataToDB(locationData) async {
    var locationDict = {
      "ort": locationData["city"],
      "longt": locationData["longt"],
      "latt": locationData["latt"],
      "land": locationData["countryname"],
    };

    await ProfilDatabase().updateProfilLocation(widget.userId, locationDict);
  }

  saveLocation() async {
    var locationData = autoComplete.getGoogleLocationData();

    if(locationData["city"] == null) {
      customSnackbar(context, AppLocalizations.of(context).ortEingeben);
      return;
    }

    await pushLocationDataToDB(locationData);
    customSnackbar(context,
        AppLocalizations.of(context).aktuelleOrt +" "+
            AppLocalizations.of(context).erfolgreichGeaender, color: Colors.green);
    Navigator.pop(context);
  }

  saveButton(){
    return TextButton(
        child: Icon(Icons.done),
        onPressed: () => saveLocation()

    );
  }

  @override
  Widget build(BuildContext context) {
    autoComplete.hintText = AppLocalizations.of(context).aktuellenOrtEingeben;

    return Scaffold(
      appBar: customAppBar(
          title: AppLocalizations.of(context).ortAendern,
          buttons: <Widget>[saveButton()]
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          autoComplete,
        ],
      ),
    );
  }
}
