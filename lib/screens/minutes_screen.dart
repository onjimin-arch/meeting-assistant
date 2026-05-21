import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/meeting.dart';
import '../providers/app_state.dart';
import '../services/notion_sync_service.dart';

class MinutesScreen extends ConsumerStatefulWidget {
  final Meeting meeting;
  final VoidCallback onBack;
  final VoidCallback onChat;
  final bool autoSave;

  const MinutesScreen({
    required this.meeting,
    required this.onBack,
    required this.onChat,
    required this.autoSave,
    Key? key,
  }) : super(key: key);

  @override
  ConsumerState<MinutesScreen> createState() => _MinutesScreenState();
}

class _MinutesScreenState extends ConsumerState<MinutesScreen> {
  bool _showTranscript = false;
  bool _copied = false;
  bool _savingToNotion = false;

  void _copyTranscript() async {
    await Clipboard.setData(ClipboardData(text: widget.meeting.transcript));
    setState(() {
      _copied = true;
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  Future<void> _saveToNotion() async {
    final settings = ref.read(appSettingsProvider);
    if (settings.notionToken == null || settings.notionPageUrl == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notion 설정이 필요합니다. 설정에서 토큰과 페이지 URL을 입력하세요.'),
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }

    setState(() {
      _savingToNotion = true;
    });

    try {
      final notionService = NotionSyncService(
        apiToken: settings.notionToken,
        pageUrl: settings.notionPageUrl,
      );
      final pageId = await notionService.saveMinutesToNotion(
        title: widget.meeting.title,
        minutes: widget.meeting.minutes,
      );

      if (!mounted) return;
      // 회의 데이터 업데이트
      final updatedMeeting = widget.meeting.copyWith(
        notionPageId: pageId,
        notionSaved: true,
      );
      await ref.read(meetingsProvider.notifier).updateOne(updatedMeeting);
      ref.read(currentMeetingProvider.notifier).state = updatedMeeting;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notion에 저장되었습니다.'),
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Notion 저장 실패: $e'),
          duration: const Duration(seconds: 5),
          backgroundColor: const Color(0xFF8B4513),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _savingToNotion = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final durMins = widget.meeting.duration ~/ 60;
    final durSecs = widget.meeting.duration % 60;

    return Scaffold(
      backgroundColor: const Color(0xFF212121),
      body: SafeArea(
        child: Column(
        children: [
          // 헤더
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey[900]!,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: widget.onBack,
                  icon: const Icon(Icons.arrow_back_ios, size: 20),
                  color: const Color(0xFF8e8ea0),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 40),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.meeting.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFececec),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${DateFormat('M월 d일 HH:mm').format(widget.meeting.dateTime)} · ${durMins}분 ${durSecs}초',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF8e8ea0),
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: _savingToNotion ? null : _saveToNotion,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.meeting.notionSaved
                        ? const Color(0xFF1a3a2e)
                        : const Color(0xFF3a3a3a),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9),
                      side: const BorderSide(
                        color: Color(0xFF3e3e3e),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      if (_savingToNotion)
                        const SizedBox(
                          width: 13,
                          height: 13,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10a37f)),
                          ),
                        )
                      else
                        Icon(
                          widget.meeting.notionSaved ? Icons.check : Icons.share,
                          size: 13,
                          color: widget.meeting.notionSaved
                              ? const Color(0xFF10a37f)
                              : Colors.white,
                        ),
                      const SizedBox(width: 6),
                      Text(
                        widget.meeting.notionSaved ? '저장됨' : 'Notion 저장',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFFececec),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // 스크롤 영역
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // 스크립트 토글 바
                  Material(
                    color: const Color(0xFF212121),
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _showTranscript = !_showTranscript),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 0),
                        height: 42,
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.grey[900]!,
                              width: 1,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _showTranscript
                                  ? Icons.arrow_forward_ios
                                  : Icons.arrow_forward_ios,
                              size: 11,
                              color: const Color(0xFF8e8ea0),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              '원본 스크립트 보기',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: Color(0xFF8e8ea0),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            if (_showTranscript)
                              GestureDetector(
                                onTap: _copyTranscript,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(7),
                                    color: _copied
                                        ? const Color(0xFF1a3a2e)
                                        : const Color(0xFF2f2f2f),
                                    border: Border.all(
                                      color: _copied
                                          ? const Color(0xFF10a37f)
                                          : const Color(0xFF3e3e3e),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        _copied ? Icons.check : Icons.copy,
                                        size: 11,
                                        color: _copied
                                            ? const Color(0xFF10a37f)
                                            : const Color(0xFF8e8ea0),
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        _copied ? '복사됨' : '복사',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: _copied
                                              ? const Color(0xFF10a37f)
                                              : const Color(0xFF8e8ea0),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // 스크립트 본문
                  if (_showTranscript)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      color: const Color(0xFF2f2f2f),
                      child: Text(
                        widget.meeting.transcript,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF8e8ea0),
                          height: 1.9,
                        ),
                      ),
                    ),
                  // 회의록 본문
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      widget.meeting.minutes,
                      style: const TextStyle(
                        fontSize: 13.5,
                        color: Color(0xFFececec),
                        height: 1.8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),
          // 추가 작업 버튼
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: widget.onChat,
                icon: const Icon(Icons.chat, color: Colors.white, size: 15),
                label: const Text(
                  '추가 작업 요청',
                  style: TextStyle(color: Color(0xFF8e8ea0), fontSize: 14),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2f2f2f),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                    side: const BorderSide(
                      color: Color(0xFF3e3e3e),
                      width: 1,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }
}
