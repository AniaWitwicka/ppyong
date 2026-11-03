import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ── Quiz question ──────────────────────────────────────────────────────────

/// One multiple-choice question: prompt card, up to 4 options, Next button.
/// Shared by the Multiple choice game and the test after a flashcard batch.
class QuizQuestionView extends StatefulWidget {
  const QuizQuestionView({
    super.key,
    required this.prompt,
    this.hint = '',
    this.label = 'WHAT DOES THIS MEAN?',
    required this.footer,
    required this.options,
    required this.correctIndex,
    required this.progress,
    required this.correct,
    required this.wrong,
    required this.onAnswer,
    required this.onNext,
  });

  /// Word asked about, with an optional line under it (romanisation).
  final String prompt;
  final String hint;
  final String label;

  /// Bottom-right of the prompt card, e.g. "Question 3 of 10".
  final String footer;
  final List<String> options;
  final int correctIndex;
  final double progress;
  final int correct;
  final int wrong;
  final void Function(bool correct) onAnswer;
  final VoidCallback onNext;

  @override
  State<QuizQuestionView> createState() => _QuizQuestionViewState();
}

class _QuizQuestionViewState extends State<QuizQuestionView>
    with TickerProviderStateMixin {
  int? _selectedIndex;
  bool _showNext = false;

  late AnimationController _slideCtrl;
  late Animation<double> _slideAnim;

  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;

  late AnimationController _popCtrl;
  late Animation<double> _popAnim;

  @override
  void initState() {
    super.initState();

    _slideCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));
    _slideAnim =
        CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut);
    _slideCtrl.forward();

    _shakeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _shakeAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -6.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -6.0, end: 6.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 6.0, end: -4.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -4.0, end: 4.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 4.0, end: 0.0), weight: 1),
    ]).animate(_shakeCtrl);

    _popCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _popAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.03), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.03, end: 1.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _popCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _slideCtrl.dispose();
    _shakeCtrl.dispose();
    _popCtrl.dispose();
    super.dispose();
  }

  void _onOptionTap(int index) {
    if (_selectedIndex != null) return;
    final isCorrect = index == widget.correctIndex;
    setState(() => _selectedIndex = index);
    widget.onAnswer(isCorrect);
    if (isCorrect) {
      _popCtrl.forward();
    } else {
      _shakeCtrl.forward();
    }
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) setState(() => _showNext = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final options = widget.options;

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(
              onBack: () => Navigator.pop(context),
              progress: widget.progress,
              correct: widget.correct,
              wrong: widget.wrong,
            ),
            const SizedBox(height: 20),
            // Question card with slide-in
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: AnimatedBuilder(
                animation: _slideAnim,
                builder: (context, child) => Transform.translate(
                  offset: Offset(30 * (1 - _slideAnim.value), 0),
                  child: Opacity(opacity: _slideAnim.value.clamp(0, 1), child: child),
                ),
                child: AnimatedBuilder(
                  animation: _popAnim,
                  builder: (context, child) =>
                      Transform.scale(scale: _popAnim.value, child: child),
                  child: _QuestionCard(
                    label: widget.label,
                    prompt: widget.prompt,
                    hint: widget.hint,
                    footer: widget.footer,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Answer options
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: List.generate(options.length, (i) {
                    final optionState = _optionState(i);
                    final isWrongSelected =
                        optionState == _OptionState.wrong;
                    return Padding(
                      padding: EdgeInsets.only(
                          bottom: i < options.length - 1 ? 8 : 0),
                      child: AnimatedBuilder(
                        animation: _shakeAnim,
                        builder: (context, child) => Transform.translate(
                          offset: Offset(
                              isWrongSelected ? _shakeAnim.value : 0, 0),
                          child: child,
                        ),
                        child: _OptionButton(
                          label: _letterLabel(i),
                          text: options[i],
                          state: optionState,
                          onTap: () => _onOptionTap(i),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
            // Next button
            AnimatedOpacity(
              opacity: _showNext ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: GestureDetector(
                  onTap: _showNext ? widget.onNext : null,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: const BoxDecoration(
                      color: AppColors.orange,
                      borderRadius: AppRadius.pill,
                    ),
                    child: const Center(
                      child: Text(
                        'Next →',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700),
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

  _OptionState _optionState(int i) {
    if (_selectedIndex == null) return _OptionState.idle;
    if (i == _selectedIndex && i == widget.correctIndex) {
      return _OptionState.correct;
    }
    if (i == _selectedIndex) return _OptionState.wrong;
    if (i == widget.correctIndex) return _OptionState.revealed;
    return _OptionState.dimmed;
  }

  String _letterLabel(int i) => ['A', 'B', 'C', 'D'][i % 4];
}

// ── Top bar ───────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.onBack,
    required this.progress,
    required this.correct,
    required this.wrong,
  });

  final VoidCallback onBack;
  final double progress;
  final int correct;
  final int wrong;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: onBack,
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: AppRadius.cardBorderRadius,
                boxShadow: [
                  BoxShadow(color: Color(0x0D1A1A2E), blurRadius: 6)
                ],
              ),
              child: const Icon(Icons.chevron_left_rounded,
                  color: AppColors.ink, size: 22),
            ),
          ),
          const SizedBox(width: 12),
          // Progress bar
          Expanded(
            child: ClipRRect(
              borderRadius: AppRadius.pill,
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 7,
                backgroundColor: AppColors.fog.withOpacity(0.3),
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.orange),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Score chips
          _ScoreChip(
            count: correct,
            icon: Icons.check_rounded,
            bg: const Color(0xFFE8F5EE),
            color: const Color(0xFF267F53),
          ),
          const SizedBox(width: 6),
          _ScoreChip(
            count: wrong,
            icon: Icons.close_rounded,
            bg: const Color(0xFFFEF0F6),
            color: const Color(0xFFC45A8A),
          ),
        ],
      ),
    );
  }
}

class _ScoreChip extends StatelessWidget {
  const _ScoreChip({
    required this.count,
    required this.icon,
    required this.bg,
    required this.color,
  });

  final int count;
  final IconData icon;
  final Color bg;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: AppRadius.pill),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 3),
          Text('$count',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: color)),
        ],
      ),
    );
  }
}

// ── Question card ─────────────────────────────────────────────────────────

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.label,
    required this.prompt,
    required this.hint,
    required this.footer,
  });

  final String label;
  final String prompt;
  final String hint;
  final String footer;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppColors.orange,
        borderRadius: BorderRadius.all(Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.white.withOpacity(0.7),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            prompt,
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          if (hint.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              hint,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.75),
              ),
            ),
          ],
          const SizedBox(height: 4),
          // Its own line, so a long prompt never runs into it.
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              footer,
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withOpacity(0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Option button ─────────────────────────────────────────────────────────

enum _OptionState { idle, correct, wrong, revealed, dimmed }

class _OptionButton extends StatelessWidget {
  const _OptionButton({
    required this.label,
    required this.text,
    required this.state,
    required this.onTap,
  });

  final String label;
  final String text;
  final _OptionState state;
  final VoidCallback onTap;

  static const _correctBg = Color(0xFFE8F5EE);
  static const _correctBorder = Color(0xFF267F53);
  static const _correctText = Color(0xFF1A5C3A);
  static const _wrongBg = Color(0xFFFEF0F6);
  static const _wrongBorder = Color(0xFFC45A8A);
  static const _wrongText = Color(0xFF7A1A4A);

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color borderColor;
    Color textColor;
    Color badgeBg;
    Color badgeText;
    bool interactive = state == _OptionState.idle;

    switch (state) {
      case _OptionState.idle:
        bg = Colors.white;
        borderColor = AppColors.border;
        textColor = AppColors.ink;
        badgeBg = AppColors.fog.withOpacity(0.25);
        badgeText = AppColors.ash;
      case _OptionState.correct:
      case _OptionState.revealed:
        bg = _correctBg;
        borderColor = _correctBorder;
        textColor = _correctText;
        badgeBg = _correctBorder;
        badgeText = Colors.white;
      case _OptionState.wrong:
        bg = _wrongBg;
        borderColor = _wrongBorder;
        textColor = _wrongText;
        badgeBg = _wrongBorder;
        badgeText = Colors.white;
      case _OptionState.dimmed:
        bg = Colors.white;
        borderColor = AppColors.border;
        textColor = AppColors.ink;
        badgeBg = AppColors.fog.withOpacity(0.25);
        badgeText = AppColors.ash;
    }

    Widget child = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: borderColor, width: 2),
        borderRadius: const BorderRadius.all(Radius.circular(18)),
      ),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: const BorderRadius.all(Radius.circular(8)),
            ),
            child: Center(
              child: Text(label,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: badgeText)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: textColor)),
          ),
        ],
      ),
    );

    if (state == _OptionState.dimmed) {
      child = Opacity(opacity: 0.55, child: child);
    }

    if (!interactive) return child;

    return GestureDetector(onTap: onTap, child: child);
  }
}

