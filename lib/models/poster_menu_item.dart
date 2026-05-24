import 'package:flutter/material.dart';

enum PosterType { birthday }

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
  ];
}
