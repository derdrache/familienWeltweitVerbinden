import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hive/hive.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../widgets/custom_appbar.dart';
import '../../../global/global_functions.dart' as global_functions;
import '../../start_page.dart';
import 'location_card.dart';

class LocationPage extends StatefulWidget {
  bool forCity;
  bool forLand;

  LocationPage({Key key, this.forCity = false, this.forLand = false}) : super(key: key);

  @override
  State<LocationPage> createState() => _LocationPageState();
}

class _LocationPageState extends State<LocationPage> {
  final String userId = FirebaseAuth.instance.currentUser.uid;
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
    var searchText = citySearchKontroller.text;
    var searchedCities = [];

    var searchTextFirstLetterBig = searchText.isEmpty ? "" :searchText.replaceFirst(searchText[0], searchText[0].toUpperCase());

    for (var city in allCities) {
      var containsSearch = city["ort"].contains(searchTextFirstLetterBig)
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
        ? AppLocalizations.of(context).nochKeineStaedteVorhanden
        : AppLocalizations.of(context).nochKeineCountriesVorhanden;
    var emptySearchText = AppLocalizations.of(context).sucheKeineErgebnisse;

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

    return Scaffold(
      appBar: CustomAppBar(
        title: widget.forCity
            ? AppLocalizations.of(context).cities
            : AppLocalizations.of(context).countries,
        leading: IconButton(
          onPressed: () => global_functions.changePageForever(context, StartPage(selectedIndex: 2,)),
          icon: Icon(Icons.arrow_back),
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Container(
              height: double.infinity,
              child: SingleChildScrollView(
                controller: _scrollController,
                  child: Container(
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
                    borderRadius: BorderRadius.all(Radius.circular(20))
                  ),
                  child: TextField(
                    controller: citySearchKontroller,
                    focusNode: searchFocusNode,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context).suche,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(10)
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
              } else{
                searchFocusNode.requestFocus();
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
