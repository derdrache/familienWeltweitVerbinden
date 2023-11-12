import 'package:familien_suche/global/style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hive/hive.dart';

import '../../../../global/global_functions.dart' as global_func;
import '../../../../services/database.dart';
import 'information_main.dart';


class CountryCitiesPage extends StatefulWidget {
  final String countryName;

  const CountryCitiesPage({Key? key, required this.countryName})
      : super(key: key);

  @override
  State<CountryCitiesPage> createState() => _CountryCitiesPageState();
}

class _CountryCitiesPageState extends State<CountryCitiesPage> {
  getAllCitiesFromCountry() {
    List allCities = Hive.box('secureBox').get("stadtinfo");
    List citiesFromCountry = [];

    for (var city in allCities) {
      var isCity = city["isCity"] == 1;
      var fromCountry = widget.countryName.contains(city["land"]);

      if (isCity && fromCountry) {
        city["userInfos"] = getCityUserInfoFromHive(city["ort"]);

        citiesFromCountry.add(city);
      }
    }

    return sortCityList(citiesFromCountry);
  }

  sortCityList(cityList) {
    cityList.sort((a, b) {
      var calculationA = a["familien"].length + a["userInfos"].length;
      var calculationB = b["familien"].length + b["userInfos"].length;

      return calculationB.compareTo(calculationA) as int;
    });

    return cityList;
  }

  setInternetIconColor(indikator) {
    if (indikator <= 20) return Colors.red;
    if (indikator <= 40) return Colors.orange;
    if (indikator <= 60) return Colors.yellow;
    if (indikator <= 80) return Colors.green;

    return Colors.green[800];
  }

  setCostIconColor(indikator) {
    if (indikator <= 1) return Colors.green[800];
    if (indikator <= 2) return Colors.green;
    if (indikator <= 3) return Colors.yellow;
    if (indikator <= 4) return Colors.orange;

    return Colors.red;
  }

  getCityUserInfoCount(cityName) {
    List cityUserInfos = getCityUserInfoFromHive(cityName);

    return cityUserInfos.length;
  }

  @override
  Widget build(BuildContext context) {
    cityEntry(city) {
      return GestureDetector(
        onTap: () => global_func.changePage(
            context, LocationInformationPage(ortName: city["ort"], ortLatt: city["latt"],)),
        child: Container(
          margin: const EdgeInsets.all(10),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              border: Border.all(), borderRadius: BorderRadius.circular(15)),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(city["ort"],
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 5),
                    Text(AppLocalizations.of(context)!.stadtInformationen +
                        getCityUserInfoCount(city["ort"]).toString()),
                    const SizedBox(height: 5),
                    Text(AppLocalizations.of(context)!.besuchtVon +
                        city["familien"].length.toString() +
                        AppLocalizations.of(context)!.familien),
                  ],
                ),
              ),
              if (city["kosten"] != null)
                Icon(
                  Icons.monetization_on_outlined,
                  size: 25,
                  color: setCostIconColor(city["kosten"]),
                ),
              const SizedBox(width: 10),
              if (city["internet"] != null)
                Icon(Icons.network_check_outlined,
                    size: 25, color: setInternetIconColor(city["internet"])),
            ],
          ),
        ),
      );
    }

    createCityList() {
      List<Widget> cityList = [];
      var citiesFromCountry = getAllCitiesFromCountry();

      for (var city in citiesFromCountry) {
        cityList.add(cityEntry(city));
      }

      return cityList;
    }

    return SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: webWidth,
              child: ListView(
                shrinkWrap: true,
                children: createCityList(),
              ),
            ),
          ],
        ));
  }
}