// Web implementation for posting messages to the iframe created by qgis2web export.
import 'dart:html' as html;
import 'dart:convert';

String? _latestPayload;
bool _listenerRegistered = false;

void _ensureListenerRegistered() {
  if (_listenerRegistered) return;
  _listenerRegistered = true;
  html.window.addEventListener('message', (event) {
    try {
      final data = event is html.MessageEvent ? event.data : null;
      final parsed = (data is String) ? (data.isNotEmpty ? jsonDecode(data) : null) : data;
      if (parsed != null && parsed['type'] == 'mapReady') {
        final payload = _latestPayload;
        if (payload != null) {
          final iframe = html.document.getElementById('gis-map-iframe') as html.IFrameElement?;
          if (iframe != null && iframe.contentWindow != null) {
            iframe.contentWindow!.postMessage(payload, '*');
          }
        }
      }
    } catch (e) {
      // ignore
    }
  });
}

void postMessageToIframe(String message) {
  _latestPayload = message;
  _ensureListenerRegistered();

  try {
    final iframe = html.document.getElementById('gis-map-iframe') as html.IFrameElement?;
    if (iframe != null && iframe.contentWindow != null) {
      iframe.contentWindow!.postMessage(message, '*');
    }
  } catch (e) {
    // ignore cross-origin errors
  }
}
