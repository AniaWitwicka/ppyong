import 'package:flutter/material.dart';
import '../models/collection.dart';
import '../models/deck.dart';
import '../services/collection_service.dart';
import '../services/deck_service.dart';
import '../theme/app_theme.dart';

/// Full-screen collection → deck picker shared by the study games.
class DeckPickerScreen extends StatefulWidget {
  const DeckPickerScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.onDeckSelected,
  });
  final String title;
  final String subtitle;
  final Color accentColor;
  final void Function(String id, String name) onDeckSelected;

  @override
  State<DeckPickerScreen> createState() => _DeckPickerScreenState();
}

class _DeckPickerScreenState extends State<DeckPickerScreen> {
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
              color: widget.accentColor,
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
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _CollectionSection(
                                collection: col,
                                isOpen: _expanded.contains(col.id),
                                decks: _decks[col.id],
                                onToggle: () => _toggleCollection(col.id),
                                accentColor: widget.accentColor,
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
    required this.accentColor,
    required this.onDeckTap,
  });

  final Collection collection;
  final bool isOpen;
  final List<DeckSummary>? decks;
  final VoidCallback onToggle;
  final Color accentColor;
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
    required this.accentColor,
    required this.onTap,
    required this.isLast,
  });

  final DeckSummary deck;
  final Color color;
  final Color accentColor;
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
