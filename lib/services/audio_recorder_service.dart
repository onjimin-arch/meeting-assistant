import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'dart:io';

/// 오디오 레코더 서비스 (AAC 형식)
class AudioRecorderService {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool _isOpen = false;
  String? _currentPath;

  /// 레코더 초기화
  Future<void> initialize() async {
    if (!_isOpen) {
      await _recorder.openRecorder();
      _isOpen = true;
    }
  }

  /// 레코더 닫기
  Future<void> close() async {
    if (_isOpen) {
      await _recorder.closeRecorder();
      _isOpen = false;
    }
  }

  /// 녹음 시작
  Future<void> startRecording() async {
    await initialize();
    final dir = await getApplicationDocumentsDirectory();
    final recordingsDir = Directory('${dir.path}/recordings');
    if (!await recordingsDir.exists()) {
      await recordingsDir.create(recursive: true);
    }
    _currentPath = '${recordingsDir.path}/${DateTime.now().millisecondsSinceEpoch}.aac';
    await _recorder.startRecorder(
      toFile: _currentPath,
      codec: Codec.aacADTS,
    );
  }

  /// 녹음 중지 및 파일 경로 반환
  Future<String?> stopRecording() async {
    final path = await _recorder.stopRecorder();
    _currentPath = path;
    return path;
  }

  /// 녹음 취소
  Future<void> cancel() async {
    await _recorder.stopRecorder();
    _currentPath = null;
  }

  /// 현재 녹음 경로
  String? get currentPath => _currentPath;

  /// 녹음 중 여부
  bool get isRecording => _recorder.isRecording;
}
