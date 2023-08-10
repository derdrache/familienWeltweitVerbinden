import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/foundation.dart';

import '../../global/profil_sprachen.dart';
import '../../widgets/ChildrenBirthdatePicker.dart';
import '../../widgets/google_autocomplete.dart';
import '../../widgets/layout/custom_dropdownButton.dart';
import '../../widgets/layout/custom_multi_select.dart';
import '../../widgets/layout/custom_text_input.dart';
import '../../global/global_functions.dart' as global_functions;
import '../../global/variablen.dart' as global_variablen;

var isGerman = kIsWeb
    ? PlatformDispatcher.instance.locale.languageCode == "de"
    : Platform.localeName == "de_DE";

class OnBoardingSlider extends StatefulWidget {
  const OnBoardingSlider({super.key});

  @override
  State<OnBoardingSlider> createState() => _OnBoardingSliderState();
}

class _OnBoardingSliderState extends State<OnBoardingSlider> {
  int currentPage = 0;
  final PageController pageController = PageController(initialPage: 0);
  var sliderStepOne = StepOne();
  var sliderStepTwo = StepTwo();
  var sliderStepThree = StepThree();

  late List<Widget> pages;

  back() {
    currentPage -= 1;
    pageController.jumpToPage(currentPage);
  }

  next() {
    //only if all is filled up
    currentPage += 1;
    pageController.jumpToPage(currentPage);
  }

  done() async {}

  @override
  void initState() {
    pages = [sliderStepOne, sliderStepTwo, sliderStepThree];

    super.initState();
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
      bool isLastPage = currentPage + 1 == pages.length;

      return Stack(
        children: [
          Positioned(
              left: 20,
              bottom: 0,
              child: TextButton(
                onPressed: () => back(),
                child: const Text("Back"),
              )),
          Positioned.fill(
            child: Align(
                alignment: Alignment.bottomCenter,
                child: Wrap(children: indicators(pages.length, currentPage))),
          ),
          Positioned(
              right: 20,
              bottom: 0,
              child: TextButton(
                onPressed: () => isLastPage ? done() : next(),
                child: Text(isLastPage ? "Done" : "Next"),
              ))
        ],
      );
    }

    return Scaffold(
        body: PageView(
          controller: pageController,
          onPageChanged: (int page) {
            setState(() {
              currentPage = page;
            });
          },
          children: pages,
        ),
        resizeToAvoidBottomInset: false,
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: navigationButtons());
  }
}

class StepOne extends StatelessWidget {
  TextEditingController userNameKontroller = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController checkPasswordController = TextEditingController();

  getName() {
    return userNameKontroller.text;
  }

  StepOne({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: EdgeInsets.only(left: 10, right: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(AppLocalizations.of(context)!.accountErstellen,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
            ),
            SizedBox(
              height: 10,
            ),
            Text(AppLocalizations.of(context)!.accountErstellenInfo),
            SizedBox(
              height: 20,
            ),
            Text(
              AppLocalizations.of(context)!.benutzername,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            CustomTextInput(
                margin: EdgeInsets.only(top: 10, bottom: 10),
                AppLocalizations.of(context)!.benutzername,
                userNameKontroller,
                validator: global_functions.checkValidatorEmpty(context)),
            SizedBox(
              height: 10,
            ),
            Text(
              "Email",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            CustomTextInput(
              "Email",
              emailController,
              margin: EdgeInsets.only(top: 10, bottom: 10),
              validator: global_functions.checkValidationEmail(context),
              textInputAction: TextInputAction.next,
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(
              height: 10,
            ),
            Text(
              AppLocalizations.of(context)!.passwort,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            CustomTextInput(
                AppLocalizations.of(context)!.passwort, passwordController,
                margin: EdgeInsets.only(top: 10, bottom: 10),
                hideInput: true,
                validator: global_functions.checkValidatorPassword(context),
                textInputAction: TextInputAction.next),
            SizedBox(
              height: 10,
            ),
            Text(
              AppLocalizations.of(context)!.passwortBestaetigen,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            CustomTextInput(
              AppLocalizations.of(context)!.passwortBestaetigen,
              checkPasswordController,
              margin: EdgeInsets.only(top: 10, bottom: 10),
              hideInput: true,
              validator: global_functions.checkValidatorPassword(context,
                  passwordCheck: passwordController.text),
              textInputAction: TextInputAction.done,
            ),
          ],
        ),
      ),
    );
  }
}

class StepTwo extends StatelessWidget {
  StepTwo({super.key});

  late GoogleAutoComplete ortAuswahlBox;
  late CustomDropdownButton reiseArtenAuswahlBox;
  late CustomMultiTextForm sprachenAuswahlBox;
  late ChildrenBirthdatePickerBox childrenAgePickerBox;

  @override
  Widget build(BuildContext context) {
    ortAuswahlBox = GoogleAutoComplete(
      margin: EdgeInsets.only(top: 10, bottom: 10),
      hintText: AppLocalizations.of(context)!.aktuellenOrtEingeben,
    );
    sprachenAuswahlBox = CustomMultiTextForm(
        margin: EdgeInsets.only(top: 10, bottom: 10),
        validator: global_functions.checkValidationMultiTextForm(context),
        hintText: AppLocalizations.of(context)!.spracheAuswaehlen,
        auswahlList: isGerman
            ? ProfilSprachen().getAllGermanLanguages()
            : ProfilSprachen().getAllEnglishLanguages());
    reiseArtenAuswahlBox = CustomDropdownButton(
      margin: EdgeInsets.only(top: 10, bottom: 10),
      hintText: AppLocalizations.of(context)!.artDerReiseAuswaehlen,
      items: isGerman
          ? global_variablen.reisearten
          : global_variablen.reiseartenEnglisch,
    );
    childrenAgePickerBox = ChildrenBirthdatePickerBox(
      margin: EdgeInsets.only(top: 10, bottom: 10),
    );

    return SafeArea(
        child: Container(
      margin: EdgeInsets.only(left: 10, right: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(AppLocalizations.of(context)!.persoenlicheDaten,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ),
          SizedBox(
            height: 10,
          ),
          Text(AppLocalizations.of(context)!.informationRegisterStepTwo),
          SizedBox(
            height: 20,
          ),
          Text(
            AppLocalizations.of(context)!.woSeidIhrImMoment,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          ortAuswahlBox,
          SizedBox(
            height: 10,
          ),
          Text(
            AppLocalizations.of(context)!.wieSeidIhrUnterwegs,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          reiseArtenAuswahlBox,
          SizedBox(
            height: 10,
          ),
          Text(
            AppLocalizations.of(context)!.welcheSprachenSprechtIhr,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          sprachenAuswahlBox,
          SizedBox(
            height: 10,
          ),
          Text(
            AppLocalizations.of(context)!.wieAltSindEureKinder,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          childrenAgePickerBox,
          Text(
            AppLocalizations.of(context)!.infoZumAlterDerKinder,
          ),
        ],
      ),
    ));
  }
}

class StepThree extends StatelessWidget {
  StepThree({super.key});

  TextEditingController aboutusKontroller = TextEditingController();
  late CustomMultiTextForm interessenAuswahlBox;

  @override
  Widget build(BuildContext context) {
    interessenAuswahlBox = CustomMultiTextForm(
        margin: EdgeInsets.only(top: 10, bottom: 10),
        validator: global_functions.checkValidationMultiTextForm(context),
        hintText: AppLocalizations.of(context)!.interessenAuswaehlen,
        auswahlList: isGerman
            ? global_variablen.interessenListe
            : global_variablen.interessenListeEnglisch);

    return SafeArea(
        child: Container(
      margin: EdgeInsets.only(left: 10, right: 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(
          child: Text(AppLocalizations.of(context)!.persoenlicheDaten,
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ),
        SizedBox(
          height: 10,
        ),
        Text(AppLocalizations.of(context)!.informationRegisterStepThree),
        SizedBox(
          height: 20,
        ),
        Text(
          AppLocalizations.of(context)!.welcheThemenInteressierenEuch,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        interessenAuswahlBox,
        SizedBox(
          height: 10,
        ),
        Text(
          AppLocalizations.of(context)!.beschreibungEuererFamilie,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        CustomTextInput(
            "${AppLocalizations.of(context)!.aboutusHintText} *optional*",
            aboutusKontroller,
            margin: EdgeInsets.only(top: 10, bottom: 10),
            moreLines: 4)
      ]),
    ));
  }
}
