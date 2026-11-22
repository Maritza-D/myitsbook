import 'package:flutter/material.dart';
import 'package:myitsbook/core/theme/app_theme.dart';

class BookGridSkeleton extends StatefulWidget {
  const BookGridSkeleton({super.key, this.itemCount = 4});

  final int itemCount;

  @override
  State<BookGridSkeleton> createState() => _BookGridSkeletonState();
}

class _BookGridSkeletonState extends State<BookGridSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmerCtrl;

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final semantic = AppSemanticColors.of(context);
    final scheme = Theme.of(context).colorScheme;
    final disableAnim = MediaQuery.disableAnimationsOf(context);
    final base = semantic.subtleSurface;
    final highlight = scheme.surface;

    return AnimatedBuilder(
      animation: _shimmerCtrl,
      builder: (context, _) {
        final slide = disableAnim ? 0.0 : (_shimmerCtrl.value * 2.4) - 0.7;
        final shimmer = BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: LinearGradient(
            begin: Alignment(slide - 0.8, -0.3),
            end: Alignment(slide + 0.8, 0.3),
            colors: [base, highlight, base],
            stops: const [0.1, 0.5, 0.9],
          ),
        );

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: widget.itemCount,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.61,
          ),
          itemBuilder: (_, _) => Card(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 6,
                    child: Container(
                      decoration: shimmer.copyWith(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    height: 13,
                    width: double.infinity,
                    decoration: shimmer,
                  ),
                  const SizedBox(height: 6),
                  Container(height: 13, width: 92, decoration: shimmer),
                  const Spacer(),
                  Container(height: 16, width: 76, decoration: shimmer),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class EmptyStateView extends StatelessWidget {
  const EmptyStateView({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final semantic = AppSemanticColors.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                color: semantic.silverFrost.withValues(alpha: 0.55),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: semantic.silverFrost,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 28, color: semantic.navy),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: semantic.textMuted,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 18),
              OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

class ErrorRetryView extends StatelessWidget {
  const ErrorRetryView({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return EmptyStateView(
      icon: Icons.wifi_off_rounded,
      title: 'Gagal memuat data',
      subtitle: message,
      actionLabel: 'Coba Lagi',
      onAction: onRetry,
    );
  }
}
