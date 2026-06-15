import 'package:web/web.dart' as web;

void setServerTapCookie(String key) {
  if (key.isEmpty) {
    return;
  }

  web.document.cookie =
      'x-servertap-key=${Uri.encodeComponent(key)}; path=/; SameSite=Lax';
}
