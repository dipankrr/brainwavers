import 'dart:async';
import 'dart:typed_data';
import 'dart:html' as html;

import 'photo_picker.dart';

PhotoPicker createPhotoPickerImpl() => WebPhotoPicker();

class WebPhotoPicker implements PhotoPicker {
  @override
  Future<Uint8List?> pickPhoto() async {
    final completer = Completer<html.File>();

    final input = html.FileUploadInputElement();
    input.accept = '.jpg,.jpeg,.png';
    input.click();

    input.onChange.listen((event) {
      if (input.files!.isNotEmpty) {
        completer.complete(input.files!.first);
      }
    });

    final file = await completer.future;

    final reader = html.FileReader();
    final readCompleter = Completer<Uint8List>();
    reader.onLoadEnd.listen((event) {
      readCompleter.complete(reader.result as Uint8List);
    });
    reader.readAsArrayBuffer(file);

    return readCompleter.future;
  }
}
