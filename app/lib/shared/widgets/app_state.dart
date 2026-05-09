import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../core/theme.dart';

class AppLoadingState extends StatelessWidget {
  final String? label;

  const AppLoadingState({super.key, this.label});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label ?? AppLocalizations.of(context).appLoading,
      liveRegion: true,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 30,
                height: 30,
                child: CircularProgressIndicator(strokeWidth: 2.6),
              ),
              if (label != null) ...[
                const SizedBox(height: 14),
                Text(
                  label!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xB3FFFFFF)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: '$title. $message',
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 34, color: Colors.white.withValues(alpha: 0.42)),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0x99FFFFFF), height: 1.35),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.refresh, size: 18),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class AppErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const AppErrorState({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Semantics(
      container: true,
      liveRegion: true,
      label: '${l.appErrorTitle}. $message',
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 34,
                color: AppColors.liveRed,
              ),
              const SizedBox(height: 12),
              Text(
                l.appErrorTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xB3FFFFFF), height: 1.35),
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: Text(l.retry),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
