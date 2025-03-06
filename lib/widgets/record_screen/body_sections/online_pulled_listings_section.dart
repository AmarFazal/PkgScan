import 'package:flutter/material.dart';

import '../../../constants/text_constants.dart';
import '../../custom_center_title_button.dart';
import '../../custom_fields.dart';
import '../../entries_image_container.dart';
import '../../expandable_widget.dart';
import '../../snack_bar.dart';

class OnlinePulledListingsSection extends StatefulWidget {
  final Map<String, TextEditingController> controllers;
  final Map<String, String> imageValues;
  final List<bool> isExpandedList;
  final bool isExpanded;
  final List<Map<String, String>> combinedList;
  final VoidCallback onToggle;

  const OnlinePulledListingsSection({
    super.key,
    required this.controllers,
    required this.imageValues,
    required this.isExpandedList,
    required this.isExpanded,
    required this.combinedList,
    required this.onToggle,
  });

  @override
  State<OnlinePulledListingsSection> createState() =>
      _OnlinePulledListingsSectionState();
}

class _OnlinePulledListingsSectionState
    extends State<OnlinePulledListingsSection> {
  @override
  Widget build(BuildContext context) {
    return buildExpandableSection(
      title: 'Online Pulled Listings',
      isExpanded: widget.isExpanded,
      onToggle: widget.onToggle,
      children: widget.combinedList.asMap().entries.map<Widget>((entry) {
        int index = entry.key;
        int correctIndex = index == 1
            ? 10
            : index == 0
                ? 1
                : index;
        Map<String, String> listing = entry.value;
        return buildExpandableSection(
          title: 'Pulled Listing ${index + 1}',
          isExpanded: index + 1 < widget.isExpandedList.length
              ? widget.isExpandedList[index + 1]
              : false,
          onToggle: () {
            setState(() {
              if (index + 1 < widget.isExpandedList.length) {
                widget.isExpandedList[index + 1] =
                    !widget.isExpandedList[index + 1];
              }
            });
          },
          children: [
            listing['image'] != null && listing['image']!.isNotEmpty
                ? EntriesImageContainer(
                    label: TextConstants.onlineImage,
                    imageUrl: listing['image']!,
                    onTapExport: () {
                      setState(() {
                        widget.controllers['Pulled Images']?.text =
                            listing['image'] ?? '';
                        widget.imageValues['Pulled Images'] =
                            listing['image'] ?? '';
                      });
                      showSnackBar(context: context,
                          message: TextConstants.pulledImageUpdatedInMainInformation);
                    })
                : const SizedBox.shrink(),
            CustomFieldWithoutIcon(
              label: TextConstants.msrp,
              controller: TextEditingController(text: listing['msrp']),
              onChanged: (value) {
                widget.controllers['MSRP ${correctIndex}']?.text = value;
              },
              onTapExport: () {
                setState(() {
                  widget.controllers['MSRP']?.text = listing['msrp'] ?? '';
                });
                showSnackBar(
                   context:  context, message: TextConstants.msrpUpdatedInMainInformation);
              },
            ),
            CustomFieldWithoutIcon(
              label: TextConstants.title,
              controller: TextEditingController(text: listing['title']),
              onChanged: (value) {
                widget.controllers['Title ${correctIndex}']?.text = value;
              },
              onTapExport: () {
                setState(() {
                  widget.controllers['Title']?.text = listing['title'] ?? '';
                });
                showSnackBar(
                   context:  context, message: TextConstants.titleUpdatedInMainInformation);
              },
            ),
            CustomCenterTitleButton(
              title: TextConstants.keepAllData,
              icon: Icons.check_circle,
              onTap: () {
                setState(() {
                  widget.controllers['Title']?.text = listing['title'] ?? '';
                  widget.controllers['MSRP']?.text = listing['msrp'] ?? '';
                  widget.controllers['Pulled Images']?.text =
                      listing['image'] ?? '';
                  widget.imageValues['Pulled Images'] = listing['image'] ?? '';
                });
                showSnackBar(
                   context: context, message: TextConstants.dataUpdatedInMainInformation);
              },
            ),
          ],
          context: context,
        );
      }).toList(),
      context: context,
    );
  }
}
