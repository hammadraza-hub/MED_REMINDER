/// Small helpers for the Home and vitals screens.
///
/// (The made-up members, doses and models that used to live here were dead
/// code since Home moved to Firestore; removed in the Home optimisation.)
library;

class HomeData {
  // ================= USER PROFILE IMAGE =================
  /// null = icon. Backend: FirebaseAuth.instance.currentUser?.photoURL
  static String? userProfileImage() => null;

  // ================= GREETING — by time of day =================
  //
  // Returns only the bucket; the text comes from AppLocalizations in the UI.
  static String greetingBucket() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'morning';
    if (hour < 17) return 'afternoon';
    return 'evening';
  }
}
