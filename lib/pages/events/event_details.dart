import 'package:familien_suche/global/custom_widgets.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../services/database.dart';

var userId = FirebaseAuth.instance.currentUser.uid;

class EventDetailsPage extends StatelessWidget {
  var event;
  double fontsize = 16;


  EventDetailsPage({Key key, this.event}) : super(key: key);


  @override
  Widget build(BuildContext context) {

    bildAndTitleBox(){
      return Stack(
        clipBehavior: Clip.none,
        children: [
          Stack(
            children: [
              Image.asset(event["bild"]),
              Positioned(
                top: 5,
                right: 8,
                child: InteresseButton(
                  interesse: event["interesse"],
                  id: event["id"],
                )
              )
            ],
          ),
          Positioned.fill(
              bottom: -10,
              child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                      padding: EdgeInsets.only(top:10, bottom: 10),
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(20)),
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.5),
                              spreadRadius: 5,
                              blurRadius: 7,
                              offset: Offset(0, 3), // changes position of shadow
                            ),
                          ]
                      ),
                      margin: EdgeInsets.only(left: 30, right: 30),
                      width: 800,
                      child: Text(
                        event["name"],
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      )
                  )
              )
          )
        ],
      );
    }

    eventInformationBox(){
      return Container(
        margin: EdgeInsets.all(10),
        child: ListView(
          shrinkWrap: true,
          children: [
            SizedBox(height: 20),
            Row(
              children: [
                Text("Datum: ", style: TextStyle(fontSize: fontsize, fontWeight: FontWeight.bold)),
                Expanded(child: SizedBox.shrink()),
                Text(
                    event["wann"].split(" ")[0].split("-").reversed.join("-"),
                    style: TextStyle(fontSize: fontsize)
                )
              ],
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Text("Uhrzeit: ", style: TextStyle(fontSize: fontsize, fontWeight: FontWeight.bold)),
                Expanded(child: SizedBox.shrink()),
                Text(
                    event["wann"].split(" ")[1].split(":").take(2).join(":") + "Uhr",
                    style: TextStyle(fontSize: fontsize)
                )
              ],
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Text("Ort: ", style: TextStyle(fontSize: fontsize, fontWeight: FontWeight.bold)),
                Expanded(child: SizedBox.shrink()),
                Text(event["stadt"] + ", " + event["land"], style: TextStyle(fontSize: fontsize))
              ],
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Text("Map: ", style: TextStyle(fontSize: fontsize, fontWeight: FontWeight.bold)),
                Expanded(child: SizedBox.shrink()),
                Text(event["link"], style: TextStyle(fontSize: fontsize))
              ],
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Text("Art: ", style: TextStyle(fontSize: fontsize, fontWeight: FontWeight.bold)),
                Expanded(child: SizedBox.shrink()),
                Text(event["art"], style: TextStyle(fontSize: fontsize))
              ],
            ),
            SizedBox(height: 15),
            Center(child: Text(event["beschreibung"], style: TextStyle(fontSize: fontsize)))
          ],
        ),
      );
    }


    return Scaffold(
      appBar: customAppBar(
        title: ""
      ),
      body: Container(
        child: Column(
          children: [
            bildAndTitleBox(),
            eventInformationBox()
          ],
        )
      ),
    );
  }
}

class InteresseButton extends StatefulWidget {
  var interesse;
  var id;

  InteresseButton({Key key, this.interesse, this.id}) : super(key: key);

  @override
  _InteresseButtonState createState() => _InteresseButtonState();
}

class _InteresseButtonState extends State<InteresseButton> {
  var color = Colors.black;
  var hasIntereset = false;

  @override
  void initState() {
    hasIntereset = widget.interesse.contains(userId);

    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: (){
          hasIntereset = hasIntereset ? false : true;

          if(hasIntereset){
            widget.interesse.add(userId);
          } else{
            widget.interesse.remove(userId);
          }

          EventDatabase().updateOne(widget.id, "interesse", widget.interesse);

          setState(() {

          });
        },
        child: Icon(Icons.favorite, color: hasIntereset ? Colors.red : Colors.black, size: 30,)
    );
  }
}

