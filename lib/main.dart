import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:familien_suche/pages/login_register_page/create_profil_page.dart';
import 'package:familien_suche/pages/events/event_details.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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

hiveInit() async {
  await Hive.initFlutter();

  const secureStorage = FlutterSecureStorage();
  final encryprionKey = await secureStorage.read(key: 'key');

  if (encryprionKey == null) {
    final key = Hive.generateSecureKey();
    await secureStorage.write(
      key: 'key',
      value: base64UrlEncode(key),
    );
  }

  final key = await secureStorage.read(key: 'key');
  final encryptionKey = base64Url.decode(key);


  await Hive.openBox(
    'profilBox',
    encryptionCipher: HiveAesCipher(encryptionKey),
  );

  await Hive.openBox(
    'eventBox',
    encryptionCipher: HiveAesCipher(encryptionKey),
  );

  await Hive.openBox(
    'ownProfilBox',
    encryptionCipher: HiveAesCipher(encryptionKey),
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

  await hiveInit();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  var userId = FirebaseAuth.instance.currentUser?.uid;
  var profilExist;
  var pageContext;
  dynamic importantUpdateNumber = 0;
  dynamic buildNumber = 0;
  var spracheIstDeutsch = kIsWeb ? window.locale.languageCode == "de" : Platform.localeName == "de_DE";

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  initialization() async {

    if(userId == null){
      await FirebaseAuth.instance.authStateChanges().first;
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
      var messagePageId = json.decode(message.data.values.last)["link"];

      if(pageContext != null){
        changeToChat(messagePageId);
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
    var eventData = await EventDatabase().getData("*", "WHERE id = '${eventId}");

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

    importantUpdateScreen(){
      return Container(
        margin: const EdgeInsets.all(20),
        child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(spracheIstDeutsch ? "Families worldwide hat ein großes Update bekommen":
                "Families worldwide has received a major update",
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(height: 30),
                Text(spracheIstDeutsch ?
                "Bitte im Playstore die neuste Version runterladen. \n\nDa es sich um eine Beta Version handelt, muss das Update manuell über den PlayStore installiert werden":
                "Please download the latest version from the Playstore. \n\nSince this is a beta version, the update must be installed manually via the PlayStore.",
                style: const TextStyle(fontSize: 16),
                ),
              ]
            )
        ),
      );
    }

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
            return MaterialApp(
              home: Scaffold(
                body: importantUpdateScreen()
              ),
            );
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
            home: userId == null ? const LoginPage() :
            profilExist == false ? const CreateProfilPage() : StartPage()

          );
        }
    );
  }


}


