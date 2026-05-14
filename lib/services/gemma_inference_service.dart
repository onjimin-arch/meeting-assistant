import 'dart:convert';
import 'package:flutter/material.dart';

/// LLM 추론 서비스 - Gemma 4 2B 사용
class GemmaInferenceService {
  /// 회의록 생성 및 제목 생성
  Future<Map<String, String>> generateMinutes({
    required String transcript,
    String? instructions,
  }) async {
    try {
      debugPrint('[Gemma] 회의록 생성 시작');

      // 실제 구현: MediaPipe LLM Inference API 사용
      // final result = await _invokeGemmaModel(transcript, instructions);

      // 임시 mock 결과
      await Future.delayed(const Duration(seconds: 3));

      final mockResponse = {
        'title': 'Q2 전략 방향 확정',
        'minutes': '''## 회의록

**일시**: 2025년 5월 13일 14:30
**참석자**: 이지민, 김철수, 박영희, 최동욱
**목적**: 2025 Q2 전략 방향 확정

### 1. 주요 안건

**AX 로드맵 업데이트**
- DEBTFLOW v2 배포 일정: 6월 첫째 주 확정
- HRFlow 설계 완료, HR팀 피드백 수렴 단계 진입
- 멀티에이전트 프레임워크 Q2 내 파일럿 적용 예정

**인력 계획**
- AX팀 헤드카운트 2명 증원 검토 중
- 외부 컨설팅 여부: 7월 이후 재논의

### 2. 결정 사항

- ☐ DEBTFLOW 배포: 이지민 담당, 6/2 마감
- ☐ HR팀 미팅 일정: 김철수 조율, 5/20 이전
- ☐ Q2 예산 재확인: 박영희 담당

### 3. 다음 회의

5월 20일 (화) 오전 10시'''
      };

      debugPrint('[Gemma] 회의록 생성 완료');
      return mockResponse;
    } catch (e) {
      debugPrint('[Gemma] 회의록 생성 실패: $e');
      rethrow;
    }
  }

  /// 채팅 기반 추가 작업 처리
  Future<String> processQuery({
    required String query,
    required String transcript,
    required String minutes,
  }) async {
    try {
      debugPrint('[Gemma] 쿼리 처리: $query');

      // 임시 mock 응답
      await Future.delayed(const Duration(seconds: 1));

      final responses = {
        '액션아이템 추출':
            '이 회의에서 추출된 액션아이템은 총 3개입니다:\n\n1. **DEBTFLOW v2 배포** — 이지민 | 마감 6/2\n2. **HR팀 미팅 일정 조율** — 김철수 | 5/20 이전\n3. **Q2 예산 재확인** — 박영희 | 미정',
        '영문 요약':
            '**Meeting Summary (EN)**\n\nDate: May 13, 2025 | Duration: 45 min\n\n**Key Decisions**: DEBTFLOW v2 deployment set for early June. HRFlow entering feedback phase. Multi-agent framework pilot planned for Q2.\n\n**Action Items**: 3 items assigned across team leads.',
        '임원 보고용 재작성':
            '**[경영진 요약]** 2025 Q2 전략 회의\n\nAX 핵심 시스템 2종(DEBTFLOW·HRFlow)이 예정대로 진행 중이며 Q2 내 배포 및 피드백 수렴을 완료할 계획입니다. 인력 증원(2명) 검토는 7월 예산 확정 후 결정됩니다.',
      };

      return responses[query] ??
          '"$query"에 대한 분석을 완료했습니다. 추가로 필요한 사항이 있으시면 말씀해 주세요.';
    } catch (e) {
      debugPrint('[Gemma] 쿼리 처리 실패: $e');
      rethrow;
    }
  }
}
