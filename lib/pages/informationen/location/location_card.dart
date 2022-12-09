import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../global/global_functions.dart';
import '../../../services/database.dart';
import 'city_information.dart';
import 'country_information.dart';

class LocationCard extends StatefulWidget {
  Map location;
  var fromCityPage;

  LocationCard({Key key, this.location, this.fromCityPage = false}) : super(key: key);

  @override
  State<LocationCard> createState() => _LocationCardState();
}

class _LocationCardState extends State<LocationCard> {
  final String userId = FirebaseAuth.instance.currentUser.uid;
  var assetCity = "assets/bilder/city.jpg";
  var assetLand = "assets/bilder/land.jpg";
  bool hasInterest;
  bool isCity;

  @override
  void initState() {
    isCity = widget.location["isCity"] == 1;

    super.initState();
  }

  changeIntereset(){
    if(hasInterest){
      hasInterest = false;

      widget.location["interesse"].remove(userId);
      StadtinfoDatabase().update(
          "interesse = JSON_REMOVE(interesse, JSON_UNQUOTE(JSON_SEARCH(interesse, 'one', '$userId')))",
          "WHERE id = '${widget.location["id"]}"
      );
    }else{
      hasInterest = true;

      widget.location["interesse"].add(userId);
      StadtinfoDatabase().update(
          "interesse = JSON_ARRAY_APPEND(interesse, '\$', '$userId')",
          "WHERE id = '${widget.location["id"]}"
      );
    }



    setState(() {

    });
  }

  @override
  Widget build(BuildContext context) {
    hasInterest = widget.location["interesse"].contains(userId);


    return GestureDetector(
      onTap: () => changePage(
          context,
          isCity
            ? CityInformationPage(
                ortName: widget.location["ort"],
                fromCityPage: widget.fromCityPage
              )
            : CountryOverviewInformationPage(
                ortName: widget.location["ort"],
                fromCityPage: widget.fromCityPage
              )
      ),
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
                          image: AssetImage( isCity ? assetCity : assetLand))),
                  child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        child: Text(
                          widget.location["ort"],
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
