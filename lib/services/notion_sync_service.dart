import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class NotionSyncService {
  final String? apiToken;
  final String? pageUrl;

  NotionSyncService({this.apiToken, this.pageUrl});

  Future<String> saveMinutesToNotion({
    required String title,
    required String minutes,
    DateTime? dateTime,
  }) async {
    if (apiToken == null || pageUrl == null) {
      throw Exception('Notion 설정이 필요합니다');
    }

    final headers = {
      'Authorization': 'Bearer $apiToken',
      'Notion-Version': '2022-06-28',
      'Content-Type': 'application/json',
    };

    // Extract a better title from the first ## heading in minutes
    final effectiveTitle = _extractTitle(title, minutes);
    debugPrint('[Notion] 저장 시작: $effectiveTitle');
    final parentId = _extractPageIdFromUrl(pageUrl!);
    debugPrint('[Notion] parent ID: $parentId');

    // Try page_id first, fall back to database_id on 404
    for (final parentType in ['page_id', 'database_id']) {
      debugPrint('[Notion] trying parent type: $parentType');
      final payload = _buildNotionPagePayload(effectiveTitle, minutes, parentId, parentType, dateTime);
      final response = await http.post(
        Uri.parse('https://api.notion.com/v1/pages'),
        headers: headers,
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final pageId = data['id'] as String;
        debugPrint('[Notion] 저장 완료 ($parentType): $pageId');
        return pageId;
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final code = body['code'] as String? ?? '';
      debugPrint('[Notion] $parentType failed (${response.statusCode}): $code');

      // Only retry on "object not found" errors
      if (response.statusCode != 404 || !['object_not_found', 'Could not find'].any((s) => (body['message'] as String? ?? '').contains(s))) {
        final msg = body['message'] ?? response.body;
        throw Exception('Notion API 오류 (${response.statusCode}): $msg');
      }
    }

    throw Exception('Notion 페이지를 찾을 수 없습니다. 설정의 페이지 URL을 확인해 주세요.');
  }

  String _extractPageIdFromUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return url;

    String lastSegment = (uri.pathSegments.isNotEmpty)
        ? uri.pathSegments.last
        : url;

    // Remove trailing slashes / query
    lastSegment = lastSegment.split('?').first.trim();

    // Already a UUID with dashes (32 hex chars = 8+4+4+4+12)
    if (RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$')
        .hasMatch(lastSegment)) {
      return lastSegment;
    }

    // 32-char hex without dashes (e.g. 33e363ae08db802cbc05d613956a1d50)
    final raw = lastSegment.replaceAll('-', '');
    final match = RegExp(r'([0-9a-f]{32})$').firstMatch(raw);
    if (match != null) {
      final h = match.group(1)!;
      return '${h.substring(0, 8)}-${h.substring(8, 12)}-'
          '${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20)}';
    }

    return lastSegment;
  }

  String _extractTitle(String fallback, String minutes) {
    for (final line in minutes.split('\n')) {
      final t = line.trim();
      if (t.startsWith('## ')) return t.substring(3).trim();
      if (t.startsWith('# ')) return t.substring(2).trim();
    }
    return fallback;
  }

  Map<String, dynamic> _buildNotionPagePayload(
    String title,
    String minutes,
    String parentPageId,
    String parentType,
    DateTime? dateTime,
  ) {
    final blocks = _markdownToNotionBlocks(minutes);
    // Notion API accepts at most 100 children per request
    final children = blocks.length > 100 ? blocks.sublist(0, 100) : blocks;

    final properties = <String, dynamic>{
      'title': {
        'title': [
          {'type': 'text', 'text': {'content': title}}
        ]
      },
    };

    if (dateTime != null) {
      final dateStr = '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
      properties['날짜'] = {'date': {'start': dateStr}};
    }

    return {
      'parent': {'type': parentType, parentType: parentPageId},
      'properties': properties,
      'children': children,
    };
  }

  List<Map<String, dynamic>> _markdownToNotionBlocks(String markdown) {
    final blocks = <Map<String, dynamic>>[];
    for (final line in markdown.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      if (trimmed.startsWith('### ')) {
        blocks.add(_headingBlock(3, trimmed.substring(4)));
      } else if (trimmed.startsWith('## ')) {
        blocks.add(_headingBlock(2, trimmed.substring(3)));
      } else if (trimmed.startsWith('# ')) {
        blocks.add(_headingBlock(1, trimmed.substring(2)));
      } else if (trimmed.startsWith('* ') || trimmed.startsWith('- ')) {
        blocks.add(_bulletBlock(trimmed.substring(2)));
      } else {
        blocks.add(_paragraphBlock(trimmed));
      }
    }
    return blocks.isNotEmpty ? blocks : [_paragraphBlock(markdown)];
  }

  Map<String, dynamic> _headingBlock(int level, String text) => {
        'object': 'block',
        'type': 'heading_$level',
        'heading_$level': {'rich_text': _parseInline(text)},
      };

  Map<String, dynamic> _bulletBlock(String text) => {
        'object': 'block',
        'type': 'bulleted_list_item',
        'bulleted_list_item': {'rich_text': _parseInline(text)},
      };

  Map<String, dynamic> _paragraphBlock(String text) => {
        'object': 'block',
        'type': 'paragraph',
        'paragraph': {'rich_text': _parseInline(text)},
      };

  List<Map<String, dynamic>> _parseInline(String text) {
    final parts = <Map<String, dynamic>>[];
    int last = 0;
    for (final m in RegExp(r'\*\*(.+?)\*\*').allMatches(text)) {
      if (m.start > last) parts.add(_rt(text.substring(last, m.start)));
      parts.add(_rt(m.group(1)!, bold: true));
      last = m.end;
    }
    if (last < text.length) parts.add(_rt(text.substring(last)));
    return parts.isEmpty ? [_rt(text)] : parts;
  }

  Map<String, dynamic> _rt(String text, {bool bold = false}) {
    final content = text.length > 2000 ? text.substring(0, 2000) : text;
    return {
      'type': 'text',
      'text': {'content': content},
      if (bold) 'annotations': {'bold': true},
    };
  }
}
