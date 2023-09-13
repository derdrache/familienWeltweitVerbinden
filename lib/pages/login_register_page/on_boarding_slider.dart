import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive/hive.dart';

import '../../global/style.dart' as style;
import '../../services/notification.dart' as notifications;
import '../../global/encryption.dart';
import '../../global/profil_sprachen.dart';
import '../../services/database.dart';
import '../../widgets/ChildrenBirthdatePicker.dart';
import '../../widgets/google_autocomplete.dart';
import '../../widgets/layout/custom_dropdown_button.dart';
import '../../widgets/layout/custom_multi_select.dart';
import '../../widgets/layout/custom_snackbar.dart';
import '../../widgets/layout/custom_text_input.dart';
import '../../global/global_functions.dart' as global_functions;
import '../../global/variablen.dart' as global_variablen;
import '../start_page.dart';
import 'login_page.dart';

var isGerman = kIsWeb
    ? PlatformDispatcher.instance.locale.languageCode == "de"
    : Platform.localeName == "de_DE";

class OnBoardingSlider extends StatefulWidget {
  bool withSocialLogin;

  OnBoardingSlider({
    super.key,
    this.withSocialLogin = false
  });

  @override
  State<OnBoardingSlider> createState() => _OnBoardingSliderState();
}

class _OnBoardingSliderState extends State<OnBoardingSlider> {
  int currentPage = 0;
  final PageController pageController = PageController(initialPage: 0);
  late var sliderStepOne;
  var sliderStepTwo = SliderStepTwo();
  var sliderStepThree = SliderStepThree();
  bool isLoading = false;

  late List<Widget> pages;

  back() {
    currentPage -= 1;
    pageController.jumpToPage(currentPage);
  }

  next() async {
    if(currentPage == 0 && ! await sliderStepOne.allFilledAndErrorMsg(context)){
      return;
    }else if(currentPage == 1 && context.mounted && !sliderStepTwo.allFilledAndErrorMsg(context)){
      return;
    }else if(currentPage == 2 && context.mounted &&!sliderStepThree.allFilledAndErrorMsg(context)){
      return;
    }

    currentPage += 1;
    pageController.jumpToPage(currentPage);
  }

  done() async{
    if(!sliderStepTwo.allFilledAndErrorMsg(context)) return;

    setState(() {
      isLoading = true;
    });

    Map accountData = sliderStepOne.getAllData();
    Map personalData1 = sliderStepTwo.getAllData();
    Map personalData2 = sliderStepThree.getAllData();
    Map allData = {...accountData, ...personalData1,...personalData2};

    if(!widget.withSocialLogin){
      bool createdAccount = await createAccount(allData);

      if(!createdAccount) {
        setState(() {
          isLoading = false;
        });
        return;
      }
    }


    Map ownProfil = await createProfil(allData);

    notifications.prepareNewLocationNotification();
    additionalDatabaseOperations(allData["location"], ownProfil["id"]);

    if(context.mounted) global_functions.changePageForever(context, StartPage());
  }

  createAccount(profilData) async{
    bool accounterSuccessfullyCreated = false;

    try {
      await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: profilData["email"], password: profilData["password"]);
      accounterSuccessfullyCreated = true;
    } on FirebaseAuthException catch (error) {
      if(!context.mounted) return;

      if (error.code == "email-already-in-use") {
          customSnackBar(
            context, AppLocalizations.of(context)!.emailInBenutzung);
      } else if (error.code == "invalid-email") {
        customSnackBar(context, AppLocalizations.of(context)!.emailUngueltig);
      } else if (error.code == "weak-password") {
          customSnackBar(
            context, AppLocalizations.of(context)!.passwortSchwach);
      } else if (error.code == "network-request-failed") {
          customSnackBar(
            context, AppLocalizations.of(context)!.keineVerbindungInternet);

      }


      pageController.jumpToPage(0);
    }

    return accounterSuccessfullyCreated;
  }

  createProfil(profilData) async{
    var userID = FirebaseAuth.instance.currentUser?.uid;

    var profil = {
      "id": userID,
      "email": encrypt(profilData["email"]),
      "name": profilData["userName"],
      "ort": profilData["location"]["city"],
      "interessen": profilData["interests"],
      "kinder": profilData["children"],
      "land": profilData["location"]["countryname"],
      "longt": profilData["location"]["longt"],
      "latt": profilData["location"]["latt"],
      "reiseart": profilData["travelTyp"],
      "sprachen": profilData["languages"],
      "token": !kIsWeb ? await FirebaseMessaging.instance.getToken() : null,
      "lastLogin": DateTime.now().toString(),
      "aboutme": profilData["aboutUs"],
      "besuchteLaender":[profilData["location"]["countryname"]]
    };

    await ProfilDatabase().addNewProfil(profil);

    await refreshHiveProfils();

    await NewsPageDatabase().addNewNews({
      "typ": "ortswechsel",
      "information": json.encode(profilData["location"]),
    });
    await refreshHiveNewsPage();

    return profil;
  }

  additionalDatabaseOperations(ortMapData, userId) async {
    await StadtinfoDatabase().addNewCity(ortMapData);
    StadtinfoDatabase().update(
        "familien = JSON_ARRAY_APPEND(familien, '\$', '$userId')",
        "WHERE ort LIKE '%${ortMapData["city"]}%' AND JSON_CONTAINS(familien, '\"$userId\"') < 1");

    await ChatGroupsDatabase().joinAndCreateCityChat(ortMapData["city"]);
    await ChatGroupsDatabase().updateChatGroup(
        "users = JSON_MERGE_PATCH(users, '${json.encode({
          userId: {"newMessages": 0}
        })}')",
        "WHERE id = '1'");
    List myGroupChats = Hive.box("secureBox").get("myGroupChats") ?? [];
    myGroupChats.add(getChatGroupFromHive(chatId: "1"));

    await refreshHiveChats();
    await refreshHiveMeetups();
  }

  skip(){
    global_functions.changePageForever(context, const LoginPage());
  }

  @override
  void initState() {
    sliderStepOne = SliderStepOne(withSocialLogin: widget.withSocialLogin,);
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
      bool isFirstPage = currentPage == 0;
      bool isLastPage = currentPage + 1 == pages.length;

      return Row(mainAxisSize: MainAxisSize.min,children: [
        TextButton(
          style: style.textButtonStyle(),
          onPressed: () => isFirstPage ? skip() : back(),
          child: Text(isFirstPage ? "Skip" : AppLocalizations.of(context)!.zurueck),
        ),
        Expanded(child: Wrap(alignment: WrapAlignment.center, children: indicators(pages.length, currentPage))),
        if(isLoading) const SizedBox(width: 20, height: 20,child: CircularProgressIndicator()),
        if(isLastPage) TextButton(style: style.textButtonStyle(), onPressed: ()=> done(), child: Text(AppLocalizations.of(context)!.fertig)),
        if(!isLastPage && !isLoading) TextButton(style: style.textButtonStyle(), onPressed: ()=> next(), child: Text(AppLocalizations.of(context)!.weiter)),
      ],);
    }

    return Scaffold(
        body: SafeArea(
          child: PageView(
            controller: pageController,
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

class SliderStepOne extends StatelessWidget {
  bool withSocialLogin;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _userNameKontroller = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _checkPasswordController = TextEditingController();

  getAllData(){
    String? userName = _userNameKontroller.text.replaceAll("'", "''");
    String? email = _emailController.text.replaceAll(" ", "");

    if(withSocialLogin){
      userName = FirebaseAuth.instance.currentUser?.displayName!;
      email = FirebaseAuth.instance.currentUser?.email;
    }

    return {
      "userName": userName,
      "email": email,
      "password": _passwordController.text
    };
  }

  Future<bool> allFilledAndErrorMsg(context) async{
    if (!_formKey.currentState!.validate()) {
      return false;
    }

    String userName = _userNameKontroller.text;
    userName = userName.replaceAll("'", "''");

    bool userExist =
        await ProfilDatabase().getData("id", "WHERE name = '$userName'");

    if(userExist != false){
      customSnackBar(context, AppLocalizations.of(context)!.benutzerNamevergeben);
      return false;
    }

    return true;
  }

  SliderStepOne({super.key, this.withSocialLogin = false});

  @override
  Widget build(BuildContext context) {

    return Container(
      margin: const EdgeInsets.only(left: 10, right: 10),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 30,),
            Center(
              child: Text(AppLocalizations.of(context)!.accountErstellen,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(
              height: 10,
            ),
            Text(AppLocalizations.of(context)!.accountErstellenInfo),
            const SizedBox(
              height: 20,
            ),
            Text(
              AppLocalizations.of(context)!.benutzername,
              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
            CustomTextInput(
                AppLocalizations.of(context)!.benutzername,
                _userNameKontroller,
                maxLength: 40,
                margin: const EdgeInsets.only(top: 10),
                validator: global_functions.checkValidatorEmpty(context)),
            if(!withSocialLogin) const Text(
              "Email",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            if(!withSocialLogin )CustomTextInput(
              "Email",
              _emailController,
              margin: const EdgeInsets.only(top: 10, bottom: 10),
              validator: global_functions.checkValidationEmail(context),
              textInputAction: TextInputAction.next,
              keyboardType: TextInputType.emailAddress,
            ),
            if(!withSocialLogin) const SizedBox(
              height: 10,
            ),
            if(!withSocialLogin) Text(
              AppLocalizations.of(context)!.passwort,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if(!withSocialLogin) CustomTextInput(
                AppLocalizations.of(context)!.passwort, _passwordController,
                margin: const EdgeInsets.only(top: 10, bottom: 10),
                hideInput: true,
                validator: global_functions.checkValidatorPassword(context),
                textInputAction: TextInputAction.next),
            if(!withSocialLogin)const SizedBox(
              height: 10,
            ),
            if(!withSocialLogin) Text(
              AppLocalizations.of(context)!.passwortBestaetigen,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if(!withSocialLogin) CustomTextInput(
              AppLocalizations.of(context)!.passwortBestaetigen,
              _checkPasswordController,
              margin: const EdgeInsets.only(top: 10, bottom: 10),
              hideInput: true,
              validator: global_functions.checkValidatorPassword(context,
                  passwordCheck: _passwordController.text),
              textInputAction: TextInputAction.done,
            ),
          ],
        ),
      ),
    );
  }
}

class SliderStepTwo extends StatelessWidget {
  SliderStepTwo({super.key});

  late GoogleAutoComplete _ortAuswahlBox;
  late CustomDropdownButton _reiseArtenAuswahlBox;
  late CustomMultiTextForm _sprachenAuswahlBox;
  late ChildrenBirthdatePickerBox _childrenAgePickerBox;

  Map getAllData(){
    return {
      "location": _ortAuswahlBox.getGoogleLocationData(),
      "travelTyp": _reiseArtenAuswahlBox.getSelected(),
      "languages": _sprachenAuswahlBox.getSelected(),
      "children": _childrenAgePickerBox.getDates()
    };
  }

  bool allFilledAndErrorMsg(context){
    var ortMapData = _ortAuswahlBox.getGoogleLocationData();
    bool locationSelected = ortMapData["city"] != null;
    bool travelTypSelected = _reiseArtenAuswahlBox.getSelected().isNotEmpty;
    bool languageSelected = _sprachenAuswahlBox.getSelected().isNotEmpty;
    bool childrenAgeFilled = _childrenAgePickerBox.getDates().length != 0 && _childrenInputValidation();

    if(!locationSelected){
      customSnackBar(context, AppLocalizations.of(context)!.ortEingeben);
      return false;
    }else if(!travelTypSelected){
      customSnackBar(context, AppLocalizations.of(context)!.reiseartAuswaehlen);
      return false;
    }else if(!languageSelected){
      customSnackBar(context, AppLocalizations.of(context)!.spracheAuswaehlen);
      return false;
    }else if(!childrenAgeFilled){
      customSnackBar(context, AppLocalizations.of(context)!.geburtsdatumEingeben);
      return false;
    }

    return true;
  }

  _childrenInputValidation() {
    bool allFilled = true;

    _childrenAgePickerBox.getDates().forEach((date) {
      if (date == null) {
        allFilled = false;
      }
    });
    return allFilled;
  }

  @override
  Widget build(BuildContext context) {
    _ortAuswahlBox = GoogleAutoComplete(
      margin: const EdgeInsets.only(top: 10, bottom: 10),
      hintText: AppLocalizations.of(context)!.aktuellenOrtEingeben,
    );
    _reiseArtenAuswahlBox = CustomDropdownButton(
      margin: const EdgeInsets.only(top: 10, bottom: 10),
      hintText: AppLocalizations.of(context)!.artDerReiseAuswaehlen,
      items: isGerman
          ? global_variablen.reisearten
          : global_variablen.reiseartenEnglisch,
    );
    _sprachenAuswahlBox = CustomMultiTextForm(
        margin: const EdgeInsets.only(top: 10, bottom: 10),
        hintText: AppLocalizations.of(context)!.spracheAuswaehlen,
        auswahlList: isGerman
            ? ProfilSprachen().getAllGermanLanguages()
            : ProfilSprachen().getAllEnglishLanguages());
    _childrenAgePickerBox = ChildrenBirthdatePickerBox(
      margin: const EdgeInsets.only(top: 10, bottom: 10),
    );

    return Container(
      margin: const EdgeInsets.only(left: 10, right: 10),
      child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 30,),
      Center(
        child: Text(AppLocalizations.of(context)!.persoenlicheDaten,
            style:
                const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      ),
      const SizedBox(
        height: 10,
      ),
      Text(AppLocalizations.of(context)!.informationRegisterStepTwo),
      const SizedBox(
        height: 20,
      ),
      Text(
        AppLocalizations.of(context)!.woSeidIhrImMoment,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      _ortAuswahlBox,
      const SizedBox(
        height: 10,
      ),
      Text(
        AppLocalizations.of(context)!.wieSeidIhrUnterwegs,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      _reiseArtenAuswahlBox,
      const SizedBox(
        height: 10,
      ),
      Text(
        AppLocalizations.of(context)!.welcheSprachenSprechtIhr,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      _sprachenAuswahlBox,
      const SizedBox(
        height: 10,
      ),
      Text(
        AppLocalizations.of(context)!.wieAltSindEureKinder,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      _childrenAgePickerBox,
      Text(
        AppLocalizations.of(context)!.infoZumAlterDerKinder,
      ),
    ],
      ),
    );
  }
}

class SliderStepThree extends StatelessWidget {
  final TextEditingController _aboutusKontroller = TextEditingController();
  late CustomMultiTextForm _interessenAuswahlBox;

  Map getAllData(){
    return {
      "interests": _interessenAuswahlBox.getSelected(),
      "aboutUs": _aboutusKontroller.text
    };
  }

  bool allFilledAndErrorMsg(context){
    bool interesetSelected = _interessenAuswahlBox.getSelected().isNotEmpty;

    if(!interesetSelected){
      customSnackBar(context, AppLocalizations.of(context)!.interessenAuswaehlen);
      return false;
    }

    return true;
  }

  SliderStepThree({super.key});

  @override
  Widget build(BuildContext context) {
    _interessenAuswahlBox = CustomMultiTextForm(
        margin: const EdgeInsets.only(top: 10, bottom: 10),
        hintText: AppLocalizations.of(context)!.interessenAuswaehlen,
        auswahlList: isGerman
            ? global_variablen.interessenListe
            : global_variablen.interessenListeEnglisch);

    return Container(
      margin: const EdgeInsets.only(left: 10, right: 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 30,),
    Center(
      child: Text(AppLocalizations.of(context)!.persoenlicheDaten,
          style:
              const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
    ),
    const SizedBox(
      height: 10,
    ),
    Text(AppLocalizations.of(context)!.informationRegisterStepThree),
    const SizedBox(
      height: 20,
    ),
    Text(
      AppLocalizations.of(context)!.welcheThemenInteressierenEuch,
      style: const TextStyle(fontWeight: FontWeight.bold),
    ),
    _interessenAuswahlBox,
    const SizedBox(
      height: 10,
    ),
    Text(
      AppLocalizations.of(context)!.beschreibungEuererFamilie,
      style: const TextStyle(fontWeight: FontWeight.bold),
    ),
    CustomTextInput(
        "${AppLocalizations.of(context)!.aboutusHintText} *optional*",
        _aboutusKontroller,
        margin: const EdgeInsets.only(top: 10, bottom: 10),
        moreLines: 4)
      ]),
    );
  }
}
