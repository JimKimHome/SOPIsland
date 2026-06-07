import 'package:flutter/material.dart';

import 'app_controller.dart';
import 'screens/home_hub.dart';
import 'theme/app_theme.dart';

typedef MySopTabBuilder = Widget Function(
  AppController controller,
  String? pendingRunSopId,
  VoidCallback onPendingRunHandled,
);

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.mySopBuilder});

  final MySopTabBuilder mySopBuilder;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late final AppController _controller;
  var _tabIndex = 0;
  String? _pendingRunSopId;

  @override
  void initState() {
    super.initState();
    _controller = AppController()..load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _switchToMySop({String? runSopId}) {
    setState(() {
      _tabIndex = 1;
      _pendingRunSopId = runSopId;
    });
  }

  void _clearPendingRun() {
    if (_pendingRunSopId != null) {
      setState(() => _pendingRunSopId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        return ColoredBox(
          color: AppColors.cream,
          child: Stack(
            children: [
              const IslandBackdrop(),
              SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    Expanded(
                      child: IndexedStack(
                        index: _tabIndex,
                        children: [
                          HomeHubScreen(
                            controller: _controller,
                            onOpenMySop: () => _switchToMySop(),
                            onRunSop: (id) => _switchToMySop(runSopId: id),
                          ),
                          widget.mySopBuilder(_controller, _pendingRunSopId, _clearPendingRun),
                        ],
                      ),
                    ),
                    _BottomTabBar(
                      index: _tabIndex,
                      onChanged: (i) => setState(() => _tabIndex = i),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BottomTabBar extends StatelessWidget {
  const _BottomTabBar({required this.index, required this.onChanged});

  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border(top: BorderSide(color: AppColors.line.withValues(alpha: 0.8))),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Row(
            children: [
              _TabItem(
                icon: Icons.home_rounded,
                label: '首页',
                selected: index == 0,
                onTap: () => onChanged(0),
              ),
              _TabItem(
                icon: Icons.checklist_rounded,
                label: '我的 SOP',
                selected: index == 1,
                onTap: () => onChanged(1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.deepMint : AppColors.softBrown;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 26),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(color: color, fontWeight: selected ? FontWeight.w900 : FontWeight.w600, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
