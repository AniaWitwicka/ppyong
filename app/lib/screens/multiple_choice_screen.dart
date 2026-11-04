import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/card.dart';
import '../models/deck_selection.dart';
import '../models/study_queue.dart';
import '../services/card_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_toast.dart';
import '../widgets/deck_picker.dart';
import '../widgets/quiz_question.dart';
import '../widgets/session_size_pills.dart';

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

enum _Phase { pick, loading, setup, quiz, complete }

/// One question per card in [batch]; wrong options come from all of [pool].
List<_Question> _buildQuestions(List<CardModel> batch, List<CardModel> pool, Random rng) {
  return [
    for (final card in batch) () {
      // Skip repeats and words with the same translation (the same word can
      // sit in two decks).
      final others = pool.where((c) => c.translation != card.translation).toList()
        ..shuffle(rng);
      final wrongAnswers = <String>[];
      for (final c in others) {
        if (wrongAnswers.length == 3) break;
        if (!wrongAnswers.contains(c.translation)) wrongAnswers.add(c.translation);
      }
      final options = [card.translation, ...wrongAnswers]..shuffle(rng);
      return _Question(
        card: card,
        options: options,
        correctIndex: options.indexOf(card.translation),
      );
    }(),
  ];
}

// ── Root screen ───────────────────────────────────────────────────────────

class MultipleChoiceScreen extends StatefulWidget {
  const MultipleChoiceScreen({
    super.key,
    this.deckId,
    this.deckName,
    this.selection,
    @visibleForTesting this.loadCards,
    @visibleForTesting this.reviewCard,
  });
  final String? deckId;
  final String? deckName;

  /// Several decks mixed into one quiz; wins over [deckId].
  final DeckSelection? selection;

  /// Test hooks: default to the API.
  final Future<List<CardModel>> Function(String deckId)? loadCards;
  final Future<void> Function(String cardId, bool correct)? reviewCard;

  @override
  State<MultipleChoiceScreen> createState() => _MultipleChoiceScreenState();
}

class _MultipleChoiceScreenState extends State<MultipleChoiceScreen> {
  final _rng = Random();
  _Phase _phase = _Phase.pick;
  /// The deck(s) being quizzed; null until picked.
  DeckSelection? _selection;

  /// Every card of the chosen decks; also the pool for wrong options.
  List<CardModel> _cards = [];
  int _sessionSize = StudyQueue.defaultSize;
  StudyQueue? _queue;

  /// Questions of the current batch.
  List<_Question> _questions = [];
  int _qi = 0;
  int _correct = 0;
  int _wrong = 0;

  /// Came in with decks already chosen, so Back leaves the screen.
  bool get _startedWithDecks => widget.selection != null || widget.deckId != null;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
    _selection = widget.selection ??
        (widget.deckId == null
            ? null
            : DeckSelection.single(widget.deckId!, widget.deckName ?? ''));
    if (_selection != null) _loadCards();
  }

  Future<void> _loadPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getInt(StudyQueue.sizePrefKey);
      if (!mounted || saved == null || !StudyQueue.sizes.contains(saved)) return;
      setState(() => _sessionSize = saved);
    } catch (_) {}
  }

  void _onSessionSizeChanged(int size) {
    setState(() => _sessionSize = size);
    SharedPreferences.getInstance()
        .then((prefs) => prefs.setInt(StudyQueue.sizePrefKey, size))
        .catchError((_) => false);
  }

  void _onSelectionDone(DeckSelection selection) {
    setState(() => _selection = selection);
    _loadCards();
  }

  Future<void> _loadCards() async {
    setState(() => _phase = _Phase.loading);
    try {
      final cards = await joinDeckCards(
          _selection!.ids,
          (id) => widget.loadCards?.call(id) ?? CardService.instance.listCards(id));
      if (!mounted) return;
      if (cards.length < 2) {
        setState(() => _phase = _Phase.pick);
        showAppToast(context,
            variant: ToastVariant.error,
            title: 'Not enough cards',
            subtitle: 'Add at least 2 cards to this deck');
        return;
      }
      setState(() {
        _cards = cards;
        _phase = _Phase.setup;
      });
    } catch (_) {
      if (mounted) setState(() => _phase = _Phase.pick);
    }
  }

  /// Orders the words (due first, then new, learning, mastered — shuffled
  /// inside each group) and starts the first batch.
  void _start() {
    final queue = StudyQueue(
      List<CardModel>.from(_cards)..shuffle(_rng),
      sessionSize: _sessionSize == 0 ? _cards.length : _sessionSize,
    );
    setState(() {
      _queue = queue;
      _beginBatch();
    });
  }

  /// Next slice of the same queue — no word repeats this sitting.
  void _nextBatch() {
    final queue = _queue;
    if (queue == null || !queue.hasNextSession) return;
    queue.nextSession();
    setState(_beginBatch);
  }

  /// Call inside setState.
  void _beginBatch() {
    _questions = _buildQuestions(_queue!.session, _cards, _rng);
    _qi = 0;
    _correct = 0;
    _wrong = 0;
    _phase = _Phase.quiz;
  }

  void _onAnswer(bool correct) {
    // Saved per answer, so leaving mid-batch keeps what was answered.
    (widget.reviewCard ?? CardService.instance.reviewCard)(_questions[_qi].card.id, correct)
        .catchError((_) {});
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

  void _backFromSetup() {
    if (_startedWithDecks) {
      Navigator.pop(context);
    } else {
      setState(() => _phase = _Phase.pick);
    }
  }

  @override
  Widget build(BuildContext context) {
    final queue = _queue;
    return switch (_phase) {
      _Phase.pick => DeckPickerScreen(
          title: 'Multiple choice',
          subtitle: 'Pick one or more decks to quiz yourself',
          accentColor: AppColors.orange,
          onSelectionDone: _onSelectionDone,
        ),
      _Phase.loading => const Scaffold(
          backgroundColor: AppColors.offWhite,
          body: Center(child: CircularProgressIndicator(color: AppColors.orange)),
        ),
      _Phase.setup => _SetupScreen(
          deckName: _selection?.label ?? '',
          cardCount: _cards.length,
          sessionSize: _sessionSize,
          onSessionSizeChanged: _onSessionSizeChanged,
          onStart: _start,
          onBack: _backFromSetup,
        ),
      _Phase.quiz => QuizQuestionView(
          key: ValueKey('${queue?.sessionNumber}-$_qi'),
          prompt: _questions[_qi].card.korean,
          hint: _questions[_qi].card.romanisation,
          footer: 'Question ${_qi + 1} of ${_questions.length}',
          options: _questions[_qi].options,
          correctIndex: _questions[_qi].correctIndex,
          progress: (_qi + 1) / _questions.length,
          correct: _correct,
          wrong: _wrong,
          onAnswer: _onAnswer,
          onNext: _nextQuestion,
          autoAdvanceOnCorrect: true,
        ),
      _Phase.complete => _CompletionScreen(
          deckName: _selection?.label,
          total: _questions.length,
          correct: _correct,
          wrong: _wrong,
          batchNumber: queue?.sessionNumber ?? 1,
          batchCount: queue?.sessionCount ?? 1,
          wordsLeft: queue?.remainingAfterSession ?? 0,
          nextBatchSize: queue?.nextSessionSize ?? 0,
          onNextBatch: _nextBatch,
          onTryAgain: _start,
          onBack: () => Navigator.pop(context),
        ),
    };
  }
}

// ── Setup screen ──────────────────────────────────────────────────────────

class _SetupScreen extends StatelessWidget {
  const _SetupScreen({
    required this.deckName,
    required this.cardCount,
    required this.sessionSize,
    required this.onSessionSizeChanged,
    required this.onStart,
    required this.onBack,
  });

  final String deckName;
  final int cardCount;
  final int sessionSize; // 0 = all
  final ValueChanged<int> onSessionSizeChanged;
  final VoidCallback onStart;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: AppColors.ink),
                    tooltip: 'Back',
                    onPressed: onBack,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Multiple choice',
                            style: text.displayMedium?.copyWith(fontSize: 22)),
                        if (deckName.isNotEmpty)
                          Text(deckName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: text.bodyMedium?.copyWith(color: AppColors.ash)),
                      ],
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
                    Text('Words per session',
                        style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    SessionSizePills(
                      size: sessionSize,
                      onChanged: onSessionSizeChanged,
                      color: AppColors.orange,
                    ),
                    const SizedBox(height: 10),
                    Text(sessionSizeHint(cardCount, sessionSize),
                        style: text.bodyMedium?.copyWith(color: AppColors.ash)),
                    const SizedBox(height: 10),
                    Text('Every answer counts toward your progress.',
                        style: text.bodyMedium?.copyWith(color: AppColors.ash)),
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
                  child: const Center(
                    child: Text('Start',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700)),
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

// ── Completion screen ─────────────────────────────────────────────────────

class _CompletionScreen extends StatelessWidget {
  const _CompletionScreen({
    this.deckName,
    required this.total,
    required this.correct,
    required this.wrong,
    required this.batchNumber,
    required this.batchCount,
    required this.wordsLeft,
    required this.nextBatchSize,
    required this.onNextBatch,
    required this.onTryAgain,
    required this.onBack,
  });

  final String? deckName;

  /// Results of the batch just finished.
  final int total;
  final int correct;
  final int wrong;
  final int batchNumber;
  final int batchCount;

  /// Words not yet asked this sitting.
  final int wordsLeft;
  final int nextBatchSize;
  final VoidCallback onNextBatch;
  final VoidCallback onTryAgain;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final score = total == 0 ? 0 : (correct / total * 100).round();
    final hasNext = wordsLeft > 0;
    final subtitle = [
      if (deckName != null && deckName!.isNotEmpty) deckName!,
      if (batchCount > 1)
        'Batch $batchNumber of $batchCount'
      else
        '$total question${total == 1 ? '' : 's'}',
    ].join(' · ');

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
              Text(hasNext ? 'Batch complete!' : 'Quiz complete!',
                  style: Theme.of(context)
                      .textTheme
                      .displayMedium
                      ?.copyWith(fontSize: 24)),
              const SizedBox(height: 6),
              Text(
                subtitle,
                textAlign: TextAlign.center,
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
              if (hasNext) ...[
                const SizedBox(height: 20),
                Text(
                  '$wordsLeft word${wordsLeft == 1 ? '' : 's'} left to go',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppColors.ash),
                ),
              ],
              const Spacer(),
              // Next batch / Try again
              GestureDetector(
                onTap: hasNext ? onNextBatch : onTryAgain,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: const BoxDecoration(
                    color: AppColors.orange,
                    borderRadius: AppRadius.pill,
                  ),
                  child: Center(
                    child: Text(
                        hasNext
                            ? 'Next $nextBatchSize word${nextBatchSize == 1 ? '' : 's'}'
                            : 'Try again',
                        style: const TextStyle(
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
                  child: Center(
                    child: Text(hasNext ? 'Finish' : 'Back to study modes',
                        style: const TextStyle(
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
