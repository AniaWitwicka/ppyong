import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'app_bottom_sheet.dart';
import 'app_input.dart';

Future<void> showEditDeckSheet(BuildContext context, {required String deckName}) {
  return showAppBottomSheet(
    context: context,
    child: _EditDeckSheet(deckName: deckName),
  );
}

class _EditDeckSheet extends StatefulWidget {
  const _EditDeckSheet({required this.deckName});
  final String deckName;

  @override
  State<_EditDeckSheet> createState() => _EditDeckSheetState();
}

class _EditDeckSheetState extends State<_EditDeckSheet> {
  late final TextEditingController _nameCtrl;
  final _descCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.deckName);
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
                onTap: () {
                  // TODO: save to backend
                  Navigator.pop(context);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: const BoxDecoration(
                    color: AppColors.orange,
                    borderRadius: AppRadius.pill,
                  ),
                  alignment: Alignment.center,
                  child: Text('Save changes',
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
