/// This file registers the iframe view factory for the web platform.
/// It is only imported and used on web platforms via conditional imports.

import 'dart:html' as html;
import 'dart:ui_web' as ui;

/// Register the iframe view factory for displaying the Leaflet map.
/// This must be called before the HtmlElementView is used.
void registerGisMapViewFactory() {
  const String viewType = 'gis-map-leaflet-iframe';

  // Register the factory that creates HTML iframe elements
  // ignore: undefined_prefixed_name
  ui.platformViewRegistry.registerViewFactory(
    viewType,
    (int viewId) {
      final iframe = html.IFrameElement()
        ..id = 'gis-map-iframe'
        ..src = 'assets/maps/index.html'
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.display = 'block';

      return iframe;
    },
  );
}
