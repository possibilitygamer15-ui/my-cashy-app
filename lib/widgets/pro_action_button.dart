import 'package:flutter/material.dart';

class ProActionButton extends StatelessWidget {
  const ProActionButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.loading = false,
    this.expand = false,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool loading;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null || loading;

    final child = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: disabled
            ? const LinearGradient(colors: [Color(0xFF94A3B8), Color(0xFF94A3B8)])
            : const LinearGradient(
                colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Color(0x331E3A8A), blurRadius: 12, offset: Offset(0, 6)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (loading)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          else if (icon != null)
            Icon(icon, color: Colors.white, size: 18),
          if (loading || icon != null) const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );

    final tappable = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: disabled ? null : onPressed,
        borderRadius: BorderRadius.circular(12),
        child: child,
      ),
    );

    if (expand) {
      return SizedBox(width: double.infinity, child: tappable);
    }
    return tappable;
  }
}
