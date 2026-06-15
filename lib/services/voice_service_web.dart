import 'package:web/web.dart' as web;

Future<void> enableVoice() async {
  await speakText('Voz activada');
}

Future<void> speakText(String text) async {
  final message = text.trim();
  if (message.isEmpty) {
    return;
  }

  final utterance = web.SpeechSynthesisUtterance(message);
  utterance.lang = 'es-ES';
  utterance.rate = 1;
  utterance.pitch = 1;
  utterance.volume = 1;

  web.window.speechSynthesis.cancel();
  web.window.speechSynthesis.resume();
  web.window.speechSynthesis.speak(utterance);
}
