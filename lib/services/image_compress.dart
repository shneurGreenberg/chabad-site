import 'dart:typed_data';

import 'package:image/image.dart' as img;

const kMaxImageSide = 1600;
const kTargetImageBytes = 380 * 1024;

/// Shrink/JPEG-encode admin uploads so they survive IndexedDB and Storage.
Uint8List compressSiteImage(Uint8List bytes) {
  if (bytes.isEmpty) return bytes;
  try {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return bytes;
    var im = decoded;
    if (im.width > kMaxImageSide || im.height > kMaxImageSide) {
      im = img.copyResize(
        im,
        width: im.width >= im.height ? kMaxImageSide : null,
        height: im.height > im.width ? kMaxImageSide : null,
        interpolation: img.Interpolation.linear,
      );
    }
    var quality = 72;
    var out = img.encodeJpg(im, quality: quality);
    if (out.length > kTargetImageBytes) {
      quality = 58;
      out = img.encodeJpg(im, quality: quality);
    }
    if (out.length > kTargetImageBytes) {
      final smaller = img.copyResize(
        im,
        width: im.width >= im.height ? 1200 : null,
        height: im.height > im.width ? 1200 : null,
        interpolation: img.Interpolation.linear,
      );
      out = img.encodeJpg(smaller, quality: 55);
    }
    return Uint8List.fromList(out);
  } catch (_) {
    return bytes;
  }
}
