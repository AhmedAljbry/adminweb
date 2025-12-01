// lib/genertcode/presentation/widgets/ResultCard.dart
import 'package:flutter/material.dart';

class ResultCard extends StatelessWidget {
  final bool isLoaded;
  final String? path;
  final int uploaded;
  final int requested;
  final bool stopped;

  const ResultCard({
    super.key,
    required this.isLoaded,
    required this.path,
    required this.uploaded,
    required this.requested,
    required this.stopped,
  });

  @override
  Widget build(BuildContext context) {
    if (!isLoaded) return const SizedBox.shrink();
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: stopped ? Colors.orange[50] : Colors.green[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(stopped ? 'تم الإيقاف' : 'تمت العملية بنجاح',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: stopped ? Colors.orange[800] : Colors.green[800],
                )),
            const SizedBox(height: 8),
            Text('المرفوع: $uploaded / المطلوب: $requested'),
            const SizedBox(height: 4),
            Text('مسار ملف Excel: ${path ?? "-"}',
                maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}
