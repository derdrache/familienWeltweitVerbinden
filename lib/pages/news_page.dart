import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../global/variablen.dart' as global_var;
import '../services/database.dart';

class NewsPage extends StatefulWidget{
  const NewsPage({Key key}) : super(key: key);

  _NewsPageState createState() => _NewsPageState();
}

class _NewsPageState extends State<NewsPage>{


  Widget build(BuildContext context){

    iconBox(icon){
      return Container(
        margin: EdgeInsets.all(15),
        height: 25,
        width: 50,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.all(Radius.circular(10))

        ),
        child: Icon(icon, color: Colors.white,size: 24,)
      );
    }

    friendsSliderBox(){
      return Container(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(width: 1, color: global_var.borderColorGrey))
        ),
        width: 600,
        height: 80,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            iconBox(Icons.people),
            iconBox(Icons.people),
            iconBox(Icons.people),
            iconBox(Icons.people),
            iconBox(Icons.people),
            iconBox(Icons.people),
          ],
        ),
      );
    }

    newsFeedBox(){
      return Container(
        child: ListView(
          children: [
            Center(child: Text("test")),
          ],
        )
      );
    }

    return Scaffold(
      body: Container(
        padding: const EdgeInsets.only(top: kIsWeb? 0: 24),
        child: Column(
          children: [
            friendsSliderBox(),
            Expanded(
                child: newsFeedBox()
            )
          ],
        ),
      )
    );

  }
}
