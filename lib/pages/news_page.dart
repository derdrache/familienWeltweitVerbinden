import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hive/hive.dart';

import '../global/variablen.dart' as global_var;
import '../services/database.dart';

class NewsPage extends StatefulWidget{
  const NewsPage({Key key}) : super(key: key);

  _NewsPageState createState() => _NewsPageState();
}

class _NewsPageState extends State<NewsPage>{
  var newsFeedData = Hive.box('secureBox').get("newsFeed");
  List<Widget> newsFeed = [];

  @override
  void initState() {
    refreshNewsFeed();
    createNewsFeed();

    super.initState();
  }

  refreshNewsFeed() async {
    List<dynamic> dbNewsData =
        await NewsFeedDatabase().getData("*", "ORDER BY date ASC");
    if (dbNewsData == false) dbNewsData = [];

    Hive.box('secureBox').put("newsFeed", dbNewsData);
  }

  createNewsFeed(){

  }

  Widget build(BuildContext context){

    iconBox(icon){
      return Container(
        margin: const EdgeInsets.all(15),
        height: 25,
        width: 50,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: const BorderRadius.all(Radius.circular(10))

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

    headBox(){
      return Container(
        padding: EdgeInsets.all(10),
        child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: null,
          )
        ],),
      );
    }

    newsFeedBox(){
      return Container(

        child: ListView(
          shrinkWrap: true,
          children: newsFeed,
        )
      );
    }

    return Scaffold(
      body: Container(
        padding: const EdgeInsets.only(top: kIsWeb? 0: 24),
        child: Column(
          children: [
            headBox(),
            newsFeedBox()
          ],
        ),
      )
    );

  }
}
