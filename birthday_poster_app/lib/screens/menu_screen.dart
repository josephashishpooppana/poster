import 'package:flutter/material.dart';

import '../models/anniversary_event.dart';
import '../models/poster_menu_item.dart';
import '../services/priest_repository.dart';
import '../services/reminder_store.dart';
import '../theme/app_theme.dart';
import '../widgets/anniversary_reminder_banner.dart';
import 'birthday_poster_screen.dart';
import 'ordination_poster_screen.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  List<AnniversaryEvent> _pendingEvents = [];
  bool _loadingReminders = true;

  @override
  void initState() {
    super.initState();
    ReminderStore.instance.addListener(_loadReminders);
    _loadReminders();
  }

  @override
  void dispose() {
    ReminderStore.instance.removeListener(_loadReminders);
    super.dispose();
  }

  Future<void> _loadReminders() async {
    await ReminderStore.instance.resetDayIfNeeded();
    final todayEvents = PriestRepository.instance.eventsOn(DateTime.now());
    final handled = await ReminderStore.instance.handledIds();
    if (!mounted) return;
    setState(() {
      _pendingEvents =
          todayEvents.where((event) => !handled.contains(event.id)).toList();
      _loadingReminders = false;
    });
  }

  Future<void> _openPoster(BuildContext context, PosterType type) async {
    final Widget screen = switch (type) {
      PosterType.birthday => const BirthdayPosterScreen(),
      PosterType.ordination => const OrdinationPosterScreen(),
    };

    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => screen),
    );
    if (!mounted) return;
    await _loadReminders();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 168,
            pinned: true,
            backgroundColor: AppColors.teal,
            foregroundColor: Colors.white,
            actions: [
              if (_pendingEvents.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Center(
                    child: Badge.count(
                      count: _pendingEvents.length,
                      child: const Icon(Icons.notifications_active_outlined),
                    ),
                  ),
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 16, bottom: 14),
              title: Text(
                'Poster App',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.teal, AppColors.tealLight],
                  ),
                ),
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 52),
                    child: Text(
                      'Roman Catholic Diocese of Cochin',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (_loadingReminders)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: LinearProgressIndicator(minHeight: 2),
              ),
            )
          else if (_pendingEvents.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              sliver: SliverList.separated(
                itemCount: _pendingEvents.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  return AnniversaryReminderBanner(event: _pendingEvents[index]);
                },
              ),
            ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              16,
              _pendingEvents.isNotEmpty || _loadingReminders ? 20 : 20,
              16,
              24,
            ),
            sliver: SliverList.separated(
              itemCount: PosterMenuItem.all.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = PosterMenuItem.all[index];
                return _PosterMenuCard(
                  item: item,
                  onTap: item.available
                      ? () => _openPoster(context, item.type)
                      : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PosterMenuCard extends StatelessWidget {
  const _PosterMenuCard({required this.item, this.onTap});

  final PosterMenuItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: enabled ? AppColors.teal.withValues(alpha: 0.35) : AppColors.panelBorder,
            ),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: AppColors.teal.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: enabled
                        ? AppColors.teal.withValues(alpha: 0.12)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    item.icon,
                    color: enabled ? AppColors.teal : Colors.grey,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: enabled ? AppColors.nameDark : Colors.grey,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade600,
                              height: 1.35,
                            ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  enabled ? Icons.arrow_forward_ios_rounded : Icons.lock_outline,
                  size: 18,
                  color: enabled ? AppColors.teal : Colors.grey.shade400,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
