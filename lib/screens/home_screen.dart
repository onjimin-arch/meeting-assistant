import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/meeting.dart';
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
    // 임시 회의 목록
    final meetings = [
      Meeting(
        id: '1',
        title: '2025 Q2 전략 회의',
        dateTime: DateTime.now(),
        duration: 2700,
        transcript: '이지민: 네, 다들 들어오셨으면 시작할게요...',
        minutes: '## 회의록\n...',
        audioPath: '/data/audio_1.m4a',
        createdAt: DateTime.now(),
        notionSaved: false,
      ),
      Meeting(
        id: '2',
        title: '신규 서비스 기획 킥오프',
        dateTime: DateTime.now().subtract(const Duration(days: 1)),
        duration: 4800,
        transcript: '김철수: 신서비스 팀이 기획...',
        minutes: '## 회의록\n...',
        audioPath: '/data/audio_2.m4a',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        notionSaved: false,
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF212121),
      body: Column(
        children: [
          // 헤더
          Container(
            padding: const EdgeInsets.only(top: 16, left: 20, right: 20, bottom: 14),
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
            child: ListView.builder(
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
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
    );
  }
}
