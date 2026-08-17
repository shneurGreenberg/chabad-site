import 'dart:typed_data';

import 'package:image/image.dart' as img;

const kMaxImageSide = 1100;
const kTargetImageBytes = 480 * 1024;

/// Shrink/JPEG-encode admin uploads for IndexedDB + Firestore (1MB doc limit).
/// Base64 is ~33% larger — keep the data URL well under ~700KB.
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
    var quality = 70;
    var out = img.encodeJpg(im, quality: quality);
    if (out.length > kTargetImageBytes) {
      quality = 60;
      out = img.encodeJpg(im, quality: quality);
    }
    if (out.length > kTargetImageBytes) {
      im = img.copyResize(
        im,
        width: im.width >= im.height ? 1000 : null,
        height: im.height > im.width ? 1000 : null,
        interpolation: img.Interpolation.linear,
      );
      out = img.encodeJpg(im, quality: 58);
    }
    if (out.length > kTargetImageBytes) {
      im = img.copyResize(
        im,
        width: im.width >= im.height ? 800 : null,
        height: im.height > im.width ? 800 : null,
        interpolation: img.Interpolation.linear,
      );
      out = img.encodeJpg(im, quality: 52);
    }
    return Uint8List.fromList(out);
  } catch (_) {
    return bytes;
  }
}
