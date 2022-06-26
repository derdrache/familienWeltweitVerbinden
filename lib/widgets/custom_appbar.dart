import 'package:familien_suche/global/global_functions.dart';
import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  var title;
  var buttons;
  var elevation;
  var onTap;
  var leading;

  CustomAppBar({
    Key key,
    this.title,
    this.buttons,
    this.elevation = 4.0,
    this.onTap,
    this.leading
  }) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(60.0);

  @override
  Widget build(BuildContext context) {
    buttons ??= <Widget>[];

    return AppBar(
      leading: leading == null ? null : Builder(
        builder: (BuildContext context) {
          return IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () { changePage(context, leading); },
            tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
          );
        },
      ),
      title: InkWell(
          onTap: onTap,
          child: Row(
              children: [
                Flexible(
                  child: SizedBox(
                      height: 50,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                            title,
                            overflow: TextOverflow.fade,
                            style: const TextStyle(color: Colors.white, fontSize: 20)
                        ),
                      )
                  ),
                )
              ]
          )
      ),
      backgroundColor: Theme.of(context).colorScheme.primary,
      elevation: elevation,
      iconTheme: const IconThemeData(
          color: Colors.white
      ),
      actions: buttons,
    );
  }
}