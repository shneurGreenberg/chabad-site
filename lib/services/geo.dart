import 'geo_stub.dart' if (dart.library.js_interop) 'geo_html.dart' as impl;

Future<(double, double)> currentPosition() => impl.currentPosition();
