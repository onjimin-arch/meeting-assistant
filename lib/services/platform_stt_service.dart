import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

/// 플랫폼 내장 STT(음성→텍스트) 서비스.
///
/// - Android: SpeechRecognizer (Google STT 엔진)
/// - iOS: SFSpeechRecognizer (Apple Speech framework)
///
/// 두 플랫폼 모두 단일 인식 세션이 60초 내외에서 종료되므로,
/// 회의처럼 긴 발화를 끊김 없이 받아 적으려면 세션이 끝날 때마다 자동 재시작한다.
/// 외부에서 보기엔 startListening 한 번으로 stopListening 시점까지 계속 받아 적는 것처럼 동작한다.
class PlatformSttService {
  final SpeechToText _stt = SpeechToText();

  bool _available = false;
  bool _wantsToListen = false;
  String _finalizedTranscript = '';
  String _currentPartial = '';
  String _localeId = 'ko_KR';

  /// 실시간 partial 결과 (현재 발화 중) — UI 자막 표시용
  void Function(String partial)? onPartial;

  /// 누적된 최종 텍스트가 갱신될 때 (한 문장 완성, 세션 재시작 시점 등)
  void Function(String accumulated)? onAccumulated;

  bool get isListening => _wantsToListen;

  /// 1회 초기화 — 마이크/음성인식 권한 요청 트리거됨.
  /// 사용 가능 여부를 반환한다. (false면 권한 거부 또는 기기 미지원)
  Future<bool> initialize() async {
    if (_available) return true;
    _available = await _stt.initialize(
      onError: (e) => debugPrint('[STT] error: ${e.errorMsg} (perm=${e.permanent})'),
      onStatus: (status) {
        debugPrint('[STT] status: $status');
        // 세션이 자연 종료되면(타임아웃/무음) 사용자가 여전히 녹음 중이면 재시작.
        if ((status == 'done' || status == 'notListening') && _wantsToListen) {
          _restartSession();
        }
      },
      debugLogging: false,
    );
    return _available;
  }

  /// 회의 녹음 시작 — 세션 자동 재시작으로 연속 받아쓰기.
  Future<void> startListening({String localeId = 'ko_KR'}) async {
    if (!_available) {
      final ok = await initialize();
      if (!ok) {
        throw Exception('음성 인식을 사용할 수 없습니다 (권한 거부 또는 기기 미지원)');
      }
    }
    _localeId = localeId;
    _wantsToListen = true;
    _finalizedTranscript = '';
    _currentPartial = '';
    await _startSession();
  }

  Future<void> _startSession() async {
    // v7 호환: SpeechListenOptions의 일부 필드가 버전마다 다르므로
    // 가장 기본 파라미터만 사용한다.
    await _stt.listen(
      onResult: _onResult,
      localeId: _localeId,
      listenFor: const Duration(seconds: 50),  // 60초 시스템 한도 직전에 끊고 재시작
      pauseFor: const Duration(hours: 24),   // 무음 감지 시간 무제한 (실질적)
      listenOptions: SpeechListenOptions(
        listenMode: ListenMode.dictation,
        partialResults: true,
        cancelOnError: false,
      ),
    );
  }

  /// 세션이 자연 종료되었지만 사용자는 계속 녹음 중인 경우 → 새 세션 시작.
  Future<void> _restartSession() async {
    if (!_wantsToListen) return;
    // partial을 finalize에 합쳐서 보존 (재시작하면 stt 내부 상태가 리셋됨)
    if (_currentPartial.isNotEmpty) {
      _finalizedTranscript =
          ('$_finalizedTranscript $_currentPartial').trim();
      _currentPartial = '';
      onAccumulated?.call(_finalizedTranscript);
    }
    await Future.delayed(const Duration(milliseconds: 200));
    if (!_wantsToListen) return;
    await _startSession();
  }

  void _onResult(SpeechRecognitionResult result) {
    if (result.finalResult) {
      _finalizedTranscript =
          ('$_finalizedTranscript ${result.recognizedWords}').trim();
      _currentPartial = '';
      onAccumulated?.call(_finalizedTranscript);
    } else {
      _currentPartial = result.recognizedWords;
      onPartial?.call(_currentPartial);
    }
  }

  /// 회의 녹음 종료 → 최종 누적 텍스트 반환.
  Future<String> stopListening() async {
    _wantsToListen = false;
    await _stt.stop();
    
    // 최종 transcript 조합 및 로깅
    final combinedTranscript = ('$_finalizedTranscript $_currentPartial').trim();
    debugPrint('[STT] stopListening - finalized: ${_finalizedTranscript.length}자, partial: ${_currentPartial.length}자, total: ${combinedTranscript.length}자');
    
    _finalizedTranscript = '';
    _currentPartial = '';
    
    return combinedTranscript.isEmpty
        ? '(음성이 감지되지 않았습니다)'
        : combinedTranscript;
  }

  Future<void> cancel() async {
    _wantsToListen = false;
    await _stt.cancel();
  }
}
