import 'package:flutter/material.dart';


class EventCard extends StatelessWidget {
  var title;
  var bild;
  var date;
  var stadt;
  var land;
  var margin;

  EventCard({
    Key key,
    this.title,
    this.bild,
    this.date,
    this.stadt,
    this.land,
    this.margin = const EdgeInsets.only(top:10, bottom: 10, right: 10, left: 10)});

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height; //laptop: 619 -  Android 737
    var fontSize = screenHeight / 52; //Android 14   51,58  => 52,6

    return Container(
        width: 130 + ((screenHeight-600)/5), //  Android 165
        height: screenHeight / 3.4, // Android 220 ~3,4
        margin: margin,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
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
            ClipRRect(
              borderRadius: new BorderRadius.only(
                topLeft: const Radius.circular(20.0),
                topRight: const Radius.circular(20.0),
              ),
              child: Image.asset(bild),
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
                      Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize),),
                      SizedBox(height: 10),
                      Row(
                        children: [
                          Text("Date: ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize)),
                          Text(date , style: TextStyle(fontSize: fontSize))
                        ],
                      ),
                      SizedBox(height: 5),
                      Row(
                        children: [
                          Text("Stadt: ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize)),
                          Text(stadt, style: TextStyle(fontSize: fontSize))
                        ],
                      ),
                      SizedBox(height: 5),
                      Row(
                        children: [
                          Text("Land: ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize)),
                          Text(land, style: TextStyle(fontSize: fontSize))
                        ],
                      ),
                    ],
                  )
              ),
            )
          ],
        )
    );
  }
}





/*
class EventCard extends StatelessWidget {
  var title;
  var bild;
  var date;
  var stadt;
  var land;
  var margin;

  EventCard({
    Key key,
    this.title,
    this.bild,
    this.date,
    this.stadt,
    this.land,
    this.margin = const EdgeInsets.only(top:10, bottom: 10, right: 10, left: 10)});

  @override
  Widget build(BuildContext context) {
    return Container(
        width: 165,
        height: 220,
        margin: margin,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
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
            ClipRRect(
              borderRadius: new BorderRadius.only(
                topLeft: const Radius.circular(20.0),
                topRight: const Radius.circular(20.0),
              ),
              child: Image.asset(bild),
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
                      Text(title, style: TextStyle(fontWeight: FontWeight.bold),),
                      SizedBox(height: 10),
                      Row(
                        children: [
                          Text("Date: ", style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(date)
                        ],
                      ),
                      SizedBox(height: 5),
                      Row(
                        children: [
                          Text("Stadt: ", style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(stadt)
                        ],
                      ),
                      SizedBox(height: 5),
                      Row(
                        children: [
                          Text("Land: ", style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(land)
                        ],
                      ),
                    ],
                  )
              ),
            )
          ],
        )
    );
  }
}
*/