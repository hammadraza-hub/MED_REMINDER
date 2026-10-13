import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../widgets/app_avatar.dart';
import 'community_data.dart';

/// ============================================================
/// COMMUNITY — condition-based group feed
///
/// PURPOSE:
/// User ke followed condition groups ke posts browse karna.
///
/// DATA:
/// UI → CommunityData (in-memory, backend-ready)
///
/// TODO Local Storage / Backend:
/// Firestore community_posts collection:
/// { id, authorId, authorName, group, body, imageUrl,
///   upvotes, commentCount, createdAt }
///
/// ACTIONS:
/// • Group filter tabs        → feed filter
/// • Upvote / bookmark tap    → in-memory toggle
/// • Tap post                 → Post Detail (pending)
/// • "+ Create Post"          → Create Post (pending)
///
/// COLORS:
/// Sirf AppColors — koi hardcoded hex nahi.
/// Action button standard green (formAccent) — app convention.
/// ============================================================
class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  String _selectedGroup = CommunityData.groupFilters.first;

  List<CommunityPost> _posts = [];

  @override
  void initState() {
    super.initState();

    _reload();
  }

  // ============================================================
  // DATA
  // ============================================================

  void _reload() {
    _posts = CommunityData.posts(group: _selectedGroup);
  }

  void _selectGroup(String group) {
    if (group == _selectedGroup) {
      return;
    }

    setState(() {
      _selectedGroup = group;
      _reload();
    });
  }

  // ============================================================
  // ACTIONS
  // ============================================================

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _toggleUpvote(String id) {
    setState(() {
      CommunityData.toggleUpvote(id);
      _reload();
    });
  }

  void _toggleBookmark(String id) {
    setState(() {
      CommunityData.toggleBookmark(id);
      _reload();
    });
  }

  void _openPost(CommunityPost post) {
    // TODO: Post Detail screen — reference UI pending.
    _showMessage('${post.authorName}\'s post — coming soon');
  }

  void _createPost() {
    // TODO: Create Post screen — reference UI pending.
    _showMessage('Create Post — coming soon');
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: _buildContent(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DARK HEADER
  // ============================================================

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      color: AppColors.permissionsHeader,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 6, 16, 0),
          child: Row(
            children: [
              IconButton(
                onPressed: () {
                  Navigator.of(context).maybePop();
                },
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: AppColors.surface,
                  size: 24,
                ),
              ),

              const Expanded(
                child: Text(
                  'Community',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.surface,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              const AppAvatar(
                size: 33,
                ringColor: AppColors.surface,
                ringWidth: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // CONTENT
  // ============================================================

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildFilterTabs(),

          const SizedBox(height: 12),

          _buildCreateButton(),

          const SizedBox(height: 12),

          if (_posts.isEmpty)
            _buildEmptyState()
          else
            ..._posts.map(
              (post) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildPostCard(post),
              ),
            ),

          const SizedBox(height: 6),

          _buildHomeIndicator(),
        ],
      ),
    );
  }

  // ============================================================
  // GROUP FILTER TABS
  // ============================================================

  Widget _buildFilterTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final group in CommunityData.groupFilters)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildFilterChip(group),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final selected = _selectedGroup == label;

    return GestureDetector(
      onTap: () {
        _selectGroup(label);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.permissionsHeader : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [
            BoxShadow(
              color: AppColors.permissionsCardShadow,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected
                ? AppColors.surface
                : AppColors.permissionsSecondary,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // CREATE POST BUTTON
  // ============================================================

  Widget _buildCreateButton() {
    return GestureDetector(
      onTap: _createPost,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.formAccent,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shareButtonShadow,
              blurRadius: 20,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_rounded, size: 22, color: AppColors.surface),
            SizedBox(width: 8),
            Text(
              'Create Post',
              style: TextStyle(
                color: AppColors.surface,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // POST CARD
  // ============================================================

  Widget _buildPostCard(CommunityPost post) {
    return GestureDetector(
      onTap: () {
        _openPost(post);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
              color: AppColors.permissionsCardShadow,
              blurRadius: 16,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPostHeader(post),

            const SizedBox(height: 10),

            Text(
              post.body,
              style: const TextStyle(
                color: AppColors.reportPrimary,
                fontSize: 13,
                height: 1.5,
              ),
            ),

            if (post.imageUrl != null) ...[
              const SizedBox(height: 10),
              _buildPostImage(post.imageUrl!),
            ],

            const SizedBox(height: 12),

            _buildPostFooter(post),
          ],
        ),
      ),
    );
  }

  Widget _buildPostHeader(CommunityPost post) {
    return Row(
      children: [
        _buildAvatar(post),

        const SizedBox(width: 10),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                post.authorName,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.reportPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 1),

              Text(
                _groupSubtitle(post),
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.permissionsSecondary,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),

        GestureDetector(
          onTap: () {
            _toggleBookmark(post.id);
          },
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: Icon(
              post.isBookmarked
                  ? Icons.bookmark_rounded
                  : Icons.bookmark_border_rounded,
              size: 20,
              color: post.isBookmarked
                  ? AppColors.interactionWarningAmber
                  : AppColors.permissionsSecondary,
            ),
          ),
        ),
      ],
    );
  }

  String _groupSubtitle(CommunityPost post) {
    if (post.group == 'General') {
      return '${post.group} · ${post.timeAgo}';
    }

    return '${post.group} group · ${post.timeAgo}';
  }

  Widget _buildAvatar(CommunityPost post) {
    final fallback = Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      color: AppColors.permissionsChipFill,
      child: Text(
        post.authorName.isNotEmpty
            ? post.authorName[0].toUpperCase()
            : '?',
        style: const TextStyle(
          color: AppColors.permissionsSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    );

    return ClipOval(
      child: SizedBox(
        width: 36,
        height: 36,
        child: post.authorImageUrl == null
            ? fallback
            : Image.network(
                post.authorImageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => fallback,
                loadingBuilder: (context, child, progress) {
                  return progress == null ? child : fallback;
                },
              ),
      ),
    );
  }

  Widget _buildPostImage(String url) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        url,
        width: double.infinity,
        height: 140,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(),
        loadingBuilder: (context, child, progress) {
          return progress == null ? child : _buildImagePlaceholder();
        },
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      width: double.infinity,
      height: 140,
      alignment: Alignment.center,
      color: AppColors.permissionsChipFill,
      child: const Icon(
        Icons.image_outlined,
        size: 30,
        color: AppColors.fieldHint,
      ),
    );
  }

  Widget _buildPostFooter(CommunityPost post) {
    return Row(
      children: [
        _buildUpvoteButton(post),

        const SizedBox(width: 16),

        _buildCommentButton(post),

        const Spacer(),

        _buildGroupTag(post.group),
      ],
    );
  }

  Widget _buildUpvoteButton(CommunityPost post) {
    final color = post.isUpvoted
        ? AppColors.formAccent
        : AppColors.permissionsSecondary;

    return GestureDetector(
      onTap: () {
        _toggleUpvote(post.id);
      },
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.arrow_upward_rounded, size: 16, color: color),

            const SizedBox(width: 6),

            Text(
              '${post.upvotes}',
              style: TextStyle(
                color: post.isUpvoted
                    ? AppColors.formAccent
                    : AppColors.reportPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentButton(CommunityPost post) {
    return GestureDetector(
      onTap: () {
        _openPost(post);
      },
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.chat_bubble_outline_rounded,
              size: 15,
              color: AppColors.permissionsSecondary,
            ),

            const SizedBox(width: 6),

            Text(
              '${post.comments}',
              style: const TextStyle(
                color: AppColors.permissionsSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupTag(String group) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.permissionsChipFill,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        group,
        style: const TextStyle(
          color: AppColors.permissionsSecondary,
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    return Container(
      height: 160,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(
            Icons.forum_outlined,
            color: AppColors.fieldHint,
            size: 44,
          ),

          SizedBox(height: 10),

          Text(
            'No posts in this group yet',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HOME INDICATOR
  // ============================================================

  Widget _buildHomeIndicator() {
    return Center(
      child: Container(
        width: 128,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.reportChipHigh,
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}
