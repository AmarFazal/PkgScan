import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class EntriesCheckbox extends StatefulWidget {
  late bool isChecked;
  final String label;
  final ValueChanged onChanged;

  EntriesCheckbox({
    super.key,
    required this.isChecked,
    required this.label,
    required this.onChanged,
  });

  @override
  State<EntriesCheckbox> createState() => _EntriesCheckboxState();
}

class _EntriesCheckboxState extends State<EntriesCheckbox> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Checkbox durumunu tersine çevir
        setState(() {
          widget.isChecked = !widget.isChecked;
        });
        // onChanged fonksiyonunu çağır
        widget.onChanged(widget.isChecked);
      },
      child: Container(
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
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Center(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Checkbox(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(60),
                  ),
                  value: widget.isChecked,
                  onChanged: widget.onChanged,
                ),
                Text(
                  widget.label,
                  style: Theme.of(context).textTheme.displayMedium,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
