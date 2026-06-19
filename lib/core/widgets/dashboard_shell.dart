import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/switch_role_helper.dart';

class FeatureCard {
  final IconData icon;
  final String label;
  final String? subtitle;
  final Widget Function() screenBuilder;
  final Color? color;
  final Widget? fab;
  // Set true when the screen already returns a full Scaffold with its own AppBar
  final bool hasOwnScaffold;

  FeatureCard({
    required this.icon,
    required this.label,
    required Widget screen,
    this.subtitle,
    this.color,
    this.fab,
    this.hasOwnScaffold = false,
  }) : screenBuilder = (() => screen);

  const FeatureCard.lazy({
    required this.icon,
    required this.label,
    required this.screenBuilder,
    this.subtitle,
    this.color,
    this.fab,
    this.hasOwnScaffold = false,
  });
}

class FeatureGroup {
  final String title;
  final List<FeatureCard> cards;
  const FeatureGroup({required this.title, required this.cards});
}

class DashboardShell extends StatefulWidget {
  final String title;
  final String employeeName;
  final String empId;
  final String role;
  final IconData roleIcon;
  final List<FeatureGroup> groups;
  final VoidCallback onLogout;

  const DashboardShell({
    super.key,
    required this.title,
    required this.employeeName,
    required this.empId,
    required this.role,
    required this.roleIcon,
    required this.groups,
    required this.onLogout,
  });

  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell> {
  bool _hasMultipleRoles = false;

  @override
  void initState() {
    super.initState();
    SwitchRoleHelper.hasMultipleRoles().then((v) {
      if (mounted) setState(() => _hasMultipleRoles = v);
    });
  }

  void _openFeature(FeatureCard card) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => _FeatureScreenWrapper(
        title: card.label,
        screen: card.screenBuilder(),
        fab: card.fab,
        hasOwnScaffold: card.hasOwnScaffold,
      ),
    )).then((_) { if (mounted) setState(() {}); });
  }

  @override
  Widget build(BuildContext context) {
    final initials = widget.employeeName.trim().split(' ')
        .take(2).map((w) => w.isNotEmpty ? w[0].toUpperCase() : '').join();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primary, AppTheme.primaryVariant, Color(0xFF062229)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 12, 28),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      const Spacer(),
                      if (_hasMultipleRoles)
                        _HeaderIconBtn(Icons.switch_account_outlined,
                            () => SwitchRoleHelper.showRolePicker(context)),
                      _HeaderIconBtn(Icons.logout_rounded, widget.onLogout),
                    ]),
                    const SizedBox(height: 4),
                    Row(children: [
                      Container(
                        width: 56, height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                        ),
                        child: Center(
                          child: Text(initials,
                              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(widget.employeeName,
                            style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800),
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 5),
                        Row(children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.secondary.withValues(alpha: 0.28),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppTheme.secondary.withValues(alpha: 0.5)),
                            ),
                            child: Text(widget.role,
                                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                          ),
                          const SizedBox(width: 8),
                          Text('ID: ${widget.empId}',
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 12)),
                        ]),
                      ])),
                    ]),
                  ]),
                ),
              ),
            ),
          ),
          ...widget.groups.expand((group) => [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                child: Row(children: [
                  Container(width: 3, height: 15,
                      decoration: BoxDecoration(color: AppTheme.secondary, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(width: 10),
                  Text(group.title.toUpperCase(),
                      style: AppTheme.bodySmall.copyWith(
                          fontWeight: FontWeight.w800, letterSpacing: 1.5, color: AppTheme.onSurfaceVariant)),
                ]),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 126,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: group.cards.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, i) => _FeatureTile(
                    card: group.cards[i],
                    onTap: () => _openFeature(group.cards[i]),
                  ),
                ),
              ),
            ),
          ]),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: Center(child: Text('Powered by GramTarang Technologies',
                  style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 11))),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _HeaderIconBtn(this.icon, this.onTap);

  @override
  Widget build(BuildContext context) => IconButton(
        icon: Icon(icon, color: Colors.white.withValues(alpha: 0.85), size: 22),
        onPressed: onTap,
      );
}

class _FeatureTile extends StatelessWidget {
  final FeatureCard card;
  final VoidCallback onTap;
  const _FeatureTile({required this.card, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = card.color ?? AppTheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withValues(alpha: 0.75)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
              child: Icon(card.icon, color: Colors.white, size: 20),
            ),
            const Spacer(),
            Text(card.label,
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700, height: 1.3),
                maxLines: 2, overflow: TextOverflow.ellipsis),
          ]),
        ),
      ),
    );
  }
}

class _FeatureScreenWrapper extends StatelessWidget {
  final String title;
  final Widget screen;
  final Widget? fab;
  final bool hasOwnScaffold;
  const _FeatureScreenWrapper({
    required this.title,
    required this.screen,
    this.fab,
    this.hasOwnScaffold = false,
  });

  @override
  Widget build(BuildContext context) {
    if (hasOwnScaffold) return screen;
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: screen,
      floatingActionButton: fab,
    );
  }
}
