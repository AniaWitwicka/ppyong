import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../models/collection.dart';
import '../models/import.dart';
import '../models/teacher.dart';
import '../services/collection_service.dart';
import '../services/deck_service.dart';
import '../services/group_service.dart';
import '../services/import_service.dart';
import '../services/teacher_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_toast.dart';

class ImportDeckScreen extends StatefulWidget {
  const ImportDeckScreen({super.key});

  @override
  State<ImportDeckScreen> createState() => _ImportDeckScreenState();
}

class _ImportDeckScreenState extends State<ImportDeckScreen> {
  int _step = 0;
  int _sourceTab = 0;
  bool _busy = false;

  // Step 0 — Source
  final _pasteController = TextEditingController();
  Uint8List? _csvBytes;
  String? _csvFilename;

  // Step 1 — Preview
  ImportResult? _importResult;
  List<ParsedCard> _cards = [];
  bool _showAll = false;

  // Step 2 — Save
  final _deckNameController = TextEditingController(text: 'Imported deck');
  String? _selectedCollectionId;
  String? _selectedGroupId;
  List<Collection> _collections = [];
  List<TeacherGroupSummary> _groups = [];

  @override
  void initState() {
    super.initState();
    // Rebuild when deck name changes so the summary chip stays current
    _deckNameController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _pasteController.dispose();
    _deckNameController.dispose();
    super.dispose();
  }

  Future<void> _onPreview() async {
    if (_sourceTab == 0 && _pasteController.text.trim().isEmpty) {
      showAppToast(context, variant: ToastVariant.error, title: 'Paste some text first');
      return;
    }
    if (_sourceTab == 1 && _csvBytes == null) {
      showAppToast(context, variant: ToastVariant.error, title: 'Pick a CSV file first');
      return;
    }
    setState(() => _busy = true);
    try {
      final ImportResult result;
      if (_sourceTab == 0) {
        result = await ImportService.instance.previewPaste(_pasteController.text.trim());
      } else {
        result = await ImportService.instance.previewCsv(_csvBytes!, _csvFilename ?? 'import.csv');
      }
      if (!mounted) return;
      if (result.parsedCards.isEmpty) {
        showAppToast(context, variant: ToastVariant.error, title: 'No cards detected', subtitle: 'Check your format and try again');
        setState(() => _busy = false);
        return;
      }
      _importResult = result;
      _cards = List.from(result.parsedCards);
      _showAll = false;
      setState(() { _step = 1; _busy = false; });
    } catch (_) {
      if (mounted) {
        showAppToast(context, variant: ToastVariant.error, title: 'Failed to parse');
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _loadStep2Data() async {
    try {
      final results = await Future.wait([
        CollectionService.instance.listCollections(),
        TeacherService.instance.getDashboard(),
      ]);
      if (mounted) {
        setState(() {
          _collections = results[0] as List<Collection>;
          _groups = (results[1] as TeacherDashboard).groups;
        });
      }
    } catch (_) {}
  }

  Future<void> _onSave() async {
    final name = _deckNameController.text.trim();
    if (name.isEmpty) {
      showAppToast(context, variant: ToastVariant.error, title: 'Enter a deck name');
      return;
    }
    if (_selectedCollectionId == null) {
      showAppToast(context, variant: ToastVariant.error, title: 'Select a collection');
      return;
    }
    setState(() => _busy = true);
    try {
      final deck = await DeckService.instance.createDeck(_selectedCollectionId!, name: name);
      final created = await ImportService.instance.bulkCreateCards(deck.id, _cards);
      if (_selectedGroupId != null) {
        try {
          final group = await GroupService.instance.getGroup(_selectedGroupId!);
          final memberIds = group.members.map((m) => m.userId).toList();
          await DeckService.instance.shareDeck(deck.id, memberIds);
        } catch (_) {
          // non-fatal — deck saved, share failed silently
        }
      }
      if (mounted) {
        showAppToast(
          context,
          variant: ToastVariant.success,
          title: 'Imported $created cards',
          subtitle: "into '$name'",
        );
        Navigator.pop(context);
      }
    } catch (_) {
      if (mounted) {
        showAppToast(context, variant: ToastVariant.error, title: 'Failed to save deck');
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _pickCsv() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true,
    );
    if (result != null && result.files.single.bytes != null) {
      setState(() {
        _csvBytes = result.files.single.bytes;
        _csvFilename = result.files.single.name;
      });
    }
  }

  Future<void> _createCollection() async {
    final nameCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'New collection',
          style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w800),
        ),
        content: TextField(
          controller: nameCtrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Collection name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Create')),
        ],
      ),
    );
    if (confirmed != true || nameCtrl.text.trim().isEmpty) return;
    try {
      final col = await CollectionService.instance.createCollection(
        name: nameCtrl.text.trim(),
        emoji: '📚',
        color: '#99B7F5',
      );
      if (mounted) {
        setState(() {
          _collections = [..._collections, col];
          _selectedCollectionId = col.id;
        });
      }
    } catch (_) {
      if (mounted) showAppToast(context, variant: ToastVariant.error, title: 'Failed to create collection');
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
            _ImportHeader(step: _step),
            Expanded(child: _buildStep()),
          ],
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return _SourceStep(
          tab: _sourceTab,
          onTabChange: (t) => setState(() => _sourceTab = t),
          pasteController: _pasteController,
          csvFilename: _csvFilename,
          onPickCsv: _pickCsv,
          busy: _busy,
          onPreview: _onPreview,
        );
      case 1:
        return _PreviewStep(
          result: _importResult!,
          cards: _cards,
          showAll: _showAll,
          onToggleShowAll: () => setState(() => _showAll = !_showAll),
          onBack: () => setState(() => _step = 0),
          onContinue: () {
            _loadStep2Data();
            setState(() => _step = 2);
          },
        );
      default:
        return _SaveStep(
          cards: _cards,
          deckNameController: _deckNameController,
          collections: _collections,
          groups: _groups,
          selectedCollectionId: _selectedCollectionId,
          selectedGroupId: _selectedGroupId,
          onCollectionSelected: (id) => setState(() => _selectedCollectionId = id),
          onGroupSelected: (id) => setState(() => _selectedGroupId = id),
          onNewCollection: _createCollection,
          busy: _busy,
          onBack: () => setState(() => _step = 1),
          onSave: _onSave,
        );
    }
  }
}

// ── Header + step indicator ───────────────────────────────────────────────────

class _ImportHeader extends StatelessWidget {
  const _ImportHeader({required this.step});
  final int step;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.forestGreen,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 22),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Import deck',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontSize: 18,
                          ),
                    ),
                    Text(
                      'Bulk add cards from text or a file',
                      style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _StepIndicator(step: step),
        ],
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.step});
  final int step;

  @override
  Widget build(BuildContext context) {
    const labels = ['Source', 'Preview', 'Save'];
    // Row: dot0 | line01 | dot1 | line12 | dot2  (5 items, even=dot, odd=line)
    return Row(
      children: List.generate(5, (i) {
        if (i.isOdd) {
          final done = step > i ~/ 2;
          return Expanded(
            child: Container(
              height: 1.5,
              color: done ? Colors.white.withOpacity(0.6) : Colors.white.withOpacity(0.3),
            ),
          );
        }
        final idx = i ~/ 2;
        final isDone = step > idx;
        final isActive = step == idx;
        return Column(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: isDone
                    ? AppColors.forestGreen
                    : isActive
                        ? Colors.white
                        : Colors.white.withOpacity(0.25),
                shape: BoxShape.circle,
                border: isActive ? Border.all(color: Colors.white, width: 2) : null,
              ),
              alignment: Alignment.center,
              child: isDone
                  ? const Icon(Icons.check, size: 13, color: Colors.white)
                  : Text(
                      '${idx + 1}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isActive ? const Color(0xFF16563A) : Colors.white,
                      ),
                    ),
            ),
            const SizedBox(height: 4),
            Text(
              labels[idx],
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: (isActive || isDone) ? Colors.white : Colors.white.withOpacity(0.55),
              ),
            ),
          ],
        );
      }),
    );
  }
}

// ── Step 0 — Source ───────────────────────────────────────────────────────────

class _SourceStep extends StatelessWidget {
  const _SourceStep({
    required this.tab,
    required this.onTabChange,
    required this.pasteController,
    required this.csvFilename,
    required this.onPickCsv,
    required this.busy,
    required this.onPreview,
  });

  final int tab;
  final ValueChanged<int> onTabChange;
  final TextEditingController pasteController;
  final String? csvFilename;
  final VoidCallback onPickCsv;
  final bool busy;
  final VoidCallback onPreview;

  static const _tabs = [
    (Icons.content_paste_rounded, 'Paste'),
    (Icons.description_outlined, 'CSV'),
    (Icons.link_rounded, 'Sheet'),
    (Icons.casino_outlined, 'Anki'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(
            children: List.generate(_tabs.length, (i) {
              final selected = tab == i;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTabChange(i),
                  child: Container(
                    margin: EdgeInsets.only(left: i > 0 ? 6 : 0),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: selected ? const Color(0xFFE8F5EE) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected ? AppColors.forestGreen : AppColors.border,
                        width: selected ? 2 : 1.5,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          _tabs[i].$1,
                          size: 18,
                          color: selected ? const Color(0xFF16563A) : AppColors.ash,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _tabs[i].$2,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: selected ? const Color(0xFF16563A) : AppColors.ash,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: _buildTabContent(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          child: GestureDetector(
            onTap: busy ? null : onPreview,
            child: Container(
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                color: busy ? AppColors.orange.withOpacity(0.6) : AppColors.orange,
                borderRadius: AppRadius.pill,
              ),
              alignment: Alignment.center,
              child: busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text(
                      'Preview →',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabContent() {
    switch (tab) {
      case 0:
        return _PasteContent(controller: pasteController);
      case 1:
        return _CsvContent(filename: csvFilename, onPick: onPickCsv);
      case 2:
        return const _SheetContent();
      default:
        return const _AnkiContent();
    }
  }
}

class _PasteContent extends StatelessWidget {
  const _PasteContent({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            'KO | EN | ROMAJA',
            style: TextStyle(fontSize: 11, color: AppColors.ash, fontFamily: 'monospace'),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          minLines: 8,
          maxLines: null,
          style: const TextStyle(fontSize: 13, height: 1.6),
          decoration: InputDecoration(
            hintText: '안녕하세요 | Hello | annyeonghaseyo\n감사합니다 | Thank you | gamsahamnida\n사랑해 | I love you | saranghae\n괜찮아요 | It\'s okay | gwaenchanayo\n어디예요? | Where is it? | eodiyeyo\n잘 먹겠습니다 | Bon appétit | jal meokgetseumnida',
            hintStyle: TextStyle(fontSize: 12, color: AppColors.fog, height: 1.6),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.all(14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.border, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.periwinkle, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF9E8),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.sunnyYellow, width: 1.5),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.auto_awesome, size: 16, color: Color(0xFF7A5500)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Format is auto-detected — use | · tab · or comma as separator. Romanisation is optional.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF7A5500), height: 1.4),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CsvContent extends StatelessWidget {
  const _CsvContent({required this.filename, required this.onPick});
  final String? filename;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPick,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: const Color(0xFFEEF3FE),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.periwinkle, width: 2),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.upload_file_outlined, size: 24, color: AppColors.periwinkle),
              ),
              const SizedBox(height: 12),
              Text(
                filename ?? 'Tap to browse CSV',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: filename != null ? AppColors.forestGreen : AppColors.periwinkle,
                ),
              ),
              if (filename == null) ...[
                const SizedBox(height: 4),
                const Text('or drop a .csv file', style: TextStyle(fontSize: 11, color: AppColors.ash)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetContent extends StatelessWidget {
  const _SheetContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Google Sheets URL',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border, width: 1.5),
          ),
          child: const Text(
            'https://docs.google.com/spreadsheets/...',
            style: TextStyle(fontSize: 13, color: AppColors.fog),
          ),
        ),
        const SizedBox(height: 12),
        const Text('Google Sheets import coming soon.', style: TextStyle(fontSize: 12, color: AppColors.ash)),
      ],
    );
  }
}

class _AnkiContent extends StatelessWidget {
  const _AnkiContent();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: const Color(0xFFFEF0F6),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.bubblegum, width: 2),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('🃏', style: TextStyle(fontSize: 48)),
            SizedBox(height: 8),
            Text(
              'Anki import coming soon',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.bubblegum),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Step 1 — Preview ──────────────────────────────────────────────────────────

class _PreviewStep extends StatelessWidget {
  const _PreviewStep({
    required this.result,
    required this.cards,
    required this.showAll,
    required this.onToggleShowAll,
    required this.onBack,
    required this.onContinue,
  });

  final ImportResult result;
  final List<ParsedCard> cards;
  final bool showAll;
  final VoidCallback onToggleShowAll;
  final VoidCallback onBack;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final visible = showAll ? cards : cards.take(6).toList();
    final remaining = cards.length - 6;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Preview', style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: const BoxDecoration(
                        color: AppColors.forestGreen,
                        borderRadius: AppRadius.pill,
                      ),
                      child: Text(
                        '${cards.length} cards',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      result.detectedFormat,
                      style: const TextStyle(fontSize: 10, color: AppColors.ash),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5EE),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.forestGreen, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline, size: 16, color: AppColors.forestGreen),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            style: const TextStyle(fontSize: 12, color: Color(0xFF16563A)),
                            children: [
                              const TextSpan(text: 'Auto-detected: '),
                              TextSpan(
                                text: result.detectedFormat,
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: AppRadius.cardBorderRadius,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      ...visible.asMap().entries.map((e) => _PreviewCard(
                            index: e.key,
                            card: e.value,
                            isLast: e.key == visible.length - 1 && (showAll || remaining <= 0),
                          )),
                      if (!showAll && remaining > 0)
                        GestureDetector(
                          onTap: onToggleShowAll,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Center(
                              child: Text(
                                '+ $remaining more cards…',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.periwinkle,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        _BackContinueRow(onBack: onBack, onContinue: onContinue, continueLabel: 'Continue →'),
      ],
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({required this.index, required this.card, required this.isLast});
  final int index;
  final ParsedCard card;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF3FE),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.periwinkle,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      card.korean,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Nunito',
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: card.translation,
                            style: const TextStyle(fontSize: 11, color: AppColors.ash),
                          ),
                          if (card.romanisation.isNotEmpty) ...[
                            const TextSpan(
                              text: ' · ',
                              style: TextStyle(fontSize: 11, color: AppColors.fog),
                            ),
                            TextSpan(
                              text: card.romanisation,
                              style: const TextStyle(fontSize: 10, color: AppColors.ash),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.edit_outlined, size: 14, color: AppColors.fog),
            ],
          ),
        ),
        if (!isLast) const Divider(height: 1, color: AppColors.border),
      ],
    );
  }
}

// ── Step 2 — Save ─────────────────────────────────────────────────────────────

class _SaveStep extends StatelessWidget {
  const _SaveStep({
    required this.cards,
    required this.deckNameController,
    required this.collections,
    required this.groups,
    required this.selectedCollectionId,
    required this.selectedGroupId,
    required this.onCollectionSelected,
    required this.onGroupSelected,
    required this.onNewCollection,
    required this.busy,
    required this.onBack,
    required this.onSave,
  });

  final List<ParsedCard> cards;
  final TextEditingController deckNameController;
  final List<Collection> collections;
  final List<TeacherGroupSummary> groups;
  final String? selectedCollectionId;
  final String? selectedGroupId;
  final ValueChanged<String?> onCollectionSelected;
  final ValueChanged<String?> onGroupSelected;
  final VoidCallback onNewCollection;
  final bool busy;
  final VoidCallback onBack;
  final VoidCallback onSave;

  String get _selectedCollectionName {
    if (selectedCollectionId == null) return 'collection';
    try {
      return collections.firstWhere((c) => c.id == selectedCollectionId).name;
    } catch (_) {
      return 'collection';
    }
  }

  @override
  Widget build(BuildContext context) {
    final deckName = deckNameController.text.trim().isEmpty ? 'deck' : deckNameController.text.trim();

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Deck name',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 16),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: deckNameController,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.border, width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.periwinkle, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Collection',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 16),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ...collections.map((c) {
                      final selected = selectedCollectionId == c.id;
                      return GestureDetector(
                        onTap: () => onCollectionSelected(c.id),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: selected ? const Color(0xFFE8F5EE) : Colors.white,
                            borderRadius: AppRadius.pill,
                            border: Border.all(
                              color: selected ? AppColors.forestGreen : AppColors.border,
                              width: selected ? 2 : 1.5,
                            ),
                          ),
                          child: Text(
                            '${c.emoji} ${c.name}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: selected ? const Color(0xFF16563A) : AppColors.ink,
                            ),
                          ),
                        ),
                      );
                    }),
                    GestureDetector(
                      onTap: onNewCollection,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: AppRadius.pill,
                          border: Border.all(color: AppColors.border, width: 1.5),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add, size: 14, color: AppColors.ash),
                            SizedBox(width: 4),
                            Text(
                              'New',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ash),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'Assign to group',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 16),
                ),
                const SizedBox(height: 10),
                _GroupRadioOption(
                  label: 'Save to library only',
                  sublabel: "Don't assign to a group",
                  icon: Icons.library_books_outlined,
                  selected: selectedGroupId == null,
                  onTap: () => onGroupSelected(null),
                ),
                ...groups.map((g) => Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: _GroupRadioOption(
                        label: g.name,
                        sublabel: '${g.memberCount} students',
                        emoji: g.emoji,
                        selected: selectedGroupId == g.id,
                        onTap: () => onGroupSelected(g.id),
                      ),
                    )),
                if (selectedCollectionId != null) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF3FE),
                      borderRadius: AppRadius.pill,
                      border: Border.all(color: AppColors.periwinkle.withOpacity(0.6), width: 1.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.layers_outlined, size: 16, color: AppColors.periwinkle),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text.rich(
                            TextSpan(
                              style: const TextStyle(fontSize: 12, color: AppColors.ink),
                              children: [
                                TextSpan(
                                  text: '${cards.length} cards',
                                  style: const TextStyle(fontWeight: FontWeight.w800),
                                ),
                                const TextSpan(text: ' → '),
                                TextSpan(text: "'$deckName'"),
                                const TextSpan(text: ' in '),
                                TextSpan(
                                  text: _selectedCollectionName,
                                  style: const TextStyle(fontWeight: FontWeight.w800),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
        _BackContinueRow(
          onBack: onBack,
          onContinue: busy ? null : onSave,
          continueLabel: 'Save deck',
          continueIcon: Icons.auto_awesome,
          busy: busy,
          continueColor: AppColors.orange,
        ),
      ],
    );
  }
}

class _GroupRadioOption extends StatelessWidget {
  const _GroupRadioOption({
    required this.label,
    required this.sublabel,
    required this.selected,
    required this.onTap,
    this.emoji,
    this.icon,
  });

  final String label;
  final String sublabel;
  final bool selected;
  final VoidCallback onTap;
  final String? emoji;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE8F5EE) : Colors.white,
          borderRadius: AppRadius.cardBorderRadius,
          border: Border.all(
            color: selected ? AppColors.forestGreen : AppColors.border,
            width: selected ? 2 : 1.5,
          ),
        ),
        child: Row(
          children: [
            if (emoji != null) ...[
              Text(emoji!, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 10),
            ] else if (icon != null) ...[
              Icon(icon, size: 20, color: AppColors.ash),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink)),
                  Text(sublabel, style: const TextStyle(fontSize: 11, color: AppColors.ash)),
                ],
              ),
            ),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? AppColors.forestGreen : Colors.transparent,
                border: Border.all(
                  color: selected ? AppColors.forestGreen : AppColors.border,
                  width: 2,
                ),
              ),
              child: selected ? const Icon(Icons.check, size: 12, color: Colors.white) : null,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared ────────────────────────────────────────────────────────────────────

class _BackContinueRow extends StatelessWidget {
  const _BackContinueRow({
    required this.onBack,
    required this.onContinue,
    required this.continueLabel,
    this.continueIcon,
    this.busy = false,
    this.continueColor = AppColors.forestGreen,
  });

  final VoidCallback onBack;
  final VoidCallback? onContinue;
  final String continueLabel;
  final IconData? continueIcon;
  final bool busy;
  final Color continueColor;

  @override
  Widget build(BuildContext context) {
    final disabled = onContinue == null || busy;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: AppRadius.pill,
                border: Border.all(color: AppColors.border, width: 1.5),
              ),
              alignment: Alignment.center,
              child: const Text(
                '← Back',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: onContinue,
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: disabled ? continueColor.withOpacity(0.6) : continueColor,
                  borderRadius: AppRadius.pill,
                ),
                alignment: Alignment.center,
                child: busy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (continueIcon != null) ...[
                            Icon(continueIcon, size: 16, color: Colors.white),
                            const SizedBox(width: 6),
                          ],
                          Text(
                            continueLabel,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
