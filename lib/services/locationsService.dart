import 'package:http/http.dart' as http;
import 'dart:convert' as convert;
import 'package:flutter/services.dart';
import 'dart:convert';

import '../auth/secrets.dart';


class LocationService {
/*
  getLocationMapDataGoogle(input) async{
    var sprache = "de";
    try{
      var response = await http.get(Uri.parse('https://maps.googleapis.com/maps/api/place/findplacefromtext/json?input=$input&inputtype=textquery&fields=formatted_address%2Cname%2Crating%2Copening_hours%2Cgeometry&language=$sprache&key=$google_key'));
      var json = convert.jsonDecode(response.body);

      var mapData = {
        "city": json["candidates"][0]["formatted_address"].split(", ").first,
        "countryname": json["candidates"][0]["formatted_address"].split(", ").last,
        "longt": json["candidates"][0]["geometry"]["location"]["lng"],
        "latt": json["candidates"][0]["geometry"]["location"]["lat"]
      };
      return mapData;
    }catch (error){
      return null;
    }
  }


 */
  getLocationMapDataGeocode(input) async{
    try{
      var response = await http.get(Uri.parse("https://geocode.xyz/cityname=$input?json=1&nostrict=0"));
      var json = convert.jsonDecode(response.body);

      var mapData = {
        "city": json["standard"]["city"],
        "countryname": json["standard"]["countryname"],
        "longt": json["longt"],
        "latt": json["latt"]
      };
      return mapData;
    }catch (error){
      print("API Problem - erneuter Versuch");
      return null;
    }
  }

  getCountryLocation(input) async{
    var jsonText = await rootBundle.loadString('assets/countryGeodata.json');
    var data = json.decode(jsonText)["data"];

    for (var i = 0; i < data.length; i++){
      var nameGer = data[i]["nameGer"];
      var nameEng = data[i]["nameEng"];

      if (nameGer == input || nameEng == input){
        return {
          "latt": data[i]["latt"],
          "longt": data[i]["longt"]
        };
      }
    }
    return null;
  }
/*
  test(input) async{
    var response = await http.get(Uri.parse("http://www.mapquestapi.com/geocoding/v1/$input"));
    var json = convert.jsonDecode(response.body);

    print(json);
  }

 */
}

