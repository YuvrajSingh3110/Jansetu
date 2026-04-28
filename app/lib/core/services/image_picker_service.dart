import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

class PickedImageData {
  const PickedImageData({
    required this.bytes,
    required this.name,
  });

  final Uint8List bytes;
  final String name;
}

class ImagePickerService {
  ImagePickerService._internal();

  static final ImagePickerService _instance = ImagePickerService._internal();

  factory ImagePickerService() => _instance;

  final ImagePicker _picker = ImagePicker();

  Future<PickedImageData?> pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (pickedFile == null) return null;

    return PickedImageData(
      bytes: await pickedFile.readAsBytes(),
      name: pickedFile.name,
    );
  }
}
