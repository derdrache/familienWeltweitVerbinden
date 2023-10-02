import 'package:flutter/material.dart';

import '../global/style.dart' as style;

class SearchAutocomplete extends StatefulWidget {
  List<String> searchableItems;
  Function? onConfirm;
  String hintText;
  Function? onRemove;
  Function? onClose;
  var selected = "";
  final TextEditingController _textEditingController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  SearchAutocomplete(
      {Key? key,
      required this.searchableItems,
      this.onConfirm,
      this.onRemove,
      this.onClose,
      this.hintText = ""})
      : super(key: key);

  getSelected() {
    if (selected.isEmpty) return [];

    return [selected];
  }

  getInput() {
    return _textEditingController.text;
  }

  clearInput() {
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
          borderRadius:
              const BorderRadius.all(Radius.circular(style.roundedCorners)),
          border: Border.all()),
      child: Stack(
        children: [
          RawAutocomplete(
            optionsViewBuilder: (BuildContext context,
                void Function(Object) onSelected, Iterable<Object> options) {
              return Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      width: MediaQuery.of(context).size.width - 21,
                      height: 300,
                      decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(),
                          borderRadius:
                              BorderRadius.circular(style.roundedCorners)),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(10.0),
                        itemCount: options.length,
                        itemBuilder: (BuildContext context, int index) {
                          final String option =
                              options.elementAt(index) as String;
                          return GestureDetector(
                            onTap: () {
                              onSelected(option);
                              widget.selected = option;
                              if (widget.onConfirm != null) {
                                widget.onConfirm!();
                              }
                            },
                            child: ListTile(
                              title: Text(option,
                                  style: const TextStyle(color: Colors.black)),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              );
            },
            optionsBuilder: (TextEditingValue textEditingValue) {
              return textEditingValue.text.isNotEmpty
                  ? widget.searchableItems.where((item) => item
                      .toLowerCase()
                      .contains(textEditingValue.text.toLowerCase()))
                  : <String>[];
            },
            fieldViewBuilder: (BuildContext context,
                TextEditingController textEditingController,
                FocusNode focusNode,
                VoidCallback onFieldSubmitted) {
              return TextFormField(
                controller: textEditingController,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: widget.hintText,
                  contentPadding: const EdgeInsets.all(10.0),
                  suffixIcon: textEditingController.text.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            textEditingController.clear();
                            if (widget.onClose != null) widget.onClose!();

                            setState(() {});
                          },
                          icon: const Icon(
                            Icons.clear,
                            color: Colors.red,
                          ),
                        ),
                ),
                focusNode: focusNode,
                onChanged: (value) async {
                  if (value.isEmpty) {
                    widget.selected = "";
                    if (widget.onRemove != null) widget.onRemove!();
                  }
                  setState(() {});
                },
                onFieldSubmitted: (String value) {
                  widget.selected = value;
                  if (widget.onConfirm != null) {
                    widget.onConfirm!();
                  }
                  onFieldSubmitted();
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
