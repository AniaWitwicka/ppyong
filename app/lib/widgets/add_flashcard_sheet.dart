import 'package:flutter/material.dart';
import '../services/card_service.dart';
import '../theme/app_theme.dart';
import 'app_bottom_sheet.dart';
import 'app_input.dart';
import 'app_toast.dart';

Future<void> showAddFlashcardSheet(
  BuildContext context, {
  required String deckId,
  required String deckName,
  int cardCount = 0,
}) {
  return showAppBottomSheet(
    context: context,
    child: _AddFlashcardSheet(deckId: deckId, deckName: deckName, cardCount: cardCount),
  );
}

class _AddFlashcardSheet extends StatefulWidget {
  const _AddFlashcardSheet({
    required this.deckId,
    required this.deckName,
    required this.cardCount,
  });
  final String deckId;
  final String deckName;
  final int cardCount;

  @override
  State<_AddFlashcardSheet> createState() => _AddFlashcardSheetState();
}

class _AddFlashcardSheetState extends State<_AddFlashcardSheet> {
  final _koreanCtrl = TextEditingController();
  final _romanisationCtrl = TextEditingController();
  final _translationCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  late int _cardCount;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _cardCount = widget.cardCount;
  }

  @override
  void dispose() {
    _koreanCtrl.dispose();
    _romanisationCtrl.dispose();
    _translationCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _clearForm() {
    _koreanCtrl.clear();
    _romanisationCtrl.clear();
    _translationCtrl.clear();
    _notesCtrl.clear();
  }

  Future<void> _save({required bool andNext}) async {
    final korean = _koreanCtrl.text.trim();
    final translation = _translationCtrl.text.trim();
    if (korean.isEmpty || translation.isEmpty) {
      showAppToast(context,
          variant: ToastVariant.error,
          title: 'Korean and translation required');
      return;
    }
    setState(() => _saving = true);
    try {
      await CardService.instance.createCard(
        widget.deckId,
        korean: korean,
        romanisation: _romanisationCtrl.text.trim(),
        translation: translation,
        notes: _notesCtrl.text.trim(),
      );
      if (!mounted) return;
      if (andNext) {
        setState(() {
          _cardCount++;
          _saving = false;
          _clearForm();
        });
        showAppToast(context,
            variant: ToastVariant.info,
            title: 'Card saved',
            subtitle: 'Add another or close when done');
      } else {
        Navigator.pop(context, true);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      showAppToast(context,
          variant: ToastVariant.error,
          title: 'Failed to save card');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Text('New flashcard', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: const BoxDecoration(
                color: Color(0xFFEEF3FE),
                borderRadius: AppRadius.pill,
              ),
              child: Text(
                'Card ${_cardCount + 1}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.periwinkle,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _koreanCtrl,
          autofocus: true,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.ink),
          decoration: InputDecoration(
            hintText: '한국어 (Korean)',
            hintStyle: const TextStyle(color: AppColors.fog, fontSize: 18, fontWeight: FontWeight.w700),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.border, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.periwinkle, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 10),
        AppInput(hint: 'Romanisation', controller: _romanisationCtrl),
        const SizedBox(height: 10),
        AppInput(hint: 'Translation', controller: _translationCtrl),
        const SizedBox(height: 10),
        AppInput(hint: 'Notes / example sentence (optional)', controller: _notesCtrl),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: _saving ? null : () => _save(andNext: false),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: AppRadius.pill,
                  ),
                  alignment: Alignment.center,
                  child: Text('Save & close',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.ash)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: _saving ? null : () => _save(andNext: true),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: const BoxDecoration(color: AppColors.orange, borderRadius: AppRadius.pill),
                  alignment: Alignment.center,
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text('Save & add next',
                          style: Theme.of(context)
                              .textTheme
                              .labelLarge
                              ?.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
