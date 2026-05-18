import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/meeting.dart';
import '../providers/app_state.dart';
import 'package:intl/intl.dart';

class HomeScreen extends ConsumerWidget {
  final VoidCallback onStartRecording;
  final Function(Meeting) onSelectMeeting;
  final VoidCallback onSettings;

  const HomeScreen({
    required this.onStartRecording,
    required this.onSelectMeeting,
    required this.onSettings,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meetings = ref.watch(meetingsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF212121),
      body: SafeArea(
        child: Column(
        children: [
          // 헤더
          Container(
            padding: const EdgeInsets.only(top: 8, left: 20, right: 20, bottom: 14),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey[800]!, width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Meeting Assistant',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFececec),
                  ),
                ),
                IconButton(
                  onPressed: onSettings,
                  icon: const Icon(Icons.settings, size: 19),
                  color: const Color(0xFF8e8ea0),
                  padding: const EdgeInsets.all(6),
                ),
              ],
            ),
          ),
          // 회의 목록
          Expanded(
            child: meetings.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: meetings.length,
              itemBuilder: (context, index) {
                final meeting = meetings[index];
                final dateStr = DateFormat('M월 d일').format(meeting.dateTime);
                final timeStr = DateFormat('HH:mm').format(meeting.dateTime);
                final durationStr =
                    '${meeting.duration ~/ 60}분 ${meeting.duration % 60}초';

                return GestureDetector(
                  onTap: () => onSelectMeeting(meeting),
                  onLongPress: () => _confirmDelete(context, ref, meeting),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 2),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: const Color(0xFF2f2f2f),
                    ),
                    child: Row(
                      children: [
                        // 문서 아이콘
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: const Color(0xFF3a3a3a),
                          ),
                          child: const Icon(
                            Icons.description,
                            color: Color(0xFF10a37f),
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // 정보
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                meeting.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFFececec),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$dateStr $timeStr · $durationStr',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF8e8ea0),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios,
                          color: Color(0xFF8e8ea0),
                          size: 14,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // 녹음 버튼
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onStartRecording,
                icon: const Icon(Icons.mic, color: Colors.white, size: 18),
                label: const Text(
                  '새 회의 녹음',
                  style: TextStyle(color: Colors.white, fontSize: 15),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10a37f),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
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

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.mic_none, size: 56, color: Colors.grey[700]),
            const SizedBox(height: 16),
            const Text(
              '아직 녹음한 회의가 없습니다',
              style: TextStyle(
                fontSize: 15,
                color: Color(0xFFececec),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '아래 "새 회의 녹음" 버튼을 눌러 시작하세요',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Color(0xFF8e8ea0)),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, WidgetRef ref, Meeting meeting) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2f2f2f),
        title: const Text(
          '회의 삭제',
          style: TextStyle(color: Color(0xFFececec)),
        ),
        content: Text(
          '"${meeting.title}"을(를) 삭제할까요?\n이 작업은 되돌릴 수 없습니다.',
          style: const TextStyle(color: Color(0xFFececec)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              '삭제',
              style: TextStyle(color: Color(0xFFef4444)),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(meetingsProvider.notifier).remove(meeting.id);
    }
  }
}
