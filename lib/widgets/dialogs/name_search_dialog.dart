import 'package:flutter/material.dart';
import 'package:flutter_pkgscan_new/services/name_search_service.dart';
import 'package:flutter_pkgscan_new/widgets/auth_button.dart';

import '../../constants/text_constants.dart';
import '../custom_fields.dart';

Future<bool?> showNameSearchDialog(
    BuildContext context,
    String entityId,
    String recordRequestId,
    ) {
  TextEditingController searchController = TextEditingController();
  TextEditingController pullingCountController = TextEditingController();

  return showModalBottomSheet<bool>(
    isScrollControlled: true,
    context: context,
    builder: (BuildContext context) {
      return Padding(
        padding: EdgeInsets.only(
          left: 16.0,
          right: 16.0,
          top: 16.0,
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomFieldWithoutIcon(
                label: TextConstants.searchProduct,
                controller: searchController,
                textInputType: TextInputType.text,
              ),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.4,
                child: AuthButton(
                  title: TextConstants.search,
                  onTap: () {
                    NameSearchService().onTitleSend(
                      context,
                      searchController.text,
                      entityId,
                      recordRequestId,
                    );
                    Navigator.pop(context, true); // <-- Dikkat buraya!
                  },
                ),
              ),
              SizedBox(height: 16),
            ],
          ),
        ),
      );
    },
  );
}
