import 'package:flutter/material.dart';
import '../models/group.dart';
import '../services/api_service.dart';
import '../services/group_service.dart';
import '../services/invite_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_bottom_sheet.dart';
import '../widgets/app_input.dart';
import '../widgets/app_toast.dart';
import 'flashcard_study_screen.dart';

class GroupDetailScreen extends StatefulWidget {
  const GroupDetailScreen({super.key, required this.groupId});
  final String groupId;

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  GroupDetail? _group;
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
      final group = await GroupService.instance.getGroup(widget.groupId);
      if (mounted) setState(() { _group = group; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _loading = false; _hasError = true; });
    }
  }

  Future<void> _showInviteSheet() async {
    final group = _group;
    if (group == null) return;
    await showAppBottomSheet(
      context: context,
      child: _InviteToGroupSheet(groupId: group.id, groupName: group.name),
    );
  }

  Future<void> _showEditSheet() async {
    final group = _group;
    if (group == null) return;
    final saved = await showAppBottomSheet<bool>(
      context: context,
      child: _EditGroupSheet(group: group, onSaved: (_) => Navigator.pop(context, true)),
    );
    if (saved == true) _load();
  }

  Future<void> _confirmLeave() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave group?'),
        content: Text('You will no longer have access to ${_group?.name}.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Leave', style: TextStyle(color: AppColors.bubblegum)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await GroupService.instance.leaveGroup(widget.groupId);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) showAppToast(context, variant: ToastVariant.error, title: 'Could not leave group');
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete group?'),
        content: Text('This will permanently delete "${_group?.name}" and remove all members. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await GroupService.instance.deleteGroup(widget.groupId);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) showAppToast(context, variant: ToastVariant.error, title: 'Could not delete group');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: SafeArea(
        bottom: false,
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.bubblegum))
            : _hasError
                ? _ErrorBody(onRetry: _load)
                : _Body(
                    group: _group!,
                    onInvite: _showInviteSheet,
                    onEdit: _showEditSheet,
                    onLeave: _confirmLeave,
                    onDelete: _confirmDelete,
                  ),
      ),
    );
  }
}

// ── Body ──────────────────────────────────────────────────────────────────

class _Body extends StatelessWidget {
  const _Body({
    required this.group,
    required this.onInvite,
    required this.onEdit,
    required this.onLeave,
    required this.onDelete,
  });
  final GroupDetail group;
  final VoidCallback onInvite;
  final VoidCallback onEdit;
  final VoidCallback onLeave;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _Header(group: group, onInvite: onInvite, onEdit: onEdit, onLeave: onLeave, onDelete: onDelete),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _GroupProgressCard(members: group.members),
                const SizedBox(height: 24),
                _SharedDecksSection(decks: group.sharedDecks),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({
    required this.group,
    required this.onInvite,
    required this.onEdit,
    required this.onLeave,
    required this.onDelete,
  });
  final GroupDetail group;
  final VoidCallback onInvite;
  final VoidCallback onEdit;
  final VoidCallback onLeave;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bubblegum,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        children: [
          Row(
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
              Text(group.emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(group.name,
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(color: Colors.white, fontSize: 18)),
                    Text(
                      '${group.memberCount} members · ${group.deckCount} decks',
                      style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'edit') onEdit();
                  if (v == 'leave') onLeave();
                  if (v == 'delete') onDelete();
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit group')),
                  if (group.isOwner)
                    const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete group', style: TextStyle(color: Colors.red)))
                  else
                    const PopupMenuItem(
                        value: 'leave',
                        child: Text('Leave group', style: TextStyle(color: AppColors.bubblegum))),
                ],
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.more_horiz_rounded, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Member avatars row
          SizedBox(
            height: 64,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: group.members.length + 1,
              itemBuilder: (context, i) {
                if (i < group.members.length) {
                  final m = group.members[i];
                  return _MemberAvatarColumn(member: m);
                }
                return _InviteAvatarColumn(onTap: onInvite);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberAvatarColumn extends StatelessWidget {
  const _MemberAvatarColumn({required this.member});
  final GroupMember member;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(member.initials,
                style: const TextStyle(
                    color: AppColors.bubblegum,
                    fontSize: 14,
                    fontWeight: FontWeight.w800)),
          ),
          const SizedBox(height: 4),
          Text(
            member.name.split(' ').first,
            style: TextStyle(
                color: Colors.white.withOpacity(0.9), fontSize: 10, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _InviteAvatarColumn extends StatelessWidget {
  const _InviteAvatarColumn({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.6), width: 2),
            ),
            alignment: Alignment.center,
            child: Icon(Icons.add_rounded, color: Colors.white.withOpacity(0.8), size: 20),
          ),
          const SizedBox(height: 4),
          Text('Invite',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.9), fontSize: 10, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ── Group progress card ───────────────────────────────────────────────────

class _GroupProgressCard extends StatelessWidget {
  const _GroupProgressCard({required this.members});
  final List<GroupMember> members;

  static const _barColors = [
    AppColors.periwinkle,
    AppColors.bubblegum,
    AppColors.orange,
    AppColors.forestGreen,
    AppColors.sunnyYellow,
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.cardBorderRadius,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Group progress',
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(height: 14),
          if (members.isEmpty)
            const Text('No members yet', style: TextStyle(color: AppColors.ash))
          else
            ...members.asMap().entries.map((e) {
              final color = _barColors[e.key % _barColors.length];
              final m = e.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                      alignment: Alignment.center,
                      child: Text(m.initials.isNotEmpty ? m.initials[0] : '?',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 80,
                      child: Text(m.name.split(' ').first,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: AppRadius.pill,
                        child: LinearProgressIndicator(
                          value: m.progress.clamp(0.0, 1.0),
                          backgroundColor: AppColors.border,
                          valueColor: AlwaysStoppedAnimation(color),
                          minHeight: 6,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('${(m.progress * 100).round()}%',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700, color: color)),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

// ── Shared decks section ──────────────────────────────────────────────────

class _SharedDecksSection extends StatelessWidget {
  const _SharedDecksSection({required this.decks});
  final List<dynamic> decks;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('SHARED DECKS',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.fog,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2)),
        const SizedBox(height: 10),
        if (decks.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text('No shared decks yet', style: TextStyle(color: AppColors.ash)),
            ),
          )
        else
          ...decks.map((deck) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _DeckRow(deck: deck),
              )),
      ],
    );
  }
}

class _DeckRow extends StatelessWidget {
  const _DeckRow({required this.deck});
  final dynamic deck;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.cardBorderRadius,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.periwinkle.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: const Text('📖', style: TextStyle(fontSize: 16)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(deck.name,
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(fontWeight: FontWeight.w700, fontSize: 14)),
                Text('${deck.cardCount} cards',
                    style: const TextStyle(color: AppColors.ash, fontSize: 12)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FlashcardStudyScreen(deckId: deck.id as String, deckName: deck.name as String),
              ),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: const BoxDecoration(
                color: AppColors.periwinkle,
                borderRadius: AppRadius.pill,
              ),
              child: const Text('Study',
                  style: TextStyle(
                      color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Edit group sheet ──────────────────────────────────────────────────────

class _EditGroupSheet extends StatefulWidget {
  const _EditGroupSheet({required this.group, required this.onSaved});
  final GroupDetail group;
  final void Function(GroupDetail) onSaved;

  @override
  State<_EditGroupSheet> createState() => _EditGroupSheetState();
}

class _EditGroupSheetState extends State<_EditGroupSheet> {
  late final TextEditingController _nameCtrl;
  late String _emoji;
  bool _saving = false;

  static const _emojis = ['🇰🇷', '📚', '✏️', '🎯', '💬'];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.group.name);
    _emoji = widget.group.emoji;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() => _saving = true);
    try {
      await GroupService.instance.updateGroup(widget.group.id, name: name, emoji: _emoji);
      if (mounted) widget.onSaved(widget.group);
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        showAppToast(context, variant: ToastVariant.error, title: 'Failed to update group');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Edit group',
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 18),
          AppInput(controller: _nameCtrl, hint: 'Group name'),
          const SizedBox(height: 18),
          Text('Emoji',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.ash, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
            children: _emojis.map((e) {
              final selected = _emoji == e;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _emoji = e),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.bubblegum.withOpacity(0.2)
                          : const Color(0xFFF0EDE8),
                      borderRadius: BorderRadius.circular(12),
                      border: selected
                          ? Border.all(color: AppColors.bubblegum, width: 2)
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(e, style: const TextStyle(fontSize: 20)),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.border),
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Cancel',
                    style: TextStyle(color: AppColors.ash, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.orange,
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                ),
                child: _saving
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Save', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

// ── Invite to group sheet ─────────────────────────────────────────────────

class _InviteToGroupSheet extends StatefulWidget {
  const _InviteToGroupSheet({required this.groupId, required this.groupName});
  final String groupId;
  final String groupName;

  @override
  State<_InviteToGroupSheet> createState() => _InviteToGroupSheetState();
}

class _InviteToGroupSheetState extends State<_InviteToGroupSheet> {
  int _tab = 0;
  // Search tab
  final _searchCtrl = TextEditingController();
  List<_UserResult> _results = [];
  bool _searching = false;
  // Email tab
  final _emailCtrl = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _search(String q) async {
    if (q.trim().length < 2) {
      setState(() => _results = []);
      return;
    }
    setState(() => _searching = true);
    try {
      final data = await ApiService.instance.get(
          '/users/search?q=${Uri.encodeQueryComponent(q.trim())}');
      if (!mounted) return;
      final users = (data as List)
          .map((e) => _UserResult.fromJson(e as Map<String, dynamic>))
          .toList();
      setState(() { _results = users; _searching = false; });
    } catch (_) {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _inviteUser(_UserResult user) async {
    try {
      await InviteService.instance.sendInvite(widget.groupId, userId: user.id);
      if (!mounted) return;
      showAppToast(context, variant: ToastVariant.success,
          title: '${user.name} invited!',
          subtitle: 'They\'ll see the invite in their Groups tab');
      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      showAppToast(context, variant: ToastVariant.error, title: 'Failed to send invite');
    }
  }

  Future<void> _inviteByEmail() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) return;
    setState(() => _sending = true);
    try {
      await InviteService.instance.sendInvite(widget.groupId, email: email);
      if (!mounted) return;
      showAppToast(context, variant: ToastVariant.success,
          title: 'Invite sent!',
          subtitle: '$email will receive an invite to ${widget.groupName}');
      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      setState(() => _sending = false);
      showAppToast(context, variant: ToastVariant.error, title: 'Failed to send invite');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Invite to ${widget.groupName}',
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 14),
          // Tab toggle
          Row(
            children: ['Search users', 'By email'].asMap().entries.map((e) {
              final active = _tab == e.key;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _tab = e.key),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: active ? AppColors.bubblegum : Colors.white,
                      borderRadius: AppRadius.pill,
                      border: Border.all(
                          color: active ? AppColors.bubblegum : AppColors.border),
                    ),
                    child: Text(e.value,
                        style: TextStyle(
                            color: active ? Colors.white : AppColors.ash,
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          if (_tab == 0) ...[
            AppInput(
              controller: _searchCtrl,
              hint: 'Search by name...',
              onChanged: _search,
              autofocus: true,
            ),
            const SizedBox(height: 8),
            if (_searching)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator(color: AppColors.bubblegum)),
              )
            else if (_results.isEmpty && _searchCtrl.text.trim().length >= 2)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                    child: Text('No users found',
                        style: TextStyle(color: AppColors.ash))),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 260),
                child: ListView(
                  shrinkWrap: true,
                  children: _results.map((u) => ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    leading: CircleAvatar(
                      backgroundColor: AppColors.bubblegum,
                      child: Text(u.initials,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700)),
                    ),
                    title: Text(u.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 14)),
                    subtitle: Text(u.role,
                        style: const TextStyle(
                            color: AppColors.ash, fontSize: 12)),
                    trailing: GestureDetector(
                      onTap: () => _inviteUser(u),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 7),
                        decoration: const BoxDecoration(
                          color: AppColors.bubblegum,
                          borderRadius: AppRadius.pill,
                        ),
                        child: const Text('Invite',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700)),
                      ),
                    ),
                  )).toList(),
                ),
              ),
          ] else ...[
            AppInput(
              controller: _emailCtrl,
              hint: 'friend@example.com',
              keyboardType: TextInputType.emailAddress,
              autofocus: true,
            ),
            const SizedBox(height: 6),
            const Text("For people not yet on Ppyong — they'll get an email link",
                style: TextStyle(color: AppColors.ash, fontSize: 12)),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _sending ? null : _inviteByEmail,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.orange,
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                ),
                child: _sending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Send invite',
                        style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _UserResult {
  const _UserResult(
      {required this.id,
      required this.name,
      required this.initials,
      required this.role});
  final String id;
  final String name;
  final String initials;
  final String role;

  factory _UserResult.fromJson(Map<String, dynamic> j) => _UserResult(
        id: j['id'] as String,
        name: j['name'] as String,
        initials: j['initials'] as String,
        role: j['role'] as String,
      );
}

// ── Error body ────────────────────────────────────────────────────────────

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Text('😕', style: TextStyle(fontSize: 48)),
        const SizedBox(height: 16),
        const Text('Could not load group',
            style: TextStyle(color: AppColors.ash, fontSize: 16)),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: onRetry,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: const BoxDecoration(
                color: AppColors.bubblegum, borderRadius: AppRadius.pill),
            child: const Text('Try again',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ),
      ]),
    );
  }
}
