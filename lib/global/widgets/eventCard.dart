import 'package:flutter/material.dart';


class EventCard extends StatelessWidget {
  var title;
  var bild;
  var date;
  var stadt;

  EventCard({Key key, this.title, this.bild, this.date, this.stadt});

  @override
  Widget build(BuildContext context) {
    return Container(
        width: 160,
        margin: EdgeInsets.only(top:20, bottom: 20, right: 10, left: 10),
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
            )
            ,
            Expanded(
              child: Container(
                  height: 80,
                  width: double.infinity,
                  padding: EdgeInsets.only(top: 10),
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
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Date: ", style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(date)
                        ],
                      ),
                      SizedBox(height: 5),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Stadt: ", style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(stadt)
                        ],
                      )
                    ],
                  )
              ),
            )
          ],
        )
    );
  }
}
