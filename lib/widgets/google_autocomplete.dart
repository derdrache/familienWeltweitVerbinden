import 'package:familien_suche/services/locationsService.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../global/variablen.dart' as global_var;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class GoogleAutoComplete extends StatefulWidget {
  List searchableItems = [];
  List autoCompleteItems = [];
  double? width;
  var isDense = false;
  var searchKontroller = TextEditingController();
  bool isSearching = false;
  bool suche;
  String hintText;
  var googleSearchResult;
  var sessionToken = const Uuid().v4();
  Function? onConfirm;
  var margin;
  bool withOwnLocation;

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

  clear(){
    searchKontroller.clear();
  }

  setLocation(location){
    googleSearchResult = location;
    searchKontroller.text = location["city"] +" / " + location["countryname"];
  }

  GoogleAutoComplete({
    Key? key,
    this.hintText = "",
    this.width,
    this.suche = true,
    this.onConfirm,
    this.margin = const EdgeInsets.only(top: 5, bottom:5, left:10, right:10),
    this.withOwnLocation = false
  }) : super(key: key);

  @override
  _GoogleAutoCompleteState createState() => _GoogleAutoCompleteState();
}

class _GoogleAutoCompleteState extends State<GoogleAutoComplete> {
  double dropdownExtraBoxHeight = 50;
  var ownProfil = Hive.box("secureBox").get("ownProfil");

  showAutoComplete(text) {
    if (text.length == 0) {
      widget.isSearching = false;
    } else {
      widget.isSearching = true;
    }

    setState(() {});
  }

  addAutoCompleteItems(text) {
    widget.autoCompleteItems = [];
    if (text.isEmpty) return widget.autoCompleteItems;

    for (var item in widget.searchableItems) {
      if (item["description"] != widget.searchKontroller.text) {
        widget.autoCompleteItems.add(item);
      }
    }
  }

  resetSearchBar() {
    widget.isSearching = false;
    widget.autoCompleteItems = [];
    FocusScope.of(context).unfocus();

    setState(() {});
  }

  getGoogleSearchLocationData(placeId) async {
    var locationData = await LocationService()
        .getLocationdataFromGoogleID(placeId, widget.sessionToken);
    var databaseLocationData = await LocationService()
        .getDatabaseLocationdataFromGoogleResult(locationData);

    return databaseLocationData;
  }

  @override
  Widget build(BuildContext context) {
    double dropdownItemSumHeight = widget.autoCompleteItems.length * 38.0;
    if (widget.autoCompleteItems.length * 38 > 160) dropdownItemSumHeight = 152;

    dropDownItem(item) {
      return GestureDetector(
        onTapDown: (details) async {
          if(item["place_id"] == null){
            widget.googleSearchResult = {
              "city": ownProfil["ort"], "countryname": ownProfil["land"], "longt": ownProfil["longt"], "latt": ownProfil["latt"]};
            item["description"] = "${ownProfil["ort"]}, ${ownProfil["land"]}";
          }else{
            widget.googleSearchResult =
              await getGoogleSearchLocationData(item["place_id"]);
          }

          widget.searchKontroller.text = item["description"];
          resetSearchBar();
          if(widget.onConfirm != null) widget.onConfirm!();
        },
        child: Container(
            padding: const EdgeInsets.all(10),
            height: 40,
            decoration: BoxDecoration(
                border: Border(
                    bottom: BorderSide(color: global_var.borderColorGrey))),
            child: Text(item["description"])),
      );
    }

    autoCompleteDropdownBox(dropBoxItems) {
      List<Widget> autoCompleteList = [];

      for (var item in dropBoxItems) {
        autoCompleteList.add(dropDownItem(item));
      }

      return Container(
        height: dropdownItemSumHeight,
        margin: const EdgeInsets.only(top: 0),
        child: ListView(
          padding: const EdgeInsets.only(top: 5),
          children: autoCompleteList,
        ),
      );
    }

    openOwnLocationSelection(focusOn){
      if(!focusOn || !widget.withOwnLocation) return;

      showAutoComplete("hallo");
      widget.searchableItems.add({"description": AppLocalizations.of(context)!.aktuellenOrtVerwenden});
      addAutoCompleteItems({"description": ""});
    }

    return Container(
      width: widget.width ?? 600,
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.all(Radius.circular(5)),
          border: Border.all()),
      height: dropdownExtraBoxHeight + dropdownItemSumHeight,
      margin: widget.margin,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 10),
                child: FocusScope(
                  child: Focus(
                    onFocusChange: (focusOn){
                      openOwnLocationSelection(focusOn);
                    },
                    child: TextField(
                        textAlignVertical: TextAlignVertical.top,
                        controller: widget.searchKontroller,
                        decoration: InputDecoration(
                            isDense: widget.isDense,
                            border: InputBorder.none,
                            hintText: widget.hintText,
                            hintStyle:
                                const TextStyle(fontSize: 15, color: Colors.grey)),
                        style: const TextStyle(),
                        onChanged: (value) async {
                          if(value.isEmpty && widget.withOwnLocation){
                            widget.searchableItems = [];
                            openOwnLocationSelection(true);
                          }else{
                            await widget._googleAutoCompleteSuche(value);

                            showAutoComplete(value);
                            addAutoCompleteItems(value);
                          }

                          setState(() {});
                        }),
                  ),
                ),
              ),
              if (widget.isSearching) autoCompleteDropdownBox(widget.autoCompleteItems)
            ],
          ),
          const Positioned(
              right: 15,
              top: 12,
              child: Icon(
                Icons.search,
                size: 25,
                color: Colors.black,
              )),
        ],
      ),
    );
  }
}
