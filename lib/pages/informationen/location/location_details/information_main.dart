import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../../../global/global_functions.dart' as global_func;
import '../../../../services/database.dart';
import '../../../../widgets/custom_appbar.dart';
import '../../../../widgets/custom_like_button.dart';
import '../../../../widgets/layout/custom_snackbar.dart';
import '../../../start_page.dart';
import '../weltkarte_mini.dart';
import 'country_cities.dart';
import 'general_information.dart';
import 'insider_information.dart';
import 'location_rating.dart';



class LocationInformationPage extends StatefulWidget {
  final String ortName;
  final double ortLatt;
  final bool fromCityPage;
  int? insiderInfoId = 0;
  final bool isCountry;

  LocationInformationPage(
      {Key? key,
      required this.ortName,
      this.ortLatt = 0.0,
      this.fromCityPage = false,
      this.insiderInfoId,
      this.isCountry = false})
      : super(key: key);

  @override
  State<LocationInformationPage> createState() =>
      _LocationInformationPageState();
}

class _LocationInformationPageState extends State<LocationInformationPage> {
  final String userId = FirebaseAuth.instance.currentUser!.uid;
  late bool isCity;
  late bool hasInterest;
  Map location = {};
  int _selectNavigationIndex = 0;
  late List tabPages;
  late List usersCityInformation;

  @override
  void initState() {
    _selectNavigationIndex = widget.insiderInfoId != null ? 2 : 0;

    location = getCityFromHive(cityName: widget.ortName, latt: widget.ortLatt, isCountry: widget.isCountry);
    usersCityInformation = getCityUserInfoFromHive(widget.ortName);
    isCity = location["isCity"] == 1;
    tabPages = [
      GeneralInformationPage(
        location: location,
        usersCityInformation: usersCityInformation,
        fromCityPage: widget.fromCityPage,
      ),
      LocationRating(location: location),
      InsiderInformationPage(
          location: location, insiderInfoId: widget.insiderInfoId),
      if (isCity) WorldmapMini(location: location),
      if (!isCity) CountryCitiesPage(countryName: widget.ortName)
    ];

    refreshRating();

    super.initState();
  }

  refreshRating() async {
    var locationRatings = await StadtInfoRatingDatabase().getData(
        "*", "where locationId = '${location["id"]}'",
        returnList: true);
    if (locationRatings == false) locationRatings = [];

    location["ratings"] = locationRatings;
  }

  void _onNavigationItemTapped(int index) {
    setState(() {
      _selectNavigationIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    hasInterest = location["interesse"]?.contains(userId) ?? false;

    return SelectionArea(
        child: Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: CustomAppBar(
        title: widget.ortName,
        buttons: [
          if (location["isCity"] == 1)
            IconButton(
              icon: Image.asset(
                "assets/icons/country.png",
                color: Colors.white,
              ),
              tooltip: AppLocalizations.of(context)!.tooltipLandInfoOeffnen,
              onPressed: () async {
                global_func.changePage(context,
                    LocationInformationPage(ortName: location["land"], isCountry: true,));
              },
            ),
          IconButton(
            icon: const Icon(Icons.link),
            tooltip: AppLocalizations.of(context)!.tooltipLinkKopieren,
            onPressed: () async {
              Clipboard.setData(
                  ClipboardData(text: "</cityId=${location["id"]}"));
              customSnackBar(
                  context, AppLocalizations.of(context)!.linkWurdekopiert,
                  color: Colors.green);
              global_func.changePageForever(
                  context,
                  StartPage(
                    selectedIndex: 3,
                  ));
            },
          ),
          CustomLikeButton(
            locationData: location,
          )
        ],
      ),
      body: tabPages.elementAt(_selectNavigationIndex),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Theme.of(context).colorScheme.primary,
        currentIndex: _selectNavigationIndex,
        selectedItemColor: Colors.white,
        onTap: _onNavigationItemTapped,
        items: <BottomNavigationBarItem>[
          const BottomNavigationBarItem(
            icon: Icon(Icons.feed),
            label: 'Information',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.rate_review),
            label: AppLocalizations.of(context)!.locationBewertung,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.tips_and_updates),
            label: AppLocalizations.of(context)!.insiderInformation,
          ),
          if (isCity)
            BottomNavigationBarItem(
              icon: const Icon(Icons.map),
              label: AppLocalizations.of(context)!.karte,
            ),
          if (!isCity)
            BottomNavigationBarItem(
              icon: const Icon(Icons.location_city),
              label: AppLocalizations.of(context)!.cities,
            ),
        ],
      ),
    ));
  }
}








