import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool isSecondary;
  final bool isOutlined;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isSecondary = false,
    this.isOutlined = false,
    this.backgroundColor,
    this.foregroundColor,
    this.padding,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    Widget buttonChild = isLoading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: foregroundColor ?? 
                (isOutlined || isSecondary 
                  ? theme.colorScheme.primary 
                  : theme.colorScheme.onPrimary),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon),
                const SizedBox(width: 8),
              ],
              Text(text),
            ],
          );

    Widget button;
    
    if (isOutlined) {
      button = OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: foregroundColor ?? theme.colorScheme.primary,
          padding: padding ?? const EdgeInsets.symmetric(
            horizontal: 24, 
            vertical: 12,
          ),
          minimumSize: Size(width ?? 0, height ?? 48),
        ),
        child: buttonChild,
      );
    } else if (isSecondary) {
      button = TextButton(
        onPressed: isLoading ? null : onPressed,
        style: TextButton.styleFrom(
          foregroundColor: foregroundColor ?? theme.colorScheme.primary,
          padding: padding ?? const EdgeInsets.symmetric(
            horizontal: 24, 
            vertical: 12,
          ),
          minimumSize: Size(width ?? 0, height ?? 48),
        ),
        child: buttonChild,
      );
    } else {
      button = ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? theme.colorScheme.primary,
          foregroundColor: foregroundColor ?? theme.colorScheme.onPrimary,
          padding: padding ?? const EdgeInsets.symmetric(
            horizontal: 24, 
            vertical: 12,
          ),
          minimumSize: Size(width ?? 0, height ?? 48),
        ),
        child: buttonChild,
      );
    }

    if (width != null) {
      return SizedBox(width: width, child: button);
    }
    
    return button;
  }
}

class FloatingActionButtonCustom extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String? tooltip;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool mini;

  const FloatingActionButtonCustom({
    super.key,
    required this.onPressed,
    required this.icon,
    this.tooltip,
    this.backgroundColor,
    this.foregroundColor,
    this.mini = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return FloatingActionButton(
      onPressed: onPressed,
      tooltip: tooltip,
      mini: mini,
      backgroundColor: backgroundColor ?? theme.colorScheme.secondary,
      foregroundColor: foregroundColor ?? theme.colorScheme.onSecondary,
      child: Icon(icon),
    );
  }
}