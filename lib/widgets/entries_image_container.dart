import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_pkgscan_new/widgets/header_icon.dart';
import 'package:photo_view/photo_view.dart';

import '../constants/app_colors.dart';

class EntriesImageContainer extends StatelessWidget {
  final String label;
  final String imageUrl;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onTapExport;

  EntriesImageContainer({
    super.key,
    required this.label,
    required this.imageUrl,
    this.onTap,
    this.onDelete,
    this.onTapExport,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(
          top: 0,
          bottom: 20,
        ),
        padding: const EdgeInsets.only(
          top: 0,
          bottom: 20,
          left: 20,
          right: 20,
        ),
        decoration: BoxDecoration(
          color: AppColors.secondaryColor,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                label,
                style: Theme.of(context)
                    .textTheme
                    .displaySmall
                    ?.copyWith(color: AppColors.textColor, fontSize: 13),
              ),
            ),
            Stack(
              children: [
                ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Image.network(imageUrl)),
                Positioned(
                    top: 5,
                    left: 5,
                    child: HeaderIcon(
                        icon: Icons.remove_red_eye,
                        color: Colors.black38,
                        iconColor: Colors.white,
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) {
                              return Dialog(
                                backgroundColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                child: Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(25),
                                      child: Image.network(
                                        imageUrl,
                                        fit: BoxFit.contain,
                                      ),
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
                                  ],
                                ),
                              );
                            },
                          );
                        })),
                Positioned(
                    top: 5,
                    right: 5,
                    child: Row(
                      children: [
                        onDelete != null
                            ? HeaderIcon(
                                icon: Icons.delete,
                                color: Colors.black38,
                                iconColor: Colors.white,
                                onTap: onDelete!)
                            : const SizedBox.shrink(),
                        onTapExport != null
                            ? Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: HeaderIcon(
                                  color: Colors.black38,
                                  iconColor: Colors.white,
                                  onTap: onTapExport!,
                                  icon: Icons.upload,
                                ),
                              )
                            : const SizedBox.shrink(),
                      ],
                    )),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
