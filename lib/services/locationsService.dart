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

  transformNearstLocation(nearstLocationData){
    var city = "";
    var region = "";
    var country = "";


    for(var item in nearstLocationData["address_components"]){
      if(item["types"].contains("locality")){
        city = item["long_name"];
      }else if(item["types"].contains("administrative_area_level_1")){
        region = item["long_name"];
      } else if(item["types"].contains("country")){
        country = item["long_name"];
      }
    }

    return{
      "city":city,
      "region": region,
      "country": country
    };

    //address_components:
    //[
    // {long_name: 2, short_name: 2, types: [street_number]},
    // {long_name: Javier Rojo Gomez, short_name: Javier Rojo Gomez, types: [route]},
    // {long_name: Centro, short_name: Centro, types: [neighborhood, political]},
    // {long_name: Puerto Morelos, short_name: Puerto Morelos, types: [locality, political]},
    // {long_name: Quintana Roo, short_name: Q.R., types: [administrative_area_level_1, political]},
    // {long_name: Mexico, short_name: MX, types: [country, political]},
    // {long_name: 77580, short_name: 77580, types: [postal_code]}
    // ]

    //formatted_address: Javier Rojo Gomez 2, Centro, 77580 Puerto Morelos, Q.R., Mexico

    //optionen entscheiden was davon angezeigt wird
  }

  getLocationGeoData(location) async {
    //location variable muss noch formatiert werden => irgendwo schonmal gemacht
    location = location.replaceAll(" ", "_");
    location = Uri.encodeComponent(location);
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




