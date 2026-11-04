import 'package:flutter/material.dart';

/// Tells screens when a full screen on top of them closes, e.g. Home
/// reloads its stats and collection progress after a study session.
final appRouteObserver = RouteObserver<PageRoute<dynamic>>();
