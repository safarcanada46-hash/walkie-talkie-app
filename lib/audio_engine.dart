import 'dart:typed_data';
import 'package:flutter_sound/flutter_sound.dart';

class AudioEngine {
  FlutterSoundRecorder? _recorder;
  FlutterSoundPlayer? _player;
  bool _isRecording = false;
  Function(Uint8List)? onAudioData;

  AudioEngine() {
    _recorder = FlutterSoundRecorder();
    _player = FlutterSoundPlayer();
  }

  Future<void> init() async {
    await _recorder!.openRecorder();
    await _player!.openPlayer();
  }

  Future<void> dispose() async {
    await _recorder!.closeRecorder();
    await _player!.closePlayer();
  }

  Future<void> startRecording(Function(Uint8List) callback) async {
    if (!_isRecording) {
      _isRecording = true;
      onAudioData = callback;
      await _recorder!.startRecorder(
        toStream: true,
        codec: Codec.pcm16,
        numChannels: 1,
        sampleRate: 16000,
        onProgress: (e) {
          if (e.buffer != null && e.buffer!.isNotEmpty) {
            onAudioData!(e.buffer!);
          }
        },
      );
    }
  }

  Future<void> stopRecording() async {
    if (_isRecording) {
      _isRecording = false;
      await _recorder!.stopRecorder();
      onAudioData = null;
    }
  }

  Future<void> playAudioChunk(Uint8List data) async {
    await _player!.startPlayer(
      fromDataBuffer: data,
      codec: Codec.pcm16,
      numChannels: 1,
      sampleRate: 16000,
      whenFinished: () {}, // for continuous play, but for chunks, may need queue
    );
  }
}