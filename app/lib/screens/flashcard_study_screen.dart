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

const _dueMockCount = 5;
const _weakMockCount = 2;

enum _Direction { krToEn, enToKr }
enum _Scope { all, due, weak }
enum _Phase { pick, study, complete }

class FlashcardStudyScreen extends StatefulWidget {
  const FlashcardStudyScreen({super.key, this.deckName});
  final String? deckName;

  @override
  State<FlashcardStudyScreen> createState() => _FlashcardStudyScreenState();
}

class _FlashcardStudyScreenState extends State<FlashcardStudyScreen> {
  _Direction _direction = _Direction.krToEn;
  _Scope _scope = _Scope.all;
  _Phase _phase = _Phase.pick;
  int _index = 0;
  int _knewIt = 0;
  int _again = 0;

  bool get _isTab => widget.deckName == null;

  void _startStudy() => setState(() => _phase = _Phase.study);

  void _answer(bool knew) {
    setState(() {
      if (knew) { _knewIt++; } else { _again++; }
      if (_index + 1 >= _mockCards.length) {
        _phase = _Phase.complete;
      } else {
        _index++;
      }
    });
  }

  void _restart() => setState(() {
    _index = 0;
    _phase = _Phase.pick;
    _knewIt = 0;
    _again = 0;
  });

  @override
  Widget build(BuildContext context) {
    // Tab mode: show pick-deck prompt before study starts
    if (_isTab && _phase == _Phase.pick) {
      return _PickDeckPrompt(
        direction: _direction,
        scope: _scope,
        onDirectionChanged: (d) => setState(() => _direction = d),
        onScopeChanged: (s) => setState(() => _scope = s),
        onStart: _startStudy,
      );
    }

    // Non-tab picker: radio-style direction + scope
    if (_phase == _Phase.pick) {
      return _DirectionPickerScreen(
        deckName: widget.deckName!,
        direction: _direction,
        scope: _scope,
        onDirectionChanged: (d) => setState(() => _direction = d),
        onScopeChanged: (s) => setState(() => _scope = s),
        onStart: _startStudy,
        totalCards: _mockCards.length,
      );
    }

    if (_phase == _Phase.complete) {
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
              knewIt: _knewIt,
              again: _again,
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

// ── Tab: pick-deck prompt ──────────────────────────────────────────────────

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

// ── Direction picker screen ────────────────────────────────────────────────

class _DirectionPickerScreen extends StatelessWidget {
  const _DirectionPickerScreen({
    required this.deckName,
    required this.direction,
    required this.scope,
    required this.onDirectionChanged,
    required this.onScopeChanged,
    required this.onStart,
    required this.totalCards,
  });

  final String deckName;
  final _Direction direction;
  final _Scope scope;
  final ValueChanged<_Direction> onDirectionChanged;
  final ValueChanged<_Scope> onScopeChanged;
  final VoidCallback onStart;
  final int totalCards;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: AppColors.periwinkle,
              padding: const EdgeInsets.fromLTRB(8, 8, 20, 16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
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
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ready to study?', style: Theme.of(context).textTheme.displayMedium),
                    const SizedBox(height: 4),
                    Text(
                      '$totalCards cards in this deck',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: AppColors.ash),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'Direction',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    _DirectionOption(
                      label: 'Korean → Translation',
                      selected: direction == _Direction.krToEn,
                      onTap: () => onDirectionChanged(_Direction.krToEn),
                    ),
                    const SizedBox(height: 10),
                    _DirectionOption(
                      label: 'Translation → Korean',
                      selected: direction == _Direction.enToKr,
                      onTap: () => onDirectionChanged(_Direction.enToKr),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'Scope',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    _ScopePills(
                      scope: scope,
                      onChanged: onScopeChanged,
                      totalCards: totalCards,
                    ),
                  ],
                ),
              ),
            ),
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
                    'Start studying',
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

class _DirectionOption extends StatelessWidget {
  const _DirectionOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.periwinkle : AppColors.fog.withOpacity(0.5),
            width: selected ? 2 : 0.5,
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? AppColors.periwinkle : Colors.transparent,
                border: selected ? null : Border.all(color: AppColors.fog, width: 2),
              ),
              child: selected
                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                  : null,
            ),
            const SizedBox(width: 14),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScopePills extends StatelessWidget {
  const _ScopePills({
    required this.scope,
    required this.onChanged,
    required this.totalCards,
  });
  final _Scope scope;
  final ValueChanged<_Scope> onChanged;
  final int totalCards;

  @override
  Widget build(BuildContext context) {
    final options = [
      (_Scope.all, 'All cards ($totalCards)'),
      (_Scope.due, 'Due today ($_dueMockCount)'),
      (_Scope.weak, 'Weak words ($_weakMockCount)'),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((opt) {
        final (value, label) = opt;
        final isSelected = scope == value;
        return GestureDetector(
          onTap: () => onChanged(value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.periwinkle : Colors.white,
              borderRadius: AppRadius.pill,
              border: Border.all(
                color: isSelected ? AppColors.periwinkle : AppColors.fog.withOpacity(0.5),
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.ash,
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        );
      }).toList(),
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
    required this.knewIt,
    required this.again,
  });

  final String deckName;
  final int index;
  final int total;
  final bool isTab;
  final int knewIt;
  final int again;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(8, 10, 12, 12),
      child: Row(
        children: [
          if (!isTab)
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 36,
                height: 36,
                margin: const EdgeInsets.only(right: 8, left: 4),
                decoration: BoxDecoration(
                  color: AppColors.offWhite,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(Icons.chevron_left_rounded, color: AppColors.ink, size: 22),
              ),
            )
          else
            const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: AppRadius.pill,
              child: LinearProgressIndicator(
                value: (index + 1) / total,
                backgroundColor: AppColors.border,
                valueColor: const AlwaysStoppedAnimation(AppColors.periwinkle),
                minHeight: 8,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '${index + 1}/$total',
            style: const TextStyle(
              color: AppColors.ash,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 10),
          _ScoreChip(count: knewIt, color: AppColors.forestGreen, icon: Icons.check_rounded),
          const SizedBox(width: 6),
          _ScoreChip(count: again, color: AppColors.bubblegum, icon: Icons.replay_rounded),
        ],
      ),
    );
  }
}

class _ScoreChip extends StatelessWidget {
  const _ScoreChip({required this.count, required this.color, required this.icon});
  final int count;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: AppRadius.pill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
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

class _StudyCardState extends State<_StudyCard> with TickerProviderStateMixin {
  late final AnimationController _entranceCtrl;
  late final Animation<double> _entranceAnim;
  late final AnimationController _flipCtrl;
  late final Animation<double> _flipAnim;
  late final AnimationController _exitCtrl;

  bool _isFlipped = false;
  double _dragOffset = 0;
  bool _exiting = false;
  bool _exitKnewIt = false;

  @override
  void initState() {
    super.initState();

    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _entranceAnim = Tween<double>(begin: 220.0, end: 0.0).animate(
      CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOut),
    );
    _entranceCtrl.forward();

    _flipCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );
    _flipAnim = Tween(begin: 0.0, end: math.pi).animate(
      CurvedAnimation(parent: _flipCtrl, curve: Curves.easeInOut),
    );

    _exitCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _exitCtrl.addListener(() {
      setState(() {
        _dragOffset = (_exitKnewIt ? 1 : -1) * _exitCtrl.value * 420;
      });
    });
    _exitCtrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onAnswer(_exitKnewIt);
      }
    });
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _flipCtrl.dispose();
    _exitCtrl.dispose();
    super.dispose();
  }

  void _flip() {
    if (_isFlipped || _exiting) return;
    _flipCtrl.forward();
    setState(() => _isFlipped = true);
  }

  void _commitSwipe(bool knewIt) {
    if (_exiting) return;
    setState(() {
      _exiting = true;
      _exitKnewIt = knewIt;
    });
    _exitCtrl.forward();
  }

  void _onDragUpdate(DragUpdateDetails d) {
    if (!_isFlipped || _exiting) return;
    setState(() => _dragOffset += d.delta.dx);
  }

  void _onDragEnd(DragEndDetails d) {
    if (!_isFlipped || _exiting) return;
    if (_dragOffset > 80) {
      _commitSwipe(true);
    } else if (_dragOffset < -80) {
      _commitSwipe(false);
    } else {
      setState(() => _dragOffset = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final overlayOpacity = (_dragOffset.abs() / 100).clamp(0.0, 1.0);
    final isKnewIt = _dragOffset > 0;
    final hintOpacity = _isFlipped ? 0.9 : 0.25;

    return GestureDetector(
      onTap: _flip,
      onHorizontalDragUpdate: _onDragUpdate,
      onHorizontalDragEnd: _onDragEnd,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          children: [
            // Swipe hints
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AnimatedOpacity(
                    opacity: hintOpacity,
                    duration: const Duration(milliseconds: 300),
                    child: const Row(
                      children: [
                        Icon(Icons.arrow_back_rounded, color: AppColors.bubblegum, size: 14),
                        SizedBox(width: 4),
                        Text(
                          "Didn't know",
                          style: TextStyle(
                            color: AppColors.bubblegum,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedOpacity(
                    opacity: hintOpacity,
                    duration: const Duration(milliseconds: 300),
                    child: const Row(
                      children: [
                        Text(
                          'Knew it',
                          style: TextStyle(
                            color: AppColors.forestGreen,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward_rounded, color: AppColors.forestGreen, size: 14),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Card
            Expanded(
              child: AnimatedBuilder(
                animation: Listenable.merge([_flipAnim, _entranceAnim]),
                builder: (context, _) {
                  final angle = _flipAnim.value;
                  final showFront = angle < math.pi / 2;
                  return Transform.translate(
                    offset: Offset(_entranceAnim.value + _dragOffset, 0),
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
                            isFlipped: _isFlipped,
                          ),
                          if (_dragOffset != 0)
                            Positioned.fill(
                              child: ClipRRect(
                                borderRadius: AppRadius.cardBorderRadius,
                                child: Opacity(
                                  opacity: overlayOpacity,
                                  child: Container(
                                    color: isKnewIt
                                        ? const Color(0xFFE8F5EE)
                                        : const Color(0xFFFEF0F6),
                                    alignment: Alignment.center,
                                    child: Text(
                                      isKnewIt ? 'Knew it!' : 'Keep trying',
                                      style: TextStyle(
                                        color: isKnewIt
                                            ? AppColors.forestGreen
                                            : AppColors.bubblegum,
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800,
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
                },
              ),
            ),

            const SizedBox(height: 16),

            if (!_isFlipped)
              Text(
                'Tap to reveal',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.periwinkle,
                      fontWeight: FontWeight.w600,
                    ),
              )
            else
              _AnswerButtons(
                onAnswer: _commitSwipe,
              ),
          ],
        ),
      ),
    );
  }
}

class _CardFace extends StatelessWidget {
  const _CardFace({
    required this.card,
    required this.direction,
    required this.isFront,
    required this.isFlipped,
  });

  final _CardData card;
  final _Direction direction;
  final bool isFront;
  final bool isFlipped;

  @override
  Widget build(BuildContext context) {
    final showKorean = (direction == _Direction.krToEn) == isFront;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.cardBorderRadius,
        border: isFlipped
            ? Border.all(color: AppColors.periwinkle, width: 2)
            : Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withOpacity(0.07),
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
            color: AppColors.periwinkle.withOpacity(0.12),
            borderRadius: AppRadius.pill,
          ),
          child: Text(
            showKorean ? 'Korean' : 'English',
            style: const TextStyle(
              color: AppColors.periwinkle,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 28),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            showKorean ? card.korean : card.translation,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        if (showKorean) ...[
          const SizedBox(height: 10),
          Text(
            card.romanisation,
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(color: AppColors.ash),
          ),
        ],
        const SizedBox(height: 28),
        const Text(
          'Tap to reveal',
          style: TextStyle(
            color: AppColors.periwinkle,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
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
            color: AppColors.orange.withOpacity(0.1),
            borderRadius: AppRadius.pill,
          ),
          child: Text(
            showKorean ? 'English' : 'Korean',
            style: const TextStyle(
              color: AppColors.orange,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            showKorean ? card.translation : card.korean,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.orange,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        if (!showKorean) ...[
          const SizedBox(height: 8),
          Text(
            card.romanisation,
            style: const TextStyle(color: AppColors.ash, fontSize: 14),
          ),
        ],
        if (card.notes.isNotEmpty) ...[
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              card.notes,
              style: const TextStyle(
                color: AppColors.ash,
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
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
          child: GestureDetector(
            onTap: () => onAnswer(false),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: const BoxDecoration(
                color: Color(0xFFFEF0F6),
                borderRadius: AppRadius.pill,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.arrow_back_rounded, color: AppColors.bubblegum, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'Again',
                    style: TextStyle(
                      color: AppColors.bubblegum,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: () => onAnswer(true),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: const BoxDecoration(
                color: Color(0xFFE8F5EE),
                borderRadius: AppRadius.pill,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Knew it',
                    style: TextStyle(
                      color: AppColors.forestGreen,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(width: 6),
                  Icon(Icons.arrow_forward_rounded, color: AppColors.forestGreen, size: 16),
                ],
              ),
            ),
          ),
        ),
      ],
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
              // Yellow squircle with star
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.sunnyYellow,
                  borderRadius: BorderRadius.circular(24),
                ),
                alignment: Alignment.center,
                child: const Text('⭐', style: TextStyle(fontSize: 36)),
              ),
              const SizedBox(height: 20),
              Text(
                'Session complete!',
                style: Theme.of(context).textTheme.displayMedium,
              ),
              if (deckName != null) ...[
                const SizedBox(height: 4),
                Text(
                  deckName!,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppColors.ash),
                ),
              ],
              const SizedBox(height: 36),
              Row(
                children: [
                  Expanded(
                    child: _ResultCard(
                      label: 'Knew it',
                      value: knewIt,
                      bg: const Color(0xFFE8F5EE),
                      textColor: AppColors.forestGreen,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _ResultCard(
                      label: 'Again',
                      value: again,
                      bg: const Color(0xFFFEF0F6),
                      textColor: AppColors.bubblegum,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 36),
              GestureDetector(
                onTap: onRestart,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: const BoxDecoration(
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
                      color: AppColors.periwinkle.withOpacity(0.12),
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
  const _ResultCard({
    required this.label,
    required this.value,
    required this.bg,
    required this.textColor,
  });
  final String label;
  final int value;
  final Color bg;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28),
      decoration: BoxDecoration(color: bg, borderRadius: AppRadius.cardBorderRadius),
      alignment: Alignment.center,
      child: Column(
        children: [
          Text(
            '$value',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textColor.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}
