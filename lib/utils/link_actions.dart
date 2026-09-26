import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens a URL in the external browser / default handler.
Future<void> openLink(String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) return;
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

Future<void> copyUrl(String url) =>
    Clipboard.setData(ClipboardData(text: url));
