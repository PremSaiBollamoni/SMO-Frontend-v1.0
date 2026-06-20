import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class NavTab {
  final IconData icon;
  final IconData? activeIcon;
  final String label;
  final Widget screen;
  const NavTab({required this.icon, required this.label, required this.screen, this.activeIcon});
}

class BottomNavShell extends StatefulWidget {
  final List<NavTab> tabs;
  const BottomNavShell({super.key, required this.tabs});

  @override
  State<BottomNavShell> createState() => _BottomNavShellState();
}

class _BottomNavShellState extends State<BottomNavShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: widget.tabs.map((t) => t.screen).toList(),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, -4))],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 60,
            child: Row(
              children: widget.tabs.asMap().entries.map((entry) {
                final i = entry.key;
                final tab = entry.value;
                final selected = i == _index;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _index = i),
                    behavior: HitTestBehavior.opaque,
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: selected ? AppTheme.primary.withValues(alpha: 0.1) : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          selected ? (tab.activeIcon ?? tab.icon) : tab.icon,
                          color: selected ? AppTheme.primary : AppTheme.onSurfaceVariant,
                          size: 22,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(tab.label,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                            color: selected ? AppTheme.primary : AppTheme.onSurfaceVariant,
                          )),
                    ]),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}
