import 'package:flutter/material.dart';
import '../services/collection_service.dart';
import '../theme/app_theme.dart';
import 'app_bottom_sheet.dart';
import 'app_input.dart';
import 'app_toast.dart';

const _colors = [
  AppColors.periwinkle,
  AppColors.forestGreen,
  AppColors.orange,
  AppColors.bubblegum,
  AppColors.sunnyYellow,
];

const _emojis = ['📚', '🏠', '🍜', '🚇', '💬', '⭐', '🎵', '✈️'];

Future<void> showAddCollectionSheet(BuildContext context) {
  return showAppBottomSheet(
    context: context,
    child: const _AddCollectionSheet(),
  );
}

class _AddCollectionSheet extends StatefulWidget {
  const _AddCollectionSheet();

  @override
  State<_AddCollectionSheet> createState() => _AddCollectionSheetState();
}

class _AddCollectionSheetState extends State<_AddCollectionSheet> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  Color _selectedColor = _colors[0];
  String _selectedEmoji = _emojis[0];
  bool _saving = false;

  String get _colorHex =>
      '#${_selectedColor.value.toRadixString(16).substring(2).toUpperCase()}';

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() => _saving = true);
    try {
      await CollectionService.instance.createCollection(
        name: name,
        emoji: _selectedEmoji,
        color: _colorHex,
      );
      if (!mounted) return;
      showAppToast(context,
          variant: ToastVariant.success,
          title: 'Collection created',
          subtitle: name);
      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      showAppToast(context,
          variant: ToastVariant.error,
          title: 'Could not create collection');
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('New collection', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 16),
        AppInput(hint: 'Collection name', controller: _nameCtrl, autofocus: true),
        const SizedBox(height: 10),
        AppInput(hint: 'Description (optional)', controller: _descCtrl),
        const SizedBox(height: 16),
        Text('Colour', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.ash)),
        const SizedBox(height: 10),
        Row(
          children: _colors.map((c) {
            final selected = c == _selectedColor;
            return GestureDetector(
              onTap: () => setState(() => _selectedColor = c),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 32,
                height: 32,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  color: c,
                  shape: BoxShape.circle,
                  border: selected ? Border.all(color: AppColors.ink, width: 3) : null,
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        Text('Emoji', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.ash)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _emojis.map((e) {
            final selected = e == _selectedEmoji;
            return GestureDetector(
              onTap: () => setState(() => _selectedEmoji = e),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: selected ? _selectedColor.withOpacity(0.2) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected ? _selectedColor : AppColors.border,
                    width: selected ? 2 : 1,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(e, style: const TextStyle(fontSize: 22)),
              ),
            );
          }).toList(),
        ),
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
                  child: Text('Create collection',
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
