import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/deck_service.dart';
import '../services/collection_service.dart';
import '../services/user_service.dart';
import '../theme/app_theme.dart';
import 'app_toast.dart';

Future<void> showDeckShareDialog(
  BuildContext context, {
  required String deckId,
  required String deckName,
}) {
  return showDialog(
    context: context,
    barrierColor: const Color(0x801A1A2E),
    builder: (_) => _ShareDialog(
      title: 'Share deck with',
      entityName: deckName,
      onShare: (memberIds) => DeckService.instance.shareDeck(deckId, memberIds),
    ),
  );
}

Future<void> showCollectionShareDialog(
  BuildContext context, {
  required String collectionId,
  required String collectionName,
}) {
  return showDialog(
    context: context,
    barrierColor: const Color(0x801A1A2E),
    builder: (_) => _ShareDialog(
      title: 'Share collection with',
      entityName: collectionName,
      onShare: (memberIds) => CollectionService.instance.shareCollection(collectionId, memberIds),
    ),
  );
}

class _ShareDialog extends StatefulWidget {
  const _ShareDialog({
    required this.title,
    required this.entityName,
    required this.onShare,
  });
  final String title;
  final String entityName;
  final Future<void> Function(List<String> memberIds) onShare;

  @override
  State<_ShareDialog> createState() => _ShareDialogState();
}

class _ShareDialogState extends State<_ShareDialog> {
  final _searchCtrl = TextEditingController();
  final Set<String> _selected = {};
  String _query = '';
  List<UserSummary> _users = [];
  bool _loading = true;
  bool _sharing = false;

  static const _avatarColors = [
    AppColors.periwinkle,
    AppColors.bubblegum,
    AppColors.sunnyYellow,
    AppColors.forestGreen,
    AppColors.orange,
  ];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    try {
      final users = await UserService.instance.listUsers();
      if (mounted) setState(() { _users = users; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<UserSummary> get _filtered {
    if (_query.isEmpty) return _users;
    final q = _query.toLowerCase();
    return _users.where((u) => u.name.toLowerCase().contains(q)).toList();
  }

  void _toggle(UserSummary user) {
    if (user.role == 'teacher') return;
    setState(() {
      if (_selected.contains(user.id)) {
        _selected.remove(user.id);
      } else {
        _selected.add(user.id);
      }
    });
  }

  String get _ctaLabel {
    final count = _selected.length;
    if (count == 0) return 'Select people to share with';
    if (count == 1) {
      final name = _users.firstWhere((u) => u.id == _selected.first).name.split(' ').first;
      return 'Share with $name';
    }
    return 'Share with $count people';
  }

  Future<void> _share() async {
    setState(() => _sharing = true);
    try {
      await widget.onShare(_selected.toList());
      if (!mounted) return;
      final names = _users
          .where((u) => _selected.contains(u.id))
          .map((u) => u.name.split(' ').first)
          .join(', ');
      showAppToast(
        context,
        variant: ToastVariant.success,
        title: 'Shared!',
        subtitle: '$names can now study this',
      );
      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      setState(() => _sharing = false);
      showAppToast(context, variant: ToastVariant.error, title: 'Failed to share');
    }
  }

  Color _colorFor(int index) => _avatarColors[index % _avatarColors.length];

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final selectedUsers = _users.where((u) => _selected.contains(u.id)).toList();

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
            _DialogHeader(title: widget.title, entityName: widget.entityName),
            if (selectedUsers.isNotEmpty)
              _SelectedChips(
                members: selectedUsers,
                colorFor: _colorFor,
                onRemove: (id) => setState(() => _selected.remove(id)),
              ),
            _SearchBar(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280),
              child: _loading
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(child: CircularProgressIndicator(color: AppColors.periwinkle)),
                    )
                  : filtered.isEmpty
                      ? const _EmptySearch()
                      : ListView.separated(
                          shrinkWrap: true,
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const SizedBox.shrink(),
                          itemBuilder: (_, i) {
                            final user = filtered[i];
                            final isTeacher = user.role == 'teacher';
                            return _MemberRow(
                              user: user,
                              avatarColor: _colorFor(_users.indexOf(user)),
                              selected: isTeacher || _selected.contains(user.id),
                              onTap: () => _toggle(user),
                            );
                          },
                        ),
            ),
            _Footer(
              label: _ctaLabel,
              enabled: _selected.isNotEmpty && !_sharing,
              loading: _sharing,
              onTap: _selected.isEmpty || _sharing ? null : _share,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────

class _DialogHeader extends StatelessWidget {
  const _DialogHeader({required this.title, required this.entityName});
  final String title;
  final String entityName;

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
                Text(title,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 18)),
                const SizedBox(height: 2),
                Text(entityName,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.ash, fontSize: 13),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(color: Color(0xFFF0EDE8), shape: BoxShape.circle),
              child: const Icon(Icons.close_rounded, color: AppColors.ash, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Selected chips ────────────────────────────────────────────────────────

class _SelectedChips extends StatelessWidget {
  const _SelectedChips({required this.members, required this.colorFor, required this.onRemove});
  final List<UserSummary> members;
  final Color Function(int) colorFor;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        children: members.map((u) {
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
                  width: 20, height: 20,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3), shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: Text(u.initials,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 6),
                Text(u.name.split(' ').first,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () => onRemove(u.id),
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

// ── Search bar ────────────────────────────────────────────────────────────

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
            borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.periwinkle, width: 1.5)),
        ),
      ),
    );
  }
}

// ── Member row ────────────────────────────────────────────────────────────

class _MemberRow extends StatelessWidget {
  const _MemberRow({
    required this.user,
    required this.avatarColor,
    required this.selected,
    required this.onTap,
  });
  final UserSummary user;
  final Color avatarColor;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isTeacher = user.role == 'teacher';
    final borderColor = isTeacher
        ? AppColors.sunnyYellow
        : selected ? AppColors.periwinkle : AppColors.border;
    final bgColor = isTeacher
        ? const Color(0xFFFEF9E8)
        : selected ? const Color(0xFFEEF3FE) : Colors.white;

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
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: avatarColor.withOpacity(0.2), shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Text(user.initials,
                  style: TextStyle(
                      color: avatarColor, fontSize: 13, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.name,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink)),
                  if (isTeacher)
                    const Text('Always included',
                        style: TextStyle(fontSize: 11, color: AppColors.ash)),
                ],
              ),
            ),
            if (isTeacher)
              const Icon(Icons.check_circle_rounded, color: AppColors.sunnyYellow, size: 22)
            else
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 22, height: 22,
                decoration: BoxDecoration(
                  color: selected ? AppColors.periwinkle : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: selected ? AppColors.periwinkle : AppColors.border, width: 2),
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

// ── Empty state ───────────────────────────────────────────────────────────

class _EmptySearch extends StatelessWidget {
  const _EmptySearch();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text('No one found', style: TextStyle(color: AppColors.fog, fontSize: 14)),
      ),
    );
  }
}

// ── Footer CTA ────────────────────────────────────────────────────────────

class _Footer extends StatelessWidget {
  const _Footer({required this.label, required this.enabled, required this.loading, this.onTap});
  final String label;
  final bool enabled;
  final bool loading;
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
          child: loading
              ? const SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text(label,
                  style: TextStyle(
                    color: enabled ? Colors.white : AppColors.fog,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  )),
        ),
      ),
    );
  }
}
