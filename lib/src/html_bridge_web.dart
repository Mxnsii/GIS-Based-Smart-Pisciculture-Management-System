// Web implementation for posting messages to the iframe created by qgis2web export.
import 'dart:async';
import 'dart:html' as html;

String? _pendingMessage;
Timer? _retryTimer;

void postMessageToIframe(String message) {
  _pendingMessage = message;
  _retryTimer?.cancel();
  _retryTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
    try {
      final iframe = html.document.getElementById('gis-map-iframe') as html.IFrameElement?;
      final payload = _pendingMessage;
      if (iframe != null && iframe.contentWindow != null && payload != null) {
        iframe.contentWindow!.postMessage(payload, '*');
        _pendingMessage = null;
        timer.cancel();
      }
      if (timer.tick >= 50) {
        timer.cancel();
      }
    } catch (e) {
      if (timer.tick >= 50) {
        timer.cancel();
      }
    }
  });

  try {
    final iframe = html.document.getElementById('gis-map-iframe') as html.IFrameElement?;
    if (iframe != null && iframe.contentWindow != null) {
      iframe.contentWindow!.postMessage(message, '*');
      _pendingMessage = null;
      _retryTimer?.cancel();
    }
  } catch (e) {
    // ignore cross-origin errors
  }
}
