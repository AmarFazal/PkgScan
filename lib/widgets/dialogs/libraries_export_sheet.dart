import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xls;
import 'package:csv/csv.dart';

import '../snack_bar.dart';

void showLibrariesExportSheet(
  BuildContext context,
  Map<String, dynamic> data,
  List<dynamic> allData,
) {
  showModalBottomSheet(
    isScrollControlled: true,
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
    ),
    backgroundColor: Colors.white,
    builder: (BuildContext context) {
      return LibrariesExportSheet(
        data: data,
        allData: allData,
      );
    },
  );
}

class LibrariesExportSheet extends StatefulWidget {
  final Map<String, dynamic> data;
  final List<dynamic> allData;
  const LibrariesExportSheet({
    super.key,
    required this.data,
    required this.allData,
  });

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
              onPressed: () => _showExportOptions(),
              child: const Text('Tamam'),
            ),
          ],
        ),
      ),
    );
  }

  List<String> getSelectedData() {
    return checkboxStates.keys
        .where((key) => checkboxStates[key] == true)
        .toList();
  }

  void _showExportOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.table_chart),
              title: const Text('Excel olarak dışa aktar'),
              onTap: () async {
                List<String> selectedData = getSelectedData();
                await exportToExcel(selectedData, widget.allData);
                Navigator.pop(context); // İlk modalı kapat
                Navigator.pop(context); // İkinci modalı kapat
              },
            ),
            ListTile(
              leading: const Icon(Icons.file_copy),
              title: const Text('CSV olarak dışa aktar'),
              onTap: () async {
                List<String> selectedData = getSelectedData();
                await exportToCsv(selectedData, widget.allData);
                Navigator.pop(context); // İlk modalı kapat
                Navigator.pop(context); // İkinci modalı kapat
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> exportToExcel(
      List<String> selectedKeys, List<dynamic> allData) async {
    if (!await _checkPermissions()) return;
    if (allData.isEmpty) {
      showSnackBar(context, 'Dışa aktarılacak kayıt bulunamadı.');
      return;
    }

    final xls.Workbook workbook = xls.Workbook();
    final xls.Worksheet sheet = workbook.worksheets[0];

    for (int i = 0; i < selectedKeys.length; i++) {
      sheet.getRangeByIndex(1, i + 1).setText(selectedKeys[i]);
    }

    for (int rowIndex = 0; rowIndex < allData.length; rowIndex++) {
      var record = allData[rowIndex];
      for (int colIndex = 0; colIndex < selectedKeys.length; colIndex++) {
        var value = record[selectedKeys[colIndex]];

        if (value is String) {
          sheet.getRangeByIndex(rowIndex + 2, colIndex + 1).setText(value);
        } else if (value is num) {
          sheet
              .getRangeByIndex(rowIndex + 2, colIndex + 1)
              .setNumber(value.toDouble());
        } else {
          sheet.getRangeByIndex(rowIndex + 2, colIndex + 1).setText('');
        }
      }
    }

    final file = await _getFilePath('excel_${_formattedDateTime()}.xlsx');
    final List<int> bytes = workbook.saveAsStream();
    await file.writeAsBytes(bytes);

    showSnackBar(context, 'Excel dışa aktarımı başarılı: ${file.path}');
    workbook.dispose();
  }

  Future<void> exportToCsv(
      List<String> selectedKeys, List<dynamic> allData) async {
    if (!await _checkPermissions()) return;
    if (allData.isEmpty) {
      showSnackBar(context, 'Dışa aktarılacak kayıt bulunamadı.');
      return;
    }

    List<List<dynamic>> rows = [];
    rows.add(selectedKeys);

    for (var record in allData) {
      rows.add(selectedKeys.map((key) => record[key] ?? '').toList());
    }

    String csvData = const ListToCsvConverter().convert(rows);
    final file = await _getFilePath('data_${_formattedDateTime()}.csv');
    await file.writeAsString(csvData);

    showSnackBar(context, 'CSV dışa aktarımı başarılı: ${file.path}');
  }

  Future<bool> _checkPermissions() async {
    if (await Permission.storage.request().isGranted ||
        await Permission.manageExternalStorage.request().isGranted) {
      return true;
    } else {
      openAppSettings();
      showSnackBar(context, 'Depolama izni gerekli.');
      return false;
    }
  }

  Future<File> _getFilePath(String fileName) async {
    final downloadsDirectory = Directory('/storage/emulated/0/Download');
    return File('${downloadsDirectory.path}/$fileName');
  }

  String _formattedDateTime() {
    final now = DateTime.now();
    return '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
  }
}
