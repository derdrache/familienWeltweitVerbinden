import 'dart:ui';

import 'package:familien_suche/services/locationsService.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'variablen.dart' as global_var;


class GoogleAutoComplete extends StatefulWidget {
  List searchableItems = [];
  List autoCompleteItems = [];
  var isDense = false;
  var searchKontroller = TextEditingController();
  bool isSearching = false;
  bool suche;
  String hintText;
  var googleSearchResult;
  var sessionToken = Uuid().v4();

  getGoogleLocationData(){
    return googleSearchResult ?? {
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
    var googleSuche = await LocationService().getGoogleAutocompleteItems(googleInput, sessionToken);
    if(googleSuche.isEmpty) return ;

    final Map<String, dynamic> data = Map.from(googleSuche);
    searchableItems = data["predictions"];

  }


  GoogleAutoComplete({Key key,
    this.searchableItems,
    this.hintText,
    this.suche = true,
  });

  @override
  _GoogleAutoCompleteState createState() => _GoogleAutoCompleteState();
}

class _GoogleAutoCompleteState extends State<GoogleAutoComplete> {
  double dropdownExtraBoxHeight = 50;


  showAutoComplete(text){
    if(text.length == 0) {
      widget.isSearching = false;
    } else{
      widget.isSearching = true;
    }

    setState(() {});

  }

  addAutoCompleteItems(text){
    widget.autoCompleteItems = [];
    if(text.isEmpty) return widget.autoCompleteItems;

    for(var item in widget.searchableItems){
      if(item["description"] != widget.searchKontroller.text){
        widget.autoCompleteItems.add(item);
      }
    }
  }

  resetSearchBar(){
    widget.isSearching = false;
    widget.autoCompleteItems = [];
    FocusScope.of(context).unfocus();

    setState(() {

    });
  }

  getGoogleSearchLocationData(placeId) async {
    var locationData = await LocationService().getLocationdataFromGoogleID(placeId, widget.sessionToken);

    var formattedAddressList = locationData["result"]["formatted_address"].split(", ");
    var formattedCity = formattedAddressList.first.split(" ");

    var city = LocationService().isNumeric(formattedCity.first) ?
    formattedCity.last : formattedCity.join(" ");
    var cityList = [];
    for(var item in city.split(" ")){
      if(!LocationService().isNumeric(item)) cityList.add(item);
    }
    city = cityList.join(" ");


    var country = formattedAddressList.last;
    if(country.contains(" - ")){
      city = city.split(" - ")[0];
      country = country.split(" - ")[1];
    }
    if(LocationService().isNumeric(country)) country = formattedAddressList[formattedAddressList.length -2];

    var locationDataMap = {
      "city":city,
      "countryname": country,
      "longt": locationData["result"]["geometry"]["location"]["lng"],
      "latt": locationData["result"]["geometry"]["location"]["lat"],
      "adress": locationData["result"]["formatted_address"]
    };

    return locationDataMap;

  }




  @override
  Widget build(BuildContext context) {
    double dropdownItemSumHeight = widget.autoCompleteItems.length * 38.0;
    if(widget.autoCompleteItems.length * 38 > 160) dropdownItemSumHeight = 152;

    dropDownItem(item){
      return GestureDetector(
        onTapUp: (details) async {
            widget.searchKontroller.text = item["description"];
            resetSearchBar();
            widget.googleSearchResult = await getGoogleSearchLocationData(item["place_id"]);
        },
        child: Container(
            padding: EdgeInsets.all(10),
            height: 40,
            decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: global_var.borderColorGrey))
            ),
            child: Text(item["description"])
        ),
      );
    }

    autoCompleteDropdownBox(){
      List<Widget> autoCompleteList = [];

      for(var item in widget.autoCompleteItems){
        autoCompleteList.add( dropDownItem(item));
      }

      return Container(
        height: dropdownItemSumHeight,
        margin: EdgeInsets.only(top: 0),
        child: ListView(
          padding: EdgeInsets.only(top: 5),
          children: autoCompleteList,
        ),
      );
    }

    return Container(
      width: 600,
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(5)),
          border: Border.all()
      ),
      height:  dropdownExtraBoxHeight + dropdownItemSumHeight,
      margin: EdgeInsets.all(10),
      //padding: EdgeInsets.only(left: 5),
      child:Stack(
        overflow: Overflow.visible,
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 10),
                child: TextField(
                    textAlignVertical: TextAlignVertical.top,
                    controller: widget.searchKontroller,
                    decoration: InputDecoration(
                        isDense: widget.isDense,
                        border: InputBorder.none,
                        hintText: widget.hintText,
                        hintStyle: TextStyle(fontSize: 13, color: Colors.grey)
                    ),
                    style: const TextStyle(),
                    onChanged: (value) async {
                      await widget._googleAutoCompleteSuche(value);

                      showAutoComplete(value);
                      addAutoCompleteItems(value);

                      setState(() {});
                    }
                ),
              ),
              if(widget.isSearching) autoCompleteDropdownBox()

            ],
          ),
          Positioned(
              right: 15,
              top: 12,
              child: Icon(Icons.search, size: 25, color: Colors.black,)
          ),
        ],
      ),
    );
  }
}
