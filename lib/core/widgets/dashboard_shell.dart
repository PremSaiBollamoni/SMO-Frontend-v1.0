import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/switch_role_helper.dart';

/// A feature card definition for the dashboard home grid
class FeatureCard {
  final IconData icon;
  final String label;
  final String? subtitle;
  final Widget Function() screenBuilder;
  final Color? color;
  final Widget? fab;

  FeatureCard({
    required this.icon,
    required this.label,
    required Widget screen,
    this.subtitle,
    this.color,
    this.fab,
  }) : screenBuilder = (() => screen);

  const FeatureCard.lazy({
    required this.icon,
    required this.label,
    required this.screenBuilder,
    this.subtitle,
    this.color,
    this.fab,
  });
}

/// A group of feature cards with a section title
class FeatureGroup {
  final String title;
  final List<FeatureCard> cards;

  const FeatureGroup({required this.title, required this.cards});
}

/// Reusable Dashboard Shell — replaces drawer-based navigation with a
/// card-grid home screen. Each card opens its feature full-screen.
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
  void _openFeature(FeatureCard card) {
    debugPrint('[DASHBOARD] Opening feature: ${card.label}');
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _FeatureScreenWrapper(
          title: card.label,
          screen: card.screenBuilder(),
          fab: card.fab,
        ),
      ),
    ).then((_) {
      debugPrint('[DASHBOARD] Returned from: ${card.label}');
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        automaticallyImplyLeading: false,
        actions: [
          // Switch Role button (only if multiple roles)
          FutureBuilder<bool>(
            future: SwitchRoleHelper.hasMultipleRoles(),
            builder: (ctx, snap) {
              if (snap.data != true) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.switch_account),
                tooltip: 'Switch Role',
                onPressed: () => SwitchRoleHelper.showRolePicker(context),
              );
            },
          ),
          // Logout
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: widget.onLogout,
          ),
        ],
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // User header card
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primary, AppTheme.primaryVariant],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      child: Icon(widget.roleIcon, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.employeeName,
                            style: AppTheme.titleLarge.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${widget.role} • ID ${widget.empId}',
                            style: AppTheme.bodySmall.copyWith(
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Feature groups
            ...widget.groups.expand((group) => [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: Text(
                    group.title,
                    style: AppTheme.titleMedium.copyWith(
                      color: AppTheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 160,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.0,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _FeatureTile(
                      card: group.cards[index],
                      onTap: () => _openFeature(group.cards[index]),
                    ),
                    childCount: group.cards.length,
                  ),
                ),
              ),
            ]),
            // Bottom spacing
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }
}

/// Individual feature tile widget
class _FeatureTile extends StatelessWidget {
  final FeatureCard card;
  final VoidCallback onTap;

  const _FeatureTile({required this.card, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = card.color ?? AppTheme.primary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppTheme.surfaceVariant,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(card.icon, color: color, size: 26),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  card.label,
                  style: AppTheme.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Wrapper that shows a feature screen with an AppBar and back button
class _FeatureScreenWrapper extends StatelessWidget {
  final String title;
  final Widget screen;
  final Widget? fab;

  const _FeatureScreenWrapper({required this.title, required this.screen, this.fab});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: screen,
      floatingActionButton: fab,
    );
  }
}
