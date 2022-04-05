import 'dart:convert';
import 'package:familien_suche/pages/landing.dart';
import 'package:familien_suche/pages/login_register_page/create_profil_page.dart';
import 'package:familien_suche/pages/events/event_details.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:in_app_update/in_app_update.dart';


import 'package:familien_suche/pages/chat/chat_details.dart';
import 'package:familien_suche/pages/start_page.dart';
import 'package:familien_suche/services/database.dart';
import 'package:familien_suche/services/local_notification.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'firebase_options.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'pages/login_register_page/login_page.dart';

var appIcon = '@mipmap/ic_launcher';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

}


void main()async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );


  if(!kIsWeb){
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }


  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  var userLogedIn = FirebaseAuth.instance.currentUser;
  var userId = FirebaseAuth.instance.currentUser?.uid;
  var profilExist;
  var pageContext;
  dynamic importantUpdateNumber = 0;
  dynamic buildNumber = 0;

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  initialization() async {

    if(userLogedIn == null){
      await FirebaseAuth.instance.authStateChanges().first;
      userLogedIn = FirebaseAuth.instance.currentUser;
      userId = FirebaseAuth.instance.currentUser.uid;
    }

    profilExist = await ProfilDatabase()
        .getData("name", "WHERE id = '${userId}'");
    if(kIsWeb) return ;


    importantUpdateNumber = await AllgemeinDatabase().getOneData("importantUpdate");
    importantUpdateNumber = int.parse(importantUpdateNumber["importantUpdate"]);
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    buildNumber = int.parse(packageInfo.buildNumber);


    final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
    var initializationSettings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher')
    );
    _notificationsPlugin.initialize(
        initializationSettings,
        onSelectNotification: (payload) async {
          final Map<String, dynamic> payLoadMap = json.decode(payload);

          if(payLoadMap["typ"] == "chat") changeToChat(payLoadMap["link"]);

          if(payLoadMap["typ"] == "event") changeToEvent(payLoadMap["link"]);
          //
        }
    );


    FirebaseMessaging.instance.getInitialMessage().then((value){
      if(value != null){
        var messageChatId = json.decode(value.data.values.last)["link"];
        changeToChat(messageChatId);
      }

    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async{
      if(message.data.isNotEmpty){
        var messageChatId = json.decode(message.data.values.last)["link"];
        var activeChat = await ProfilDatabase()
            .getData("activeChat", "WHERE id = '${userId}'");

        if(activeChat == null || activeChat != messageChatId){
          LocalNotificationService().display(message);
        }
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async{
      var messageChatId = json.decode(message.data.values.last)["link"];

      if(pageContext != null){
        changeToChat(messageChatId);
      }

    });

  }


  changeToChat(chatId)async {
    var groupChatData = await ChatDatabase().getChatData("*", "WHERE id = '$chatId'");

    navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (_) => ChatDetailsPage(
            groupChatData: groupChatData))
    );
  }

  changeToEvent(eventId) async {
    var eventData = await EventDatabase().getEvent(eventId);

    navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (_) => EventDetailsPage(
            event: eventData)
        )
    );
  }

  @override
  Widget build(BuildContext context) {
    pageContext = context;

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.black,
    ));


    return FutureBuilder(
      future: initialization(),
        builder: (context, snapshot){
          if(snapshot.hasError){
            ("something went wrong");
          }
          if(snapshot.connectionState == ConnectionState.waiting){
            return const Center(child: CircularProgressIndicator());
          }
          if(buildNumber < importantUpdateNumber){
            InAppUpdate.performImmediateUpdate();
            return const Center(child: CircularProgressIndicator());
          }
          return MaterialApp(
            title: "families worldwide",
            theme: ThemeData(
              scaffoldBackgroundColor: Colors.white,
              colorScheme: ColorScheme.fromSwatch().copyWith(
                primary: Color(0xFFBF1D53),
                secondary: Color(0xFF3CB28F), //buttonColor?
            ),
              iconTheme: IconThemeData(color: Color(0xFF3CB28F))
            ),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: const [
              Locale('en', ''),
              Locale('de', ''),
            ],
            navigatorKey: navigatorKey,
            debugShowCheckedModeBanner: false,
            home: userLogedIn == null ? const LoginPage() :
            profilExist == false ? const CreateProfilPage() : StartPage()

          );
        }
    );
  }


}


