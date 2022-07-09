import 'package:familien_suche/global/global_functions.dart';
import 'package:familien_suche/services/database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../services/locationsService.dart';
import '../../widgets/dialogWindow.dart';
import '../../widgets/search_autocomplete.dart';
import 'community_card.dart';
import 'community_erstellen.dart';

class CommunityPage extends StatefulWidget {
  const CommunityPage({Key key}) : super(key: key);

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  var suchleiste = SearchAutocomplete();
  var allCommunities = Hive.box("secureBox").get("communities");
  var isLoading = true;
  bool filterOn = false;
  var filterList = [];
  var allCommunitiesCities = [];
  var allCommunitiesCountries = [];

  @override
  void initState() {
    WidgetsBinding.instance?.addPostFrameCallback((_) => initialize());

    super.initState();
  }

  initialize() async {
    var dbCommunities = await CommunityDatabase()
        .getData("*", "", returnList: true); //sortieren?

    if (dbCommunities == false) dbCommunities = [];
    Hive.box("secureBox").put("communities", dbCommunities);

    allCommunities = dbCommunities;

    for (var community in allCommunities) {
      allCommunitiesCities.add(community["ort"]);

      var countryData = LocationService().getCountryLocation(community["land"]);
      allCommunitiesCountries.add(
          spracheIstDeutsch ? countryData["nameGer"] : countryData["nameEng"]);
    }

    isLoading = false;

    suchleiste = SearchAutocomplete(
        searchableItems: allCommunitiesCities + allCommunitiesCountries,
        onConfirm: () => showFilter(),
        onRemove: () {
          filterList = [];
          showFilter();
        });

    setState(() {});
  }

  showFilter() {
    var comunitiesList = Hive.box("secureBox").get("communities");
    var filterCommunities = [];

    if (suchleiste.getSelected().isNotEmpty) {
      filterList = suchleiste.getSelected();
    }

    for (var community in comunitiesList) {
      if (checkIfInFilter(community, filterList))
        filterCommunities.add(community);
    }

    setState(() {
      allCommunities = filterCommunities;
    });
  }

  checkIfInFilter(community, filterList) {
    var land = community["land"];
    var stadt = community["stadt"];

    if (filterList.isEmpty) return true;

    var stadtMatch = checkMatch(filterList, [stadt], allCommunitiesCities,
        simpleSearch: true);
    var countryMatch = checkMatch(filterList, [land], allCommunitiesCountries,
        simpleSearch: true);

    if (stadtMatch && countryMatch) return true;

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

  showFavoritesWindow() {
    var userId = FirebaseAuth.instance.currentUser.uid;
    List<Widget> allfavorites = [];

    for (var community in allCommunities) {
      if (community["interesse"].contains(userId)) {
        allfavorites.add(CommunityCard(
          community: community,
          margin: const EdgeInsets.only(top: 10, bottom: 10, left: 70, right: 70),
        ));
      }
    }

    showDialog(
        context: context,
        builder: (BuildContext buildContext) {
          return CustomAlertDialog(
            title: "favorites",
            children: allfavorites,
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    suchleiste.hintText = AppLocalizations.of(context).filterEventSuche;

    showCommunities() {
      List<Widget> communities = [];

      for (var community in allCommunities) {
        communities.add(CommunityCard(
          community: community,
          withFavorite: true,
        ));
      }

      return SingleChildScrollView(
        child: Wrap(children: communities),
      );
    }

    bottomBar() {
      return Container(
        margin: const EdgeInsets.all(10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FloatingActionButton(
                heroTag: "show favorites",
                child: const Icon(Icons.star),
                onPressed: () => showFavoritesWindow()),
            const SizedBox(width: 10),
            FloatingActionButton(
                heroTag: "create Community",
                child: const Icon(Icons.create),
                onPressed: () =>
                    changePage(context, const CommunityErstellen())),
          ],
        ),
      );
    }

    return Scaffold(
      body: Padding(
          padding: const EdgeInsets.only(top: kIsWeb ? 0 : 24),
          child: Column(
            children: [
              suchleiste,
              Expanded(child: showCommunities()),
              bottomBar()
            ],
          )),
    );
  }
}
