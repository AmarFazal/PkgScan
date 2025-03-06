import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/text_constants.dart';
import '../../../helpers/validation_helper.dart';
import '../../../services/handle_image_upload.dart';
import '../../../services/record_service.dart';
import '../../header_icon.dart';
import '../../snack_bar.dart';

class ManualImagesSection extends StatefulWidget {
  final Map<String, dynamic> entity;
  final Map<String, String> imageValues;
  final Map<String, dynamic> oldImageValues;
  final Map<String, bool> isLoadingMap;
  final String entitiesId;
  final String? recordId;
  final Future<void> Function() fetchRecordData;
  final bool isNew;

  ManualImagesSection({
    super.key,
    required this.entity,
    required this.imageValues,
    required this.oldImageValues,
    required this.entitiesId,
    required this.recordId,
    required this.isLoadingMap,
    required this.fetchRecordData,
    required this.isNew,
  });

  @override
  State<ManualImagesSection> createState() => _ManualImagesSectionState();
}

class _ManualImagesSectionState extends State<ManualImagesSection> {
  @override
  Widget build(BuildContext context) {
    final recordService = RecordService();
    final validationHelper = ValidationHelper(recordService);
    return Container(
      margin: const EdgeInsets.only(
        top: 0,
        bottom: 20,
      ),
      padding: const EdgeInsets.only(
        top: 0,
        bottom: 10,
      ),
      decoration: BoxDecoration(
        color: AppColors.secondaryColor,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 14, top: 8),
            child: Text(
              "Manual Images",
              style: Theme.of(context)
                  .textTheme
                  .displaySmall
                  ?.copyWith(color: AppColors.textColor, fontSize: 13),
            ),
          ),
          SizedBox(
            height: 200, // Fotoğrafların yüksekliği
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount:
                  widget.entity!['groupedAttributes']['Manual Images'].length +
                      1,
              itemBuilder: (context, index) {
                List<String> emptyAttributeNames = [];

                // Boş attribute'ları kontrol et ve listeyi doldur
                for (var attribute in widget.entity!['groupedAttributes']
                    ['Manual Images']) {
                  final attributeName = attribute['name'];
                  final imageValue = widget.imageValues[attributeName];
                  if ((imageValue == null || imageValue.isEmpty) &&
                      attributeName.contains("Manual Image")) {
                    emptyAttributeNames.add(attributeName);
                  }
                }

                if (index ==
                    widget
                        .entity!['groupedAttributes']['Manual Images'].length) {
                  // Son eleman, Add Image butonu olacak
                  return GestureDetector(
                    onTap: () async {
                      final List<String>? uploadedImageUrls =
                          await handleImageUpload(
                        context,
                        widget.entitiesId,
                        widget.recordId,
                        emptyAttributeNames,
                        widget.oldImageValues,
                        widget.imageValues,
                        (attributeName, imageUrl) {
                          setState(() {
                            widget.imageValues[attributeName] = imageUrl;
                          });
                        },
                        widget.isLoadingMap,
                        widget.isNew,
                      );

                      if (uploadedImageUrls != null) {
                        await widget.fetchRecordData();
                      } else {
                        showSnackBar(context: context,
                            message: "Image upload failed or canceled. Please Try Again.");
                      }
                    },
                    child: Container(
                      width: 150,
                      height: 200,
                      margin: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        image: const DecorationImage(
                          image: AssetImage("assets/images/background_1.png"),
                          fit: BoxFit.cover,
                        ),
                        color: Colors.white.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add_a_photo,
                              size: 40, color: AppColors.primaryColor),
                          const SizedBox(height: 5),
                          Text(
                            TextConstants.addImage,
                            style: Theme.of(context)
                                .textTheme
                                .displayMedium
                                ?.copyWith(color: AppColors.primaryColor),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            TextConstants.youHave +
                                emptyAttributeNames.length.toString() +
                                TextConstants.photosLeft,
                            style: Theme.of(context)
                                .textTheme
                                .displaySmall
                                ?.copyWith(color: AppColors.textColor),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final attribute =
                    widget.entity!['groupedAttributes']['Manual Images'][index];
                final imageUrl = widget.imageValues[attribute['name']];

                if (imageUrl == null || imageUrl.isEmpty) {
                  return Container();
                }

                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Stack(
                    children: [
                      GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => Dialog(
                              backgroundColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(25),
                                    child: Image.network(imageUrl,
                                        fit: BoxFit.contain),
                                  ),
                                  Positioned(
                                    top: 20,
                                    right: 20,
                                    child: HeaderIcon(
                                      icon: Icons.close_rounded,
                                      onTap: () => Navigator.pop(context),
                                      iconColor: Colors.white,
                                      color: Colors.black38,
                                      iconSize: 15,
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 20,
                                    right: 20,
                                    child: HeaderIcon(
                                      icon: Icons.delete,
                                      onTap: () {
                                        setState(() {
                                          widget.oldImageValues[
                                                  attribute['name']] =
                                              widget.imageValues[
                                                  attribute['name']] = '';
                                        });
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
                                        Navigator.pop(context);
                                      },
                                      iconColor: Colors.white,
                                      color: Colors.black38,
                                      iconSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            width: 150,
                            height: 200,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 5,
                        right: 5,
                        child: SizedBox(
                          height: 20,
                          width: 20,
                          child: HeaderIcon(
                            icon: Icons.delete,
                            onTap: () {
                              setState(() {
                                widget.oldImageValues[attribute['name']] =
                                    widget.imageValues[attribute['name']] = '';
                              });
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
                            },
                            iconColor: Colors.white,
                            color: Colors.black38,
                            iconSize: 15,
                          ),
                        ),
                      ),
                      if (widget.isLoadingMap[attribute['name']] ==
                          true) // Loader göster
                        Positioned.fill(
                          child: Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
