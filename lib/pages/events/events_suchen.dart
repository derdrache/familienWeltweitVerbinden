import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../global/variablen.dart' as global_var;
import '../../widgets/custom_appbar.dart';
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
  var allEventCities = <dynamic>{};
  var allEventCountries = <dynamic>{};
  var allEventSprachen =
      global_var.sprachenListe + global_var.sprachenListeEnglisch;
  var keineEventsText = "";

  @override
  void initState() {
    WidgetsBinding.instance?.addPostFrameCallback((_) => initialize());

    super.initState();
  }

  initialize() async {
    eventsBackup = await EventDatabase().getData(
        "*",
        "WHERE art != 'privat' AND art != 'private' AND erstelltVon != '" +
            userId +
            "' ORDER BY wann ASC",
        returnList: true);

    if (eventsBackup == false) {
      eventsBackup = [];
      keineEventsText = "keine Events vorhanden";
    }
    allEvents = eventsBackup;

    for (var event in eventsBackup) {
      allEventCities.add(event["stadt"]);
      allEventCountries.add(event["land"]);
    }

    searchAutocomplete = SearchAutocomplete(
      hintText: AppLocalizations.of(context).filterEventSuche,
      searchableItems: allEventCities.toList() +
          allEventSprachen +
          allEventCountries.toList()+
          ["online", "offline"],
      onConfirm: () => filterShowEvents(),
      onRemove: () => filterShowEvents(),
    );

    setState(() {});
  }

  filterShowEvents() {
    var filterProfils = [];
    var filterList = searchAutocomplete.getSelected();

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
    var stadtMatch =
        checkMatch(filterList, [eventStadt], allEventCities, userSearch: true);
    var countryMatch = checkMatch(filterList, [eventLand], allEventCountries);
    var typMatch = checkMatch(filterList, [eventTyp], global_var.eventTyp + global_var.eventTypEnglisch);

    if (spracheMatch && stadtMatch && countryMatch && typMatch) return true;

    return false;
  }

  checkMatch(List selected, List checkList, globalList, {userSearch = false}) {
    bool globalMatch = false;
    bool match = false;

    for (var select in selected) {
      if (globalList.contains(select)) globalMatch = true;

      if (checkList.contains(select)) match = true;

      if (userSearch) continue;

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

    return Scaffold(
        appBar: CustomAppBar(title: AppLocalizations.of(context).alleEvents),
        body: Container(
            padding: const EdgeInsets.only(top: 10),
            width: double.infinity,
            height: double.infinity,
            child: Stack(children: [
              Container(
                margin: const EdgeInsets.only(top: 60),
                child: SingleChildScrollView(
                  child: Center(
                    child: allEvents.isEmpty
                        ? Container(
                            margin: const EdgeInsets.only(top: 50),
                            child: keineEventsText.isEmpty
                                ? const CircularProgressIndicator()
                                : Text(keineEventsText))
                        : Wrap(children: showEvents()),
                  ),
                ),
              ),
              searchAutocomplete,
            ])));
  }
}
