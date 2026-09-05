// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:convert';

void applyWebFavicon({
  required String title,
  List<int>? logoBytes,
}) {
  html.document.title = title;

  if (logoBytes == null || logoBytes.isEmpty) return;

  final b64 = base64Encode(logoBytes);
  final href = 'data:image/png;base64,$b64';

  html.Element? link = html.document.querySelector("link[rel*='icon']");
  if (link is html.LinkElement) {
    link.type = 'image/png';
    link.href = href;
  } else {
    final el = html.LinkElement()
      ..type = 'image/png'
      ..rel = 'icon'
      ..href = href;
    html.document.head?.append(el);
  }

  // Apple touch
  html.Element? apple =
      html.document.querySelector("link[rel='apple-touch-icon']");
  if (apple is html.LinkElement) {
    apple.href = href;
  }
}
