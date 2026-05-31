import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/anniversary_event.dart';
import '../services/notification_router.dart';
import '../services/priest_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/anniversary_list_tile.dart';
import '../widgets/edit_priest_dialog.dart';

class UpcomingAnniversariesScreen extends StatefulWidget {
  const UpcomingAnniversariesScreen({super.key});

  @override
  State<UpcomingAnniversariesScreen> createState() =>
      _UpcomingAnniversariesScreenState();
}

class _UpcomingAnniversariesScreenState
    extends State<UpcomingAnniversariesScreen> {
  List<AnniversaryEvent> _events = [];
  bool _loading = true;
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents({bool forceRefresh = false}) async {
    if (forceRefresh) {
      setState(() => _refreshing = true);
      await PriestRepository.instance.initialize(forceRefresh: true);
    }

    final events = PriestRepository.instance.upcomingEvents();
    if (!mounted) return;
    setState(() {
      _events = events;
      _loading = false;
      _refreshing = false;
    });
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  Future<void> _editEvent(AnniversaryEvent event) async {
    final saved = await EditPriestDialog.show(context, event);
    if (saved == true) {
      await _loadEvents();
    }
  }

  void _createPoster(AnniversaryEvent event) {
    NotificationRouter.openPosterFromEvent(event);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upcoming Anniversaries'),
        actions: [
          IconButton(
            icon: _refreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.sync_outlined),
            tooltip: 'Refresh from sheet',
            onPressed: _refreshing ? null : () => _loadEvents(forceRefresh: true),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _events.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.event_busy_outlined,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No upcoming anniversaries',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => _loadEvents(forceRefresh: true),
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Text(
                            '${_events.length} upcoming birthdays & ordinations from today',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey.shade700,
                                ),
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        sliver: SliverList.separated(
                          itemCount: _events.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final event = _events[index];
                            final showMonthHeader = index == 0 ||
                                !_sameMonth(
                                  event.anniversaryOn,
                                  _events[index - 1].anniversaryOn,
                                );

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (showMonthHeader) ...[
                                  if (index > 0) const SizedBox(height: 8),
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: 10,
                                      top: 4,
                                    ),
                                    child: Text(
                                      DateFormat('MMMM yyyy')
                                          .format(event.anniversaryOn),
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                            color: AppColors.teal,
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                  ),
                                ],
                                AnniversaryListTile(
                                  event: event,
                                  isToday: _isToday(event.anniversaryOn),
                                  onEdit: () => _editEvent(event),
                                  onCreatePoster: () => _createPoster(event),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  bool _sameMonth(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month;
}
