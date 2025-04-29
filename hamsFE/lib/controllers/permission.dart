import 'package:permission_handler/permission_handler.dart';

Future<bool> requestImagePermission() async {
  // For Android 13+ you must request Permission.photos
  if (await Permission.photos.request().isGranted) {
    return true;
  } else if (await Permission.photos.isPermanentlyDenied) {
    // Optional: Open app settings if denied permanently
    openAppSettings();
  }
  return false;
}
