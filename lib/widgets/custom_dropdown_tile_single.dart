import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class CustomDropdownTileSingle extends StatefulWidget {
  final TextEditingController? controller;
  final List<dynamic> options;
  final String label;
  late String? title;
  final String placeholder;

   CustomDropdownTileSingle({
    super.key,
    required this.controller,
    required this.options,
    this.title = 'Select Option',
    this.placeholder = 'Choose...',
    required this.label,
  });

  @override
  State<CustomDropdownTileSingle> createState() =>
      _CustomDropdownTileSingleState();
}

class _CustomDropdownTileSingleState extends State<CustomDropdownTileSingle> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _dropdownOverlay;
  String? _selectedValue;

  @override
  void initState() {
    super.initState();
    // Eğer widget.title, options listesinde varsa onu seçili yap
    if (widget.options.isNotEmpty) {
      if (widget.title != null && widget.options.contains(widget.title)) {
        _selectedValue = widget.title;
      } else {
        // Eğer title listede yoksa varsayılan olarak ilk seçeneği seç
        _selectedValue = widget.options[0];
      }
      widget.controller?.text = _selectedValue!;
    }
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
                color: Colors
                    .transparent, // Tıklamayı algılamak için bir arka plan
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
                        return ListTile(
                          title: Text(
                            option,
                            style: Theme.of(context).textTheme.displayMedium,
                          ),
                          trailing: Radio<String>(
                            value: option,
                            groupValue: _selectedValue,
                            onChanged: (String? value) {
                              setState(() {
                                widget.title = value;
                                widget.controller?.text = value!;
                              });
                              _hideDropdown();
                            },
                          ),
                          onTap: () {
                            setState(() {
                              _selectedValue = option;
                              widget.controller?.text = option;
                              widget.title = widget.controller?.text;
                            });
                            _hideDropdown();
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
                        widget.label,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(fontSize: 13),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        widget.title ?? widget.placeholder,
                        softWrap: true,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .displayMedium
                            ?.copyWith(),
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
