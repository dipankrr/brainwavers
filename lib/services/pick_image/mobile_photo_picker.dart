import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'photo_picker.dart';

PhotoPicker createPhotoPickerImpl() => MobilePhotoPicker();

class MobilePhotoPicker implements PhotoPicker {
  @override
  Future<Uint8List?> pickPhoto() async {
    final picker = ImagePicker();
    final XFile? file = await picker.pickImage(source: ImageSource.gallery);
    return file?.readAsBytes();
  }
}
