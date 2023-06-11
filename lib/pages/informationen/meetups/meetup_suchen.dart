import 'package:familien_suche/services/locationsService.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'dart:io';
import 'dart:ui';

import '../../../global/variablen.dart' as global_var;
import '../../../widgets/custom_appbar.dart';
import '../../../widgets/dialogWindow.dart';
import '../../../widgets/search_autocomplete.dart';
import '../../../services/database.dart';
import 'meetupCard.dart';

class MeetupSuchenPage extends StatefulWidget {
  const MeetupSuchenPage({Key? key}) : super(key: key);

  @override
  _MeetupSuchenPageState createState() => _MeetupSuchenPageState();
}

class _MeetupSuchenPageState extends State<MeetupSuchenPage> {
  var userId = FirebaseAuth.instance.currentUser!.uid;
  var searchAutocomplete = SearchAutocomplete(searchableItems: [],);
  dynamic meetupsBackup = [];
  var allMeetups = [];
  List<String> allMeetupCities = [];
  List<String> allMeetupCountries = [];
  bool filterOn = false;
  var filterList = [];
  var isLoading = true;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) => initialize());

    super.initState();
  }

  initialize() async {
    var spracheIstDeutsch = kIsWeb
        ? window.locale.languageCode == "de"
        : Platform.localeName == "de_DE";

    meetupsBackup = await MeetupDatabase().getData(
        "*",
        "WHERE art != 'privat' AND art != 'private' AND erstelltVon != '$userId' ORDER BY wann ASC",
        returnList: true);

    if (meetupsBackup == false) meetupsBackup = [];

    allMeetups = meetupsBackup;

    isLoading = false;

    for (var meetup in meetupsBackup) {
      if (meetup["stadt"] != "Online") allMeetupCities.add(meetup["stadt"]);
      if (meetup["land"] != "Online") {
        var countryData = LocationService().getCountryLocation(meetup["land"]);

        allMeetupCountries.add(spracheIstDeutsch
            ? countryData["nameGer"]
            : countryData["nameEng"]);
      }
    }

    searchAutocomplete = SearchAutocomplete(
        hintText: AppLocalizations.of(context)!.filterMeetupSuche,
        searchableItems: allMeetupCities.toList()  + allMeetupCountries.toList(),
        onConfirm: () => filterShowMeetups(),
        onRemove: () {
          filterList = [];
          filterShowMeetups();
        });

    setState(() {});
  }

  filterShowMeetups() {
    var filterProfils = [];

    if (filterList.isEmpty && searchAutocomplete.getSelected().isNotEmpty) {
      filterList = searchAutocomplete.getSelected();
    }

    for (var meetup in meetupsBackup) {
      if (checkIfInFilter(meetup, filterList)) filterProfils.add(meetup);
    }

    setState(() {
      allMeetups = filterProfils;
    });
  }

  checkIfInFilter(meetup, filterList) {
    var meetupLand = meetup["land"];
    var meetupStadt = meetup["stadt"];
    var meetupSprache = meetup["sprache"];
    var meetupTyp = meetup["typ"];

    if (filterList.isEmpty) return true;

    var spracheMatch = checkMatch(filterList, meetupSprache,
        global_var.sprachenListe + global_var.sprachenListeEnglisch);
    var stadtMatch = checkMatch(filterList, [meetupStadt], allMeetupCities,
        simpleSearch: true);
    var countryMatch = checkMatch(filterList, [meetupLand], allMeetupCountries,
        simpleSearch: true);
    var typMatch = checkMatch(filterList, [meetupTyp],
        global_var.meetupTyp + global_var.meetupTypEnglisch);

    if (spracheMatch && stadtMatch && countryMatch && typMatch) return true;

    return false;
  }

  checkMatch(List selected, List checkList, globalList,
      {simpleSearch = false}) {
    bool globalMatch = false;
    bool match = false;

    for (var select in selected) {
      if (globalList.contains(select)) globalMatch = true;

      if (checkList.contains(select)) match = true;

      if (simpleSearch) continue;

      if (globalMatch && !match) {
        int halfListNumber = (globalList.length / 2).toInt();

        var positionGlobal = globalList.indexOf(select);
        var calculatePosition = positionGlobal < halfListNumber
            ? positionGlobal + halfListNumber
            : positionGlobal - halfListNumber;
        var otherLanguage = globalList[calculatePosition];

        if (checkList.contains(otherLanguage)) match = true;
      }
    }

    if (!globalMatch) return true;
    if (match) return true;

    return false;
  }

  openFilterWindow() async {
    var sprachenSelection = spracheIstDeutsch
        ? global_var.sprachenListe
        : global_var.sprachenListeEnglisch;
    var typSelection =
        spracheIstDeutsch ? global_var.meetupTyp : global_var.meetupTypEnglisch;

    await showDialog(
        context: context,
        builder: (BuildContext buildContext) {
          return StatefulBuilder(builder: (context, windowSetState) {
            return CustomAlertDialog(
              title: "",
              children: [
                createCheckBoxen(windowSetState, sprachenSelection,
                    AppLocalizations.of(context)!.sprachen),
                createCheckBoxen(windowSetState, typSelection, "Meetup typ"),
              ],
            );
          });
        });

    if (filterList.isNotEmpty) {
      filterOn = true;
    } else {
      filterOn = false;
    }

    setState(() {});
  }

  createCheckBoxen(windowSetState, selectionList, title) {
    List<Widget> checkBoxWidget = [];

    for (var selection in selectionList) {
      var widthFactor = 0.5;

      if (selection.length < 3) widthFactor = 0.2;

      checkBoxWidget.add(FractionallySizedBox(
        widthFactor: widthFactor,
        child: Row(
          children: [
            SizedBox(
              width: 25,
              height: 25,
              child: Checkbox(
                  value: filterList.contains(selection),
                  onChanged: (newValue) {
                    if (newValue == true) {
                      filterList.add(selection);
                    } else {
                      filterList.remove(selection);
                    }
                    windowSetState(() {});

                    filterShowMeetups();
                  }),
            ),
            Expanded(
                child: InkWell(
              onTap: () => changeCheckboxState(selection, windowSetState),
              child: Text(
                selection,
                style: const TextStyle(fontSize: 13),
                maxLines: 2,
              ),
            ))
          ],
        ),
      ));
    }

    return Column(
      children: [
        Text(title),
        const SizedBox(height: 5),
        Wrap(children: [...checkBoxWidget]),
        const SizedBox(height: 10)
      ],
    );
  }

  changeCheckboxState(selection, windowSetState) {
    if (filterList.contains(selection)) {
      filterList.remove(selection);
    } else {
      filterList.add(selection);
    }
    windowSetState(() {});

    filterShowMeetups();
  }

  @override
  Widget build(BuildContext context) {
    showMeetups() {
      List<Widget> meineMeetups = [];

      for (var meetup in allMeetups) {
        meineMeetups.add(MeetupCard(
            margin:
                const EdgeInsets.only(top: 10, bottom: 10, left: 17, right: 17),
            withInteresse: true,
            meetupData: meetup,
            afterPageVisit: () async {
              meetupsBackup = allMeetups = await MeetupDatabase().getData(
                  "*",
                  "WHERE art != 'privat' AND art != 'private' AND erstelltVon != '" +
                      userId +
                      "' ORDER BY wann ASC",
                  returnList: true);

              setState(() {});
            }));
      }

      return meineMeetups;
    }

    filterButton() {
      return IconButton(
          padding: EdgeInsets.zero,
          icon: Icon(filterOn ? Icons.filter_list_off : Icons.filter_list,
              size: 32, color: Theme.of(context).colorScheme.primary),
          onPressed: () {
            openFilterWindow();
          });
    }

    return Scaffold(
        appBar: CustomAppBar(title: AppLocalizations.of(context)!.alleMeetups),
        body: SafeArea(
          child: Container(
              padding: const EdgeInsets.only(top: 10),
              width: double.infinity,
              height: double.infinity,
              child: Stack(children: [
                Container(
                  margin: const EdgeInsets.only(top: 80),
                  child: SingleChildScrollView(
                    child: Center(
                      child: allMeetups.isEmpty
                          ? Container(
                              margin: const EdgeInsets.only(top: 50),
                              child: isLoading
                                  ? const CircularProgressIndicator()
                                  : Text(
                                      AppLocalizations.of(context)!
                                          .keineMeetupsVorhanden,
                                      style: const TextStyle(fontSize: 30),
                                    ))
                          : Wrap(children: showMeetups()),
                    ),
                  ),
                ),
                Container(margin: const EdgeInsets.only(right: 35) ,child: searchAutocomplete),
                Positioned(
                  top: 10,
                  right: 0,
                  child: filterButton(),
                )
              ])),
        ));
  }
}
