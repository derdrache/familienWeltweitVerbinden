import 'dart:convert';
import 'dart:io';
import 'dart:math';

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
import 'themes/dark_theme.dart';
import 'themes/light_theme.dart';

refreshDataOnNotification(messageTyp) async{
  Random random = new Random();
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

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  var messageData = json.decode(message.data["info"]);
  refreshDataOnNotification(messageData["typ"]);

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
  String? userId = FirebaseAuth.instance.currentUser?.uid;

  await refreshHiveNewsPage();
  await refreshHiveCommunities();
  await refreshHiveStadtInfo();
  await refreshHiveStadtInfoUser();
  await refreshHiveFamilyProfils();
  await refreshHiveBulletinBoardNotes();

  if(userId == null) return;

  await refreshHiveProfils();
  await refreshHiveChats();
  await refreshHiveMeetups();
}

deleteOldVoiceMessages() async {
  var appDir = await getApplicationDocumentsDirectory();
  var allFiles = Directory(appDir.path).listSync();

  for(var file in allFiles){
    final fileStat = FileStat.statSync(file.path);
    DateTime createdDate = fileStat.modified;
    const oneMotninHours = 720;
    bool tooOld =  DateTime.now().compareTo(createdDate.add(Duration(hours: oneMotninHours))) == 1;
    String fileTyp = file.path.split(".").last;
    bool isMP3 = fileTyp == "mp3";

    if(tooOld && isMP3){
      file.delete();
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  bool isPhone = getDeviceType() == "phone";

  if(isPhone){
    await SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  }else{
    await SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown, DeviceOrientation.landscapeLeft,DeviceOrientation.landscapeRight]);
  }

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

String getDeviceType() {
  final data = MediaQueryData.fromView(WidgetsBinding.instance.window);
  return data.size.shortestSide < 550 ? 'phone' :'tablet';
}

class MyApp extends StatelessWidget {
  String? userId = FirebaseAuth.instance.currentUser?.uid;
  BuildContext? pageContext;

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  _initialization() async {
    if (userId == null) {
      await FirebaseAuth.instance.authStateChanges().first;
      userId = FirebaseAuth.instance.currentUser?.uid;
    }

    if (kIsWeb) return;

    _setFirebaseNotifications();
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

  _setFirebaseNotifications() {
    final FlutterLocalNotificationsPlugin _notificationsPlugin =
        FlutterLocalNotificationsPlugin();
    var initializationSettings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings()
    );

    FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    _notificationsPlugin.initialize(initializationSettings,
        onDidReceiveNotificationResponse: (payload) async {
      final Map<String, dynamic> payLoadMap = json.decode(payload.payload!);
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

        refreshDataOnNotification(messageData["typ"]);

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
              theme: lightTheme,
              darkTheme: darkTheme,
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
