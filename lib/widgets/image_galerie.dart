import 'dart:convert';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../global/custom_widgets.dart';
import '../services/database.dart';

class ImageGalerie extends StatefulWidget {
  var id;
  var isCreator;
  var child;

  ImageGalerie({
    Key key,
    this.child,
    this.id,
    this.isCreator
  }) : super(key: key);

  @override
  _ImageGalerieState createState() => _ImageGalerieState();
}

class _ImageGalerieState extends State<ImageGalerie> {
  var isWebDesktop = kIsWeb && (defaultTargetPlatform != TargetPlatform.iOS || defaultTargetPlatform != TargetPlatform.android);
  double fontsize;
  List<Widget> allImages = [];
  var ownPictureKontroller = TextEditingController();
  var selected = "";
  var windowSetState;
  var imagePaths;

  @override
  void initState() {
    fontsize = isWebDesktop? 12 : 16;

    _initImages();

    super.initState();
  }

  Future _initImages() async {

    final manifestContent = await rootBundle.loadString('AssetManifest.json');

    final Map<String, dynamic> manifestMap = json.decode(manifestContent);

    imagePaths = manifestMap.keys
        .where((String key) => key.contains('assets/bilder/'))
        .where((String key) => key.contains('.jpg'))
        .toList();


    setState(() {});
  }

  saveChanges(){
    if(selected == "" && ownPictureKontroller.text == ""){
      customSnackbar(context, AppLocalizations.of(context).bitteBildAussuchen);
      return;
    }

    if(selected == "") selected = ownPictureKontroller.text;

    widget.child = Image.asset(selected, fit: BoxFit.fitWidth);
    setState(() {});
    EventDatabase().updateOne(widget.id, "bild", selected);
    Navigator.pop(context);

  }


  @override
  Widget build(BuildContext context) {

    showImages() {
      List<Widget> allImages = [];

      for(var image in imagePaths){
        var imageDecode = Uri.decodeComponent(image);

        allImages.add(
            InkWell(
              child: Container(
                  margin: EdgeInsets.all(5),
                  decoration: BoxDecoration(
                      border: Border.all(
                          width: selected == imageDecode ? 3: 1,
                          color: selected == imageDecode ? Colors.green : Colors.black
                      )
                  ),
                  child:Image.asset(imageDecode, fit: BoxFit.fill, width: 80, height: 60)
              ),
              onTap: () {
                selected = imageDecode;
                windowSetState(() {

                });
              },
            )
        );
      }

      return Container(
          child: Wrap(
            children: allImages,
          )
      );
    }

    _closeWindow(){
      Navigator.pop(context);
    }

    windowHeader(){
      return Container(
        margin: const EdgeInsets.only(top: 10),
        child: Row(
          children: [
            Expanded(
              child: Center(
                  child: Text(
                    AppLocalizations.of(context).eventBildAendern,
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold
                    ),
                  )
              ),
            )
          ],
        ),
      );
    }

    ownLinkInput(){
      return Container(
          width: 200,
          child: customTextInput(
              "Eigenes Bild - Link eingeben",
              ownPictureKontroller,
              onSubmit: () {
                allImages.add(
                    Image.network(ownPictureKontroller.text, fit: BoxFit.fill, width: 80, height: 60)
                );
                selected = ownPictureKontroller.text;

                ownPictureKontroller.clear();
                windowSetState(() {

                });
              }
          )
      );
    }

    windowOptions(){
      return Container(
        margin: const EdgeInsets.only(right: 10),
        child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                child: Text(AppLocalizations.of(context).abbrechen, style: TextStyle(fontSize: fontsize)),
                onPressed: () => Navigator.pop(context),
              ),
              TextButton(
                  child: Text(AppLocalizations.of(context).speichern, style: TextStyle(fontSize: fontsize)),
                  onPressed: () => saveChanges()
              ),
            ]
        ),
      );
    }

    windowCloseButton(){
      return Positioned(
        height: 30,
        right: -13,
        top: -7,
        child: InkResponse(
            onTap: () => _closeWindow(),
            child: const CircleAvatar(
              child: Icon(Icons.close, size: 16,),
              backgroundColor: Colors.red,
            )
        ),
      );
    }

    return InkWell(
      child: Container(
        constraints: BoxConstraints(
            minHeight: 200,
        ),
        width: double.infinity,
        child:widget.child,
      ),
      onTap:!widget.isCreator ? null :   () => showDialog(
          context: context,
          builder: (BuildContext buildContext){
            return StatefulBuilder(
                builder: (context, setState) {
                  windowSetState = setState;
                  return AlertDialog(
                    shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(20.0))
                    ),
                    contentPadding: EdgeInsets.zero,
                    content: SizedBox(
                      height: 500,
                      width: 600,
                      child: Stack(
                        overflow: Overflow.visible,
                        children: [
                          ScrollConfiguration(
                            behavior: ScrollConfiguration.of(context).copyWith(dragDevices: {
                              PointerDeviceKind.touch,
                              PointerDeviceKind.mouse,
                            }),
                            child: Container(
                              margin: EdgeInsets.only(left: 10),
                              child: ListView(
                                children: [
                                  windowHeader(),
                                  SizedBox(height: 10),
                                  showImages(),
                                  SizedBox(height: 20),
                                  ownLinkInput(),
                                  SizedBox(height: 20),
                                  windowOptions()
                                ],
                              ),
                            ),
                          ),
                          windowCloseButton()
                        ] ,
                      ),
                    ),

                  );
                }
            );
          }
      ),
    );

  }
}
