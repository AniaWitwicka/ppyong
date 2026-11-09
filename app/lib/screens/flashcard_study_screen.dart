import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/batch_test.dart';
import '../models/card.dart';
import '../models/deck_selection.dart';
import '../models/study_queue.dart';
import '../services/card_service.dart';
import '../services/game_feedback.dart';
import '../theme/app_theme.dart';
import '../widgets/app_toast.dart';
import '../widgets/deck_picker.dart';
import '../widgets/quiz_question.dart';
import '../widgets/session_celebration.dart';
import '../widgets/session_size_pills.dart';

enum _Direction { krToEn, enToKr }
enum _Scope { all, due, weak }
enum _Phase { pick, study, test, complete }

class FlashcardStudyScreen extends StatefulWidget {
  const FlashcardStudyScreen({
    super.key,
    this.deckName,
    this.deckId,
    this.selection,
    this.isTab = false,
    this.loadCards,
    this.reviewCard,
  });
  final String? deckName;
  final String? deckId;

  /// Several decks mixed into one session; wins over [deckId].
  final DeckSelection? selection;
  final bool isTab;

  /// Test hooks: default to the API. `scope` is '' (all), 'due' or 'weak'.
  @visibleForTesting
  final Future<List<CardModel>> Function(String deckId, String scope)? loadCards;
  @visibleForTesting
  final Future<void> Function(String cardId, bool knewIt)? reviewCard;

  @override
  State<FlashcardStudyScreen> createState() => _FlashcardStudyScreenState();
}

class _FlashcardStudyScreenState extends State<FlashcardStudyScreen> {
  _Direction _direction = _Direction.krToEn;
  _Scope _scope = _Scope.all;
  _Phase _phase = _Phase.pick;

  /// The deck(s) being studied; null until picked.
  DeckSelection? _selection;

  /// Cards of the current session (a slice of [_queue]).
  List<CardModel> _cards = [];
  StudyQueue? _queue;
  int _sessionSize = StudyQueue.defaultSize;

  /// Cards still to go through in the learn phase; the front one is shown.
  /// With the test on, "Again" sends a card to the back until it's known.
  List<CardModel> _learn = [];
  int _step = 0;
  int _knewIt = 0;
  int _again = 0;
  bool _loadingCards = false;

  /// Learn → test: swipes are a self-check and only the mini test after the
  /// batch saves word progress. Off: every swipe saves, as before.
  bool _testAfterBatch = true;
  bool _testing = false;

  /// Wrong options for the test come from all chosen decks.
  List<CardModel> _pool = [];
  BatchTest? _test;
  int _testCorrect = 0;
  int _testWrong = 0;

  int _totalCount = 0;
  int _dueCount = 0;
  int _weakCount = 0;

  bool get _isTab => widget.isTab;

  @override
  void initState() {
    super.initState();
    _selection = widget.selection ??
        (widget.deckId == null
            ? null
            : DeckSelection.single(widget.deckId!, widget.deckName ?? ''));
    if (_selection != null) _loadCounts();
    _loadPrefs();
  }

  Future<List<CardModel>> _load(String deckId, String scope) =>
      widget.loadCards?.call(deckId, scope) ??
      CardService.instance.listCards(deckId, scope: scope);

  /// Cards of every chosen deck for [scope], joined.
  Future<List<CardModel>> _loadSelected(String scope) =>
      joinDeckCards(_selection!.ids, (id) => _load(id, scope));

  static const _sessionSizeKey = StudyQueue.sizePrefKey;
  static const _testAfterBatchKey = 'study_test_after_batch';

  Future<void> _loadPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getInt(_sessionSizeKey);
      final test = prefs.getBool(_testAfterBatchKey);
      if (!mounted) return;
      setState(() {
        if (saved != null && StudyQueue.sizes.contains(saved)) _sessionSize = saved;
        if (test != null) _testAfterBatch = test;
      });
    } catch (_) {}
  }

  void _onTestAfterBatchChanged(bool value) {
    setState(() => _testAfterBatch = value);
    SharedPreferences.getInstance()
        .then((prefs) => prefs.setBool(_testAfterBatchKey, value))
        .catchError((_) => false);
  }

  void _onSessionSizeChanged(int size) {
    setState(() => _sessionSize = size);
    SharedPreferences.getInstance()
        .then((prefs) => prefs.setInt(_sessionSizeKey, size))
        .catchError((_) => false);
  }

  int get _scopeCount => switch (_scope) {
        _Scope.all => _totalCount,
        _Scope.due => _dueCount,
        _Scope.weak => _weakCount,
      };

  void _onSelectionDone(DeckSelection selection) {
    setState(() {
      _selection = selection;
      _totalCount = 0;
      _dueCount = 0;
      _weakCount = 0;
    });
    _loadCounts();
  }

  Future<void> _loadCounts() async {
    try {
      final results = await Future.wait([
        _loadSelected(''),
        _loadSelected('due'),
        _loadSelected('weak'),
      ]);
      if (mounted) {
        setState(() {
          _totalCount = results[0].length;
          _dueCount = results[1].length;
          _weakCount = results[2].length;
        });
      }
    } catch (_) {}
  }

  Future<void> _startStudy() async {
    if (_isTab) {
      setState(() => _phase = _Phase.study);
      return;
    }
    setState(() => _loadingCards = true);
    try {
      final scope = _scope == _Scope.due
          ? 'due'
          : _scope == _Scope.weak
              ? 'weak'
              : '';
      final selection = _selection!;
      final cards = await _loadSelected(scope);
      final pool = scope.isEmpty ? cards : await _loadSelected('');
      if (!mounted) return;
      // Mixed decks: shuffle so the queue mixes them inside each group
      // (due → new → learning → mastered). One deck keeps deck order.
      if (!selection.isSingle) cards.shuffle();
      // The home Resume card opens one deck, so only one-deck sessions update it.
      if (cards.isNotEmpty && selection.isSingle) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('last_deck_id', selection.ids.first);
        await prefs.setString('last_deck_name', selection.label);
      }
      final queue = StudyQueue(
        cards,
        sessionSize: _sessionSize == 0 ? cards.length.clamp(1, 1 << 30) : _sessionSize,
      );
      setState(() {
        _queue = queue;
        _pool = pool;
        _testing = _testAfterBatch &&
            BatchTest.canTest(pool, koreanPrompt: _direction == _Direction.krToEn);
        _loadingCards = false;
        _beginBatch(queue.session);
      });
    } catch (_) {
      if (mounted) setState(() => _loadingCards = false);
    }
  }

  /// Resets per-batch state for [cards]; call inside setState.
  void _beginBatch(List<CardModel> cards) {
    _cards = cards;
    _learn = List.of(cards);
    _step = 0;
    _knewIt = 0;
    _again = 0;
    _test = null;
    _testCorrect = 0;
    _testWrong = 0;
    _phase = cards.isEmpty ? _Phase.complete : _Phase.study;
  }

  void _saveReview(CardModel card, bool knew) {
    (widget.reviewCard ?? CardService.instance.reviewCard)(card.id, knew).catchError((_) {
      if (mounted) {
        showAppToast(context, variant: ToastVariant.error, title: 'Review sync failed');
      }
    });
  }

  void _answer(bool knew) {
    if (_learn.isEmpty) return;
    final card = _learn.first;
    if (!_testing) _saveReview(card, knew);
    setState(() {
      if (knew) { _knewIt++; } else { _again++; }
      _learn.removeAt(0);
      if (_testing && !knew) _learn.add(card);
      _step++;
      if (_learn.isEmpty) {
        if (_testing) {
          _test = BatchTest(_cards, _pool, koreanPrompt: _direction == _Direction.krToEn);
          _phase = _Phase.test;
        } else {
          _phase = _Phase.complete;
        }
      }
    });
  }

  void _onTestAnswer(bool correct) {
    final test = _test;
    if (test == null) return;
    final card = test.current.card;
    final firstTry = test.answer(correct);
    if (firstTry != null) _saveReview(card, firstTry);
    setState(() {
      if (correct) { _testCorrect++; } else { _testWrong++; }
    });
  }

  void _onTestNext() {
    final test = _test;
    if (test == null) return;
    setState(() {
      if (!test.next()) _phase = _Phase.complete;
    });
  }

  void _restart() {
    setState(() {
      _phase = _Phase.pick;
      _knewIt = 0;
      _again = 0;
      _cards = [];
      _learn = [];
      _test = null;
      _queue = null;
    });
    if (_selection != null) _loadCounts();
  }

  /// Continues with the next slice of the same queue — no repeats this sitting.
  void _nextSession() {
    final queue = _queue;
    if (queue == null || !queue.hasNextSession) return;
    queue.nextSession();
    setState(() => _beginBatch(queue.session));
  }

  @override
  Widget build(BuildContext context) {
    if ((_isTab || _selection == null) && _phase == _Phase.pick) {
      return DeckPickerScreen(
        title: 'Choose decks',
        subtitle: 'Pick one or more decks to study',
        accentColor: AppColors.periwinkle,
        showBack: !_isTab,
        onSelectionDone: _onSelectionDone,
      );
    }

    if (_phase == _Phase.pick) {
      return _DirectionPickerScreen(
        deckName: _selection!.label,
        deckCount: _selection!.decks.length,
        direction: _direction,
        scope: _scope,
        onDirectionChanged: (d) => setState(() => _direction = d),
        onScopeChanged: (s) => setState(() => _scope = s),
        sessionSize: _sessionSize,
        onSessionSizeChanged: _onSessionSizeChanged,
        testAfterBatch: _testAfterBatch,
        onTestAfterBatchChanged: _onTestAfterBatchChanged,
        scopeCount: _scopeCount,
        onStart: _startStudy,
        loading: _loadingCards,
        totalCount: _totalCount,
        dueCount: _dueCount,
        weakCount: _weakCount,
      );
    }

    if (_phase == _Phase.complete) {
      final queue = _queue;
      final test = _test;
      return _SessionComplete(
        deckName: _selection?.label,
        knewIt: _knewIt,
        again: _again,
        remembered: test?.remembered,
        missed: test?.missed,
        total: _cards.isNotEmpty ? _cards.length : 0,
        sessionNumber: queue?.sessionNumber ?? 1,
        sessionCount: queue?.sessionCount ?? 1,
        wordsLeft: queue?.remainingAfterSession ?? 0,
        nextSessionSize: queue?.nextSessionSize ?? 0,
        onNextSession: _nextSession,
        onRestart: _restart,
        isTab: _isTab,
      );
    }

    final test = _test;
    if (_phase == _Phase.test && test != null) {
      final q = test.current;
      final batchSize = _cards.length;
      return QuizQuestionView(
        key: ValueKey('test-${test.position}'),
        label: test.koreanPrompt ? 'WHAT DOES THIS MEAN?' : 'HOW DO YOU SAY THIS IN KOREAN?',
        prompt: q.prompt,
        hint: q.hint,
        footer: q.isRetry
            ? 'Quick test · one more try'
            : 'Quick test · ${test.position + 1} of $batchSize',
        options: q.options,
        correctIndex: q.correctIndex,
        progress: (test.position + 1) / test.length,
        correct: _testCorrect,
        wrong: _testWrong,
        onAnswer: _onTestAnswer,
        onNext: _onTestNext,
        autoAdvanceOnCorrect: true,
      );
    }

    if (_loadingCards) {
      return const Scaffold(
        backgroundColor: AppColors.offWhite,
        body: Center(child: CircularProgressIndicator(color: AppColors.periwinkle)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: SafeArea(
        child: Column(
          children: [
            _StudyHeader(
              deckName: _selection?.label ?? 'Study',
              index: _cards.length - _learn.length,
              total: _cards.length,
              isTab: _isTab,
              knewIt: _knewIt,
              again: _again,
            ),
            Expanded(
              child: _StudyCard(
                key: ValueKey(_step),
                card: _learn.first,
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

// ── Direction picker screen ────────────────────────────────────────────────

class _DirectionPickerScreen extends StatelessWidget {
  const _DirectionPickerScreen({
    required this.deckName,
    this.deckCount = 1,
    required this.direction,
    required this.scope,
    required this.onDirectionChanged,
    required this.onScopeChanged,
    required this.sessionSize,
    required this.onSessionSizeChanged,
    required this.testAfterBatch,
    required this.onTestAfterBatchChanged,
    required this.scopeCount,
    required this.onStart,
    required this.loading,
    required this.totalCount,
    required this.dueCount,
    required this.weakCount,
  });

  final String deckName;
  final int deckCount;
  final _Direction direction;
  final _Scope scope;
  final ValueChanged<_Direction> onDirectionChanged;
  final ValueChanged<_Scope> onScopeChanged;
  final int sessionSize; // 0 = whole deck
  final ValueChanged<int> onSessionSizeChanged;
  final bool testAfterBatch;
  final ValueChanged<bool> onTestAfterBatchChanged;
  final int scopeCount; // cards in the chosen scope

  /// e.g. "61 cards → 4 sessions of up to 20" or "All 61 cards in one go".
  String _sessionHint() {
    if (scopeCount == 0) return 'No cards to study here yet';
    return sessionSizeHint(scopeCount, sessionSize);
  }
  final VoidCallback onStart;
  final bool loading;
  final int totalCount;
  final int dueCount;
  final int weakCount;

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
                      deckCount == 1
                          ? '$totalCount cards in this deck'
                          : '$totalCount cards in $deckCount decks',
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
                      totalCount: totalCount,
                      dueCount: dueCount,
                      weakCount: weakCount,
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'Words per session',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    SessionSizePills(size: sessionSize, onChanged: onSessionSizeChanged),
                    const SizedBox(height: 10),
                    Text(
                      _sessionHint(),
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: AppColors.ash),
                    ),
                    const SizedBox(height: 28),
                    _TestToggle(value: testAfterBatch, onChanged: onTestAfterBatchChanged),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              child: GestureDetector(
                onTap: loading ? null : onStart,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: const BoxDecoration(
                    color: AppColors.orange,
                    borderRadius: AppRadius.pill,
                  ),
                  alignment: Alignment.center,
                  child: loading
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(
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

/// "Test after each batch" switch on the setup screen.
class _TestToggle extends StatelessWidget {
  const _TestToggle({required this.value, required this.onChanged});
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.fog.withOpacity(0.5), width: 0.5),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Test after each batch',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value
                        ? 'A quick quiz on the batch — only it counts toward progress'
                        : 'Quick review — every swipe counts toward progress',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: AppColors.ash, fontSize: 13),
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: Colors.white,
              activeTrackColor: AppColors.periwinkle,
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
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
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
    required this.totalCount,
    required this.dueCount,
    required this.weakCount,
  });
  final _Scope scope;
  final ValueChanged<_Scope> onChanged;
  final int totalCount;
  final int dueCount;
  final int weakCount;

  @override
  Widget build(BuildContext context) {
    final options = [
      (_Scope.all, 'All cards ($totalCount)'),
      (_Scope.due, 'Due today ($dueCount)'),
      (_Scope.weak, 'Weak words ($weakCount)'),
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
                value: total > 0 ? (index + 1) / total : 0,
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

  final CardModel card;
  final _Direction direction;
  final ValueChanged<bool> onAnswer;

  @override
  State<_StudyCard> createState() => _StudyCardState();
}

class _StudyCardState extends State<_StudyCard> with TickerProviderStateMixin {
  /// How long a new card takes to settle in, and an answered one to leave.
  static const entranceDuration = Duration(milliseconds: 280);
  static const exitDuration = Duration(milliseconds: 260);

  late final AnimationController _entranceCtrl;
  late final Animation<double> _entranceAnim;
  late final AnimationController _flipCtrl;
  late final Animation<double> _flipAnim;
  late final AnimationController _exitCtrl;
  late final Animation<double> _exitAnim;

  /// Finger drag. A notifier, not setState, so a drag repaints only the card.
  final _drag = ValueNotifier<double>(0);

  bool _isFlipped = false;
  bool _exiting = false;
  bool _exitKnewIt = false;
  double _exitFrom = 0;

  @override
  void initState() {
    super.initState();

    // The new card fades in, grows from 94% and rises a little. Nothing moves
    // it sideways, so it never pops in half off screen.
    _entranceCtrl = AnimationController(vsync: this, duration: entranceDuration);
    _entranceAnim = CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOutCubic);
    _entranceCtrl.forward();

    _flipCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );
    _flipAnim = Tween(begin: 0.0, end: math.pi).animate(
      CurvedAnimation(parent: _flipCtrl, curve: Curves.easeInOut),
    );

    _exitCtrl = AnimationController(vsync: this, duration: exitDuration);
    _exitAnim = CurvedAnimation(parent: _exitCtrl, curve: Curves.easeIn);
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
    _drag.dispose();
    super.dispose();
  }

  void _flip() {
    if (_isFlipped || _exiting) return;
    GameFeedback.of(context).flip();
    _flipCtrl.forward();
    setState(() => _isFlipped = true);
  }

  /// A finished swipe or an answer button. Feedback plays here only, so a
  /// drag that's let go before the line stays silent.
  void _commitSwipe(bool knewIt) {
    if (_exiting) return;
    final feedback = GameFeedback.of(context);
    knewIt ? feedback.correct() : feedback.again();
    setState(() {
      _exiting = true;
      _exitKnewIt = knewIt;
      _exitFrom = _drag.value;
    });
    _exitCtrl.forward();
  }

  void _onDragUpdate(DragUpdateDetails d) {
    if (!_isFlipped || _exiting) return;
    _drag.value += d.delta.dx;
  }

  void _onDragEnd(DragEndDetails d) {
    if (!_isFlipped || _exiting) return;
    if (_drag.value > 80) {
      _commitSwipe(true);
    } else if (_drag.value < -80) {
      _commitSwipe(false);
    } else {
      _drag.value = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hintOpacity = _isFlipped ? 0.9 : 0.25;

    return GestureDetector(
      onTap: _flip,
      onHorizontalDragUpdate: _onDragUpdate,
      onHorizontalDragEnd: _onDragEnd,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          children: [
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
            Expanded(
              // Own layer: dragging and animating repaint only the card.
              child: RepaintBoundary(
                child: AnimatedBuilder(
                  animation: Listenable.merge([_flipAnim, _entranceAnim, _exitAnim, _drag]),
                  builder: (context, _) => _buildMovingCard(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Fixed height: the card keeps its size when the buttons appear.
            SizedBox(
              height: _answerAreaHeight,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: !_isFlipped
                    ? Center(
                        key: const ValueKey('reveal'),
                        child: Text(
                          'Tap to reveal',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.periwinkle,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      )
                    : _AnswerButtons(key: const ValueKey('answer'), onAnswer: _commitSwipe),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const _answerAreaHeight = 52.0;

  Widget _buildMovingCard() {
    final enter = _entranceAnim.value;
    final exit = _exitAnim.value;
    final angle = _flipAnim.value;
    final showFront = angle < math.pi / 2;

    final double dx;
    if (_exiting) {
      final target = _exitKnewIt ? 440.0 : -440.0;
      dx = _exitFrom + (target - _exitFrom) * exit;
    } else {
      dx = _drag.value;
    }
    final overlayOpacity = (dx.abs() / 100).clamp(0.0, 1.0);
    final isKnewIt = dx > 0;
    final opacity = (enter * (1 - exit)).clamp(0.0, 1.0);

    return Opacity(
      opacity: opacity,
      child: Transform.translate(
        offset: Offset(dx, (1 - enter) * 16),
        child: Transform.rotate(
          angle: dx / 3000,
          child: Transform.scale(
            scale: 0.94 + 0.06 * enter,
            // The swipe tint sits outside the flip, so its text never reads
            // mirrored on a turned card.
            child: Stack(
              children: [
                Transform(
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..rotateY(angle),
                  alignment: Alignment.center,
                  child: _CardFace(
                    card: widget.card,
                    direction: widget.direction,
                    isFront: showFront,
                    isFlipped: _isFlipped,
                  ),
                ),
                if (dx != 0)
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

  final CardModel card;
  final _Direction direction;
  final bool isFront;
  final bool isFlipped;

  @override
  Widget build(BuildContext context) {
    // Whether the front shows Korean; _BackContent shows the other side.
    final showKorean = direction == _Direction.krToEn;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.cardBorderRadius,
        // Same width both ways, so the content doesn't shift on the flip.
        border: Border.all(
          color: isFlipped ? AppColors.periwinkle : AppColors.border,
          width: 2,
        ),
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
  final CardModel card;
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
            showKorean ? 'Korean' : 'Translation',
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
        if (showKorean && card.romanisation.isNotEmpty) ...[
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
  final CardModel card;
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
            showKorean ? 'Translation' : 'Korean',
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
        if (!showKorean && card.romanisation.isNotEmpty) ...[
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
  const _AnswerButtons({super.key, required this.onAnswer});
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
    this.remembered,
    this.missed,
    required this.total,
    required this.sessionNumber,
    required this.sessionCount,
    required this.wordsLeft,
    required this.nextSessionSize,
    required this.onNextSession,
    required this.onRestart,
    required this.isTab,
  });

  final String? deckName;
  final int knewIt;
  final int again;

  /// First-try test results; null when the batch had no test.
  final int? remembered;
  final int? missed;
  final int total;
  final int sessionNumber;
  final int sessionCount;

  /// Words in this deck/scope not yet covered this sitting.
  final int wordsLeft;
  final int nextSessionSize;
  final VoidCallback onNextSession;
  final VoidCallback onRestart;
  final bool isTab;

  @override
  Widget build(BuildContext context) {
    final hasNext = wordsLeft > 0;
    final tested = remembered != null && missed != null;
    final subtitle = [
      if (deckName != null) deckName!,
      if (sessionCount > 1) 'Session $sessionNumber of $sessionCount',
    ].join(' · ');

    final content = SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
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
                hasNext || sessionCount == 1 ? 'Session complete!' : 'All sessions done!',
                style: Theme.of(context).textTheme.displayMedium,
              ),
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppColors.ash),
                ),
              ],
              if (total > 0) ...[
                const SizedBox(height: 10),
                Text(
                  '$total word${total == 1 ? '' : 's'} practised'
                  '${tested && missed == 0 ? ' · Perfect round!' : ''}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppColors.ink, fontWeight: FontWeight.w600),
                ),
              ],
              const SizedBox(height: 30),
              Row(
                children: [
                  Expanded(
                    child: _ResultCard(
                      label: tested ? 'Remembered' : 'Knew it',
                      value: tested ? remembered! : knewIt,
                      bg: const Color(0xFFE8F5EE),
                      textColor: AppColors.forestGreen,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _ResultCard(
                      label: tested ? 'Missed' : 'Again',
                      value: tested ? missed! : again,
                      bg: const Color(0xFFFEF0F6),
                      textColor: AppColors.bubblegum,
                    ),
                  ),
                ],
              ),
              if (tested) ...[
                const SizedBox(height: 20),
                Text(
                  missed == 0
                      ? 'All $total remembered!'
                      : '$remembered / $total remembered — '
                          '$missed will come back sooner',
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppColors.ink, fontWeight: FontWeight.w600),
                ),
              ],
              if (hasNext) ...[
                SizedBox(height: tested ? 8 : 20),
                Text(
                  '$wordsLeft word${wordsLeft == 1 ? '' : 's'} left to go',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppColors.ash),
                ),
              ],
              const SizedBox(height: 36),
              GestureDetector(
                onTap: hasNext ? onNextSession : onRestart,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: const BoxDecoration(
                    color: AppColors.orange,
                    borderRadius: AppRadius.pill,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    hasNext
                        ? 'Next $nextSessionSize word${nextSessionSize == 1 ? '' : 's'}'
                        : 'Study again',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                  ),
                ),
              ),
              if (!isTab || hasNext) ...[
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: isTab ? onRestart : () => Navigator.pop(context),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: AppColors.periwinkle.withOpacity(0.12),
                      borderRadius: AppRadius.pill,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      hasNext ? 'Done for now' : 'Back to deck',
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
      );

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      // An empty batch (nothing in scope) has nothing to celebrate.
      body: total > 0 ? SessionCelebration(big: !hasNext, child: content) : content,
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
