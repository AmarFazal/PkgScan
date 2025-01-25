import 'package:flutter/material.dart';
import 'package:flutter_pkgscan/services/name_search_service.dart';
import 'package:flutter_pkgscan/widgets/auth_button.dart';

import '../../constants/text_constants.dart';
import '../custom_fields.dart';

void showTextSearchDialog(BuildContext context,String entityId) {
  TextEditingController searchController = TextEditingController();
  TextEditingController pullingCountController = TextEditingController();

  showModalBottomSheet(
    isScrollControlled: true,
    context: context,
    builder: (BuildContext context) {
      return Padding(
        padding: EdgeInsets.only(
          left: 16.0,
          right: 16.0,
          top: 16.0,
          bottom:
              MediaQuery.of(context).viewInsets.bottom, // Klavyeye göre padding
        ),
        child: SingleChildScrollView(
          // İçeriği kaydırılabilir hale getirir
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomFieldWithoutIcon(
                label: TextConstants.search,
                controller: searchController,
                textInputType: TextInputType.text,
              ),
              CustomFieldWithoutIcon(
                label: TextConstants.howMuchProductWillBePulled,
                controller: pullingCountController,
                textInputType: TextInputType.number,
              ),
              SizedBox(
                width: MediaQuery.of(context).size.width*0.4,
                child: AuthButton(title: TextConstants.search, onTap: () {
                  NameSearchService().onTitleSend(context, searchController.text, entityId);

                },),
              ),
              SizedBox(height: 16),
            ],
          ),
        ),
      );
    },
  );
}
