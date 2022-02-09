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
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'pages/login_register_page/login_page.dart';
import 'global/global_functions.dart' as global_functions;

var appIcon = '@mipmap/ic_launcher';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {

}


void main()async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );


  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);


  runApp(MyApp());
}



class MyApp extends StatelessWidget {
  var pageMainColor = Colors.white;
  var userLogedIn = FirebaseAuth.instance.currentUser;
  var userId = FirebaseAuth.instance.currentUser!.uid;
  var pageContext;

  initialization() async {
    LocalNotificationService.initialize();
    var notificationBox = await Hive.openBox('notificationBox');

    ///if the App is closed
    FirebaseMessaging.instance.getInitialMessage().then((value){
      if(value != null){

      }
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async{
      if(message.data.isNotEmpty){
        var chatId = message.data["chatId"];
        var activeChat = await ProfilDatabaseKontroller().getActiveChat(userId);

        if(activeChat == null || activeChat != message.data["chatId"]){
          notificationToDatabase(chatId);
          LocalNotificationService().display(message);
        }
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async{
      var chatId = message.data["chatId"];

      if(pageContext != null){
        var groupChatData = await ChatDatabaseKontroller().getChat(chatId);

        global_functions.changePageForever(pageContext, ChatDetailsPage(
            groupChatData: groupChatData)
        );
      }

    });

  }

  notificationToDatabase(chatId) async {
    var newMessages = await ProfilDatabaseKontroller().getNewMessages(userId);
    print(newMessages);
    if(newMessages == null) newMessages = 0;

    ProfilDatabaseKontroller().updateProfil(
        userId,
        {"newMessages": newMessages +1}
    );

    var newChatMessages = await ChatDatabaseKontroller().getNewMessagesCounter(chatId, userId);

    ChatDatabaseKontroller().updateNewMessageCounter(
        chatId,
        userId,
        newChatMessages + 1
    );
  }

  @override
  Widget build(BuildContext context) {
    pageContext = context;

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.black,
    ));

    return FutureBuilder(
      future: initialization(),
        builder: (context, snapshot){
          if(snapshot.hasError){
            print("something went wrong");
          }
          if(snapshot.connectionState == ConnectionState.waiting){
            return Center(child: CircularProgressIndicator());
          }
          return MaterialApp(
              theme: ThemeData(
                scaffoldBackgroundColor: pageMainColor,
              ),
            debugShowCheckedModeBanner: false,
            home: userLogedIn != null ? StartPage() :LoginPage()
          );
        }
    );
  }


}


