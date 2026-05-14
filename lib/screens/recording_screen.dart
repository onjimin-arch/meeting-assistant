import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/meeting.dart';

class RecordingScreen extends ConsumerStatefulWidget {
  final VoidCallback onStop;

  const RecordingScreen({required this.onStop, Key? key}) : super(key: key);

  @override
  ConsumerState<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends ConsumerState<RecordingScreen> {
  int _seconds = 0;
  late List<double> _waveform;

  @override
  void initState() {
    super.initState();
    _waveform = List.filled(30, 20);
    _startTimer();
    _startWaveform();
  }

  void _startTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() {
          _seconds++;
        });
      }
      return mounted;
    });
  }

  void _startWaveform() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 120));
      if (mounted) {
        setState(() {
          _waveform = List.generate(30,
              (i) => 15 + (60 * (0.3 + (0.7 * (i % 2)))));
        });
      }
      return mounted;
    });
  }

  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF212121),
      body: Column(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // REC 뱃지
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2f2f2f),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: const Color(0xFFef4444),
                          borderRadius: BorderRadius.circular(50),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'REC',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF8e8ea0),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                // 웨이브폼
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    for (int i = 0; i < _waveform.length; i++)
                      Expanded(
                        child: Container(
                          height: (_waveform[i] / 100) * 64,
                          margin: const EdgeInsets.symmetric(horizontal: 1.5),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            color: i % 3 == 0
                                ? const Color(0xFF10a37f)
                                : const Color(0xFF8e8ea0),
                          ),
                          opacity: i % 3 == 0 ? 0.9 : 0.3,
                        ),
                      )
                  ],
                ),
                // 타이머
                Text(
                  _formatTime(_seconds),
                  style: const TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.w200,
                    color: Color(0xFFececec),
                    letterSpacing: 0.06,
                  ),
                ),
                // 종료 버튼
                GestureDetector(
                  onTap: widget.onStop,
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: const Color(0xFFef4444),
                      borderRadius: BorderRadius.circular(50),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFef4444).withOpacity(0.2),
                          spreadRadius: 10,
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: Container(
                      margin: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                ),
                const Text(
                  '탭하여 종료',
                  style: TextStyle(
                    color: Color(0xFF8e8ea0),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
