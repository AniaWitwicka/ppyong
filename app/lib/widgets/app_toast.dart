import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ── Public API ─────────────────────────────────────────────────────────────

enum ToastVariant { success, error, info, warning }

/// Show a toast that slides in from the top, auto-dismisses after 3.5s,
/// and can be tapped to dismiss early.
///
/// Example:
///   showAppToast(context, variant: ToastVariant.success, title: 'Card saved');
void showAppToast(
  BuildContext context, {
  required ToastVariant variant,
  required String title,
  String? subtitle,
}) {
  final topPadding = MediaQuery.of(context).padding.top;
  final overlay = Overlay.of(context);
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _AppToastEntry(
      variant: variant,
      title: title,
      subtitle: subtitle,
      topPadding: topPadding,
      onDismiss: () {
        if (entry.mounted) entry.remove();
      },
    ),
  );
  overlay.insert(entry);
}

// ── Styling ────────────────────────────────────────────────────────────────

class _ToastStyle {
  const _ToastStyle({
    required this.bg,
    required this.iconBg,
    required this.icon,
    required this.titleColor,
    required this.subtitleColor,
  });
  final Color bg;
  final Color iconBg;
  final IconData icon;
  final Color titleColor;
  final Color subtitleColor;
}

_ToastStyle _styleFor(ToastVariant variant) => switch (variant) {
      ToastVariant.success => const _ToastStyle(
          bg: AppColors.forestGreen,
          iconBg: Color(0x33FFFFFF),
          icon: Icons.check_rounded,
          titleColor: Colors.white,
          subtitleColor: Color(0xFFA8D9C0),
        ),
      ToastVariant.error => const _ToastStyle(
          bg: AppColors.ink,
          iconBg: AppColors.bubblegum,
          icon: Icons.priority_high_rounded,
          titleColor: Colors.white,
          subtitleColor: AppColors.fog,
        ),
      ToastVariant.info => const _ToastStyle(
          bg: AppColors.periwinkle,
          iconBg: Color(0x40FFFFFF),
          icon: Icons.info_outline_rounded,
          titleColor: AppColors.ink,
          subtitleColor: Color(0xFF1A3A7A),
        ),
      ToastVariant.warning => const _ToastStyle(
          bg: AppColors.sunnyYellow,
          iconBg: Color(0x4DFFFFFF),
          icon: Icons.warning_amber_rounded,
          titleColor: AppColors.ink,
          subtitleColor: Color(0xFF7A5500),
        ),
    };

// ── Overlay entry widget ───────────────────────────────────────────────────

class _AppToastEntry extends StatefulWidget {
  const _AppToastEntry({
    required this.variant,
    required this.title,
    required this.subtitle,
    required this.topPadding,
    required this.onDismiss,
  });

  final ToastVariant variant;
  final String title;
  final String? subtitle;
  final double topPadding;
  final VoidCallback onDismiss;

  @override
  State<_AppToastEntry> createState() => _AppToastEntryState();
}

class _AppToastEntryState extends State<_AppToastEntry>
    with TickerProviderStateMixin {
  late final AnimationController _inCtrl;
  late final AnimationController _outCtrl;
  late final Animation<double> _slideIn;
  late final Animation<double> _opacityIn;
  late final Animation<double> _slideOut;
  late final Animation<double> _opacityOut;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _inCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 250));
    _outCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));

    _slideIn = Tween<double>(begin: -28.0, end: 0.0)
        .animate(CurvedAnimation(parent: _inCtrl, curve: Curves.easeOut));
    _opacityIn =
        Tween<double>(begin: 0.0, end: 1.0).animate(_inCtrl);

    _slideOut = Tween<double>(begin: 0.0, end: -8.0)
        .animate(CurvedAnimation(parent: _outCtrl, curve: Curves.easeIn));
    _opacityOut =
        Tween<double>(begin: 1.0, end: 0.0).animate(_outCtrl);

    _inCtrl.forward();
    _timer = Timer(const Duration(milliseconds: 3500), _dismiss);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _inCtrl.dispose();
    _outCtrl.dispose();
    super.dispose();
  }

  void _dismiss() {
    if (!mounted) return;
    _timer?.cancel();
    _outCtrl.forward().then((_) => widget.onDismiss());
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: widget.topPadding + 16,
      left: 16,
      right: 16,
      child: AnimatedBuilder(
        animation: Listenable.merge([_inCtrl, _outCtrl]),
        builder: (_, child) => Transform.translate(
          offset: Offset(0, _slideIn.value + _slideOut.value),
          child: Opacity(
            opacity: (_opacityIn.value * _opacityOut.value).clamp(0.0, 1.0),
            child: child,
          ),
        ),
        child: GestureDetector(
          onTap: _dismiss,
          child: _ToastCard(
            variant: widget.variant,
            title: widget.title,
            subtitle: widget.subtitle,
          ),
        ),
      ),
    );
  }
}

// ── Visual card ────────────────────────────────────────────────────────────

class _ToastCard extends StatelessWidget {
  const _ToastCard({
    required this.variant,
    required this.title,
    required this.subtitle,
  });

  final ToastVariant variant;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final style = _styleFor(variant);
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: style.bg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: style.bg.withOpacity(0.35),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: style.iconBg,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(style.icon, color: style.titleColor, size: 16),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: style.titleColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: TextStyle(
                        color: style.subtitleColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '×',
              style: TextStyle(
                color: style.titleColor.withOpacity(0.5),
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
