import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:permission_handler/permission_handler.dart';
import 'package:familien_suche/pages/informationen/community/community_details.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:path_provider/path_provider.dart';

import 'firebase_options.dart';
import 'pages/start_page.dart';
import 'pages/show_profil.dart';
import 'pages/chat/chat_details.dart';
import 'pages/informationen/meetups/meetup_details.dart';
import 'pages/login_register_page/login_page.dart';
import 'services/database.dart';
import 'services/local_notification.dart';
import 'auth/secrets.dart';

import 'themes/light_theme.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  if (!kIsWeb) await _notificationSetup();

  await hiveInit();
  await setGeoData();
  await setOrientation();

  refreshHiveData();

  runApp(MyApp());
}

_notificationSetup() async {
    askNotificationPermission();
  final FlutterLocalNotificationsPlugin notificationsPlugin =
    FlutterLocalNotificationsPlugin();
  var initializationSettings = InitializationSettings(
      android: const AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
          notificationCategories: [
            DarwinNotificationCategory(
                "meetupParticipate",
                actions: <DarwinNotificationAction>[
                  DarwinNotificationAction.plain('id_1', 'Action 1'),
                  DarwinNotificationAction.plain('id_2', 'Action 2'),
                ]
            )
          ]
      )
  );

  FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: onSelectNotification,
      onDidReceiveBackgroundNotificationResponse: onSelectNotification);

  FirebaseMessaging.onBackgroundMessage((RemoteMessage message) async {
    var messageData = message.data["info"];
    refreshDataOnNotification(messageData["typ"]);
  });

  FirebaseMessaging.instance.getInitialMessage().then((value) {
    if (value != null) {
      var notification = json.decode(value.data.values.last);
      notificationLeadPage(notification);
    }
  });

  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    String? userId = FirebaseAuth.instance.currentUser?.uid;

    var messageData = message.data;

    bool isMeetupReminder = messageData["typ"] == "event" && (message.notification!.title!.contains("Reminder")
        || message.notification!.title!.contains("Erinnerung"));

    refreshDataOnNotification(messageData["typ"]);

    if (messageData["typ"] == "chat") {
      var chatId = messageData["link"];
      var chatData = getChatFromHive(chatId);

      if (chatData["users"][userId]["mute"] == true ||
          chatData["users"][userId]["mute"] == "true") {
        return;
      }
    }

    LocalNotificationService().display(message, withMeetupAction: isMeetupReminder);
  });

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
    var notification = json.decode(message.data.values.last);
    notificationLeadPage(notification);
  });
}

refreshDataOnNotification(messageTyp) async{
  Random random = Random();
  int randomNumber = random.nextInt(60);
  await Future.delayed(Duration(seconds: randomNumber), (){});
  if (messageTyp == "chat") {
    refreshHiveChats();
  }else if (messageTyp == "event"){
    refreshHiveMeetups();
  }
  else if (messageTyp == "newFriend") {
    refreshHiveProfils();
  }else if(messageTyp == "community"){
    refreshHiveCommunities();
  }
}

@pragma('vm:entry-point')
onSelectNotification(NotificationResponse notificationResponse) async {
  //var payloadData = notificationResponse.payload!;
  var payloadData = jsonDecode(notificationResponse.payload!);
  var actionId = notificationResponse.actionId;

  if(actionId == "id_1"){
    takePartDecision(payloadData["link"],true);
  }else if(actionId == "id_2"){
    takePartDecision(payloadData["link"],false);
  }else{
    notificationLeadPage(payloadData);
  }

}

takePartDecision(meetupId, bool confirm) async {
  await hiveInit();

  String? userId = Hive.box('secureBox').get("ownProfil")["id"];
  Map meetupData = getMeetupFromHive(meetupId);

  if (confirm) {
    if (meetupData["absage"].contains(userId)) {
      MeetupDatabase().update(
          "absage = JSON_REMOVE(absage, JSON_UNQUOTE(JSON_SEARCH(absage, 'one', '$userId'))),zusage = JSON_ARRAY_APPEND(zusage, '\$', '$userId')",
          "WHERE id = '${meetupData["id"]}'");
    } else {
      MeetupDatabase().update(
          "zusage = JSON_ARRAY_APPEND(zusage, '\$', '$userId')",
          "WHERE id = '${meetupData["id"]}'");
    }

    meetupData["zusage"].add(userId);
    meetupData["absage"].remove(userId);
  } else {
    if (meetupData["zusage"].contains(userId)) {
      MeetupDatabase().update(
          "zusage = JSON_REMOVE(zusage, JSON_UNQUOTE(JSON_SEARCH(zusage, 'one', '$userId'))),absage = JSON_ARRAY_APPEND(absage, '\$', '$userId')",
          "WHERE id = '${meetupData["id"]}'");
    } else {
      MeetupDatabase().update(
          "absage = JSON_ARRAY_APPEND(absage, '\$', '$userId')",
          "WHERE id = '${meetupData["id"]}'");
    }

    meetupData["zusage"].remove(userId);
    meetupData["absage"].add(userId);
  }
}

notificationLeadPage(notification) {
  if (notification["typ"] == "chat") {
    _changeToChat(notification["link"]);
  }else if (notification["typ"] == "event"){
    _changeToEvent(notification["link"]);
  }
  else if (notification["typ"] == "newFriend") {
    _changeToProfil(notification["link"]);
  }else if(notification["typ"] == "community"){
    _changeToCommunity(notification["link"]);
  }
}

_changeToChat(chatId) async {
  navigatorKey.currentState?.push(MaterialPageRoute(
      builder: (_) => ChatDetailsPage(
        chatId: chatId.toString(),
      )));
}

_changeToEvent(eventId) async {
  var eventData = getMeetupFromHive(eventId);

  navigatorKey.currentState?.push(
      MaterialPageRoute(builder: (_) => MeetupDetailsPage(meetupData: eventData)));
}

_changeToProfil(profilId) async {
  var profilData = getProfilFromHive(profilId: profilId);

  navigatorKey.currentState?.push(MaterialPageRoute(
      builder: (_) => ShowProfilPage(
        profil: profilData,
      )));
}

_changeToCommunity(communityId) async{
  var communityData = getCommunityFromHive(communityId);

  navigatorKey.currentState?.push(
      MaterialPageRoute(builder: (_) => CommunityDetails(community: communityData,)));
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

setOrientation() async {
  final firstView = WidgetsBinding.instance.platformDispatcher.views.first;
  final logicalShortestSide = firstView.physicalSize.shortestSide / firstView.devicePixelRatio;
  bool isPhone = logicalShortestSide < 600 ? true : false;

  if(isPhone){
    await SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  }else{
    await SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown, DeviceOrientation.landscapeLeft,DeviceOrientation.landscapeRight]);
  }
}

refreshHiveData() async {
  String? userId = FirebaseAuth.instance.currentUser?.uid;

  await refreshHiveCommunities();
  await refreshHiveStadtInfo();
  await refreshHiveStadtInfoUser();
  await refreshHiveFamilyProfils();
  await refreshHiveBulletinBoardNotes();

  if(userId == null) return;

  await refreshHiveChats();
  await refreshHiveMeetups();
}



askNotificationPermission() async{
  await Permission.notification.isDenied.then((value) {
    if (value) {
      Permission.notification.request();
    }
  });
}

//ignore: must_be_immutable
class MyApp extends StatelessWidget {
  String? userId = FirebaseAuth.instance.currentUser?.uid;

  MyApp({super.key});

  initialization() async {
    if (userId == null) {
      await FirebaseAuth.instance.authStateChanges().first;
      userId = FirebaseAuth.instance.currentUser?.uid;
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.black,
    ));

    return FutureBuilder(
        future: initialization(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          return MaterialApp(
              title: "families worldwide",
              theme: lightTheme,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: const [
                Locale('en', ''),
                Locale('de', ''),
              ],
              navigatorKey: navigatorKey,
              debugShowCheckedModeBanner: false,
              home: FirebaseAuth.instance.currentUser != null
                  ? StartPage()
                  : const LoginPage());
        });
  }
}


