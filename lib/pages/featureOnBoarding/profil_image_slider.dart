import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../../functions/upload_and_save_image.dart';
import '../../widgets/profil_image.dart';


class ProfilImageSlider extends StatefulWidget {
  const ProfilImageSlider({super.key});

  @override
  State<ProfilImageSlider> createState() => _ProfilImageSliderState();
}

class _ProfilImageSliderState extends State<ProfilImageSlider> {
  @override
  Widget build(BuildContext context) {
    Map userProfil = Hive.box("secureBox").get("ownProfil");
    bool noImage = userProfil["bild"] == null || userProfil["bild"].isEmpty;

    addProfilImage() async {
      var newImage = await uploadAndSaveImage(context, "profil");

      setState(() {
        userProfil[newImage];
      });
    }

    return Container(
      margin: const EdgeInsets.only(left: 20, right: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if(noImage) Center(child:
          Image.asset("assets/icons/profil_image_icon.png",
              width: 150, height: 150),),
          if(!noImage) Center(child: ProfilImage(userProfil, size: 80, onlyFullScreen: false,),),
          const SizedBox(height: 30),
          Text(AppLocalizations.of(context)!.profilBild,
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          Text(AppLocalizations.of(context)!.profilBildBeschreibung,
            style: const TextStyle(fontSize: 20),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 100),
          FloatingActionButton.extended(
            onPressed: () => addProfilImage(),
            label: Text(AppLocalizations.of(context)!.profilBildButtonText, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),),
          ),
        ],
      ),
    );
  }
}

