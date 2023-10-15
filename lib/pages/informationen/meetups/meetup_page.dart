import 'dart:io' as io;
import 'dart:ui' as ui;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hive/hive.dart';


import '../../../global/global_functions.dart' as global_func;
import '../../../services/locationsService.dart';
import '../../../widgets/custom_appbar.dart';
import '../../../widgets/layout/badge_widget.dart';
import '../../start_page.dart';
import 'meetup_card.dart';
import 'meetup_erstellen.dart';

class MeetupPage extends StatefulWidget {
  final bool toInformationPage;

  const MeetupPage({Key? key, this.toInformationPage = false}) : super(key: key);

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

      var countryData =
          LocationService().getCountryLocationData(meetup["land"]);
      allMeetupCountries.add(
          spracheIstDeutsch ? countryData["nameGer"] : countryData["nameEng"]);
    }

    isLoading = false;

    setState(() {});
  }

  getAllSearchMeetups() {
    var searchedMeetups = [];
    var searchText = meetupSearchKontroller.text.toLowerCase();

    if (searchText.isEmpty) return allMeetups;

    for (var meetup in allMeetups) {
      bool isNotPrivat = !meetup["art"].contains("private") &&
          !meetup["art"].contains("privat");
      bool nameKondition = meetup["name"].toLowerCase().contains(searchText);
      bool countryKondition =
          meetup["land"].toLowerCase().contains(searchText) ||
              LocationService()
                  .transformCountryLanguage(meetup["land"])
                  .toLowerCase()
                  .contains(searchText);
      bool cityKondition = meetup["stadt"].toLowerCase().contains(searchText);

      if ((nameKondition || countryKondition || cityKondition) && isNotPrivat) {
        searchedMeetups.add(meetup);
      }
    }

    return searchedMeetups;
  }

  @override
  Widget build(BuildContext context) {
    allMeetups = Hive.box('secureBox').get("events") ?? [];
    double width = MediaQuery.of(context).size.width;

    showMeetups() {
      List myMeetups = Hive.box('secureBox').get("interestEvents") +
          Hive.box('secureBox').get("myEvents");
      List allEntries = onSearch
          ? getAllSearchMeetups()
          : myMeetups;

      List<Widget> meetupCards = [];
      var emptyText =
          AppLocalizations.of(context)!.keineMeetupsErstellt;
      var emptySearchText = AppLocalizations.of(context)!.sucheKeineErgebnisse;

      if (allEntries.isEmpty) {
        meetupCards.add(SizedBox(
          height: 300,
          child: Center(
              child: Text(
            onSearch ? emptySearchText : emptyText,
            style: const TextStyle(fontSize: 20),
          )),
        ));
      }

      for (var meetup in allEntries) {
        bool isOwner = meetup["erstelltVon"] == userId;
        bool isNotPublic =
            meetup["art"] != "public" && meetup["art"] != "öffentlich";
        int freischaltenCount =
            isOwner && isNotPublic ? meetup["freischalten"].length : 0;

        meetupCards.add(BadgeWidget(
          number: freischaltenCount,
          child: MeetupCard(
              meetupData: meetup,
              withInteresse: true,
              fromMeetupPage: true,
              afterFavorite: () => setState(() {}),
              afterPageVisit: () => setState(() {})),
        ));
      }

      return SingleChildScrollView(
        child: Wrap(alignment: WrapAlignment.spaceEvenly, children: [
          ...meetupCards,
          if (onSearch) const SizedBox(height: 330)
        ]),
      );
    }

    return Scaffold(
      appBar: CustomAppBar(
          title: onSearch
              ? "${AppLocalizations.of(context)!.suche} Meetups"
              : "Meetups",
          leading: onSearch || widget.toInformationPage
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    if(widget.toInformationPage){
                      global_func.changePageForever(
                          context, StartPage(selectedIndex: 2));
                    }else{
                      setState(() {
                        onSearch = false;
                      });
                    }
                  },
                  tooltip:
                      MaterialLocalizations.of(context).openAppDrawerTooltip,
                )
              : null),
      body: SafeArea(
        child: Stack(
          children: [
            Container(
                margin: const EdgeInsets.only(top: 10),
                height: double.infinity,
                width: double.infinity,
                child: showMeetups()),
            if (onSearch)
              Positioned(
                  bottom: 15,
                  right: 15,
                  child: Container(
                    width: width * 0.9,
                    height: 50,
                    decoration: BoxDecoration(
                        border: Border.all(),
                        color: Colors.white,
                        borderRadius:
                            const BorderRadius.all(Radius.circular(20))),
                    child: TextField(
                      controller: meetupSearchKontroller,
                      focusNode: searchFocusNode,
                      decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.suche,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(10)),
                      onChanged: (_) => setState(() {}),
                    ),
                  ))
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
              heroTag: "create meetup",
              tooltip: AppLocalizations.of(context)!.tooltipMeetupErstellen,
              child: const Icon(Icons.create),
              onPressed: () => global_func.changePage(context, const MeetupErstellen())),
          const SizedBox(height: 10),
          FloatingActionButton(
            mini: onSearch ? true : false,
            backgroundColor: onSearch ? Colors.red : null,
            onPressed: () {
              if (onSearch) {
                searchFocusNode.unfocus();
                meetupSearchKontroller.clear();
              }

              setState(() {
                onSearch = !onSearch;
              });
            },
            tooltip: AppLocalizations.of(context)!.tooltipMeetupSuche,
            child: Icon(onSearch ? Icons.close : Icons.search),
          ),
        ],
      ),
    );
  }
}
