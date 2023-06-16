import 'package:familien_suche/global/global_functions.dart';
import 'package:familien_suche/pages/start_page.dart';
import 'package:familien_suche/services/database.dart';
import 'package:familien_suche/widgets/custom_appbar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../../services/locationsService.dart';
import '../../../global/global_functions.dart' as global_functions;
import 'community_card.dart';
import 'community_erstellen.dart';

class CommunityPage extends StatefulWidget {
  bool searchOn;

  CommunityPage({Key? key, this.searchOn = false}) : super(key: key);

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  var userId = FirebaseAuth.instance.currentUser!.uid;
  var allCommunities = Hive.box('secureBox').get("communities") ?? [];
  var isLoading = true;
  bool filterOn = false;
  var filterList = [];
  var allCommunitiesCities = [];
  var allCommunitiesCountries = [];
  bool getInvite = false;
  late int invitedCommunityIndex;
  bool onSearch = false;
  TextEditingController communitySearchKontroller = TextEditingController();
  FocusNode searchFocusNode = FocusNode();
  String pageTitle = "Communities";

  @override
  void initState() {
    onSearch = widget.searchOn;
    WidgetsBinding.instance.addPostFrameCallback((_) => initialize());

    super.initState();
  }

  initialize() async {
    for (var community in allCommunities) {
      allCommunitiesCities.add(community["ort"]);

      var countryData = LocationService().getCountryLocation(community["land"]);
      allCommunitiesCountries.add(
          spracheIstDeutsch ? countryData["nameGer"] : countryData["nameEng"]);
    }

    isLoading = false;

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
        "einladung = JSON_REMOVE(einladung, JSON_UNQUOTE(JSON_SEARCH(einladung, 'one', '$userId'))), interesse = JSON_REMOVE(interesse, JSON_UNQUOTE(JSON_SEARCH(interesse, 'one', '$userId')))",
        "WHERE id = '${allCommunities[invitedCommunityIndex]["id"]}'");
  }

  getAllSearchCommunities(){
    var searchedCommunities = [];
    var searchText = communitySearchKontroller.text;

    if(searchText.isEmpty) return allCommunities;

    var searchTextFirstLetterBig = searchText.replaceFirst(searchText[0], searchText[0].toUpperCase());

    for(var community in allCommunities){
      bool nameKondition = community["name"].contains(searchText) || community["name"].contains(searchTextFirstLetterBig);
      bool countryKondition = community["land"].contains(searchText) || community["land"].contains(searchTextFirstLetterBig);
      bool cityKondition = community["ort"].contains(searchText) || community["ort"].contains(searchTextFirstLetterBig);

      if(nameKondition || countryKondition || cityKondition) searchedCommunities.add(community);

    }

    return searchedCommunities;
  }

  getAllFavoritesCommunities(){
    var favoritesCommunities = [];

    for(var community in allCommunities){
      var myCommunity = community["erstelltVon"].contains(userId);
      var isFavorite = community["interesse"].contains(userId);

      if(myCommunity || isFavorite) favoritesCommunities.add(community);
    }

    return favoritesCommunities;
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;

    showCommunities() {
      List shownCommunities = onSearch ? getAllSearchCommunities() : getAllFavoritesCommunities();
      List<Widget> communities = [];
      var emptyText = AppLocalizations.of(context)!.nochKeinegemeinschaftVorhanden;
      var emptySearchText = AppLocalizations.of(context)!.sucheKeineErgebnisse;

      if (shownCommunities.isEmpty) {
        communities.add(SizedBox(
          height: 300,
          child: Center(
              child: Text(onSearch ? emptySearchText : emptyText,
                style: const TextStyle(fontSize: 20),
              )),
        ));
      }

      for (var community in shownCommunities) {
        communities.add(CommunityCard(
            margin: const EdgeInsets.all(15),
            community: community,
            withFavorite: true,
            fromCommunityPage: !onSearch,
            fromCommunityPageSearch: onSearch,
            afterFavorite: (){
              setState(() {});
            })
        );
      }

      return SingleChildScrollView(
        child: SizedBox(
          width: double.infinity,
          child: Wrap(
              alignment: WrapAlignment.center,
              children: [
                ...communities,
                if(onSearch) const SizedBox(height: 330)
              ]
          ),
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
            Text(AppLocalizations.of(context)!.zurCommunityEingeladen),
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
                    child: Text(AppLocalizations.of(context)!.annehmen),
                    onPressed: () => communityEinladungAnnehmen(),
                    style: ButtonStyle(
                        backgroundColor:
                            MaterialStateProperty.all<Color>(Colors.green))),
                const SizedBox(width: 30),
                ElevatedButton(
                    child: Text(AppLocalizations.of(context)!.ablehnen),
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
            Column(
              children: [
                Expanded(child: showCommunities()),
                if (getInvite) showInvite(),
              ],
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
                    controller: communitySearchKontroller,
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
              heroTag: "create Community",
              child: const Icon(Icons.create),
              onPressed: () =>
                  changePage(context, const CommunityErstellen())),
          const SizedBox(height: 10),
          FloatingActionButton(
            mini: onSearch ? true: false,
            backgroundColor: onSearch ? Colors.red : null,
            onPressed: () {
              if(onSearch){
                pageTitle = "Communities";
                searchFocusNode.unfocus();
                communitySearchKontroller.clear();
              }else{
                pageTitle = AppLocalizations.of(context)!.suche +" "+ "Communities";
              }

              setState(() {
                onSearch = !onSearch;
              });
            },
            child: Icon(onSearch ? Icons.close : Icons.search),
          ),
          if(getInvite) const SizedBox(height: 110),
        ],
      ),
    );
  }
}
