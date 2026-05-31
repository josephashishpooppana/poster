import 'package:flutter/material.dart';

import '../models/anniversary_event.dart';
import '../services/notification_router.dart';
import '../services/poster_prefill_mapper.dart';
import '../theme/app_theme.dart';

class AnniversaryReminderBanner extends StatelessWidget {
  const AnniversaryReminderBanner({
    super.key,
    required this.event,
  });

  final AnniversaryEvent event;

  @override
  Widget build(BuildContext context) {
    final bodyLines = PosterPrefillMapper.notificationBody(event).split('\n');
    final name = bodyLines.isNotEmpty ? bodyLines.first : event.priest.fullName;
    final dateLine = bodyLines.length > 1 ? bodyLines[1] : '';
    final detailLines = bodyLines.length > 2 ? bodyLines.sublist(2) : const [];

    return Material(
      color: AppColors.teal.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => NotificationRouter.openFromEvent(event),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.teal.withValues(alpha: 0.35)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      event.type == AnniversaryType.birthday
                          ? Icons.cake_outlined
                          : Icons.church_outlined,
                      color: AppColors.teal,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        event.title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: AppColors.teal,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.nameDark,
                      ),
                ),
                if (dateLine.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    dateLine,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade700,
                        ),
                  ),
                ],
                for (final line in detailLines) ...[
                  const SizedBox(height: 2),
                  Text(
                    line,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                          height: 1.35,
                        ),
                  ),
                ],
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: () => NotificationRouter.openFromEvent(event),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Create Poster'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
