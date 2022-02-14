import 'package:flutter/material.dart';
import '../../global/custom_widgets.dart';
import '../../services/locationsService.dart';
import '../../services/database.dart';

class ChangeCityPage extends StatefulWidget {
  var userId;

  ChangeCityPage({Key? key, this.userId}) : super(key: key);




  @override
  _ChangeCityPageState createState() => _ChangeCityPageState();
}

class _ChangeCityPageState extends State<ChangeCityPage> {
  var ortChangeKontroller = TextEditingController();
  var suggestedCities = [];
  List<Widget> suggestedCitiesList = [];
  int selectedIndex = -1;
  var locationData = {};

  @override
  void initState() {
    super.initState();
  }

  pushLocationDataToDB(locationData) async {

    var locationDict = {
      "ort": locationData["city"],
      "longt": locationData["longt"],
      "latt": locationData["latt"],
      "land": locationData["countryname"]
    };

    ProfilDatabase().updateProfil(
        widget.userId, locationDict
    );
  }

  saveButton(){
    return TextButton(
        child: Icon(Icons.done),
        onPressed: () async {
          if(suggestedCities.isEmpty) {
            suggestedCities = await LocationService()
                .getLocationMapDataGoogle2(ortChangeKontroller.text);

            if(suggestedCities.length > 1){
              setState(() {});
              customSnackbar(context, "genauen Ort auswählen");
            } else{
              pushLocationDataToDB(suggestedCities[0]);
              Navigator.pop(context);
            }
          }
        },

    );
  }

  @override
  Widget build(BuildContext context) {
    createSuggestedList(List suggestedCities){
      List<Widget> newSuggestList = [];

      for(var i = 0; i<suggestedCities.length; i++){
        newSuggestList.add(
            GestureDetector(
              onTap: () {
                selectedIndex = i;
                locationData = suggestedCities[i];
                pushLocationDataToDB(locationData);
                Navigator.pop(context);
              },
              child: Container(
                  margin: const EdgeInsets.only(top:20, left: 10),
                  child: Text(
                    suggestedCities[i]["adress"],
                    style: TextStyle(
                        fontSize: 16,
                        color: selectedIndex == i ? Colors.green : Colors.black)
                    ,)
              ),
            )
        );
      }

      suggestedCitiesList = newSuggestList;

    }

    createSuggestedList(suggestedCities);


    return Scaffold(
      appBar: customAppBar(title: "Aktuelle Stadt ändern", button: saveButton()),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          customTextInput("Stadt eingeben", ortChangeKontroller, onSubmit: () async{
            suggestedCities = await LocationService()
                .getLocationMapDataGoogle2(ortChangeKontroller.text);

            setState(() {});

          }),
          suggestedCitiesList.isNotEmpty ? const Padding(
            padding: EdgeInsets.all(12.0),
            child: Text(
              "Bitte den gewünschten Ort auswählen:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ): const SizedBox.shrink(),
          ...suggestedCitiesList

        ],
      ),
    );
  }
}
