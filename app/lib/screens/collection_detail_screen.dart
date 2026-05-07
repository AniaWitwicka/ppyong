import 'package:flutter/material.dart';
import '../models/deck.dart';
import '../services/deck_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_bottom_sheet.dart';
import '../widgets/app_input.dart';
import '../widgets/app_toast.dart';
import '../widgets/deck_share_dialog.dart';
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

  Future<void> _showAddDeckSheet() async {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final added = await showAppBottomSheet<bool>(
      context: context,
      child: _AddDeckSheet(nameCtrl: nameCtrl, descCtrl: descCtrl),
    );
    final name = nameCtrl.text.trim();
    final desc = descCtrl.text.trim();
    nameCtrl.dispose();
    descCtrl.dispose();
    if (added != true || name.isEmpty) return;
    try {
      await DeckService.instance.createDeck(widget.collectionId, name: name, description: desc);
      if (mounted) {
        showAppToast(context, variant: ToastVariant.success, title: 'Deck created');
        _load();
      }
    } catch (_) {
      if (mounted) showAppToast(context, variant: ToastVariant.error, title: 'Failed to create deck');
    }
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
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDeckSheet,
        backgroundColor: AppColors.orange,
        elevation: 4,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              collectionId: widget.collectionId,
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
  const _Header({required this.collectionId, required this.collectionName, required this.accentColor});
  final String collectionId;
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
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => showCollectionShareDialog(
              context,
              collectionId: collectionId,
              collectionName: collectionName,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.share_outlined, size: 14, color: Colors.white),
                  SizedBox(width: 5),
                  Text('Share', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                ],
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
                GestureDetector(
                  onTap: () => showDeckShareDialog(context, deckId: deck.id, deckName: deck.name),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    margin: const EdgeInsets.only(right: 8),
                    decoration: const BoxDecoration(
                      color: Color(0xFFEEF3FE),
                      borderRadius: AppRadius.pill,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.share_outlined, size: 13, color: AppColors.periwinkle),
                        const SizedBox(width: 4),
                        Text('Share',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.ink,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                )),
                      ],
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

// ── Add deck sheet ────────────────────────────────────────────────────────

class _AddDeckSheet extends StatelessWidget {
  const _AddDeckSheet({required this.nameCtrl, required this.descCtrl});
  final TextEditingController nameCtrl;
  final TextEditingController descCtrl;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('New deck', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 16),
        AppInput(hint: 'Deck name', controller: nameCtrl, autofocus: true),
        const SizedBox(height: 10),
        AppInput(hint: 'Description (optional)', controller: descCtrl),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => Navigator.pop(context, false),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: AppRadius.pill,
                  ),
                  alignment: Alignment.center,
                  child: Text('Cancel',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.ash)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () => Navigator.pop(context, true),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: const BoxDecoration(color: AppColors.orange, borderRadius: AppRadius.pill),
                  alignment: Alignment.center,
                  child: Text('Create deck',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: Colors.white, fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
