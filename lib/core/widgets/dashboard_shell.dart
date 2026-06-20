import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../utils/switch_role_helper.dart';

class FeatureCard {
  final IconData icon;
  final String label;
  final String? subtitle;
  final Widget Function() screenBuilder;
  final Color? color;
  final Widget? fab;
  final bool hasOwnScaffold;

  FeatureCard({
    required this.icon, required this.label, required Widget screen,
    this.subtitle, this.color, this.fab, this.hasOwnScaffold = false,
  }) : screenBuilder = (() => screen);

  const FeatureCard.lazy({
    required this.icon, required this.label, required this.screenBuilder,
    this.subtitle, this.color, this.fab, this.hasOwnScaffold = false,
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
    required this.title, required this.employeeName, required this.empId,
    required this.role, required this.roleIcon, required this.groups, required this.onLogout,
  });

  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _hasMultipleRoles = false;

  @override
  void initState() {
    super.initState();
    SwitchRoleHelper.hasMultipleRoles().then((v) { if (mounted) setState(() => _hasMultipleRoles = v); });
  }

  void _openFeature(FeatureCard card) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => _FeatureScreenWrapper(
        title: card.label, screen: card.screenBuilder(),
        fab: card.fab, hasOwnScaffold: card.hasOwnScaffold,
      ),
    )).then((_) { if (mounted) setState(() {}); });
  }

  String get _initials => widget.employeeName.trim().split(' ')
      .take(2).map((w) => w.isNotEmpty ? w[0].toUpperCase() : '').join();

  @override
  Widget build(BuildContext context) {
    final ringColor = AppTheme.roleColor(widget.role);
    final topPad = MediaQuery.of(context).padding.top;
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good Morning' : hour < 17 ? 'Good Afternoon' : 'Good Evening';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppTheme.background,
      drawer: _buildDrawer(ringColor, greeting),
      body: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ── Hero header (bleeds to top edge) ──
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(16, topPad + 12, 16, 24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primary, AppTheme.primaryVariant],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              boxShadow: [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.35), blurRadius: 20, offset: const Offset(0, 8))],
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Top row: hamburger only
              GestureDetector(
                onTap: () => _scaffoldKey.currentState?.openDrawer(),
                child: Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.menu_rounded, color: Colors.white, size: 22),
                ),
              ),
              const SizedBox(height: 20),
              // Greeting + name
              Text(greeting, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Text(widget.employeeName,
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 10),
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                  ),
                  child: Text(widget.role,
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 8),
                Text('· ${widget.empId}',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
              ]),
            ]),
          ),

          // ── Quick access grid ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Quick Access',
                  style: AppTheme.titleSmall.copyWith(fontWeight: FontWeight.w800, color: AppTheme.onSurface)),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.4,
                children: widget.groups
                    .expand((g) => g.cards)
                    .take(4)
                    .map((card) => _QuickTile(card: card, onTap: () => _openFeature(card)))
                    .toList(),
              ),
            ]),
          ),
        ]),
      ),
    ));
  }

  Widget _groupLabel(String title) => Padding(
    padding: const EdgeInsets.only(top: 12, bottom: 4),
    child: Row(children: [
      Container(width: 3, height: 12,
          decoration: BoxDecoration(color: AppTheme.secondary, borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 7),
      Text(title.toUpperCase(),
          style: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w800, letterSpacing: 1.3, color: AppTheme.onSurfaceVariant)),
    ]),
  );

  Widget _buildDrawer(Color ringColor, String greeting) {
    final topPad = MediaQuery.of(context).padding.top;
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Drawer(
      backgroundColor: const Color(0xFFF7F8FA),
      child: Column(children: [
        // ── Header ──
        Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(16, topPad + 16, 16, 16),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.primary, AppTheme.primaryVariant],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
          ),
          child: Row(children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.15),
                border: Border.all(color: ringColor, width: 2.5),
              ),
              child: Center(child: Text(_initials,
                  style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w900))),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.employeeName,
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800),
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 5),
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: ringColor.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: ringColor.withValues(alpha: 0.7)),
                  ),
                  child: Text(widget.role,
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.4)),
                ),
                const SizedBox(width: 8),
                Text('# ${widget.empId}',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 11)),
              ]),
            ])),
          ]),
        ),

        // ── Feature list ──
        Expanded(
          child: ListView(
            padding: EdgeInsets.fromLTRB(10, 8, 10, bottomPad + 12),
            children: [
              ...widget.groups.expand((group) => [
                Padding(
                  padding: const EdgeInsets.fromLTRB(6, 14, 6, 4),
                  child: Row(children: [
                    Container(width: 3, height: 10,
                        decoration: BoxDecoration(color: AppTheme.secondary, borderRadius: BorderRadius.circular(2))),
                    const SizedBox(width: 6),
                    Text(group.title.toUpperCase(),
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800,
                            letterSpacing: 1.3, color: AppTheme.onSurfaceVariant)),
                  ]),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: group.cards.asMap().entries.map((e) {
                      final isLast = e.key == group.cards.length - 1;
                      return _DrawerItem(card: e.value, isLast: isLast,
                          onTap: () { Navigator.pop(context); _openFeature(e.value); });
                    }).toList(),
                  ),
                ),
              ]),
              const SizedBox(height: 14),
              // Account actions card
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(children: [
                  if (_hasMultipleRoles) ...[
                    _DrawerSimpleItem(
                      icon: Icons.switch_account_outlined, label: 'Switch Role', color: AppTheme.info,
                      onTap: () { Navigator.pop(context); SwitchRoleHelper.showRolePicker(context); },
                      isLast: false,
                    ),
                  ],
                  _DrawerSimpleItem(
                    icon: Icons.logout_rounded, label: 'Logout', color: AppTheme.error,
                    onTap: () { Navigator.pop(context); widget.onLogout(); },
                    isLast: true,
                  ),
                ]),
              ),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _buildGroupHeader(String title) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
    child: Row(children: [
      Container(width: 3, height: 13,
          decoration: BoxDecoration(color: AppTheme.secondary, borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 8),
      Text(title.toUpperCase(),
          style: AppTheme.bodySmall.copyWith(
              fontWeight: FontWeight.w800, letterSpacing: 1.4, color: AppTheme.onSurfaceVariant)),
    ]),
  );
}

class _FeatureTile extends StatelessWidget {
  final FeatureCard card;
  final VoidCallback onTap;
  const _FeatureTile({required this.card, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = card.color ?? AppTheme.primary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Row(children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(card.icon, color: color, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(child: Text(card.label,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.onSurface))),
              Icon(Icons.chevron_right_rounded, color: Colors.grey.shade300, size: 22),
            ]),
          ),
        ),
      ),
    );
  }
}

class _QuickTile extends StatelessWidget {
  final FeatureCard card;
  final VoidCallback onTap;
  const _QuickTile({required this.card, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = card.color ?? AppTheme.primary;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 3))],
          ),
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
              child: Icon(card.icon, color: color, size: 17),
            ),
            const SizedBox(height: 8),
            Text(card.label,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.onSurface),
                maxLines: 2, overflow: TextOverflow.ellipsis),
          ]),
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final FeatureCard card;
  final VoidCallback onTap;
  final bool isLast;
  const _DrawerItem({required this.card, required this.onTap, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    final color = card.color ?? AppTheme.primary;
    return Column(children: [
      InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(card.icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(card.label,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.onSurface))),
            Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.grey.shade300),
          ]),
        ),
      ),
      if (!isLast) Divider(height: 1, indent: 62, endIndent: 0, color: Colors.grey.shade100),
    ]);
  }
}

class _DrawerSimpleItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool isLast;
  const _DrawerSimpleItem({required this.icon, required this.label, required this.color, required this.onTap, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color)),
          ]),
        ),
      ),
      if (!isLast) Divider(height: 1, indent: 62, color: Colors.grey.shade100),
    ]);
  }
}

class _FeatureScreenWrapper extends StatelessWidget {
  final String title;
  final Widget screen;
  final Widget? fab;
  final bool hasOwnScaffold;
  const _FeatureScreenWrapper({required this.title, required this.screen, this.fab, this.hasOwnScaffold = false});

  @override
  Widget build(BuildContext context) {
    if (hasOwnScaffold) return screen;
    return Scaffold(appBar: AppBar(title: Text(title)), body: screen, floatingActionButton: fab);
  }
}
