import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_config.dart';
import '../../shared/widgets/app_logo.dart';

class HomeShell extends StatelessWidget {
  const HomeShell({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  static const _routes = ['/', '/fuel', '/events', '/stats', '/garage'];

  static const _destinations = [
    _NavItem('Огляд', Icons.dashboard_outlined, Icons.dashboard_rounded),
    _NavItem(
      'Пальне',
      Icons.local_gas_station_outlined,
      Icons.local_gas_station_rounded,
    ),
    _NavItem('Події', Icons.build_outlined, Icons.build_rounded),
    _NavItem('Статистика', Icons.insights_outlined, Icons.insights_rounded),
    _NavItem(
      'Гараж',
      Icons.directions_car_outlined,
      Icons.directions_car_rounded,
    ),
  ];

  int get _currentIndex {
    for (var i = _routes.length - 1; i > 0; i--) {
      if (location == _routes[i] || location.startsWith('${_routes[i]}/')) {
        return i;
      }
    }
    return 0;
  }

  void _go(BuildContext context, int index) {
    if (index == _currentIndex) return;
    context.go(_routes[index]);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final wide = width >= 900;
    final extended = width >= 1180;

    if (wide) {
      return Scaffold(
        body: Row(
          children: [
            _Sidebar(
              extended: extended,
              currentIndex: _currentIndex,
              onSelect: (index) => _go(context, index),
            ),
            Expanded(child: child),
          ],
        ),
      );
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => _go(context, index),
        destinations: [
          for (final item in _destinations)
            NavigationDestination(
              icon: Icon(item.icon),
              selectedIcon: Icon(item.selectedIcon),
              label: item.label,
            ),
        ],
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.extended,
    required this.currentIndex,
    required this.onSelect,
  });

  final bool extended;
  final int currentIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      width: extended ? 260 : 84,
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(right: BorderSide(color: scheme.outline)),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            extended ? 16 : 10,
            22,
            extended ? 16 : 10,
            18,
          ),
          child: Column(
            crossAxisAlignment: extended
                ? CrossAxisAlignment.stretch
                : CrossAxisAlignment.center,
            children: [
              _Brand(extended: extended),
              const SizedBox(height: 26),
              if (extended)
                Padding(
                  padding: const EdgeInsets.only(left: 12, bottom: 10),
                  child: Text(
                    'НАВІГАЦІЯ',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.38),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                    ),
                  ),
                )
              else
                const SizedBox(height: 8),
              for (var i = 0; i < HomeShell._destinations.length; i++) ...[
                _SidebarTile(
                  item: HomeShell._destinations[i],
                  selected: i == currentIndex,
                  extended: extended,
                  onTap: () => onSelect(i),
                ),
                const SizedBox(height: 6),
              ],
              const Spacer(),
              if (extended)
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Text(
                    'v${AppConfig.version}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.32),
                      letterSpacing: 0.3,
                    ),
                  ),
                )
              else
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: scheme.outline,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand({required this.extended});

  final bool extended;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (!extended) return const AppLogo(size: 42);

    return Row(
      children: [
        const AppLogo(size: 42),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppConfig.appName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                'Щоденник авто',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SidebarTile extends StatelessWidget {
  const _SidebarTile({
    required this.item,
    required this.selected,
    required this.extended,
    required this.onTap,
  });

  final _NavItem item;
  final bool selected;
  final bool extended;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final accent = scheme.primary;
    final inactiveIcon = scheme.onSurface.withValues(alpha: 0.52);
    final inactiveText = scheme.onSurface.withValues(alpha: 0.72);

    final iconBox = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: selected
            ? accent.withValues(alpha: isDark ? 0.22 : 0.15)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Icon(
        selected ? item.selectedIcon : item.icon,
        size: 20,
        color: selected ? accent : inactiveIcon,
      ),
    );

    final tile = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          height: 50,
          padding: EdgeInsets.symmetric(horizontal: extended ? 10 : 0),
          decoration: BoxDecoration(
            color: selected
                ? accent.withValues(alpha: isDark ? 0.14 : 0.09)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: selected
                  ? accent.withValues(alpha: isDark ? 0.24 : 0.16)
                  : Colors.transparent,
            ),
          ),
          child: extended
              ? Row(
                  children: [
                    iconBox,
                    const SizedBox(width: 11),
                    Expanded(
                      child: Text(
                        item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.1,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w600,
                          letterSpacing: -0.1,
                          color: selected ? scheme.onSurface : inactiveText,
                        ),
                      ),
                    ),
                    if (selected)
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: accent,
                        ),
                      ),
                  ],
                )
              : Center(child: iconBox),
        ),
      ),
    );

    if (extended) return tile;
    return Tooltip(message: item.label, child: tile);
  }
}

class _NavItem {
  const _NavItem(this.label, this.icon, this.selectedIcon);

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}
