import 'package:familien_suche/global/global_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hive/hive.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../widgets/custom_appbar.dart';
import 'create_stadtinformation.dart';
import 'city_card.dart';

class CityPage extends StatefulWidget {
  const CityPage({Key key}) : super(key: key);

  @override
  State<CityPage> createState() => _CityPageState();
}

class _CityPageState extends State<CityPage> {
  final String userId = FirebaseAuth.instance.currentUser.uid;

  getAllInterestCities() {
    var allCities = Hive.box('secureBox').get("stadtinfo");
    var interestCities = [];

    for (var city in allCities) {
      var interesetCity =
          city["interesse"].contains(userId) && city["isCity"] == 1;

      if (interesetCity) interestCities.add(city);
    }

    return interestCities;
  }

  showAllInteresetCities() {
    List interesetCities = getAllInterestCities();
    List<Widget> interestCitiyCards = [];

    if (interesetCities.isEmpty) {
      interestCitiyCards.add(SizedBox(
        height: 600,
        child: Center(
            child: Text(
          AppLocalizations.of(context).nochKeineStaedteVorhanden,
          style: const TextStyle(fontSize: 20),
        )),
      ));
    }

    for (var city in interesetCities) {
      interestCitiyCards.add(CityCard(city: city,));
    }

    return interestCitiyCards;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: AppLocalizations.of(context).cities,
        buttons: [
          IconButton(
              onPressed: () => null,
              icon: const Icon(
                Icons.search,
                size: 30,
              ))
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
            child: SizedBox(
          width: double.infinity,
          child: Wrap(
            alignment: WrapAlignment.center,
            children: showAllInteresetCities(),
          ),
        )),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () =>
            changePage(context, const CreateStadtinformationsPage()),
        child: const Icon(Icons.create),
      ),
    );
  }
}
