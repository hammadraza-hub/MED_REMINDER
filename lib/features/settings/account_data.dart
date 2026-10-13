/// ============================================================
/// ACCOUNT DATA — backend-ready
///
/// PURPOSE:
/// Account screen ke linked social sign-in providers ka config.
///
/// Backend: Future mein Firebase Auth se actual linked providers
/// (Google / Apple) aur password meta yahan se feed honge.
///
/// ACTIONS (abhi in-memory):
/// • linkApple        → Apple row ko "Connected" + LINKED bana deta hai
/// ============================================================
library;

enum LinkedProvider { google, apple }

class LinkedAccount {
  const LinkedAccount({
    required this.provider,
    required this.title,
    required this.subtitle,
    required this.linked,
  });

  final LinkedProvider provider;

  final String title;

  final String subtitle;

  /// true → "LINKED" pill, false → "Link" action.
  final bool linked;

  LinkedAccount copyWith({String? subtitle, bool? linked}) {
    return LinkedAccount(
      provider: provider,
      title: title,
      subtitle: subtitle ?? this.subtitle,
      linked: linked ?? this.linked,
    );
  }
}

class AccountData {
  AccountData._();

  /// Security section ke linked sign-in providers.
  static const List<LinkedAccount> linkedAccounts = [
    LinkedAccount(
      provider: LinkedProvider.google,
      title: 'Google Account',
      subtitle: 'Connected',
      linked: true,
    ),
    LinkedAccount(
      provider: LinkedProvider.apple,
      title: 'Apple ID',
      subtitle: 'Not linked',
      linked: false,
    ),
  ];
}
