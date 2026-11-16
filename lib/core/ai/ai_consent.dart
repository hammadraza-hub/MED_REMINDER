import 'package:flutter/foundation.dart';

/// AI assistant consent. M18 step 1.
///
/// The assistant may only be used after the user has said yes
/// (`users/{uid}.aiConsentAt` is set to the server time). Withdrawing sets it
/// back to null. Everything is injected, so the rules are unit-testable.

enum AiConsentStatus {
  /// Not read yet.
  unknown,

  /// No consent (never given, withdrawn, or it could not be checked).
  notGiven,

  /// The user agreed.
  given,
}

/// Where the consent time lives (Firestore in the app).
abstract class AiConsentStore {
  /// When consent was given, or null when it was not.
  Future<DateTime?> read();

  /// Saves consent with the server time.
  Future<void> grant();

  /// Removes consent.
  Future<void> withdraw();
}

class AiConsentController {
  AiConsentController(this._store);

  final AiConsentStore _store;

  final ValueNotifier<AiConsentStatus> status = ValueNotifier(
    AiConsentStatus.unknown,
  );

  bool get isGiven => status.value == AiConsentStatus.given;

  /// Reads the saved consent. Fails CLOSED: if it cannot be read, the answer
  /// is "not given", so the assistant stays shut until it can be checked.
  Future<AiConsentStatus> refresh() async {
    try {
      final at = await _store.read();
      status.value = at == null
          ? AiConsentStatus.notGiven
          : AiConsentStatus.given;
    } catch (e) {
      debugPrint('AiConsentController.refresh failed — $e');
      status.value = AiConsentStatus.notGiven;
    }
    return status.value;
  }

  /// The gate: true when the assistant may be used right now. Always reads
  /// again, so a different account on the same phone never inherits consent.
  Future<bool> ensure() async => await refresh() == AiConsentStatus.given;

  /// The user agreed. Throws when it cannot be saved (the screen shows it);
  /// the status is then unchanged.
  Future<void> grant() async {
    await _store.grant();
    status.value = AiConsentStatus.given;
  }

  /// The user takes consent back. Throws when it cannot be saved.
  Future<void> withdraw() async {
    await _store.withdraw();
    status.value = AiConsentStatus.notGiven;
  }

  /// Forget everything (sign-out).
  void reset() => status.value = AiConsentStatus.unknown;
}
