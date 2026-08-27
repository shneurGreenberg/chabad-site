import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/cors_proxy.dart';

/// Remote photo that still shows when the host does not send CORS headers.
class CrossOriginImage extends StatefulWidget {
  const CrossOriginImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.error,
  });

  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Alignment alignment;
  final Widget? error;

  @override
  State<CrossOriginImage> createState() => _CrossOriginImageState();
}

class _CrossOriginImageState extends State<CrossOriginImage> {
  Uint8List? _imageBytes;
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(CrossOriginImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      setState(() {
        _imageBytes = null;
        _loading = true;
        _failed = false;
      });
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    final url = widget.url.trim();
    if (url.isEmpty) {
      if (mounted) {
        setState(() {
          _loading = false;
          _failed = true;
        });
      }
      return;
    }

    try {
      http.Response res;
      if (url.contains('synagogue-kadish-shneur.amvera.io/photos/')) {
        res = await CorsProxy.getDirectOrProxy(url);
      } else {
        res = await http.get(Uri.parse(url));
      }

      if (res.statusCode >= 200 && res.statusCode < 300 && mounted) {
        setState(() {
          _imageBytes = res.bodyBytes;
          _loading = false;
          _failed = false;
        });
      } else if (mounted) {
        setState(() {
          _loading = false;
          _failed = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _failed = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: _loading
          ? SizedBox(
              width: widget.width,
              height: widget.height,
              child: const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          : _failed || _imageBytes == null
              ? (widget.error ?? const SizedBox.shrink())
              : Image.memory(
                  _imageBytes!,
                  width: widget.width,
                  height: widget.height,
                  fit: widget.fit,
                  alignment: widget.alignment,
                  filterQuality: FilterQuality.medium,
                ),
    );
  }
}
