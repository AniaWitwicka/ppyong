import 'package:flutter/material.dart';
import '../models/deck.dart';
import '../services/deck_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_toast.dart';
import 'deck_detail_screen.dart';

class CollectionDetailScreen extends StatefulWidget {
  const CollectionDetailScreen({
    super.key,
    required this.collectionId,
    required this.collectionName,
    required this.accentColor,
  });

  final String collectionId;
  final String collectionName;
  final Color accentColor;

  @override
  State<CollectionDetailScreen> createState() => _CollectionDetailScreenState();
}

class _CollectionDetailScreenState extends State<CollectionDetailScreen> {
  List<DeckSummary> _decks = [];
  bool _loading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _hasError = false; });
    try {
      final decks = await DeckService.instance.listDecks(widget.collectionId);
      setState(() { _decks = decks; _loading = false; });
    } catch (_) {
      setState(() { _loading = false; _hasError = true; });
      if (mounted) {
        showAppToast(context,
            variant: ToastVariant.error,
            title: 'Failed to load decks',
            subtitle: 'Check your connection and try again');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              collectionName: widget.collectionName,
              accentColor: widget.accentColor,
            ),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.periwinkle),
      );
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('😕', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            const Text('Could not load decks',
                style: TextStyle(color: AppColors.ash, fontSize: 16)),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _load,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: const BoxDecoration(
                    color: AppColors.periwinkle, borderRadius: AppRadius.pill),
                child: const Text('Try again',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      );
    }

    if (_decks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('📖', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            Text('No decks yet',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text('Add a deck to get started',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.ash)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      itemCount: _decks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) => _DeckRow(
        deck: _decks[i],
        accentColor: widget.accentColor,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DeckDetailScreen(
              deckId: _decks[i].id,
              accentColor: widget.accentColor,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.collectionName, required this.accentColor});
  final String collectionName;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: accentColor,
      padding: const EdgeInsets.fromLTRB(16, 12, 20, 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 22),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              collectionName,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontSize: 20,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Deck row ──────────────────────────────────────────────────────────────

class _DeckRow extends StatelessWidget {
  const _DeckRow({required this.deck, required this.accentColor, required this.onTap});
  final DeckSummary deck;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppRadius.cardBorderRadius,
          boxShadow: [
            BoxShadow(
              color: AppColors.ink.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    deck.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppColors.fog, size: 20),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${deck.cardCount} cards · ${deck.masteredCount} mastered',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.ash, fontSize: 12),
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: AppRadius.pill,
              child: SizedBox(
                height: 6,
                child: deck.cardCount == 0
                    ? Container(color: AppColors.border)
                    : Row(
                        children: [
                          Flexible(flex: deck.masteredCount, child: Container(color: AppColors.forestGreen)),
                          Flexible(flex: deck.learningCount, child: Container(color: accentColor)),
                          Flexible(flex: deck.newCount, child: Container(color: AppColors.border)),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
