import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class CustomDropdownTile extends StatefulWidget {
  final TextEditingController controller;
  final List<String> options;
  final String title;
  final String placeholder;

  const CustomDropdownTile({
    super.key,
    required this.controller,
    required this.options,
    this.title = 'Select Options',
    this.placeholder = 'Choose...',
  });

  @override
  State<CustomDropdownTile> createState() => _CustomDropdownTileState();
}

class _CustomDropdownTileState extends State<CustomDropdownTile> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _dropdownOverlay;
  late List<String> _selectedValues;

  @override
  void initState() {
    super.initState();
    // Controller'daki değeri ayarla
    _selectedValues = widget.controller.text.isNotEmpty
        ? widget.controller.text.split(", ")
        : [];
  }

  void _toggleDropdown() {
    if (_dropdownOverlay == null) {
      _showDropdown();
    } else {
      _hideDropdown();
    }
  }

  void _showDropdown() {
    _dropdownOverlay = _createDropdown();
    Overlay.of(context).insert(_dropdownOverlay!);
  }

  void _hideDropdown() {
    _dropdownOverlay?.remove();
    _dropdownOverlay = null;
  }

  OverlayEntry _createDropdown() {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    Size size = renderBox.size;
    Offset offset = renderBox.localToGlobal(Offset.zero);

    return OverlayEntry(
      builder: (BuildContext context) {
        return Stack(
          children: [
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _hideDropdown, // Dropdown dışına tıklanınca kapanır
              child: Container(
                color: Colors.transparent, // Tıklamayı algılamak için bir arka plan
              ),
            ),
            Positioned(
              left: offset.dx,
              bottom: MediaQuery.of(context).size.height - offset.dy,
              width: size.width,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  constraints: const BoxConstraints(maxHeight: 300),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: widget.options.map((option) {
                        return StatefulBuilder(
                          builder: (context, setState) {
                            return Row(
                              children: [
                                Checkbox(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(60),
                                  ),
                                  value: _selectedValues.contains(option),
                                  onChanged: (bool? isChecked) {
                                    setState(() {});
                                    this.setState(() {
                                      if (isChecked == true) {
                                        _selectedValues.add(option);
                                      } else {
                                        _selectedValues.remove(option);
                                      }
                                      widget.controller.text =
                                          _selectedValues.join(", ");
                                    });
                                  },
                                ),
                                Text(
                                  option,
                                  style: Theme.of(context).textTheme.displayMedium,
                                ),
                              ],
                            );
                          },
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: _toggleDropdown,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
            decoration: BoxDecoration(
              color: AppColors.secondaryColor,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.title,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(fontSize: 13),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _selectedValues.isEmpty
                            ? widget.placeholder
                            : _selectedValues.join(", "),
                        softWrap: true,
                        overflow: TextOverflow.ellipsis,
                        style:
                        Theme.of(context).textTheme.displayMedium?.copyWith(),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppColors.primaryColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _hideDropdown();
    super.dispose();
  }
}
