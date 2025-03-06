import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class CustomDropdownTile extends StatefulWidget {
  final TextEditingController controller;
  final List<String> options;
  final String title;
  final String placeholder;
  final Function(List<String>)?
      onChanged; // Zorunlu olmayan onChanged callback'i

  const CustomDropdownTile({
    super.key,
    required this.controller,
    required this.options,
    this.title = 'Select Options',
    this.placeholder = 'Choose...',
    this.onChanged, // Zorunlu değil
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

  // Manual Image 1'den 10'a kadar olan seçenekleri döndürür
  List<String> _getManualImageOptions() {
    return List.generate(10, (index) => 'Manual Image ${index + 1}');
  }

  // Tüm Manual Image seçenekleri seçili mi kontrol eder
  bool _areAllManualImagesSelected() {
    final manualImageOptions = _getManualImageOptions();
    return manualImageOptions
        .every((option) => _selectedValues.contains(option));
  }

  // Manual Images içeren seçenekleri filtreler
  bool _isManualImageOption(String option) {
    return _getManualImageOptions().contains(option);
  }

  // MSRP 1'den 10'a kadar olan seçenekleri döndürür
  List<String> _getMSRPOptions() {
    return List.generate(10, (index) => 'MSRP ${index + 1}');
  }

  // Image 1'den 10'a kadar olan seçenekleri döndürür
  List<String> _getImageOptions() {
    return List.generate(10, (index) => 'Image ${index + 1}');
  }

  // Title 1'den 10'a kadar olan seçenekleri döndürür
  List<String> _getTitleOptions() {
    return List.generate(10, (index) => 'Title ${index + 1}');
  }

  // Online Pulled Listings ile ilişkili tüm seçenekleri döndürür
  List<String> _getOnlinePulledListingsOptions() {
    return [
      ..._getMSRPOptions(),
      ..._getImageOptions(),
      ..._getTitleOptions(),
    ];
  }

  // Online Pulled Listings ile ilişkili seçenekler seçili mi kontrol eder
  bool _areAllOnlinePulledListingsSelected() {
    final onlinePulledListingsOptions = _getOnlinePulledListingsOptions();
    return onlinePulledListingsOptions
        .every((option) => _selectedValues.contains(option));
  }

  // Online Pulled Listings ile ilişkili seçenekleri filtreler
  bool _isOnlinePulledListingsOption(String option) {
    return _getOnlinePulledListingsOptions().contains(option);
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
                      )
                    ],
                  ),
                  constraints: const BoxConstraints(maxHeight: 300),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: widget.options.map((option) {
                        // Manual Images ve Online Pulled Listings ile ilişkili seçenekleri filtrele
                        if (_isManualImageOption(option) ||
                            _isOnlinePulledListingsOption(option)) {
                          return const SizedBox.shrink(); // Gizle
                        }
                        return StatefulBuilder(
                          builder: (context, setState) {
                            return Row(
                              children: [
                                Checkbox(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(60),
                                  ),
                                  value: option == 'Manual Images'
                                      ? _areAllManualImagesSelected() // Manual Images seçeneğinin durumu
                                      : option == 'Online Pulled Listings'
                                          ? _areAllOnlinePulledListingsSelected() // Online Pulled Listings seçeneğinin durumu
                                          : _selectedValues.contains(option),
                                  onChanged: (bool? isChecked) {
                                    setState(() {});
                                    this.setState(() {
                                      if (option == 'Manual Images') {
                                        // Manual Images seçildiğinde
                                        if (isChecked == true) {
                                          // Tüm Manual Image seçeneklerini ekle
                                          _selectedValues
                                              .addAll(_getManualImageOptions());
                                        } else {
                                          // Tüm Manual Image seçeneklerini kaldır
                                          _selectedValues.removeWhere((item) =>
                                              _getManualImageOptions()
                                                  .contains(item));
                                        }
                                      } else if (option ==
                                          'Online Pulled Listings') {
                                        // Online Pulled Listings seçildiğinde
                                        if (isChecked == true) {
                                          // Tüm MSRP, Image ve Title seçeneklerini ekle
                                          _selectedValues.addAll(
                                              _getOnlinePulledListingsOptions());
                                        } else {
                                          // Tüm MSRP, Image ve Title seçeneklerini kaldır
                                          _selectedValues.removeWhere((item) =>
                                              _getOnlinePulledListingsOptions()
                                                  .contains(item));
                                        }
                                      } else {
                                        // Diğer seçenekler için normal işlem
                                        if (isChecked == true) {
                                          _selectedValues.add(option);
                                        } else {
                                          _selectedValues.remove(option);
                                        }
                                      }
                                      widget.controller.text =
                                          _selectedValues.join(", ");
                                      // onChanged callback'i çağır
                                      if (widget.onChanged != null) {
                                        widget.onChanged!(_selectedValues);
                                      }
                                    });
                                  },
                                ),
                                Text(
                                  option,
                                  style:
                                      Theme.of(context).textTheme.displayMedium,
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
