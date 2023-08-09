import 'package:familien_suche/services/locationsService.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../global/style.dart' as style;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class GoogleAutoComplete extends StatefulWidget {
  List<Map> searchableItems = [];
  double? width;
  bool isDense = false;
  TextEditingController searchKontroller = TextEditingController();
  bool isSearching = false;
  bool suche;
  String hintText;
  var googleSearchResult;
  var sessionToken = const Uuid().v4();
  Function? onConfirm;
  var margin;
  bool withOwnLocation;
  bool withWorldwideLocation;

  getGoogleLocationData() {
    return googleSearchResult ??
        {
          "city": null,
          "countryname": null,
          "longt": null,
          "latt": null,
          "adress": null
        };
  }

  _googleAutoCompleteSuche(input) async {
    var googleInput = input;
    searchableItems = [];
    var googleSuche = await LocationService()
        .getGoogleAutocompleteItems(googleInput, sessionToken);

    if (googleSuche.isEmpty) return;

    final Map<String, dynamic> data = Map.from(googleSuche);
    searchableItems = data["predictions"];
  }

  clear() {
    searchKontroller.clear();
  }

  setLocation(location) {
    googleSearchResult = location;
    searchKontroller.text = location["city"] + " / " + location["countryname"];
  }

  GoogleAutoComplete(
      {Key? key,
      this.hintText = "",
      this.width,
      this.suche = true,
      this.onConfirm,
      this.margin =
          const EdgeInsets.only(top: 5, bottom: 5, left: 10, right: 10),
      this.withOwnLocation = false,
      this.withWorldwideLocation = false})
      : super(key: key);

  @override
  _GoogleAutoCompleteState createState() => _GoogleAutoCompleteState();
}

class _GoogleAutoCompleteState extends State<GoogleAutoComplete> {
  double dropdownExtraBoxHeight = 50;
  var ownProfil = Hive.box("secureBox").get("ownProfil");
  bool focusOn = false;
  var myFocusNode = FocusNode();

  addEmptySearchItems(focusOn) {
    widget.searchableItems.clear();

    if(widget.withOwnLocation){
      widget.searchableItems.add({
        "description": AppLocalizations.of(context)!.aktuellenOrtVerwenden,
        "place_id": "ownLocation"
      });
    }

    if (widget.withWorldwideLocation) {
      widget.searchableItems.add({
        "description": AppLocalizations.of(context)!.weltweit,
        "place_id": "worldwide"
      });
    }
  }

  getGoogleSearchLocationData(placeId) async {
    var locationData = await LocationService()
        .getLocationdataFromGoogleID(placeId, widget.sessionToken);
    var databaseLocationData = await LocationService()
        .getDatabaseLocationdataFromGoogleResult(locationData);

    return databaseLocationData;
  }

  @override
  void initState() {
    myFocusNode.addListener(() {
      focusOn = myFocusNode.hasFocus;

      addEmptySearchItems(focusOn);

      setState(() {});
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(10),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(style.roundedCorners)),
          border: Border.all()),
      child: Stack(
        children: [
          RawAutocomplete(
            textEditingController: widget.searchKontroller,
            focusNode: myFocusNode,
            optionsViewBuilder: (BuildContext context,
                void Function(Map) onSelected, Iterable<Map> options) {
              return Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      width: MediaQuery.of(context).size.width - 21,
                      height: 300,
                      decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(),
                          borderRadius:
                              BorderRadius.circular(style.roundedCorners)),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(10.0),
                        itemCount: options.length,
                        itemBuilder: (BuildContext context, int index) {

                          final Map option = options.elementAt(index);
                          return GestureDetector(
                            onTap: () async {
                              if (option["place_id"] == "ownLocation") {
                                widget.googleSearchResult = {
                                  "city": ownProfil["ort"],
                                  "countryname": ownProfil["land"],
                                  "longt": ownProfil["longt"],
                                  "latt": ownProfil["latt"]
                                };
                                option["description"] =
                                    "${ownProfil["ort"]}, ${ownProfil["land"]}";
                              } else if (option["place_id"] == "worldwide") {
                                widget.googleSearchResult = {
                                  "city": "worldwide",
                                  "countryname": "worldwide",
                                  "longt": -50.1,
                                  "latt": 30.1
                                };
                                option["description"] =
                                    AppLocalizations.of(context)!.weltweit;
                              } else {
                                widget.googleSearchResult =
                                    await getGoogleSearchLocationData(
                                        option["place_id"]);
                              }

                              widget.searchKontroller.text =
                                  option["description"];
                              myFocusNode.unfocus();
                              if (widget.onConfirm != null) widget.onConfirm!();
                            },
                            child: ListTile(
                              title: Text(option["description"],
                                  style: const TextStyle(color: Colors.black)),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              );
            },
            optionsBuilder: (TextEditingValue textEditingValue) async{
              var inputValue = textEditingValue.text;

              if (inputValue.isEmpty) {
                addEmptySearchItems(true);
              } else if(inputValue.isNotEmpty) {
                await widget._googleAutoCompleteSuche(inputValue);
              }

              return widget.searchableItems;
            },
            fieldViewBuilder: (BuildContext context,
                TextEditingController textEditingController,
                FocusNode focusNode,
                VoidCallback onFieldSubmitted) {
              return TextFormField(
                controller: textEditingController,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: widget.hintText,
                  contentPadding: const EdgeInsets.all(10.0),
                ),
                focusNode: focusNode,
                onFieldSubmitted: (String value) {
                  onFieldSubmitted();
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
