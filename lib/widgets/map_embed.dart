import 'package:flutter/material.dart';

import 'map_embed_stub.dart'
    if (dart.library.js_interop) 'map_embed_web.dart' as impl;

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
