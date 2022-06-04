import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:in_app_update/in_app_update.dart';

import '../global/custom_widgets.dart';
import '../global/global_functions.dart';
import '../global/variablen.dart';
import '../services/database.dart';
import '../services/locationsService.dart';
import '../widgets/badge_icon.dart';
import '../windows/patchnotes.dart';
import 'force_update.dart';
import 'events/event_page.dart';
import 'login_register_page/create_profil_page.dart';
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

  @override
  void initState() {
    WidgetsBinding.instance?.addPostFrameCallback((_) => _asyncMethod());

    super.initState();
  }

  _asyncMethod() async {
    await setHiveBoxen();

    checkNewVersion();

    checkAndUpdateProfil();

    showPatchnotes();
  }

  setHiveBoxen() async {
    var ownProfil = await ProfilDatabase().getData("*", "WHERE id = '$userId'");
    Hive.box('secureBox').put("ownProfil", ownProfil);
  }

  checkNewVersion() async{
    if(kIsWeb) return;

    var updateInfo = await InAppUpdate.checkForUpdate();

    if(updateInfo?.updateAvailability ==
        UpdateAvailability.updateAvailable){
      await InAppUpdate.startFlexibleUpdate();
      await InAppUpdate.completeFlexibleUpdate();
    }

  }

  checkAndUpdateProfil() async {
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
      setAutomaticLoaction(automaticLocation);
    }

    ProfilDatabase().updateProfil(
        "lastLogin = '${DateTime.now().toString()}'", "WHERE id = '$userId'");
  }

  showPatchnotes() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    var buildNumber = int.parse(packageInfo.buildNumber);

    if (localBox.get("version") == null ||
        buildNumber > localBox.get("version")) {
      PatchnotesWindow(context: context).openWindow();
      localBox.put("version", buildNumber);
    }
  }

  setAutomaticLoaction(automaticLocationStatus) async {
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

      if (nearstLocationData["country"].isEmpty) return;

      if (automaticLocationStatus == standortbestimmung[1] ||
          automaticLocationStatus == standortbestimmungEnglisch[1]) {
        ProfilDatabase().updateProfilLocation(userId, {
          "city": " ",
          "land": nearstLocationData["country"],
          "longt": currentPosition.longitude,
          "latt": currentPosition.latitude,
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
      StadtinfoDatabase().addNewCity(locationData);
      StadtinfoDatabase().update(
          "familien = JSON_ARRAY_APPEND(familien, '\$', '$userId')",
          "WHERE ort LIKE '${locationData["city"]}' AND JSON_CONTAINS(familien, '\"$userId\"') < 1");
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> tabPages = <Widget>[
      //BoardPage(),
      const ErkundenPage(),
      const EventPage(),
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

    checkForceUpdate() async {
      var importantUpdateNumber =
          await AllgemeinDatabase().getData("importantUpdate", "");
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      var buildNumber = int.parse(packageInfo.buildNumber);

      if (buildNumber < importantUpdateNumber) {
        changePageForever(context, ForceUpdatePage());
      }
    }

    checkProfilExist() async {
      var profilExist =
          await ProfilDatabase().getData("name", "WHERE id = '$userId'");

      if (profilExist == false) {
        changePageForever(context, const CreateProfilPage());
      }
    }

    if (!kIsWeb) hasNetwork();
    if (!kIsWeb) checkForceUpdate();
    checkProfilExist();

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
            /*
              BottomNavigationBarItem(
                icon: Icon(Icons.feed),
                label: 'News',
              ),
*/
            const BottomNavigationBarItem(
              icon: Icon(Icons.map),
              label: 'World',
            ),
            BottomNavigationBarItem(
              icon: eventIcon(),
              label: 'Events',
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
