import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/meeting.dart';

class AppSettingsService {
  static const String _notionTokenKey = 'notion_token';
  static const String _notionPageUrlKey = 'notion_page_url';
  static const String _autoSaveKey = 'auto_save_to_notion';
  static const String _minutesInstructionsKey = 'minutes_instructions';
  static const String _openaiApiKeyKey = 'openai_api_key';
  static const String _useCloudLlmKey = 'use_cloud_llm';
  static const String _useWhisperSttKey = 'use_whisper_stt';

  static const String kHardcodedNotionToken =
      String.fromEnvironment('NOTION_TOKEN', defaultValue: '');

  Future<AppSettings> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return AppSettings(
        notionToken: prefs.getString(_notionTokenKey) ?? kHardcodedNotionToken,
        notionPageUrl: prefs.getString(_notionPageUrlKey),
        autoSaveToNotion: prefs.getBool(_autoSaveKey) ?? false,
        minutesInstructions: prefs.getString(_minutesInstructionsKey),
        openaiApiKey: prefs.getString(_openaiApiKeyKey),
        useCloudLlm: prefs.getBool(_useCloudLlmKey) ?? false,
        useWhisperStt: prefs.getBool(_useWhisperSttKey) ?? true,
      );
    } catch (e) {
      debugPrint('[Settings] 설정 로드 실패: $e');
      return AppSettings(notionToken: kHardcodedNotionToken);
    }
  }

  Future<void> saveSettings(AppSettings settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await Future.wait([
        prefs.setString(_notionTokenKey, kHardcodedNotionToken),
        if (settings.notionPageUrl != null)
          prefs.setString(_notionPageUrlKey, settings.notionPageUrl!)
        else
          prefs.remove(_notionPageUrlKey),
        prefs.setBool(_autoSaveKey, settings.autoSaveToNotion),
        if (settings.minutesInstructions != null)
          prefs.setString(_minutesInstructionsKey, settings.minutesInstructions!)
        else
          prefs.remove(_minutesInstructionsKey),
        if (settings.openaiApiKey != null)
          prefs.setString(_openaiApiKeyKey, settings.openaiApiKey!)
        else
          prefs.remove(_openaiApiKeyKey),
        prefs.setBool(_useCloudLlmKey, settings.useCloudLlm),
        prefs.setBool(_useWhisperSttKey, settings.useWhisperStt),
      ]);
      debugPrint('[Settings] 설정 저장 완료');
    } catch (e) {
      debugPrint('[Settings] 설정 저장 실패: $e');
      rethrow;
    }
  }
}
