import 'package:flutter/foundation.dart' show kIsWeb;

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


  if(!kIsWeb) FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);


  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  var userLogedIn = FirebaseAuth.instance.currentUser;
  var userId = FirebaseAuth.instance.currentUser?.uid;
  var pageContext;
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  initialization() async {
    if(kIsWeb) return ;
      print("wrong");
    final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
    var initializationSettings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher')
    );

    _notificationsPlugin.initialize(
        initializationSettings,
        onSelectNotification: (payload) async => changeToChat(payload)
    );


    FirebaseMessaging.instance.getInitialMessage().then((value){
      if(value != null){
        print("Seitenwechsel getInitalMessage");
      }
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async{
      if(message.data.isNotEmpty){
        var activeChat = await ProfilDatabase().getActiveChat(userId);

        if(activeChat == null || activeChat != message.data["chatId"]){
          LocalNotificationService().display(message);
        }
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async{
      var chatId = message.data["chatId"];

      if(pageContext != null){
        changeToChat(chatId);
      }
    });


  }



  changeToChat(chatId)async {
    var groupChatData = await ChatDatabase().getChat(chatId);

    navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (_) => ChatDetailsPage(
            groupChatData: groupChatData))
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
          return MaterialApp(
            theme: ThemeData(
              scaffoldBackgroundColor: Colors.white,
              colorScheme: ColorScheme.fromSwatch().copyWith(
                primary: Color(0xFFBF1D53),
                secondary: Color(0xFFBF1D53), //buttonColor?
                tertiary: Color(0xFF3CB28F)
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
            home: userLogedIn != null ? StartPage() :const LoginPage()
          );
        }
    );
  }


}


