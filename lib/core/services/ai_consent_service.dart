import '../../repositories/firestore_ai_consent_store.dart';
import '../ai/ai_consent.dart';

/// The app's single [AiConsentController]. M18 step 1.
class AiConsentService {
  AiConsentService._();

  static final AiConsentController instance = AiConsentController(
    FirestoreAiConsentStore(),
  );
}
