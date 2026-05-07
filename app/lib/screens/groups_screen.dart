import 'package:flutter/material.dart';
import '../models/friend.dart';
import '../models/group.dart';
import '../models/invite.dart';
import '../models/user.dart';
import '../services/friend_service.dart';
import '../services/group_service.dart';
import '../services/invite_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_bottom_sheet.dart';
import '../widgets/app_input.dart';
import '../widgets/app_toast.dart';
import 'group_detail_screen.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  int _segment = 0;
  int _pendingCount = 0;

  @override
  void initState() {
    super.initState();
    _loadPendingCount();
  }

  Future<void> _loadPendingCount() async {
    try {
      final count = await InviteService.instance.pendingCount();
      if (mounted) setState(() => _pendingCount = count);
    } catch (_) {}
  }

  void _onSegmentChange(int i) {
    setState(() => _segment = i);
    if (i == 2) _loadPendingCount();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _GroupsHeader(
              segment: _segment,
              pendingCount: _pendingCount,
              onSegmentChange: _onSegmentChange,
            ),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
      floatingActionButton: _segment == 0
          ? FloatingActionButton(
              backgroundColor: AppColors.orange,
              onPressed: _showCreateGroupSheet,
              child: const Icon(Icons.add_rounded, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildBody() {
    switch (_segment) {
      case 0:
        return _MyGroupsView(onGroupCreated: _onGroupCreated);
      case 1:
        return const _FriendsView();
      case 2:
        return _InvitesView(onInviteActioned: _loadPendingCount);
      default:
        return const SizedBox.shrink();
    }
  }

  void _onGroupCreated() {
    // Trigger rebuild so _MyGroupsView reloads
    setState(() {});
  }

  Future<void> _showCreateGroupSheet() async {
    final created = await showAppBottomSheet<bool>(
      context: context,
      child: _CreateGroupSheet(onCreated: (g) {
        Navigator.pop(context, true);
        setState(() {});
      }),
    );
    if (created == true) setState(() {});
  }
}

// ── Header ────────────────────────────────────────────────────────────────

class _GroupsHeader extends StatelessWidget {
  const _GroupsHeader({
    required this.segment,
    required this.pendingCount,
    required this.onSegmentChange,
  });

  final int segment;
  final int pendingCount;
  final ValueChanged<int> onSegmentChange;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bubblegum,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Groups',
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white)),
          const SizedBox(height: 12),
          _SegmentedControl(
            segment: segment,
            pendingCount: pendingCount,
            onChanged: onSegmentChange,
          ),
        ],
      ),
    );
  }
}

class _SegmentedControl extends StatelessWidget {
  const _SegmentedControl({
    required this.segment,
    required this.pendingCount,
    required this.onChanged,
  });

  final int segment;
  final int pendingCount;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final labels = ['My groups', 'Friends', 'Invites'];
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.bubblegum.withOpacity(0.4),
        borderRadius: AppRadius.pill,
      ),
      child: Row(
        children: List.generate(labels.length, (i) {
          final active = segment == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: active ? Colors.white : Colors.transparent,
                  borderRadius: AppRadius.pill,
                  boxShadow: active
                      ? [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 4, offset: const Offset(0, 1))]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      labels[i],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: active ? AppColors.ink : Colors.white.withOpacity(0.8),
                        fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                    if (i == 2 && pendingCount > 0) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.orange,
                          borderRadius: AppRadius.pill,
                        ),
                        child: Text(
                          '$pendingCount',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ── My Groups view ────────────────────────────────────────────────────────

class _MyGroupsView extends StatefulWidget {
  const _MyGroupsView({required this.onGroupCreated});
  final VoidCallback onGroupCreated;

  @override
  State<_MyGroupsView> createState() => _MyGroupsViewState();
}

class _MyGroupsViewState extends State<_MyGroupsView> {
  List<GroupSummary> _groups = [];
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
      final groups = await GroupService.instance.listGroups();
      if (mounted) setState(() { _groups = groups; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _loading = false; _hasError = true; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppColors.bubblegum));
    if (_hasError) return _ErrorRetry(onRetry: _load);

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: _groups.length + 1,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        if (i < _groups.length) {
          return _GroupCard(
            group: _groups[i],
            onTap: () async {
              await Navigator.push(context,
                  MaterialPageRoute(builder: (_) => GroupDetailScreen(groupId: _groups[i].id)));
              _load();
            },
          );
        }
        return _CreateGroupCard(onTap: () async {
          final created = await showAppBottomSheet<bool>(
            context: context,
            child: _CreateGroupSheet(onCreated: (g) {
              Navigator.pop(context, true);
            }),
          );
          if (created == true) _load();
        });
      },
    );
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({required this.group, required this.onTap});
  final GroupSummary group;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = _parseColor(group.color);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppRadius.cardBorderRadius,
          border: Border.all(color: color, width: 2),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Text(group.emoji, style: const TextStyle(fontSize: 22)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(group.name,
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(fontWeight: FontWeight.w800, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(
                    '${group.memberCount} members · ${group.deckCount} decks',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: AppColors.ash, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _AvatarStack(avatars: group.avatars),
          ],
        ),
      ),
    );
  }
}

class _AvatarStack extends StatelessWidget {
  const _AvatarStack({required this.avatars});
  final List<MemberAvatar> avatars;

  @override
  Widget build(BuildContext context) {
    if (avatars.isEmpty) return const SizedBox.shrink();
    const size = 28.0;
    const overlap = 8.0;
    final count = avatars.length.clamp(0, 4);
    final width = size + (count - 1) * (size - overlap);
    return SizedBox(
      width: width,
      height: size,
      child: Stack(
        children: List.generate(count, (i) {
          final av = avatars[i];
          return Positioned(
            left: i * (size - overlap),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: _parseColor(av.color),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              alignment: Alignment.center,
              child: Text(av.initials,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
            ),
          );
        }),
      ),
    );
  }
}

class _CreateGroupCard extends StatelessWidget {
  const _CreateGroupCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF0F6),
          borderRadius: AppRadius.cardBorderRadius,
          border: Border.all(
            color: AppColors.bubblegum,
            width: 1.5,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.bubblegum.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.add_rounded, color: AppColors.bubblegum, size: 22),
            ),
            const SizedBox(width: 14),
            Text('Create a new group',
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(color: AppColors.bubblegum, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

// ── Friends view ──────────────────────────────────────────────────────────

class _FriendsView extends StatefulWidget {
  const _FriendsView();

  @override
  State<_FriendsView> createState() => _FriendsViewState();
}

class _FriendsViewState extends State<_FriendsView> {
  List<Friend> _friends = [];
  List<Friend> _requests = [];
  bool _loading = true;
  bool _hasError = false;
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(() => setState(() => _query = _searchCtrl.text.toLowerCase()));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _hasError = false; });
    try {
      final results = await Future.wait([
        FriendService.instance.listFriends(),
        FriendService.instance.listPendingRequests(),
      ]);
      if (mounted) {
        setState(() {
          _friends = results[0];
          _requests = results[1];
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() { _loading = false; _hasError = true; });
    }
  }

  Future<void> _accept(Friend request) async {
    try {
      await FriendService.instance.acceptFriendRequest(request.friendshipId);
      if (mounted) {
        showAppToast(context, variant: ToastVariant.success,
            title: 'You and ${request.name} are now friends!');
        _load();
      }
    } catch (_) {
      if (mounted) showAppToast(context, variant: ToastVariant.error, title: 'Failed to accept request');
    }
  }

  Future<void> _decline(Friend request) async {
    try {
      await FriendService.instance.declineFriendRequest(request.friendshipId);
      if (mounted) _load();
    } catch (_) {
      if (mounted) showAppToast(context, variant: ToastVariant.error, title: 'Failed to decline request');
    }
  }

  List<Friend> get _filtered => _query.isEmpty
      ? _friends
      : _friends.where((f) => f.name.toLowerCase().contains(_query)).toList();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: TextField(
            controller: _searchCtrl,
            style: const TextStyle(fontSize: 14, color: AppColors.ink),
            decoration: InputDecoration(
              hintText: 'Search friends...',
              hintStyle: const TextStyle(color: AppColors.fog, fontSize: 14),
              prefixIcon: const Icon(Icons.search_rounded, color: AppColors.fog, size: 20),
              filled: true,
              fillColor: const Color(0xFFF0EDE8),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        Expanded(child: _buildList()),
      ],
    );
  }

  Widget _buildList() {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppColors.bubblegum));
    if (_hasError) return _ErrorRetry(onRetry: _load);

    final friends = _filtered;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
      children: [
        if (_requests.isNotEmpty) ...[
          const _SectionLabel('FRIEND REQUESTS'),
          const SizedBox(height: 8),
          ..._requests.map((req) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _FriendRequestRow(
              request: req,
              onAccept: () => _accept(req),
              onDecline: () => _decline(req),
            ),
          )),
          const SizedBox(height: 8),
        ],
        if (friends.isNotEmpty) ...[
          if (_requests.isNotEmpty) const _SectionLabel('FRIENDS'),
          if (_requests.isNotEmpty) const SizedBox(height: 8),
          ...friends.map((f) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _FriendRow(friend: f),
          )),
          const SizedBox(height: 4),
        ],
        _AddFriendRow(onTap: () async {
          await showAppBottomSheet(
            context: context,
            child: const _AddFriendSheet(),
          );
          _load();
        }),
      ],
    );
  }
}

class _FriendRequestRow extends StatelessWidget {
  const _FriendRequestRow({required this.request, required this.onAccept, required this.onDecline});
  final Friend request;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FBF5),
        borderRadius: AppRadius.cardBorderRadius,
        border: Border.all(color: AppColors.forestGreen, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(color: AppColors.forestGreen, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(request.initials,
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(request.name,
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(fontWeight: FontWeight.w700, fontSize: 14)),
          ),
          _InviteButton(label: 'Accept', color: AppColors.forestGreen, onTap: onAccept),
          const SizedBox(width: 8),
          _InviteButton(label: 'Decline', color: AppColors.ash, outlined: true, onTap: onDecline),
        ],
      ),
    );
  }
}

class _FriendRow extends StatelessWidget {
  const _FriendRow({required this.friend});
  final Friend friend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.cardBorderRadius,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
                color: AppColors.periwinkle, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(friend.initials,
                style: const TextStyle(
                    color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(friend.name,
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(fontWeight: FontWeight.w700, fontSize: 14)),
                if (friend.role == 'teacher')
                  const Text('Teacher',
                      style: TextStyle(color: Color(0xFF7A5500), fontSize: 11, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          _FriendStatBadge(friend: friend),
        ],
      ),
    );
  }
}

class _FriendStatBadge extends StatelessWidget {
  const _FriendStatBadge({required this.friend});
  final Friend friend;

  @override
  Widget build(BuildContext context) {
    if (friend.role == 'teacher') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.sunnyYellow.withOpacity(0.2),
          borderRadius: AppRadius.pill,
        ),
        child: const Text('Teacher',
            style: TextStyle(
                color: Color(0xFF7A5500), fontSize: 11, fontWeight: FontWeight.w700)),
      );
    }
    if (friend.dueCount > 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.bubblegum.withOpacity(0.15),
          borderRadius: AppRadius.pill,
        ),
        child: Text('${friend.dueCount} due',
            style: const TextStyle(
                color: AppColors.bubblegum, fontSize: 11, fontWeight: FontWeight.w700)),
      );
    }
    if (friend.streak > 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.forestGreen.withOpacity(0.1),
          borderRadius: AppRadius.pill,
        ),
        child: Text('${friend.streak}d 🔥',
            style: const TextStyle(
                color: AppColors.forestGreen, fontSize: 11, fontWeight: FontWeight.w700)),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.periwinkle.withOpacity(0.15),
        borderRadius: AppRadius.pill,
      ),
      child: Text('${friend.wordCount} words',
          style: const TextStyle(
              color: AppColors.periwinkle, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}

class _AddFriendRow extends StatelessWidget {
  const _AddFriendRow({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.orange.withOpacity(0.06),
          borderRadius: AppRadius.cardBorderRadius,
          border: Border.all(color: AppColors.orange, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.orange.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.person_add_alt_1_rounded,
                  color: AppColors.orange, size: 18),
            ),
            const SizedBox(width: 12),
            Text('Add a friend',
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(color: AppColors.orange, fontWeight: FontWeight.w700, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

// ── Invites view ──────────────────────────────────────────────────────────

class _InvitesView extends StatefulWidget {
  const _InvitesView({required this.onInviteActioned});
  final VoidCallback onInviteActioned;

  @override
  State<_InvitesView> createState() => _InvitesViewState();
}

class _InvitesViewState extends State<_InvitesView> {
  InviteList? _invites;
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
      final invites = await InviteService.instance.listInvites();
      if (mounted) setState(() { _invites = invites; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _loading = false; _hasError = true; });
    }
  }

  Future<void> _accept(Invite invite) async {
    try {
      await InviteService.instance.acceptInvite(invite.id);
      if (mounted) {
        showAppToast(context, variant: ToastVariant.success,
            title: 'Joined ${invite.groupName}!');
        _load();
        widget.onInviteActioned();
      }
    } catch (_) {
      if (mounted) showAppToast(context, variant: ToastVariant.error, title: 'Failed to accept invite');
    }
  }

  Future<void> _decline(Invite invite) async {
    try {
      await InviteService.instance.declineInvite(invite.id);
      if (mounted) { _load(); widget.onInviteActioned(); }
    } catch (_) {
      if (mounted) showAppToast(context, variant: ToastVariant.error, title: 'Failed to decline invite');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppColors.bubblegum));
    if (_hasError) return _ErrorRetry(onRetry: _load);

    final incoming = _invites!.incoming;
    final sent = _invites!.sent;
    final hasAny = incoming.isNotEmpty || sent.isNotEmpty;

    if (!hasAny) {
      return const Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('📬', style: TextStyle(fontSize: 48)),
          SizedBox(height: 16),
          Text('No invites', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.ink)),
          SizedBox(height: 6),
          Text('Group invites will show up here', style: TextStyle(color: AppColors.ash, fontSize: 14)),
        ]),
      );
    }

    return RefreshIndicator(
      color: AppColors.bubblegum,
      onRefresh: _load,
      child: ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        if (incoming.isNotEmpty) ...[
          _SectionLabel('INCOMING'),
          const SizedBox(height: 8),
          ...incoming.map((inv) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _IncomingInviteRow(
              invite: inv,
              onAccept: () => _accept(inv),
              onDecline: () => _decline(inv),
            ),
          )),
          const SizedBox(height: 8),
        ],
        if (sent.isNotEmpty) ...[
          _SectionLabel('SENT'),
          const SizedBox(height: 8),
          ...sent.map((inv) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _SentInviteRow(invite: inv),
          )),
          const SizedBox(height: 12),
        ],
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.periwinkle.withOpacity(0.12),
            borderRadius: AppRadius.cardBorderRadius,
          ),
          child: Row(children: [
            const Icon(Icons.info_outline_rounded, color: AppColors.periwinkle, size: 16),
            const SizedBox(width: 8),
            Text('Invites expire after 7 days',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF1A3A7A), fontSize: 12, fontWeight: FontWeight.w600)),
          ]),
        ),
      ],
    ),
    );
  }
}

class _IncomingInviteRow extends StatelessWidget {
  const _IncomingInviteRow({
    required this.invite,
    required this.onAccept,
    required this.onDecline,
  });
  final Invite invite;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FBF5),
        borderRadius: AppRadius.cardBorderRadius,
        border: Border.all(color: AppColors.forestGreen, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
                color: AppColors.forestGreen, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(invite.groupEmoji, style: const TextStyle(fontSize: 16)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(TextSpan(children: [
                  TextSpan(
                      text: invite.inviterName,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.ink)),
                  const TextSpan(
                      text: ' invited you to ',
                      style: TextStyle(fontSize: 13, color: AppColors.ash)),
                  TextSpan(
                      text: invite.groupName,
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: _parseColor(invite.groupColor))),
                ])),
                const SizedBox(height: 8),
                Row(children: [
                  _InviteButton(
                    label: 'Accept',
                    color: AppColors.forestGreen,
                    onTap: onAccept,
                  ),
                  const SizedBox(width: 8),
                  _InviteButton(
                    label: 'Decline',
                    color: AppColors.ash,
                    outlined: true,
                    onTap: onDecline,
                  ),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InviteButton extends StatelessWidget {
  const _InviteButton({
    required this.label,
    required this.color,
    required this.onTap,
    this.outlined = false,
  });
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: outlined ? Colors.transparent : color,
          borderRadius: AppRadius.pill,
          border: outlined ? Border.all(color: color) : null,
        ),
        child: Text(label,
            style: TextStyle(
                color: outlined ? color : Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _SentInviteRow extends StatelessWidget {
  const _SentInviteRow({required this.invite});
  final Invite invite;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.7,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppRadius.cardBorderRadius,
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.fog.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.person_rounded, color: AppColors.fog, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(invite.inviteeEmail,
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(fontWeight: FontWeight.w700, fontSize: 13)),
                  Text('Invited to ${invite.groupName}',
                      style: const TextStyle(color: AppColors.ash, fontSize: 12)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.sunnyYellow.withOpacity(0.2),
                borderRadius: AppRadius.pill,
              ),
              child: const Text('Pending',
                  style: TextStyle(
                      color: Color(0xFF7A5500), fontSize: 11, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Create group sheet ────────────────────────────────────────────────────

class _CreateGroupSheet extends StatefulWidget {
  const _CreateGroupSheet({required this.onCreated});
  final void Function(GroupSummary) onCreated;

  @override
  State<_CreateGroupSheet> createState() => _CreateGroupSheetState();
}

class _CreateGroupSheetState extends State<_CreateGroupSheet> {
  final _nameCtrl = TextEditingController();
  String _emoji = '🇰🇷';
  String _color = '#F296BD';
  bool _saving = false;

  static const _emojis = ['🇰🇷', '📚', '✏️', '🎯', '💬'];
  static const _colors = ['#99B7F5', '#267F53', '#F5793B', '#F296BD', '#FCCA59'];

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
      final group = await GroupService.instance.createGroup(
          name: name, emoji: _emoji, color: _color);
      widget.onCreated(group);
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        showAppToast(context, variant: ToastVariant.error, title: 'Failed to create group');
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
          Text('New group',
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 18),
          AppInput(controller: _nameCtrl, hint: 'Group name', autofocus: true),
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
                          ? _parseColor(_color).withOpacity(0.2)
                          : const Color(0xFFF0EDE8),
                      borderRadius: BorderRadius.circular(12),
                      border: selected
                          ? Border.all(color: _parseColor(_color), width: 2)
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(e, style: const TextStyle(fontSize: 20)),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 18),
          Text('Color',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.ash, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
            children: _colors.map((c) {
              final selected = _color == c;
              final col = _parseColor(c);
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _color = c),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: col,
                      shape: BoxShape.circle,
                      border: selected
                          ? Border.all(color: AppColors.ink, width: 2.5)
                          : Border.all(color: Colors.transparent, width: 2.5),
                    ),
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
                    : const Text('Create group',
                        style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

// ── Add friend sheet ──────────────────────────────────────────────────────

class _AddFriendSheet extends StatefulWidget {
  const _AddFriendSheet();

  @override
  State<_AddFriendSheet> createState() => _AddFriendSheetState();
}

class _AddFriendSheetState extends State<_AddFriendSheet> {
  int _tab = 0;
  final _searchCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  List<UserSummary> _results = [];
  List<GroupSummary> _groups = [];
  GroupSummary? _selectedGroup;
  bool _searching = false;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadGroups() async {
    try {
      final groups = await GroupService.instance.listGroups();
      if (mounted) setState(() {
        _groups = groups;
        if (groups.isNotEmpty) { _selectedGroup = groups.first; }
      });
    } catch (_) {}
  }

  Future<void> _search(String q) async {
    if (q.trim().length < 2) { setState(() => _results = []); return; }
    setState(() => _searching = true);
    try {
      final results = await FriendService.instance.searchUsers(q.trim());
      if (mounted) setState(() { _results = results; _searching = false; });
    } catch (_) {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _sendInviteByEmail() async {
    final email = _emailCtrl.text.trim();
    final group = _selectedGroup;
    if (email.isEmpty || group == null) return;
    setState(() => _sending = true);
    try {
      await InviteService.instance.sendInvite(group.id, email: email);
      if (!mounted) return;
      showAppToast(context, variant: ToastVariant.success,
          title: 'Invite sent!',
          subtitle: '$email was invited to ${group.name}');
      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      setState(() => _sending = false);
      showAppToast(context, variant: ToastVariant.error, title: 'Failed to send invite');
    }
  }

  Future<void> _sendRequest(UserSummary user) async {
    try {
      await FriendService.instance.sendFriendRequest(user.id);
      if (mounted) {
        showAppToast(context, variant: ToastVariant.success,
            title: 'Friend request sent to ${user.name}');
        Navigator.pop(context);
      }
    } catch (_) {
      if (mounted) showAppToast(context, variant: ToastVariant.error, title: 'Failed to send request');
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
          Text('Add a friend',
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          Row(
            children: ['Search name', 'Invite to group'].asMap().entries.map((e) {
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
              hint: 'Search by name or email...',
              onChanged: _search,
              autofocus: true,
            ),
            if (_searching)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator(color: AppColors.bubblegum)),
              )
            else if (_results.isEmpty && _searchCtrl.text.length >= 2)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text('No one found', style: TextStyle(color: AppColors.ash)),
                ),
              )
            else
              ..._results.map((u) => ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    leading: CircleAvatar(
                      backgroundColor: AppColors.periwinkle,
                      child: Text(u.initials,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                    ),
                    title: Text(u.name,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    subtitle: Text(u.role,
                        style: const TextStyle(color: AppColors.ash, fontSize: 12)),
                    trailing: GestureDetector(
                      onTap: () => _sendRequest(u),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.bubblegum,
                          borderRadius: AppRadius.pill,
                        ),
                        child: const Text('Add',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700)),
                      ),
                    ),
                  )),
          ] else ...[
            AppInput(
              controller: _emailCtrl,
              hint: 'friend@example.com',
              keyboardType: TextInputType.emailAddress,
              autofocus: true,
            ),
            if (_groups.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _selectedGroup != null ? AppColors.periwinkle : AppColors.border,
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  color: Colors.white,
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<GroupSummary>(
                    value: _selectedGroup,
                    isExpanded: true,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    borderRadius: BorderRadius.circular(14),
                    items: _groups.map((g) => DropdownMenuItem(
                      value: g,
                      child: Text('${g.emoji}  ${g.name}',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink)),
                    )).toList(),
                    onChanged: (g) => setState(() => _selectedGroup = g),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_sending || _selectedGroup == null) ? null : _sendInviteByEmail,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.orange,
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                ),
                child: const Text('Send invite',
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

// ── Shared helpers ────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.fog,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2));
  }
}

class _ErrorRetry extends StatelessWidget {
  const _ErrorRetry({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Text('😕', style: TextStyle(fontSize: 40)),
        const SizedBox(height: 12),
        const Text('Something went wrong', style: TextStyle(color: AppColors.ash)),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: onRetry,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
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

Color _parseColor(String hex) {
  final h = hex.replaceAll('#', '');
  return Color(int.parse('FF$h', radix: 16));
}

