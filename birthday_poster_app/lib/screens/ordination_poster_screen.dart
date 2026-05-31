import 'package:flutter/material.dart';

import '../models/poster_data.dart';
import 'birthday_poster_screen.dart';

class OrdinationPosterScreen extends StatelessWidget {
  const OrdinationPosterScreen({
    super.key,
    this.initialData,
  });

  final PosterData? initialData;

  @override
  Widget build(BuildContext context) {
    return BirthdayPosterScreen(
      initialData: initialData,
      screenTitle: 'Ordination Poster',
    );
  }
}
