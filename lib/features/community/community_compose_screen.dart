import 'package:flutter/material.dart';

import '../../core/community/community_models.dart';
import '../../core/community/community_posts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/community_post_service.dart';
import '../../l10n/app_localizations.dart';
import 'community_safety_ui.dart';
import 'community_texts.dart';

/// Write a new post, or edit one of your own. Pops `true` when saved.
/// M19 step 4.
class CommunityComposeScreen extends StatefulWidget {
  const CommunityComposeScreen({
    super.key,
    required this.groupId,
    this.existing,
    this.actions,
  });

  final String groupId;

  /// Set when editing.
  final CommunityFeedPost? existing;

  /// For tests: fake actions.
  @visibleForTesting
  final CommunityPostActions? actions;

  @override
  State<CommunityComposeScreen> createState() => _CommunityComposeScreenState();
}

class _CommunityComposeScreenState extends State<CommunityComposeScreen> {
  late final TextEditingController _text;
  bool _saving = false;
  String? _error;

  CommunityPostActions get _actions =>
      widget.actions ?? CommunityPostService.actions;

  bool get _editing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _text = TextEditingController(text: widget.existing?.body ?? '');
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    final l10n = AppLocalizations.of(context);
    final navigator = Navigator.of(context);
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final done = await submitWithWarnings(context, (confirmed) async {
        if (_editing) {
          await _actions.editPost(
            widget.existing!,
            _text.text,
            confirmed: confirmed,
          );
        } else {
          await _actions.createPost(
            widget.groupId,
            _text.text,
            confirmed: confirmed,
          );
        }
      });
      if (!mounted) return;
      if (done) {
        navigator.pop(true);
      } else {
        setState(() => _saving = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = communityActionError(l10n, e);
      });
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
          _editing ? l10n.communityEditPost : l10n.communityNewPost,
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
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: const BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.health_and_safety_outlined,
                                size: 22,
                                color: AppColors.permissionsGreen,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  l10n.communityPostSafety,
                                  key: const Key('compose-safety'),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    height: 1.35,
                                    color: AppColors.permissionsSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          key: const Key('compose-text'),
                          controller: _text,
                          enabled: !_saving,
                          autofocus: true,
                          minLines: 6,
                          maxLines: 12,
                          maxLength: CommunityLimits.postBodyMax,
                          decoration: InputDecoration(
                            hintText: l10n.communityPostHint,
                            errorText: _error,
                            errorMaxLines: 3,
                            filled: true,
                            fillColor: AppColors.surface,
                            border: const OutlineInputBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(10),
                              ),
                            ),
                          ),
                          onChanged: (_) {
                            if (_error != null) setState(() => _error = null);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                  child: ElevatedButton(
                    key: const Key('compose-save'),
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
                            _editing
                                ? l10n.communitySave
                                : l10n.communityPostButton,
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
}
