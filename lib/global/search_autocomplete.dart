import 'dart:convert';

import 'package:familien_suche/services/locationsService.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'variablen.dart' as global_var;


class SearchAutocomplete extends StatefulWidget {
  List searchableItems = [];
  var filterList = [];
  var onConfirm;
  var onDelete;
  List autoCompleteItems = [];
  var isDense = false;
  var searchKontroller = TextEditingController();
  bool isSearching = false;
  bool withFilter;
  bool suche;
  String hintText;
  var googleAutocomplete;
  var googleSearchResult;
  var sessionToken = Uuid().v4();

  getSelected(){
    return filterList;
  }

  getGoogleLocationData(){
    return googleSearchResult;
  }

  _googleAutoCompleteSuche(input) async {
    var googleSuche = await LocationService().getGoogleAutocompleteItems(input, sessionToken);
    if(googleSuche.isEmpty) return;

    final Map<String, dynamic> data = Map.from(googleSuche);

    searchableItems = data["predictions"];

  }



  SearchAutocomplete({Key key,
    this.searchableItems,
    this.onConfirm,
    this.onDelete,
    this.withFilter = true,
    this.hintText = "search",
    this.suche = true,
    this.googleAutocomplete = false,
  }) : isDense = !withFilter;

  @override
  _SearchAutocompleteState createState() => _SearchAutocompleteState();
}

class _SearchAutocompleteState extends State<SearchAutocomplete> {
  double dropdownExtraBoxHeight = 55;


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
      if(widget.googleAutocomplete && item["description"] != widget.searchKontroller.text){
        widget.autoCompleteItems.add(item);
      } else if(item.toLowerCase().contains(text.toLowerCase())) widget.autoCompleteItems.add(item);
    }

    setState(() {});
  }

  deleteFilterItem(item){
    widget.filterList.remove(item);

    if(widget.filterList.isEmpty) widget.isDense = false;

    setState(() {});
  }

  addFilterItem(item){
    if(widget.filterList.length == 3) return ;

    if (!widget.filterList.contains(item)){
      widget.filterList.add(item);
      if(widget.withFilter) widget.isDense = true;
    }
  }

  resetSearchBar(){
    if(!widget.googleAutocomplete) widget.searchKontroller.text = "";
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
    /*
    {html_attributions: [],
    result: {formatted_address: Wiesbaden, Germany,
      geometry: {location: {lat: 50.0782184, lng: 8.239760799999999},
      viewport: {northeast: {lat: 50.15180528728477, lng: 8.386191987556698},
      southwest: {lat: 49.99315976979197, lng: 8.110514779998914}}}},
      status: OK}

 */

    return locationDataMap;



  }

  @override
  Widget build(BuildContext context) {
    double dropdownItemSumHeight = widget.autoCompleteItems.length *38.0;
    if(widget.autoCompleteItems.length * 38 > 160) dropdownItemSumHeight = widget.withFilter? 160 : 152;

    dropDownItem(item){
      return GestureDetector(
        onTap: widget.onConfirm,
        onTapUp: (details) async {
          if(widget.googleAutocomplete){
            widget.searchKontroller.text = item["description"];
            resetSearchBar();
            widget.googleSearchResult = await getGoogleSearchLocationData(item["place_id"]);
          } else{
            addFilterItem(item);
            resetSearchBar();
          }

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
          margin: EdgeInsets.only(top: (widget.isDense && widget.withFilter)? 25: 0),
          child: ListView(
            padding: EdgeInsets.only(top: widget.withFilter? 0: 5),
            children: autoCompleteList,
          ),
      );
    }

    createFilterBox(){
      List<Widget> boxList = [];

      for(var item in widget.filterList){
        boxList.add(GestureDetector(
          onTap: widget.onDelete,
          onTapUp: (_) => deleteFilterItem(item),
          child: Container(
            padding: EdgeInsets.all(2),
            margin: EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondary,
              border: Border.all(),
              borderRadius: BorderRadius.circular(10)
            ),
            child: Text(
              item,
              style: TextStyle(fontSize: 12),
            )
          ),
        ));
      }

      return Row(
          children: boxList,
        );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(7)),
        border: Border.all()
      ),
      height:  dropdownExtraBoxHeight + dropdownItemSumHeight,
      margin: EdgeInsets.all(10),
      padding: EdgeInsets.only(left: 5),
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
                    contentPadding: EdgeInsets.only(top: widget.withFilter? widget.isDense? 9 : 5 : 15),
                    isDense: widget.isDense,
                    border: InputBorder.none,
                    hintText: widget.hintText,
                  ),
                  style: TextStyle(
                  ),
                  onChanged: (value) async {
                    if(widget.googleAutocomplete) await widget._googleAutoCompleteSuche(value);

                    showAutoComplete(value);
                    addAutoCompleteItems(value);
                  }
                  ,
            ),
              ),
              if(widget.isSearching) autoCompleteDropdownBox()

            ],
          ),
          if(widget.isDense && widget.withFilter) Positioned(
            top: 30,
            child: createFilterBox()
          ),
          Positioned(
            right: 15,
            top: 12,
            child: GestureDetector(
              onTap: null,
              child: Icon(Icons.search, size: 25,)
            )
          ),
        ],
      ),
    );
  }
}
