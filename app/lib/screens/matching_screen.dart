import 'dart:async';
import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/card.dart';
import '../models/match_game.dart';
import '../services/card_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_toast.dart';
import '../widgets/deck_picker.dart';
import '../widgets/session_celebration.dart';

const _bubblegumTint = Color(0xFFFEF0F6);
const _pinkDark = Color(0xFFC45A8A);
const _greenTint = Color(0xFFE8F5EE);

enum _Phase { pick, setup, loading, playing, complete }

/// Result of one finished game, shown on the end screen.
class _MatchResult {
  const _MatchResult({
    required this.matched,
    required this.mistakes,
    required this.accuracy,
    required this.perfectRun,
    required this.secondsLeft,
    required this.best,
    required this.isNewBest,
    required this.toReview,
  });
  final int matched;
  final int mistakes;
  final double accuracy;
  final bool perfectRun;
  final int secondsLeft;
  final int best;
  final bool isNewBest;

  /// Words mismatched twice, sent as "didn't know" so they come back sooner.
  final int toReview;
}

// ── Root screen ───────────────────────────────────────────────────────────

class MatchingScreen extends StatefulWidget {
  const MatchingScreen({
    super.key,
    this.deckId,
    this.deckName,
    this.loadCards,
    this.recordGame,
  });
  final String? deckId;
  final String? deckName;

  /// Test hooks: default to loading cards from the API and sending the
  /// practice + "didn't know" calls.
  @visibleForTesting
  final Future<List<CardModel>> Function(String deckId)? loadCards;
  @visibleForTesting
  final void Function(String deckId, MatchGame game)? recordGame;

  @override
  State<MatchingScreen> createState() => _MatchingScreenState();
}

class _MatchingScreenState extends State<MatchingScreen> {
  _Phase _phase = _Phase.pick;
  String? _deckId;
  String? _deckName;
  int _seconds = 60;
  int _pairsPerBoard = 6;
  List<CardModel> _cards = [];
  int _gameKey = 0;
  _MatchResult? _result;

  @override
  void initState() {
    super.initState();
    _deckId = widget.deckId;
    _deckName = widget.deckName;
    if (_deckId != null) _phase = _Phase.setup;
  }

  void _onDeckSelected(String id, String name) {
    setState(() {
      _deckId = id;
      _deckName = name;
      _phase = _Phase.setup;
    });
  }

  Future<void> _loadAndStart() async {
    setState(() => _phase = _Phase.loading);
    try {
      final load = widget.loadCards ?? CardService.instance.listCards;
      final cards = await load(_deckId!);
      if (!mounted) return;
      if (cards.length < 2) {
        setState(() => _phase = _Phase.setup);
        showAppToast(context,
            variant: ToastVariant.error,
            title: 'Not enough cards',
            subtitle: 'Add at least 2 cards to this deck');
        return;
      }
      setState(() {
        _cards = cards;
        _gameKey++;
        _phase = _Phase.playing;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _phase = _Phase.setup);
      showAppToast(context, variant: ToastVariant.error, title: 'Could not load cards');
    }
  }

  /// Counts the game toward the streak and marks words mismatched twice as
  /// "didn't know". Fire-and-forget: a network error must not block the end screen.
  void _recordGame(MatchGame game) {
    if (widget.recordGame != null) {
      widget.recordGame!(_deckId!, game);
      return;
    }
    final cards = CardService.instance;
    cards
        .logPractice(deckId: _deckId!, mode: 'match', matched: game.matched, mistakes: game.mistakes)
        .catchError((_) {});
    for (final card in game.cardsToReview) {
      cards.reviewCard(card.id, false).catchError((_) {});
    }
  }

  Future<void> _onGameOver(MatchGame game, int secondsLeft) async {
    _recordGame(game);
    final key = 'match_best_${_deckId}_${_seconds}s';
    var best = 0;
    var isNewBest = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      best = prefs.getInt(key) ?? 0;
      if (game.matched > best) {
        isNewBest = best > 0;
        best = game.matched;
        await prefs.setInt(key, best);
      }
    } catch (_) {
      best = game.matched;
    }
    if (!mounted) return;
    setState(() {
      _result = _MatchResult(
        matched: game.matched,
        mistakes: game.mistakes,
        accuracy: game.accuracy,
        perfectRun: game.deckFinished,
        secondsLeft: secondsLeft,
        best: best,
        isNewBest: isNewBest,
        toReview: game.cardsToReview.length,
      );
      _phase = _Phase.complete;
    });
  }

  @override
  Widget build(BuildContext context) {
    return switch (_phase) {
      _Phase.pick => DeckPickerScreen(
          title: 'Matching',
          subtitle: 'Choose a deck to play',
          accentColor: AppColors.bubblegum,
          onDeckSelected: _onDeckSelected,
        ),
      _Phase.setup => _SetupScreen(
          deckName: _deckName ?? '',
          seconds: _seconds,
          pairsPerBoard: _pairsPerBoard,
          onSecondsChanged: (s) => setState(() => _seconds = s),
          onPairsChanged: (p) => setState(() => _pairsPerBoard = p),
          onStart: _loadAndStart,
          onBack: () => Navigator.pop(context),
        ),
      _Phase.loading => const Scaffold(
          backgroundColor: AppColors.offWhite,
          body: Center(child: CircularProgressIndicator(color: AppColors.bubblegum)),
        ),
      _Phase.playing => _BoardScreen(
          key: ValueKey(_gameKey),
          cards: _cards,
          seconds: _seconds,
          pairsPerBoard: _pairsPerBoard,
          onGameOver: _onGameOver,
        ),
      _Phase.complete => _CompletionScreen(
          deckName: _deckName,
          result: _result!,
          onPlayAgain: _loadAndStart,
          onBack: () => Navigator.pop(context),
        ),
    };
  }
}

// ── Setup screen ──────────────────────────────────────────────────────────

class _SetupScreen extends StatelessWidget {
  const _SetupScreen({
    required this.deckName,
    required this.seconds,
    required this.pairsPerBoard,
    required this.onSecondsChanged,
    required this.onPairsChanged,
    required this.onStart,
    required this.onBack,
  });

  final String deckName;
  final int seconds;
  final int pairsPerBoard;
  final ValueChanged<int> onSecondsChanged;
  final ValueChanged<int> onPairsChanged;
  final VoidCallback onStart;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              color: AppColors.bubblegum,
              padding: const EdgeInsets.fromLTRB(8, 8, 20, 20),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                    onPressed: onBack,
                  ),
                  Expanded(
                    child: Text(deckName,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .displayMedium
                            ?.copyWith(color: Colors.white, fontSize: 22)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                children: [
                  Text('Ready to match?', style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 24)),
                  const SizedBox(height: 4),
                  Text('Match each Korean word with its translation before time runs out.',
                      style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 28),
                  const _SettingLabel('Time limit'),
                  const SizedBox(height: 10),
                  _ChipRow(
                    values: const [30, 60, 90],
                    selected: seconds,
                    label: (v) => '$v s',
                    onSelected: onSecondsChanged,
                  ),
                  const SizedBox(height: 24),
                  const _SettingLabel('Pairs per board'),
                  const SizedBox(height: 10),
                  _ChipRow(
                    values: const [4, 5, 6],
                    selected: pairsPerBoard,
                    label: (v) => '$v',
                    onSelected: onPairsChanged,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: _PillButton(label: 'Start', color: AppColors.orange, onTap: onStart),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingLabel extends StatelessWidget {
  const _SettingLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700));
  }
}

class _ChipRow extends StatelessWidget {
  const _ChipRow({
    required this.values,
    required this.selected,
    required this.label,
    required this.onSelected,
  });

  final List<int> values;
  final int selected;
  final String Function(int) label;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: [
        for (final v in values)
          GestureDetector(
            onTap: () => onSelected(v),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: v == selected ? AppColors.bubblegum : Colors.white,
                borderRadius: AppRadius.pill,
                border: Border.all(
                    color: v == selected ? AppColors.bubblegum : AppColors.border, width: 1.5),
              ),
              child: Text(label(v),
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: v == selected ? Colors.white : AppColors.ink)),
            ),
          ),
      ],
    );
  }
}

// ── Board screen ──────────────────────────────────────────────────────────

class _BoardScreen extends StatefulWidget {
  const _BoardScreen({
    super.key,
    required this.cards,
    required this.seconds,
    required this.pairsPerBoard,
    required this.onGameOver,
  });

  final List<CardModel> cards;
  final int seconds;
  final int pairsPerBoard;
  final void Function(MatchGame game, int secondsLeft) onGameOver;

  @override
  State<_BoardScreen> createState() => _BoardScreenState();
}

class _BoardScreenState extends State<_BoardScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late final MatchGame _game;
  final Stopwatch _clock = clock.stopwatch();
  Timer? _ticker;
  bool _over = false;
  bool _dealing = false;

  late final AnimationController _shakeCtrl;
  late final Animation<double> _shakeAnim;
  late final AnimationController _popCtrl;
  late final Animation<double> _popAnim;

  Set<MatchTile> _wrongTiles = {};
  Set<MatchTile> _poppingTiles = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _game = MatchGame(cards: widget.cards, pairsPerBoard: widget.pairsPerBoard);

    _shakeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _shakeAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -6.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -6.0, end: 6.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 6.0, end: -4.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -4.0, end: 4.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 4.0, end: 0.0), weight: 1),
    ]).animate(_shakeCtrl);

    _popCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _popAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.06), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.06, end: 1.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _popCtrl, curve: Curves.easeInOut));

    _clock.start();
    _ticker = Timer.periodic(const Duration(milliseconds: 100), (_) => _tick());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    _shakeCtrl.dispose();
    _popCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_over) return;
    if (state == AppLifecycleState.resumed) {
      _clock.start();
    } else {
      _clock.stop();
    }
  }

  Duration get _limit => Duration(seconds: widget.seconds);
  Duration get _remaining {
    final left = _limit - _clock.elapsed;
    return left.isNegative ? Duration.zero : left;
  }

  void _tick() {
    if (_over) return;
    if (_remaining == Duration.zero) {
      _finish();
    } else {
      setState(() {});
    }
  }

  void _finish() {
    if (_over) return;
    _over = true;
    _clock.stop();
    _ticker?.cancel();
    widget.onGameOver(_game, _remaining.inSeconds);
  }

  void _onTileTap(MatchTile tile) {
    if (_over || _dealing) return;
    final outcome = _game.select(tile);
    switch (outcome) {
      case MatchOutcome.correct:
        setState(() => _poppingTiles = _game.lastPair.toSet());
        _popCtrl.forward(from: 0);
        if (_game.boardCleared) _afterBoardCleared();
      case MatchOutcome.wrong:
        setState(() => _wrongTiles = _game.lastPair.toSet());
        _shakeCtrl.forward(from: 0).whenComplete(() {
          if (mounted) setState(() => _wrongTiles = {});
        });
      case MatchOutcome.selected:
      case MatchOutcome.deselected:
        setState(() {});
      case MatchOutcome.ignored:
        break;
    }
  }

  void _afterBoardCleared() {
    if (_game.deckFinished) {
      _finish();
      return;
    }
    _dealing = true;
    Future.delayed(const Duration(milliseconds: 350), () {
      if (!mounted || _over) return;
      setState(() {
        _game.dealBoard();
        _poppingTiles = {};
        _wrongTiles = {};
        _dealing = false;
      });
    });
  }

  Future<void> _confirmLeave() async {
    _clock.stop();
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave the game?'),
        content: const Text('Your score for this game will be lost.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep playing')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Leave', style: TextStyle(color: AppColors.bubblegum)),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (leave == true) {
      _over = true;
      _ticker?.cancel();
      Navigator.pop(context);
    } else {
      _clock.start();
    }
  }

  _TileState _stateOf(MatchTile tile) {
    if (_game.isMatched(tile)) return _TileState.matched;
    if (_wrongTiles.contains(tile)) return _TileState.wrong;
    if (_game.selected == tile) return _TileState.selected;
    return _TileState.idle;
  }

  @override
  Widget build(BuildContext context) {
    final remaining = _remaining;
    final fraction = remaining.inMilliseconds / _limit.inMilliseconds;
    final secondsLeft = (remaining.inMilliseconds / 1000).ceil();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmLeave();
      },
      child: Scaffold(
        backgroundColor: AppColors.offWhite,
        body: SafeArea(
          child: Column(
            children: [
              _TopBar(
                onBack: _confirmLeave,
                fraction: fraction,
                secondsLeft: secondsLeft,
                matched: _game.matched,
                mistakes: _game.mistakes,
              ),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(child: _ColumnLabel('Korean')),
                    SizedBox(width: 12),
                    Expanded(child: _ColumnLabel('Translation')),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Column(
                    children: [
                      for (var i = 0; i < _game.boardSize; i++)
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(bottom: i < _game.boardSize - 1 ? 10 : 0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(child: _buildTile(_game.koreanColumn[i])),
                                const SizedBox(width: 12),
                                Expanded(child: _buildTile(_game.translationColumn[i])),
                              ],
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
      ),
    );
  }

  Widget _buildTile(MatchTile tile) {
    final state = _stateOf(tile);
    return AnimatedBuilder(
      animation: Listenable.merge([_shakeAnim, _popAnim]),
      builder: (context, child) {
        final shaking = state == _TileState.wrong;
        final popping = _poppingTiles.contains(tile);
        return Transform.translate(
          offset: Offset(shaking ? _shakeAnim.value : 0, 0),
          child: Transform.scale(scale: popping ? _popAnim.value : 1.0, child: child),
        );
      },
      child: _Tile(
        key: ValueKey('${tile.card.id}-${tile.side.name}'),
        text: tile.label,
        isKorean: tile.side == MatchSide.korean,
        state: state,
        onTap: () => _onTileTap(tile),
      ),
    );
  }
}

class _ColumnLabel extends StatelessWidget {
  const _ColumnLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text.toUpperCase(),
        textAlign: TextAlign.center,
        style: const TextStyle(
            fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.ash, letterSpacing: 0.5));
  }
}

enum _TileState { idle, selected, matched, wrong }

class _Tile extends StatelessWidget {
  const _Tile({
    super.key,
    required this.text,
    required this.isKorean,
    required this.state,
    required this.onTap,
  });

  final String text;
  final bool isKorean;
  final _TileState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (bg, border, fg) = switch (state) {
      _TileState.idle => (Colors.white, AppColors.border, AppColors.ink),
      _TileState.selected => (AppColors.periwinkle.withOpacity(0.15), AppColors.periwinkle, AppColors.ink),
      _TileState.matched => (_greenTint, AppColors.forestGreen, AppColors.forestGreen),
      _TileState.wrong => (_bubblegumTint, _pinkDark, _pinkDark),
    };
    final long = text.length > 18;

    return AnimatedOpacity(
      opacity: state == _TileState.matched ? 0.0 : 1.0,
      duration: const Duration(milliseconds: 250),
      child: Semantics(
        button: true,
        label: text,
        selected: state == _TileState.selected,
        child: GestureDetector(
          onTap: state == _TileState.matched ? null : onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: const BorderRadius.all(Radius.circular(18)),
              border: Border.all(color: border, width: 2),
            ),
            alignment: Alignment.center,
            child: Text(
              text,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: isKorean ? 20 : (long ? 13 : 15),
                fontWeight: isKorean ? FontWeight.w800 : FontWeight.w600,
                color: fg,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Top bar ───────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.onBack,
    required this.fraction,
    required this.secondsLeft,
    required this.matched,
    required this.mistakes,
  });

  final VoidCallback onBack;
  final double fraction;
  final int secondsLeft;
  final int matched;
  final int mistakes;

  @override
  Widget build(BuildContext context) {
    final hurry = secondsLeft <= 10;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: AppRadius.cardBorderRadius,
                boxShadow: [BoxShadow(color: Color(0x0D1A1A2E), blurRadius: 6)],
              ),
              child: const Icon(Icons.chevron_left_rounded, color: AppColors.ink, size: 22),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ClipRRect(
              borderRadius: AppRadius.pill,
              child: LinearProgressIndicator(
                value: fraction,
                minHeight: 7,
                backgroundColor: AppColors.fog.withOpacity(0.3),
                valueColor: AlwaysStoppedAnimation<Color>(
                    hurry ? AppColors.orange : AppColors.bubblegum),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 34,
            child: Text('${secondsLeft}s',
                textAlign: TextAlign.right,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: hurry ? AppColors.orange : AppColors.ink)),
          ),
          const SizedBox(width: 8),
          _ScoreChip(count: matched, icon: Icons.check_rounded, bg: _greenTint, color: AppColors.forestGreen),
          const SizedBox(width: 6),
          _ScoreChip(count: mistakes, icon: Icons.close_rounded, bg: _bubblegumTint, color: _pinkDark),
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
          Text('$count', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }
}

// ── Completion screen ─────────────────────────────────────────────────────

class _CompletionScreen extends StatelessWidget {
  const _CompletionScreen({
    this.deckName,
    required this.result,
    required this.onPlayAgain,
    required this.onBack,
  });

  final String? deckName;
  final _MatchResult result;
  final VoidCallback onPlayAgain;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final r = result;
    final title = r.perfectRun ? 'Deck cleared!' : "Time's up!";
    final subtitle = r.perfectRun
        ? 'All ${r.matched} words matched with ${r.secondsLeft}s to spare'
        : '${deckName ?? 'Matching'} · best ${r.best}';

    // A round ends either way (board cleared or time's up) — both celebrate.
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: SessionCelebration(
        big: true,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Spacer(),
                Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    color: AppColors.sunnyYellow,
                    borderRadius: BorderRadius.all(Radius.circular(24)),
                  ),
                  child: Center(
                    child: Text(r.perfectRun ? '🎉' : '⏱️', style: const TextStyle(fontSize: 36)),
                  ),
                ),
                const SizedBox(height: 20),
                Text(title,
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 24)),
                const SizedBox(height: 6),
                Text(subtitle,
                    textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
                if (r.isNewBest) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: const BoxDecoration(color: _bubblegumTint, borderRadius: AppRadius.pill),
                    child: const Text('New best!',
                        style: TextStyle(color: _pinkDark, fontSize: 13, fontWeight: FontWeight.w800)),
                  ),
                ],
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                          value: '${r.matched}', label: 'MATCHED', bg: _greenTint, valueColor: AppColors.forestGreen),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatCard(
                          value: '${r.mistakes}', label: 'MISTAKES', bg: _bubblegumTint, valueColor: _pinkDark),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatCard(
                        value: '${(r.accuracy * 100).round()}%',
                        label: 'ACCURACY',
                        bg: const Color(0xFFFEF9E8),
                        valueColor: const Color(0xFF7A5500),
                      ),
                    ),
                  ],
                ),
                if (r.toReview > 0) ...[
                  const SizedBox(height: 16),
                  Text(
                    '${r.toReview} tricky word${r.toReview == 1 ? '' : 's'} will come back sooner in Flashcards',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
                const Spacer(),
                _PillButton(label: 'Play again', color: AppColors.orange, onTap: onPlayAgain),
                const SizedBox(height: 12),
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
                          style: TextStyle(color: AppColors.ash, fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
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
      decoration: BoxDecoration(color: bg, borderRadius: AppRadius.cardBorderRadius),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: valueColor)),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.ash, letterSpacing: 0.5)),
        ],
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  const _PillButton({required this.label, required this.color, required this.onTap});
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(color: color, borderRadius: AppRadius.pill),
        child: Center(
          child: Text(label,
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }
}
