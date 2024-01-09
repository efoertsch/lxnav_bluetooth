

import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';


// Just relevant for Android, iOS no issue
// Note Android 30+ can't see files in Downloads (say to import into another phone app)
// Can only see via Android file transfer :(
Future<void> checkPermission({
  required Permission permission,
  required Function permissionGrantedFunction,
  required Function requestPermissionFunction,
  required Function permissionDeniedFunction}) async {
  if (Platform.isIOS ){
    permissionGrantedFunction();
    return;
  }
  PermissionStatus? status;
  if (Platform.isAndroid) {
    final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
    final AndroidDeviceInfo info = await deviceInfoPlugin.androidInfo;
    if ((info.version.sdkInt) >= 31) {
      status = await permission.request();
    } else {
      permissionGrantedFunction();
    }
  } else {
    status = await permission.request();
  }

  if (status! == PermissionStatus.denied) {
    var statusGranted = await permission.request().isGranted;
    // We didn't ask for permission yet or the permission has been denied before but not permanently.
    if (statusGranted) {
      // Good to go
      permissionGrantedFunction();
    } else {
      permissionDeniedFunction();
    }
  }
  if (status == PermissionStatus.permanentlyDenied) {
    // display msg to user they need to go to settings to re-enable
    permissionDeniedFunction;
  }
  if (status == PermissionStatus.granted) {
    permissionGrantedFunction();
  }
}