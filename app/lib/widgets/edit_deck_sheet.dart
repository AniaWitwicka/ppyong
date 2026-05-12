import 'package:flutter/material.dart';
import '../services/deck_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_toast.dart';
import 'app_bottom_sheet.dart';
import 'app_input.dart';

Future<bool> showEditDeckSheet(
  BuildContext context, {
  required String deckId,
  required String deckName,
  String? description,
}) async {
  final result = await showAppBottomSheet<bool>(
    context: context,
    child: _EditDeckSheet(deckId: deckId, deckName: deckName, description: description),
  );
  return result == true;
}

class _EditDeckSheet extends StatefulWidget {
  const _EditDeckSheet({required this.deckId, required this.deckName, this.description});
  final String deckId;
  final String deckName;
  final String? description;

  @override
  State<_EditDeckSheet> createState() => _EditDeckSheetState();
}

class _EditDeckSheetState extends State<_EditDeckSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.deckName);
    _descCtrl = TextEditingController(text: widget.description ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty || _saving) return;
    setState(() => _saving = true);
    try {
      await DeckService.instance.updateDeck(
        widget.deckId,
        name: name,
        description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(context, true);
      showAppToast(context, variant: ToastVariant.info, title: 'Deck updated');
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      showAppToast(context, variant: ToastVariant.error, title: 'Failed to save changes');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Edit deck', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 16),
        AppInput(hint: 'Deck name', controller: _nameCtrl, autofocus: true),
        const SizedBox(height: 10),
        AppInput(hint: 'Description (optional)', controller: _descCtrl),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: _saving ? null : () => Navigator.pop(context, false),
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
                onTap: _saving ? null : _save,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: const BoxDecoration(
                    color: AppColors.orange,
                    borderRadius: AppRadius.pill,
                  ),
                  alignment: Alignment.center,
                  child: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text('Save changes',
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
