import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'firebase_options.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'pages/chat/chat_details.dart';
import 'pages/start_page.dart';
import 'services/database.dart';
import 'services/local_notification.dart';
import 'pages/login_register_page/create_profil_page.dart';
import 'pages/events/event_details.dart';
import 'auth/secrets.dart';


import 'pages/login_register_page/login_page.dart';

var appIcon = '@mipmap/ic_launcher';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}

hiveInit() async {
  await Hive.initFlutter();

  await Hive.openBox("countryGeodataBox", encryptionCipher: HiveAesCipher(boxEncrpytionKey));
  var countryJsonText =
      await rootBundle.loadString('assets/countryGeodata.json');
  var geodata = json.decode(countryJsonText)["data"];
  Hive.box('countryGeodataBox').put("list", geodata);

  await Hive.openBox("kontinentGeodataBox", encryptionCipher: HiveAesCipher(boxEncrpytionKey));
  var continentsJsonText =
      await rootBundle.loadString('assets/continentsGeodata.json');
  var continentsGeodata = json.decode(continentsJsonText)["data"];
  Hive.box('kontinentGeodataBox').put("list", continentsGeodata);

  await Hive.openBox('profilBox', encryptionCipher: HiveAesCipher(boxEncrpytionKey));

  await Hive.openBox('ownProfilBox');

  await Hive.openBox('eventBox', encryptionCipher: HiveAesCipher(boxEncrpytionKey));

  await Hive.openBox('myEventsBox');

  await Hive.openBox('interestEventsBox');

  await Hive.openBox('myChatBox');

  await Hive.openBox('stadtinfoUserBox', encryptionCipher: HiveAesCipher(boxEncrpytionKey));
  var stadtinfoUserBox = Hive.box("stadtinfoUserBox");
  if(stadtinfoUserBox.get("list") == null){
    var stadtinfoUser = await StadtinfoUserDatabase()
        .getData("*", "", returnList: true);
    Hive.box("stadtinfoUserBox").put("list",stadtinfoUser);
  }

  await Hive.openBox('stadtinfoBox', encryptionCipher: HiveAesCipher(boxEncrpytionKey));
  var stadtinfo =
    await StadtinfoDatabase().getData("*", "ORDER BY ort ASC", returnList: true);
  Hive.box("stadtinfoBox").put("list", stadtinfo);

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

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  var userId = FirebaseAuth.instance.currentUser?.uid;
  var profilExist;
  var pageContext;
  dynamic importantUpdateNumber = 0;
  dynamic buildNumber = 0;
  var spracheIstDeutsch = kIsWeb
      ? window.locale.languageCode == "de"
      : Platform.localeName == "de_DE";

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  initialization() async {
    await setUserIdAndCheckProfil();

    if (kIsWeb) return;

    await setUpdateInformation();
    setFirebaseNotifications();

  }

  setUserIdAndCheckProfil() async{
    if (userId == null) {
      await FirebaseAuth.instance.authStateChanges().first;
      userId = FirebaseAuth.instance.currentUser.uid;
    }

    profilExist =
        await ProfilDatabase().getData("name", "WHERE id = '$userId'");
  }

  setUpdateInformation() async {
    importantUpdateNumber =
    await AllgemeinDatabase().getData("importantUpdate", "");
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    buildNumber = int.parse(packageInfo.buildNumber);
  }

  setFirebaseNotifications(){
    final FlutterLocalNotificationsPlugin _notificationsPlugin =
    FlutterLocalNotificationsPlugin();
    var initializationSettings = const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'));


    _notificationsPlugin.initialize(initializationSettings,
        onSelectNotification: (payload) async {
          final Map<String, dynamic> payLoadMap = json.decode(payload);

          if (payLoadMap["typ"] == "chat") changeToChat(payLoadMap["link"]);
          if (payLoadMap["typ"] == "event") changeToEvent(payLoadMap["link"]);
        });

    FirebaseMessaging.instance.getInitialMessage().then((value) {
      if (value != null) {
        var notificationTyp = json.decode(value.data.values.last)["typ"];
        var pageId = json.decode(value.data.values.last)["link"];

        if (notificationTyp == "chat") changeToChat(pageId);
        if (notificationTyp == "event") changeToEvent(pageId);
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

  @override
  Widget build(BuildContext context) {
    pageContext = context;

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.black,
    ));

    importantUpdateScreen() {
      return Container(
        margin: const EdgeInsets.all(20),
        child: Center(
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(
            spracheIstDeutsch
                ? "Families worldwide hat ein großes Update bekommen"
                : "Families worldwide has received a major update",
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(height: 30),
          Text(
            spracheIstDeutsch
                ? "Bitte im Playstore die neuste Version runterladen. "
                  "\n\nDa es sich um eine Beta Version handelt, muss das Update "
                  "manuell über den PlayStore installiert werden"
                : "Please download the latest version from the Playstore. "
                  "\n\nSince this is a beta version, the update must be "
                  "installed manually via the PlayStore.",
            style: const TextStyle(fontSize: 16),
          ),
        ])),
      );
    }

    return FutureBuilder(
        future: initialization(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (buildNumber < importantUpdateNumber) {
            InAppUpdate.performImmediateUpdate();
            return MaterialApp(
              home: Scaffold(body: importantUpdateScreen()),
            );
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
                  iconTheme: const IconThemeData(color: Color(0xFF3CB28F))
              ),

              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: const [
                Locale('en', ''),
                Locale('de', ''),
              ],
              navigatorKey: navigatorKey,
              debugShowCheckedModeBanner: false,
              home: userId == null
                  ? const LoginPage()
                  : profilExist == false
                      ? const CreateProfilPage()
                      : StartPage()
          );


        });
  }
}
