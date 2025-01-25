import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class EntriesScrapeStatusTile extends StatefulWidget {
  final String label;
  final String title;
  final TextEditingController controller;
  final List<dynamic> options;

  EntriesScrapeStatusTile(
      {super.key, required this.label, required this.controller, required this.title, required this.options});

  @override
  State<EntriesScrapeStatusTile> createState() =>
      _EntriesScrapeStatusTileState();
}

class _EntriesScrapeStatusTileState extends State<EntriesScrapeStatusTile> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(
        top: 0,
        bottom: 20,
      ),
      padding: const EdgeInsets.only(
        left: 7,
        right: 7,
      ),
      decoration: BoxDecoration(
        color: AppColors.secondaryColor,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        child: Center(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.label,
                    style: Theme.of(context)
                        .textTheme
                        .displaySmall
                        ?.copyWith(color: AppColors.primaryColor),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    widget.title,
                    style: Theme.of(context)
                        .textTheme
                        .displaySmall
                        ?.copyWith(color: AppColors.textColor, fontSize: 13),
                  ),
                ],
              ),
              const Icon(
                Icons.check_circle,
                color: AppColors.successColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
