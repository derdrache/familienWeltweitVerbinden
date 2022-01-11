import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'firebase_options.dart';
// wechsel für live
import 'pages/login_register_page/login_page.dart';
import 'pages/start_page.dart';


void main()async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final Future<FirebaseApp> _initialization = Firebase.initializeApp();

  @override
  Widget build(BuildContext context) {
    const pageMainColor = Colors.grey;

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.black,
    ));

    return FutureBuilder(
      future: _initialization,
        builder: (context, snapshot){
          if(snapshot.hasError){
            print("something went wrong");
          }
          if(snapshot.connectionState == ConnectionState.waiting){
            return Center(child: CircularProgressIndicator());
          }
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              scaffoldBackgroundColor: pageMainColor,
            ),
            home: StartPage()//LoginPage()
          );
        }
    );
  }
}
