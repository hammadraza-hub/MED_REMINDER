import 'package:flutter/material.dart';

import '../../core/community/community_name_suggester.dart';

/// A preset avatar: a round coloured badge with an icon. M19 step 2.
/// No photo is ever uploaded, so nothing here can identify a person.
class CommunityAvatar extends StatelessWidget {
  const CommunityAvatar({super.key, required this.avatarKey, this.size = 44});

  final String? avatarKey;
  final double size;

  static const List<IconData> _icons = [
    Icons.eco_rounded,
    Icons.favorite_rounded,
    Icons.wb_sunny_rounded,
    Icons.water_drop_rounded,
    Icons.star_rounded,
    Icons.pets_rounded,
    Icons.local_florist_rounded,
    Icons.directions_walk_rounded,
    Icons.self_improvement_rounded,
    Icons.coffee_rounded,
    Icons.music_note_rounded,
    Icons.spa_rounded,
  ];

  static const List<Color> _colors = [
    Color(0xFF2E7D32),
    Color(0xFFC62828),
    Color(0xFFEF6C00),
    Color(0xFF1565C0),
    Color(0xFF6A1B9A),
    Color(0xFF4E342E),
    Color(0xFFAD1457),
    Color(0xFF00838F),
    Color(0xFF37474F),
    Color(0xFF8D6E63),
    Color(0xFF3949AB),
    Color(0xFF558B2F),
  ];

  @override
  Widget build(BuildContext context) {
    final i = CommunityAvatars.keys.indexOf(CommunityAvatars.safe(avatarKey));
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: _colors[i], shape: BoxShape.circle),
      child: Icon(_icons[i], color: Colors.white, size: size * 0.55),
    );
  }
}
