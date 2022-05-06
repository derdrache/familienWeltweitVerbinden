import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' as convert;
import 'dart:ui';
import 'package:geolocator/geolocator.dart';

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

  getCurrentUserLocation() async{
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();

    if (permission == LocationPermission.denied) return false;

    if((permission == LocationPermission.deniedForever)) return false;

    return await Geolocator.getCurrentPosition();
  }


  getNearstLocationData(position) async  {
    position = position.replaceAll(" ", "_");
    position = Uri.encodeComponent(position);

    try{

      var url = "https://families-worldwide.com/services/googleGetNearstCity.php";

      var res = await http.post(Uri.parse(url), body: json.encode({
        "google_maps_key": google_maps_key,
        "lat":position.latitude.toString(),
        "lng": position.longitude.toString(),
      }));
      dynamic responseBody = res.body;
      var data = convert.jsonDecode(responseBody);

      return data["results"][0];



    } catch(error){
      return {};
    }

  }

  getLocationGeoData(location) async {
    //location variable muss noch formatiert werden => irgendwo schonmal gemacht

    try{
      var url = "https://families-worldwide.com/services/googlegetGeodataFromLocationName.php";

      var res = await http.post(Uri.parse(url), body: json.encode({
        "googleKey": google_maps_key,
        "location": location,
      }));
      dynamic responseBody = res.body;


      var data = convert.jsonDecode(responseBody);

      return data;

    } catch(error){
      print(error);
      return [];
    }



    /*
    var output = {
      "candidates" : [
        {
          "formatted_address" : "Puerto Morelos, Q.R., México",
          "geometry" : {
            "location" : {
              "lat" : 20.8478084,
              "lng" : -86.87553419999999
            },
            "viewport" : {
              "northeast" : {
                "lat" : 20.8595556,
                "lng" : -86.8704874
              },
              "southwest" : {
                "lat" : 20.8239622,
                "lng" : -86.90026840000002
              }
            }
          }
        }
      ],
      "status" : "OK"
    };

     */

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


class NearstLocationHelper{

  getCity(){

  }

  getRegion(){

  }

  getCountry(){

  }

}



