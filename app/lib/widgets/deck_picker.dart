import 'package:flutter/material.dart';
import '../models/collection.dart';
import '../models/deck.dart';
import '../models/deck_selection.dart';
import '../services/collection_service.dart';
import '../services/deck_service.dart';
import '../theme/app_theme.dart';

/// Full-screen collection → deck picker shared by the study games.
///
/// With [onDeckSelected] a tap on a deck picks it straight away. With
/// [onSelectionDone] the picker is multi-select: decks get checkboxes, each
/// collection gets "Select all", and a Start button hands over the choice.
class DeckPickerScreen extends StatefulWidget {
  const DeckPickerScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    this.onDeckSelected,
    this.onSelectionDone,
    this.showBack = true,
    @visibleForTesting this.loadCollections,
    @visibleForTesting this.loadDecks,
  }) : assert((onDeckSelected == null) != (onSelectionDone == null));

  final String title;
  final String subtitle;
  final Color accentColor;
  final void Function(String id, String name)? onDeckSelected;
  final void Function(DeckSelection selection)? onSelectionDone;
  final bool showBack;

  /// Test hooks: default to the API.
  final Future<List<Collection>> Function()? loadCollections;
  final Future<List<DeckSummary>> Function(String collectionId)? loadDecks;

  @override
  State<DeckPickerScreen> createState() => _DeckPickerScreenState();
}

class _DeckPickerScreenState extends State<DeckPickerScreen> {
  List<Collection> _collections = [];
  final Map<String, List<DeckSummary>?> _decks = {};
  final Set<String> _expanded = {};
  bool _loading = true;

  /// Picked decks in the order they were picked (multi-select only).
  final Map<String, DeckRef> _picked = {};

  bool get _multi => widget.onSelectionDone != null;

  @override
  void initState() {
    super.initState();
    _loadCollections();
  }

  Future<void> _loadCollections() async {
    try {
      final cols = await (widget.loadCollections?.call() ??
          CollectionService.instance.listCollections());
      if (mounted) setState(() { _collections = cols; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<List<DeckSummary>> _ensureDecks(String collectionId) async {
    final cached = _decks[collectionId];
    if (cached != null) return cached;
    List<DeckSummary> decks;
    try {
      decks = await (widget.loadDecks?.call(collectionId) ??
          DeckService.instance.listDecks(collectionId));
    } catch (_) {
      decks = [];
    }
    if (mounted) setState(() => _decks[collectionId] = decks);
    return decks;
  }

  Future<void> _toggleCollection(String id) async {
    if (_expanded.contains(id)) {
      setState(() => _expanded.remove(id));
      return;
    }
    setState(() => _expanded.add(id));
    await _ensureDecks(id);
  }

  void _toggleDeck(DeckSummary deck) {
    setState(() {
      if (_picked.remove(deck.id) == null) {
        _picked[deck.id] = DeckRef(id: deck.id, name: deck.name, cardCount: deck.cardCount);
      }
    });
  }

  bool _allPicked(List<DeckSummary>? decks) =>
      decks != null && decks.isNotEmpty && decks.every((d) => _picked.containsKey(d.id));

  /// "Select all" on a collection: picks every deck in it, or clears them
  /// when all are picked already.
  Future<void> _toggleWholeCollection(String collectionId) async {
    setState(() => _expanded.add(collectionId));
    final decks = await _ensureDecks(collectionId);
    if (!mounted || decks.isEmpty) return;
    final clear = _allPicked(decks);
    setState(() {
      for (final d in decks) {
        if (clear) {
          _picked.remove(d.id);
        } else {
          _picked[d.id] = DeckRef(id: d.id, name: d.name, cardCount: d.cardCount);
        }
      }
    });
  }

  void _done() {
    if (_picked.isEmpty) return;
    final picked = _picked.values.toList();
    final ids = picked.map((d) => d.id).toSet();
    String? collectionName;
    if (picked.length > 1) {
      for (final col in _collections) {
        final decks = _decks[col.id];
        if (decks != null &&
            decks.length == ids.length &&
            decks.every((d) => ids.contains(d.id))) {
          collectionName = col.name;
          break;
        }
      }
    }
    widget.onSelectionDone!(DeckSelection(picked, collectionName: collectionName));
  }

  @override
  Widget build(BuildContext context) {
    final words = _picked.values.fold(0, (sum, d) => sum + d.cardCount);
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Container(
              width: double.infinity,
              color: widget.accentColor,
              padding: const EdgeInsets.fromLTRB(8, 8, 20, 20),
              child: Row(
                children: [
                  if (widget.showBack)
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    )
                  else
                    const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.title,
                            style: Theme.of(context)
                                .textTheme
                                .displayMedium
                                ?.copyWith(color: Colors.white, fontSize: 22)),
                        Text(widget.subtitle,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: Colors.white.withOpacity(0.8))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? Center(
                      child: CircularProgressIndicator(color: widget.accentColor))
                  : _collections.isEmpty
                      ? _EmptyCollections()
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                          itemCount: _collections.length,
                          itemBuilder: (context, i) {
                            final col = _collections[i];
                            final decks = _decks[col.id];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _CollectionSection(
                                collection: col,
                                isOpen: _expanded.contains(col.id),
                                decks: decks,
                                onToggle: () => _toggleCollection(col.id),
                                accentColor: widget.accentColor,
                                multiSelect: _multi,
                                allPicked: _allPicked(decks),
                                isPicked: (id) => _picked.containsKey(id),
                                onSelectAll: () => _toggleWholeCollection(col.id),
                                onDeckTap: (deck) => _multi
                                    ? _toggleDeck(deck)
                                    : widget.onDeckSelected!(deck.id, deck.name),
                              ),
                            );
                          },
                        ),
            ),
            if (_multi && _picked.isNotEmpty)
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: GestureDetector(
                    onTap: _done,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: const BoxDecoration(
                        color: AppColors.orange,
                        borderRadius: AppRadius.pill,
                      ),
                      child: Center(
                        child: Text(
                          'Start · ${_picked.length} deck${_picked.length == 1 ? '' : 's'}'
                          ' · $words word${words == 1 ? '' : 's'}',
                          style: const TextStyle(
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
    required this.accentColor,
    required this.onDeckTap,
    required this.multiSelect,
    required this.allPicked,
    required this.isPicked,
    required this.onSelectAll,
  });

  final Collection collection;
  final bool isOpen;
  final List<DeckSummary>? decks;
  final VoidCallback onToggle;
  final Color accentColor;
  final void Function(DeckSummary deck) onDeckTap;
  final bool multiSelect;
  final bool allPicked;
  final bool Function(String deckId) isPicked;
  final VoidCallback onSelectAll;

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
                  if (multiSelect && collection.deckCount > 0) ...[
                    GestureDetector(
                      onTap: onSelectAll,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: allPicked ? accentColor : accentColor.withOpacity(0.12),
                          borderRadius: AppRadius.pill,
                        ),
                        child: Text(allPicked ? 'Clear' : 'Select all',
                            style: TextStyle(
                                color: allPicked ? Colors.white : accentColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
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
              Padding(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: accentColor),
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
                    accentColor: accentColor,
                    onTap: () => onDeckTap(e.value),
                    isLast: e.key == decks!.length - 1,
                    multiSelect: multiSelect,
                    picked: isPicked(e.value.id),
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
    required this.accentColor,
    required this.onTap,
    required this.isLast,
    required this.multiSelect,
    required this.picked,
  });

  final DeckSummary deck;
  final Color color;
  final Color accentColor;
  final VoidCallback onTap;
  final bool isLast;
  final bool multiSelect;
  final bool picked;

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
            if (multiSelect)
              AnimatedContainer(
                key: ValueKey('check-${deck.id}'),
                duration: const Duration(milliseconds: 150),
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: picked ? accentColor : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: picked ? accentColor : AppColors.fog, width: 2),
                ),
                child: picked
                    ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                    : null,
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: accentColor,
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
