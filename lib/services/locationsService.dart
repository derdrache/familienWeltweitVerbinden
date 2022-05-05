import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' as convert;
import 'dart:ui';

import '../auth/secrets.dart';


class LocationService {
  var countryGeodata = Hive.box('countryGeodataBox').get("list");
  var kontinentGeodata = Hive.box("kontinentGeodataBox").get("list");

  getGoogleAutocompleteItems(input, sessionToken) async {
    var deviceLanguage = kIsWeb? window.locale.languageCode :  Platform.localeName.split("_")[0];
    var sprache = deviceLanguage == "de" ? "de" : "en";
    input = input.replaceAll(" ", "_");
    input = Uri.encodeComponent(input);

    try{

      var url = "https://families-worldwide.com/services/googleAutocomplete2.php";

      var res = await http.post(Uri.parse(url), body: json.encode({
        "googleKey": google_key,
        "input": input,
        "sprache": sprache,
        "sessionToken": sessionToken
      }));
      dynamic responseBody = res.body;

      var data = convert.jsonDecode(responseBody);

      return data;


    } catch(error){
      return [];
    }

  }

  getLocationdataFromGoogleID(id, sessionToken) async {
    try{
      var url = "https://families-worldwide.com/services/googlePlaceDetails2.php";

      var res = await http.post(Uri.parse(url), body: json.encode({
        "googleKey": google_key,
        "id": id,
        "sessionToken": sessionToken
      }));
      dynamic responseBody = res.body;


      var data = convert.jsonDecode(responseBody);

      return data;

    } catch(error){
      print(error);
      return [];
    }
  }

  getUserGeodata(){

  }

  getNearstCity(){

  }


  bool isNumeric(String str) {
    if(str == null) {
      return false;
    }
    return double.tryParse(str) != null;
  }

  getCountryLocation(input){
    for (var i = 0; i < countryGeodata.length; i++){
      var nameGer = countryGeodata[i]["nameGer"];
      var nameEng = countryGeodata[i]["nameEng"];

      if (nameGer == input || nameEng == input){
        return countryGeodata[i];
      }
    }
    return null;
  }

  getKontinentLocation(kontinent){
    if(kontinent == null) return null;

    for (var i = 0; i < kontinentGeodata.length; i++){
      var nameGer = kontinentGeodata[i]["kontinentGer"];
      var nameEng = kontinentGeodata[i]["kontinentEng"];

      if (nameGer == kontinent || nameEng == kontinent){
        return kontinentGeodata[i];
      }
    }
    return null;

  }

  getAllCountries() {
    List<String> countriesListGer = [];
    List<String> countriesListEng = [];

    for(var country in countryGeodata){
      countriesListGer.add(country["nameGer"]);
      countriesListEng.add(country["nameEng"]);
    }

    return {
      "ger" : countriesListGer,
      "eng" : countriesListEng
    };
  }

}


