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
  late TextEditingController _tokenController;
  late TextEditingController _pageUrlController;
  late TextEditingController _instructionsController;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(appSettingsProvider);
    _tokenController = TextEditingController(text: settings.notionToken ?? '');
    _pageUrlController = TextEditingController(text: settings.notionPageUrl ?? '');
    _instructionsController =
        TextEditingController(text: settings.minutesInstructions ?? '');
  }

  @override
  void dispose() {
    _tokenController.dispose();
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
            // ?§Îçî
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
                  const Text(
                    '?§Ï†ï',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFececec),
                    ),
                  ),
                ],
              ),
            ),
            // ?§ÌÅ¨Î°??ÅÏó≠
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Notion ?∞Îèô
                    const Text(
                      'NOTION ?∞Îèô',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: Color(0xFF8e8ea0),
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.1,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildTextField(
                      label: 'API ?†ÌÅ∞',
                      controller: _tokenController,
                      placeholder: 'secret_xxxxxxxxx',
                      isPassword: true,
                      showValue: false,
                    ),
                    const SizedBox(height: 10),
                    _buildTextField(
                      label: '?Ä???òÏù¥ÏßÄ URL',
                      controller: _pageUrlController,
                      placeholder: 'https://notion.so/...',
                      isPassword: false,
                    ),
                    const SizedBox(height: 10),
                    // ?êÎèô ?Ä???†Í?
                    GestureDetector(
                      onTap: () {
                        ref
                            .read(appSettingsProvider.notifier)
                            .toggleAutoSave(!settings.autoSaveToNotion);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF2f2f2f),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFF3e3e3e),
                            width: 1,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 11,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  '?åÏùòÎ°??ÑÏÑ± ???êÎèô ?Ä??,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFFececec),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  '?ÑÏÑ± Ï¶âÏãú Notion ???êÎèô?ºÎ°ú ?Ä?•Îê©?àÎã§',
                                  style: TextStyle(
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
                                color: settings.autoSaveToNotion
                                    ? const Color(0xFF10a37f)
                                    : const Color(0xFF3e3e3e),
                              ),
                              child: Stack(
                                children: [
                                  AnimatedPositioned(
                                    duration: const Duration(milliseconds: 200),
                                    left: settings.autoSaveToNotion ? 18 : 2,
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
                    ),
                    const SizedBox(height: 16),
                    // Notion Í∞Ä?¥Îìú
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1a1a1a),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFF10a37f)withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 16,
                                color: Color(0xFF10a37f),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Notion ?∞Îèô Í∞Ä?¥Îìú',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF10a37f),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            '1. Not ?êÏÑú "???òÏù¥ÏßÄ ?ùÏÑ±"',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF8e8ea0),
                            ),
                          ),
                          Text(
                            '2. "?∞Í≤∞" ??"AX Bot" Ï∂îÍ?',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF8e8ea0),
                            ),
                          ),
                          Text(
                            '3. ?òÏù¥ÏßÄ Í≥µÏú† ??"Ï¥àÎ?" ??"AX Bot" ?†ÌÉù',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF8e8ea0),
                            ),
                          ),
                          Text(
                            '4. API ?†ÌÅ∞ ?ÖÎ†•',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF8e8ea0),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // ?åÏùòÎ°??ëÏÑ± ÏßÄÏπ?                    const Text(
                      '?åÏùòÎ°??ëÏÑ± ÏßÄÏπ?,
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
                        color: Color(0xFFececec),
                        fontSize: 13,
                      ),
                      decoration: InputDecoration(
                        hintText:
                            '?? Ï∞∏ÏÑù?? ?àÍ±¥, Í≤∞Ï†ï?¨Ìï≠, ?°ÏÖò?ÑÏù¥???úÏúºÎ°??ëÏÑ±?òÎêò ?¥Îãπ?êÏ? ÎßàÍ∞ê???¨Ìï®...',
                        hintStyle: const TextStyle(
                          color: Color(0xFF8e8ea0),
                        ),
                        filled: true,
                        fillColor: const Color(0xFF2f2f2f),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Color(0xFF3e3e3e),
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Color(0xFF10a37f),
                            width: 1,
                          ),
                        ),
                        contentPadding: const EdgeInsets.all(10),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Î™®Îç∏ ?ïÎ≥¥
                    const Text(
                      'Î™®Îç∏ ?ïÎ≥¥',
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
                          color: const Color(0xFF3e3e3e),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          _buildInfoRow('STT ?îÏßÑ', '?åÎû´???¥Ïû• (Google/Apple)', 0),
                          _buildInfoRow('LLM Î™®Îç∏', 'Gemma 4 2B', 1),
                          _buildInfoRow('Ï≤òÎ¶¨ Î∞©Ïãù', '?®ÎîîÎ∞îÏù¥??, 2),
                          _buildInfoRow(
                            'ÏßÄ???åÎû´??,
                            'Android / iOS',
                            3,
                            isLast: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    // ?Ä??Î≤ÑÌäº
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          ref
                              .read(appSettingsProvider.notifier)
                              .updateSettings(
                                AppSettings(
                                  notionToken: _tokenController.text,
                                  notionPageUrl: _pageUrlController.text,
                                  autoSaveToNotion: settings.autoSaveToNotion,
                                  minutesInstructions:
                                      _instructionsController.text,
                                ),
                              );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('?§Ï†ï???Ä?•Îêò?àÏäµ?àÎã§.')),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10a37f),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          '?Ä??,
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

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String placeholder,
    required bool isPassword,
    bool showValue = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF8e8ea0),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: isPassword && showValue,
          style: const TextStyle(
            color: Color(0xFFececec),
            fontSize: 13,
          ),
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: const TextStyle(
              color: Color(0xFF8e8ea0),
            ),
            filled: true,
            fillColor: const Color(0xFF2f2f2f),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Color(0xFF3e3e3e),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Color(0xFF10a37f),
                width: 1,
              ),
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
                bottom: BorderSide(
                  color: Colors.grey[900]!,
                  width: 1,
                ),
              )
            : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            key,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF8e8ea0),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF10a37f),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
