import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'app_bottom_sheet.dart';
import 'app_input.dart';
import 'app_toast.dart';

Future<void> showAddFlashcardSheet(BuildContext context, {required String deckName, int cardCount = 0}) {
  return showAppBottomSheet(
    context: context,
    child: _AddFlashcardSheet(deckName: deckName, cardCount: cardCount),
  );
}

class _AddFlashcardSheet extends StatefulWidget {
  const _AddFlashcardSheet({required this.deckName, required this.cardCount});
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
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
          decoration: InputDecoration(
            hintText: '한국어 (Korean)',
            hintStyle: const TextStyle(
              color: AppColors.fog,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
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
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: AppRadius.pill,
                  ),
                  alignment: Alignment.center,
                  child: Text('Save & close',
                      style: Theme.of(context)
                          .textTheme
                          .labelLarge
                          ?.copyWith(color: AppColors.ash)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _cardCount++;
                    _clearForm();
                  });
                  showAppToast(
                    context,
                    variant: ToastVariant.info,
                    title: 'Card saved',
                    subtitle: 'Add another or close when done',
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: const BoxDecoration(
                    color: AppColors.orange,
                    borderRadius: AppRadius.pill,
                  ),
                  alignment: Alignment.center,
                  child: Text('Save & add next',
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
