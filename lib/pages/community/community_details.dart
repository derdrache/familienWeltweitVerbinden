import 'package:familien_suche/widgets/custom_appbar.dart';
import 'package:flutter/material.dart';

class CommunityDetails extends StatelessWidget {
  var community;

  CommunityDetails({Key key, this.community}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;

    communityImage(){
      return Image.asset(community["bild"], height: screenHeight /3, fit: BoxFit.fitWidth);
    }

    communityInformation(){
      return Container(
        margin: EdgeInsets.all(10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Text(community["name"], style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),)),
          SizedBox(height: 15),
          Row(children: [
            Text("Ort: ", style: TextStyle(fontWeight: FontWeight.bold)),
            Text(community["ort"] + " / " + community["land"])
          ],),
          SizedBox(height: 5),
          Row(children: [
            Text("Link: ", style: TextStyle(fontWeight: FontWeight.bold),),
            Text(community["link"])
          ],),
          SizedBox(height: 15),
          Text(community["beschreibung"])
        ],),
      );
    }

    return Scaffold(
      appBar: CustomAppBar(title: community["name"],),
      body: ListView(padding: EdgeInsets.zero, children: [
        communityImage(),
        communityInformation(),
        // Name in Bild oder Appbar?
        // kurze Information + Beschreibung
        // Später Erweitern
      ],)
    );
  }
}
