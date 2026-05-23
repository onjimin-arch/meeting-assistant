import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProcessingScreen extends ConsumerWidget {
  final int step;
  final bool autoSave;

  const ProcessingScreen({
    required this.step,
    required this.autoSave,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final steps = [
      {'label': '음성 파일 변환 중', 'sub': 'OpenAI Whisper API'},
      {'label': '회의록 생성 중', 'sub': 'Gemma 3 1B on-device'},
      if (autoSave) {'label': 'Notion에 저장 중', 'sub': '지정 페이지에 업로드'},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF212121),
      body: SafeArea(
        child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 로딩 스피너
            SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF10a37f),
                ),
                strokeWidth: 2.5,
              ),
            ),
            const SizedBox(height: 36),
            // 단계별 진행
            SizedBox(
              width: 260,
              child: Column(
                children: [
                  for (int i = 0; i < steps.length; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        children: [
                          // 단계 표시자
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: step > i
                                  ? const Color(0xFF10a37f)
                                  : const Color(0xFF3a3a3a),
                              border: step == i
                                  ? Border.all(
                                      color: const Color(0xFF10a37f),
                                      width: 2,
                                    )
                                  : null,
                            ),
                            child: step > i
                                ? const Icon(
                                    Icons.check,
                                    size: 10,
                                    color: Colors.white,
                                  )
                                : step == i
                                    ? Container(
                                        width: 5,
                                        height: 5,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: const Color(0xFF10a37f),
                                        ),
                                      )
                                    : null,
                          ),
                          const SizedBox(width: 14),
                          // 텍스트
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                steps[i]['label']!,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFFececec)
                                      .withOpacity(step >= i ? 1 : 0.3),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                steps[i]['sub']!,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: const Color(0xFF8e8ea0)
                                      .withOpacity(step >= i ? 1 : 0.3),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}
