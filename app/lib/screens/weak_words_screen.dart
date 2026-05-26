import 'package:flutter/material.dart';
import '../models/weak_card.dart';
import '../services/user_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_toast.dart';
import '../widgets/app_error_body.dart';

class WeakWordsScreen extends StatefulWidget {
  const WeakWordsScreen({super.key});

  @override
  State<WeakWordsScreen> createState() => _WeakWordsScreenState();
}

class _WeakWordsScreenState extends State<WeakWordsScreen> {
  List<WeakCard> _cards = [];
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
      final cards = await UserService.instance.getWeakCards();
      if (mounted) setState(() { _cards = cards; _loading = false; });
    } catch (_) {
      if (mounted) {
        setState(() { _loading = false; _hasError = true; });
        showAppToast(context, variant: ToastVariant.error, title: 'Failed to load weak words');
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
            _TopBar(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.periwinkle));
    }
    if (_hasError) {
      return AppErrorBody(message: 'Could not load weak words', onRetry: _load);
    }
    if (_cards.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('🎉', style: TextStyle(fontSize: 56)),
            SizedBox(height: 16),
            Text('No weak words!',
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.ink)),
            SizedBox(height: 8),
            Text('Keep studying to maintain your progress',
                style: TextStyle(color: AppColors.ash, fontSize: 14)),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(
            children: [
              Text('${_cards.length} cards to work on',
                  style: const TextStyle(
                      color: AppColors.ash, fontSize: 13, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
            itemCount: _cards.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) => _WeakCardRow(card: _cards[i]),
          ),
        ),
      ],
    );
  }
}

class _TopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bubblegum,
      padding: const EdgeInsets.fromLTRB(16, 12, 20, 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 22),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text('Weak words',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white, fontSize: 20)),
          ),
        ],
      ),
    );
  }
}

class _WeakCardRow extends StatefulWidget {
  const _WeakCardRow({required this.card});
  final WeakCard card;

  @override
  State<_WeakCardRow> createState() => _WeakCardRowState();
}

class _WeakCardRowState extends State<_WeakCardRow> {
  bool _expanded = false;

  // Ease factor 2.5 is default — below 2.0 is struggling, below 1.5 is very weak.
  Color get _strengthColor {
    if (widget.card.easeFactor < 1.5) return AppColors.bubblegum;
    if (widget.card.easeFactor < 2.0) return AppColors.orange;
    return AppColors.sunnyYellow;
  }

  String get _strengthLabel {
    if (widget.card.easeFactor < 1.5) return 'Struggling';
    if (widget.card.easeFactor < 2.0) return 'Weak';
    return 'Shaky';
  }

  @override
  Widget build(BuildContext context) {
    final card = widget.card;
    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _expanded ? const Color(0xFFFEF0F6) : Colors.white,
          borderRadius: AppRadius.cardBorderRadius,
          border: Border.all(
            color: _expanded ? AppColors.bubblegum : AppColors.border,
            width: _expanded ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(card.korean,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w800, fontSize: 16)),
                      if (card.romanisation.isNotEmpty)
                        Text(card.romanisation,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.fog, fontSize: 12)),
                      Text(card.translation,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.ash, fontSize: 13)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _strengthColor.withOpacity(0.15),
                    borderRadius: AppRadius.pill,
                  ),
                  child: Text(_strengthLabel,
                      style: TextStyle(
                          color: _strengthColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 6),
                Icon(
                  _expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                  color: _expanded ? AppColors.bubblegum : AppColors.fog,
                  size: 20,
                ),
              ],
            ),
            if (_expanded) ...[
              const SizedBox(height: 10),
              const Divider(color: AppColors.border, height: 1),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.library_books_outlined, size: 13, color: AppColors.fog),
                  const SizedBox(width: 5),
                  Text('${card.collectionName} · ${card.deckName}',
                      style: const TextStyle(
                          color: AppColors.ash, fontSize: 12, fontWeight: FontWeight.w500)),
                ],
              ),
              if (card.notes.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(card.notes,
                    style: const TextStyle(
                        color: AppColors.ash, fontSize: 12, fontStyle: FontStyle.italic)),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
