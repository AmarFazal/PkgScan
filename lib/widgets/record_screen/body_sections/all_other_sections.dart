import 'package:flutter/material.dart';

import '../../../helpers/validation_helper.dart';
import '../../../services/record_service.dart';
import '../../attribute_widgets.dart';
import '../../expandable_widget.dart';

class AllOtherSections extends StatefulWidget {
  final Map<String, dynamic> entity;
  final Map<String, String> imageValues;
  final Map<String, bool> dynamicBooleans;
  final Map<String, TextEditingController> controllers;
  final Map<String, dynamic> oldImageValues;
  final Map<String, dynamic> oldBooleanValues;
  final String entitiesId;
  final String? recordId;
  final String header;
  final bool isExpanded;
  final VoidCallback onToggle;
  final bool isNew;

  const AllOtherSections(
      {super.key,
      required this.entity,
      required this.imageValues,
      required this.dynamicBooleans,
      required this.controllers,
      required this.oldImageValues,
      required this.oldBooleanValues,
      required this.entitiesId,
      required this.recordId,
      required this.header,
      required this.isExpanded,
      required this.onToggle, required this.isNew});

  @override
  State<AllOtherSections> createState() => _AllOtherSectionsState();
}

class _AllOtherSectionsState extends State<AllOtherSections> {
  @override
  Widget build(BuildContext context) {
    final recordService = RecordService();
    final validationHelper = ValidationHelper(recordService);
    return buildExpandableSection(
      title: widget.header,
      isExpanded: widget.isExpanded,
      onToggle: widget.onToggle,
      children: widget.entity!['groupedAttributes'][widget.header]
          .map<Widget>((attribute) {
        return AttributeWidgets.buildAttributeWidget(
          context: context,
          attribute: attribute,
          header: widget.header,
          controllers: widget.controllers,
          dynamicBooleans: widget.dynamicBooleans,
          imageValues: widget.imageValues,
          oldImageValues: widget.oldImageValues,
          entitiesId: widget.entity!["_id"],
          recordId: widget.recordId,
          isNew: widget.isNew,
          onChanged: (value) {
            setState(() {
              widget.dynamicBooleans[attribute['name']] = value;
            });
            validationHelper.checkBooleanForChanges(
              key: attribute['name'],
              newValue: {attribute['name']: value},
              oldBooleanValues: widget.oldBooleanValues,
              entitiesId: widget.entitiesId,
              recordId: widget.recordId,
              context: context,
              updateState: () => setState(() {}),
            );
          },
          onDelete: () {
            setState(() {
              widget.oldImageValues[attribute['name']] =
                  widget.imageValues[attribute['name']] = '';
              validationHelper.checkImageForChanges(
                key: attribute['name'],
                newValue: {attribute['name']: ''},
                imageValues: widget.imageValues,
                oldImageValues: widget.oldImageValues,
                entitiesId: widget.entitiesId,
                recordId: widget.recordId,
                context: context,
                updateState: () => setState(() {}),
              );
            });
          },
        );
      }).toList(),
      context: context,
    );
  }
}
