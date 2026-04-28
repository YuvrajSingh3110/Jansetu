import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jansetu/core/services/image_picker_service.dart';

Future<PickedImageData?> showImageSourceSheet(BuildContext context) async {
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Upload from gallery'),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Click from camera'),
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
            ],
          ),
        ),
      );
    },
  );

  if (source == null) return null;
  return ImagePickerService().pickImage(source);
}
