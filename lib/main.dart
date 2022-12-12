import 'dart:convert';

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
import 'pages/informationen/events/event_details.dart';
import 'pages/login_register_page/login_page.dart';
import 'services/database.dart';
import 'services/local_notification.dart';
import 'auth/secrets.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("test");
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}

hiveInit() async {
  await Hive.initFlutter();

  await Hive.openBox("secureBox",
      encryptionCipher: HiveAesCipher(boxEncrpytionKey), crashRecovery: false);
}

setGeoData() async{
  var countryJsonText =
  await rootBundle.loadString('assets/countryGeodata.json');
  var geodata = json.decode(countryJsonText)["data"];
  Hive.box('secureBox').put("countryGeodata", geodata);

  var continentsJsonText =
  await rootBundle.loadString('assets/continentsGeodata.json');
  var continentsGeodata = json.decode(continentsJsonText)["data"];
  Hive.box('secureBox').put("kontinentGeodata", continentsGeodata);
}

refreshHiveData() async {
  String userId = FirebaseAuth.instance.currentUser?.uid;

  await refreshHiveNewsPage();
  await refreshHiveCommunities();
  await refreshHiveStadtInfo();
  await refreshHiveStadtInfoUser();
  await refreshHiveFamilyProfils();

  if(userId == null) return;

  await refreshHiveProfils();
  await refreshHiveChats();
  await refreshHiveEvents();
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
  await setGeoData();

  refreshHiveData();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  String userId = FirebaseAuth.instance.currentUser?.uid;
  BuildContext pageContext;

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  MyApp({Key key}) : super(key: key);

  _initialization() async {
    if (userId == null) {
      await FirebaseAuth.instance.authStateChanges().first;
      userId = FirebaseAuth.instance.currentUser.uid;
    }

    if (kIsWeb) return;

    _setFirebaseNotifications();
  }

  notificationLeadPage(notification) {
    if (notification["typ"] == "chat") {
      _changeToChat(notification["link"]);
    }
    if (notification["typ"] == "event") _changeToEvent(notification["link"]);
    if (notification["typ"] == "newFriend") {
      _changeToProfil(notification["link"]);
    }
  }

  _setFirebaseNotifications() {
    final FlutterLocalNotificationsPlugin _notificationsPlugin =
        FlutterLocalNotificationsPlugin();
    var initializationSettings = const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: IOSInitializationSettings()
    );

    _notificationsPlugin.initialize(initializationSettings,
        onSelectNotification: (payload) async {
      final Map<String, dynamic> payLoadMap = json.decode(payload);

      notificationLeadPage(payLoadMap);
    });

    FirebaseMessaging.instance.getInitialMessage().then((value) {
      if (value != null) {
        var notification = json.decode(value.data.values.last);
        notificationLeadPage(notification);
      }
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      if (message.data.isNotEmpty) {
        var messageData = json.decode(message.data["info"]);

        if (messageData["typ"] == "chat") {
          var chatId = messageData["link"];
          var chatData = getChatFromHive(chatId);

          if (chatData["users"][userId]["mute"] == true ||
              chatData["users"][userId]["mute"] == "true") {
            return;
          }
        }

        LocalNotificationService().display(message);
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
      var notification = json.decode(message.data.values.last);
      if (pageContext != null) {
        notificationLeadPage(notification);
      }
    });
  }

  _changeToChat(chatId) async {
    var groupChatData = getChatFromHive(chatId);

    navigatorKey.currentState?.push(MaterialPageRoute(
        builder: (_) => ChatDetailsPage(
            groupChatData: groupChatData,
        )));
  }

  _changeToEvent(eventId) async {
    var eventData = getEventFromHive(eventId);

    navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (_) => EventDetailsPage(event: eventData)));
  }

  _changeToProfil(profilId) async {
    var profilData = getProfilFromHive(profilId: profilId);

    navigatorKey.currentState?.push(MaterialPageRoute(
        builder: (_) => ShowProfilPage(
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
        future: _initialization(),
        builder: (context, snapshot) {
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
                  ),
                  iconTheme: const IconThemeData(color: Color(0xAA3CB28F))),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: const [
                Locale('en', ''),
                Locale('de', ''),
              ],
              navigatorKey: navigatorKey,
              debugShowCheckedModeBanner: false,
              home: FirebaseAuth.instance.currentUser != null
                  ? StartPage()
                  : LoginPage());
        });
  }
}
