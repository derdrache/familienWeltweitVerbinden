import 'package:familien_suche/pages/start_page.dart';
import 'package:familien_suche/services/local_notification.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'firebase_options.dart';

import 'pages/login_register_page/login_page.dart';

var appIcon = '@mipmap/ic_launcher';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {

}


void main()async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );


  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);


  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  var pageMainColor = Colors.white;
  var userLogedIn = FirebaseAuth.instance.currentUser;

  initialization() async {
    LocalNotificationService.initialize();

    ///if the App is closed
    FirebaseMessaging.instance.getInitialMessage().then((value){
      if(value != null){

      }
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print(message.notification!.title);
      print(message.data.values);

      LocalNotificationService().display(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message){
      print("test");
    });

  }



  @override
  Widget build(BuildContext context) {


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


