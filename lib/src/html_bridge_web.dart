// Web implementation for posting messages to the iframe created by qgis2web export.
import 'dart:html' as html;

void postMessageToIframe(String message) {
  try {
    final iframe = html.document.getElementById('gis-map-iframe') as html.IFrameElement?;
    if (iframe != null && iframe.contentWindow != null) {
      iframe.contentWindow!.postMessage(message, '*');
    }
  } catch (e) {
    // ignore cross-origin errors
  }
}
