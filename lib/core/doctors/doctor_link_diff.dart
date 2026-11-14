/// What has to change when the user ticks / unticks medications on the
/// Add / Edit Doctor screen. Pure logic. M16 step 4.
class DoctorLinkDiff {
  const DoctorLinkDiff({required this.toLink, required this.toUnlink});

  /// Medications that must now name this doctor.
  final List<String> toLink;

  /// Medications that named this doctor but were unticked.
  final List<String> toUnlink;

  bool get isEmpty => toLink.isEmpty && toUnlink.isEmpty;

  /// [original] = medication ids linked when the screen opened,
  /// [selected] = ids ticked when saving. Result is sorted so it is stable.
  static DoctorLinkDiff compute({
    required Set<String> original,
    required Set<String> selected,
  }) => DoctorLinkDiff(
    toLink: (selected.difference(original).toList()..sort()),
    toUnlink: (original.difference(selected).toList()..sort()),
  );
}
