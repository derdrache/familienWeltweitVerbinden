import 'dart:convert';

import 'package:familien_suche/widgets/layout/ownIconButton.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:upgrader/upgrader.dart';

import '../global/encryption.dart';
import '../global/global_functions.dart';
import '../global/variablen.dart';
import '../services/database.dart';
import '../services/locationsService.dart';
import '../services/network_Connectivity.dart';
import 'informationen/information.dart';
import 'login_register_page/create_profil_page.dart';
import 'news/news_page.dart';
import 'weltkarte/erkunden_page.dart';
import 'chat/chat_page.dart';
import 'settings/setting_page.dart';
import 'force_update.dart';


//ignore: must_be_immutable
class StartPage extends StatefulWidget {
  int selectedIndex;
  int? chatPageSliderIndex;

  StartPage({
    Key? key,
    this.selectedIndex = 0,
    this.chatPageSliderIndex,
  }) : super(key: key);

  @override
  _StartPageState createState() => _StartPageState();
}

class _StartPageState extends State<StartPage> {
  final String userId = FirebaseAuth.instance.currentUser!.uid;
  final String? userName = FirebaseAuth.instance.currentUser!.displayName;
  Map ownProfil = Hive.box("secureBox").get("ownProfil");
  bool hasInternet = true;
  var checkedA2HS = false;
  late List<Widget> pages;
  var _networkConnectivity;
  late bool noProfil;

  @override
  void initState() {
    widget.chatPageSliderIndex ??= 0;
    noProfil = ownProfil == null || ownProfil["id"] == null;
    _networkConnectivity = NetworkConnectivity(context);

    WidgetsBinding.instance.addPostFrameCallback((_) => _asyncMethod());

    super.initState();

    _networkConnectivity.checkInternetStatusStream();
  }

  _asyncMethod() async {
    await refreshHiveAllgemein();
    if (!kIsWeb) {
      var newUpdate = await _checkForceUpdate();
      if (newUpdate) return;
    }

    bool profileExist = await _checkProfilExist();
    if (!profileExist) changePageForever(context, const CreateProfilPage());

    if (userName == null || ownProfil == null) return;

    _oldUserAutomaticJoinChats(ownProfil["ort"]);
    _setOwnLocation();
    _updateOwnEmail();
    _updateOwnToken();
    _updateOwnLastLogin();
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

  _updateOwnLastLogin() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    var buildNumber = int.parse(packageInfo.buildNumber);
    Hive.box('secureBox').put("version", buildNumber);

    ProfilDatabase().updateProfil(
        "lastLogin = '${DateTime.now().toString()}'", "WHERE id = '$userId'");

    ownProfil["lastLogin"] = DateTime.now().toString();


  }

  _updateOwnEmail() async {
    final String? userAuthEmail = FirebaseAuth.instance.currentUser!.email;
    String enryptEmail = encrypt(userAuthEmail!);
    var userDBEmail = ownProfil["email"];

    if (userAuthEmail != userDBEmail) {
      ProfilDatabase()
          .updateProfil("email = '$enryptEmail'", "WHERE id = '$userId'");
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

  _setOwnLocation(){
    var automaticLocation = ownProfil["automaticLocation"];
    bool automaticLocationOff = automaticLocation == standortbestimmung[0] ||
        automaticLocation == standortbestimmungEnglisch[0];
    var dateDifference =
    DateTime.now().difference(DateTime.parse(ownProfil["lastLogin"]));
    var firstTimeOnDay = dateDifference.inDays > 0;

    if(automaticLocation == null || automaticLocationOff || !firstTimeOnDay){
      _checkTravelPlanAndUpdateLocation();
    }else{
      _setAutomaticLoaction(automaticLocation);
    }
  }

  _checkTravelPlanAndUpdateLocation(){

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

      if (ownProfil["ort"] == locationData["city"]) return;

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
    _updateCityInformation(locationData, exactLocation);
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

  _updateCityInformation(locationData, exactLocation) async {
    await StadtinfoDatabase().addNewCity(locationData);

    StadtinfoDatabase().update(
        "familien = JSON_ARRAY_APPEND(familien, '\$', '$userId')",
        "WHERE (ort LIKE '%${locationData["city"]}%' OR ort LIKE '%${locationData["countryname"]}%') AND JSON_CONTAINS(familien, '\"$userId\"') < 1");
  }

  _updateChatGroups(oldLocation, locationData) {
    var leaveChat = getCityFromHive(cityName: oldLocation);
    var leaveChatId = leaveChat != null ? leaveChat["id"] : "0";

    ChatGroupsDatabase().leaveChat(leaveChatId);
    ChatGroupsDatabase().joinAndCreateCityChat(locationData["city"]);
  }

  _oldUserAutomaticJoinChats(ort) async {
    var savedVersion = Hive.box('secureBox').get("version");
    var lastLoginBeforeUpdate = savedVersion == null && DateTime.parse(ownProfil["lastLogin"])
        .isBefore(DateTime.parse("2022-12-16"));
    var versionBiggerThenChatGroupUpdate = savedVersion != null && savedVersion >= 34;

    if (!lastLoginBeforeUpdate || versionBiggerThenChatGroupUpdate) return;

    await ChatGroupsDatabase().updateChatGroup(
        "users = JSON_MERGE_PATCH(users, '${json.encode({
              userId: {"newMessages": 0}
            })}')",
        "WHERE id = '1'");
    await ChatGroupsDatabase().joinAndCreateCityChat(ort);
  }

  @override
  Widget build(BuildContext context) {
    pages = [
      NewsPage(),
      ErkundenPage(),
      InformationPage(),
      ChatPage(
          chatPageSliderIndex: widget.chatPageSliderIndex!
      ),
      const SettingPage()
    ];

    void _onItemTapped(int index) {
      setState(() {
        widget.selectedIndex = index;
      });
    }

    if(noProfil) return Scaffold();

    return UpgradeAlert(
      upgrader: Upgrader(shouldPopScope: () => true),
      child: Scaffold(
          body: Center(
            child: pages.elementAt(widget.selectedIndex),
          ),
          bottomNavigationBar: CustomBottomNavigationBar(
            onNavigationItemTapped: _onItemTapped,
            selectNavigationItem: widget.selectedIndex,
          )),
    );
  }
}

class CustomBottomNavigationBar extends StatelessWidget {
  final String userId = FirebaseAuth.instance.currentUser!.uid;
  final Function(int)  onNavigationItemTapped;
  final int selectNavigationItem;

  CustomBottomNavigationBar(
      {Key? key, required this.onNavigationItemTapped, required this.selectNavigationItem})
      : super(key: key);

  _eventNotification() {
    num eventNotification = 0;
    var myMeetups = Hive.box('secureBox').get("myEvents") ?? [];

    for (var meetup in myMeetups) {
      bool isOwner = meetup["erstelltVon"] == userId;
      bool isNotPublic = meetup["art"] != "public" && meetup["art"] != "öffentlich";

      if(isOwner && isNotPublic){
        eventNotification += meetup["freischalten"].length;
      }
    }

    return eventNotification;
  }

  _communitNotifikation() {
    var communityNotifikation = 0;
    var allCommunities = Hive.box('secureBox').get("communities") ?? [];

    for (var community in allCommunities) {
      if (community["einladung"].contains(userId)) communityNotifikation += 1;
    }

    return communityNotifikation;
  }

  informationenIcon(){
    var notification = _eventNotification() + _communitNotifikation();

    return OwnIconButton(
      icon: Icons.group_work,
      size: 24,
      margin: EdgeInsets.zero,
      badgeText: notification > 0 ? notification.toString() : "",
    );
  }

  chatIcon() {
    return FutureBuilder(
      future: getChatNewMessageCount(),
      builder: (context, snapshot) {
        num newMessageCount = 0;

        List myChats = Hive.box("secureBox").get("myChats") ?? [];
        List myGroupChats = Hive.box("secureBox").get("myGroupChats") ?? [];

        for (var chat in myChats + myGroupChats) {
          if (chat["users"][userId] == null) continue;
          newMessageCount += chat["users"][userId]["newMessages"];
        }

        if(snapshot.hasData && snapshot.data != false){
          newMessageCount = 0;
          newMessageCount += snapshot.data as num;
        }

        return OwnIconButton(
          icon: Icons.chat,
          size: 24,
          margin: EdgeInsets.zero,
          badgeText: newMessageCount > 0 ? newMessageCount.toString() : "",
        );
      }
    );
  }

  getChatNewMessageCount() async{
    var newMessageCount = 0;

    var privatChatNewMessages = await ChatDatabase().getChatData("SUM(JSON_EXTRACT(users, '\$.$userId.newMessages'))",
        "WHERE JSON_CONTAINS_PATH(users, 'one', '\$.$userId') > 0");
    var groupChatNewMessages = await ChatGroupsDatabase().getChatData("SUM(JSON_EXTRACT(users, '\$.$userId.newMessages'))",
        "WHERE JSON_CONTAINS_PATH(users, 'one', '\$.$userId') > 0");

    return newMessageCount + privatChatNewMessages + groupChatNewMessages;
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
          icon: informationenIcon(),
          label: "Information",
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
