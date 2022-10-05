import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:in_app_update/in_app_update.dart';
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

class StartPage extends StatefulWidget {
  int selectedIndex;

  StartPage({Key key, this.selectedIndex = 0}) : super(key: key);

  @override
  _StartPageState createState() => _StartPageState();
}

class _StartPageState extends State<StartPage> {
  var userId = FirebaseAuth.instance.currentUser?.uid;
  var userName = FirebaseAuth.instance.currentUser?.displayName;
  var userAuthEmail = FirebaseAuth.instance.currentUser?.email;
  var hasInternet = true;
  var localBox = Hive.box('secureBox');
  var checkedA2HS = false;

  @override
  void initState() {
    WidgetsBinding.instance?.addPostFrameCallback((_) => _asyncMethod());

    super.initState();
  }

  _asyncMethod() async {
    print("refresht");
    if (!kIsWeb){
      var newUpdate = await checkForceUpdate();
      if(newUpdate) return;
    }

    await _checkNewVersion();

    await checkProfilExist();

    await _checkAndUpdateProfil();

    await _showPatchnotes();
  }

  _checkNewVersion() async{
    if(kIsWeb) return;

    try{
      var updateInfo = await InAppUpdate.checkForUpdate();

      if(updateInfo?.updateAvailability ==
          UpdateAvailability.updateAvailable){
        await InAppUpdate.startFlexibleUpdate();
        await InAppUpdate.completeFlexibleUpdate();
      }
    }catch(_){}
  }

  _checkAndUpdateProfil() async {
    if (userName == null) return;

    var dbData = await ProfilDatabase()
        .getData("email, token, automaticLocation", "WHERE id = '$userId'");

    var userDBEmail = dbData["email"];
    var userDeviceTokenDb = dbData["token"];
    var userDeviceTokenReal =
        kIsWeb ? null : await FirebaseMessaging.instance.getToken();

    if (userAuthEmail != userDBEmail) {
      ProfilDatabase()
          .updateProfil("email = '$userAuthEmail'", "WHERE id = '$userId'");
    }

    if (userDeviceTokenDb != userDeviceTokenReal) {
      ProfilDatabase().updateProfil(
          "token = '$userDeviceTokenReal'", "WHERE id = '$userId'");
    }

    var automaticLocation = dbData["automaticLocation"];
    if (automaticLocation != null &&
        automaticLocation != standortbestimmung[0] &&
        automaticLocation != standortbestimmungEnglisch[0]) {
      _setAutomaticLoaction(automaticLocation);
    }

    ProfilDatabase().updateProfil(
        "lastLogin = '${DateTime.now().toString()}'", "WHERE id = '$userId'");


  }

  checkProfilExist() async {
    var profilExist =
    await ProfilDatabase().getData("name", "WHERE id = '$userId'");

    if (profilExist == false) {
      changePageForever(context, const CreateProfilPage());
    }
  }

  _showPatchnotes() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    var buildNumber = int.parse(packageInfo.buildNumber);

    if (localBox.get("version") == null ||
        buildNumber > localBox.get("version")) {
      PatchnotesWindow(context: context).openWindow();
      localBox.put("version", buildNumber);
    }
  }

  _setAutomaticLoaction(automaticLocationStatus) async {
    var ownProfil = Hive.box('secureBox').get("ownProfil");

    if (DateTime.now()
            .difference(DateTime.parse(ownProfil["lastLogin"]))
            .inDays >
        0) {
      var newLocation = "";
      var currentPosition = await LocationService().getCurrentUserLocation();

      var nearstLocationData =
          await LocationService().getNearstLocationData(currentPosition);
      nearstLocationData =
          LocationService().transformNearstLocation(nearstLocationData);

      if(nearstLocationData["country"].isEmpty || nearstLocationData["city"].isEmpty) return;

      if (automaticLocationStatus == standortbestimmung[1] ||
          automaticLocationStatus == standortbestimmungEnglisch[1]) {

        var locationData = {
          "city": nearstLocationData["city"],
          "countryname": nearstLocationData["country"],
          "longt": currentPosition.longitude,
          "latt": currentPosition.latitude,
        };

        ProfilDatabase().updateProfilLocation(userId, locationData);

        NewsPageDatabase().addNewNews({
          "typ": "ortswechsel",
          "information": json.encode(locationData),
        });

        return;
      } else if (automaticLocationStatus == standortbestimmung[2] ||
          automaticLocationStatus == standortbestimmungEnglisch[2]) {
        newLocation = nearstLocationData["city"];
      } else if (automaticLocationStatus == standortbestimmung[3] ||
          automaticLocationStatus == standortbestimmungEnglisch[3]) {
        newLocation = nearstLocationData["region"];
      }

      if (newLocation == ownProfil["ort"]) return;

      var geoData = await LocationService().getLocationGeoData(newLocation);

      var locationData = await LocationService()
          .getDatabaseLocationdataFromGoogleResult(geoData);

      ProfilDatabase().updateProfilLocation(userId, locationData);
      await StadtinfoDatabase().addNewCity(locationData);
      StadtinfoDatabase().update(
          "familien = JSON_ARRAY_APPEND(familien, '\$', '$userId')",
          "WHERE ort LIKE '${locationData["city"]}' AND JSON_CONTAINS(familien, '\"$userId\"') < 1"
      );
      NewsPageDatabase().addNewNews({
        "typ": "ortswechsel",
        "information": json.encode(locationData),
      });
    }
  }

  checkForceUpdate() async {
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



  @override
  Widget build(BuildContext context) {
    List<Widget> tabPages = <Widget>[
      const NewsPage(),
      const ErkundenPage(),
      const EventPage(),
      const CommunityPage(),
      const ChatPage(),
      const SettingPage()
    ];


    void hasNetwork() async {
      try {
        await InternetAddress.lookup('example.com');
        if (hasInternet == false) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
        }
        hasInternet = true;
      } on SocketException catch (_) {
        hasInternet = false;
        customSnackbar(context, "kein Internet",
            duration: const Duration(days: 365));
      }
    }

    void _onItemTapped(int index) {
      setState(() {
        widget.selectedIndex = index;
      });
    }

    eventIcon() {
      return FutureBuilder(
          future: EventDatabase().getData("*",
              "WHERE erstelltVon ='$userId' AND json_length(freischalten) > 0",
              returnList: true),
          builder: (BuildContext context, AsyncSnapshot snap) {
            if (!snap.hasData) return const Icon(Icons.event);

            var events = snap.data;
            events = events == false ? 0 : events.length;

            return BadgeIcon(
                icon: Icons.event, text: events > 0 ? events.toString() : "");
          });
    }

    communityIcon(){
      return FutureBuilder(
          future: CommunityDatabase().getData("*",
              "WHERE JSON_CONTAINS(einladung, '\"$userId\"') > 0",
              returnList: true),
          builder: (BuildContext context, AsyncSnapshot snap) {
            if (!snap.hasData) return const Icon(Icons.cottage);

            var invitedCommunity = snap.data;
            var hasInvite = invitedCommunity == false ? 0 : 1;

            return BadgeIcon(
                icon: Icons.cottage, text: hasInvite > 0 ? "1" : "");
          });
    }

    chatIcon() {
      return FutureBuilder(
          future:
              ProfilDatabase().getData("newMessages", "WHERE id = '$userId'"),
          builder: (BuildContext context, AsyncSnapshot snap) {
            if (!snap.hasData) return const Icon(Icons.chat);

            var newMessages = snap.data;
            newMessages = newMessages == false ? 0 : newMessages;

            return BadgeIcon(
                icon: Icons.chat,
                text: newMessages > 0 ? newMessages.toString() : "");
          });
    }

    Future<bool> showAddHomePageDialog(BuildContext context) async {
      return showDialog<bool>(
        context: context,
        builder: (context) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 20.0),
                  Text(
                    AppLocalizations.of(context).a2hsBody,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 20.0),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    ElevatedButton(
                        onPressed: () {
                          js.context.callMethod("presentAddToHome");
                          Navigator.pop(context, false);
                          localBox.put("a2hs", true);
                        },
                        child: Text(AppLocalizations.of(context).ja)),
                    const SizedBox(width: 50),
                    ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context, false);
                          localBox.put("a2hs", false);
                        },
                        child: Text(AppLocalizations.of(context).nein))
                  ],)

                ],
              ),
            ),
          );
        },
      );
    }

    checkA2HS(){
      if (kIsWeb && !checkedA2HS) {
        checkedA2HS = true;
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          var usedA2HS = localBox.get("a2hs");
          if (usedA2HS == null) {
            final bool isDeferredNotNull =
            js.context.callMethod("isDeferredNotNull") as bool;

            if (isDeferredNotNull){
              localBox.put("a2hs", true);
              await showAddHomePageDialog(context);
            }
          }
        });
      }
    }

    if (!kIsWeb) hasNetwork();

    checkA2HS();


    return Scaffold(
        body: Center(
          child: tabPages.elementAt(widget.selectedIndex),
        ),
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Theme.of(context).colorScheme.primary,
          currentIndex: widget.selectedIndex,
          selectedItemColor: Colors.white,
          onTap: _onItemTapped,
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
        ));
  }
}
