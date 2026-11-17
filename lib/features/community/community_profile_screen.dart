import 'package:flutter/material.dart';

import '../../core/community/community_models.dart';
import '../../core/community/community_name_suggester.dart';
import '../../core/community/community_profile_controller.dart';
import '../../core/community/community_validator.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/community_profile_service.dart';
import '../../l10n/app_localizations.dart';
import 'community_avatar.dart';

/// Create (first time) or edit the user's pseudonym profile. M19 step 2.
///
/// Pops with the saved [CommunityProfile] when the user saves.
class CommunityProfileScreen extends StatefulWidget {
  const CommunityProfileScreen({
    super.key,
    this.existing,
    this.controller,
    this.onSaved,
  });

  /// Set when editing.
  final CommunityProfile? existing;

  /// For tests: a controller with a fake store.
  @visibleForTesting
  final CommunityProfileController? controller;

  /// Called after saving. When null the screen pops with the profile.
  final ValueChanged<CommunityProfile>? onSaved;

  @override
  State<CommunityProfileScreen> createState() => _CommunityProfileScreenState();
}

class _CommunityProfileScreenState extends State<CommunityProfileScreen> {
  late final TextEditingController _name;
  late final TextEditingController _bio;
  late String _avatar;
  bool _saving = false;
  CommunityInputError? _nameError;
  CommunityInputError? _bioError;

  CommunityProfileController get _controller =>
      widget.controller ?? CommunityProfileService.instance;

  bool get _editing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.pseudonym ?? '');
    _bio = TextEditingController(text: e?.bio ?? '');
    _avatar = CommunityAvatars.safe(e?.avatar);
  }

  @override
  void dispose() {
    _name.dispose();
    _bio.dispose();
    super.dispose();
  }

  String _message(AppLocalizations l10n, CommunityInputError e) {
    return switch (e) {
      CommunityInputError.empty => l10n.communityErrEmpty,
      CommunityInputError.tooShort => l10n.communityErrTooShort,
      CommunityInputError.tooLong => l10n.communityErrTooLong,
      CommunityInputError.badCharacters => l10n.communityErrChars,
      CommunityInputError.containsContact => l10n.communityErrContact,
      CommunityInputError.inappropriate => l10n.communityErrInappropriate,
    };
  }

  Future<void> _save() async {
    if (_saving) return;
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    // Check on the phone first so the user sees a clear message.
    final nameError = CommunityValidator.pseudonym(_name.text);
    final bioError = CommunityValidator.bio(_bio.text);
    setState(() {
      _nameError = nameError;
      _bioError = bioError;
    });
    if (nameError != null || bioError != null) return;

    setState(() => _saving = true);
    try {
      final saved = await _controller.save(
        pseudonym: _name.text,
        avatar: _avatar,
        bio: _bio.text,
      );
      if (!mounted) return;
      if (widget.onSaved != null) {
        widget.onSaved!(saved);
      } else {
        navigator.pop(saved);
      }
    } on CommunityInputException catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        if (e.field == CommunityField.pseudonym) {
          _nameError = e.error;
        } else {
          _bioError = e.error;
        }
      });
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.communitySaveFailed)));
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.permissionsHeader,
        foregroundColor: AppColors.surface,
        title: Text(
          _editing ? l10n.communityEditTitle : l10n.communityCreateTitle,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _privacyNote(l10n.communityPrivacyNote),
                        const SizedBox(height: 20),
                        Center(
                          child: CommunityAvatar(avatarKey: _avatar, size: 72),
                        ),
                        const SizedBox(height: 16),
                        _label(l10n.communityAvatarLabel),
                        const SizedBox(height: 8),
                        _avatarPicker(),
                        const SizedBox(height: 20),
                        _label(l10n.communityPseudonymLabel),
                        const SizedBox(height: 8),
                        TextField(
                          key: const Key('community-name'),
                          controller: _name,
                          enabled: !_saving,
                          maxLength: CommunityLimits.pseudonymMax,
                          autocorrect: false,
                          textInputAction: TextInputAction.next,
                          decoration: _decoration(
                            hint: l10n.communityPseudonymHint,
                            error: _nameError == null
                                ? null
                                : _message(l10n, _nameError!),
                          ),
                          onChanged: (_) {
                            if (_nameError != null) {
                              setState(() => _nameError = null);
                            }
                          },
                        ),
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: TextButton.icon(
                            key: const Key('community-suggest'),
                            onPressed: _saving
                                ? null
                                : () => setState(() {
                                    _name.text =
                                        CommunityNameSuggester.suggest();
                                    _nameError = null;
                                  }),
                            icon: const Icon(Icons.casino_outlined, size: 18),
                            label: Text(l10n.communitySuggest),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _label(l10n.communityBioLabel),
                        const SizedBox(height: 8),
                        TextField(
                          key: const Key('community-bio'),
                          controller: _bio,
                          enabled: !_saving,
                          maxLength: CommunityLimits.bioMax,
                          maxLines: 3,
                          decoration: _decoration(
                            error: _bioError == null
                                ? null
                                : _message(l10n, _bioError!),
                          ),
                          onChanged: (_) {
                            if (_bioError != null) {
                              setState(() => _bioError = null);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                  child: ElevatedButton(
                    key: const Key('community-save'),
                    onPressed: _saving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.permissionsGreen,
                      foregroundColor: AppColors.surface,
                      minimumSize: const Size.fromHeight(52),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.surface,
                            ),
                          )
                        : Text(
                            _editing ? l10n.communitySave : l10n.communityJoin,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _avatarPicker() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final key in CommunityAvatars.keys)
          GestureDetector(
            key: Key('community-avatar-$key'),
            onTap: _saving ? null : () => setState(() => _avatar = key),
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  width: 2,
                  color: key == _avatar
                      ? AppColors.permissionsGreen
                      : Colors.transparent,
                ),
              ),
              child: CommunityAvatar(avatarKey: key, size: 40),
            ),
          ),
      ],
    );
  }

  InputDecoration _decoration({String? hint, String? error}) {
    return InputDecoration(
      hintText: hint,
      errorText: error,
      errorMaxLines: 3,
      filled: true,
      fillColor: AppColors.surface,
      border: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(10)),
      ),
    );
  }

  Widget _label(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w700,
      color: AppColors.permissionsHeader,
    ),
  );

  Widget _privacyNote(String text) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.shield_outlined,
            size: 22,
            color: AppColors.permissionsGreen,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                height: 1.35,
                color: AppColors.permissionsSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
