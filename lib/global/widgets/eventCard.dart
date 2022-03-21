import 'package:familien_suche/services/database.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../pages/events/event_details.dart';
import '../global_functions.dart' as global_functions;

var userId = FirebaseAuth.instance.currentUser.uid;

class EventCard extends StatelessWidget {
  var margin;
  var event;
  var withInteresse;

  EventCard({
    Key key,
    this.event,
    this.withInteresse = false,
    this.margin = const EdgeInsets.only(top:10, bottom: 10, right: 10, left: 10)
  });

  @override
  Widget build(BuildContext context) {
    event["bild"] ??= "assets/bilder/strand.jpg";

    double screenHeight = MediaQuery.of(context).size.height; //laptop: 619 -  Android 737
    var fontSize = screenHeight / 52; //Android 14   51,58  => 52,6


    return GestureDetector(
      onTap: () => global_functions.changePage(context, EventDetailsPage(
        event: event,
      )),
      child: Container(
          width: 130 + ((screenHeight-600)/5), //  Android 165
          height: screenHeight / 3.4, // Android 220 ~3,4
          margin: margin,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
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
          child: Column(
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: new BorderRadius.only(
                      topLeft: const Radius.circular(20.0),
                      topRight: const Radius.circular(20.0),
                    ),
                    child: Image.asset(
                        event["bild"],
                        height: 70 + ((screenHeight-600)/5),
                        width: 130 + ((screenHeight-600)/5),
                        fit: BoxFit.fill
                    ),
                  ),
                  if(withInteresse) Positioned(
                    top: 2,
                    right: 8,
                    child: InteresseButton(
                        interesse: event["interesse"],
                        id: event["id"],
                    )
                  )
                ],
              ),
              Expanded(
                child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.only(top: 10, left: 5),
                    decoration: BoxDecoration(
                      borderRadius: new BorderRadius.only(
                        bottomLeft: const Radius.circular(20.0),
                        bottomRight: const Radius.circular(20.0),
                      ),
                      color: Colors.white,
                    ),
                    child: Column(
                      children: [
                        Text(event["name"], style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize),),
                        SizedBox(height: 10),
                        Row(
                          children: [
                            Text("Date: ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize)),
                            Text(
                                event["wann"].split(" ")[0].split("-").reversed.join("."),
                                style: TextStyle(fontSize: fontSize))
                          ],
                        ),
                        SizedBox(height: 5),
                        Row(
                          children: [
                            Text("Stadt: ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize)),
                            Text(event["stadt"], style: TextStyle(fontSize: fontSize))
                          ],
                        ),
                        SizedBox(height: 5),
                        Row(
                          children: [
                            Text("Land: ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize)),
                            Text(event["land"], style: TextStyle(fontSize: fontSize))
                          ],
                        ),
                      ],
                    )
                ),
              )
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
      child: Icon(Icons.favorite, color: hasIntereset ? Colors.red : Colors.black)
    );
  }
}
