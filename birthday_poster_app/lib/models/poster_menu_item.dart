import 'package:flutter/material.dart';

enum PosterType { birthday, ordination, upcomingAnniversaries }

class PosterMenuItem {
  const PosterMenuItem({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.available = true,
  });

  final PosterType type;
  final String title;
  final String subtitle;
  final IconData icon;
  final bool available;

  static const List<PosterMenuItem> all = [
    PosterMenuItem(
      type: PosterType.birthday,
      title: 'Birthday Poster',
      subtitle:
          'Clergy birthday layout — photo, name, date, and church positions',
      icon: Icons.cake_outlined,
    ),
    PosterMenuItem(
      type: PosterType.ordination,
      title: 'Ordination Poster',
      subtitle:
          'Priestly ordination anniversary — photo, name, date, and church positions',
      icon: Icons.church_outlined,
    ),
    PosterMenuItem(
      type: PosterType.upcomingAnniversaries,
      title: 'Upcoming Anniversaries',
      subtitle:
          'All birthdays and ordinations from today — edit details or create posters',
      icon: Icons.event_note_outlined,
    ),
  ];
}
