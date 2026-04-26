import 'package:flutter/material.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';

class GhostButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double size;
  final Color? background;
  final Color? color;

  const GhostButton({
    super.key,
    required this.child,
    this.onTap,
    this.size = 40,
    this.background,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background ?? Colors.transparent,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: size,
          height: size,
          child: IconTheme(
            data: IconThemeData(color: color ?? AppTokens.fg, size: 20),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  final String label;
  final IconData? leading;
  final VoidCallback? onTap;

  const PrimaryButton({super.key, required this.label, this.leading, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTokens.accent(),
      borderRadius: BorderRadius.circular(AppTokens.radiusPill),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTokens.radiusPill),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leading != null) ...[
                Icon(leading, size: 14, color: const Color(0xFF0A0A0C)),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: AppType.sans(
                  size: 13,
                  weight: FontWeight.w500,
                  color: const Color(0xFF0A0A0C),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PrimaryButtonBlock extends StatelessWidget {
  final String label;
  final IconData? leading;
  final VoidCallback? onTap;
  final bool enabled;
  final double height;

  const PrimaryButtonBlock({
    super.key,
    required this.label,
    this.leading,
    this.onTap,
    this.enabled = true,
    this.height = 50,
  });

  @override
  Widget build(BuildContext context) {
    final bg = enabled ? AppTokens.accent() : AppTokens.surface3;
    final fg = enabled ? const Color(0xFF0A0A0C) : AppTokens.dim;
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(AppTokens.radiusLg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTokens.radiusLg),
        onTap: enabled ? onTap : null,
        child: SizedBox(
          height: height,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (leading != null) ...[
                Icon(leading, size: 18, color: fg),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: AppType.sans(size: 15, weight: FontWeight.w500, color: fg),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GhostButtonBlock extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  const GhostButtonBlock({super.key, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppTokens.radiusLg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTokens.radiusLg),
        onTap: onTap,
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            border: Border.all(color: AppTokens.hairlineStrong),
            borderRadius: BorderRadius.circular(AppTokens.radiusLg),
          ),
          alignment: Alignment.center,
          child: Text(label, style: AppType.body()),
        ),
      ),
    );
  }
}

class Chip extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  const Chip({super.key, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTokens.surface2,
      borderRadius: BorderRadius.circular(AppTokens.radiusPill),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTokens.radiusPill),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            border: Border.all(color: AppTokens.hairline),
            borderRadius: BorderRadius.circular(AppTokens.radiusPill),
          ),
          child: Text(label, style: AppType.sans(size: 12.5)),
        ),
      ),
    );
  }
}

class CtlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool active;
  final double size;
  final double iconSize;

  const CtlButton({
    super.key,
    required this.icon,
    this.onTap,
    this.active = false,
    this.size = 48,
    this.iconSize = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(
            icon,
            size: iconSize,
            color: active ? AppTokens.accent() : AppTokens.fg,
          ),
        ),
      ),
    );
  }
}
