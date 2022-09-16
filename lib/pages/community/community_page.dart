import 'package:familien_suche/global/global_functions.dart';
import 'package:familien_suche/pages/start_page.dart';
import 'package:familien_suche/services/database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:async/async.dart';

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
  var allCommunities = Hive.box('secureBox').get("communities");
  var isLoading = true;
  bool filterOn = false;
  var filterList = [];
  var allCommunitiesCities = [];
  var allCommunitiesCountries = [];
  bool getInvite = false;
  int invitedCommunityIndex;
  var _myCancelableFuture;

  @override
  void initState() {
    WidgetsBinding.instance?.addPostFrameCallback((_){
      _myCancelableFuture = CancelableOperation.fromFuture(
        initialize(),
        onCancel: () => null,
      );
    });

    super.initState();
  }

  @override
  void dispose() {
    _myCancelableFuture?.cancel();
    super.dispose();
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

    checkCommunityInvite();

    setState(() {});
  }

  checkCommunityInvite() {
    for (var i = 0; i < allCommunities.length; i++) {
      if (allCommunities[i]["einladung"].contains(userId)) {
        invitedCommunityIndex = i;
        getInvite = true;
        break;
      }
    }
  }

  showFilter() {
    var comunitiesList = Hive.box("secureBox").get("communities");
    var filterCommunities = [];

    if (suchleiste.getSelected().isNotEmpty) {
      filterList = suchleiste.getSelected();
    }

    for (var community in comunitiesList) {
      if (checkIfInFilter(community, filterList)) {
        filterCommunities.add(community);
      }
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
          margin:
              const EdgeInsets.only(top: 10, bottom: 10, left: 70, right: 70),
          afterPageVisit: () => changePage(
              context,
              StartPage(
                selectedIndex: 3,
              )),
        ));
      }
    }

    if (allfavorites.isEmpty) {
      allfavorites.add(Container(
          margin: const EdgeInsets.all(10),
          child: Text(AppLocalizations.of(context).keineCommunityFavorite)));
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

  communityEinladungAnnehmen() {
    setState(() {
      allCommunities[invitedCommunityIndex]["members"].add(userId);
      allCommunities[invitedCommunityIndex]["einladung"].remove(userId);
      getInvite = false;
    });

    CommunityDatabase().update(
        "einladung = JSON_REMOVE(einladung, JSON_UNQUOTE(JSON_SEARCH(einladung, 'one', '$userId'))), members = JSON_ARRAY_APPEND(members, '\$', '$userId')",
        "WHERE id = '${allCommunities[invitedCommunityIndex]["id"]}'");
  }

  communityEinladungAblehnen() {
    setState(() {
      allCommunities[invitedCommunityIndex]["einladung"].remove(userId);
      getInvite = false;
    });

    CommunityDatabase().update(
        "einladung = JSON_REMOVE(einladung, JSON_UNQUOTE(JSON_SEARCH(einladung, 'one', '$userId')))",
        "WHERE id = '${allCommunities[invitedCommunityIndex]["id"]}'");
  }

  @override
  Widget build(BuildContext context) {
    suchleiste.hintText = AppLocalizations.of(context).filterEventSuche;

    showCommunities() {
      List<Widget> communities = [];

      for (var community in allCommunities) {
        communities.add(CommunityCard(
            margin: const EdgeInsets.all(10),
            community: community,
            withFavorite: true,
            afterPageVisit: () => changePage(
                context,
                StartPage(
                  selectedIndex: 3,
                )),
            afterFavorite: () {
              for (var i = 0; i < allCommunities.length; i++) {
                if (community["id"] == allCommunities[i]["id"]) {
                  if (allCommunities[i]["interesse"].contains(userId)) {
                    allCommunities[i]["interesse"].remove(userId);
                  } else {
                    allCommunities[i]["interesse"].add(userId);
                  }
                  setState(() {});
                }
              }
            }));
      }

      return SingleChildScrollView(
        child: Wrap(children: communities),
      );
    }

    floatingActionButtons() {
      return Container(
        alignment: Alignment.bottomRight,
        margin: const EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FloatingActionButton(
                heroTag: "show favorites",
                child: const Icon(Icons.star),
                onPressed: () => showFavoritesWindow()),
            const SizedBox(height: 10),
            FloatingActionButton(
                heroTag: "create Community",
                child: const Icon(Icons.add),
                onPressed: () =>
                    changePage(context, const CommunityErstellen())),
          ],
        ),
      );
    }

    showInvite() {
      return Container(
        padding: const EdgeInsets.all(10),
        height: 112,
        decoration: BoxDecoration(
          border: Border.all(),
        ),
        child: Column(
          children: [
            Text(AppLocalizations.of(context).zurCommunityEingeladen),
            const SizedBox(height: 5),
            Text(
              allCommunities[invitedCommunityIndex]["name"],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                    child: Text(AppLocalizations.of(context).annehmen),
                    onPressed: () => communityEinladungAnnehmen(),
                    style: ButtonStyle(
                        backgroundColor:
                            MaterialStateProperty.all<Color>(Colors.green))),
                const SizedBox(width: 30),
                ElevatedButton(
                    child: Text(AppLocalizations.of(context).ablehnen),
                    onPressed: () => communityEinladungAblehnen(),
                    style: ButtonStyle(
                        backgroundColor:
                            MaterialStateProperty.all<Color>(Colors.red)))
              ],
            )
          ],
        ),
      );
    }

    return Scaffold(
      floatingActionButton: floatingActionButtons(),
      body: Padding(
          padding: const EdgeInsets.only(top: kIsWeb ? 0 : 24),
          child: Column(
            children: [
              suchleiste,
              Expanded(child: showCommunities()),
              if (getInvite) showInvite(),
            ],
          )),
    );
  }
}
