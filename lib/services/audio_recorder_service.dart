import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'dart:io';

/// 오디오 레코더 서비스 (AAC 형식)
class AudioRecorderService {
  final AudioRecorder _recorder = AudioRecorder();
  String? _currentPath;

  /// 레코더 초기화
  Future<void> initialize() async {
    // 권한 확인은 _startRecording 에서 수행
  }

  /// 레코더 닫기
  Future<void> close() async {
    if (await _recorder.isRecording()) {
      await _recorder.stop();
    }
  }

  /// 녹음 시작
  Future<void> startRecording() async {
    final config = const RecordConfig(
      encoder: AudioEncoder.aacLc,
      bitRate: 128000,
      sampleRate: 44100,
    );

    final dir = await getApplicationDocumentsDirectory();
    final recordingsDir = Directory('${dir.path}/recordings');
    if (!await recordingsDir.exists()) {
      await recordingsDir.create(recursive: true);
    }
    _currentPath = '${recordingsDir.path}/${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _recorder.start(config, path: _currentPath!);
  }

  /// 녹음 중지 및 파일 경로 반환
  Future<String?> stopRecording() async {
    try {
      await _recorder.stop();
      return _currentPath;
    } finally {
      _currentPath = null;
    }
  }

  /// 녹음 취소
  Future<void> cancel() async {
    try {
      await _recorder.stop();
    } finally {
      _currentPath = null;
    }
  }

  /// 현재 녹음 경로
  String? get currentPath => _currentPath;

  /// 녹음 중 여부
  Future<bool> get isRecording async => await _recorder.isRecording();

  /// 녹음 권한 확인
  Future<bool> hasPermission() async {
    return await _recorder.hasPermission();
  }
}
