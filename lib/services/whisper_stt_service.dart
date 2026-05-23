import 'package:flutter/foundation.dart';
import 'package:whisper_dart/whisper_dart.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

/// Whisper 로컬 STT 서비스
class WhisperSttService {
  Whisper? _whisper;
  bool _initialized = false;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  final String _modelId = 'base'; // 'tiny', 'base', 'small', 'medium', 'large'

  /// 모델 다운로드 상태
  bool get isDownloading => _isDownloading;
  double get downloadProgress => _downloadProgress;
  bool get isInitialized => _initialized;

  /// Whisper 모델 초기화 (첫 호출 시 자동 다운로드)
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      debugPrint('[Whisper] 모델 초기화 시작: $_modelId');
      
      final modelPath = await _getOrCreateModelPath();
      _whisper = await Whisper.fromPath(modelPath);
      _initialized = true;
      
      debugPrint('[Whisper] 모델 초기화 완료');
    } catch (e) {
      debugPrint('[Whisper] 모델 초기화 실패: $e');
      rethrow;
    }
  }

  /// 모델 경로 확인 및 다운로드
  Future<String> _getOrCreateModelPath() async {
    final dir = await getApplicationDocumentsDirectory();
    final modelsDir = Directory('${dir.path}/whisper_models');
    if (!await modelsDir.exists()) {
      await modelsDir.create(recursive: true);
    }

    final modelFile = File('${modelsDir.path}/whisper-$_modelId.bin');
    
    if (!await modelFile.exists()) {
      await _downloadModel(modelFile);
    }

    return modelFile.path;
  }

  /// Whisper 모델 다운로드
  Future<void> _downloadModel(File targetFile) async {
    try {
      _isDownloading = true;
      _downloadProgress = 0.0;

      debugPrint('[Whisper] 모델 다운로드 시작: ${targetFile.path}');

      // Whisper Dart 패키지 모델 다운로드
      final client = WhisperClient();
      await client.downloadModel(
        model: _getModelType(),
        destination: targetFile.path,
        onProgress: (progress) {
          _downloadProgress = progress.progress;
          debugPrint('[Whisper] 다운로드 진행: ${(_downloadProgress * 100).toStringAsFixed(1)}%');
        },
      );

      _isDownloading = false;
      debugPrint('[Whisper] 모델 다운로드 완료');
    } catch (e) {
      _isDownloading = false;
      debugPrint('[Whisper] 모델 다운로드 실패: $e');
      rethrow;
    }
  }

  WhisperModelType _getModelType() {
    switch (_modelId) {
      case 'tiny':
        return WhisperModelType.tiny;
      case 'base':
        return WhisperModelType.base;
      case 'small':
        return WhisperModelType.small;
      case 'medium':
        return WhisperModelType.medium;
      case 'large':
        return WhisperModelType.large;
      default:
        return WhisperModelType.base;
    }
  }

  /// 오디오 파일에서 텍스트 변환
  Future<String> transcribe(String audioPath) async {
    if (!_initialized) {
      await initialize();
    }

    try {
      debugPrint('[Whisper] 변환 시작: $audioPath');

      final file = File(audioPath);
      if (!await file.exists()) {
        throw Exception('오디오 파일을 찾을 수 없습니다: $audioPath');
      }

      final result = await _whisper!.transcribeFile(
        audioPath,
        language: 'korean',
      );

      final transcript = result
          ?.where((s) => s != null)
          .map((s) => s!.text)
          .join('')
          .trim() ?? '';

      debugPrint('[Whisper] 변환 완료: ${transcript.length}자');

      return transcript.isEmpty ? '(음성이 감지되지 않았습니다)' : transcript;
    } catch (e) {
      debugPrint('[Whisper] 변환 실패: $e');
      rethrow;
    }
  }

  /// 모델 삭제
  Future<void> deleteModel() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final modelsDir = Directory('${dir.path}/whisper_models');
      if (await modelsDir.exists()) {
        await modelsDir.delete(recursive: true);
      }
      _initialized = false;
      _whisper = null;
      debugPrint('[Whisper] 모델 삭제 완료');
    } catch (e) {
      debugPrint('[Whisper] 모델 삭제 실패: $e');
      rethrow;
    }
  }
}
