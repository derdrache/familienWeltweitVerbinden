
import 'package:familien_suche/pages/featureOnBoarding/social_media_slider.dart';
import 'package:familien_suche/pages/featureOnBoarding/reiseplanung_slider.dart';
import 'package:familien_suche/pages/featureOnBoarding/support_slider.dart';
import 'package:flutter/material.dart';

import '../../services/database.dart';
import 'profil_image_slider.dart';
import 'standortbestimmung_slider.dart';


class FeatureOnboarding extends StatefulWidget {
  const FeatureOnboarding({super.key});

  @override
  State<FeatureOnboarding> createState() => _FeatureOnboardingState();
}

class _FeatureOnboardingState extends State<FeatureOnboarding> {
  int currentPage = 0;
  final PageController pageController = PageController(initialPage: 0);
  List<String> pageNames = [];
  List<Widget> pages = [];

  @override
  void initState() {
    addPages();
  }

  addPages(){
    var featureOnBoardingData = getHiveFeatureOnBoarding();
    print(featureOnBoardingData);
    if(featureOnBoardingData["profilImage"] == null){
      pageNames.add("profilImage");
      pages.add(const ProfilImageSlider());
    }
    if(featureOnBoardingData["standortBestimmung"] == null){
      pageNames.add("standortBestimmung");
      pages.add(const StandortbestimmungSlider());
    }
    if(featureOnBoardingData["reisePlanung"] == null){
      pageNames.add("reisePlanung");
      pages.add(const ReiseplanungSlider());
    }
    if(featureOnBoardingData["socialMedia"] == null){
      pageNames.add("socialMedia");
      pages.add(const SocialMediaSlider());
    }
    if(featureOnBoardingData["support"] == null){
      pageNames.add("support");
      pages.add(const SupportSlider());
    }
  }

  back() {
    currentPage -= 1;
    pageController.jumpToPage(currentPage);
  }

  next() async {
    currentPage += 1;
    pageController.jumpToPage(currentPage);
  }

  done() async{
    for (final name in pageNames) {
      updateHiveFeatureOnBoarding(name, true);
    }
    Navigator.pop(context);
  }


  @override
  Widget build(BuildContext context) {

    List<Widget> indicators(pagesLength, currentIndex) {
      return List<Widget>.generate(pagesLength, (index) {
        return Container(
          margin: const EdgeInsets.all(3),
          width: 10,
          height: 10,
          decoration: BoxDecoration(
              color: currentIndex == index ? Colors.black : Colors.black26,
              shape: BoxShape.circle),
        );
      });
    }

    navigationButtons() {
      bool isFirstPage = currentPage == 0;
      bool isLastPage = currentPage + 1 == pages.length;

      return Container(
        width: 600,
        margin: const EdgeInsets.only(left: 20, right: 20),
        child: Row(mainAxisSize: MainAxisSize.min,children: [
          Opacity(
            opacity: isFirstPage ? 0 : 1,
            child: FloatingActionButton(
              mini: true,
              onPressed: () => back(),
              child: const Icon(Icons.chevron_left),
            ),
          ),
          Expanded(child: Wrap(alignment: WrapAlignment.center, children: indicators(pages.length, currentPage))),
          if(isLastPage) FloatingActionButton(
            mini: true,
            onPressed: () => done(),
            child: const Icon(Icons.done),
          ),
          if(!isLastPage) FloatingActionButton(
            mini: true,
            onPressed: () => next(),
            child: const Icon(Icons.chevron_right),
          ),
        ],),
      );
    }

    return Scaffold(
        body: SafeArea(
          child: PageView(
            controller: pageController,
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: (int page) {
              setState(() {
                currentPage = page;
              });
            },
            children: pages,
          ),
        ),
        resizeToAvoidBottomInset: false,
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: navigationButtons());
  }
}

