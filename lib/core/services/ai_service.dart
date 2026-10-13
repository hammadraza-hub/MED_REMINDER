import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// ============================================================
/// AI SERVICE — Google Gemini (REST)
///
/// PURPOSE:
/// Med Assistant Chat ko AI ke saath link karta hai. User ke
/// sawaal ka jawab Gemini se laata hai (conversation history ke
/// saath, taake context bana rahe).
///
/// SECURITY:
/// API key `.env` se aati hai (git mein commit nahi hoti).
///   GEMINI_API_KEY=...
///   GEMINI_MODEL=gemini-2.0-flash   (optional)
///
/// TODO Backend:
/// Jab backend banega to key server pe rakho aur yahan app apne
/// proxy endpoint ko call kare. Sirf is class ke andar badlaav
/// hoga — screens untouched rahengi.
/// ============================================================

/// Ek chat turn — user ya assistant ka message.
class AiChatTurn {
  const AiChatTurn({required this.isUser, required this.text});

  final bool isUser;
  final String text;
}

/// AI call fail hone par throw hone wali error.
class AiServiceException implements Exception {
  const AiServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Gemini REST client.
class AiService {
  AiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const String _defaultModel = 'gemini-3.8-flash';
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';

  /// Med assistant ka behaviour + safety instructions.
  ///
  /// IMPORTANT: Replies short aur to-the-point rahengi. User detail
  /// maange to hi lamba jawab de.
  static const String systemInstruction =
      'You are MedRemind\'s medication assistant. Answer the user\'s '
      'question directly and briefly — 1 to 3 short sentences, or a few '
      'short bullet points. Do NOT write long paragraphs. Get straight to '
      'the point; only expand if the user explicitly asks for more detail. '
      'Use the USER DATA provided to answer about the user\'s own '
      'medications, dose times, refills/inventory and health logs. If the '
      'answer is not in the data, say so briefly. If medication-related, end '
      'with a very short reminder to confirm with their doctor.';

  bool get isConfigured {
    final key = _apiKey;
    return key != null && key.isNotEmpty && key != 'PASTE_YOUR_GEMINI_API_KEY_HERE';
  }

  String? get _apiKey {
    final key = dotenv.maybeGet('GEMINI_API_KEY')?.trim();
    return (key == null || key.isEmpty) ? null : key;
  }

  String get _model {
    final model = dotenv.maybeGet('GEMINI_MODEL')?.trim();
    return (model == null || model.isEmpty) ? _defaultModel : model;
  }

  /// Primary model busy/overloaded (503) ho to inhe order mein try
  /// kiya jayega, taake user ko error na dikhe.
  static const String _fallbackModel = 'gemini-flash-latest';

  List<String> get _modelCandidates {
    final primary = _model;
    if (primary == _fallbackModel) return [primary];
    return [primary, _fallbackModel];
  }

  /// User ke message ka AI reply return karta hai.
  ///
  /// [history] mein pehle ke turns bhejne se AI ko context milta hai.
  /// [context] mein user ka real app data (meds, schedule, refill,
  /// vitals) pass karo taake AI sach-much us data ke hisaab se jawab de.
  Future<String> sendMessage({
    required String message,
    List<AiChatTurn> history = const [],
    String? context,
  }) async {
    final key = _apiKey;
    if (!isConfigured || key == null) {
      throw const AiServiceException(
        'AI is not configured. Add your GEMINI_API_KEY in the .env file.',
      );
    }

    final contents = <Map<String, dynamic>>[
      for (final turn in history)
        {
          'role': turn.isUser ? 'user' : 'model',
          'parts': [
            {'text': turn.text},
          ],
        },
      {
        'role': 'user',
        'parts': [
          {'text': message},
        ],
      },
    ];

    final systemText = (context == null || context.trim().isEmpty)
        ? systemInstruction
        : '$systemInstruction\n\n'
            '--- USER DATA (authoritative, use these exact values) ---\n'
            '${context.trim()}\n'
            '--- END USER DATA ---';

    final body = jsonEncode({
      'systemInstruction': {
        'parts': [
          {'text': systemText},
        ],
      },
      'contents': contents,
      'generationConfig': {
        'temperature': 0.5,
        'maxOutputTokens': 300,
      },
    });

    AiServiceException? lastError;

    for (final model in _modelCandidates) {
      final uri = Uri.parse('$_baseUrl/$model:generateContent?key=$key');

      http.Response response;
      try {
        response = await _client
            .post(
              uri,
              headers: const {'Content-Type': 'application/json'},
              body: body,
            )
            .timeout(const Duration(seconds: 30));
      } catch (_) {
        throw const AiServiceException(
          'Could not reach the AI service. Check your internet connection.',
        );
      }

      if (response.statusCode == 200) {
        return _textFrom(response.body);
      }

      lastError = AiServiceException(_errorFrom(response));

      // Sirf temporary overload par fallback model try karo.
      if (response.statusCode != 503 && response.statusCode != 429) {
        throw lastError;
      }
    }

    throw lastError ??
        const AiServiceException('AI request failed. Please try again.');
  }

  /// Gemini response body se pehla text part nikalta hai.
  String _textFrom(String rawBody) {
    final dynamic decoded = jsonDecode(rawBody);

    if (decoded is! Map<String, dynamic>) {
      throw const AiServiceException('Unexpected AI response.');
    }

    final candidates = decoded['candidates'];
    if (candidates is! List || candidates.isEmpty) {
      throw const AiServiceException(
        'The AI did not return an answer. Please try again.',
      );
    }

    final content = (candidates.first as Map<String, dynamic>)['content'];
    final parts = (content as Map<String, dynamic>?)?['parts'];

    if (parts is! List || parts.isEmpty) {
      throw const AiServiceException(
        'The AI did not return an answer. Please try again.',
      );
    }

    final buffer = StringBuffer();
    for (final part in parts) {
      final text = (part as Map<String, dynamic>)['text'];
      if (text is String && text.trim().isNotEmpty) {
        buffer.write(text);
      }
    }

    final result = buffer.toString().trim();
    if (result.isEmpty) {
      throw const AiServiceException(
        'The AI did not return an answer. Please try again.',
      );
    }

    return result;
  }

  /// Error response se readable message nikalta hai.
  String _errorFrom(http.Response response) {
    if (response.statusCode == 400 || response.statusCode == 403) {
      return 'AI error: invalid or unauthorized API key.';
    }
    if (response.statusCode == 429) {
      return 'AI is busy right now. Please try again in a moment.';
    }
    if (response.statusCode == 503) {
      return 'AI is temporarily overloaded. Please try again shortly.';
    }

    try {
      final decoded = jsonDecode(response.body);
      final error = (decoded as Map<String, dynamic>)['error'];
      final message = (error as Map<String, dynamic>?)?['message'];
      if (message is String && message.trim().isNotEmpty) {
        return 'AI error: $message';
      }
    } catch (_) {
      // Fall through to generic message.
    }

    return 'AI request failed (${response.statusCode}).';
  }
}
