import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../global/variablen.dart' as global_var;
import '../../global/custom_widgets.dart';
import '../../global/search_autocomplete.dart';
import 'eventCard.dart';
import '../../services/database.dart';
import 'event_details.dart';


class EventsSuchenPage extends StatefulWidget {
  const EventsSuchenPage({Key key}) : super(key: key);

  @override
  _EventsSuchenPageState createState() => _EventsSuchenPageState();
}

class _EventsSuchenPageState extends State<EventsSuchenPage> {
  var userId = FirebaseAuth.instance.currentUser.uid;
  var searchAutocomplete = SearchAutocomplete();
  var eventsBackup = [];
  var allEvents = [];
  var allEventCities;
  var allEventCountries;
  var allEventSprachen;



  @override
  void initState() {
    WidgetsBinding.instance?.addPostFrameCallback((_) => initialize() );

    super.initState();
  }

  initialize() async {
    eventsBackup = await EventDatabase().getEvents("art != 'privat' AND erstelltVon != '"+userId+"'");
    allEvents = eventsBackup;

    allEventCities = Set();
    allEventCountries = Set();
    allEventSprachen = global_var.sprachenListe + global_var.sprachenListeEnglisch;

    for(var event in eventsBackup){
      allEventCities.add(event["stadt"]);
      allEventCountries.add(event["land"]);
    }

    searchAutocomplete = SearchAutocomplete(
      hintText: "Filter",
      withFilter: true,
      searchableItems: allEventCities.toList() + allEventSprachen + allEventCountries.toList(),
      onConfirm: () => filterShowEvents(),
      onDelete: () => filterShowEvents(),
    );

    setState(() {

    });
  }

  filterShowEvents(){
    var filterProfils = [];
    var filterList = searchAutocomplete.getSelected();

    for(var event in eventsBackup){
      if(checkIfInFilter(event, filterList)) filterProfils.add(event);
    }

    setState(() {
      allEvents = filterProfils;
    });

  }

  checkIfInFilter(event, filterList){
    var eventLand = event["land"];
    var eventStadt = event["stadt"];
    var eventSprache = event["sprache"];

    if(filterList.isEmpty) return true;

    var spracheMatch = checkMatch(filterList, eventSprache,
        global_var.sprachenListe + global_var.sprachenListeEnglisch);
    var stadtMatch = checkMatch(filterList, [eventStadt], allEventCities , userSearch: true);
    var countryMatch = checkMatch(filterList, [eventLand], allEventCountries);

    if(spracheMatch && stadtMatch && countryMatch) return true;


    return false;
  }

  checkMatch(List selected, List checkList, globalList, {userSearch = false}){
    bool globalMatch = false;
    bool match = false;

    for (var select in selected) {
      if(globalList.contains(select)) globalMatch = true;

      if(checkList.contains(select)) match = true;

      if(userSearch) continue;

      if(globalMatch && !match){
        int halfListNumber = (globalList.length /2).toInt();
        var positionGlobal = globalList.indexOf(select);
        var calculatePosition = positionGlobal < halfListNumber ?
        positionGlobal + halfListNumber : positionGlobal - halfListNumber;
        var otherLanguage = globalList[calculatePosition];

        if(checkList.contains(otherLanguage)) match = true;
      }
    }


    if(!globalMatch) return true;
    if(match) return true;

    return false;
  }


  @override
  Widget build(BuildContext context) {

    showEvents(){
      List<Widget> meineEvents = [];

      for(var event in allEvents){
        meineEvents.add(
            EventCard(
              margin: EdgeInsets.only(top: 10 , bottom: 10, left: 15, right: 15),
              withInteresse: true,
              event: event,
              afterPageVisit: () async {
                eventsBackup = allEvents = await EventDatabase().getEvents("art != 'privat' AND erstelltVon != '"+userId+"'");

                setState(() {});
              }
            )
        );
      }

      return meineEvents;
    }

    return Scaffold(
      appBar: customAppBar(
        title: AppLocalizations.of(context).eventSuchen
      ),
      body: Container(
          padding: EdgeInsets.only(top:10),
          width: double.infinity,
          height: double.infinity,
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: EdgeInsets.only(top:70),
                child: Wrap(
                    children: showEvents()
                ),
              ),
              searchAutocomplete,
            ]
          )
      )
    );
  }
}
