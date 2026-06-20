import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class MoreTabItem {
  final IconData icon;
  final String label;
  final Color color;
  final Widget screen;
  final bool hasOwnScaffold;
  const MoreTabItem({required this.icon, required this.label, required this.color, required this.screen, this.hasOwnScaffold = false});
}

class MoreTab extends StatelessWidget {
  final String employeeName;
  final String empId;
  final String role;
  final List<MoreTabItem> items;
  final VoidCallback onLogout;

  const MoreTab({
    super.key,
    required this.employeeName,
    required this.empId,
    required this.role,
    required this.items,
    required this.onLogout,
  });

  String get _initials => employeeName.trim().split(' ')
      .take(2).map((w) => w.isNotEmpty ? w[0].toUpperCase() : '').join();

  @override
  Widget build(BuildContext context) {
    final ringColor = AppTheme.roleColor(role);
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('More'), automaticallyImplyLeading: false),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _profileCard(ringColor),
          const SizedBox(height: 20),
          ...items.map((item) => _featureCard(context, item)),
          const SizedBox(height: 8),
          _logoutButton(context),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _profileCard(Color ringColor) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: [AppTheme.primary, AppTheme.primaryVariant], begin: Alignment.topLeft, end: Alignment.bottomRight),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(children: [
      Container(
        width: 52, height: 52,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          shape: BoxShape.circle,
          border: Border.all(color: ringColor, width: 2.5),
        ),
        child: Center(child: Text(_initials,
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800))),
      ),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(employeeName,
            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800),
            overflow: TextOverflow.ellipsis),
        const SizedBox(height: 4),
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: ringColor.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: ringColor.withValues(alpha: 0.7)),
            ),
            child: Text(role, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 8),
          Text('· $empId', style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 11)),
        ]),
      ])),
    ]),
  );

  Widget _featureCard(BuildContext context, MoreTabItem item) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => item.hasOwnScaffold ? item.screen : Scaffold(appBar: AppBar(title: Text(item.label)), body: item.screen),
        )),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(color: item.color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
              child: Icon(item.icon, color: item.color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(child: Text(item.label,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.onSurface))),
            Icon(Icons.chevron_right_rounded, color: Colors.grey.shade300, size: 22),
          ]),
        ),
      ),
    ),
  );

  Widget _logoutButton(BuildContext context) => Material(
    color: AppTheme.error.withValues(alpha: 0.06),
    borderRadius: BorderRadius.circular(14),
    child: InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onLogout,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(color: AppTheme.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.logout_rounded, color: AppTheme.error, size: 20),
          ),
          const SizedBox(width: 14),
          const Text('Logout', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.error)),
        ]),
      ),
    ),
  );
}
