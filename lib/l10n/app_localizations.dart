import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en')
  ];

  /// No description provided for @helloWorld.
  ///
  /// In en, this message translates to:
  /// **'Hello World!'**
  String get helloWorld;

  /// No description provided for @passwort.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwort;

  /// No description provided for @passwortVergessen.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get passwortVergessen;

  /// No description provided for @registrieren.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get registrieren;

  /// No description provided for @diesesFeldAusfuellen.
  ///
  /// In en, this message translates to:
  /// **'fill in this field'**
  String get diesesFeldAusfuellen;

  /// No description provided for @emailEingeben.
  ///
  /// In en, this message translates to:
  /// **'Enter e-mail'**
  String get emailEingeben;

  /// No description provided for @gueltigeEmailEingeben.
  ///
  /// In en, this message translates to:
  /// **'enter valid e-mail'**
  String get gueltigeEmailEingeben;

  /// No description provided for @passwortEingeben.
  ///
  /// In en, this message translates to:
  /// **'enter password'**
  String get passwortEingeben;

  /// No description provided for @passwortStimmtNichtUeberein.
  ///
  /// In en, this message translates to:
  /// **'Password does not match'**
  String get passwortStimmtNichtUeberein;

  /// No description provided for @ausfuellen.
  ///
  /// In en, this message translates to:
  /// **'Please select'**
  String get ausfuellen;

  /// No description provided for @registerAndEmailBestaetigen.
  ///
  /// In en, this message translates to:
  /// **'Registration successful, please confirm e-mail'**
  String get registerAndEmailBestaetigen;

  /// No description provided for @emailInBenutzung.
  ///
  /// In en, this message translates to:
  /// **'E-mail is already in use'**
  String get emailInBenutzung;

  /// No description provided for @emailUngueltig.
  ///
  /// In en, this message translates to:
  /// **'E-mail is not valid'**
  String get emailUngueltig;

  /// No description provided for @passwortSchwach.
  ///
  /// In en, this message translates to:
  /// **'Password is too weak'**
  String get passwortSchwach;

  /// No description provided for @passwortBestaetigen.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get passwortBestaetigen;

  /// No description provided for @passwortZuruecksetzen.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get passwortZuruecksetzen;

  /// No description provided for @passwortResetLink.
  ///
  /// In en, this message translates to:
  /// **'Reset link will be sent to your e-mail address'**
  String get passwortResetLink;

  /// No description provided for @emailSenden.
  ///
  /// In en, this message translates to:
  /// **'Send e-mail'**
  String get emailSenden;

  /// No description provided for @emailZuruecksetzenPasswort.
  ///
  /// In en, this message translates to:
  /// **'Password reset e-mail has been sent'**
  String get emailZuruecksetzenPasswort;

  /// No description provided for @userEmailNichtGefunden.
  ///
  /// In en, this message translates to:
  /// **'No user found for the e-mail address'**
  String get userEmailNichtGefunden;

  /// No description provided for @spracheAuswaehlen.
  ///
  /// In en, this message translates to:
  /// **'Select languages'**
  String get spracheAuswaehlen;

  /// No description provided for @interessenAuswaehlen.
  ///
  /// In en, this message translates to:
  /// **'Select interests'**
  String get interessenAuswaehlen;

  /// No description provided for @ortEingeben.
  ///
  /// In en, this message translates to:
  /// **'enter location'**
  String get ortEingeben;

  /// No description provided for @bitteEingabeKorrigieren.
  ///
  /// In en, this message translates to:
  /// **'Please correct entries: '**
  String get bitteEingabeKorrigieren;

  /// No description provided for @usernameInVerwendung.
  ///
  /// In en, this message translates to:
  /// **'Name is already in use'**
  String get usernameInVerwendung;

  /// No description provided for @reiseartAuswaehlen.
  ///
  /// In en, this message translates to:
  /// **'Select travel type'**
  String get reiseartAuswaehlen;

  /// No description provided for @geburtsdatumEingeben.
  ///
  /// In en, this message translates to:
  /// **'Enter the child\'s date of birth'**
  String get geburtsdatumEingeben;

  /// No description provided for @genauenStandortWaehlen.
  ///
  /// In en, this message translates to:
  /// **'Please select the exact location'**
  String get genauenStandortWaehlen;

  /// No description provided for @profilErstellen.
  ///
  /// In en, this message translates to:
  /// **'Create profile'**
  String get profilErstellen;

  /// No description provided for @benutzername.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get benutzername;

  /// No description provided for @aktuellenOrtEingeben.
  ///
  /// In en, this message translates to:
  /// **'Enter current location'**
  String get aktuellenOrtEingeben;

  /// No description provided for @anzahlUndAlterKinder.
  ///
  /// In en, this message translates to:
  /// **'number and ages of children:'**
  String get anzahlUndAlterKinder;

  /// No description provided for @emailNichtBestaetigt.
  ///
  /// In en, this message translates to:
  /// **'E-mail has not yet been confirmed'**
  String get emailNichtBestaetigt;

  /// No description provided for @benutzerNichtGefunden.
  ///
  /// In en, this message translates to:
  /// **'user not found'**
  String get benutzerNichtGefunden;

  /// No description provided for @passwortFalsch.
  ///
  /// In en, this message translates to:
  /// **'Password is wrong'**
  String get passwortFalsch;

  /// No description provided for @kinder.
  ///
  /// In en, this message translates to:
  /// **'Children'**
  String get kinder;

  /// No description provided for @datumEingeben.
  ///
  /// In en, this message translates to:
  /// **'enter date'**
  String get datumEingeben;

  /// No description provided for @artDerReiseAuswaehlen.
  ///
  /// In en, this message translates to:
  /// **'Select type of travel'**
  String get artDerReiseAuswaehlen;

  /// No description provided for @geburtsdatum.
  ///
  /// In en, this message translates to:
  /// **'birth date'**
  String get geburtsdatum;

  /// No description provided for @nachricht.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get nachricht;

  /// No description provided for @personSuchen.
  ///
  /// In en, this message translates to:
  /// **'search person'**
  String get personSuchen;

  /// No description provided for @ueberMichVeraendern.
  ///
  /// In en, this message translates to:
  /// **'change about us'**
  String get ueberMichVeraendern;

  /// No description provided for @ueberMich.
  ///
  /// In en, this message translates to:
  /// **'About us'**
  String get ueberMich;

  /// No description provided for @kinderAendern.
  ///
  /// In en, this message translates to:
  /// **'change children'**
  String get kinderAendern;

  /// No description provided for @ortAendern.
  ///
  /// In en, this message translates to:
  /// **'Change current location'**
  String get ortAendern;

  /// No description provided for @bitteGenaueOrtAuswaehlen.
  ///
  /// In en, this message translates to:
  /// **'Please select the desired location'**
  String get bitteGenaueOrtAuswaehlen;

  /// No description provided for @emailOderPasswortFalsch.
  ///
  /// In en, this message translates to:
  /// **'Wrong e-mail or password'**
  String get emailOderPasswortFalsch;

  /// No description provided for @emailAendern.
  ///
  /// In en, this message translates to:
  /// **'Change E-Mail'**
  String get emailAendern;

  /// No description provided for @neueEmail.
  ///
  /// In en, this message translates to:
  /// **'new e-mail'**
  String get neueEmail;

  /// No description provided for @interessenVeraendern.
  ///
  /// In en, this message translates to:
  /// **'change interests'**
  String get interessenVeraendern;

  /// No description provided for @neuenNamenEingeben.
  ///
  /// In en, this message translates to:
  /// **'Enter new name'**
  String get neuenNamenEingeben;

  /// No description provided for @nameAendern.
  ///
  /// In en, this message translates to:
  /// **'Change name'**
  String get nameAendern;

  /// No description provided for @reiseartAendern.
  ///
  /// In en, this message translates to:
  /// **'change type of travel'**
  String get reiseartAendern;

  /// No description provided for @spracheVeraendern.
  ///
  /// In en, this message translates to:
  /// **'Change language'**
  String get spracheVeraendern;

  /// No description provided for @neuesPasswortEingeben.
  ///
  /// In en, this message translates to:
  /// **'Enter a new password'**
  String get neuesPasswortEingeben;

  /// No description provided for @altesPasswortEingeben.
  ///
  /// In en, this message translates to:
  /// **'Enter old password'**
  String get altesPasswortEingeben;

  /// No description provided for @passwortStimmtNichtMitNeuem.
  ///
  /// In en, this message translates to:
  /// **'Password confirmation does not match the new password'**
  String get passwortStimmtNichtMitNeuem;

  /// No description provided for @altesPasswortFalsch.
  ///
  /// In en, this message translates to:
  /// **'Old password is wrong'**
  String get altesPasswortFalsch;

  /// No description provided for @neuesPasswortSchwach.
  ///
  /// In en, this message translates to:
  /// **'New password is too weak'**
  String get neuesPasswortSchwach;

  /// No description provided for @passwortVeraendern.
  ///
  /// In en, this message translates to:
  /// **'change password'**
  String get passwortVeraendern;

  /// No description provided for @neuesPasswortWiederholen.
  ///
  /// In en, this message translates to:
  /// **'Repeat new password'**
  String get neuesPasswortWiederholen;

  /// No description provided for @feedbackText.
  ///
  /// In en, this message translates to:
  /// **'Here you can tell me everything from errors in the app to improvement requests to nice words.'**
  String get feedbackText;

  /// No description provided for @feedback.
  ///
  /// In en, this message translates to:
  /// **'feedback'**
  String get feedback;

  /// No description provided for @senden.
  ///
  /// In en, this message translates to:
  /// **'send'**
  String get senden;

  /// No description provided for @alleBenachrichtigungen.
  ///
  /// In en, this message translates to:
  /// **'all notifications'**
  String get alleBenachrichtigungen;

  /// No description provided for @benachrichtigungen.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get benachrichtigungen;

  /// No description provided for @emailAlleSichtbar.
  ///
  /// In en, this message translates to:
  /// **'e-mail visible to all'**
  String get emailAlleSichtbar;

  /// No description provided for @privatsphaereSicherheit.
  ///
  /// In en, this message translates to:
  /// **'Privacy and security'**
  String get privatsphaereSicherheit;

  /// No description provided for @abmelden.
  ///
  /// In en, this message translates to:
  /// **'Log off'**
  String get abmelden;

  /// No description provided for @antippenZumAendern.
  ///
  /// In en, this message translates to:
  /// **'Tap to change entries'**
  String get antippenZumAendern;

  /// No description provided for @aktuelleOrt.
  ///
  /// In en, this message translates to:
  /// **'Current location'**
  String get aktuelleOrt;

  /// No description provided for @artDerReise.
  ///
  /// In en, this message translates to:
  /// **'Type of travel'**
  String get artDerReise;

  /// No description provided for @alterDerKinder.
  ///
  /// In en, this message translates to:
  /// **'Age of the children'**
  String get alterDerKinder;

  /// No description provided for @interessen.
  ///
  /// In en, this message translates to:
  /// **'Interests'**
  String get interessen;

  /// No description provided for @sprachen.
  ///
  /// In en, this message translates to:
  /// **'Languages'**
  String get sprachen;

  /// No description provided for @einstellungen.
  ///
  /// In en, this message translates to:
  /// **'Setting'**
  String get einstellungen;

  /// No description provided for @appInformation.
  ///
  /// In en, this message translates to:
  /// **'App information'**
  String get appInformation;

  /// No description provided for @geplanteErweiterungen.
  ///
  /// In en, this message translates to:
  /// **'Planned extensions'**
  String get geplanteErweiterungen;

  /// No description provided for @spenden.
  ///
  /// In en, this message translates to:
  /// **'Donate'**
  String get spenden;

  /// No description provided for @suche.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get suche;

  /// No description provided for @kontakt.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get kontakt;

  /// No description provided for @neuenChatEroeffnen.
  ///
  /// In en, this message translates to:
  /// **'Open a new chat'**
  String get neuenChatEroeffnen;

  /// No description provided for @keineVerbindungInternet.
  ///
  /// In en, this message translates to:
  /// **'No connection to the internet'**
  String get keineVerbindungInternet;

  /// No description provided for @willkommenBeiAppName.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Families worldwide'**
  String get willkommenBeiAppName;

  /// No description provided for @friendlistEntfernt.
  ///
  /// In en, this message translates to:
  /// **' removed from friends list'**
  String get friendlistEntfernt;

  /// No description provided for @friendlistHinzugefuegt.
  ///
  /// In en, this message translates to:
  /// **' added to friends list'**
  String get friendlistHinzugefuegt;

  /// No description provided for @familienAnzeige.
  ///
  /// In en, this message translates to:
  /// **'Family display - Connect multiple Accounts'**
  String get familienAnzeige;

  /// No description provided for @gemeinschaftenUpdate.
  ///
  /// In en, this message translates to:
  /// **'Register/Show communities'**
  String get gemeinschaftenUpdate;

  /// No description provided for @chatgruppen.
  ///
  /// In en, this message translates to:
  /// **'Chat groups'**
  String get chatgruppen;

  /// No description provided for @weitereAnemdlungsMoeglichkeiten.
  ///
  /// In en, this message translates to:
  /// **'Other login/registration options'**
  String get weitereAnemdlungsMoeglichkeiten;

  /// No description provided for @chatErweiterung.
  ///
  /// In en, this message translates to:
  /// **'Chat expansion'**
  String get chatErweiterung;

  /// No description provided for @accountLoeschen.
  ///
  /// In en, this message translates to:
  /// **'delete account'**
  String get accountLoeschen;

  /// No description provided for @layoutVerbessern.
  ///
  /// In en, this message translates to:
  /// **'improve layout'**
  String get layoutVerbessern;

  /// No description provided for @neueEmailVerifizieren.
  ///
  /// In en, this message translates to:
  /// **'New e-mail is valid after verification'**
  String get neueEmailVerifizieren;

  /// No description provided for @geburtsdatumHint.
  ///
  /// In en, this message translates to:
  /// **'Month/Year'**
  String get geburtsdatumHint;

  /// No description provided for @usernameZuLang.
  ///
  /// In en, this message translates to:
  /// **'Username is too long, maximum 40 characters'**
  String get usernameZuLang;

  /// No description provided for @feedbackDanke.
  ///
  /// In en, this message translates to:
  /// **'Thanks for your feedback'**
  String get feedbackDanke;

  /// No description provided for @erfolgreichGeaender.
  ///
  /// In en, this message translates to:
  /// **'successfully changed'**
  String get erfolgreichGeaender;

  /// No description provided for @ortEingabeInformation.
  ///
  /// In en, this message translates to:
  /// **'For the location, you can decide how precise your input should be. \n The more precise your input is, the more likely it is that you will be contacted by others.  \n\n Examples for the input: City / Country / Region'**
  String get ortEingabeInformation;

  /// No description provided for @stadtEingeben.
  ///
  /// In en, this message translates to:
  /// **'Stadt eingeben'**
  String get stadtEingeben;

  /// No description provided for @favoritenMeetups.
  ///
  /// In en, this message translates to:
  /// **'I\'m interested in'**
  String get favoritenMeetups;

  /// No description provided for @meineMeetups.
  ///
  /// In en, this message translates to:
  /// **'My Meetups'**
  String get meineMeetups;

  /// No description provided for @meetupArten.
  ///
  /// In en, this message translates to:
  /// **'public / semi-public / private'**
  String get meetupArten;

  /// No description provided for @bitteNameEingeben.
  ///
  /// In en, this message translates to:
  /// **'Please enter a name'**
  String get bitteNameEingeben;

  /// No description provided for @bitteMeetupArtEingeben.
  ///
  /// In en, this message translates to:
  /// **'Please enter the type of meetup'**
  String get bitteMeetupArtEingeben;

  /// No description provided for @bitteMeetupTypEingeben.
  ///
  /// In en, this message translates to:
  /// **'Please choose: offline or online meetup'**
  String get bitteMeetupTypEingeben;

  /// No description provided for @bitteStadtEingeben.
  ///
  /// In en, this message translates to:
  /// **'Please enter city'**
  String get bitteStadtEingeben;

  /// No description provided for @bitteLinkEingeben.
  ///
  /// In en, this message translates to:
  /// **'Please enter link to the meetup'**
  String get bitteLinkEingeben;

  /// No description provided for @bitteSpracheEingeben.
  ///
  /// In en, this message translates to:
  /// **'Please select language'**
  String get bitteSpracheEingeben;

  /// No description provided for @bitteMeetupDatumEingeben.
  ///
  /// In en, this message translates to:
  /// **'Please enter the date of the meetup'**
  String get bitteMeetupDatumEingeben;

  /// No description provided for @bitteMeetupUhrzeitEingeben.
  ///
  /// In en, this message translates to:
  /// **'Please enter the time of the meetup'**
  String get bitteMeetupUhrzeitEingeben;

  /// No description provided for @bitteMeetupBeschreibungEingeben.
  ///
  /// In en, this message translates to:
  /// **'Please enter a description of the meetup'**
  String get bitteMeetupBeschreibungEingeben;

  /// No description provided for @datumAuswaehlen.
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get datumAuswaehlen;

  /// No description provided for @uhrzeitAuswaehlen.
  ///
  /// In en, this message translates to:
  /// **'Select time'**
  String get uhrzeitAuswaehlen;

  /// No description provided for @meetupLinkEingeben.
  ///
  /// In en, this message translates to:
  /// **'Enter link from meetup'**
  String get meetupLinkEingeben;

  /// No description provided for @informationMeetupArt.
  ///
  /// In en, this message translates to:
  /// **'Information about the meetup type'**
  String get informationMeetupArt;

  /// No description provided for @privatInformationText.
  ///
  /// In en, this message translates to:
  /// **'These cannot be found in the global search.\nThe sharing only works via a link.\nIf a family is interested, the organizer must still approve them for the meetup.'**
  String get privatInformationText;

  /// No description provided for @halbOeffentlich.
  ///
  /// In en, this message translates to:
  /// **'semi-public'**
  String get halbOeffentlich;

  /// No description provided for @halbOeffentlichInformationText.
  ///
  /// In en, this message translates to:
  /// **'These can be found everywhere.\nTo see the details of the meetup, permission from the organizer is required.'**
  String get halbOeffentlichInformationText;

  /// No description provided for @oeffentlich.
  ///
  /// In en, this message translates to:
  /// **'public'**
  String get oeffentlich;

  /// No description provided for @oeffentlichInformationText.
  ///
  /// In en, this message translates to:
  /// **'These can be found anywhere and viewed in full by anyone'**
  String get oeffentlichInformationText;

  /// No description provided for @meetupErstellen.
  ///
  /// In en, this message translates to:
  /// **'Create meetup'**
  String get meetupErstellen;

  /// No description provided for @meetupBeschreibung.
  ///
  /// In en, this message translates to:
  /// **'Meetup description'**
  String get meetupBeschreibung;

  /// No description provided for @meetupMelden.
  ///
  /// In en, this message translates to:
  /// **'Report meetup'**
  String get meetupMelden;

  /// No description provided for @meetupMeldenFrage.
  ///
  /// In en, this message translates to:
  /// **'Why do you want to report the meetup?'**
  String get meetupMeldenFrage;

  /// No description provided for @meetupLoeschen.
  ///
  /// In en, this message translates to:
  /// **'Delete meetup'**
  String get meetupLoeschen;

  /// No description provided for @linkKopieren.
  ///
  /// In en, this message translates to:
  /// **'copy Link'**
  String get linkKopieren;

  /// No description provided for @linkWurdekopiert.
  ///
  /// In en, this message translates to:
  /// **'Link has been copied - only usable in chat'**
  String get linkWurdekopiert;

  /// No description provided for @familienFreigeben.
  ///
  /// In en, this message translates to:
  /// **'Share families'**
  String get familienFreigeben;

  /// No description provided for @teilnehmen.
  ///
  /// In en, this message translates to:
  /// **'Take part'**
  String get teilnehmen;

  /// No description provided for @absage.
  ///
  /// In en, this message translates to:
  /// **'Refuse'**
  String get absage;

  /// No description provided for @datum.
  ///
  /// In en, this message translates to:
  /// **'Date: '**
  String get datum;

  /// No description provided for @stadt.
  ///
  /// In en, this message translates to:
  /// **'City: '**
  String get stadt;

  /// No description provided for @land.
  ///
  /// In en, this message translates to:
  /// **'Country: '**
  String get land;

  /// No description provided for @meetupNameAendern.
  ///
  /// In en, this message translates to:
  /// **'Change meetup name'**
  String get meetupNameAendern;

  /// No description provided for @meetupDatumAendern.
  ///
  /// In en, this message translates to:
  /// **'Change meetup Date'**
  String get meetupDatumAendern;

  /// No description provided for @neuesDatumEingeben.
  ///
  /// In en, this message translates to:
  /// **'enter new date'**
  String get neuesDatumEingeben;

  /// No description provided for @meetupUhrzeitAendern.
  ///
  /// In en, this message translates to:
  /// **'Change meetup time'**
  String get meetupUhrzeitAendern;

  /// No description provided for @neueUhrzeitEingeben.
  ///
  /// In en, this message translates to:
  /// **'enter new time'**
  String get neueUhrzeitEingeben;

  /// No description provided for @meetupStadtAendern.
  ///
  /// In en, this message translates to:
  /// **'Change meetup city'**
  String get meetupStadtAendern;

  /// No description provided for @neueStadtEingeben.
  ///
  /// In en, this message translates to:
  /// **'Enter new city'**
  String get neueStadtEingeben;

  /// No description provided for @meetupMapLinkAendern.
  ///
  /// In en, this message translates to:
  /// **'Change meetup map link'**
  String get meetupMapLinkAendern;

  /// No description provided for @neuenKartenlinkEingeben.
  ///
  /// In en, this message translates to:
  /// **'enter new map link'**
  String get neuenKartenlinkEingeben;

  /// No description provided for @meetupIntervalAendern.
  ///
  /// In en, this message translates to:
  /// **'Change meetup interval'**
  String get meetupIntervalAendern;

  /// No description provided for @meetupBeschreibungAendern.
  ///
  /// In en, this message translates to:
  /// **'Change meetup description'**
  String get meetupBeschreibungAendern;

  /// No description provided for @neueBeschreibungEingeben.
  ///
  /// In en, this message translates to:
  /// **'enter new description'**
  String get neueBeschreibungEingeben;

  /// No description provided for @meetupInteresseZurueckgenommen.
  ///
  /// In en, this message translates to:
  /// **'Your interest in the meetup has been withdrawn'**
  String get meetupInteresseZurueckgenommen;

  /// No description provided for @meetupInteresseMitgeteilt.
  ///
  /// In en, this message translates to:
  /// **'Your interest in the meetup has been sent to the organizer'**
  String get meetupInteresseMitgeteilt;

  /// No description provided for @speichern.
  ///
  /// In en, this message translates to:
  /// **'save'**
  String get speichern;

  /// No description provided for @abbrechen.
  ///
  /// In en, this message translates to:
  /// **'cancel'**
  String get abbrechen;

  /// No description provided for @meetupBildAendern.
  ///
  /// In en, this message translates to:
  /// **'Change meetup image'**
  String get meetupBildAendern;

  /// No description provided for @meetupArtAendern.
  ///
  /// In en, this message translates to:
  /// **'Change meetup type'**
  String get meetupArtAendern;

  /// No description provided for @uhrzeit.
  ///
  /// In en, this message translates to:
  /// **'Time: '**
  String get uhrzeit;

  /// No description provided for @ort.
  ///
  /// In en, this message translates to:
  /// **'Location: '**
  String get ort;

  /// No description provided for @meetupSpracheAendern.
  ///
  /// In en, this message translates to:
  /// **'Change meetup language'**
  String get meetupSpracheAendern;

  /// No description provided for @sprache.
  ///
  /// In en, this message translates to:
  /// **'Language: '**
  String get sprache;

  /// No description provided for @eingabeKeinLink.
  ///
  /// In en, this message translates to:
  /// **'Input is not a link'**
  String get eingabeKeinLink;

  /// No description provided for @bitteBildAussuchen.
  ///
  /// In en, this message translates to:
  /// **'Please choose an image'**
  String get bitteBildAussuchen;

  /// No description provided for @slogn1.
  ///
  /// In en, this message translates to:
  /// **'The networking app for families worldwide.'**
  String get slogn1;

  /// No description provided for @slogn2.
  ///
  /// In en, this message translates to:
  /// **'Find families around the world quickly and easily'**
  String get slogn2;

  /// No description provided for @linkBearbeiten.
  ///
  /// In en, this message translates to:
  /// **'edit link'**
  String get linkBearbeiten;

  /// No description provided for @linkOeffnen.
  ///
  /// In en, this message translates to:
  /// **'open link'**
  String get linkOeffnen;

  /// No description provided for @teilnehmer.
  ///
  /// In en, this message translates to:
  /// **'Participants: '**
  String get teilnehmer;

  /// No description provided for @organisatorWechsel.
  ///
  /// In en, this message translates to:
  /// **'Change organizer'**
  String get organisatorWechsel;

  /// No description provided for @keineFamilienFreigebenVorhanden.
  ///
  /// In en, this message translates to:
  /// **'no families to share'**
  String get keineFamilienFreigebenVorhanden;

  /// No description provided for @interessierte.
  ///
  /// In en, this message translates to:
  /// **'Interested: '**
  String get interessierte;

  /// No description provided for @zusagen.
  ///
  /// In en, this message translates to:
  /// **'Commitments: '**
  String get zusagen;

  /// No description provided for @absagen.
  ///
  /// In en, this message translates to:
  /// **'Cancellations: '**
  String get absagen;

  /// No description provided for @freigegeben.
  ///
  /// In en, this message translates to:
  /// **'Shared: '**
  String get freigegeben;

  /// No description provided for @freigegebeneFamilien.
  ///
  /// In en, this message translates to:
  /// **'Shared Families'**
  String get freigegebeneFamilien;

  /// No description provided for @filterMeetupSuche.
  ///
  /// In en, this message translates to:
  /// **'search by country or City'**
  String get filterMeetupSuche;

  /// No description provided for @filterErkunden.
  ///
  /// In en, this message translates to:
  /// **'Family, City or Country'**
  String get filterErkunden;

  /// No description provided for @emailErhalten.
  ///
  /// In en, this message translates to:
  /// **'receive e-mail'**
  String get emailErhalten;

  /// No description provided for @chatNotification.
  ///
  /// In en, this message translates to:
  /// **'chat notification'**
  String get chatNotification;

  /// No description provided for @meetupNotification.
  ///
  /// In en, this message translates to:
  /// **'meetup notification'**
  String get meetupNotification;

  /// No description provided for @meetupUebergebenAn1.
  ///
  /// In en, this message translates to:
  /// **'the meetup was successfully handed over to '**
  String get meetupUebergebenAn1;

  /// No description provided for @meetupUebergebenAn2.
  ///
  /// In en, this message translates to:
  /// **' '**
  String get meetupUebergebenAn2;

  /// No description provided for @uebertragen.
  ///
  /// In en, this message translates to:
  /// **'transfer'**
  String get uebertragen;

  /// No description provided for @organisatorAbgeben.
  ///
  /// In en, this message translates to:
  /// **'submit organizer'**
  String get organisatorAbgeben;

  /// No description provided for @hatDirNachrichtGeschrieben.
  ///
  /// In en, this message translates to:
  /// **' has written you a message'**
  String get hatDirNachrichtGeschrieben;

  /// No description provided for @meetupZeitzoneAendern.
  ///
  /// In en, this message translates to:
  /// **'Change meetup time zone'**
  String get meetupZeitzoneAendern;

  /// No description provided for @zeitzone.
  ///
  /// In en, this message translates to:
  /// **'Time zone: '**
  String get zeitzone;

  /// No description provided for @neueZeitzoneEingeben.
  ///
  /// In en, this message translates to:
  /// **'Enter new time zone'**
  String get neueZeitzoneEingeben;

  /// No description provided for @bestitzerWechseln.
  ///
  /// In en, this message translates to:
  /// **'Change Owner'**
  String get bestitzerWechseln;

  /// No description provided for @meetupWirklichLoeschen.
  ///
  /// In en, this message translates to:
  /// **'Do you really want to delete the meetup?'**
  String get meetupWirklichLoeschen;

  /// No description provided for @unsicher.
  ///
  /// In en, this message translates to:
  /// **'Unsure: '**
  String get unsicher;

  /// No description provided for @onlineMeetups.
  ///
  /// In en, this message translates to:
  /// **'Online meetups'**
  String get onlineMeetups;

  /// No description provided for @meetupsOrganisationstools.
  ///
  /// In en, this message translates to:
  /// **'organize meetups'**
  String get meetupsOrganisationstools;

  /// No description provided for @newsBoard.
  ///
  /// In en, this message translates to:
  /// **'News Board'**
  String get newsBoard;

  /// No description provided for @loginMitGoogle.
  ///
  /// In en, this message translates to:
  /// **'Login with Google'**
  String get loginMitGoogle;

  /// No description provided for @alleMeetups.
  ///
  /// In en, this message translates to:
  /// **'All meetups'**
  String get alleMeetups;

  /// No description provided for @ueber.
  ///
  /// In en, this message translates to:
  /// **'About families worldwide'**
  String get ueber;

  /// No description provided for @bitteMeetupIntervalEingeben.
  ///
  /// In en, this message translates to:
  /// **'Please enter meetup interval'**
  String get bitteMeetupIntervalEingeben;

  /// No description provided for @nochKeineChatsVorhanden.
  ///
  /// In en, this message translates to:
  /// **'No chats yet'**
  String get nochKeineChatsVorhanden;

  /// No description provided for @nochKeineFreundeVorhanden.
  ///
  /// In en, this message translates to:
  /// **'No friends yet'**
  String get nochKeineFreundeVorhanden;

  /// No description provided for @nochKeineMeetupsAusgewaehlt.
  ///
  /// In en, this message translates to:
  /// **'No meetups selected yet'**
  String get nochKeineMeetupsAusgewaehlt;

  /// No description provided for @nochKeineMeetupsErstellt.
  ///
  /// In en, this message translates to:
  /// **'No meetups created yet'**
  String get nochKeineMeetupsErstellt;

  /// No description provided for @profilbildAendern.
  ///
  /// In en, this message translates to:
  /// **'Change profile picture'**
  String get profilbildAendern;

  /// No description provided for @linkProfilbildEingeben.
  ///
  /// In en, this message translates to:
  /// **'Enter link to profile picture'**
  String get linkProfilbildEingeben;

  /// No description provided for @bitteEnddatumMeetupEingeben.
  ///
  /// In en, this message translates to:
  /// **'Please enter the end of the meetup'**
  String get bitteEnddatumMeetupEingeben;

  /// No description provided for @meetupEnde.
  ///
  /// In en, this message translates to:
  /// **'Meetup end: '**
  String get meetupEnde;

  /// No description provided for @inaktiv.
  ///
  /// In en, this message translates to:
  /// **'inactive'**
  String get inaktiv;

  /// No description provided for @aboutusHintText.
  ///
  /// In en, this message translates to:
  /// **'We travel because... \nWe want to network because... \nWe search...\n'**
  String get aboutusHintText;

  /// No description provided for @eingebenBisTagMeetup.
  ///
  /// In en, this message translates to:
  /// **'Enter until which day the meetup goes'**
  String get eingebenBisTagMeetup;

  /// No description provided for @eingebenBisUhrzeitMeetup.
  ///
  /// In en, this message translates to:
  /// **'Enter until what time the meetup goes'**
  String get eingebenBisUhrzeitMeetup;

  /// No description provided for @angemeldetBleiben.
  ///
  /// In en, this message translates to:
  /// **'Stay logged in?'**
  String get angemeldetBleiben;

  /// No description provided for @aufReise.
  ///
  /// In en, this message translates to:
  /// **'On travel'**
  String get aufReise;

  /// No description provided for @aufReiseAendern.
  ///
  /// In en, this message translates to:
  /// **'Change on travel'**
  String get aufReiseAendern;

  /// No description provided for @seit.
  ///
  /// In en, this message translates to:
  /// **'since: '**
  String get seit;

  /// No description provided for @bis.
  ///
  /// In en, this message translates to:
  /// **'until: '**
  String get bis;

  /// No description provided for @offen.
  ///
  /// In en, this message translates to:
  /// **'open'**
  String get offen;

  /// No description provided for @eingebenSeitWannReise.
  ///
  /// In en, this message translates to:
  /// **'Please enter since when you have been traveling'**
  String get eingebenSeitWannReise;

  /// No description provided for @eingebenBisWannReise.
  ///
  /// In en, this message translates to:
  /// **'Please enter until when you were traveling'**
  String get eingebenBisWannReise;

  /// No description provided for @stadtinformationErstellen.
  ///
  /// In en, this message translates to:
  /// **'Create city information'**
  String get stadtinformationErstellen;

  /// No description provided for @beschreibung.
  ///
  /// In en, this message translates to:
  /// **'description'**
  String get beschreibung;

  /// No description provided for @titel.
  ///
  /// In en, this message translates to:
  /// **'title'**
  String get titel;

  /// No description provided for @titelStadtinformationEingeben.
  ///
  /// In en, this message translates to:
  /// **'Enter title for city information'**
  String get titelStadtinformationEingeben;

  /// No description provided for @beschreibungStadtinformationEingeben.
  ///
  /// In en, this message translates to:
  /// **'Enter description for city information'**
  String get beschreibungStadtinformationEingeben;

  /// No description provided for @keineStadtinformationVorhanden.
  ///
  /// In en, this message translates to:
  /// **'no city information available'**
  String get keineStadtinformationVorhanden;

  /// No description provided for @allgemeineInformation.
  ///
  /// In en, this message translates to:
  /// **'General information'**
  String get allgemeineInformation;

  /// No description provided for @wetter.
  ///
  /// In en, this message translates to:
  /// **'weather: '**
  String get wetter;

  /// No description provided for @insiderInformation.
  ///
  /// In en, this message translates to:
  /// **'Inside info'**
  String get insiderInformation;

  /// No description provided for @besuchtVon.
  ///
  /// In en, this message translates to:
  /// **'Visited by: '**
  String get besuchtVon;

  /// No description provided for @familien.
  ///
  /// In en, this message translates to:
  /// **' families'**
  String get familien;

  /// No description provided for @bearbeiten.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get bearbeiten;

  /// No description provided for @loeschen.
  ///
  /// In en, this message translates to:
  /// **'delete'**
  String get loeschen;

  /// No description provided for @melden.
  ///
  /// In en, this message translates to:
  /// **'report'**
  String get melden;

  /// No description provided for @informationLoeschen.
  ///
  /// In en, this message translates to:
  /// **'delete information'**
  String get informationLoeschen;

  /// No description provided for @informationWirklichLoeschen.
  ///
  /// In en, this message translates to:
  /// **'Do you really want to delete the information?'**
  String get informationWirklichLoeschen;

  /// No description provided for @informationMelden.
  ///
  /// In en, this message translates to:
  /// **'report information'**
  String get informationMelden;

  /// No description provided for @informationMeldenFrage.
  ///
  /// In en, this message translates to:
  /// **'Why do you want to report the information?'**
  String get informationMeldenFrage;

  /// No description provided for @informationAendern.
  ///
  /// In en, this message translates to:
  /// **'change information'**
  String get informationAendern;

  /// No description provided for @ortAuswaehlen.
  ///
  /// In en, this message translates to:
  /// **'Select location'**
  String get ortAuswaehlen;

  /// No description provided for @freundesListe.
  ///
  /// In en, this message translates to:
  /// **'friends list'**
  String get freundesListe;

  /// No description provided for @automatischeStandortbestimmung.
  ///
  /// In en, this message translates to:
  /// **'automatic location'**
  String get automatischeStandortbestimmung;

  /// No description provided for @geloeschterUser.
  ///
  /// In en, this message translates to:
  /// **'deleted user'**
  String get geloeschterUser;

  /// No description provided for @accountWirklichLoeschen.
  ///
  /// In en, this message translates to:
  /// **'Do you really want to delete the account?\nPlease write \'delete\' in the input field to be sure'**
  String get accountWirklichLoeschen;

  /// No description provided for @freundHinzufuegen.
  ///
  /// In en, this message translates to:
  /// **'add friend'**
  String get freundHinzufuegen;

  /// No description provided for @freundEntfernen.
  ///
  /// In en, this message translates to:
  /// **'remove friend'**
  String get freundEntfernen;

  /// No description provided for @friendNotification.
  ///
  /// In en, this message translates to:
  /// **'new friend notification'**
  String get friendNotification;

  /// No description provided for @titleZuLang.
  ///
  /// In en, this message translates to:
  /// **'Title is too long, max 100 characters'**
  String get titleZuLang;

  /// No description provided for @automatischeUebersetzung.
  ///
  /// In en, this message translates to:
  /// **'This text has been automatically translated'**
  String get automatischeUebersetzung;

  /// No description provided for @keineFamilieStadt.
  ///
  /// In en, this message translates to:
  /// **'There weren\'t any families in this town yet'**
  String get keineFamilieStadt;

  /// No description provided for @genauerStandort.
  ///
  /// In en, this message translates to:
  /// **'exact location'**
  String get genauerStandort;

  /// No description provided for @verkaufenTauschenSchenken.
  ///
  /// In en, this message translates to:
  /// **'Sell / Exchange / Give'**
  String get verkaufenTauschenSchenken;

  /// No description provided for @tradeHintText.
  ///
  /// In en, this message translates to:
  /// **'We sell... \nWe trade... \nWe give away...\n'**
  String get tradeHintText;

  /// No description provided for @tradeVeraendern.
  ///
  /// In en, this message translates to:
  /// **'change sell/trade/give away'**
  String get tradeVeraendern;

  /// No description provided for @keineInsiderInformation.
  ///
  /// In en, this message translates to:
  /// **'There is no insider information entered yet'**
  String get keineInsiderInformation;

  /// No description provided for @insiderInformationHinzufuegen.
  ///
  /// In en, this message translates to:
  /// **'add insider information'**
  String get insiderInformationHinzufuegen;

  /// No description provided for @reisePlanung.
  ///
  /// In en, this message translates to:
  /// **'travel planning'**
  String get reisePlanung;

  /// No description provided for @besuchteLaender.
  ///
  /// In en, this message translates to:
  /// **'visited countries'**
  String get besuchteLaender;

  /// No description provided for @besucheLaenderVeraendern.
  ///
  /// In en, this message translates to:
  /// **'change countries visited'**
  String get besucheLaenderVeraendern;

  /// No description provided for @reisePlanungVeraendern.
  ///
  /// In en, this message translates to:
  /// **'Change travel planning'**
  String get reisePlanungVeraendern;

  /// No description provided for @laenderAuswahl.
  ///
  /// In en, this message translates to:
  /// **'select countries'**
  String get laenderAuswahl;

  /// No description provided for @besuchteLaenderUpdate.
  ///
  /// In en, this message translates to:
  /// **'visited countries has been updated'**
  String get besuchteLaenderUpdate;

  /// No description provided for @von.
  ///
  /// In en, this message translates to:
  /// **'from'**
  String get von;

  /// No description provided for @jetzt.
  ///
  /// In en, this message translates to:
  /// **'now'**
  String get jetzt;

  /// No description provided for @vonKleinerAlsBis.
  ///
  /// In en, this message translates to:
  /// **'from-date must be smaller than until-date'**
  String get vonKleinerAlsBis;

  /// No description provided for @zeitraumUeberschneidetSich.
  ///
  /// In en, this message translates to:
  /// **'period overlaps with another entry'**
  String get zeitraumUeberschneidetSich;

  /// No description provided for @reiseplanungSichtbarFuer.
  ///
  /// In en, this message translates to:
  /// **'travel planning visible to '**
  String get reiseplanungSichtbarFuer;

  /// No description provided for @fuer.
  ///
  /// In en, this message translates to:
  /// **'for '**
  String get fuer;

  /// No description provided for @weltkarteReiseplanungSuchen.
  ///
  /// In en, this message translates to:
  /// **'for what period are you looking for other families?'**
  String get weltkarteReiseplanungSuchen;

  /// No description provided for @anzeigen.
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get anzeigen;

  /// No description provided for @benutzerMelden.
  ///
  /// In en, this message translates to:
  /// **'report user'**
  String get benutzerMelden;

  /// No description provided for @benutzerMeldenFrage.
  ///
  /// In en, this message translates to:
  /// **'why do you want to report the user?'**
  String get benutzerMeldenFrage;

  /// No description provided for @benutzerGemeldet.
  ///
  /// In en, this message translates to:
  /// **'user was reported'**
  String get benutzerGemeldet;

  /// No description provided for @verifizierungsEmailNochmalSenden.
  ///
  /// In en, this message translates to:
  /// **'Resend verification email'**
  String get verifizierungsEmailNochmalSenden;

  /// No description provided for @meetupErweiterung.
  ///
  /// In en, this message translates to:
  /// **'Meetup expansion'**
  String get meetupErweiterung;

  /// No description provided for @immerDabei.
  ///
  /// In en, this message translates to:
  /// **'always take part'**
  String get immerDabei;

  /// No description provided for @meetupOptionen.
  ///
  /// In en, this message translates to:
  /// **'Meetup options'**
  String get meetupOptionen;

  /// No description provided for @blockieren.
  ///
  /// In en, this message translates to:
  /// **'block'**
  String get blockieren;

  /// No description provided for @freigeben.
  ///
  /// In en, this message translates to:
  /// **'release'**
  String get freigeben;

  /// No description provided for @benutzerFreigegeben.
  ///
  /// In en, this message translates to:
  /// **'user is released again'**
  String get benutzerFreigegeben;

  /// No description provided for @benutzerBlockieren.
  ///
  /// In en, this message translates to:
  /// **'user is blocked'**
  String get benutzerBlockieren;

  /// No description provided for @meinDatum.
  ///
  /// In en, this message translates to:
  /// **'My Date'**
  String get meinDatum;

  /// No description provided for @tagsChange.
  ///
  /// In en, this message translates to:
  /// **'change tags'**
  String get tagsChange;

  /// No description provided for @tagHinzufuegen.
  ///
  /// In en, this message translates to:
  /// **'add tag'**
  String get tagHinzufuegen;

  /// No description provided for @nochKeineNachrichtVorhanden.
  ///
  /// In en, this message translates to:
  /// **'no messages available yet'**
  String get nochKeineNachrichtVorhanden;

  /// No description provided for @emailErneutVersendet.
  ///
  /// In en, this message translates to:
  /// **'e-mail has been sent again'**
  String get emailErneutVersendet;

  /// No description provided for @reisearten.
  ///
  /// In en, this message translates to:
  /// **'Travel type'**
  String get reisearten;

  /// No description provided for @genauerStandortSichtbarFuer.
  ///
  /// In en, this message translates to:
  /// **'exact location visible for '**
  String get genauerStandortSichtbarFuer;

  /// No description provided for @filterErgebnisse.
  ///
  /// In en, this message translates to:
  /// **'filters results'**
  String get filterErgebnisse;

  /// No description provided for @keineMeetupsErstellt.
  ///
  /// In en, this message translates to:
  /// **'no own Meetups created yet'**
  String get keineMeetupsErstellt;

  /// No description provided for @langeZeitNichtGesehen.
  ///
  /// In en, this message translates to:
  /// **'not seen for more than one month'**
  String get langeZeitNichtGesehen;

  /// No description provided for @innerhalbMonatsGesehen.
  ///
  /// In en, this message translates to:
  /// **'seen within one month'**
  String get innerhalbMonatsGesehen;

  /// No description provided for @innerhalbWocheGesehen.
  ///
  /// In en, this message translates to:
  /// **'seen within one week'**
  String get innerhalbWocheGesehen;

  /// No description provided for @kuerzlichGesehen.
  ///
  /// In en, this message translates to:
  /// **'seen recently'**
  String get kuerzlichGesehen;

  /// No description provided for @automatischerStandortNichtMoeglich.
  ///
  /// In en, this message translates to:
  /// **'automatic location cannot be combined with \'fixed location\' travel type'**
  String get automatischerStandortNichtMoeglich;

  /// No description provided for @neueMeetups.
  ///
  /// In en, this message translates to:
  /// **'new meetups'**
  String get neueMeetups;

  /// No description provided for @link.
  ///
  /// In en, this message translates to:
  /// **'link'**
  String get link;

  /// No description provided for @hochladen.
  ///
  /// In en, this message translates to:
  /// **'upload'**
  String get hochladen;

  /// No description provided for @bilderauswahl.
  ///
  /// In en, this message translates to:
  /// **'image selection'**
  String get bilderauswahl;

  /// No description provided for @eigenesBildLinkEingeben.
  ///
  /// In en, this message translates to:
  /// **'own picture - enter link'**
  String get eigenesBildLinkEingeben;

  /// No description provided for @communityErstellen.
  ///
  /// In en, this message translates to:
  /// **'create community'**
  String get communityErstellen;

  /// No description provided for @communityName.
  ///
  /// In en, this message translates to:
  /// **'community name'**
  String get communityName;

  /// No description provided for @beschreibungCommunity.
  ///
  /// In en, this message translates to:
  /// **'community description'**
  String get beschreibungCommunity;

  /// No description provided for @bitteCommunityBeschreibungEingeben.
  ///
  /// In en, this message translates to:
  /// **'Please enter community description'**
  String get bitteCommunityBeschreibungEingeben;

  /// No description provided for @linkEingebenOptional.
  ///
  /// In en, this message translates to:
  /// **'enter link *optional*'**
  String get linkEingebenOptional;

  /// No description provided for @communityWirklichLoeschen.
  ///
  /// In en, this message translates to:
  /// **'Do you really want to delete the community?'**
  String get communityWirklichLoeschen;

  /// No description provided for @communityMelden.
  ///
  /// In en, this message translates to:
  /// **'report community'**
  String get communityMelden;

  /// No description provided for @communityMeldenFrage.
  ///
  /// In en, this message translates to:
  /// **'why do you want to report the community?'**
  String get communityMeldenFrage;

  /// No description provided for @beschreibungAendern.
  ///
  /// In en, this message translates to:
  /// **'change description'**
  String get beschreibungAendern;

  /// No description provided for @linkAendern.
  ///
  /// In en, this message translates to:
  /// **'change link'**
  String get linkAendern;

  /// No description provided for @neuenLinkEingeben.
  ///
  /// In en, this message translates to:
  /// **'enter new link'**
  String get neuenLinkEingeben;

  /// No description provided for @bildAendern.
  ///
  /// In en, this message translates to:
  /// **'change image'**
  String get bildAendern;

  /// No description provided for @mitgliedHinzufuegen.
  ///
  /// In en, this message translates to:
  /// **'add member'**
  String get mitgliedHinzufuegen;

  /// No description provided for @member.
  ///
  /// In en, this message translates to:
  /// **'members'**
  String get member;

  /// No description provided for @familyProfil.
  ///
  /// In en, this message translates to:
  /// **'family profile'**
  String get familyProfil;

  /// No description provided for @annehmen.
  ///
  /// In en, this message translates to:
  /// **'accept'**
  String get annehmen;

  /// No description provided for @ablehnen.
  ///
  /// In en, this message translates to:
  /// **'reject'**
  String get ablehnen;

  /// No description provided for @communityLoeschen.
  ///
  /// In en, this message translates to:
  /// **'delete community'**
  String get communityLoeschen;

  /// No description provided for @ungueltigerLink.
  ///
  /// In en, this message translates to:
  /// **'link invalid - the link must start with http or www'**
  String get ungueltigerLink;

  /// No description provided for @keineCommunityFavorite.
  ///
  /// In en, this message translates to:
  /// **'no community saved as favorites'**
  String get keineCommunityFavorite;

  /// No description provided for @zurCommunityEingeladen.
  ///
  /// In en, this message translates to:
  /// **'you have been invited to the following community: '**
  String get zurCommunityEingeladen;

  /// No description provided for @communityErweiterung.
  ///
  /// In en, this message translates to:
  /// **'Community expansion'**
  String get communityErweiterung;

  /// No description provided for @familienmitgliedHinzufuegen.
  ///
  /// In en, this message translates to:
  /// **'add family member'**
  String get familienmitgliedHinzufuegen;

  /// No description provided for @hauptprofilWaehlen.
  ///
  /// In en, this message translates to:
  /// **'choose main profile'**
  String get hauptprofilWaehlen;

  /// No description provided for @familienprofilName.
  ///
  /// In en, this message translates to:
  /// **'family profile name'**
  String get familienprofilName;

  /// No description provided for @familienprofilAktivieren.
  ///
  /// In en, this message translates to:
  /// **'activate family profile ?'**
  String get familienprofilAktivieren;

  /// No description provided for @familienprofilBeschreibung.
  ///
  /// In en, this message translates to:
  /// **'If the family profile is activated, a unified profile will appear for each family member.\n\nThe world map no longer shows each family member individually, only the family profile.'**
  String get familienprofilBeschreibung;

  /// No description provided for @familyprofilInvite.
  ///
  /// In en, this message translates to:
  /// **'you have been invited to join the following family profile:'**
  String get familyprofilInvite;

  /// No description provided for @familie.
  ///
  /// In en, this message translates to:
  /// **'family'**
  String get familie;

  /// No description provided for @isImFamilienprofil.
  ///
  /// In en, this message translates to:
  /// **'is already in the family profile'**
  String get isImFamilienprofil;

  /// No description provided for @wurdeSchonEingeladen.
  ///
  /// In en, this message translates to:
  /// **'was already invited'**
  String get wurdeSchonEingeladen;

  /// No description provided for @istInEinemFamilienprofil.
  ///
  /// In en, this message translates to:
  /// **'is already in a family profile'**
  String get istInEinemFamilienprofil;

  /// No description provided for @familienprofilEingeladen.
  ///
  /// In en, this message translates to:
  /// **'has been invited to the family profile'**
  String get familienprofilEingeladen;

  /// No description provided for @istSchonMitgliedCommunity.
  ///
  /// In en, this message translates to:
  /// **' is already a member of the community'**
  String get istSchonMitgliedCommunity;

  /// No description provided for @wurdeSchonEingeladenCommunity.
  ///
  /// In en, this message translates to:
  /// **' has already been invited to the community'**
  String get wurdeSchonEingeladenCommunity;

  /// No description provided for @wurdeEingeladenCommunity.
  ///
  /// In en, this message translates to:
  /// **' was invited to the community'**
  String get wurdeEingeladenCommunity;

  /// No description provided for @familienprofilAnzeigen.
  ///
  /// In en, this message translates to:
  /// **'show family profile'**
  String get familienprofilAnzeigen;

  /// No description provided for @familienprofilUnvollstaendig.
  ///
  /// In en, this message translates to:
  /// **'to make the profile, the name and a main profile must be entered'**
  String get familienprofilUnvollstaendig;

  /// No description provided for @familyProfilloeschen.
  ///
  /// In en, this message translates to:
  /// **'delete family profile'**
  String get familyProfilloeschen;

  /// No description provided for @familyProfilWirklichLoeschen.
  ///
  /// In en, this message translates to:
  /// **'do you really want to delete the family profile?'**
  String get familyProfilWirklichLoeschen;

  /// No description provided for @neueCommunities.
  ///
  /// In en, this message translates to:
  /// **'new communities'**
  String get neueCommunities;

  /// No description provided for @alsFreundHinzugefuegt.
  ///
  /// In en, this message translates to:
  /// **' has added you as a friend'**
  String get alsFreundHinzugefuegt;

  /// No description provided for @freundOrtsWechsel.
  ///
  /// In en, this message translates to:
  /// **' is now in '**
  String get freundOrtsWechsel;

  /// No description provided for @familieInDeinemOrt.
  ///
  /// In en, this message translates to:
  /// **' is now in your location'**
  String get familieInDeinemOrt;

  /// No description provided for @hatNeueStadtinformation.
  ///
  /// In en, this message translates to:
  /// **' has a new information:'**
  String get hatNeueStadtinformation;

  /// No description provided for @newsSettingTitle.
  ///
  /// In en, this message translates to:
  /// **'News display'**
  String get newsSettingTitle;

  /// No description provided for @newsSettingFriendAdd.
  ///
  /// In en, this message translates to:
  /// **'added as a friend'**
  String get newsSettingFriendAdd;

  /// No description provided for @newsSettingFriendLocationChanged.
  ///
  /// In en, this message translates to:
  /// **'friend changed location'**
  String get newsSettingFriendLocationChanged;

  /// No description provided for @newsSettingNewFamilieLocation.
  ///
  /// In en, this message translates to:
  /// **'new family in your place'**
  String get newsSettingNewFamilieLocation;

  /// No description provided for @newsSettingShowMeetup.
  ///
  /// In en, this message translates to:
  /// **'interesting meetups'**
  String get newsSettingShowMeetup;

  /// No description provided for @newsSettingShowCityInformation.
  ///
  /// In en, this message translates to:
  /// **'new city information in my location'**
  String get newsSettingShowCityInformation;

  /// No description provided for @newsSettingShowTravelPlan.
  ///
  /// In en, this message translates to:
  /// **'new travel plan from friends'**
  String get newsSettingShowTravelPlan;

  /// No description provided for @friendNewTravelPlan.
  ///
  /// In en, this message translates to:
  /// **' has a new travel plan:'**
  String get friendNewTravelPlan;

  /// No description provided for @a2hsTitle.
  ///
  /// In en, this message translates to:
  /// **'families worldwide place on the home screen ?'**
  String get a2hsTitle;

  /// No description provided for @a2hsBody.
  ///
  /// In en, this message translates to:
  /// **'This will make the website look 100% like the app version'**
  String get a2hsBody;

  /// No description provided for @ja.
  ///
  /// In en, this message translates to:
  /// **'yes'**
  String get ja;

  /// No description provided for @nein.
  ///
  /// In en, this message translates to:
  /// **'no'**
  String get nein;

  /// No description provided for @frageTeilGemeinschaft.
  ///
  /// In en, this message translates to:
  /// **'Are you a contact person for this community ?'**
  String get frageTeilGemeinschaft;

  /// No description provided for @frageErstellerMeetup.
  ///
  /// In en, this message translates to:
  /// **'Are you the initiator of this meetup?'**
  String get frageErstellerMeetup;

  /// No description provided for @nichtTeilGemeinschaft.
  ///
  /// In en, this message translates to:
  /// **'The creator is not a part of this community'**
  String get nichtTeilGemeinschaft;

  /// No description provided for @nichtErstellerMeetup.
  ///
  /// In en, this message translates to:
  /// **'The creator is not the initiator of the meetup'**
  String get nichtErstellerMeetup;

  /// No description provided for @benutzerEingeben.
  ///
  /// In en, this message translates to:
  /// **'enter user'**
  String get benutzerEingeben;

  /// No description provided for @newOwnerIsInitiator.
  ///
  /// In en, this message translates to:
  /// **'Is the new meetup owner the initiator?'**
  String get newOwnerIsInitiator;

  /// No description provided for @nochKeineNewsVorhanden.
  ///
  /// In en, this message translates to:
  /// **'No news have been created for you yet'**
  String get nochKeineNewsVorhanden;

  /// No description provided for @meetupWiederholung.
  ///
  /// In en, this message translates to:
  /// **'Meetup repetition'**
  String get meetupWiederholung;

  /// No description provided for @meetupOeffentlichkeit.
  ///
  /// In en, this message translates to:
  /// **'Meetup public'**
  String get meetupOeffentlichkeit;

  /// No description provided for @keineNewsVorhanden.
  ///
  /// In en, this message translates to:
  /// **'No news yet'**
  String get keineNewsVorhanden;

  /// No description provided for @chatLoeschen.
  ///
  /// In en, this message translates to:
  /// **'delete Chat'**
  String get chatLoeschen;

  /// No description provided for @chatWirklichLoeschen.
  ///
  /// In en, this message translates to:
  /// **'Do you really want to delete / leave the chat ? '**
  String get chatWirklichLoeschen;

  /// No description provided for @chatsWirklichLoeschen.
  ///
  /// In en, this message translates to:
  /// **'Do you really want to delete / leave the chats ? '**
  String get chatsWirklichLoeschen;

  /// No description provided for @auchBeiLoeschen.
  ///
  /// In en, this message translates to:
  /// **'also delete for '**
  String get auchBeiLoeschen;

  /// No description provided for @antworten.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get antworten;

  /// No description provided for @textKopieren.
  ///
  /// In en, this message translates to:
  /// **'Copy text'**
  String get textKopieren;

  /// No description provided for @weiterleiten.
  ///
  /// In en, this message translates to:
  /// **'Forward'**
  String get weiterleiten;

  /// No description provided for @loeschenGross.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get loeschenGross;

  /// No description provided for @meldenGross.
  ///
  /// In en, this message translates to:
  /// **'Melden'**
  String get meldenGross;

  /// No description provided for @nachrichtZwischenAblage.
  ///
  /// In en, this message translates to:
  /// **'Message stored in clipboard'**
  String get nachrichtZwischenAblage;

  /// No description provided for @nachrichtGemeldet.
  ///
  /// In en, this message translates to:
  /// **'Message was reported'**
  String get nachrichtGemeldet;

  /// No description provided for @nachrichtBearbeiten.
  ///
  /// In en, this message translates to:
  /// **'Edit message'**
  String get nachrichtBearbeiten;

  /// No description provided for @bearbeitet.
  ///
  /// In en, this message translates to:
  /// **'edited'**
  String get bearbeitet;

  /// No description provided for @empfaengerWaehlen.
  ///
  /// In en, this message translates to:
  /// **'Select receiver'**
  String get empfaengerWaehlen;

  /// No description provided for @weitergeleitetVon.
  ///
  /// In en, this message translates to:
  /// **'Forwarded from '**
  String get weitergeleitetVon;

  /// No description provided for @weitergeleitet.
  ///
  /// In en, this message translates to:
  /// **'Forwarded'**
  String get weitergeleitet;

  /// No description provided for @angehefteteNachrichten.
  ///
  /// In en, this message translates to:
  /// **'Pinned messages'**
  String get angehefteteNachrichten;

  /// No description provided for @anheften.
  ///
  /// In en, this message translates to:
  /// **'Pin'**
  String get anheften;

  /// No description provided for @losloesen.
  ///
  /// In en, this message translates to:
  /// **'detach'**
  String get losloesen;

  /// No description provided for @stummEin.
  ///
  /// In en, this message translates to:
  /// **'Mute on'**
  String get stummEin;

  /// No description provided for @stummAus.
  ///
  /// In en, this message translates to:
  /// **'Mute off'**
  String get stummAus;

  /// No description provided for @chatEinstellung.
  ///
  /// In en, this message translates to:
  /// **'chat settings'**
  String get chatEinstellung;

  /// No description provided for @keineErgebnisse.
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get keineErgebnisse;

  /// No description provided for @schwarzesBrett.
  ///
  /// In en, this message translates to:
  /// **'Bulletin board'**
  String get schwarzesBrett;

  /// No description provided for @geloeschteNachricht.
  ///
  /// In en, this message translates to:
  /// **'deleted message'**
  String get geloeschteNachricht;

  /// No description provided for @alle.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get alle;

  /// No description provided for @private.
  ///
  /// In en, this message translates to:
  /// **'Private'**
  String get private;

  /// No description provided for @gruppen.
  ///
  /// In en, this message translates to:
  /// **'Groups'**
  String get gruppen;

  /// No description provided for @weltChat.
  ///
  /// In en, this message translates to:
  /// **'World Chat'**
  String get weltChat;

  /// No description provided for @teilnehmerSimple.
  ///
  /// In en, this message translates to:
  /// **' Participant'**
  String get teilnehmerSimple;

  /// No description provided for @gruppeVerlassen.
  ///
  /// In en, this message translates to:
  /// **'Leave group'**
  String get gruppeVerlassen;

  /// No description provided for @gruppeWirklichVerlassen.
  ///
  /// In en, this message translates to:
  /// **'Do you really want to leave the group?'**
  String get gruppeWirklichVerlassen;

  /// No description provided for @neuerChat.
  ///
  /// In en, this message translates to:
  /// **'New Chat'**
  String get neuerChat;

  /// No description provided for @gruppeBeitreten.
  ///
  /// In en, this message translates to:
  /// **'Join group'**
  String get gruppeBeitreten;

  /// No description provided for @globaleSuche.
  ///
  /// In en, this message translates to:
  /// **'Global search'**
  String get globaleSuche;

  /// No description provided for @uebersetzen.
  ///
  /// In en, this message translates to:
  /// **'Translate'**
  String get uebersetzen;

  /// No description provided for @uebersetzungSchliessen.
  ///
  /// In en, this message translates to:
  /// **'Close translation'**
  String get uebersetzungSchliessen;

  /// No description provided for @newsLocationBegruessung.
  ///
  /// In en, this message translates to:
  /// **'Welcome in '**
  String get newsLocationBegruessung;

  /// No description provided for @erfahrungenTeilen.
  ///
  /// In en, this message translates to:
  /// **'Share with other families your experience about the place'**
  String get erfahrungenTeilen;

  /// No description provided for @erfahrungenAnschauenUndTeilen.
  ///
  /// In en, this message translates to:
  /// **'Have a Look at the experiences of other families and complement them with your own experiences'**
  String get erfahrungenAnschauenUndTeilen;

  /// No description provided for @bildLadezeit.
  ///
  /// In en, this message translates to:
  /// **'Loading the image can take a little time'**
  String get bildLadezeit;

  /// No description provided for @nachrichtLoeschen.
  ///
  /// In en, this message translates to:
  /// **'delete message ?'**
  String get nachrichtLoeschen;

  /// No description provided for @nachrichtWirklichLoeschen.
  ///
  /// In en, this message translates to:
  /// **'Do you really want to delete this message ?'**
  String get nachrichtWirklichLoeschen;

  /// No description provided for @newsPageOnlineMeetupVorschlag.
  ///
  /// In en, this message translates to:
  /// **'Suggested to you because of the following interest: '**
  String get newsPageOnlineMeetupVorschlag;

  /// No description provided for @newsPageOfflineMeetupVorschlag.
  ///
  /// In en, this message translates to:
  /// **'New meetup in your location'**
  String get newsPageOfflineMeetupVorschlag;

  /// No description provided for @emailBestaetigen.
  ///
  /// In en, this message translates to:
  /// **'Email confirm'**
  String get emailBestaetigen;

  /// No description provided for @emailStimmtNichtUeberein.
  ///
  /// In en, this message translates to:
  /// **'Email does not match'**
  String get emailStimmtNichtUeberein;

  /// No description provided for @familienmitglieder.
  ///
  /// In en, this message translates to:
  /// **'Family members: '**
  String get familienmitglieder;

  /// No description provided for @hilfe.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get hilfe;

  /// No description provided for @hilfeVorschlag.
  ///
  /// In en, this message translates to:
  /// **'How can we help you ? \n\nPlease also provide us with your contact details (email, Telegram username or similar) so that we can contact you.'**
  String get hilfeVorschlag;

  /// No description provided for @ungeleseneNachrichten.
  ///
  /// In en, this message translates to:
  /// **'unread messages'**
  String get ungeleseneNachrichten;

  /// No description provided for @hilfeVersendetText.
  ///
  /// In en, this message translates to:
  /// **'Message sent - We will get back to you as soon as possible'**
  String get hilfeVersendetText;

  /// No description provided for @cities.
  ///
  /// In en, this message translates to:
  /// **'Locations'**
  String get cities;

  /// No description provided for @nochKeineStaedteVorhanden.
  ///
  /// In en, this message translates to:
  /// **'No cities selected yet'**
  String get nochKeineStaedteVorhanden;

  /// No description provided for @countries.
  ///
  /// In en, this message translates to:
  /// **'Countries'**
  String get countries;

  /// No description provided for @nochKeineCountriesVorhanden.
  ///
  /// In en, this message translates to:
  /// **'No countries selected yet'**
  String get nochKeineCountriesVorhanden;

  /// No description provided for @nochKeinegemeinschaftVorhanden.
  ///
  /// In en, this message translates to:
  /// **'No communities selected yet'**
  String get nochKeinegemeinschaftVorhanden;

  /// No description provided for @sucheKeineErgebnisse.
  ///
  /// In en, this message translates to:
  /// **'No results for the search query'**
  String get sucheKeineErgebnisse;

  /// No description provided for @stadtInformationen.
  ///
  /// In en, this message translates to:
  /// **'City information: '**
  String get stadtInformationen;

  /// No description provided for @kosten.
  ///
  /// In en, this message translates to:
  /// **'Costs: '**
  String get kosten;

  /// No description provided for @aktuellDort.
  ///
  /// In en, this message translates to:
  /// **'Currently there: '**
  String get aktuellDort;

  /// No description provided for @kopieren.
  ///
  /// In en, this message translates to:
  /// **'copy'**
  String get kopieren;

  /// No description provided for @informationKopiert.
  ///
  /// In en, this message translates to:
  /// **'Information has been copied'**
  String get informationKopiert;

  /// No description provided for @nutzungsbedingungen.
  ///
  /// In en, this message translates to:
  /// **'Terms of Use'**
  String get nutzungsbedingungen;

  /// No description provided for @datenschutzrichtlinie.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get datenschutzrichtlinie;

  /// No description provided for @dateiBeschaedigt.
  ///
  /// In en, this message translates to:
  /// **'File is damaged'**
  String get dateiBeschaedigt;

  /// No description provided for @benutzerNamevergeben.
  ///
  /// In en, this message translates to:
  /// **'User name is already taken'**
  String get benutzerNamevergeben;

  /// No description provided for @aktuellenOrtVerwenden.
  ///
  /// In en, this message translates to:
  /// **'Use current location'**
  String get aktuellenOrtVerwenden;

  /// No description provided for @keineEingabe.
  ///
  /// In en, this message translates to:
  /// **'Input field is empty'**
  String get keineEingabe;

  /// No description provided for @imUmkreis.
  ///
  /// In en, this message translates to:
  /// **' is in your surroundings'**
  String get imUmkreis;

  /// No description provided for @umkreis.
  ///
  /// In en, this message translates to:
  /// **'Surroundings'**
  String get umkreis;

  /// No description provided for @familieInRangeEmailErhalten.
  ///
  /// In en, this message translates to:
  /// **'receive new familie around you e-mails'**
  String get familieInRangeEmailErhalten;

  /// No description provided for @familieInRangeNotification.
  ///
  /// In en, this message translates to:
  /// **'new familie around notification'**
  String get familieInRangeNotification;

  /// No description provided for @neuenOrtEingeben.
  ///
  /// In en, this message translates to:
  /// **'Enter new location'**
  String get neuenOrtEingeben;

  /// No description provided for @socialMediaLinkAendern.
  ///
  /// In en, this message translates to:
  /// **'Change Social Media Link'**
  String get socialMediaLinkAendern;

  /// No description provided for @mitFreundenTeilen.
  ///
  /// In en, this message translates to:
  /// **'Share with friends'**
  String get mitFreundenTeilen;

  /// No description provided for @teilenLinkText.
  ///
  /// In en, this message translates to:
  /// **'The networking app for travel families'**
  String get teilenLinkText;

  /// No description provided for @karte.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get karte;

  /// No description provided for @notizeUeber.
  ///
  /// In en, this message translates to:
  /// **'Note about '**
  String get notizeUeber;

  /// No description provided for @notizEingeben.
  ///
  /// In en, this message translates to:
  /// **'Enter note'**
  String get notizEingeben;

  /// No description provided for @bildBearbeiten.
  ///
  /// In en, this message translates to:
  /// **'edit image'**
  String get bildBearbeiten;

  /// No description provided for @geheimerChat.
  ///
  /// In en, this message translates to:
  /// **'Secret chat'**
  String get geheimerChat;

  /// No description provided for @geheimerChatMeldung.
  ///
  /// In en, this message translates to:
  /// **'Private chat group - Members only'**
  String get geheimerChatMeldung;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @reiseplanungNotification.
  ///
  /// In en, this message translates to:
  /// **'New travel plan'**
  String get reiseplanungNotification;

  /// No description provided for @tag.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get tag;

  /// No description provided for @monat.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get monat;

  /// No description provided for @jahr.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get jahr;

  /// No description provided for @genauesDatum.
  ///
  /// In en, this message translates to:
  /// **'Accurate date'**
  String get genauesDatum;

  /// No description provided for @bisDatumFalsch.
  ///
  /// In en, this message translates to:
  /// **'End date must be greater than the start date'**
  String get bisDatumFalsch;

  /// No description provided for @zeitraumSuche.
  ///
  /// In en, this message translates to:
  /// **'Period selection'**
  String get zeitraumSuche;

  /// No description provided for @vollesDatumEingeben.
  ///
  /// In en, this message translates to:
  /// **'enter full date'**
  String get vollesDatumEingeben;

  /// No description provided for @hinzufuegen.
  ///
  /// In en, this message translates to:
  /// **'add'**
  String get hinzufuegen;

  /// No description provided for @verlassen.
  ///
  /// In en, this message translates to:
  /// **'leave'**
  String get verlassen;

  /// No description provided for @aboutAppText.
  ///
  /// In en, this message translates to:
  /// **'Families worldwide was created to connect people. Everyone can be as anonymous as they want. There is no commercial background. Your data will not be shared or sold.\n\nThereby there is no budget for advertising and it is up to you, the community, if this app will grow in popularity over the years or not.\n\nThe code of the app is publicly available. Only the php files for the database link are under lock and key for security reasons.\n\nIf you miss a function in the app, you found a bug or a process does not run as fast / well as you would like, then write me a feedback or write me directly in the support chat of the app (both can be found under Settings).\n\nI am very happy about donations to cover the running costs of the app.\n\nThank you very much for your support\n\nDominik Mast'**
  String get aboutAppText;

  /// No description provided for @titelEingeben.
  ///
  /// In en, this message translates to:
  /// **'Enter title'**
  String get titelEingeben;

  /// No description provided for @beschreibungEingeben.
  ///
  /// In en, this message translates to:
  /// **'Enter description'**
  String get beschreibungEingeben;

  /// No description provided for @bulletinNoteLoeschen.
  ///
  /// In en, this message translates to:
  /// **'delete note'**
  String get bulletinNoteLoeschen;

  /// No description provided for @note.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get note;

  /// No description provided for @weltweit.
  ///
  /// In en, this message translates to:
  /// **'worldwide'**
  String get weltweit;

  /// No description provided for @bild.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get bild;

  /// No description provided for @sprachnachricht.
  ///
  /// In en, this message translates to:
  /// **'Sprachnachricht'**
  String get sprachnachricht;

  /// No description provided for @tooltipLinkKopieren.
  ///
  /// In en, this message translates to:
  /// **'Copy link for paste in Chat'**
  String get tooltipLinkKopieren;

  /// No description provided for @tooltipChatErsteller.
  ///
  /// In en, this message translates to:
  /// **'Open chat with the creator'**
  String get tooltipChatErsteller;

  /// No description provided for @tooltipMehrOptionen.
  ///
  /// In en, this message translates to:
  /// **'Open menu with more options'**
  String get tooltipMehrOptionen;

  /// No description provided for @tooltipMeetupDetailsVerwaltung.
  ///
  /// In en, this message translates to:
  /// **'Managing people who can see Meetup details'**
  String get tooltipMeetupDetailsVerwaltung;

  /// No description provided for @tooltipMehrInformationen.
  ///
  /// In en, this message translates to:
  /// **'Öffnet ein Fenster mit mehr Informationen zu diesem Thema'**
  String get tooltipMehrInformationen;

  /// No description provided for @tooltipInformationPage.
  ///
  /// In en, this message translates to:
  /// **'From here you can get to the following pages: Meetups, Communities, Location Info, Country Info and Bulletin Board'**
  String get tooltipInformationPage;

  /// No description provided for @tooltipChatPage.
  ///
  /// In en, this message translates to:
  /// **'To the overview of the chat system'**
  String get tooltipChatPage;

  /// No description provided for @tooltipWeltkarte.
  ///
  /// In en, this message translates to:
  /// **'To the world map view'**
  String get tooltipWeltkarte;

  /// No description provided for @tooltipNewsPage.
  ///
  /// In en, this message translates to:
  /// **'To view all information from friends'**
  String get tooltipNewsPage;

  /// No description provided for @tooltipSettingPage.
  ///
  /// In en, this message translates to:
  /// **'For all profile settings and app information'**
  String get tooltipSettingPage;

  /// No description provided for @tooltipChatBenutzer.
  ///
  /// In en, this message translates to:
  /// **'Open chat with user'**
  String get tooltipChatBenutzer;

  /// No description provided for @tooltipNotizBenutzerAngelegen.
  ///
  /// In en, this message translates to:
  /// **'Create a note about the user'**
  String get tooltipNotizBenutzerAngelegen;

  /// No description provided for @tooltipZeigFreunde.
  ///
  /// In en, this message translates to:
  /// **'Show only friends'**
  String get tooltipZeigFreunde;

  /// No description provided for @tooltipZeigeMeetups.
  ///
  /// In en, this message translates to:
  /// **'Show all Meetups'**
  String get tooltipZeigeMeetups;

  /// No description provided for @tooltipZeigeGemeinschaften.
  ///
  /// In en, this message translates to:
  /// **'Show all communities'**
  String get tooltipZeigeGemeinschaften;

  /// No description provided for @tooltipZeigeReiseplanungen.
  ///
  /// In en, this message translates to:
  /// **'Show all travel plans'**
  String get tooltipZeigeReiseplanungen;

  /// No description provided for @tooltipZeigeInsiderInfos.
  ///
  /// In en, this message translates to:
  /// **'Show all places / countries info'**
  String get tooltipZeigeInsiderInfos;

  /// No description provided for @tooltipZeigeEigenenFilter.
  ///
  /// In en, this message translates to:
  /// **'Filter yourself what is displayed'**
  String get tooltipZeigeEigenenFilter;

  /// No description provided for @tooltipOeffneWeltchat.
  ///
  /// In en, this message translates to:
  /// **'Open world chat'**
  String get tooltipOeffneWeltchat;

  /// No description provided for @tooltipOpenNewsSettings.
  ///
  /// In en, this message translates to:
  /// **'Open news pages setting'**
  String get tooltipOpenNewsSettings;

  /// No description provided for @tooltipOpenMeetupPage.
  ///
  /// In en, this message translates to:
  /// **'To the overview of all Meetups'**
  String get tooltipOpenMeetupPage;

  /// No description provided for @tooltipOpenCommunityPage.
  ///
  /// In en, this message translates to:
  /// **'To the overview of all communities'**
  String get tooltipOpenCommunityPage;

  /// No description provided for @tooltipOpenCityPage.
  ///
  /// In en, this message translates to:
  /// **'To the overview of all locations'**
  String get tooltipOpenCityPage;

  /// No description provided for @tooltipOpenCountryPage.
  ///
  /// In en, this message translates to:
  /// **'To the overview of all countries'**
  String get tooltipOpenCountryPage;

  /// No description provided for @tooltipOpenBulletinBoardPage.
  ///
  /// In en, this message translates to:
  /// **'To the overview of all bulletin board notes'**
  String get tooltipOpenBulletinBoardPage;

  /// No description provided for @tooltipChatPageSuche.
  ///
  /// In en, this message translates to:
  /// **'Activate chat search'**
  String get tooltipChatPageSuche;

  /// No description provided for @tooltipCreateNewChat.
  ///
  /// In en, this message translates to:
  /// **'Create new chat'**
  String get tooltipCreateNewChat;

  /// No description provided for @tooltipShowOwnProfil.
  ///
  /// In en, this message translates to:
  /// **'Show how others see my profile'**
  String get tooltipShowOwnProfil;

  /// No description provided for @gemeinschaftWurdeGeloescht.
  ///
  /// In en, this message translates to:
  /// **'Community was deleted'**
  String get gemeinschaftWurdeGeloescht;

  /// No description provided for @meetupWurdeGeloescht.
  ///
  /// In en, this message translates to:
  /// **'Meetup was deleted'**
  String get meetupWurdeGeloescht;

  /// No description provided for @tooltipSprachnachrichtAufnehmen.
  ///
  /// In en, this message translates to:
  /// **'Record voice message'**
  String get tooltipSprachnachrichtAufnehmen;

  /// No description provided for @tooltipBildSenden.
  ///
  /// In en, this message translates to:
  /// **'Select and send image'**
  String get tooltipBildSenden;

  /// No description provided for @tooltipMeetupErstellen.
  ///
  /// In en, this message translates to:
  /// **'Create Meetup'**
  String get tooltipMeetupErstellen;

  /// No description provided for @tooltipMeetupSuche.
  ///
  /// In en, this message translates to:
  /// **'Show and search all Meetups'**
  String get tooltipMeetupSuche;

  /// No description provided for @tooltipGetMeetupInformation.
  ///
  /// In en, this message translates to:
  /// **'Request for Meetup Information'**
  String get tooltipGetMeetupInformation;

  /// No description provided for @tooltipRemoveMeetupInformationRequest.
  ///
  /// In en, this message translates to:
  /// **'Withdraw request for Meetup information'**
  String get tooltipRemoveMeetupInformationRequest;

  /// No description provided for @tooltipEingabeBestaetigen.
  ///
  /// In en, this message translates to:
  /// **'Confirm entry'**
  String get tooltipEingabeBestaetigen;

  /// No description provided for @tooltipCommunityErstellen.
  ///
  /// In en, this message translates to:
  /// **'Create community'**
  String get tooltipCommunityErstellen;

  /// No description provided for @tooltipCommunitySuche.
  ///
  /// In en, this message translates to:
  /// **'Show and search all communities'**
  String get tooltipCommunitySuche;

  /// No description provided for @tooltipOrtChatOeffnen.
  ///
  /// In en, this message translates to:
  /// **'To the place chat'**
  String get tooltipOrtChatOeffnen;

  /// No description provided for @tooltipNotizErstellen.
  ///
  /// In en, this message translates to:
  /// **'Create note'**
  String get tooltipNotizErstellen;

  /// No description provided for @tooltipNotizSuche.
  ///
  /// In en, this message translates to:
  /// **'Show and search all notes'**
  String get tooltipNotizSuche;

  /// No description provided for @tooltipSpracheWechseln.
  ///
  /// In en, this message translates to:
  /// **'Switch language'**
  String get tooltipSpracheWechseln;

  /// No description provided for @tooltipZeigeProfilErsteller.
  ///
  /// In en, this message translates to:
  /// **'To creator profile'**
  String get tooltipZeigeProfilErsteller;

  /// No description provided for @tooltipNotizBearbeiten.
  ///
  /// In en, this message translates to:
  /// **'Edit note'**
  String get tooltipNotizBearbeiten;

  /// No description provided for @tooltipNotizLoeschen.
  ///
  /// In en, this message translates to:
  /// **'Delete note'**
  String get tooltipNotizLoeschen;

  /// No description provided for @keinAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account ? '**
  String get keinAccount;

  /// No description provided for @oderWeiterMit.
  ///
  /// In en, this message translates to:
  /// **'Or continue with'**
  String get oderWeiterMit;

  /// No description provided for @bereitsMitglied.
  ///
  /// In en, this message translates to:
  /// **'Already a member ? '**
  String get bereitsMitglied;

  /// No description provided for @anmelden.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get anmelden;

  /// No description provided for @accountErstellen.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get accountErstellen;

  /// No description provided for @persoenlicheDaten.
  ///
  /// In en, this message translates to:
  /// **'Personal data'**
  String get persoenlicheDaten;

  /// No description provided for @woSeidIhrImMoment.
  ///
  /// In en, this message translates to:
  /// **'Where are you at the moment ?'**
  String get woSeidIhrImMoment;

  /// No description provided for @wieSeidIhrUnterwegs.
  ///
  /// In en, this message translates to:
  /// **'How are you traveling ?'**
  String get wieSeidIhrUnterwegs;

  /// No description provided for @welcheSprachenSprechtIhr.
  ///
  /// In en, this message translates to:
  /// **'What languages do you speak ?'**
  String get welcheSprachenSprechtIhr;

  /// No description provided for @wieAltSindEureKinder.
  ///
  /// In en, this message translates to:
  /// **'How old are your children ?'**
  String get wieAltSindEureKinder;

  /// No description provided for @infoZumAlterDerKinder.
  ///
  /// In en, this message translates to:
  /// **'The exact date of your children is not shown publicly, it is only used to calculate the displayed age'**
  String get infoZumAlterDerKinder;

  /// No description provided for @welcheThemenInteressierenEuch.
  ///
  /// In en, this message translates to:
  /// **'What topics are you interested in ?'**
  String get welcheThemenInteressierenEuch;

  /// No description provided for @beschreibungEuererFamilie.
  ///
  /// In en, this message translates to:
  /// **'Description of your family - optional'**
  String get beschreibungEuererFamilie;

  /// No description provided for @weiter.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get weiter;

  /// No description provided for @fertig.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get fertig;

  /// No description provided for @zurueck.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get zurueck;

  /// No description provided for @benutzernameEingeben.
  ///
  /// In en, this message translates to:
  /// **'Benutzername eingeben'**
  String get benutzernameEingeben;

  /// No description provided for @familienMerkmale.
  ///
  /// In en, this message translates to:
  /// **'Family features'**
  String get familienMerkmale;

  /// No description provided for @jahre.
  ///
  /// In en, this message translates to:
  /// **'Years'**
  String get jahre;

  /// No description provided for @chatNotificationHinweis.
  ///
  /// In en, this message translates to:
  /// **'Turning off will no longer display notifications triggered by chat'**
  String get chatNotificationHinweis;

  /// No description provided for @meetupNotificationHinweis.
  ///
  /// In en, this message translates to:
  /// **'Turning off will no longer display notifications triggered by the Meetup'**
  String get meetupNotificationHinweis;

  /// No description provided for @newFriendNotificationHinweis.
  ///
  /// In en, this message translates to:
  /// **'By turning it off, there is no more notification when someone adds you as a friend'**
  String get newFriendNotificationHinweis;

  /// No description provided for @travelPlanNotificationHinweis.
  ///
  /// In en, this message translates to:
  /// **'By switching off, you will no longer be shown notifications from friends'**
  String get travelPlanNotificationHinweis;

  /// No description provided for @familieAroundNotificationHinweis.
  ///
  /// In en, this message translates to:
  /// **'By switching off, you will no longer receive a notification when a family comes near you'**
  String get familieAroundNotificationHinweis;

  /// No description provided for @tooltipLandInfoOeffnen.
  ///
  /// In en, this message translates to:
  /// **'open land information'**
  String get tooltipLandInfoOeffnen;

  /// No description provided for @supportFamiliesWorldwide.
  ///
  /// In en, this message translates to:
  /// **'Support families worldwide'**
  String get supportFamiliesWorldwide;

  /// No description provided for @keineSchwarzeBrettZettelVorhanden.
  ///
  /// In en, this message translates to:
  /// **'No notes have been created yet'**
  String get keineSchwarzeBrettZettelVorhanden;

  /// No description provided for @keineSchwarzeBrettZettelGefunden.
  ///
  /// In en, this message translates to:
  /// **'No notes found'**
  String get keineSchwarzeBrettZettelGefunden;

  /// No description provided for @privateProfilNotize.
  ///
  /// In en, this message translates to:
  /// **'private note'**
  String get privateProfilNotize;

  /// No description provided for @freundEntfernen1.
  ///
  /// In en, this message translates to:
  /// **'Do you really want to take'**
  String get freundEntfernen1;

  /// No description provided for @freundEntfernen2.
  ///
  /// In en, this message translates to:
  /// **'off your friendlist?'**
  String get freundEntfernen2;

  /// No description provided for @freundHinzufuegen1.
  ///
  /// In en, this message translates to:
  /// **'Do you really want to add'**
  String get freundHinzufuegen1;

  /// No description provided for @freundHinzufuegen2.
  ///
  /// In en, this message translates to:
  /// **'to your friendlist?'**
  String get freundHinzufuegen2;

  /// No description provided for @locationBewertung.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get locationBewertung;

  /// No description provided for @bewerten1.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get bewerten1;

  /// No description provided for @bewerten2.
  ///
  /// In en, this message translates to:
  /// **''**
  String get bewerten2;

  /// No description provided for @aendern.
  ///
  /// In en, this message translates to:
  /// **'change'**
  String get aendern;

  /// No description provided for @deinKommentar.
  ///
  /// In en, this message translates to:
  /// **'your comment'**
  String get deinKommentar;

  /// No description provided for @bewertungen.
  ///
  /// In en, this message translates to:
  /// **'Reviews: '**
  String get bewertungen;

  /// No description provided for @gesamt.
  ///
  /// In en, this message translates to:
  /// **'total'**
  String get gesamt;

  /// No description provided for @familienfreundlich.
  ///
  /// In en, this message translates to:
  /// **'family friendly'**
  String get familienfreundlich;

  /// No description provided for @sicherheit.
  ///
  /// In en, this message translates to:
  /// **'security'**
  String get sicherheit;

  /// No description provided for @freundlichkeit.
  ///
  /// In en, this message translates to:
  /// **'kindness'**
  String get freundlichkeit;

  /// No description provided for @umlandNatur.
  ///
  /// In en, this message translates to:
  /// **'surrounding'**
  String get umlandNatur;

  /// No description provided for @aktivitaeten.
  ///
  /// In en, this message translates to:
  /// **'activities'**
  String get aktivitaeten;

  /// No description provided for @alternativeLebensmittel.
  ///
  /// In en, this message translates to:
  /// **'alternative food'**
  String get alternativeLebensmittel;

  /// No description provided for @kommentare.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get kommentare;

  /// No description provided for @bewerten.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get bewerten;

  /// No description provided for @ortBewerten.
  ///
  /// In en, this message translates to:
  /// **'Review location'**
  String get ortBewerten;

  /// No description provided for @klimatabelle.
  ///
  /// In en, this message translates to:
  /// **'Climate chart'**
  String get klimatabelle;

  /// No description provided for @bestaetigen.
  ///
  /// In en, this message translates to:
  /// **'confim'**
  String get bestaetigen;

  /// No description provided for @ortBesuchtTitle.
  ///
  /// In en, this message translates to:
  /// **'location visited ?'**
  String get ortBesuchtTitle;

  /// No description provided for @ortBesuchtBody1.
  ///
  /// In en, this message translates to:
  /// **'You have already been to'**
  String get ortBesuchtBody1;

  /// No description provided for @ortBesuchtBody2.
  ///
  /// In en, this message translates to:
  /// **'and want to add yourself ?'**
  String get ortBesuchtBody2;

  /// No description provided for @ortNichtBesuchtTitle.
  ///
  /// In en, this message translates to:
  /// **'location not visited ?'**
  String get ortNichtBesuchtTitle;

  /// No description provided for @ortNichtBesuchtBody1.
  ///
  /// In en, this message translates to:
  /// **'You have been added to'**
  String get ortNichtBesuchtBody1;

  /// No description provided for @ortNichtBesuchtBody2.
  ///
  /// In en, this message translates to:
  /// **'by mistake and want to remove yourself again ?'**
  String get ortNichtBesuchtBody2;

  /// No description provided for @klickForLabel.
  ///
  /// In en, this message translates to:
  /// **'add Meetuplabel'**
  String get klickForLabel;

  /// No description provided for @besitzer.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get besitzer;

  /// No description provided for @bewertungAendern.
  ///
  /// In en, this message translates to:
  /// **'change rating'**
  String get bewertungAendern;

  /// No description provided for @zumLogin.
  ///
  /// In en, this message translates to:
  /// **'to login'**
  String get zumLogin;

  /// No description provided for @eineOptionMussAusgewaehltSein.
  ///
  /// In en, this message translates to:
  /// **'one option must be selected'**
  String get eineOptionMussAusgewaehltSein;

  /// No description provided for @standortHinweis.
  ///
  /// In en, this message translates to:
  /// **'With your location, it\'s up to you how accurate you want to be. The country is the least accurate and the city/village the most accurate.'**
  String get standortHinweis;

  /// No description provided for @profilErstellenGreeting.
  ///
  /// In en, this message translates to:
  /// **'Nice that you want to become a member of families worldwide community.\nThe profile creation will take ~3 min.'**
  String get profilErstellenGreeting;

  /// No description provided for @entfernen.
  ///
  /// In en, this message translates to:
  /// **'remove'**
  String get entfernen;

  /// No description provided for @eigenesProfil.
  ///
  /// In en, this message translates to:
  /// **'own Profil'**
  String get eigenesProfil;

  /// No description provided for @noteMelden.
  ///
  /// In en, this message translates to:
  /// **'Note melden'**
  String get noteMelden;

  /// No description provided for @noteMeldenFrage.
  ///
  /// In en, this message translates to:
  /// **'Why do you want to report the note ?'**
  String get noteMeldenFrage;

  /// No description provided for @inaktiveKartenHinweis.
  ///
  /// In en, this message translates to:
  /// **'Inactive users (3+ months) are \nnot displayed on the Map'**
  String get inaktiveKartenHinweis;

  /// No description provided for @adminDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'This message has been deleted by the admin for the following reason'**
  String get adminDeleteMessage;

  /// No description provided for @tooltipGroupChatOpen.
  ///
  /// In en, this message translates to:
  /// **'Open group chat'**
  String get tooltipGroupChatOpen;

  /// No description provided for @showFull.
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get showFull;

  /// No description provided for @standortBestimmungBeschreibung.
  ///
  /// In en, this message translates to:
  /// **'You can set whether and how exactly your location is tracked when you open the app and made visible to everyone'**
  String get standortBestimmungBeschreibung;

  /// No description provided for @standortBestimmungsButtonText.
  ///
  /// In en, this message translates to:
  /// **'Activate location determination'**
  String get standortBestimmungsButtonText;

  /// No description provided for @profilBild.
  ///
  /// In en, this message translates to:
  /// **'Profile image'**
  String get profilBild;

  /// No description provided for @profilBildButtonText.
  ///
  /// In en, this message translates to:
  /// **'Set up profile picture'**
  String get profilBildButtonText;

  /// No description provided for @profilBildBeschreibung.
  ///
  /// In en, this message translates to:
  /// **'Add a picture of your family so that the other families can get a better picture of you'**
  String get profilBildBeschreibung;

  /// No description provided for @planungAnlegen.
  ///
  /// In en, this message translates to:
  /// **'Create plan'**
  String get planungAnlegen;

  /// No description provided for @reiseplanungBeschreibung.
  ///
  /// In en, this message translates to:
  /// **'Add your next travel destinations so that other families know what you are up to. \n\nOn the world map you can see where other families will be at a certain time.'**
  String get reiseplanungBeschreibung;

  /// No description provided for @cityCountryInformation.
  ///
  /// In en, this message translates to:
  /// **'City und Country Information'**
  String get cityCountryInformation;

  /// No description provided for @socialMedia.
  ///
  /// In en, this message translates to:
  /// **'Social Media'**
  String get socialMedia;

  /// No description provided for @socialMediaBeschreibung.
  ///
  /// In en, this message translates to:
  /// **'Füge deine Social Media Links deinem Profil hinzu, damit es für andere Familien sichtbar ist'**
  String get socialMediaBeschreibung;

  /// No description provided for @addLink.
  ///
  /// In en, this message translates to:
  /// **'Add Link'**
  String get addLink;

  /// No description provided for @support.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;

  /// No description provided for @supportBeschreibung.
  ///
  /// In en, this message translates to:
  /// **'If you like the app, support the app through the following actions \n\n- Tell other families about the app \n- Create city-country information, meetups or communities\n- Donate'**
  String get supportBeschreibung;

  /// No description provided for @bulletinWirklichLoeschen.
  ///
  /// In en, this message translates to:
  /// **'Do you really want to delete the note?'**
  String get bulletinWirklichLoeschen;

  /// No description provided for @tooltipCancelEditNote.
  ///
  /// In en, this message translates to:
  /// **'cancel editing'**
  String get tooltipCancelEditNote;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
