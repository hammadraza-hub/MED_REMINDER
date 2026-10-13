/// ============================================================
/// COMMUNITY DATA — backend-ready
///
/// Backend: Firestore community_posts collection — UI zero change!
///
/// Firestore document shape (future):
/// {
///   id, authorId, authorName, authorImageUrl,
///   group, body, imageUrl,
///   upvotes, commentCount, createdAt
/// }
///
/// GROUPS:
/// Condition-based community groups (Diabetes / Hypertension /
/// General). Filter tabs "All" + groups dikhati hain.
///
/// ACTIONS (abhi in-memory):
/// • toggleUpvote   → upvotes count +/- 1
/// • toggleBookmark  → saved flag
/// ============================================================
library;

class CommunityPost {
  const CommunityPost({
    required this.id,
    required this.authorName,
    required this.group,
    required this.timeAgo,
    required this.body,
    required this.upvotes,
    required this.comments,
    this.authorImageUrl,
    this.imageUrl,
    this.isUpvoted = false,
    this.isBookmarked = false,
  });

  final String id;

  /// Example: Maria_G, DavidK, Sarah_22
  final String authorName;

  final String? authorImageUrl;

  /// Example: Diabetes, Hypertension, General
  final String group;

  /// Already-formatted relative label, e.g. "2h ago".
  final String timeAgo;

  final String body;

  /// Optional post photo.
  final String? imageUrl;

  final int upvotes;
  final int comments;

  final bool isUpvoted;
  final bool isBookmarked;

  CommunityPost copyWith({
    int? upvotes,
    bool? isUpvoted,
    bool? isBookmarked,
  }) {
    return CommunityPost(
      id: id,
      authorName: authorName,
      authorImageUrl: authorImageUrl,
      group: group,
      timeAgo: timeAgo,
      body: body,
      imageUrl: imageUrl,
      upvotes: upvotes ?? this.upvotes,
      comments: comments,
      isUpvoted: isUpvoted ?? this.isUpvoted,
      isBookmarked: isBookmarked ?? this.isBookmarked,
    );
  }
}

/// ============================================================
/// DATA PROVIDER — abhi in-memory, backend Firestore
/// ============================================================
class CommunityData {
  /// Filter tabs — "All" + condition groups.
  static const List<String> groupFilters = [
    'All',
    'Diabetes',
    'Hypertension',
    'General',
  ];

  static final List<CommunityPost> _posts = _demoPosts();

  /// Backend: community_posts collection filtered by group
  static List<CommunityPost> posts({String group = 'All'}) {
    if (group == 'All') {
      return List.unmodifiable(_posts);
    }

    return List.unmodifiable(
      _posts.where((post) => post.group == group),
    );
  }

  /// Upvote toggle — count bhi adjust hota hai.
  static void toggleUpvote(String id) {
    final index = _posts.indexWhere((post) => post.id == id);

    if (index == -1) {
      return;
    }

    final post = _posts[index];

    _posts[index] = post.copyWith(
      isUpvoted: !post.isUpvoted,
      upvotes: post.isUpvoted ? post.upvotes - 1 : post.upvotes + 1,
    );
  }

  /// Bookmark/save toggle.
  static void toggleBookmark(String id) {
    final index = _posts.indexWhere((post) => post.id == id);

    if (index == -1) {
      return;
    }

    final post = _posts[index];

    _posts[index] = post.copyWith(isBookmarked: !post.isBookmarked);
  }

  /// Demo posts (design mock + group variety).
  static List<CommunityPost> _demoPosts() {
    return const [
      CommunityPost(
        id: 'cp_maria_metformin',
        authorName: 'Maria_G',
        authorImageUrl:
            'https://lh3.googleusercontent.com/aida/AEtjO1UzTT_2tFuf-2tDSpv9lQkGfRNQcCwhBum3WwNSr5gjW1Js4_Z0qoTYIiYhGdBRiPuDcbM7XisQJiqEPgKvpzk40xMXMkaY04rtqrB5Zdd-gz8REwsoDFD3KyxIOKMl3T6letV8WXFJz5M3mrT1wyHmScAME62yidDVXH8Up53EbDhfuxyAqvIg91EBSOsJIcJbu-zscOEPB_emQ2MUhwOLpnV5LYHxhcpK-FWv_NMUx6Di7wtlPvfCC14E',
        group: 'Diabetes',
        timeAgo: '2h ago',
        body:
            'Switched to taking Metformin right after dinner instead of '
            'breakfast — evening readings improved a lot. Anyone else tried '
            'changing timing?',
        imageUrl:
            'https://lh3.googleusercontent.com/aida-public/AB6AXuDbjFi1MWkU7FV6nm6bDqMzbSwHPTMgYQjqS8XCo1_AJJcOzkFPy8esU4gMtxpRzw-0EnQyS8W8p5NS3zahAOfVpSXRVhSfH535_u-tY3RLD83FNI7yPlQQoxkdlHjGp4CaOq_MZqRfldI-Ik0nqAbM0BdFtVrFw0cFzMpz_H5wl2YPNXGqDU8rfS1epf4aiszkOZPoeWv3gyNmEbW2ZmB6zKYL0jRZZMWOLGu_8A8JKKAaSNv5C3G1RQ',
        upvotes: 24,
        comments: 8,
        isUpvoted: true,
      ),
      CommunityPost(
        id: 'cp_david_amlodipine',
        authorName: 'DavidK',
        authorImageUrl:
            'https://lh3.googleusercontent.com/aida/AEtjO1Ve4Uqav1U2dwh9XMsfi84F8iCDKf1c-TyPpnAn2gZaJJ6ASl6lH52elL8eH7ekG-b50wvNlijhWQoq8My11ojtZxY8yJFQ7QhkJsxPfB3yWBvu6Avnj4-o7dX2LacVBbATGqF4LOP-Me7IcQD0Cb0paGapU7jwO0TBnv7JN7EOWU8gOeXXCDnNTBVLvbLptnf-cjhv48lGzrmy3FnCkzTWxAzEbYNcOoagHJmgA_JG2lxO6VbjxgvNIx4',
        group: 'Hypertension',
        timeAgo: '5h ago',
        body:
            'My doctor lowered my Amlodipine dose after 3 months of stable '
            'readings. Feels good to see progress!',
        upvotes: 17,
        comments: 5,
      ),
      CommunityPost(
        id: 'cp_sarah_organizer',
        authorName: 'Sarah_22',
        authorImageUrl:
            'https://lh3.googleusercontent.com/aida/AEtjO1XohiTB2HgIwLqoO7eO68dGM4cg-b9QZZKoJ9VDU1CAlceHNFtL92f8b2tWNqkB-gPtH2ZWhagjX-9imaDHSlZVtvdMRaDrBrA65ko1Kw1r9H9NDGKWBrQOl8VnVPlRfgGo1YWrdBHvfXx-uSAWoDPgvpFmstDTEfjMFHib7CgxtfB7vAgPWbk7wGkhrWTWj3E5v1uBjdfzM8aw-rX_oFcdtrAT4a3EUnepbXCTAGXcPKUmIp6MMa78w6I',
        group: 'General',
        timeAgo: '1d ago',
        body:
            'Tip: I keep a small pill organizer in my bag for busy days. '
            'Saved me twice this month.',
        upvotes: 41,
        comments: 12,
        isBookmarked: true,
      ),
      CommunityPost(
        id: 'cp_raj_glucose',
        authorName: 'RajP',
        group: 'Diabetes',
        timeAgo: '3h ago',
        body:
            'Does anyone check glucose before vs after their evening dose? '
            'My morning fasting numbers look different on the days I test late.',
        upvotes: 9,
        comments: 3,
      ),
      CommunityPost(
        id: 'cp_emily_refill',
        authorName: 'EmilyS',
        group: 'General',
        timeAgo: '6h ago',
        body:
            'Reminder: refill your pill boxes on Sunday evenings. Makes the '
            'whole week stress-free and you never miss a dose.',
        upvotes: 6,
        comments: 2,
      ),
    ];
  }
}
