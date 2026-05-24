import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/meeting.dart';
import '../providers/app_state.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  final VoidCallback onBack;

  const SettingsScreen({required this.onBack, Key? key}) : super(key: key);

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late TextEditingController _openaiApiKeyController;
  late TextEditingController _pageUrlController;
  late TextEditingController _instructionsController;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(appSettingsProvider);
    _openaiApiKeyController =
        TextEditingController(text: settings.openaiApiKey ?? '');
    _pageUrlController =
        TextEditingController(text: settings.notionPageUrl ?? '');
    _instructionsController =
        TextEditingController(text: settings.minutesInstructions ?? '');
  }

  @override
  void dispose() {
    _openaiApiKeyController.dispose();
    _pageUrlController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appSettingsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF212121),
      body: SafeArea(
        child: Column(
          children: [
            // 헤더
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey[900]!, width: 1),
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
                  const Text(
                    '설정',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFececec),
                    ),
                  ),
                ],
              ),
            ),
            // 스크롤 영역
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── OpenAI API 키 ──────────────────────────────────
                    const Text(
                      'OPENAI',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: Color(0xFF8e8ea0),
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.1,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildTextField(
                      label: 'OpenAI API 키',
                      controller: _openaiApiKeyController,
                      placeholder: 'sk-...',
                      isPassword: true,
                    ),
                    const SizedBox(height: 24),

                    // ── STT 엔진 ───────────────────────────────────────
                    const Text(
                      'STT 엔진 (음성 → 텍스트)',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: Color(0xFF8e8ea0),
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.1,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildToggle(
                      activeLabel: 'OpenAI Whisper API',
                      activeSub: '클라우드 · 높은 정확도 · API 키 필요',
                      inactiveLabel: '플랫폼 내장 STT (무료)',
                      inactiveSub: 'Android/iOS 내장 · 오프라인 · 무료',
                      value: settings.useWhisperStt,
                      onTap: () => ref
                          .read(appSettingsProvider.notifier)
                          .toggleWhisperStt(!settings.useWhisperStt),
                    ),
                    const SizedBox(height: 24),

                    // ── 회의록 & 채팅 AI 엔진 ──────────────────────────
                    const Text(
                      '회의록 & 채팅 AI 엔진',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: Color(0xFF8e8ea0),
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.1,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildToggle(
                      activeLabel: '클라우드 GPT (OpenAI)',
                      activeSub: 'gpt-4o-mini · 인터넷 연결 필요',
                      inactiveLabel: '온디바이스 Gemma',
                      inactiveSub: 'Gemma 3 1B · ~530MB 다운로드 필요',
                      value: settings.useCloudLlm,
                      onTap: () => ref
                          .read(appSettingsProvider.notifier)
                          .toggleCloudLlm(!settings.useCloudLlm),
                    ),
                    const SizedBox(height: 10),
                    // API 키 사용 범위 안내
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1a1a1a),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFF10a37f).withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(children: [
                            Icon(Icons.info_outline,
                                size: 16, color: Color(0xFF10a37f)),
                            SizedBox(width: 8),
                            Text(
                              'OpenAI API 키 사용 범위',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF10a37f),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ]),
                          const SizedBox(height: 8),
                          Text(
                            '• STT: ${settings.useWhisperStt ? "Whisper API 사용 (키 필요)" : "플랫폼 내장 사용 (키 불필요)"}',
                            style: const TextStyle(
                                fontSize: 11, color: Color(0xFF8e8ea0)),
                          ),
                          Text(
                            '• 회의록/채팅: ${settings.useCloudLlm ? "OpenAI GPT 사용 (키 필요)" : "온디바이스 Gemma (키 불필요)"}',
                            style: const TextStyle(
                                fontSize: 11, color: Color(0xFF8e8ea0)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Notion 연동 ───────────────────────────────────
                    const Text(
                      'NOTION 연동',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: Color(0xFF8e8ea0),
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.1,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // API 토큰 — 고정값 표시 (편집 불가)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 13, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2f2f2f),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: const Color(0xFF3e3e3e), width: 1),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'API 토큰',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF8e8ea0)),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'xxxxxxxxxxx',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF8e8ea0),
                                    letterSpacing: 2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.lock_outline,
                              size: 16, color: Color(0xFF8e8ea0)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildTextField(
                      label: '노션 페이지 URL',
                      controller: _pageUrlController,
                      placeholder: 'https://notion.so/...',
                      isPassword: false,
                    ),
                    const SizedBox(height: 10),
                    // 자동 저장 토글
                    _buildToggle(
                      activeLabel: '회의록 작성 시 자동 저장',
                      activeSub: '작성 즉시 Notion에 자동으로 저장됩니다',
                      inactiveLabel: '회의록 작성 시 자동 저장',
                      inactiveSub: '작성 즉시 Notion에 자동으로 저장됩니다',
                      value: settings.autoSaveToNotion,
                      onTap: () => ref
                          .read(appSettingsProvider.notifier)
                          .toggleAutoSave(!settings.autoSaveToNotion),
                    ),
                    const SizedBox(height: 16),
                    // Notion 가이드
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1a1a1a),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFF10a37f).withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Row(children: [
                            Icon(Icons.info_outline,
                                size: 16, color: Color(0xFF10a37f)),
                            SizedBox(width: 8),
                            Text(
                              'Notion 연동 가이드',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF10a37f),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ]),
                          SizedBox(height: 8),
                          Text('1. Notion에서 저장할 페이지 열기',
                              style: TextStyle(
                                  fontSize: 11, color: Color(0xFF8e8ea0))),
                          Text('2. 우상단 "…" → "연결" → "AX Bot" 추가',
                              style: TextStyle(
                                  fontSize: 11, color: Color(0xFF8e8ea0))),
                          Text('3. 위 페이지 URL을 입력 후 저장',
                              style: TextStyle(
                                  fontSize: 11, color: Color(0xFF8e8ea0))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── 회의록 작성 지침 ──────────────────────────────
                    const Text(
                      '회의록 작성 지침',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: Color(0xFF8e8ea0),
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.1,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _instructionsController,
                      maxLines: 5,
                      style: const TextStyle(
                          color: Color(0xFFececec), fontSize: 13),
                      decoration: InputDecoration(
                        hintText:
                            '참석자, 결정사항, 액션아이템 위주로 작성하되 마감일도 포함...',
                        hintStyle:
                            const TextStyle(color: Color(0xFF8e8ea0)),
                        filled: true,
                        fillColor: const Color(0xFF2f2f2f),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                              color: Color(0xFF3e3e3e), width: 1),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                              color: Color(0xFF10a37f), width: 1),
                        ),
                        contentPadding: const EdgeInsets.all(10),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── 모델 정보 ─────────────────────────────────────
                    const Text(
                      '모델 정보',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: Color(0xFF8e8ea0),
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.1,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      clipBehavior: Clip.hardEdge,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2f2f2f),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: const Color(0xFF3e3e3e), width: 1),
                      ),
                      child: Column(
                        children: [
                          _buildInfoRow(
                            'STT 엔진',
                            settings.useWhisperStt
                                ? 'OpenAI Whisper API'
                                : '플랫폼 내장 STT',
                            0,
                          ),
                          _buildInfoRow(
                            '회의록 & 채팅',
                            settings.useCloudLlm
                                ? 'OpenAI GPT-4o mini'
                                : 'Gemma 3 1B on-device',
                            1,
                          ),
                          _buildInfoRow(
                            'LLM 처리',
                            settings.useCloudLlm
                                ? '클라우드 (인터넷 필요)'
                                : '온디바이스 (오프라인 가능)',
                            2,
                          ),
                          _buildInfoRow(
                            '지원 플랫폼',
                            'Android / iOS',
                            3,
                            isLast: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ── 저장 버튼 ─────────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          ref
                              .read(appSettingsProvider.notifier)
                              .updateSettings(
                                AppSettings(
                                  notionToken: settings.notionToken,
                                  notionPageUrl: _pageUrlController.text.isEmpty
                                      ? null
                                      : _pageUrlController.text,
                                  autoSaveToNotion: settings.autoSaveToNotion,
                                  minutesInstructions:
                                      _instructionsController.text.isEmpty
                                          ? null
                                          : _instructionsController.text,
                                  openaiApiKey:
                                      _openaiApiKeyController.text.isEmpty
                                          ? null
                                          : _openaiApiKeyController.text,
                                  useCloudLlm: settings.useCloudLlm,
                                  useWhisperStt: settings.useWhisperStt,
                                ),
                              );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('설정이 저장되었습니다.')),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10a37f),
                          padding:
                              const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          '저장',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggle({
    required String activeLabel,
    required String activeSub,
    required String inactiveLabel,
    required String inactiveSub,
    required bool value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF2f2f2f),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF3e3e3e), width: 1),
        ),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value ? activeLabel : inactiveLabel,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFFececec),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value ? activeSub : inactiveSub,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF8e8ea0),
                  ),
                ),
              ],
            ),
            Container(
              width: 42,
              height: 24,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: value
                    ? const Color(0xFF10a37f)
                    : const Color(0xFF3e3e3e),
              ),
              child: Stack(
                children: [
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 200),
                    left: value ? 18 : 2,
                    top: 2,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(50),
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 3,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String placeholder,
    required bool isPassword,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF8e8ea0)),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: isPassword,
          style: const TextStyle(color: Color(0xFFececec), fontSize: 13),
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: const TextStyle(color: Color(0xFF8e8ea0)),
            filled: true,
            fillColor: const Color(0xFF2f2f2f),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: Color(0xFF3e3e3e), width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: Color(0xFF10a37f), width: 1),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(
    String key,
    String value,
    int index, {
    bool isLast = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: !isLast
            ? Border(
                bottom: BorderSide(color: Colors.grey[900]!, width: 1))
            : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(key,
              style: const TextStyle(
                  fontSize: 13, color: Color(0xFF8e8ea0))),
          Text(value,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF10a37f),
                fontWeight: FontWeight.w500,
              )),
        ],
      ),
    );
  }
}
