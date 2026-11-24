import 'dart:convert';

import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

import '../models/event_photo.dart';

class PhotoException implements Exception {
  PhotoException(this.message);

  final String message;

  @override
  String toString() => message;
}

class PhotoService {
  PhotoService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  static const int maxPhotosPerEvent = 5;
  static const int _maxBytes = 450 * 1024;

  Future<List<PickedPhoto>> pickAndCompress({required int maxCount}) async {
    if (maxCount <= 0) {
      throw PhotoException('Досягнуто ліміт фото для події.');
    }

    final files = await _picker.pickMultiImage(
      maxWidth: 2200,
      maxHeight: 2200,
      imageQuality: 92,
      limit: maxCount,
      requestFullMetadata: false,
    );

    if (files.isEmpty) return const [];

    final photos = <PickedPhoto>[];
    for (final file in files.take(maxCount)) {
      photos.add(await _compress(file));
    }
    return photos;
  }

  Future<PickedPhoto> _compress(XFile file) async {
    final raw = await file.readAsBytes();
    final decoded = img.decodeImage(raw);
    if (decoded == null) {
      throw PhotoException(
        'Не вдалося обробити «${file.name}». Підтримуються JPEG, PNG та WebP.',
      );
    }

    var image = img.bakeOrientation(decoded);
    image = _resizeToMax(image, 1400);

    var quality = 78;
    var bytes = img.encodeJpg(image, quality: quality);

    while (bytes.lengthInBytes > _maxBytes && quality > 42) {
      quality -= 8;
      bytes = img.encodeJpg(image, quality: quality);
    }

    if (bytes.lengthInBytes > _maxBytes) {
      image = _resizeToMax(image, 1000);
      quality = 62;
      bytes = img.encodeJpg(image, quality: quality);
      while (bytes.lengthInBytes > _maxBytes && quality > 38) {
        quality -= 6;
        bytes = img.encodeJpg(image, quality: quality);
      }
    }

    final thumbImage = _resizeToMax(image, 420);
    final thumbBytes = img.encodeJpg(thumbImage, quality: 62);

    return PickedPhoto(
      data: base64Encode(bytes),
      thumb: base64Encode(thumbBytes),
      width: image.width,
      height: image.height,
      size: bytes.lengthInBytes,
    );
  }

  img.Image _resizeToMax(img.Image image, int maxSide) {
    if (image.width <= maxSide && image.height <= maxSide) return image;
    if (image.width >= image.height) {
      return img.copyResize(
        image,
        width: maxSide,
        interpolation: img.Interpolation.linear,
      );
    }
    return img.copyResize(
      image,
      height: maxSide,
      interpolation: img.Interpolation.linear,
    );
  }
}
