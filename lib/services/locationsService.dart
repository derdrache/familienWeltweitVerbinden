import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' as convert;
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:ui';

import '../auth/secrets.dart';


class LocationService {
  var countryGeodata = Hive.box('countryGeodataBox').get("list");

  getGoogleAutocompleteItems(input, sessionToken) async {
    var deviceLanguage = kIsWeb? window.locale.languageCode :  Platform.localeName.split("_")[0];
    var sprache = deviceLanguage == "de" ? "de" : "en";
    input = input.replaceAll(" ", "_");
    input = Uri.encodeComponent(input);

    try{

      var url = "https://families-worldwide.com/services/googleAutocomplete.php";

      var zusatz = "?param1=$google_key&param2=$input&param3=$sprache&param4=$sessionToken";

      var response = await http.get(Uri.parse(url + zusatz), headers: {"Accept": "application/json"});

      var json = convert.jsonDecode(response.body);

      return json;

    } catch(error){
      return [];
    }

  }

  getLocationdataFromGoogleID(id, sessionToken) async {
    try{
      var url = "https://families-worldwide.com/services/googlePlaceDetails.php";
      var zusatz = "?param1=$google_key&param2=$id&param3=$sessionToken";

      var response = await http.get(Uri.parse(url + zusatz), headers: {"Accept": "application/json"});
      var json = convert.jsonDecode(response.body);

      return json;

    } catch(error){
      print(error);
      return [];
    }
  }


  bool isNumeric(String str) {
    if(str == null) {
      return false;
    }
    return double.tryParse(str) != null;
  }

  getCountryLocation(input) async{
    if(countryGeodata == null){
      var jsonText = await rootBundle.loadString('assets/countryGeodata.json');
      var geodata = json.decode(jsonText)["data"];
      Hive.box('countryGeodataBox').put("list", geodata);
      countryGeodata = geodata;
    }


    for (var i = 0; i < countryGeodata.length; i++){
      var nameGer = countryGeodata[i]["nameGer"];
      var nameEng = countryGeodata[i]["nameEng"];

      if (nameGer == input || nameEng == input){
        return {
          "latt": countryGeodata[i]["latt"],
          "longt": countryGeodata[i]["longt"]
        };
      }
    }
    return null;
  }

  getAllCountries() async {
    if(countryGeodata == null){
      var jsonText = await rootBundle.loadString('assets/countryGeodata.json');
      var geodata = json.decode(jsonText)["data"];
      Hive.box('countryGeodataBox').put("list", geodata);
      countryGeodata = geodata;
    }

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


