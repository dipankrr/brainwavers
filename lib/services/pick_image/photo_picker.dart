import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;

// This picks the correct implementation based on platform.
// Web → uses web_photo_picker.dart
// Mobile/Desktop → uses mobile_photo_picker.dart
import 'mobile_photo_picker.dart'
if (dart.library.html) 'web_photo_picker.dart';

abstract class PhotoPicker {
  Future<Uint8List?> pickPhoto();
}

PhotoPicker createPhotoPicker() => createPhotoPickerImpl();

// Singleton instance your UI will use
class PhotoPickerService {
  static final PhotoPicker instance = createPhotoPicker();
}
