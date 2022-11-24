import 'package:familien_suche/services/locationsService.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'dart:io';
import 'dart:ui';

import '../../global/variablen.dart' as global_var;
import '../../widgets/custom_appbar.dart';
import '../../widgets/dialogWindow.dart';
import '../../widgets/search_autocomplete.dart';
import 'eventCard.dart';
import '../../services/database.dart';

class EventsSuchenPage extends StatefulWidget {
  const EventsSuchenPage({Key key}) : super(key: key);

  @override
  _EventsSuchenPageState createState() => _EventsSuchenPageState();
}

class _EventsSuchenPageState extends State<EventsSuchenPage> {
  var userId = FirebaseAuth.instance.currentUser.uid;
  var searchAutocomplete = SearchAutocomplete();
  dynamic eventsBackup = [];
  var allEvents = [];
  var allEventCities = [];
  var allEventCountries = [];
  bool filterOn = false;
  var filterList = [];
  var isLoading = true;

  @override
  void initState() {
    WidgetsBinding.instance?.addPostFrameCallback((_) => initialize());

    super.initState();
  }

  initialize() async {
    var spracheIstDeutsch = kIsWeb
        ? window.locale.languageCode == "de"
        : Platform.localeName == "de_DE";

    eventsBackup = await EventDatabase().getData(
        "*",
        "WHERE art != 'privat' AND art != 'private' AND erstelltVon != '$userId' ORDER BY wann ASC",
        returnList: true);

    if (eventsBackup == false) eventsBackup = [];

    allEvents = eventsBackup;

    isLoading = false;

    for (var event in eventsBackup) {
      if (event["stadt"] != "Online") allEventCities.add(event["stadt"]);
      if (event["land"] != "Online") {
        var countryData = LocationService().getCountryLocation(event["land"]);

        allEventCountries.add(spracheIstDeutsch
            ? countryData["nameGer"]
            : countryData["nameEng"]);
      }
    }

    searchAutocomplete = SearchAutocomplete(
        hintText: AppLocalizations.of(context).filterEventSuche,
        searchableItems: allEventCities.toList() + allEventCountries.toList(),
        onConfirm: () => filterShowEvents(),
        onRemove: () {
          filterList = [];
          filterShowEvents();
        });

    setState(() {});
  }

  filterShowEvents() {
    var filterProfils = [];

    if (filterList.isEmpty && searchAutocomplete.getSelected().isNotEmpty) {
      filterList = searchAutocomplete.getSelected();
    }

    for (var event in eventsBackup) {
      if (checkIfInFilter(event, filterList)) filterProfils.add(event);
    }

    setState(() {
      allEvents = filterProfils;
    });
  }

  checkIfInFilter(event, filterList) {
    var eventLand = event["land"];
    var eventStadt = event["stadt"];
    var eventSprache = event["sprache"];
    var eventTyp = event["typ"];

    if (filterList.isEmpty) return true;

    var spracheMatch = checkMatch(filterList, eventSprache,
        global_var.sprachenListe + global_var.sprachenListeEnglisch);
    var stadtMatch = checkMatch(filterList, [eventStadt], allEventCities,
        simpleSearch: true);
    var countryMatch = checkMatch(filterList, [eventLand], allEventCountries,
        simpleSearch: true);
    var typMatch = checkMatch(filterList, [eventTyp],
        global_var.eventTyp + global_var.eventTypEnglisch);

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
        spracheIstDeutsch ? global_var.eventTyp : global_var.eventTypEnglisch;

    await showDialog(
        context: context,
        builder: (BuildContext buildContext) {
          return StatefulBuilder(builder: (context, windowSetState) {
            return CustomAlertDialog(
              title: "",
              children: [
                createCheckBoxen(windowSetState, sprachenSelection,
                    AppLocalizations.of(context).sprachen),
                createCheckBoxen(windowSetState, typSelection, "Event typ"),
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

                    filterShowEvents();
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

    filterShowEvents();
  }

  @override
  Widget build(BuildContext context) {
    showEvents() {
      List<Widget> meineEvents = [];

      for (var event in allEvents) {
        meineEvents.add(EventCard(
            margin:
                const EdgeInsets.only(top: 10, bottom: 10, left: 17, right: 17),
            withInteresse: true,
            event: event,
            afterPageVisit: () async {
              eventsBackup = allEvents = await EventDatabase().getData(
                  "*",
                  "WHERE art != 'privat' AND art != 'private' AND erstelltVon != '" +
                      userId +
                      "' ORDER BY wann ASC",
                  returnList: true);

              setState(() {});
            }));
      }

      return meineEvents;
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
        appBar: CustomAppBar(title: AppLocalizations.of(context).alleEvents),
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
                      child: allEvents.isEmpty
                          ? Container(
                              margin: const EdgeInsets.only(top: 50),
                              child: isLoading
                                  ? const CircularProgressIndicator()
                                  : Text(
                                      AppLocalizations.of(context)
                                          .keineEventsVorhanden,
                                      style: const TextStyle(fontSize: 30),
                                    ))
                          : Wrap(children: showEvents()),
                    ),
                  ),
                ),
                searchAutocomplete,
                Positioned(
                  top: 10,
                  right: 10,
                  child: filterButton(),
                )
              ])),
        ));
  }
}
