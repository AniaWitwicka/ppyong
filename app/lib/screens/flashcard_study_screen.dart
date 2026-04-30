import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

typedef _CardData = ({
  String korean,
  String romanisation,
  String translation,
  String notes,
});

const _mockCards = <_CardData>[
  (korean: '안녕하세요', romanisation: 'annyeonghaseyo', translation: 'Hello', notes: 'Formal greeting'),
  (korean: '감사합니다', romanisation: 'gamsahamnida', translation: 'Thank you', notes: 'Formal'),
  (korean: '괜찮아요', romanisation: 'gwaenchanayo', translation: "It's okay", notes: 'Casual'),
  (korean: '죄송합니다', romanisation: 'joesonghamnida', translation: "I'm sorry", notes: 'Formal'),
  (korean: '안녕히 계세요', romanisation: 'annyeonghi gyeseyo', translation: 'Goodbye', notes: 'Said to one who stays'),
];

enum _Direction { krToEn, enToKr }
enum _Scope { all, due, weak }

class FlashcardStudyScreen extends StatefulWidget {
  const FlashcardStudyScreen({super.key, this.deckName});
  final String? deckName;

  @override
  State<FlashcardStudyScreen> createState() => _FlashcardStudyScreenState();
}

class _FlashcardStudyScreenState extends State<FlashcardStudyScreen> {
  _Direction _direction = _Direction.krToEn;
  _Scope _scope = _Scope.all;
  int _index = 0;
  bool _sessionStarted = false;
  bool _complete = false;
  int _knewIt = 0;
  int _again = 0;

  bool get _isTab => widget.deckName == null;

  void _answer(bool knew) {
    setState(() {
      if (knew) { _knewIt++; } else { _again++; }
      if (_index + 1 >= _mockCards.length) {
        _complete = true;
      } else {
        _index++;
      }
    });
  }

  void _restart() => setState(() {
        _index = 0;
        _complete = false;
        _sessionStarted = false;
        _knewIt = 0;
        _again = 0;
      });

  @override
  Widget build(BuildContext context) {
    if (_isTab && !_sessionStarted) {
      return _PickDeckPrompt(
        direction: _direction,
        scope: _scope,
        onDirectionChanged: (d) => setState(() => _direction = d),
        onScopeChanged: (s) => setState(() => _scope = s),
        onStart: () => setState(() => _sessionStarted = true),
      );
    }

    if (_complete) {
      return _SessionComplete(
        deckName: widget.deckName,
        knewIt: _knewIt,
        again: _again,
        total: _mockCards.length,
        onRestart: _restart,
        isTab: _isTab,
      );
    }

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: SafeArea(
        child: Column(
          children: [
            _StudyHeader(
              deckName: widget.deckName ?? 'Study',
              index: _index,
              total: _mockCards.length,
              isTab: _isTab,
            ),
            _Pickers(
              direction: _direction,
              scope: _scope,
              onDirectionChanged: (d) => setState(() => _direction = d),
              onScopeChanged: (s) => setState(() => _scope = s),
            ),
            Expanded(
              child: _StudyCard(
                key: ValueKey(_index),
                card: _mockCards[_index],
                direction: _direction,
                onAnswer: _answer,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── No deck selected (tab) ─────────────────────────────────────────────────

class _PickDeckPrompt extends StatelessWidget {
  const _PickDeckPrompt({
    required this.direction,
    required this.scope,
    required this.onDirectionChanged,
    required this.onScopeChanged,
    required this.onStart,
  });

  final _Direction direction;
  final _Scope scope;
  final ValueChanged<_Direction> onDirectionChanged;
  final ValueChanged<_Scope> onScopeChanged;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              color: AppColors.periwinkle,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Text(
                'Learn',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(color: Colors.white),
              ),
            ),
            _Pickers(
              direction: direction,
              scope: scope,
              onDirectionChanged: onDirectionChanged,
              onScopeChanged: onScopeChanged,
            ),
            const Spacer(),
            const Icon(Icons.school_rounded, size: 64, color: AppColors.fog),
            const SizedBox(height: 16),
            const Text('Pick a deck to start studying',
                style: TextStyle(color: AppColors.ash, fontSize: 16)),
            const SizedBox(height: 8),
            const Text('Or tap below to study all due cards',
                style: TextStyle(color: AppColors.fog, fontSize: 14)),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              child: GestureDetector(
                onTap: onStart,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: const BoxDecoration(
                    color: AppColors.orange,
                    borderRadius: AppRadius.pill,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Study all due cards',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
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

// ── Study header ───────────────────────────────────────────────────────────

class _StudyHeader extends StatelessWidget {
  const _StudyHeader({
    required this.deckName,
    required this.index,
    required this.total,
    required this.isTab,
  });

  final String deckName;
  final int index;
  final int total;
  final bool isTab;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.periwinkle,
      padding: const EdgeInsets.fromLTRB(8, 8, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (!isTab)
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              if (isTab) const SizedBox(width: 20),
              Expanded(
                child: Text(
                  deckName,
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(color: Colors.white),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${index + 1} / $total',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.white.withOpacity(0.85)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: AppRadius.pill,
            child: LinearProgressIndicator(
              value: (index + 1) / total,
              backgroundColor: Colors.white.withOpacity(0.3),
              valueColor: const AlwaysStoppedAnimation(Colors.white),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Pickers ────────────────────────────────────────────────────────────────

class _Pickers extends StatelessWidget {
  const _Pickers({
    required this.direction,
    required this.scope,
    required this.onDirectionChanged,
    required this.onScopeChanged,
  });

  final _Direction direction;
  final _Scope scope;
  final ValueChanged<_Direction> onDirectionChanged;
  final ValueChanged<_Scope> onScopeChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          _SegmentedPicker<_Direction>(
            options: const [
              (_Direction.krToEn, 'KR → EN'),
              (_Direction.enToKr, 'EN → KR'),
            ],
            selected: direction,
            onChanged: onDirectionChanged,
          ),
          const SizedBox(width: 12),
          _SegmentedPicker<_Scope>(
            options: const [
              (_Scope.all, 'All'),
              (_Scope.due, 'Due'),
              (_Scope.weak, 'Weak'),
            ],
            selected: scope,
            onChanged: onScopeChanged,
          ),
        ],
      ),
    );
  }
}

class _SegmentedPicker<T> extends StatelessWidget {
  const _SegmentedPicker({required this.options, required this.selected, required this.onChanged});

  final List<(T, String)> options;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.offWhite,
        borderRadius: AppRadius.pill,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: options.map((opt) {
          final (value, label) = opt;
          final isSelected = selected == value;
          return GestureDetector(
            onTap: () => onChanged(value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.periwinkle : Colors.transparent,
                borderRadius: AppRadius.pill,
              ),
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isSelected ? Colors.white : AppColors.ash,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      fontSize: 12,
                    ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Study card ─────────────────────────────────────────────────────────────

class _StudyCard extends StatefulWidget {
  const _StudyCard({
    super.key,
    required this.card,
    required this.direction,
    required this.onAnswer,
  });

  final _CardData card;
  final _Direction direction;
  final ValueChanged<bool> onAnswer;

  @override
  State<_StudyCard> createState() => _StudyCardState();
}

class _StudyCardState extends State<_StudyCard> with SingleTickerProviderStateMixin {
  late final AnimationController _flipCtrl;
  late final Animation<double> _flipAnim;
  bool _isFlipped = false;
  double _dragOffset = 0;

  @override
  void initState() {
    super.initState();
    _flipCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _flipAnim = Tween(begin: 0.0, end: math.pi).animate(
      CurvedAnimation(parent: _flipCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _flipCtrl.dispose();
    super.dispose();
  }

  void _flip() {
    if (_isFlipped) return;
    _flipCtrl.forward();
    setState(() => _isFlipped = true);
  }

  void _onDragUpdate(DragUpdateDetails d) {
    if (!_isFlipped) return;
    setState(() => _dragOffset += d.delta.dx);
  }

  void _onDragEnd(DragEndDetails d) {
    if (!_isFlipped) return;
    if (_dragOffset > 80) {
      widget.onAnswer(true);
    } else if (_dragOffset < -80) {
      widget.onAnswer(false);
    } else {
      setState(() => _dragOffset = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final overlayOpacity = (_dragOffset.abs() / 120).clamp(0.0, 0.8);
    final isKnewIt = _dragOffset > 0;

    return GestureDetector(
      onTap: _flip,
      onHorizontalDragUpdate: _onDragUpdate,
      onHorizontalDragEnd: _onDragEnd,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Expanded(
              child: AnimatedBuilder(
                animation: _flipAnim,
                builder: (context, _) {
                  final angle = _flipAnim.value;
                  final showFront = angle < math.pi / 2;
                  return Transform.translate(
                    offset: Offset(_dragOffset, 0),
                    child: Transform(
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..rotateY(angle),
                    alignment: Alignment.center,
                    child: Stack(
                      children: [
                        _CardFace(
                          card: widget.card,
                          direction: widget.direction,
                          isFront: showFront,
                        ),
                        if (_isFlipped && _dragOffset != 0)
                          Positioned.fill(
                            child: AnimatedOpacity(
                              opacity: overlayOpacity,
                              duration: Duration.zero,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isKnewIt
                                      ? AppColors.forestGreen
                                      : AppColors.bubblegum,
                                  borderRadius: AppRadius.cardBorderRadius,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  isKnewIt ? '✓ Knew it!' : '↩ Again',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ));
                },
              ),
            ),
            const SizedBox(height: 16),
            if (!_isFlipped)
              Text(
                'Tap to reveal',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.fog),
              )
            else
              _AnswerButtons(onAnswer: widget.onAnswer),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _CardFace extends StatelessWidget {
  const _CardFace({required this.card, required this.direction, required this.isFront});

  final _CardData card;
  final _Direction direction;
  final bool isFront;

  @override
  Widget build(BuildContext context) {
    final showKorean = (direction == _Direction.krToEn) == isFront;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.cardBorderRadius,
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: isFront
          ? _FrontContent(card: card, showKorean: showKorean)
          : Transform(
              transform: Matrix4.identity()..rotateY(math.pi),
              alignment: Alignment.center,
              child: _BackContent(card: card, showKorean: showKorean),
            ),
    );
  }
}

class _FrontContent extends StatelessWidget {
  const _FrontContent({required this.card, required this.showKorean});
  final _CardData card;
  final bool showKorean;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.periwinkle.withOpacity(0.15),
            borderRadius: AppRadius.pill,
          ),
          child: Text(
            showKorean ? 'Korean' : 'English',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.periwinkle, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          showKorean ? card.korean : card.translation,
          style: Theme.of(context).textTheme.displayLarge,
          textAlign: TextAlign.center,
        ),
        if (showKorean) ...[
          const SizedBox(height: 8),
          Text(
            card.romanisation,
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(color: AppColors.ash),
          ),
        ],
      ],
    );
  }
}

class _BackContent extends StatelessWidget {
  const _BackContent({required this.card, required this.showKorean});
  final _CardData card;
  final bool showKorean;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.forestGreen.withOpacity(0.15),
            borderRadius: AppRadius.pill,
          ),
          child: Text(
            showKorean ? 'Korean' : 'English',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.forestGreen, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          showKorean ? card.korean : card.translation,
          style: Theme.of(context).textTheme.displayLarge,
          textAlign: TextAlign.center,
        ),
        if (showKorean) ...[
          const SizedBox(height: 8),
          Text(
            card.romanisation,
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(color: AppColors.ash),
          ),
        ],
        if (card.notes.isNotEmpty) ...[
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              card.notes,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.fog, fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ],
    );
  }
}

class _AnswerButtons extends StatelessWidget {
  const _AnswerButtons({required this.onAnswer});
  final ValueChanged<bool> onAnswer;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _AnswerButton(
            label: '↩  Again',
            color: AppColors.bubblegum,
            onTap: () => onAnswer(false),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _AnswerButton(
            label: '✓  Knew it',
            color: AppColors.forestGreen,
            onTap: () => onAnswer(true),
          ),
        ),
      ],
    );
  }
}

class _AnswerButton extends StatelessWidget {
  const _AnswerButton({required this.label, required this.color, required this.onTap});
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(color: color, borderRadius: AppRadius.pill),
        alignment: Alignment.center,
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
        ),
      ),
    );
  }
}

// ── Session complete ───────────────────────────────────────────────────────

class _SessionComplete extends StatelessWidget {
  const _SessionComplete({
    required this.deckName,
    required this.knewIt,
    required this.again,
    required this.total,
    required this.onRestart,
    required this.isTab,
  });

  final String? deckName;
  final int knewIt;
  final int again;
  final int total;
  final VoidCallback onRestart;
  final bool isTab;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🎉', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 16),
              Text(
                'Session complete!',
                style: Theme.of(context).textTheme.displayMedium,
              ),
              if (deckName != null) ...[
                const SizedBox(height: 4),
                Text(deckName!,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: AppColors.ash)),
              ],
              const SizedBox(height: 40),
              Row(
                children: [
                  Expanded(
                    child: _ResultCard(
                      label: 'Knew it',
                      value: knewIt,
                      color: AppColors.forestGreen,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _ResultCard(
                      label: 'Again',
                      value: again,
                      color: AppColors.bubblegum,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              GestureDetector(
                onTap: onRestart,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.orange,
                    borderRadius: AppRadius.pill,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Study again',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                  ),
                ),
              ),
              if (!isTab) ...[
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: AppColors.periwinkle.withOpacity(0.15),
                      borderRadius: AppRadius.pill,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Back to deck',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: AppColors.periwinkle,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.label, required this.value, required this.color});
  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(color: color, borderRadius: AppRadius.cardBorderRadius),
      alignment: Alignment.center,
      child: Column(
        children: [
          Text(
            '$value',
            style: Theme.of(context)
                .textTheme
                .displayLarge
                ?.copyWith(color: Colors.white),
          ),
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .labelLarge
                ?.copyWith(color: Colors.white.withOpacity(0.9)),
          ),
        ],
      ),
    );
  }
}
