import 'dart:developer';
import 'package:flutter/material.dart';

void showLibrariesExportSheet(
    BuildContext context,
    Map<String, dynamic> data,
    ) {
  showModalBottomSheet(
    isScrollControlled: true,
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
    ),
    backgroundColor: Colors.white,
    builder: (BuildContext context) {
      return LibrariesExportSheet(data: data);
    },
  );
}

class LibrariesExportSheet extends StatefulWidget {
  final Map<String, dynamic> data;

  const LibrariesExportSheet({Key? key, required this.data}) : super(key: key);

  @override
  _LibrariesExportSheetState createState() => _LibrariesExportSheetState();
}

class _LibrariesExportSheetState extends State<LibrariesExportSheet> {
  late Map<String, bool> checkboxStates;

  @override
  void initState() {
    super.initState();

    checkboxStates = widget.data.keys.fold<Map<String, bool>>({}, (map, key) {
      map[key] = false;
      return map;
    });
  }

  @override
  Widget build(BuildContext context) {
    List<String> keys = widget.data.keys.toList();

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.8,
      child: Padding(
        padding: EdgeInsets.only(
          left: 16.0,
          right: 16.0,
          top: 16.0,
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: keys.map((key) {
                      return Row(
                        children: [
                          Checkbox(
                            value: checkboxStates[key],
                            onChanged: (bool? value) {
                              setState(() {
                                checkboxStates[key] = value ?? false;
                              });
                              log('$key checked: $value');
                            },
                          ),
                          Expanded(
                            child: Text(
                              key,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                log("Selected values: $checkboxStates");
                Navigator.pop(context);
              },
              child: const Text('Tamam'),
            ),
          ],
        ),
      ),
    );
  }
}