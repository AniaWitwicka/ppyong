import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/card.dart';
import '../models/collection.dart';
import '../models/deck.dart';
import '../services/card_service.dart';
import '../services/collection_service.dart';
import '../services/deck_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_toast.dart';

enum _Direction { krToEn, enToKr }
enum _Scope { all, due, weak }
enum _Phase { pick, study, complete }

class FlashcardStudyScreen extends StatefulWidget {
  const FlashcardStudyScreen({super.key, this.deckName, this.deckId, this.isTab = false});
  final String? deckName;
  final String? deckId;
  final bool isTab;

  @override
  State<FlashcardStudyScreen> createState() => _FlashcardStudyScreenState();
}

class _FlashcardStudyScreenState extends State<FlashcardStudyScreen> {
  _Direction _direction = _Direction.krToEn;
  _Scope _scope = _Scope.all;
  _Phase _phase = _Phase.pick;

  String? _deckId;
  String? _deckName;

  List<CardModel> _cards = [];
  int _index = 0;
  int _knewIt = 0;
  int _again = 0;
  bool _loadingCards = false;

  int _totalCount = 0;
  int _dueCount = 0;
  int _weakCount = 0;

  bool get _isTab => widget.isTab;

  @override
  void initState() {
    super.initState();
    _deckId = widget.deckId;
    _deckName = widget.deckName;
    if (_deckId != null) _loadCounts();
  }

  void _onDeckSelected(String id, String name) {
    setState(() {
      _deckId = id;
      _deckName = name;
    });
    _loadCounts();
  }

  Future<void> _loadCounts() async {
    try {
      final results = await Future.wait([
        CardService.instance.listCards(_deckId!),
        CardService.instance.listCards(_deckId!, scope: 'due'),
        CardService.instance.listCards(_deckId!, scope: 'weak'),
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
      final cards = await CardService.instance.listCards(_deckId!, scope: scope);
      if (!mounted) return;
      if (cards.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('last_deck_id', _deckId!);
        await prefs.setString('last_deck_name', _deckName ?? '');
      }
      setState(() {
        _cards = cards;
        _loadingCards = false;
        _phase = cards.isEmpty ? _Phase.complete : _Phase.study;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingCards = false);
    }
  }

  void _answer(bool knew) {
    final card = _cards.isNotEmpty ? _cards[_index] : null;
    if (card != null) {
      CardService.instance.reviewCard(card.id, knew).catchError((_) {
        if (mounted) {
          showAppToast(context, variant: ToastVariant.error, title: 'Review sync failed');
        }
      });
    }
    setState(() {
      if (knew) { _knewIt++; } else { _again++; }
      if (_cards.isEmpty || _index + 1 >= _cards.length) {
        _phase = _Phase.complete;
      } else {
        _index++;
      }
    });
  }

  void _restart() {
    setState(() {
      _index = 0;
      _phase = _Phase.pick;
      _knewIt = 0;
      _again = 0;
      _cards = [];
    });
    if (_deckId != null) _loadCounts();
  }

  @override
  Widget build(BuildContext context) {
    if ((_isTab || _deckId == null) && _phase == _Phase.pick) {
      return _PickDeckPrompt(
        isTab: _isTab,
        onDeckSelected: _onDeckSelected,
      );
    }

    if (_phase == _Phase.pick) {
      return _DirectionPickerScreen(
        deckName: _deckName!,
        direction: _direction,
        scope: _scope,
        onDirectionChanged: (d) => setState(() => _direction = d),
        onScopeChanged: (s) => setState(() => _scope = s),
        onStart: _startStudy,
        loading: _loadingCards,
        totalCount: _totalCount,
        dueCount: _dueCount,
        weakCount: _weakCount,
      );
    }

    if (_phase == _Phase.complete) {
      return _SessionComplete(
        deckName: _deckName,
        knewIt: _knewIt,
        again: _again,
        total: _cards.isNotEmpty ? _cards.length : 0,
        onRestart: _restart,
        isTab: _isTab,
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
              deckName: widget.deckName ?? 'Study',
              index: _index,
              total: _cards.length,
              isTab: _isTab,
              knewIt: _knewIt,
              again: _again,
            ),
            Expanded(
              child: _StudyCard(
                key: ValueKey(_index),
                card: _cards[_index],
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

// ── Deck picker ───────────────────────────────────────────────────────────

class _PickDeckPrompt extends StatefulWidget {
  const _PickDeckPrompt({
    required this.isTab,
    required this.onDeckSelected,
  });

  final bool isTab;
  final void Function(String id, String name) onDeckSelected;

  @override
  State<_PickDeckPrompt> createState() => _PickDeckPromptState();
}

class _PickDeckPromptState extends State<_PickDeckPrompt> {
  List<Collection> _collections = [];
  // collectionId → decks (null = not yet loaded)
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
            // Header
            Container(
              width: double.infinity,
              color: AppColors.periwinkle,
              padding: const EdgeInsets.fromLTRB(8, 8, 20, 20),
              child: Row(
                children: [
                  if (!widget.isTab)
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    )
                  else
                    const SizedBox(width: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Choose a deck',
                          style: Theme.of(context)
                              .textTheme
                              .displayMedium
                              ?.copyWith(color: Colors.white, fontSize: 22)),
                      Text('Select a deck to start studying',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: Colors.white.withOpacity(0.8))),
                    ],
                  ),
                ],
              ),
            ),
            // Body
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.periwinkle))
                  : _collections.isEmpty
                      ? _EmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                          itemCount: _collections.length,
                          itemBuilder: (context, i) {
                            final col = _collections[i];
                            final isOpen = _expanded.contains(col.id);
                            final decks = _decks[col.id];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _CollectionSection(
                                collection: col,
                                isOpen: isOpen,
                                decks: decks,
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

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.library_books_rounded, size: 56, color: AppColors.fog),
          SizedBox(height: 16),
          Text('No collections yet',
              style: TextStyle(color: AppColors.ash, fontSize: 16, fontWeight: FontWeight.w600)),
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
          // Collection header row
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
                      child: Text(collection.emoji, style: const TextStyle(fontSize: 20)),
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
                        Text('${collection.deckCount} deck${collection.deckCount == 1 ? '' : 's'}',
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
          // Deck list
          if (isOpen) ...[
            const Divider(height: 1, color: AppColors.border),
            if (decks == null)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.periwinkle),
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
              ...decks!.map((deck) => _DeckRow(
                    deck: deck,
                    color: collection.color,
                    onTap: () => onDeckTap(deck.id, deck.name),
                    isLast: deck == decks!.last,
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
            Container(width: 4, height: 36, decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.all(Radius.circular(4)),
            )),
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
              decoration: BoxDecoration(
                color: AppColors.periwinkle,
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

// ── Direction picker screen ────────────────────────────────────────────────

class _DirectionPickerScreen extends StatelessWidget {
  const _DirectionPickerScreen({
    required this.deckName,
    required this.direction,
    required this.scope,
    required this.onDirectionChanged,
    required this.onScopeChanged,
    required this.onStart,
    required this.loading,
    required this.totalCount,
    required this.dueCount,
    required this.weakCount,
  });

  final String deckName;
  final _Direction direction;
  final _Scope scope;
  final ValueChanged<_Direction> onDirectionChanged;
  final ValueChanged<_Scope> onScopeChanged;
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
                      '$totalCount cards in this deck',
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
              _AnswerButtons(onAnswer: _commitSwipe),
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

  final CardModel card;
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
