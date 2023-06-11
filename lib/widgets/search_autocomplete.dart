import 'package:flutter/material.dart';

class SearchAutocomplete extends StatefulWidget {
  List<String> searchableItems;
  Function? onConfirm;
  String hintText;
  Function? onRemove;
  var selected = "";
  final TextEditingController _textEditingController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  SearchAutocomplete(
      {Key? key,
      required this.searchableItems,
      this.onConfirm,
      this.onRemove,
      this.hintText = ""}) : super(key: key);

  getSelected() {
    if (selected.isEmpty) return [];

    return [selected];
  }

  getInput(){
    return _textEditingController.text;
  }

  clearInput(){
    _focusNode.unfocus();
    _textEditingController.clear();
  }

  @override
  State<SearchAutocomplete> createState() => _SearchAutocompleteState();
}

class _SearchAutocompleteState extends State<SearchAutocomplete> {
  var filterList = [];


  @override
  Widget build(BuildContext context) {

    return Container(
      margin: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
          borderRadius: const BorderRadius.all(Radius.circular(5)),
          border: Border.all()
      ),
      child: Stack(
        children: [
          RawAutocomplete(
            optionsViewBuilder: (BuildContext context, void Function(Object) onSelected, Iterable<Object> options) {
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  child: Container(
                    width: MediaQuery.of(context).size.width - 21,
                    height: 300,
                    decoration: const BoxDecoration(
                        border: Border(
                            left: BorderSide(),
                            right: BorderSide(),
                            bottom: BorderSide()
                        )
                    ),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(10.0),
                      itemCount: options.length,
                      itemBuilder: (BuildContext context, int index) {
                        final String option = options.elementAt(index) as String;
                        return GestureDetector(
                          onTap: () {
                            onSelected(option);
                            widget.selected = option;
                            if (widget.onConfirm != null){
                              widget.onConfirm!();
                            }
                          },
                          child: ListTile(
                            title: Text(option, style: const TextStyle(color: Colors.black)),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
            optionsBuilder: (TextEditingValue textEditingValue) {
              return textEditingValue.text.isNotEmpty ? widget.searchableItems.where((item) => item.toLowerCase()
                  .contains(textEditingValue.text.toLowerCase())) : <String>[];
            },
            fieldViewBuilder: (BuildContext context,
                TextEditingController textEditingController,
                FocusNode focusNode,
                VoidCallback onFieldSubmitted) {
              return TextFormField(
                controller: textEditingController,
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  contentPadding: const EdgeInsets.all(10.0),
                ),
                focusNode: focusNode,
                onChanged: (value){
                  if(value.isEmpty){
                    widget. selected = "";
                    if(widget.onRemove != null) widget.onRemove!();
                  }
                  setState(() {

                  });
                },
                onFieldSubmitted: (String value) {
                  onFieldSubmitted();
                },
              );
            },
          ),
          if(widget._textEditingController.text.isNotEmpty) Positioned(
              right: 0, top: 0,
              child: CloseButton(
                color: Colors.red,
                onPressed: (){
                  widget.clearInput();
                  if(widget.onRemove != null) widget.onRemove!();
                  setState(() {});
                },
              ))
        ],
      ),
    );
  }
}




