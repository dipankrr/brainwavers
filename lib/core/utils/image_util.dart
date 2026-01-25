import 'dart:typed_data';
import 'package:image/image.dart' as img;

bool isSupportedImage(Uint8List b) {
  // JPEG
  if (b[0] == 0xFF && b[1] == 0xD8) return true;

  // PNG
  if (b[0] == 0x89 && b[1] == 0x50) return true;

  return false;
}

Future<Uint8List> compressTo150KB(Uint8List bytes) async {
  int quality = 90;
  Uint8List result = bytes;

  final decoded = img.decodeImage(bytes);
  if (decoded == null) throw "Invalid image";

  while (result.lengthInBytes > 150000 && quality > 20) {
    result = Uint8List.fromList(img.encodeJpg(decoded, quality: quality));
    quality -= 10;
  }

  return result;
}
