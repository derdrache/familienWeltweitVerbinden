import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'dart:ui';
import 'package:geolocator/geolocator.dart';

import '../auth/secrets.dart';

class LocationService {
  var countryGeodata = Hive.box('countryGeodataBox').get("list");
  var kontinentGeodata = Hive.box("kontinentGeodataBox").get("list");

  getDatabaseLocationdataFromGoogleResult(googleResult) {
    if (googleResult["result"] != null) {
      googleResult = googleResult["result"];
    } else if (googleResult["candidates"] != null) {
      googleResult = googleResult["candidates"][0];
    }

    var formattedAddressList = googleResult["formatted_address"].split(", ");
    var formattedCity = formattedAddressList.first.split(" ");

    var city = LocationService().isNumeric(formattedCity.first)
        ? formattedCity.sublist(1).join(" ")
        : formattedCity.join(" ");

    var cityList = [];
    for (var item in city.split(" ")) {
      if (!LocationService().isNumeric(item)) cityList.add(item);
    }
    city = cityList.join(" ");

    var country = formattedAddressList.last;
    if (country.contains(" - ")) {
      city = city.split(" - ")[0];
      country = country.split(" - ")[1];
    }
    if (LocationService().isNumeric(country)) {
      country = formattedAddressList[formattedAddressList.length - 2];
    }

    return {
      "city": city,
      "countryname": country,
      "longt": googleResult["geometry"]["location"]["lng"],
      "latt": googleResult["geometry"]["location"]["lat"],
      "adress": googleResult["formatted_address"]
    };
  }

  getGoogleAutocompleteItems(input, sessionToken) async {
    var deviceLanguage =
        kIsWeb ? window.locale.languageCode : Platform.localeName.split("_")[0];
    var sprache = deviceLanguage == "de" ? "de" : "en";
    input = input.replaceAll(" ", "_");
    input = Uri.encodeComponent(input);

    try {
      var url =
          "https://families-worldwide.com/services/googleAutocomplete2.php";

      var res = await http.post(Uri.parse(url),
          body: json.encode({
            "googleKey": google_key,
            "input": input,
            "sprache": sprache,
            "sessionToken": sessionToken
          }));
      dynamic responseBody = res.body;

      var data = jsonDecode(responseBody);

      return data;
    } catch (error) {
      return [];
    }
  }

  getLocationdataFromGoogleID(id, sessionToken) async {
    try {
      var url =
          "https://families-worldwide.com/services/googlePlaceDetails2.php";

      var res = await http.post(Uri.parse(url),
          body: json.encode({
            "googleKey": google_key,
            "id": id,
            "sessionToken": sessionToken
          }));
      dynamic responseBody = res.body;

      var data = jsonDecode(responseBody);

      return data;
    } catch (error) {
      return [];
    }
  }

  getCurrentUserLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) return false;

    if ((permission == LocationPermission.deniedForever)) return false;

    return await Geolocator.getCurrentPosition();
  }

  getNearstLocationData(position) async {
    try {
      var url =
          "https://families-worldwide.com/services/googleGetNearstCity.php";

      var res = await http.post(Uri.parse(url),
          body: json.encode({
            "google_maps_key": google_maps_key,
            "lat": position.latitude.toString(),
            "lng": position.longitude.toString(),
          }));
      dynamic responseBody = res.body;
      var data = jsonDecode(responseBody);

      return data["results"][0];
    } catch (error) {
      return ;
    }
  }

  transformNearstLocation(nearstLocationData) {
    var city = "";
    var region = "";
    var country = "";
    for (var item in nearstLocationData["address_components"]) {
      if (item["types"].contains("locality")) {
        city = item["long_name"];
      } else if (item["types"].contains("administrative_area_level_1")) {
        region = item["long_name"];
      } else if (item["types"].contains("country")) {
        country = item["long_name"];
      }
    }

    return {"city": city, "region": region, "country": country};
  }

  getLocationGeoData(location) async {
    location = location.replaceAll(" ", "_");
    location = Uri.encodeComponent(location);
    try {
      var url =
          "https://families-worldwide.com/services/googlegetGeodataFromLocationName.php";

      var res = await http.post(Uri.parse(url),
          body: json.encode({
            "googleKey": google_maps_key,
            "location": location,
          }));
      dynamic responseBody = res.body;

      var data = jsonDecode(responseBody);

      return data;
    } catch (error) {
      return [];
    }
  }

  bool isNumeric(String str) {
    if (str == null) {
      return false;
    }
    return double.tryParse(str) != null;
  }

  getCountryLocation(input) {
    for (var i = 0; i < countryGeodata.length; i++) {
      var nameGer = countryGeodata[i]["nameGer"];
      var nameEng = countryGeodata[i]["nameEng"];

      if (nameGer == input || nameEng == input) {
        return countryGeodata[i];
      }
    }
    return null;
  }

  getKontinentLocation(kontinent) {
    if (kontinent == null) return null;

    for (var i = 0; i < kontinentGeodata.length; i++) {
      var nameGer = kontinentGeodata[i]["kontinentGer"];
      var nameEng = kontinentGeodata[i]["kontinentEng"];

      if (nameGer == kontinent || nameEng == kontinent) {
        return kontinentGeodata[i];
      }
    }
    return null;
  }

  getAllCountries() {
    List<String> countriesListGer = [];
    List<String> countriesListEng = [];

    for (var country in countryGeodata) {
      countriesListGer.add(country["nameGer"]);
      countriesListEng.add(country["nameEng"]);
    }

    return {"ger": countriesListGer, "eng": countriesListEng};
  }
}
