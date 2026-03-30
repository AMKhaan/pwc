import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Drop into any screen to show a one-time hint card.
/// Reads/writes SharedPreferences key "hint_{featureKey}".
///
/// Usage:
///   FeatureHint(
///     featureKey: 'home',
///     icon: Icons.explore_outlined,
///     title: 'Discover Rides',
///     description: 'Browse available rides...',
///     color: AppTheme.primary,
///   )
class FeatureHint extends StatefulWidget {
  final String featureKey;
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  const FeatureHint({
    super.key,
    required this.featureKey,
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });

  @override
  State<FeatureHint> createState() => _FeatureHintState();
}

class _FeatureHintState extends State<FeatureHint>
    with SingleTickerProviderStateMixin {
  bool _visible = false;
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

    _check();
  }

  Future<void> _check() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool('hint_${widget.featureKey}') ?? false;
    if (!seen && mounted) {
      setState(() => _visible = true);
      _ctrl.forward();
    }
  }

  Future<void> _dismiss() async {
    await _ctrl.reverse();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hint_${widget.featureKey}', true);
    if (mounted) setState(() => _visible = false);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          decoration: BoxDecoration(
            color: widget.color.withOpacity(0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: widget.color.withOpacity(0.2)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: widget.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child:
                      Icon(widget.icon, color: widget.color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: widget.color,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        widget.description,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _dismiss,
                  icon: const Icon(Icons.close_rounded,
                      size: 16, color: Color(0xFF94A3B8)),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  splashRadius: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
