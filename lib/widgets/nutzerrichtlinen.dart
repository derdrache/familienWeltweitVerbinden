import 'dart:io';
import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../windows/dialog_window.dart';

class NutzerrichtlinenAnzeigen extends StatelessWidget {
  final String page;
  final bool isGerman = kIsWeb
      ? PlatformDispatcher.instance.locale.languageCode == "de"
      : Platform.localeName == "de_DE";

  NutzerrichtlinenAnzeigen({Key? key,  required this.page}) : super(key: key);

  getPageClickOn() {
    if (page == "register") {
      return isGerman ? "Registrieren " : "Sign up ";
    } else if (page == "login") {
      return "Login ";
    } else if (page == "create") {
      return isGerman ? "Erstellen oder Speichern " : "Create or Save ";
    }
  }

  @override
  Widget build(BuildContext context) {
    double fontSize = 12;
    var startText = isGerman
        ? "Ich akzeptiere die families worldwide "
        : "I accept the families worldwide ";

    var getNotifications = isGerman
        ? " und stimmen zu, Benachrichtigungen zu erhalten"
        : " and agree to receive notifications";

    termsOfUseWindow() {
      showDialog(
          context: context,
          builder: (BuildContext buildContext) {
            return CustomAlertDialog(
                title: AppLocalizations.of(context)!.nutzungsbedingungen,
                children: [ isGerman
                  ? const Text("""Indem Sie auf unser Angebot zugreifen bestätigen Sie, dass Sie diese Nutzungsbedingungen annehmen. Wenn Sie nicht zustimmen, sind Sie nicht berechtigt, auf unsere Angebote zuzugreifen oder diese zu nutzen.

Sie erhalten innerhab der families worldwide App verschiedene Möglichkeiten eigene Inhalte zu erstellen. Jeder von Ihnen erstellte Inhalt wird automatisch mit anderen Usern geteilt.
Möglichkeiten für eigene Inhalte:
- Profil - 'Über uns'
- Event erstellen
- Gemeinschaft erstellen
- Stadt- /Landinformation erstellen

Sie sind für alle von ihnen veröffentlichten Inhalte selber verantwortlich. Families worldwide kontrolliert die eingestellten Inhalte nicht systematisch.
Sie verpflichten sich insbesondere, keine Inhalte zu erstellen, welche gegen geltendes Recht verstossen und/oder Rechte Dritter (z.B.Urheber-, Marken- oder Persönlichkeitsrechte) verletzen.  

Darüber hinaus unterlassen Sie das Anbieten und die Verlinkung von folgenden Inhalten:
-  urheberrechtlich geschützte Inhalte, wenn keine Berechtigung zur Nutzung vorliegt (z.B. Fotos, zu deren Veröffentlichung im Internet der Fotograf und / oder eine abgebildete Person nicht eingewilligt hat)
-  falsche Tatsachenbehauptungen
-  rassistische, fremdenfeindliche, diskriminierende oder beleidigende Inhalte
-  pornografische oder nicht jugendfreie Inhalte
-  gewaltdarstellende Inhalte, Verherrlichung krimineller Handlungen; Verherrlichung von Drogen oder anderen illegalen Suchtmitteln

Families worldwide ist berechtigt, den User-Account eines Nutzers ohne Angabe von Gründen und ohne Einhaltung von Fristen jederzeit zu sperren sowie die publizierten Inhalte zu löschen. Dies gilt insbesondere bei Kenntnisnahme einer Nichtbeachtung der obigen Verpflichtungen. 

Alle Nutzer verpflichten sich, die Families worldwide von jeglicher Haftung und von allen Verpflichtungen, Aufwendungen und Ansprüchen, die sich aus Schäden wegen übler Nachrede, Beleidigung, Verletzung von Persönlichkeitsrechten, wegen des Ausfalls von Dienstleistungen für Nutzer, wegen der Verletzung von immateriellen Gütern oder sonstigen Rechten ergeben, freizustellen. Die dem Dienst bzw. seinen Mitarbeitenden und/oder Dritten diesbezüglich entstehenden Kosten einer angemessenen Rechtsverteidigung und -verfolgung gegenüber den Dritten trägt der Nutzer.
                  """)
                  : const Text("""By accessing our Offerings, you confirm that you accept these Terms of Use. If you do not agree, you are not authorized to access or use our Offerings.

You will have several opportunities to create your own content within the families worldwide app. Any content you create will automatically be shared with other users.
Possibilities for own content:
- Profile - 'About us'
- Create event
- Create community
- Create city / country information

You are responsible for all content you post. Families worldwide does not systematically control the posted content.
In particular, you undertake not to create content that violates applicable law and/or infringes the rights of third parties (e.g. copyright, trademark or personal rights).  

Furthermore, you refrain from offering and linking the following content:
- copyrighted content if there is no authorization to use it (e.g. photos that the photographer and / or a person depicted has not agreed to be published on the Internet)
- false statements of fact
- racist, xenophobic, discriminatory or offensive content
- pornographic or adult content
- content depicting violence, glorification of criminal acts; glorification of drugs or other illegal addictive substances.

Families worldwide is entitled to block the user account of a user at any time without giving reasons and without observing deadlines as well as to delete the published contents. This applies in particular if Families worldwide becomes aware of a failure to comply with the above obligations. 

All users commit themselves to exempt the Families worldwide from any liability and from all obligations, expenses and claims resulting from damages due to defamation, insult, violation of personal rights, due to the failure of services for users, due to the violation of immaterial goods or other rights. The costs incurred by the Service or its employees and/or third parties in this regard for reasonable legal defense and prosecution against the third parties shall be borne by the User.    
                  """)
                ]);
          });
    }

    termsOfUse() {
      return TextSpan(
          text: AppLocalizations.of(context)!.nutzungsbedingungen,
          recognizer: TapGestureRecognizer()..onTap = () => termsOfUseWindow(),
          style: TextStyle(
              fontSize: fontSize,
              color: Colors.black,
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.underline));
    }

    return Container(
        margin: const EdgeInsets.all(15),
        child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(children: [
          TextSpan(
              text: startText,
              style: TextStyle(fontSize: fontSize, color: Colors.black,)),
          termsOfUse(),
          if (page == "register")
            TextSpan(
                text: getNotifications,
                style: TextStyle(fontSize: fontSize, color: Colors.black))
        ])));
  }
}
