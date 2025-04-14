import 'dart:async';

import 'package:flutter/material.dart';
import '../../screens/camera_screen.dart';

Future<bool?> showCameraDialog(
  BuildContext context,
  String entityId,
  String recordRequestId,
) {
  return showModalBottomSheet<bool>(
    isScrollControlled: true,
    context: context,
    builder: (BuildContext context) {
      return SizedBox(
        height: MediaQuery.of(context).size.height * 0.8,
        width: MediaQuery.of(context).size.width,
        child: CameraScreen(
          entityId: entityId,
          recordRequestId: recordRequestId,
        ),
      );
    },
  );
}
