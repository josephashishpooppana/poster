import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/anniversary_event.dart';
import '../theme/app_theme.dart';

class AnniversaryListTile extends StatelessWidget {
  const AnniversaryListTile({
    super.key,
    required this.event,
    required this.onEdit,
    required this.onCreatePoster,
    this.isToday = false,
  });

  final AnniversaryEvent event;
  final VoidCallback onEdit;
  final VoidCallback onCreatePoster;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final priest = event.priest;
    final dateStr = DateFormat('EEE, d MMM yyyy').format(event.anniversaryOn);
    final isBirthday = event.type == AnniversaryType.birthday;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isToday
                ? AppColors.teal.withValues(alpha: 0.6)
                : AppColors.panelBorder,
            width: isToday ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.teal.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.teal.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isBirthday ? Icons.cake_outlined : Icons.church_outlined,
                      color: AppColors.teal,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: AppColors.teal,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        Text(
                          dateStr,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey.shade600,
                              ),
                        ),
                      ],
                    ),
                  ),
                  if (isToday)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.teal,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Today',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                priest.fullName,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.nameDark,
                    ),
              ),
              if (priest.designation.trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  priest.designation.trim(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade700,
                      ),
                ),
              ],
              if (priest.servingAt.trim().isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  priest.servingAt.trim(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                        height: 1.35,
                      ),
                ),
              ],
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Edit'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onCreatePoster,
                      icon: const Icon(Icons.image_outlined, size: 18),
                      label: const Text('Poster'),
                    ),
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
