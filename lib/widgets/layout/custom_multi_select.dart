import 'package:familien_suche/widgets/layout/custom_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../global/style.dart' as style;

class CustomMultiTextForm extends StatefulWidget {
  List auswahlList;
  List? selected;
  String hintText;
  Function? onConfirm;
  EdgeInsets? margin;

  getSelected(){
    return selected;
  }


  CustomMultiTextForm({Key? key,
    required this.auswahlList,
    this.selected,
    this.hintText = "",
    this.onConfirm,
    this.margin
  }) : super(key: key);

  @override
  State<CustomMultiTextForm> createState() => _CustomMultiTextFormState();
}

class _CustomMultiTextFormState extends State<CustomMultiTextForm> {

  @override
  void initState() {
    widget.onConfirm ??= (){};
    widget.selected ??= [];
    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    changeSelectToList(select){
      widget.selected = select;
      if(select.isNotEmpty) widget.onConfirm!();
      setState(() {});
    }

    return Container(
      width: style.webWidth,
      margin: widget.margin ?? const EdgeInsets.all(style.sideSpace),
      decoration: BoxDecoration(
          border: Border.all(color: Colors.black),
          borderRadius: BorderRadius.circular(style.roundedCorners)
      ),
      child: MultiSelectDialogField(
        decoration: const BoxDecoration(),
        initialValue: widget.selected!,
        buttonIcon: Icon(Icons.arrow_downward, color: Colors.black),
        items: widget.auswahlList.map((e) => MultiSelectItem(e, e)).toList(),
        listType: MultiSelectListType.LIST,
        searchable: true,
        onConfirm: changeSelectToList,
        onSelectionChanged: changeSelectToList,
        buttonText: Text(widget.hintText, style: const TextStyle(color: Colors.grey),),
        chipDisplay: MultiSelectChipDisplay(
          onTap: (value){

            if(widget.selected!.length == 1){
              customSnackBar(context, AppLocalizations.of(context)!.eineOptionMussAusgewaehltSein);
              return null;
            }


            setState(() {
              widget.selected!.remove(value);
            });

            widget.onConfirm!();

            return widget.selected;
          },
        ),
      ),
    );
  }
}