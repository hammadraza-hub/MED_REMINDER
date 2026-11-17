import 'package:flutter/material.dart';

import '../../core/app_error_text.dart';
import '../../core/daily_limits.dart';
import '../../core/app_exception.dart';
import '../../core/community/community_content_filter.dart';
import '../../core/community/community_models.dart';
import '../../core/community/community_posts.dart';
import '../../core/community/community_profile_controller.dart';
import '../../core/community/community_time.dart';
import '../../core/community/community_validator.dart';
import '../../l10n/app_localizations.dart';

/// "5 min ago", "2 h ago", "3 d ago" or a short date. M19 step 3/4.
String communityAgoText(
  BuildContext context,
  DateTime then, {
  DateTime Function()? now,
}) {
  final l10n = AppLocalizations.of(context);
  final ago = CommunityTime.ago(then, (now ?? DateTime.now)());
  return switch (ago.unit) {
    CommunityAgoUnit.justNow => l10n.communityAgoNow,
    CommunityAgoUnit.minutes => l10n.communityAgoMinutes(ago.value),
    CommunityAgoUnit.hours => l10n.communityAgoHours(ago.value),
    CommunityAgoUnit.days => l10n.communityAgoDays(ago.value),
    CommunityAgoUnit.date => MaterialLocalizations.of(
      context,
    ).formatShortDate(then),
  };
}

/// The message for a failed write. [max] is the text limit (for "too long").
String communityActionError(
  AppLocalizations l10n,
  Object error, {
  int max = CommunityLimits.postBodyMax,
}) {
  if (error is CommunityInputException) {
    return switch (error.error) {
      CommunityInputError.empty => l10n.communityErrBodyEmpty,
      CommunityInputError.tooLong => l10n.communityErrBodyTooLong(max),
      CommunityInputError.inappropriate => l10n.communityErrInappropriate,
      _ => l10n.communitySaveFailed,
    };
  }
  if (error is CommunityContentException) {
    return error.verdict == CommunityVerdict.contact
        ? l10n.communityErrContactPost
        : l10n.communityErrInappropriate;
  }
  if (error is DailyLimitException) return l10n.dailyLimitReached;
  if (error is CommunityNoProfileException) return l10n.communityNoProfile;
  if (error is CommunityDeniedException) return l10n.communityDenied;
  // No connection / no answer: say so, so the user knows to try again later.
  final mapped = AppException.fromAny(error);
  if (mapped.type == AppExceptionType.network) {
    return AppErrorText.of(l10n, mapped);
  }
  return l10n.communitySaveFailed;
}
