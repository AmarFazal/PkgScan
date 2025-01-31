import 'package:flutter/material.dart';

import '../../screens/camera_screen.dart';

Future<void> showCameraDialog(BuildContext context, String entityId) {
  return showModalBottomSheet(
    isScrollControlled: true,
    context: context,
    builder: (BuildContext context) {
      return SizedBox(
        height: MediaQuery.of(context).size.height * 0.8,
        width: MediaQuery.of(context).size.width,
        child: CameraScreen(entityId: entityId),
      );
    },
  );
}
