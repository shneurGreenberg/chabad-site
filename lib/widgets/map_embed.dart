import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'map_embed_stub.dart'
    if (dart.library.js_interop) 'map_embed_web.dart' as impl;
import 'playful_icons.dart';

class MapEmbed extends StatelessWidget {
  const MapEmbed({super.key, required this.url});
  final String url;

  @override
  Widget build(BuildContext context) => impl.MapIFrame(url: url);
}

String osmEmbedUrl(double lat, double lon) {
  const dLon = 0.012;
  const dLat = 0.008;
  final minLon = lon - dLon;
  final minLat = lat - dLat;
  final maxLon = lon + dLon;
  final maxLat = lat + dLat;
  return 'https://www.openstreetmap.org/export/embed.html'
      '?bbox=$minLon,$minLat,$maxLon,$maxLat'
      '&layer=mapnik&marker=$lat,$lon';
}

String googleMapsEmbedUrl({
  required String apiKey,
  required double lat,
  required double lon,
  String address = '',
}) {
  final q = address.trim().isNotEmpty
      ? Uri.encodeQueryComponent(address.trim())
      : Uri.encodeQueryComponent('$lat,$lon');
  return 'https://www.google.com/maps/embed/v1/place?key=$apiKey&q=$q';
}

String googleMapsSearchUrl({
  required double lat,
  required double lon,
  String address = '',
}) {
  final q = address.trim().isNotEmpty
      ? Uri.encodeQueryComponent(address.trim())
      : Uri.encodeQueryComponent('$lat,$lon');
  return 'https://www.google.com/maps/search/?api=1&query=$q';
}

/// OSM always works without a key; Google Embed is used when [apiKey] is set.
String siteMapEmbedUrl({
  required double lat,
  required double lon,
  String apiKey = '',
  String address = '',
}) {
  if (apiKey.trim().isNotEmpty) {
    return googleMapsEmbedUrl(
      apiKey: apiKey.trim(),
      lat: lat,
      lon: lon,
      address: address,
    );
  }
  return osmEmbedUrl(lat, lon);
}

/// Raster fallback so the about-page map is visible even if the iframe is blocked.
String osmStaticMapUrl(double lat, double lon, {int width = 800, int height = 480}) {
  return 'https://staticmap.openstreetmap.de/staticmap.php'
      '?center=$lat,$lon&zoom=16&size=${width}x$height'
      '&maptype=mapnik&markers=$lat,$lon,red-pushpin';
}

/// Yandex static maps (works without an API key; lon,lat order).
String yandexStaticMapUrl(double lat, double lon, {int width = 650, int height = 450}) {
  return 'https://static-maps.yandex.ru/1.x/'
      '?ll=$lon,$lat&z=16&l=map&size=$width,$height&pt=$lon,$lat,pm2rdm';
}

String osmTileUrl(double lat, double lon, {int z = 16}) {
  final n = 1 << z;
  final x = ((lon + 180.0) / 360.0 * n).floor().clamp(0, n - 1);
  final latRad = lat * math.pi / 180;
  final y = ((1 - math.log(math.tan(latRad) + 1 / math.cos(latRad)) / math.pi) / 2 * n)
      .floor()
      .clamp(0, n - 1);
  return 'https://tile.openstreetmap.org/$z/$x/$y.png';
}

List<String> staticMapCandidateUrls(double lat, double lon) => [
      yandexStaticMapUrl(lat, lon),
      osmStaticMapUrl(lat, lon),
      osmTileUrl(lat, lon),
    ];

/// Visible raster map (no HtmlElementView). Iframes inside ClipRRect/Stack
/// often paint blank on Flutter web.
class LocationMap extends StatelessWidget {
  const LocationMap({
    super.key,
    required this.lat,
    required this.lon,
    this.height = 320,
    this.onOpen,
  });

  final double lat;
  final double lon;
  final double height;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Material(
        color: const Color(0xFFD6E4F5),
        child: InkWell(
          onTap: onOpen,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _StaticMapImage(lat: lat, lon: lon),
              const IgnorePointer(
                child: Align(
                  alignment: Alignment(0, -0.05),
                  child: PlayfulIcon(
                    Icons.location_on,
                    size: 44,
                    color: Color(0xFFC62828),
                  ),
                ),
              ),
              const Positioned(
                left: 8,
                bottom: 8,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Color(0xCCFFFFFF),
                      borderRadius: BorderRadius.all(Radius.circular(6)),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Text(
                        'OpenStreetMap / Yandex',
                        style: TextStyle(fontSize: 10, color: Color(0xFF334155)),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StaticMapImage extends StatefulWidget {
  const _StaticMapImage({required this.lat, required this.lon});
  final double lat;
  final double lon;

  @override
  State<_StaticMapImage> createState() => _StaticMapImageState();
}

class _StaticMapImageState extends State<_StaticMapImage> {
  late List<String> _urls;
  int _i = 0;

  @override
  void initState() {
    super.initState();
    _urls = staticMapCandidateUrls(widget.lat, widget.lon);
  }

  @override
  void didUpdateWidget(covariant _StaticMapImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lat != widget.lat || oldWidget.lon != widget.lon) {
      _urls = staticMapCandidateUrls(widget.lat, widget.lon);
      _i = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_i >= _urls.length) {
      return const ColoredBox(color: Color(0xFFD6E4F5));
    }
    return Image.network(
      _urls[_i],
      key: ValueKey(_urls[_i]),
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      filterQuality: FilterQuality.medium,
      errorBuilder: (_, _, _) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _i < _urls.length) {
            setState(() => _i++);
          }
        });
        return const ColoredBox(color: Color(0xFFD6E4F5));
      },
    );
  }
}
