import 'package:familien_suche/widgets/custom_appbar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hive/hive.dart';
import 'dart:io' as io;
import 'dart:ui' as ui;

import '../../../global/global_functions.dart';
import '../../../global/global_functions.dart' as global_functions;
import '../../../services/locationsService.dart';
import '../../start_page.dart';
import 'meetupCard.dart';
import 'meetup_erstellen.dart';

class MeetupPage extends StatefulWidget {
  const MeetupPage({Key? key}) : super(key: key);

  @override
  State<MeetupPage> createState() => _MeetupPageState();
}

class _MeetupPageState extends State<MeetupPage> {
  var userId = FirebaseAuth.instance.currentUser!.uid;
  var allMeetups = Hive.box('secureBox').get("events") ?? [];
  var isLoading = true;
  bool filterOn = false;
  var filterList = [];
  var allMeetupCities = [];
  var allMeetupCountries = [];
  bool onSearch = false;
  TextEditingController meetupSearchKontroller = TextEditingController();
  FocusNode searchFocusNode = FocusNode();
  String pageTitle = "Meetups";
  var spracheIstDeutsch = kIsWeb
      ? ui.PlatformDispatcher.instance.locale.languageCode == "de"
      : io.Platform.localeName == "de_DE";

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) => initialize());

    super.initState();
  }

  initialize() async {
    for (var meetup in allMeetups) {
      allMeetupCities.add(meetup["ort"]);

      var countryData = LocationService().getCountryLocation(meetup["land"]);
      allMeetupCountries.add(
          spracheIstDeutsch ? countryData["nameGer"] : countryData["nameEng"]);
    }

    isLoading = false;

    setState(() {});
  }

  getAllSearchMeetups(){
    var searchedMeetups = [];
    var searchText = meetupSearchKontroller.text.toLowerCase();

    if(searchText.isEmpty) return allMeetups;

    for(var meetup in allMeetups){
      bool isNotPrivat = !meetup["art"].contains("private") && !meetup["art"].contains("privat");
      bool nameKondition = meetup["name"].toLowerCase().contains(searchText);
      bool countryKondition = meetup["land"].toLowerCase().contains(searchText) ||
          LocationService()
              .transformCountryLanguage(meetup["land"])
              .toLowerCase()
              .contains(searchText);
      bool cityKondition = meetup["ort"].toLowerCase().contains(searchText);

      if((nameKondition || countryKondition || cityKondition) && isNotPrivat) searchedMeetups.add(meetup);

    }

    return searchedMeetups;
  }

  @override
  Widget build(BuildContext context) {
    allMeetups = Hive.box('secureBox').get("events") ?? [];
    double width = MediaQuery.of(context).size.width;

    showMeetups() {
      List allEntries = onSearch
          ? getAllSearchMeetups()
          : Hive.box('secureBox').get("interestEvents") ?? [] + Hive.box('secureBox').get("myEvents") ?? [];
      List<Widget> meetupCards = [];
      var emptyText = AppLocalizations.of(context)!.nochKeinegemeinschaftVorhanden;
      var emptySearchText = AppLocalizations.of(context)!.sucheKeineErgebnisse;

      if (allEntries.isEmpty) {
        meetupCards.add(SizedBox(
          height: 300,
          child: Center(
              child: Text(onSearch ? emptySearchText : emptyText,
                style: const TextStyle(fontSize: 20),
              )),
        ));
      }

      for (var meetup in allEntries) {
        bool isOwner = meetup["erstelltVon"] == userId;
        var freischaltenCount = meetup["freischalten"].length;
        bool isNotPublic = meetup["art"] != "public" && meetup["art"] != "öffentlich";

        meetupCards.add(Stack(
          children: [
            MeetupCard(
                meetupData: meetup,
                margin: const EdgeInsets.only(top: 30, bottom: 0, right: 20, left: 20),
                withInteresse: true,
                fromMeetupPage: true,
                afterFavorite: () => setState((){}),
                afterPageVisit: () => setState((){})
            ),
            if (isOwner && isNotPublic && freischaltenCount > 0)
              Positioned(
                  right: 10,
                  top: 20,
                  child: Container(
                      height: 20,
                      width: 20,
                      decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.secondary,
                          shape: BoxShape.circle
                      ),
                      child: Center(
                        child: FittedBox(
                          child: Text(
                            freischaltenCount.toString(),
                            style: const TextStyle(fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                        ),
                      )
                  )
              )
          ],
        ),
      );

      }

      return SingleChildScrollView(
        child: SizedBox(
          width: double.infinity,
          child: Wrap(
              alignment: WrapAlignment.center,
              children: [
                ...meetupCards,
                if(onSearch) const SizedBox(height: 330)
              ]
          ),
        ),
      );
    }

    return Scaffold(
      appBar: CustomAppBar(
          title: pageTitle,
          leading: IconButton(
            onPressed: () => global_functions.changePageForever(context, StartPage(selectedIndex: 2,)),
            icon: const Icon(Icons.arrow_back),
          )
      ),
      body: SafeArea(
        child: Stack(
          children: [
            showMeetups(),
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
                    controller: meetupSearchKontroller,
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
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
              heroTag: "create meetup",
              child: const Icon(Icons.create),
              onPressed: () =>
                  changePage(context, const MeetupErstellen())),
          const SizedBox(height: 10),
          FloatingActionButton(
            mini: onSearch ? true: false,
            backgroundColor: onSearch ? Colors.red : null,
            onPressed: () {
              if(onSearch){
                pageTitle = "Meetups";
                searchFocusNode.unfocus();
                meetupSearchKontroller.clear();
              }else{
                pageTitle = "${AppLocalizations.of(context)!.suche} Meetups";
              }

              setState(() {
                onSearch = !onSearch;
              });
            },
            child: Icon(onSearch ? Icons.close : Icons.search),
          ),
        ],
      ),
    );
  }
}