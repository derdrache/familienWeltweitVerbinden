import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:upgrader/upgrader.dart';
import "package:universal_html/js.dart" as js;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../global/custom_widgets.dart';
import '../global/global_functions.dart';
import '../global/variablen.dart';
import '../services/database.dart';
import '../services/locationsService.dart';
import '../widgets/badge_icon.dart';
import '../windows/patchnotes.dart';
import 'community/community_page.dart';
import 'force_update.dart';
import 'events/event_page.dart';
import 'login_register_page/create_profil_page.dart';
import 'news/news_page.dart';
import 'weltkarte/erkunden_page.dart';
import 'chat/chat_page.dart';
import 'settings/setting_page.dart';

final String userId = FirebaseAuth.instance.currentUser?.uid;

//ignore: must_be_immutable
class StartPage extends StatefulWidget {
  int selectedIndex;

  StartPage({Key key, this.selectedIndex = 0}) : super(key: key);

  @override
  _StartPageState createState() => _StartPageState();
}

class _StartPageState extends State<StartPage> with WidgetsBindingObserver {
  final String userName = FirebaseAuth.instance.currentUser?.displayName;
  Map ownProfil = Hive.box("secureBox").get("ownProfil");
  bool hasInternet = true;
  var checkedA2HS = false;
  List<Widget> tabPages = <Widget>[
    const NewsPage(),
    const ErkundenPage(),
    const EventPage(),
    const CommunityPage(),
    const ChatPage(),
    const SettingPage()
  ];

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance?.addPostFrameCallback((_) => _asyncMethod());

    super.initState();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshHiveDb();
    }
  }

  _asyncMethod() async {
    await refreshHiveAllgemein();
    if (!kIsWeb) {
      var newUpdate = await _checkForceUpdate();
      if (newUpdate) return;
    }

    bool profileExist = await _checkProfilExist();
    if (!profileExist) changePageForever(context, const CreateProfilPage());
    await _showPatchnotes();

    if (userName == null || ownProfil == null) return;

    _updateOwnLastLogin();
    _oldUserAutomaticJoinChats(ownProfil["ort"]);
    _updateAutomaticLocation();
    _updateOwnEmail();
    _updateOwnToken();
  }

  _checkForceUpdate() async {
    var importantUpdateNumber =
    await AllgemeinDatabase().getData("importantUpdate", "");

    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    var buildNumber = int.parse(packageInfo.buildNumber);

    if (buildNumber < importantUpdateNumber) {
      changePageForever(context, ForceUpdatePage());
      return true;
    }
    return false;
  }

  _checkProfilExist() async {
    var profilExist =
    await ProfilDatabase().getData("name", "WHERE id = '$userId'");

    return profilExist != false;
  }

  _showPatchnotes() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    var buildNumber = int.parse(packageInfo.buildNumber);

    if (buildNumber == Hive.box('secureBox').get("version")) return;

    PatchnotesWindow(context: context).openWindow();
    Hive.box('secureBox').put("version", buildNumber);
  }

  _updateOwnLastLogin() async {
    ProfilDatabase().updateProfil(
        "lastLogin = '${DateTime.now().toString()}'", "WHERE id = '$userId'");

    ownProfil["lastLogin"] = DateTime.now().toString();
  }

  _updateOwnEmail() async {
    final String userAuthEmail = FirebaseAuth.instance.currentUser?.email;
    var userDBEmail = ownProfil["email"];

    if (userAuthEmail != userDBEmail) {
      ProfilDatabase()
          .updateProfil("email = '$userAuthEmail'", "WHERE id = '$userId'");
    }
  }

  _updateOwnToken() async {
    var userDeviceTokenDb = ownProfil["token"];
    var userDeviceTokenReal =
        kIsWeb ? null : await FirebaseMessaging.instance.getToken();

    if (userDeviceTokenDb != userDeviceTokenReal) {
      ProfilDatabase().updateProfil(
          "token = '$userDeviceTokenReal'", "WHERE id = '$userId'");
    }
  }

  _updateAutomaticLocation() async {
    var automaticLocation = ownProfil["automaticLocation"];
    bool automaticLocationOff = automaticLocation == standortbestimmung[0] &&
        automaticLocation == standortbestimmungEnglisch[0];
    var dateDifference =
        DateTime.now().difference(DateTime.parse(ownProfil["lastLogin"]));
    var firstTimeOnDay = dateDifference.inDays > 0;

    if (automaticLocation == null || automaticLocationOff || !firstTimeOnDay)
      return;

    _setAutomaticLoaction(automaticLocation);
  }

  _setAutomaticLoaction(automaticLocationStatus) async {
    String newLocation = "";
    bool exactLocation = automaticLocationStatus == standortbestimmung[1] ||
        automaticLocationStatus == standortbestimmungEnglisch[1];
    bool nearstCity = automaticLocationStatus == standortbestimmung[2] ||
        automaticLocationStatus == standortbestimmungEnglisch[2];
    bool nearstRegion = automaticLocationStatus == standortbestimmung[3] ||
        automaticLocationStatus == standortbestimmungEnglisch[3];
    var currentPosition = await LocationService().getCurrentUserLocation();
    var nearstLocationData =
        await LocationService().getNearstLocationData(currentPosition);
    nearstLocationData =
        LocationService().transformNearstLocation(nearstLocationData);

    if (nearstLocationData["country"].isEmpty ||
        nearstLocationData["city"].isEmpty) return;

    if (exactLocation) {
      var locationData = {
        "city": nearstLocationData["city"],
        "countryname": nearstLocationData["country"],
        "longt": currentPosition.longitude,
        "latt": currentPosition.latitude,
      };

      if (ownProfil["city"] == locationData["city"]) return;

      _databaseOperations(locationData,
          exactLocation: true, nearstLocationData: nearstLocationData);

      return;
    } else if (nearstCity) {
      newLocation = nearstLocationData["city"];
    } else if (nearstRegion) {
      newLocation = nearstLocationData["region"];
    }

    if (newLocation == ownProfil["ort"]) return;

    var geoData = await LocationService().getLocationGeoData(newLocation);
    var locationData = await LocationService()
        .getDatabaseLocationdataFromGoogleResult(geoData);

    _databaseOperations(locationData, exactLocation: false);
  }

  _databaseOperations(locationData,
      {exactLocation = false, nearstLocationData}) async {
    var oldLocation = ownProfil["ort"];

    _updateOwnLocation(locationData);
    _updateNewsPage(locationData);
    _updateCityInformation(locationData, exactLocation, nearstLocationData);
    _updateChatGroups(oldLocation, locationData);
  }

  _updateOwnLocation(locationData) {
    ProfilDatabase().updateProfilLocation(userId, locationData);

    var ownProfil = Hive.box("secureBox").get("ownProfil");
    ownProfil["ort"] = locationData["city"];
    ownProfil["longt"] = locationData["longt"];
    ownProfil["latt"] = locationData["latt"];
    ownProfil["land"] = locationData["countryname"];
  }

  _updateNewsPage(locationData) {
    NewsPageDatabase().addNewNews({
      "typ": "ortswechsel",
      "information": json.encode(locationData),
    });

    var newsFeed = Hive.box("secureBox").get("newsFeed");
    newsFeed.add({
      "typ": "ortswechsel",
      "information": locationData,
      "erstelltVon": userId,
      "erstelltAm": DateTime.now().toString()
    });
  }

  _updateCityInformation(
      locationData, exactLocation, nearstLocationData) async {
    if (exactLocation) {
      locationData["latt"] = nearstLocationData["latt"];
      locationData["longt"] = nearstLocationData["longt"];
    }
    await StadtinfoDatabase().addNewCity(locationData);

    StadtinfoDatabase().update(
        "familien = JSON_ARRAY_APPEND(familien, '\$', '$userId')",
        "WHERE ort LIKE '${locationData["city"]}' AND JSON_CONTAINS(familien, '\"$userId\"') < 1");
  }

  _updateChatGroups(oldLocation, locationData) {
    var leaveChat = getCityFromHive(cityName: oldLocation);
    var leaveChatId = leaveChat != null ? leaveChat["id"] : "0";

    ChatGroupsDatabase().leaveChat(leaveChatId);
    ChatGroupsDatabase().joinAndCreateCityChat(locationData["city"]);
  }

  _refreshHiveDb() async {
    await refreshHiveChats();
    await refreshHiveEvents();
    await refreshHiveProfils();
    await refreshHiveCommunities();
    await refreshHiveNewsPage();
  }

  _oldUserAutomaticJoinChats(ort) async {
    var lastLoginBeforeUpdate = DateTime.parse(ownProfil["lastLogin"])
        .isBefore(DateTime.parse("2022-11-16"));

    if (!lastLoginBeforeUpdate) return;

    await ChatGroupsDatabase().updateChatGroup(
        "users = JSON_MERGE_PATCH(users, '${json.encode({
              userId: {"newMessages": 0}
            })}')",
        "WHERE id = '1'");
    await ChatGroupsDatabase().joinAndCreateCityChat(ort);
  }

  @override
  Widget build(BuildContext context) {

    void hasNetwork() async {
      try {
        await InternetAddress.lookup('example.com');
        if (hasInternet == false) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
        }
        hasInternet = true;
      } on SocketException catch (_) {
        hasInternet = false;
        customSnackbar(context, AppLocalizations.of(context).keineVerbindungInternet,
            duration: const Duration(days: 365));
      }
    }

    void _onItemTapped(int index) {
      setState(() {
        widget.selectedIndex = index;
      });
    }

    Future<bool> showAddHomePageDialog(BuildContext context) async {
      return showDialog<bool>(
        context: context,
        builder: (context) {
          return Dialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                      child: Icon(
                    Icons.add_circle,
                    size: 70,
                    color: Theme.of(context).primaryColor,
                  )),
                  const SizedBox(height: 20.0),
                  Text(
                    AppLocalizations.of(context).a2hsTitle,
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 20.0),
                  Text(
                    AppLocalizations.of(context).a2hsBody,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 20.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                          onPressed: () {
                            js.context.callMethod("presentAddToHome");
                            Navigator.pop(context, false);
                            Hive.box('secureBox').put("a2hs", true);
                          },
                          child: Text(AppLocalizations.of(context).ja)),
                      const SizedBox(width: 50),
                      ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context, false);
                            Hive.box('secureBox').put("a2hs", false);
                          },
                          child: Text(AppLocalizations.of(context).nein))
                    ],
                  )
                ],
              ),
            ),
          );
        },
      );
    }

    checkA2HS() {
      if (kIsWeb && !checkedA2HS) {
        checkedA2HS = true;
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          var usedA2HS = Hive.box('secureBox').get("a2hs");
          if (usedA2HS == null) {
            final bool isDeferredNotNull =
                js.context.callMethod("isDeferredNotNull") as bool;

            if (isDeferredNotNull) {
              Hive.box('secureBox').put("a2hs", true);
              await showAddHomePageDialog(context);
            }
          }
        });
      }
    }

    if (!kIsWeb) hasNetwork();

    checkA2HS();

    return UpgradeAlert(
      upgrader: Upgrader(shouldPopScope: () => true),
      child: Scaffold(
          body: Center(
            child: tabPages.elementAt(widget.selectedIndex),
          ),
          bottomNavigationBar: CustomBottomNavigationBar(
            onNavigationItemTapped: _onItemTapped,
            selectNavigationItem: widget.selectedIndex,
          )),
    );
  }
}

class CustomBottomNavigationBar extends StatelessWidget {
  final Function onNavigationItemTapped;
  final int selectNavigationItem;

  CustomBottomNavigationBar(
      {Key key, this.onNavigationItemTapped, this.selectNavigationItem})
      : super(key: key);

  eventIcon() {
    var userFreischalten = 0;
    var myEvents = Hive.box('secureBox').get("myEvents") ?? [];

    for (var event in myEvents) {
      userFreischalten += event["freischalten"].length;
    }

    return BadgeIcon(
        icon: Icons.event,
        text: userFreischalten > 0 ? userFreischalten.toString() : "");
  }

  communityIcon() {
    var communityInvite = 0;
    var allCommunities = Hive.box('secureBox').get("communities") ?? [];

    for (var community in allCommunities) {
      if (community["einladung"].contains(userId)) communityInvite += 1;
    }

    return BadgeIcon(
        icon: Icons.cottage,
        text: communityInvite > 0 ? communityInvite.toString() : "");
  }

  chatIcon() {
    var newMessageCount = 0;
    List myChats = Hive.box("secureBox").get("myChats") ?? [];
    List myGroupChats = Hive.box("secureBox").get("myGroupChats") ?? [];

    for (var chat in myChats + myGroupChats) {
      if (chat["users"][userId] == null) continue;
      newMessageCount += chat["users"][userId]["newMessages"];
    }

    return BadgeIcon(
        icon: Icons.chat,
        text: newMessageCount > 0 ? newMessageCount.toString() : "");
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: Theme.of(context).colorScheme.primary,
      currentIndex: selectNavigationItem,
      selectedItemColor: Colors.white,
      onTap: onNavigationItemTapped,
      items: <BottomNavigationBarItem>[
        const BottomNavigationBarItem(
          icon: Icon(Icons.feed),
          label: 'News',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.map),
          label: 'World',
        ),
        BottomNavigationBarItem(
          icon: eventIcon(),
          label: 'Events',
        ),
        BottomNavigationBarItem(
          icon: communityIcon(),
          label: 'Community',
        ),
        BottomNavigationBarItem(
          icon: chatIcon(),
          label: 'Chat',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.settings),
          label: 'Settings',
        ),
      ],
    );
  }
}
