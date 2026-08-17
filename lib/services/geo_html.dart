import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

Future<(double, double)> currentPosition() {
  final done = Completer<(double, double)>();
  web.window.navigator.geolocation.getCurrentPosition(
    (web.GeolocationPosition pos) {
      done.complete((pos.coords.latitude, pos.coords.longitude));
    }.toJS,
    (web.GeolocationPositionError err) {
      done.completeError(Exception(err.message));
    }.toJS,
  );
  return done.future;
}
