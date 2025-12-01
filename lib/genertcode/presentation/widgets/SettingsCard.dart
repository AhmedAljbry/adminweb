// lib/genertcode/presentation/widgets/SettingsCard.dart
import 'package:flutter/material.dart';

typedef FieldBuilder = Widget Function(BuildContext context);

class SettingsCard extends StatelessWidget {
  final GlobalKey<FormState> formKey;

  final FieldBuilder countFieldBuilder;
  final FieldBuilder collectionFieldBuilder;
  final FieldBuilder fileFieldBuilder;
  final FieldBuilder documentFieldBuilder;

  final VoidCallback onStart;
  final VoidCallback? onStop;
  final VoidCallback onReset;
  final bool isRunning;
  final bool isOnline;

  const SettingsCard({
    super.key,
    required this.formKey,
    required this.countFieldBuilder,
    required this.collectionFieldBuilder,
    required this.fileFieldBuilder,
    required this.documentFieldBuilder,
    required this.onStart,
    required this.onStop,
    required this.onReset,
    required this.isRunning,
    required this.isOnline,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: formKey,
          child: Column(
            children: [
              // عدد المعرّفات
              Row(children: [Expanded(child: countFieldBuilder(context))]),
              const SizedBox(height: 12),

              // Collection
              Row(children: [Expanded(child: collectionFieldBuilder(context))]),
              const SizedBox(height: 12),

              // file + document
              Row(
                children: [
                  Expanded(child: fileFieldBuilder(context)),
                  const SizedBox(width: 12),
                  Expanded(child: documentFieldBuilder(context)),
                ],
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: (!isRunning && isOnline) ? onStart : null,
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text('بدء العملية'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: isRunning ? onStop : null,
                      icon: const Icon(Icons.stop_circle_outlined),
                      label: const Text('إيقاف'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton.filledTonal(
                    onPressed: onReset,
                    icon: const Icon(Icons.refresh_rounded),
                    tooltip: 'إعادة ضبط',
                  ),
                ],
              ),
              const SizedBox(height: 6),
              if (!isOnline)
                Row(
                  children: [
                    const Icon(Icons.wifi_off, size: 18, color: Colors.red),
                    const SizedBox(width: 6),
                    Text(
                      'لا يوجد اتصال بالإنترنت',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: Colors.red),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
