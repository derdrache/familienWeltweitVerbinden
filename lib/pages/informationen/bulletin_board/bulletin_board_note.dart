import 'package:familien_suche/global/global_functions.dart';
import 'package:flutter/material.dart';
import 'dart:math';

import 'bulletin_board_details.dart';

class BulletinBoardCard extends StatefulWidget {
  const BulletinBoardCard({Key? key});

  @override
  State<BulletinBoardCard> createState() => _BulletinBoardCardState();
}

class _BulletinBoardCardState extends State<BulletinBoardCard> {
  String noteLocation = "Puerto Morelosss";
  String noteCountry = "Mexico";

  double getRandomRange() {
    Random random = new Random();
    int randomNumber = random.nextInt(11);
    int changedNumber = 0;

    if(randomNumber < 5){
      changedNumber = randomNumber * -1;
    }else{
      changedNumber =  randomNumber - 5;
    }

    return changedNumber / 100;
  }

  getNoteTitle(){
    String noteTitle = "Bücher zu verschenken";

    if(noteTitle.length > 30){
      return "${noteTitle.substring(0,28)}...";
    }else{
      return noteTitle;
    }
  }

  getStringSized(str){
    if(str.length > 14){
      return "${str.substring(0,12)}...";
    }else{
      return str;
    }
  }

  @override
  Widget build(BuildContext context) {

    return InkWell(
      onTap: () => changePage(context, BulletinBoardDetails()),
      child: Container(
        margin: EdgeInsets.all(10),
        padding: EdgeInsets.all(5),
        width: 110,
        height: 120,
        transform: Matrix4.rotationZ(getRandomRange()),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          color: Colors.yellow[200],
          border: Border.all(),
        ),
        child: Center(child: Column(
          children: [
            Text(getNoteTitle(), textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold),),
            SizedBox(height: 5,),
            Text("Location:"),
            Text(getStringSized(noteLocation)),
            Text(getStringSized(noteCountry))
          ],
        )),
      ),
    );
  }
}
