import 'dart:io';

import 'package:chat/utils/constants.dart';

String getDeviceType() {
  if (Platform.isAndroid) {
    return Constants.ANDROID;
  } else if (Platform.isIOS) {
    return Constants.IOS;
  } else {
    return 'Unknown';
  }
}
