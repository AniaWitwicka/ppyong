import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'app_toast.dart';

typedef _Member = ({String id, String name, String initials, Color color, bool isTeacher});

const _mockMembers = <_Member>[
  (id: 'teacher', name: 'Park Min-jun', initials: 'PM', color: AppColors.sunnyYellow, isTeacher: true),
  (id: 'm1', name: 'Kim Soo-ah', initials: 'KS', color: AppColors.periwinkle, isTeacher: false),
  (id: 'm2', name: 'Lee Ji-yeon', initials: 'LJ', color: AppColors.bubblegum, isTeacher: false),
  (id: 'm3', name: 'Choi Hyun-woo', initials: 'CH', color: AppColors.forestGreen, isTeacher: false),
];

Future<void> showDeckShareDialog(BuildContext context, {required String deckName}) {
  return showDialog(
    context: context,
    barrierColor: const Color(0x801A1A2E),
    builder: (_) => _DeckShareDialog(deckName: deckName),
  );
}

class _DeckShareDialog extends StatefulWidget {
  const _DeckShareDialog({required this.deckName});
  final String deckName;

  @override
  State<_DeckShareDialog> createState() => _DeckShareDialogState();
}

class _DeckShareDialogState extends State<_DeckShareDialog> {
  final _searchCtrl = TextEditingController();
  final Set<String> _selected = {};
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<_Member> get _filtered {
    if (_query.isEmpty) return _mockMembers;
    final q = _query.toLowerCase();
    return _mockMembers.where((m) => m.name.toLowerCase().contains(q)).toList();
  }

  void _toggle(_Member member) {
    if (member.isTeacher) return;
    setState(() {
      if (_selected.contains(member.id)) {
        _selected.remove(member.id);
      } else {
        _selected.add(member.id);
      }
    });
  }

  String get _ctaLabel {
    final count = _selected.length;
    if (count == 0) return 'Select people to share with';
    if (count == 1) {
      final name = _mockMembers.firstWhere((m) => m.id == _selected.first).name.split(' ').first;
      return 'Share with $name';
    }
    return 'Share with $count people';
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final selectedMembers = _mockMembers.where((m) => _selected.contains(m.id)).toList();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DialogHeader(deckName: widget.deckName),
            if (selectedMembers.isNotEmpty)
              _SelectedChips(
                members: selectedMembers,
                onRemove: (id) => setState(() => _selected.remove(id)),
              ),
            _SearchBar(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280),
              child: filtered.isEmpty
                  ? const _EmptySearch()
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 0),
                      itemBuilder: (_, i) => _MemberRow(
                        member: filtered[i],
                        selected: filtered[i].isTeacher || _selected.contains(filtered[i].id),
                        onTap: () => _toggle(filtered[i]),
                      ),
                    ),
            ),
            _Footer(
              label: _ctaLabel,
              enabled: _selected.isNotEmpty,
              onTap: _selected.isEmpty
                  ? null
                  : () {
                      final names = _mockMembers
                          .where((m) => _selected.contains(m.id))
                          .map((m) => m.name.split(' ').first)
                          .join(', ');
                      showAppToast(
                        context,
                        variant: ToastVariant.success,
                        title: 'Deck shared!',
                        subtitle: '$names can now study this deck',
                      );
                      Navigator.pop(context);
                    },
            ),
          ],
        ),
      ),
    );
  }
}

class _DialogHeader extends StatelessWidget {
  const _DialogHeader({required this.deckName});
  final String deckName;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Share deck with',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 18),
                ),
                const SizedBox(height: 2),
                Text(
                  deckName,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.ash,
                        fontSize: 13,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Color(0xFFF0EDE8),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close_rounded, color: AppColors.ash, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectedChips extends StatelessWidget {
  const _SelectedChips({required this.members, required this.onRemove});
  final List<_Member> members;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        children: members.map((m) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.periwinkle,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    m.initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  m.name.split(' ').first,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () => onRemove(m.id),
                  child: const Icon(Icons.close_rounded, color: Colors.white, size: 14),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller, required this.onChanged});
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(fontSize: 14, color: AppColors.ink),
        decoration: InputDecoration(
          hintText: 'Search members...',
          hintStyle: const TextStyle(color: AppColors.fog, fontSize: 14),
          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.fog, size: 20),
          filled: true,
          fillColor: const Color(0xFFF0EDE8),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.periwinkle, width: 1.5),
          ),
        ),
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({required this.member, required this.selected, required this.onTap});
  final _Member member;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isTeacher = member.isTeacher;
    final borderColor = isTeacher
        ? AppColors.sunnyYellow
        : selected
            ? AppColors.periwinkle
            : AppColors.border;
    final bgColor = isTeacher
        ? const Color(0xFFFEF9E8)
        : selected
            ? const Color(0xFFEEF3FE)
            : Colors.white;

    return GestureDetector(
      onTap: isTeacher ? null : onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: selected || isTeacher ? 2 : 1),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: member.color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                member.initials,
                style: TextStyle(
                  color: member.color,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  if (isTeacher)
                    const Text(
                      'Always included',
                      style: TextStyle(fontSize: 11, color: AppColors.ash),
                    ),
                ],
              ),
            ),
            if (isTeacher)
              const Icon(Icons.check_circle_rounded, color: AppColors.sunnyYellow, size: 22)
            else
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: selected ? AppColors.periwinkle : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: selected ? AppColors.periwinkle : AppColors.border,
                    width: 2,
                  ),
                ),
                child: selected
                    ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                    : null,
              ),
          ],
        ),
      ),
    );
  }
}

class _EmptySearch extends StatelessWidget {
  const _EmptySearch();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(
          'No one found',
          style: TextStyle(color: AppColors.fog, fontSize: 14),
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.label, required this.enabled, this.onTap});
  final String label;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            color: enabled ? AppColors.orange : AppColors.border,
            borderRadius: AppRadius.pill,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: enabled ? Colors.white : AppColors.fog,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
