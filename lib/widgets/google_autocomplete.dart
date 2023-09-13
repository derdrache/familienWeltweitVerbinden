import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../global/style.dart' as style;
import '../services/locationsService.dart';


class GoogleAutoComplete extends StatefulWidget {
  List<Map> searchableItems = [];
  double? width;
  bool isDense = false;
  TextEditingController searchKontroller = TextEditingController();
  bool isSearching = false;
  bool suche;
  String hintText;
  Map? googleSearchResult;
  var sessionToken = const Uuid().v4();
  Function? onConfirm;
  EdgeInsets margin;
  bool withOwnLocation;
  bool withWorldwideLocation;
  Color? borderColor;

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
    searchableItems = List<Map>.from(data["predictions"]);
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
      this.margin = const EdgeInsets.all(10),
      this.withOwnLocation = false,
      this.withWorldwideLocation = false,
      this.borderColor})
      : super(key: key);

  @override
  State<GoogleAutoComplete> createState() => _GoogleAutoCompleteState();
}

class _GoogleAutoCompleteState extends State<GoogleAutoComplete> {
  double dropdownExtraBoxHeight = 50;
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
    widget.borderColor ??= Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : Colors.black;

    return Container(
      margin: widget.margin,
      constraints: const BoxConstraints(maxWidth: style.webWidth),
      decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(style.roundedCorners)),
          border: Border.all(color: widget.borderColor!)),
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
                                var ownProfil = Hive.box("secureBox").get("ownProfil");

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
                  hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
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
