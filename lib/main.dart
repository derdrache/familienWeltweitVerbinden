import 'dart:convert';

import 'package:familien_suche/services/locationsService.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'firebase_options.dart';
import 'pages/start_page.dart';
import 'pages/show_profil.dart';
import 'pages/chat/chat_details.dart';
import 'pages/events/event_details.dart';
import 'pages/login_register_page/login_page.dart';
import 'services/database.dart';
import 'services/local_notification.dart';
import 'auth/secrets.dart';

var appIcon = '@mipmap/ic_launcher';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}

hiveInit() async {
  await Hive.initFlutter();

  await Hive.openBox("secureBox", encryptionCipher: HiveAesCipher(boxEncrpytionKey), crashRecovery: false);

  var countryJsonText =
  await rootBundle.loadString('assets/countryGeodata.json');
  var geodata = json.decode(countryJsonText)["data"];
  Hive.box('secureBox').put("countryGeodata", geodata);

  var continentsJsonText =
  await rootBundle.loadString('assets/continentsGeodata.json');
  var continentsGeodata = json.decode(continentsJsonText)["data"];
  Hive.box('secureBox').put("kontinentGeodata", continentsGeodata);

}

sortProfils(profils) {
  var allCountries = LocationService().getAllCountries();

  profils.sort((a, b) {
    var profilALand = a['land'];
    var profilBLand = b['land'];

    if (allCountries["eng"].contains(profilALand)) {
      var index = allCountries["eng"].indexOf(profilALand);
      profilALand = allCountries["ger"][index];
    }
    if (allCountries["eng"].contains(profilBLand)) {
      var index = allCountries["eng"].indexOf(profilBLand);
      profilBLand = allCountries["ger"][index];
    }

    int compareCountry = (profilBLand).compareTo(profilALand) as int;

    if (compareCountry != 0) return compareCountry;

    return b["ort"].compareTo(a["ort"]) as int;
  });

  return profils;
}

refreshHiveData() async {
  var stadtinfo = await StadtinfoDatabase()
      .getData("*", "ORDER BY ort ASC", returnList: true);
  Hive.box("secureBox").put("stadtinfo", stadtinfo);

  var stadtinfoUser =
  await StadtinfoUserDatabase().getData("*", "", returnList: true);
  Hive.box("secureBox").put("stadtinfoUser", stadtinfoUser);
}


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  if (!kIsWeb) {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  await hiveInit();
  refreshHiveData();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  String userId = FirebaseAuth.instance.currentUser?.uid;
  bool emailVerified = FirebaseAuth.instance.currentUser?.emailVerified ?? false;
  BuildContext pageContext;

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  MyApp({Key key}) : super(key: key);

  initialization() async {
    if (userId == null) {
      await FirebaseAuth.instance.authStateChanges().first;
      userId = FirebaseAuth.instance.currentUser.uid;
      emailVerified = FirebaseAuth.instance.currentUser?.emailVerified ?? false;
    }

    if (kIsWeb) return;

    setFirebaseNotifications();
  }

  setFirebaseNotifications() {
    final FlutterLocalNotificationsPlugin _notificationsPlugin =
        FlutterLocalNotificationsPlugin();
    var initializationSettings = const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'));

    _notificationsPlugin.initialize(initializationSettings,
        onSelectNotification: (payload) async {
      final Map<String, dynamic> payLoadMap = json.decode(payload);

      if (payLoadMap["typ"] == "chat") changeToChat(payLoadMap["link"]);
      if (payLoadMap["typ"] == "event") changeToEvent(payLoadMap["link"]);
      if (payLoadMap["typ"] == "newFriend") changeToProfil(payLoadMap["link"]);
    });

    FirebaseMessaging.instance.getInitialMessage().then((value) {
      if (value != null) {
        var notificationTyp = json.decode(value.data.values.last)["typ"];
        var pageId = json.decode(value.data.values.last)["link"];

        if (notificationTyp == "chat") changeToChat(pageId);
        if (notificationTyp == "event") changeToEvent(pageId);
        if (notificationTyp == "newFriend") changeToProfil(pageId);
      }
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      if (message.data.isNotEmpty) {
        LocalNotificationService().display(message);
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
      var notificationTyp = json.decode(message.data.values.last)["typ"];
      var pageId = json.decode(message.data.values.last)["link"];
      if (pageContext != null) {
        if (notificationTyp == "chat") changeToChat(pageId);
        if (notificationTyp == "chat") changeToEvent(pageId);
        if (notificationTyp == "newFriend") changeToProfil(pageId);
      }
    });
  }

  changeToChat(chatId) async {
    var groupChatData =
        await ChatDatabase().getChatData("*", "WHERE id = '$chatId'");

    navigatorKey.currentState?.push(MaterialPageRoute(
        builder: (_) => ChatDetailsPage(groupChatData: groupChatData)));
  }

  changeToEvent(eventId) async {
    var eventData = await EventDatabase().getData("*", "WHERE id = '$eventId'");

    navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (_) => EventDetailsPage(event: eventData)));
  }

  changeToProfil(profilId) async {
    var profilData =
        await ProfilDatabase().getData("*", "WHERE id = '$profilId'");
    var ownName = FirebaseAuth.instance.currentUser.displayName;

    navigatorKey.currentState?.push(MaterialPageRoute(
        builder: (_) => ShowProfilPage(
              userName: ownName,
              profil: profilData,
            )));
  }

  @override
  Widget build(BuildContext context) {
    pageContext = context;

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.black,
    ));

    return FutureBuilder(
        future: initialization(),
        builder: (context, snapshot) {
          print(Hive.box('secureBox').get("ownProfil") == false);
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          return MaterialApp(
              title: "families worldwide",
              theme: ThemeData(
                  scaffoldBackgroundColor: Colors.white,
                  colorScheme: ColorScheme.fromSwatch().copyWith(
                    primary: const Color(0xFFBF1D53),
                    secondary: const Color(0xFF3CB28F),
                    //buttonColor?
                  ),
                  iconTheme: const IconThemeData(color: Color(0xFF3CB28F))),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: const [
                Locale('en', ''),
                Locale('de', ''),
              ],
              navigatorKey: navigatorKey,
              debugShowCheckedModeBanner: false,
              home: emailVerified ? StartPage() : const LoginPage()
          );
        });
  }
}
