import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Notion API 연동 서비스
class NotionSyncService {
  final String? apiToken;
  final String? pageUrl;

  NotionSyncService({this.apiToken, this.pageUrl});

  /// 회의록을 Notion 페이지에 저장
  Future<String> saveMinutesToNotion({
    required String title,
    required String minutes,
  }) async {
    if (apiToken == null || pageUrl == null) {
      throw Exception('Notion 설정이 필요합니다');
    }

    try {
      debugPrint('[Notion] 저장 시작: $title');

      // 실제 구현: Notion REST API v1 사용
      // final pageId = _extractPageIdFromUrl(pageUrl!);
      // final response = await http.post(
      //   Uri.parse('https://api.notion.com/v1/pages'),
      //   headers: {
      //     'Authorization': 'Bearer $apiToken',
      //     'Notion-Version': '2022-06-28',
      //     'Content-Type': 'application/json',
      //   },
      //   body: jsonEncode(_buildNotionPagePayload(title, minutes, pageId)),
      // );

      // 임시 mock
      await Future.delayed(const Duration(seconds: 1));
      const String pageId = 'mock_page_id_${DateTime.now().millisecondsSinceEpoch}';

      debugPrint('[Notion] 저장 완료: $pageId');
      return pageId;
    } catch (e) {
      debugPrint('[Notion] 저장 실패: $e');
      rethrow;
    }
  }

  /// URL에서 페이지 ID 추출
  String _extractPageIdFromUrl(String url) {
    // https://notion.so/page-title-xxx -> xxx 추출
    final parts = url.split('-');
    return parts.last.replaceAll(RegExp(r'[^\w]'), '');
  }

  /// Notion 페이지 생성 payload 구성
  Map<String, dynamic> _buildNotionPagePayload(
    String title,
    String minutes,
    String parentPageId,
  ) {
    return {
      'parent': {'type': 'page_id', 'page_id': parentPageId},
      'properties': {
        'title': {
          'title': [
            {'type': 'text', 'text': {'content': title}}
          ]
        },
      },
      'children': [
        {
          'object': 'block',
          'type': 'paragraph',
          'paragraph': {
            'rich_text': [
              {'type': 'text', 'text': {'content': minutes}}
            ]
          }
        }
      ]
    };
  }
}
