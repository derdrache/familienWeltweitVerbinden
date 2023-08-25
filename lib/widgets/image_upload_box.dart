import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../functions/upload_and_save_image.dart';
import '../services/database.dart';
import 'dialogWindow.dart';

class ImageUploadBox extends StatefulWidget {
  String imageKategorie;
  int numerImages;
  List? uploadedImages;
  List images = [null, null, null, null];

  ImageUploadBox({
    Key? key,
    required this.imageKategorie,
    this.numerImages = 4,
    this.uploadedImages
  });

  getImages(){
    return images.whereType<String>().toList();
  }

  @override
  State<ImageUploadBox> createState() => _ImageUploadBoxState();
}

class _ImageUploadBoxState extends State<ImageUploadBox> {

  @override
  void initState() {
    setImages();

    super.initState();
  }

  setImages(){
    if(widget.uploadedImages == null || widget.uploadedImages!.isEmpty) return;

    widget.images = List.of(widget.uploadedImages!);
    for (var i = widget.images.length; i < widget.numerImages; i++) {
      widget.images.add(null);
    }
  }

  imageFullscreen(image) {
    showDialog(
        context: context,
        builder: (BuildContext buildContext) {
          return CustomAlertDialog(
            windowPadding: const EdgeInsets.all(30),
            children: [CachedNetworkImage(imageUrl: image,)],
          );
        });
  }

  uploadImage() async {
    var imageList =
    await uploadAndSaveImage(context, "notes", folder: "notes/");

    for (var i = 0; i < widget.images.length; i++) {
      if (widget.images[i] == null) {
        widget.images[i] = imageList[0];
        break;
      }
    }

    setState(() {});
  }

  getPath(){
    if(widget.imageKategorie == "note"){
      return "notes/";
    }else if(widget.imageKategorie == "chat"){
      return "chats/";
    }else if(widget.imageKategorie == "information"){
      return "insiderInfo";
    }

    return "";
  }

  deleteImage(imageIndex) {
    var image = widget.images[imageIndex];
    String path = getPath();
    dbDeleteImage(image, imagePath: path);

    widget.images[imageIndex] = null;
  }

  @override
  Widget build(BuildContext context) {

    setImages() {
      List<Widget> imageWidgets = [];

      widget.images.asMap().forEach((index, value) {
        imageWidgets.add(InkWell(
          onTap: value == null
              ? () => uploadImage()
              : () => imageFullscreen(value),
          child: Stack(
            children: [
              Container(
                margin: const EdgeInsets.all(5),
                width: 80,
                height: 80,
                decoration:
                BoxDecoration(border: Border.all(), color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey
                    : Colors.white),
                child: value == null
                    ? IconButton(
                    onPressed: () => uploadImage(),
                    icon: const Icon(Icons.upload))
                    : CachedNetworkImage(imageUrl: value,),
              ),
              if (value != null)
                Positioned(
                  top: 0,
                  right: 0,
                  child: InkWell(
                    onTap: () {
                      deleteImage(index);
                      setState(() {});
                    },
                    child: const CircleAvatar(
                        radius: 12.0,
                        backgroundColor: Colors.red,
                        child:
                        Icon(Icons.close, color: Colors.white, size: 18)),
                  ),
                )
            ],
          ),
        ));
      });

      return Container(
        margin: const EdgeInsets.all(5),
        child: Wrap(children: imageWidgets),
      );
    }

    return setImages();
  }
}
