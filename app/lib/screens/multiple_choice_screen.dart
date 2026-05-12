import 'dart:math';
import 'package:flutter/material.dart';
import '../models/card.dart';
import '../models/collection.dart';
import '../models/deck.dart';
import '../services/card_service.dart';
import '../services/collection_service.dart';
import '../services/deck_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_toast.dart';

// ── Data ──────────────────────────────────────────────────────────────────

class _Question {
  const _Question({
    required this.card,
    required this.options,
    required this.correctIndex,
  });
  final CardModel card;
  final List<String> options;
  final int correctIndex;
}

enum _Phase { pick, loading, quiz, complete }

// ── Root screen ───────────────────────────────────────────────────────────

class MultipleChoiceScreen extends StatefulWidget {
  const MultipleChoiceScreen({super.key, this.deckId, this.deckName});
  final String? deckId;
  final String? deckName;

  @override
  State<MultipleChoiceScreen> createState() => _MultipleChoiceScreenState();
}

class _MultipleChoiceScreenState extends State<MultipleChoiceScreen> {
  _Phase _phase = _Phase.pick;
  String? _deckId;
  String? _deckName;
  List<_Question> _questions = [];
  int _qi = 0;
  int _correct = 0;
  int _wrong = 0;

  @override
  void initState() {
    super.initState();
    _deckId = widget.deckId;
    _deckName = widget.deckName;
    if (_deckId != null) _loadAndStart();
  }

  void _onDeckSelected(String id, String name) {
    setState(() {
      _deckId = id;
      _deckName = name;
    });
    _loadAndStart();
  }

  Future<void> _loadAndStart() async {
    setState(() => _phase = _Phase.loading);
    try {
      final cards = await CardService.instance.listCards(_deckId!);
      if (!mounted) return;
      if (cards.length < 2) {
        setState(() => _phase = _Phase.pick);
        showAppToast(context,
            variant: ToastVariant.error,
            title: 'Not enough cards',
            subtitle: 'Add at least 2 cards to this deck');
        return;
      }
      final rng = Random();
      final shuffled = List<CardModel>.from(cards)..shuffle(rng);
      final questions = shuffled.map((card) {
        final others = cards.where((c) => c.id != card.id).toList()..shuffle(rng);
        final wrongAnswers = others.take(3).map((c) => c.translation).toList();
        final options = [card.translation, ...wrongAnswers]..shuffle(rng);
        return _Question(
          card: card,
          options: options,
          correctIndex: options.indexOf(card.translation),
        );
      }).toList();
      setState(() {
        _questions = questions;
        _qi = 0;
        _correct = 0;
        _wrong = 0;
        _phase = _Phase.quiz;
      });
    } catch (_) {
      if (mounted) setState(() => _phase = _Phase.pick);
    }
  }

  void _onAnswer(bool correct) {
    setState(() {
      if (correct) { _correct++; } else { _wrong++; }
    });
  }

  void _nextQuestion() {
    if (_qi + 1 >= _questions.length) {
      setState(() => _phase = _Phase.complete);
    } else {
      setState(() => _qi++);
    }
  }

  @override
  Widget build(BuildContext context) {
    return switch (_phase) {
      _Phase.pick => _DeckPickerScreen(onDeckSelected: _onDeckSelected),
      _Phase.loading => const Scaffold(
          backgroundColor: AppColors.offWhite,
          body: Center(child: CircularProgressIndicator(color: AppColors.orange)),
        ),
      _Phase.quiz => _QuizScreen(
          key: ValueKey(_qi),
          question: _questions[_qi],
          questionIndex: _qi,
          totalQuestions: _questions.length,
          correct: _correct,
          wrong: _wrong,
          onAnswer: _onAnswer,
          onNext: _nextQuestion,
        ),
      _Phase.complete => _CompletionScreen(
          deckName: _deckName,
          total: _questions.length,
          correct: _correct,
          wrong: _wrong,
          onTryAgain: _loadAndStart,
          onBack: () => Navigator.pop(context),
        ),
    };
  }
}

// ── Deck picker ───────────────────────────────────────────────────────────

class _DeckPickerScreen extends StatefulWidget {
  const _DeckPickerScreen({required this.onDeckSelected});
  final void Function(String id, String name) onDeckSelected;

  @override
  State<_DeckPickerScreen> createState() => _DeckPickerScreenState();
}

class _DeckPickerScreenState extends State<_DeckPickerScreen> {
  List<Collection> _collections = [];
  final Map<String, List<DeckSummary>?> _decks = {};
  final Set<String> _expanded = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCollections();
  }

  Future<void> _loadCollections() async {
    try {
      final cols = await CollectionService.instance.listCollections();
      if (mounted) setState(() { _collections = cols; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleCollection(String id) async {
    if (_expanded.contains(id)) {
      setState(() => _expanded.remove(id));
      return;
    }
    setState(() => _expanded.add(id));
    if (_decks[id] == null) {
      try {
        final decks = await DeckService.instance.listDecks(id);
        if (mounted) setState(() => _decks[id] = decks);
      } catch (_) {
        if (mounted) setState(() => _decks[id] = []);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Container(
              width: double.infinity,
              color: AppColors.orange,
              padding: const EdgeInsets.fromLTRB(8, 8, 20, 20),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Multiple choice',
                          style: Theme.of(context)
                              .textTheme
                              .displayMedium
                              ?.copyWith(color: Colors.white, fontSize: 22)),
                      Text('Choose a deck to quiz yourself',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: Colors.white.withOpacity(0.8))),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.orange))
                  : _collections.isEmpty
                      ? _EmptyCollections()
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                          itemCount: _collections.length,
                          itemBuilder: (context, i) {
                            final col = _collections[i];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _CollectionSection(
                                collection: col,
                                isOpen: _expanded.contains(col.id),
                                decks: _decks[col.id],
                                onToggle: () => _toggleCollection(col.id),
                                onDeckTap: widget.onDeckSelected,
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyCollections extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.library_books_rounded, size: 56, color: AppColors.fog),
          SizedBox(height: 16),
          Text('No collections yet',
              style: TextStyle(
                  color: AppColors.ash,
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
          SizedBox(height: 6),
          Text('Add decks in the Library tab first',
              style: TextStyle(color: AppColors.fog, fontSize: 13)),
        ],
      ),
    );
  }
}

class _CollectionSection extends StatelessWidget {
  const _CollectionSection({
    required this.collection,
    required this.isOpen,
    required this.decks,
    required this.onToggle,
    required this.onDeckTap,
  });

  final Collection collection;
  final bool isOpen;
  final List<DeckSummary>? decks;
  final VoidCallback onToggle;
  final void Function(String id, String name) onDeckTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.all(Radius.circular(18)),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(18),
              bottom: isOpen ? Radius.zero : const Radius.circular(18),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: collection.color.withOpacity(0.15),
                      borderRadius: const BorderRadius.all(Radius.circular(12)),
                    ),
                    child: Center(
                      child: Text(collection.emoji,
                          style: const TextStyle(fontSize: 20)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(collection.name,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700)),
                        Text(
                            '${collection.deckCount} deck${collection.deckCount == 1 ? '' : 's'}',
                            style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: isOpen ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.keyboard_arrow_down_rounded,
                        color: AppColors.fog, size: 22),
                  ),
                ],
              ),
            ),
          ),
          if (isOpen) ...[
            const Divider(height: 1, color: AppColors.border),
            if (decks == null)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.orange),
                  ),
                ),
              )
            else if (decks!.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text('No decks in this collection',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: AppColors.fog)),
              )
            else
              ...decks!.asMap().entries.map((e) => _DeckRow(
                    deck: e.value,
                    color: collection.color,
                    onTap: () => onDeckTap(e.value.id, e.value.name),
                    isLast: e.key == decks!.length - 1,
                  )),
          ],
        ],
      ),
    );
  }
}

class _DeckRow extends StatelessWidget {
  const _DeckRow({
    required this.deck,
    required this.color,
    required this.onTap,
    required this.isLast,
  });

  final DeckSummary deck;
  final Color color;
  final VoidCallback onTap;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: isLast
          ? const BorderRadius.vertical(bottom: Radius.circular(18))
          : BorderRadius.zero,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : const Border(bottom: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 36,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.all(Radius.circular(4)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(deck.name,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontSize: 15)),
                  Text('${deck.cardCount} cards',
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: const BoxDecoration(
                color: AppColors.orange,
                borderRadius: AppRadius.pill,
              ),
              child: const Text('Select',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Quiz screen ────────────────────────────────────────────────────────────

class _QuizScreen extends StatefulWidget {
  const _QuizScreen({
    super.key,
    required this.question,
    required this.questionIndex,
    required this.totalQuestions,
    required this.correct,
    required this.wrong,
    required this.onAnswer,
    required this.onNext,
  });

  final _Question question;
  final int questionIndex;
  final int totalQuestions;
  final int correct;
  final int wrong;
  final void Function(bool correct) onAnswer;
  final VoidCallback onNext;

  @override
  State<_QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<_QuizScreen>
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
    final isCorrect = index == widget.question.correctIndex;
    setState(() => _selectedIndex = index);
    widget.onAnswer(isCorrect);
    CardService.instance.reviewCard(widget.question.card.id, isCorrect).catchError((_) {});
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
    final q = widget.question;
    final progress = (widget.questionIndex + 1) / widget.totalQuestions;

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(
              onBack: () => Navigator.pop(context),
              progress: progress,
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
                    korean: q.card.korean,
                    romanisation: q.card.romanisation,
                    questionIndex: widget.questionIndex,
                    totalQuestions: widget.totalQuestions,
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
                  children: List.generate(q.options.length, (i) {
                    final optionState = _optionState(i);
                    final isWrongSelected =
                        optionState == _OptionState.wrong;
                    return Padding(
                      padding: EdgeInsets.only(
                          bottom: i < q.options.length - 1 ? 8 : 0),
                      child: AnimatedBuilder(
                        animation: _shakeAnim,
                        builder: (context, child) => Transform.translate(
                          offset: Offset(
                              isWrongSelected ? _shakeAnim.value : 0, 0),
                          child: child,
                        ),
                        child: _OptionButton(
                          label: _letterLabel(i),
                          text: q.options[i],
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
    if (i == _selectedIndex && i == widget.question.correctIndex) {
      return _OptionState.correct;
    }
    if (i == _selectedIndex) return _OptionState.wrong;
    if (i == widget.question.correctIndex) return _OptionState.revealed;
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
    required this.korean,
    required this.romanisation,
    required this.questionIndex,
    required this.totalQuestions,
  });

  final String korean;
  final String romanisation;
  final int questionIndex;
  final int totalQuestions;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppColors.orange,
        borderRadius: BorderRadius.all(Radius.circular(24)),
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'WHAT DOES THIS MEAN?',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withOpacity(0.7),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                korean,
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              if (romanisation.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  romanisation,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.75),
                  ),
                ),
              ],
              const SizedBox(height: 4),
            ],
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Text(
              'Question ${questionIndex + 1} of $totalQuestions',
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

// ── Completion screen ─────────────────────────────────────────────────────

class _CompletionScreen extends StatelessWidget {
  const _CompletionScreen({
    this.deckName,
    required this.total,
    required this.correct,
    required this.wrong,
    required this.onTryAgain,
    required this.onBack,
  });

  final String? deckName;
  final int total;
  final int correct;
  final int wrong;
  final VoidCallback onTryAgain;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final score = total == 0 ? 0 : (correct / total * 100).round();

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              // Trophy squircle
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: AppColors.sunnyYellow,
                  borderRadius: BorderRadius.all(Radius.circular(24)),
                ),
                child: const Center(
                  child: Text('🎉', style: TextStyle(fontSize: 36)),
                ),
              ),
              const SizedBox(height: 20),
              Text('Quiz complete!',
                  style: Theme.of(context)
                      .textTheme
                      .displayMedium
                      ?.copyWith(fontSize: 24)),
              const SizedBox(height: 6),
              Text(
                deckName != null
                    ? '$deckName · $total question${total == 1 ? '' : 's'}'
                    : 'You answered $total question${total == 1 ? '' : 's'}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),
              // Stat cards
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      value: '$correct',
                      label: 'CORRECT',
                      bg: const Color(0xFFE8F5EE),
                      valueColor: const Color(0xFF267F53),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatCard(
                      value: '$wrong',
                      label: 'WRONG',
                      bg: const Color(0xFFFEF0F6),
                      valueColor: const Color(0xFFC45A8A),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatCard(
                      value: '$score%',
                      label: 'SCORE',
                      bg: const Color(0xFFFEF9E8),
                      valueColor: const Color(0xFF7A5500),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // Try again
              GestureDetector(
                onTap: onTryAgain,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: const BoxDecoration(
                    color: AppColors.orange,
                    borderRadius: AppRadius.pill,
                  ),
                  child: const Center(
                    child: Text('Try again',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Back ghost button
              GestureDetector(
                onTap: onBack,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border, width: 1.5),
                    borderRadius: AppRadius.pill,
                  ),
                  child: const Center(
                    child: Text('Back to study modes',
                        style: TextStyle(
                            color: AppColors.ash,
                            fontSize: 16,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.value,
    required this.label,
    required this.bg,
    required this.valueColor,
  });

  final String value;
  final String label;
  final Color bg;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.cardBorderRadius,
      ),
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: valueColor)),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ash,
                  letterSpacing: 0.5)),
        ],
      ),
    );
  }
}
