import 'package:flutter/material.dart';

class QuickActionsBar extends StatelessWidget {
  final List<String> actions;
  final Function(String action) onAction;

  const QuickActionsBar({
    super.key,
    required this.actions,
    required this.onAction,
  });

  static const _actionLabels = {
    '\t': 'TAB',
    '\x1b': 'ESC',
    '\x03': 'C+C',
    '\x04': 'C+D',
    '\x1b[A': '↑',
    '\x1b[B': '↓',
    '\x1b[D': '←',
    '\x1b[C': '→',
  };

  static const _actionIcons = {
    '\x1b[A': Icons.arrow_upward,
    '\x1b[B': Icons.arrow_downward,
    '\x1b[D': Icons.arrow_back,
    '\x1b[C': Icons.arrow_forward,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: actions.map((action) {
            final label = _actionLabels[action];
            final icon = _actionIcons[action];
            
            if (icon != null) {
              return _ActionButton(
                icon: icon,
                onPressed: () => onAction(action),
              );
            } else if (label != null) {
              return _ActionButton(
                label: label,
                onPressed: () => onAction(action),
              );
            }
            return const SizedBox.shrink();
          }).toList(),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final VoidCallback onPressed;

  const _ActionButton({
    this.label,
    this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Material(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(4),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: icon != null
                ? Icon(icon, size: 18)
                : Text(
                    label ?? '',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
