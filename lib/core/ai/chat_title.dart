import 'ai_text_scrubber.dart';
import 'chat_models.dart';

/// Makes a thread title from the first question. M18 step 4.
///
/// The first few words, cleaned of phone numbers / emails / links (a title is
/// shown in the history list and stored), cut to a readable length. Smarter
/// titles from a model come after Blaze.
class ChatTitle {
  ChatTitle._();

  static const int maxWords = 7;
  static const int maxLength = 50;
  static const String fallback = 'New chat';

  static String fromQuestion(String? question) {
    final cleaned = AiTextScrubber.clean(question, maxLength: 200);
    if (cleaned == null) return fallback;

    final words = cleaned.split(' ').where((w) => w.isNotEmpty).toList();
    var title = words.take(maxWords).join(' ');

    // Drop a trailing "?" and similar for a calmer title.
    title = title.replaceAll(RegExp(r'[\s?!.,:;]+$'), '');
    if (title.isEmpty) return fallback;

    if (title.length > maxLength) {
      title = '${title.substring(0, maxLength - 1).trimRight()}…';
    }
    return title.length > ChatLimits.maxTitleLength
        ? title.substring(0, ChatLimits.maxTitleLength)
        : title;
  }
}
