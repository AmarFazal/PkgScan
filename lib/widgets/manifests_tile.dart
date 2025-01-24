import 'package:flutter/material.dart';
import 'package:flutter_pkgscan/widgets/outlined_custom_tile.dart';

import '../constants/app_colors.dart';

class ManifestsTile extends StatefulWidget {
  final String title;
  final String? subtitle;
  final double iconSize;
  final IconData icon;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool holdDownWorking;

  const ManifestsTile({
    super.key,
    required this.title,
    this.subtitle,
    required this.icon,
    required this.iconSize,
    required this.onTap,
    required this.holdDownWorking,
    this.onLongPress,
  });

  @override
  State<ManifestsTile> createState() => _ManifestsTileState();
}

class _ManifestsTileState extends State<ManifestsTile> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: widget.holdDownWorking == true ? widget.onLongPress : () {},
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.only(top: 20, bottom: 0, left: 20, right: 20),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        height: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          color: AppColors.secondaryColor,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(widget.icon,
                    color: AppColors.primaryColor, size: widget.iconSize),
                const SizedBox(width: 16),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.displayMedium,
                    ),
                    if (widget.subtitle != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                            widget.subtitle!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.displaySmall),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
