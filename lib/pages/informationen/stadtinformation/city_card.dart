import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../global/global_functions.dart';
import '../../../services/database.dart';
import 'stadtinformation.dart';

class CityCard extends StatefulWidget {
  Map city;

  CityCard({Key key, this.city}) : super(key: key);

  @override
  State<CityCard> createState() => _CityCardState();
}

class _CityCardState extends State<CityCard> {
  final String userId = FirebaseAuth.instance.currentUser.uid;
  bool hasInterest;


  @override
  void initState() {
    hasInterest = widget.city["interesse"].contains(userId);

    super.initState();
  }

  changeIntereset(){
    if(hasInterest){
      hasInterest = false;

      widget.city["interesse"].remove(userId);
      StadtinfoDatabase().update(
          "interesse = JSON_REMOVE(interesse, JSON_UNQUOTE(JSON_SEARCH(interesse, 'one', '$userId')))",
          "WHERE id = '${widget.city["id"]}"
      );
    }else{
      hasInterest = true;

      widget.city["interesse"].add(userId);
      StadtinfoDatabase().update(
          "interesse = JSON_ARRAY_APPEND(interesse, '\$', '$userId')",
          "WHERE id = '${widget.city["id"]}"
      );
    }



    setState(() {

    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => changePage(
          context,
          StadtinformationsPage(
            ortName: widget.city["ort"],
          )),
      child: Container(
        margin: const EdgeInsets.all(15),
        child: Stack(
          children: [
            Card(
              elevation: 5,
              shadowColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15.0),
              ),
              child: Container(
                  width: 150,
                  height: 200,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15.0),
                      image: DecorationImage(
                          fit: BoxFit.fitHeight,
                          colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.7), BlendMode.dstATop),
                          image: const AssetImage("assets/bilder/city.jpg"))),
                  child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        child: Text(
                          widget.city["ort"],
                          style:
                          const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                      ))),
            ),
            Positioned(
                right: 0,
                child: IconButton(
                  onPressed: () => changeIntereset(),
                  icon: Icon(Icons.star, color: hasInterest ? Colors.yellow.shade900 : Colors.black,),
                )
            )
          ],
        ),
      ),
    );
  }
}
