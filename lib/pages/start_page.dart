import 'dart:io';

import 'package:familien_suche/global/custom_widgets.dart';
import 'package:familien_suche/pages/events/event_page.dart';
import 'package:familien_suche/services/database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:in_app_update/in_app_update.dart';

import '../global/variablen.dart';
import '../services/locationsService.dart';
import '../widgets/badge_icon.dart';
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
  PackageInfo packageInfo;
  var hasInternet = true;

  @override
  void initState() {
    WidgetsBinding.instance?.addPostFrameCallback((_) => _asyncMethod());

    super.initState();
  }

  _asyncMethod() async {
    await setHiveBoxen();

    checkFlexibleUpdate();

    checkAndUpdateProfil();
  }

  setHiveBoxen() async {
    var ownProfilBox = Hive.box("ownProfilBox");
    if (ownProfilBox.get("list") == null) {
      var ownProfil =
          await ProfilDatabase().getData("*", "WHERE id = '$userId'");
      ownProfilBox.put("list", ownProfil);
    }

    var stadtinfo =
        await StadtinfoDatabase().getData("*", "", returnList: true);
    Hive.box("stadtinfoBox").put("list", stadtinfo);
  }

  checkFlexibleUpdate() async {
    try {
      var updateInformation = await InAppUpdate.checkForUpdate();
      if (updateInformation.updateAvailability ==
              UpdateAvailability.updateAvailable &&
          !kIsWeb) {
        InAppUpdate.startFlexibleUpdate();
      }
    } catch (_) {}
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

    ProfilDatabase().updateProfil(
        "lastLogin = '${DateTime.now().toString()}'", "WHERE id = '$userId'");

    var automaticLocation = dbData["automaticLocation"];
    if (automaticLocation != null &&
        automaticLocation != standortbestimmung[0] &&
        automaticLocation != standortbestimmungEnglisch[0]) {
      setAutomaticLoaction(automaticLocation);
    }
  }

  setAutomaticLoaction(automaticLocationStatus) async {
    var ownProfilBox = Hive.box("ownProfilBox");
    var ownProfil = ownProfilBox.get("list");

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

      if (automaticLocationStatus == standortbestimmung[1] ||
          automaticLocationStatus == standortbestimmungEnglisch[1]) {
        ProfilDatabase().updateProfilLocation(userId, {
          "city": " ",
          "countryname": nearstLocationData["country"],
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

      //var geoData = {"candidates": [{"formatted_address": "Calarreona, Spain", "geometry": {"location": {"lat": 37.3833412, "lng": -1.6211373}, "viewport": {"northeast": {"lat": 37.3848616, "lng": -1.61708}, "southwest": {"lat": 37.38210979999999, "lng": -1.622294}}}}, {"formatted_address": "30889 Calarreona, Murcia, Spain", "geometry": {"location": {"lat": 37.3870332, "lng": -1.6196208}, "viewport": {"northeast": {"lat": 37.3899129, "lng": -1.6161955}, "southwest": {"lat": 37.3838421, "lng": -1.6231069}}}}], "status": "OK"};

      var locationData = await LocationService()
          .getDatabaseLocationdataFromGoogleResult(geoData);

      ProfilDatabase().updateProfilLocation(userId, locationData);
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

    if (!kIsWeb) hasNetwork();

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
            const BottomNavigationBarItem(
              icon: Icon(Icons.event),
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
