import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hive/hive.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../widgets/custom_appbar.dart';
import 'location_card.dart';

class LocationPage extends StatefulWidget {
  final bool forCity;
  final bool forLand;

  const LocationPage({Key? key, this.forCity = false, this.forLand = false}) : super(key: key);

  @override
  State<LocationPage> createState() => _LocationPageState();
}

class _LocationPageState extends State<LocationPage> {
  final String userId = FirebaseAuth.instance.currentUser!.uid;
  var onSearch = false;
  TextEditingController citySearchKontroller = TextEditingController();
  FocusNode searchFocusNode = FocusNode();
  final _scrollController = ScrollController();
  int displayDataEntries = 20;

  @override
  void initState() {
    _scrollBar();
    super.initState();
  }

  _scrollBar(){
    _scrollController.addListener(() {
      bool isBottom = _scrollController.position.atEdge;

      if(isBottom){
        setState(() {
          displayDataEntries += 20;
        });
      }
    });
  }

  getAllInterestLocations() {
    var allCities = Hive.box('secureBox').get("stadtinfo");
    var interestCities = [];

    for (var city in allCities) {
      var hasInterest = city["interesse"].contains(userId);
      var isCity = city["isCity"] == 1;

      if (hasInterest && (widget.forLand ? !isCity : isCity)) interestCities.add(city);
    }

    return interestCities;
  }

  getAllSearchedLocations(){
    var allCities = Hive.box('secureBox').get("stadtinfo");
    var searchText = citySearchKontroller.text.toLowerCase();
    var searchedCities = [];

    for (var city in allCities) {
      var containsSearch = city["ort"].toLowerCase().contains(searchText)
          || city["ort"].contains(searchText)
          || searchText.isEmpty;
      var isCity = city["isCity"] == 1;

      if (containsSearch && (widget.forLand ? !isCity : isCity)) searchedCities.add(city);
    }

    return searchedCities;

  }

  showAllLocations() {
    List interesetCities = onSearch ? getAllSearchedLocations() : getAllInterestLocations();
    List<Widget> interestCitiyCards = [];
    var emptyText = widget.forCity
        ? AppLocalizations.of(context)!.nochKeineStaedteVorhanden
        : AppLocalizations.of(context)!.nochKeineCountriesVorhanden;
    var emptySearchText = AppLocalizations.of(context)!.sucheKeineErgebnisse;

    if (interesetCities.isEmpty) {
      interestCitiyCards.add(SizedBox(
        height: 300,
        child: Center(
            child: Text(onSearch ? emptySearchText : emptyText,
              style: const TextStyle(fontSize: 20),
        )),
      ));
    }

    for (var city in interesetCities.take(displayDataEntries).toList()) {
      interestCitiyCards.add(LocationCard(location: city, fromCityPage: true,));
    }

    return interestCitiyCards;
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    String onSearchText = onSearch ? AppLocalizations.of(context)!.suche : "";

    return Scaffold(
      appBar: CustomAppBar(
        title: widget.forCity
            ? "$onSearchText ${AppLocalizations.of(context)!.cities}"
            : "$onSearchText ${AppLocalizations.of(context)!.countries}"
      ),
      body: SafeArea(
        child: Stack(
          children: [
            SizedBox(
              height: double.infinity,
              child: SingleChildScrollView(
                controller: _scrollController,
                  child: SizedBox(
                    width: double.infinity,
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      children: showAllLocations(),
                    ),
              )),
            ),
            if(onSearch) Positioned(
                bottom: 15,
                right: 15,
                child: Container(
                  width: width*0.9,
                  height: 50,
                  decoration: BoxDecoration(
                    border: Border.all(),
                    color: Colors.white,
                    borderRadius: const BorderRadius.all(Radius.circular(20))
                  ),
                  child: TextField(
                    controller: citySearchKontroller,
                    focusNode: searchFocusNode,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.suche,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(10)
                    ),
                    onChanged: (_) => setState((){}),
                  ),
                )
            )
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
            mini: onSearch ? true: false,
            backgroundColor: onSearch ? Colors.red : null,
            onPressed: () {
              if(onSearch){
                searchFocusNode.unfocus();
                citySearchKontroller.clear();
              }

              setState(() {
                onSearch = !onSearch;
              });
            },
            child: Icon(onSearch ? Icons.close : Icons.search),
          )
    );
  }
}
