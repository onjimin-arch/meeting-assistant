import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/meeting.dart';

/// 앱 설정 서비스
class AppSettingsService {
  static const String _notionTokenKey = 'notion_token';
  static const String _notionPageUrlKey = 'notion_page_url';
  static const String _autoSaveKey = 'auto_save_to_notion';
  static const String _minutesInstructionsKey = 'minutes_instructions';

  /// 설정 로드
  Future<AppSettings> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      return AppSettings(
        notionToken: prefs.getString(_notionTokenKey),
        notionPageUrl: prefs.getString(_notionPageUrlKey),
        autoSaveToNotion: prefs.getBool(_autoSaveKey) ?? false,
        minutesInstructions: prefs.getString(_minutesInstructionsKey),
      );
    } catch (e) {
      debugPrint('[Settings] 설정 로드 실패: $e');
      return AppSettings();
    }
  }

  /// 설정 저장
  Future<void> saveSettings(AppSettings settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await Future.wait([
        if (settings.notionToken != null)
          prefs.setString(_notionTokenKey, settings.notionToken!)
        else
          prefs.remove(_notionTokenKey),
        if (settings.notionPageUrl != null)
          prefs.setString(_notionPageUrlKey, settings.notionPageUrl!)
        else
          prefs.remove(_notionPageUrlKey),
        prefs.setBool(_autoSaveKey, settings.autoSaveToNotion),
        if (settings.minutesInstructions != null)
          prefs.setString(_minutesInstructionsKey, settings.minutesInstructions!)
        else
          prefs.remove(_minutesInstructionsKey),
      ]);

      debugPrint('[Settings] 설정 저장 완료');
    } catch (e) {
      debugPrint('[Settings] 설정 저장 실패: $e');
      rethrow;
    }
  }
}
