import 'voice_service_stub.dart'
    if (dart.library.html) 'voice_service_web.dart';

class VoiceService {
  Future<void> enable() => enableVoice();

  Future<void> speak(String text) => speakText(text);
}
