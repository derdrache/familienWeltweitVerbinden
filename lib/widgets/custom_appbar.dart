import 'package:familien_suche/global/global_functions.dart';
import 'package:familien_suche/widgets/profil_image.dart';
import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  var title;
  var buttons;
  var elevation;
  var onTap;
  var leading;
  var profilBildProfil;
  var withLeading;

  CustomAppBar(
      {Key key,
      this.title,
      this.buttons,
      this.elevation = 4.0,
      this.withLeading = true,
      this.onTap,
      this.leading,
      this.profilBildProfil})
      : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(60.0);

  @override
  Widget build(BuildContext context) {
    buttons ??= <Widget>[];

    return AppBar(
      titleSpacing: 0,
      leading: leading == null
          ? null
          : leading.runtimeType == IconButton ? leading : Builder(
        builder: (BuildContext context) {
          return IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              changePage(context, leading);
            },
            tooltip:
            MaterialLocalizations.of(context).openAppDrawerTooltip,
          );
        },
      ),
      title: SizedBox(
        height: 50,
        child: Row(children: [
          if (profilBildProfil != null)
            Padding(
                padding: const EdgeInsets.only(top: 3, right: 10),
                child: ProfilImage(
                  profilBildProfil,
                  fullScreenWindow: true,
                )),
          Expanded(
            child: InkWell(
              onTap: onTap,
              child: Text(title,
                  overflow: TextOverflow.fade,
                  style: const TextStyle(color: Colors.white, fontSize: 20)),
            ),
          )
        ]),
      ),
      backgroundColor: Theme.of(context).colorScheme.primary,
      elevation: elevation,
      iconTheme: const IconThemeData(color: Colors.white),
      actions: buttons,
      automaticallyImplyLeading: withLeading,
    );
  }
}
