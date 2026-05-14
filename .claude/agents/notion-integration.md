---
title: Notion Integration Subagent - API 클라이언트 & 블록 변환
description: Notion REST API v1 구현 및 마크다운 → 블록 변환
---

# Notion Integration 서브에이전트

**목표**: Notion REST API v1을 이용하여 회의록을 Notion 페이지에 저장하고, 마크다운 형식을 Notion 블록으로 변환

**담당 영역**:
- Notion REST API 인증 및 호출
- 마크다운 → Notion 블록 변환
- 페이지 생성 및 에러 처리
- 네트워크 복원력 (재시도, 타임아웃)

---

## 구현 범위

### 1. NotionSyncService 실제 구현

**파일**: `lib/services/notion_sync_service.dart`

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';

class NotionSyncService {
  final String apiToken;
  final String pageUrl;
  static const String _baseUrl = 'https://api.notion.com/v1';
  static const String _notionVersion = '2022-06-28';
  
  NotionSyncService({
    required this.apiToken,
    required this.pageUrl,
  });
  
  /// 회의록을 Notion 페이지에 저장
  Future<String> saveMinutesToNotion({
    required String title,
    required String minutes,
    String? meetingDate,
  }) async {
    try {
      // 1. 페이지 URL에서 부모 ID 추출
      final parentPageId = _extractPageIdFromUrl(pageUrl);
      if (parentPageId.isEmpty) {
        throw Exception('유효하지 않은 페이지 URL');
      }
      
      // 2. 마크다운 → Notion 블록 변환
      final blocks = NotionBlockConverter.markdownToBlocks(minutes);
      
      // 3. 페이지 생성 payload 구성
      final payload = {
        'parent': {
          'type': 'page_id',
          'page_id': parentPageId,
        },
        'properties': {
          'title': {
            'title': [
              {
                'type': 'text',
                'text': {'content': title, 'link': null}
              }
            ]
          },
          // 선택: 메타데이터 추가
          'Date': {
            'date': {'start': meetingDate ?? DateTime.now().toIso8601String()}
          },
        },
        'children': blocks,
      };
      
      // 4. Notion API 호출
      final response = await _post(
        '/pages',
        payload,
      );
      
      if (response.statusCode != 200) {
        throw Exception('페이지 생성 실패: ${response.statusCode}');
      }
      
      final json = jsonDecode(response.body);
      final pageId = json['id'] as String;
      
      debugPrint('[Notion] 페이지 생성 완료: $pageId');
      return pageId;
    } catch (e) {
      debugPrint('[Notion] 저장 실패: $e');
      rethrow;
    }
  }
  
  /// Notion API POST 요청
  Future<http.Response> _post(String endpoint, Map<String, dynamic> body) {
    return http.post(
      Uri.parse('$_baseUrl$endpoint'),
      headers: {
        'Authorization': 'Bearer $apiToken',
        'Notion-Version': _notionVersion,
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    ).timeout(
      const Duration(seconds: 30),
      onTimeout: () => throw Exception('Notion API 타임아웃'),
    );
  }
  
  /// Notion API GET 요청
  Future<http.Response> _get(String endpoint) {
    return http.get(
      Uri.parse('$_baseUrl$endpoint'),
      headers: {
        'Authorization': 'Bearer $apiToken',
        'Notion-Version': _notionVersion,
      },
    ).timeout(
      const Duration(seconds: 30),
      onTimeout: () => throw Exception('Notion API 타임아웃'),
    );
  }
  
  /// URL에서 페이지 ID 추출
  /// https://www.notion.so/Page-Title-abc123def456 → abc123def456
  String _extractPageIdFromUrl(String url) {
    try {
      // URL 정규화
      final cleanUrl = url.replaceAll('?', '');
      final parts = cleanUrl.split('-');
      
      if (parts.isEmpty) return '';
      
      // 마지막 부분에서 페이지 ID 추출 (32자)
      final lastPart = parts.last;
      final pageId = lastPart.replaceAll(RegExp(r'[^\w]'), '');
      
      return pageId.length >= 32 ? pageId.substring(0, 32) : pageId;
    } catch (e) {
      debugPrint('[Notion] URL 파싱 실패: $url');
      return '';
    }
  }
  
  /// 연결 테스트
  Future<bool> testConnection() async {
    try {
      final response = await _get('/users/me');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[Notion] 연결 테스트 실패: $e');
      return false;
    }
  }
}
```

### 2. Notion 블록 변환기

**파일**: `lib/utils/notion_block_converter.dart`

```dart
class NotionBlockConverter {
  /// 마크다운 텍스트 → Notion 블록 배열 변환
  static List<Map<String, dynamic>> markdownToBlocks(String markdown) {
    final blocks = <Map<String, dynamic>>[];
    final lines = markdown.split('\n');
    
    int i = 0;
    while (i < lines.length) {
      final line = lines[i];
      
      if (line.isEmpty) {
        i++;
        continue;
      }
      
      // 제목 (# ## ###)
      if (line.startsWith('###')) {
        blocks.add(_heading3Block(line.replaceFirst('### ', '').trim()));
        i++;
      } else if (line.startsWith('##')) {
        blocks.add(_heading2Block(line.replaceFirst('## ', '').trim()));
        i++;
      } else if (line.startsWith('#')) {
        blocks.add(_heading1Block(line.replaceFirst('# ', '').trim()));
        i++;
      }
      
      // 리스트
      else if (line.startsWith('- ') || line.startsWith('* ')) {
        final itemContent = line.replaceFirst(RegExp(r'^[-*]\s'), '').trim();
        blocks.add(_bulletListBlock(itemContent));
        i++;
      } else if (line.startsWith('1. ') || RegExp(r'^\d+\.\s').hasMatch(line)) {
        final itemContent = line.replaceFirst(RegExp(r'^\d+\.\s'), '').trim();
        blocks.add(_numberedListBlock(itemContent));
        i++;
      }
      
      // 코드 블록
      else if (line.startsWith('```')) {
        final codeLines = <String>[];
        i++;
        while (i < lines.length && !lines[i].startsWith('```')) {
          codeLines.add(lines[i]);
          i++;
        }
        if (i < lines.length) i++; // 종료 ``` 건너뛰기
        blocks.add(_codeBlock(codeLines.join('\n')));
      }
      
      // 일반 단락
      else {
        blocks.add(_paragraphBlock(line));
        i++;
      }
    }
    
    return blocks;
  }
  
  // ─── 블록 생성 함수 ───
  
  static Map<String, dynamic> _heading1Block(String text) {
    return {
      'object': 'block',
      'type': 'heading_1',
      'heading_1': {
        'rich_text': [_richText(text)],
      },
    };
  }
  
  static Map<String, dynamic> _heading2Block(String text) {
    return {
      'object': 'block',
      'type': 'heading_2',
      'heading_2': {
        'rich_text': [_richText(text)],
      },
    };
  }
  
  static Map<String, dynamic> _heading3Block(String text) {
    return {
      'object': 'block',
      'type': 'heading_3',
      'heading_3': {
        'rich_text': [_richText(text)],
      },
    };
  }
  
  static Map<String, dynamic> _paragraphBlock(String text) {
    return {
      'object': 'block',
      'type': 'paragraph',
      'paragraph': {
        'rich_text': [_richText(text)],
      },
    };
  }
  
  static Map<String, dynamic> _bulletListBlock(String text) {
    return {
      'object': 'block',
      'type': 'bulleted_list_item',
      'bulleted_list_item': {
        'rich_text': [_richText(text)],
      },
    };
  }
  
  static Map<String, dynamic> _numberedListBlock(String text) {
    return {
      'object': 'block',
      'type': 'numbered_list_item',
      'numbered_list_item': {
        'rich_text': [_richText(text)],
      },
    };
  }
  
  static Map<String, dynamic> _codeBlock(String code) {
    return {
      'object': 'block',
      'type': 'code',
      'code': {
        'rich_text': [_richText(code)],
        'language': 'text',
      },
    };
  }
  
  static Map<String, dynamic> _quoteBlock(String text) {
    return {
      'object': 'block',
      'type': 'quote',
      'quote': {
        'rich_text': [_richText(text)],
      },
    };
  }
  
  static Map<String, dynamic> _richText(String content) {
    return {
      'type': 'text',
      'text': {
        'content': content,
        'link': null,
      },
      'annotations': {
        'bold': false,
        'italic': false,
        'strikethrough': false,
        'underline': false,
        'code': false,
        'color': 'default',
      },
    };
  }
  
  /// 볼드 텍스트 생성
  static Map<String, dynamic> _richTextBold(String content) {
    final rt = _richText(content);
    rt['annotations']['bold'] = true;
    return rt;
  }
  
  /// 이탤릭 텍스트 생성
  static Map<String, dynamic> _richTextItalic(String content) {
    final rt = _richText(content);
    rt['annotations']['italic'] = true;
    return rt;
  }
}
```

---

## Notion API 검증

### 인증 테스트

```dart
Future<bool> validateNotionSettings(String token, String pageUrl) async {
  final service = NotionSyncService(
    apiToken: token,
    pageUrl: pageUrl,
  );
  
  // 1. 연결 테스트
  final isConnected = await service.testConnection();
  if (!isConnected) return false;
  
  // 2. 페이지 ID 추출 검증
  final pageId = service._extractPageIdFromUrl(pageUrl);
  return pageId.isNotEmpty;
}
```

### 페이지 생성 테스트

```dart
Future<void> testPageCreation(String token, String pageUrl) async {
  final service = NotionSyncService(
    apiToken: token,
    pageUrl: pageUrl,
  );
  
  final testPageId = await service.saveMinutesToNotion(
    title: 'Test Meeting Minutes',
    minutes: '''## 회의록

### 주요 안건
- 안건 1
- 안건 2

### 결정사항
- 결정 1
''',
  );
  
  expect(testPageId.isNotEmpty, true);
}
```

---

## 에러 처리

| 에러 | 원인 | 해결책 |
|------|------|--------|
| 401 Unauthorized | 토큰 유효하지 않음 | 설정에서 토큰 확인 |
| 404 Not Found | 페이지 ID 잘못됨 | URL 재확인, 다시 추출 |
| 429 Rate Limited | API 호출 과다 | 지수 백오프 재시도 |
| 500 Internal Server Error | Notion 서버 에러 | 재시도 대기 |
| Timeout | 네트워크 느림 | 타임아웃 연장 (선택사항) |

---

## 재시도 전략

```dart
class RetryHelper {
  static Future<T> retry<T>(
    Future<T> Function() fn, {
    int maxRetries = 3,
  }) async {
    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        return await fn();
      } catch (e) {
        if (attempt == maxRetries - 1) rethrow;
        
        // 지수 백오프: 1초, 2초, 4초
        final delaySeconds = 1 << attempt;
        await Future.delayed(Duration(seconds: delaySeconds));
      }
    }
    throw Exception('재시도 실패');
  }
}
```

---

## 완료 체크리스트

- [ ] NotionSyncService 구현 (REST API 호출)
- [ ] NotionBlockConverter 구현 (마크다운 변환)
- [ ] 인증 검증 (Bearer Token)
- [ ] 페이지 URL 파싱 및 검증
- [ ] 에러 처리 (네트워크, 인증, 속도 제한)
- [ ] 재시도 로직 구현
- [ ] 단위 테스트 작성
- [ ] 통합 테스트 (실제 Notion 계정)

**산출물**: NotionSyncService, NotionBlockConverter 실제 구현 완료
