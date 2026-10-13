/// ============================================================
/// PAYMENT SUCCESS DATA — backend-ready
///
/// PURPOSE:
/// Purchase confirmation screen ka static/demo config — order id,
/// receipt email, payment method.
///
/// IMPORTANT:
/// Display text yahan nahi rakhte — woh AppLocalizations (ARB) se
/// stable id ke through aata hai, taake language change effect ho.
/// Sirf demo values (order id, email, brand name) constant hain.
///
/// TODO Backend:
/// RevenueCat / StoreKit / Play Billing receipt data se ye values
/// aayengi.
/// ============================================================
library;

class PaymentSuccessData {
  PaymentSuccessData._();

  /// Demo user first name (proper noun — localized nahi hota).
  static const String userName = 'Sarah';

  /// Demo order id.
  static const String orderId = 'MRN-2026-08417';

  /// Demo receipt email.
  static const String email = 'sarah.mitchell@email.com';

  /// Payment method brand (proper noun).
  static const String paymentMethod = 'Apple Pay';

  /// Receipt file meta (size demo hai).
  static const String receiptSize = 'PDF • 142 KB';

  /// Free trial duration (days) — next billing date isse calculate hoti hai.
  static const int trialDays = 7;
}
