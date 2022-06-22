import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../global/custom_widgets.dart';
import '../../widgets/custom_appbar.dart';
import '../../widgets/google_autocomplete.dart';
import '../../services/database.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ChangeCityPage extends StatefulWidget {
  var userId = FirebaseAuth.instance.currentUser.uid;

  ChangeCityPage({Key key}) : super(key: key);

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
  var isLoading = false;

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
    await StadtinfoDatabase().addNewCity(locationDict);
    await StadtinfoDatabase().update(
        "familien = JSON_ARRAY_APPEND(familien, '\$', '${widget.userId}')",
        "WHERE ort LIKE '${locationData["city"]}' AND JSON_CONTAINS(familien, '\"${widget.userId}\"') < 1"
    );



  }

  saveLocation() async {
    setState(() {
      isLoading = true;
    });

    var locationData = autoComplete.getGoogleLocationData();


    if(locationData["city"] == null) {
      setState(() {
        isLoading = false;
      });

      customSnackbar(context, AppLocalizations.of(context).ortEingeben);
      return;
    }


    await pushLocationDataToDB(locationData);
    customSnackbar(context,
        AppLocalizations.of(context).aktuelleOrt +" "+
            AppLocalizations.of(context).erfolgreichGeaender, color: Colors.green);
    Navigator.pop(context);
  }


  @override
  Widget build(BuildContext context) {
    autoComplete.hintText = AppLocalizations.of(context).aktuellenOrtEingeben;

    return Scaffold(
      appBar: CustomAppBar(
          title: AppLocalizations.of(context).ortAendern,
          buttons: <Widget>[
            if(!isLoading) IconButton(
                icon: const Icon(Icons.done),
                onPressed: () => saveLocation()
            ),
            if(isLoading) Container(
                width: 30,
                padding: const EdgeInsets.only(top:20, right: 10, bottom: 20),
                child: const CircularProgressIndicator(
                  color: Colors.white,
                ))

          ]
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
