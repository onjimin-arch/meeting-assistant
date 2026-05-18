import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/meeting.dart';

/// 회의 로컬 저장소.
///
/// SharedPreferences에 회의 목록 전체를 JSON 문자열로 저장한다.
/// 데이터량이 적고(개당 수십 KB) 회의 수가 수백 개 미만이면 충분히 빠름.
/// 더 규모가 커지면 sqflite/drift로 전환 예정.
class MeetingRepository {
  static const String _key = 'meetings_v1';

  Future<List<Meeting>> loadAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null || raw.isEmpty) return [];
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => Meeting.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[MeetingRepo] loadAll 실패 (스키마 변경 가능성): $e');
      return [];
    }
  }

  Future<void> _saveAll(List<Meeting> meetings) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(meetings.map((m) => m.toJson()).toList());
    await prefs.setString(_key, raw);
  }

  /// 새 회의 추가 (최신순 정렬 유지: 맨 앞에 삽입)
  Future<List<Meeting>> append(Meeting meeting) async {
    final all = await loadAll();
    all.insert(0, meeting);
    await _saveAll(all);
    debugPrint('[MeetingRepo] 회의 저장됨: ${meeting.title}');
    return all;
  }

  /// 회의 삭제
  Future<List<Meeting>> remove(String id) async {
    final all = await loadAll();
    all.removeWhere((m) => m.id == id);
    await _saveAll(all);
    return all;
  }

  /// 회의 갱신 (예: Notion 저장 성공 시 notionPageId 추가)
  Future<List<Meeting>> update(Meeting updated) async {
    final all = await loadAll();
    final idx = all.indexWhere((m) => m.id == updated.id);
    if (idx >= 0) {
      all[idx] = updated;
      await _saveAll(all);
    }
    return all;
  }

  /// 전체 삭제 (디버그/리셋용)
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
