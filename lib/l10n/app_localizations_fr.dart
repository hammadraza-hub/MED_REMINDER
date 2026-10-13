// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String comingSoon(String title) {
    return '$title — bientôt disponible';
  }

  @override
  String get cancel => 'Annuler';

  @override
  String get navHome => 'Accueil';

  @override
  String get navMeds => 'Médicaments';

  @override
  String get navCalendar => 'Calendrier';

  @override
  String get navReports => 'Rapports';

  @override
  String get navSettings => 'Réglages';

  @override
  String get settingsTitle => 'Réglages';

  @override
  String get settingsGroupPreferences => 'Préférences';

  @override
  String get settingsGroupAccountPlan => 'Compte et offre';

  @override
  String get settingsGroupSupportLegal => 'Assistance et légal';

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get settingsNotificationsTrailing => 'Sonnerie et vibration';

  @override
  String get settingsLanguage => 'Langue';

  @override
  String get settingsLanguageTrailing => 'Français';

  @override
  String get settingsAccessibility => 'Accessibilité';

  @override
  String get settingsPrivacySecurity => 'Confidentialité et sécurité';

  @override
  String get settingsSubscription => 'Abonnement';

  @override
  String get settingsDataExport => 'Exportation des données';

  @override
  String get settingsDataExportTrailing => 'CSV et PDF';

  @override
  String get settingsHelpSupport => 'Aide et assistance';

  @override
  String get settingsAbout => 'À propos';

  @override
  String get settingsAboutTrailing => 'v1.2.0';

  @override
  String get settingsPro => 'PRO';

  @override
  String get settingsCaregiverSync => 'Synchronisation active';

  @override
  String get settingsLogoutTitle => 'Se déconnecter ?';

  @override
  String get settingsLogoutMessage =>
      'Vous devrez vous reconnecter pour accéder à votre plan de soins.';

  @override
  String get settingsLogOut => 'Se déconnecter';

  @override
  String get settingsLogoutComingSoon => 'Déconnexion — bientôt disponible';

  @override
  String get settingsFooterVersion =>
      'MedRemind Care Health Suite • v1.2.0 (Build 412)';

  @override
  String get settingsHipaa => 'Conforme HIPAA et chiffré';

  @override
  String get languageTitle => 'Langue';

  @override
  String get languageNote =>
      'L\'application se met à jour instantanément après avoir choisi une langue.';

  @override
  String get languageDeviceDefault =>
      'Par défaut de l\'appareil : langue du système (English - US)';

  @override
  String get homeGreetingMorning => 'Bonjour';

  @override
  String get homeGreetingAfternoon => 'Bon après-midi';

  @override
  String get homeGreetingEvening => 'Bonsoir';

  @override
  String homeGreetingWithName(String greeting, String name) {
    return '$greeting, $name 👋';
  }

  @override
  String homeDayStreak(int days) {
    return 'Série de $days jours';
  }

  @override
  String get homeAdd => 'Ajouter';

  @override
  String get homeTodaySchedule => 'Programme du jour';

  @override
  String get homeFilterAll => 'Toutes';

  @override
  String get homeFilterPending => 'En attente';

  @override
  String get homeFilterTaken => 'Prises';

  @override
  String get homeDaily => 'Quotidien';

  @override
  String homeStatTaken(int count) {
    return '$count prises';
  }

  @override
  String homeStatPending(int count) {
    return '$count en attente';
  }

  @override
  String homeStatMissed(int count) {
    return '$count manquées';
  }

  @override
  String get homeQuickAccess => 'ACCÈS RAPIDE';

  @override
  String get homeShortcuts => 'Raccourcis';

  @override
  String get homeQuickVitals => 'Constantes';

  @override
  String get homeQuickDoctors => 'Médecins';

  @override
  String get homeQuickAI => 'IA Assist';

  @override
  String get homeQuickFamily => 'Famille';

  @override
  String homeScreenComingSoon(String name) {
    return 'L\'écran $name arrive bientôt.';
  }

  @override
  String homeMarkedTaken(String name) {
    return '$name marquée comme prise ✓';
  }

  @override
  String homeMarkedUntaken(String name) {
    return '$name marquée comme non prise 🔄';
  }

  @override
  String homeSkipped(String name) {
    return '$name ignorée';
  }

  @override
  String homeSkippedReason(String name, String reason) {
    return '$name ignorée — $reason';
  }

  @override
  String homeSnoozed(String name, int minutes) {
    return '$name reportée — rappel de nouveau dans $minutes min';
  }

  @override
  String homeSwitchedMember(String name) {
    return 'Passé aux médicaments de $name';
  }

  @override
  String get homeActionTaken => 'Prise';

  @override
  String get homeActionSkip => 'Ignorer';

  @override
  String get homeActionSnooze => 'Reporter';

  @override
  String get homeStatusPending => 'EN ATTENTE';

  @override
  String get homeStatusTaken => 'PRISE';

  @override
  String get homeStatusUpcoming => 'À VENIR';

  @override
  String get homeStatusSkipped => 'IGNORÉE';

  @override
  String homeRunningLow(String name, int days) {
    return '$name bientôt épuisée · $days jours restants';
  }

  @override
  String get homeRefill => 'Renouveler →';

  @override
  String get homeSkippedNote => 'Ignorée — le rappel reviendra demain';

  @override
  String get doseFormTablet => 'Comprimé';

  @override
  String get doseFormLiquid => 'Liquide';

  @override
  String get doseScheduleDaily => '1 fois par jour';

  @override
  String get doseScheduleBeforeBreakfast => 'Avant le petit-déjeuner';

  @override
  String get doseScheduleAfterBreakfast => 'Après le petit-déjeuner';

  @override
  String get doseScheduleWithDinner => 'Au dîner';

  @override
  String doseDueSoon(String time) {
    return '$time · Bientôt';
  }

  @override
  String get doseMarkTaken => 'Marquer comme prise';

  @override
  String get doseMarkUntaken => 'Marquer comme non prise';

  @override
  String get doseHideReason => 'Masquer la raison';

  @override
  String get doseSkipDose => 'Ignorer la dose';

  @override
  String get doseSnoozeFor => 'REPORTER POUR';

  @override
  String get doseReasonLabel => 'Raison (facultatif)';

  @override
  String get doseReasonHint => 'ex. : Nausées';

  @override
  String get doseConfirmSkip => 'Confirmer l\'omission';

  @override
  String get dataExportTitle => 'Exportation des données';

  @override
  String get dataExportHeroTitle => 'Exporter toutes mes données';

  @override
  String get dataExportHeroSubtitle =>
      'Obtenez une copie complète de tout ce qui est stocké dans votre compte.';

  @override
  String get dataExportBadge => 'Export chiffré conforme GDPR et HIPAA';

  @override
  String get dataExportIncludedTitle => 'Ce qui est inclus';

  @override
  String get dataExportModules => '4 modules';

  @override
  String get dataExportIncludedProfiles => 'Tous les profils et médicaments';

  @override
  String get dataExportIncludedDoses =>
      'Historique complet des doses et de l\'observance';

  @override
  String get dataExportIncludedVitals => 'Signes vitaux, symptômes et notes';

  @override
  String get dataExportIncludedPrescribers =>
      'Médecins, rendez-vous et pharmacies';

  @override
  String dataExportFormatNote(String formats) {
    return 'Vous recevrez une archive ZIP ($formats) par e-mail sous 24 heures.';
  }

  @override
  String get dataExportFormats => 'JSON + CSV';

  @override
  String dataExportSentTo(String email) {
    return 'Envoyé directement à $email';
  }

  @override
  String get dataExportRequest => 'Demander l\'exportation';

  @override
  String get dataExportGenerating => 'Génération du paquet...';

  @override
  String get dataExportSubmitted => 'Demande envoyée';

  @override
  String get dataExportSuccessTitle => 'Exportation demandée !';

  @override
  String get dataExportSuccessMessage =>
      'Nous préparons votre archive de données brutes. Vous recevrez un lien direct dès la fin de la compilation.';

  @override
  String get dataExportQueued => 'En file d\'attente sur le serveur';

  @override
  String get dataExportLastExportNever => 'Dernière exportation : Jamais';

  @override
  String dataExportLastExportNow(String timestamp) {
    return 'Dernière exportation : À l\'instant ($timestamp)';
  }

  @override
  String dataExportRetentionId(String id) {
    return 'ID de conservation des données du compte : $id';
  }

  @override
  String get helpSupportTitle => 'Aide et assistance';

  @override
  String get helpSupportSearchHint => 'Rechercher dans la FAQ...';

  @override
  String get helpSupportNoResults => 'Aucun article correspondant.';

  @override
  String get helpSupportBannerTitle => 'Service aidants et patients';

  @override
  String get helpSupportBannerSubtitle =>
      'Nous sommes là pour maintenir vos routines à l\'heure.';

  @override
  String get helpSupportFaqHeader => 'Questions fréquentes';

  @override
  String helpSupportFaqCount(int count) {
    return '$count articles';
  }

  @override
  String get helpSupportStillNeedHelp => 'Besoin d\'aide ?';

  @override
  String get helpSupportLiveOnline => 'Équipe en ligne';

  @override
  String get helpSupportEmailSupport => 'Assistance par e-mail';

  @override
  String get helpSupportEmailAction => 'E-mail';

  @override
  String get helpSupportSubmitRequest => 'Envoyer une demande';

  @override
  String get helpSupportResponseTime => 'Réponse moyenne en moins de 2 heures';

  @override
  String get helpSupportHelpful => 'Cette page vous a-t-elle aidé ?';

  @override
  String get helpSupportYes => 'Oui';

  @override
  String get helpSupportNo => 'Non';

  @override
  String get helpSupportFeedbackThanks => 'Merci pour votre retour !';

  @override
  String get helpSupportVersion => 'MedRemind v1.2.0 (build 245)';

  @override
  String get helpSupportCompliance =>
      'Réseau d\'aidants chiffré • Conforme HIPAA';

  @override
  String helpSupportEmailClipped(String email) {
    return 'Écrivez-nous à $email';
  }

  @override
  String get faqQ1 => 'Comment modifier l\'heure d\'une dose ?';

  @override
  String get faqA1 =>
      'Ouvrez l\'onglet Planning ou Médicaments, touchez la carte du médicament, sélectionnez Modifier le planning, puis ajustez vos alertes. Les changements se synchronisent instantanément entre les appareils des aidants.';

  @override
  String get faqQ2 => 'Pourquoi n\'ai-je pas reçu de rappel ?';

  @override
  String get faqA2 =>
      'Assurez-vous que l\'optimisation de la batterie est désactivée pour MedRemind dans les Réglages du téléphone. Vérifiez aussi que les Alertes critiques et les autorisations de notification sont accordées dans les réglages de votre système.';

  @override
  String get faqQ3 => 'Comment fonctionnent les alertes des aidants ?';

  @override
  String get faqA3 =>
      'Les aidants reçoivent des confirmations silencieuses lorsque les médicaments sont enregistrés. Si une dose cruciale est manquée pendant plus de 30 minutes, une notification escaladée est automatiquement envoyée à l\'aidant principal.';

  @override
  String get faqQ4 => 'Comment ajouter un membre de la famille ?';

  @override
  String get faqA4 =>
      'Allez dans Profils, touchez Ajouter, puis envoyez une invitation par e-mail ou téléphone. La personne accepte le lien pour se connecter.';

  @override
  String get aboutTitle => 'À propos';

  @override
  String get aboutAppName => 'MedRemind';

  @override
  String get aboutVersion => 'Version 1.2.0 (build 245)';

  @override
  String get aboutUpToDate => 'À JOUR ✓';

  @override
  String get aboutTerms => 'Conditions d\'utilisation';

  @override
  String get aboutPrivacy => 'Politique de confidentialité';

  @override
  String get aboutLicenses => 'Licences open source';

  @override
  String get aboutCredits => 'Crédits';

  @override
  String get aboutCreditsDesign => 'Design';

  @override
  String get aboutCreditsDesignValue => 'Équipe MedRemind';

  @override
  String get aboutCreditsDrugData => 'Données médicamenteuses';

  @override
  String get aboutCreditsDrugDataValue => 'RxNorm · OpenFDA';

  @override
  String get aboutCreditsIcons => 'Icônes';

  @override
  String get aboutCreditsIconsValue => 'Jeux open source';

  @override
  String get aboutFooter =>
      'Conçu avec soin pour les familles qui gèrent leur santé ensemble.';

  @override
  String get aboutLegalBody1 =>
      'MedRemind s\'engage pour une grande précision clinique et un design bienveillant. Nos sources de données respectent strictement les normes publiées par la National Library of Medicine (RxNorm) et la base réglementaire de la FDA.';

  @override
  String get aboutLegalBody2 =>
      'Toutes les heuristiques de reconnaissance de comprimés, les alertes aux aidants et les journaux de dosage restent chiffrés et liés à votre coffre familial désigné. Les paramètres de santé ne sont ni monétisés ni partagés avec des annonceurs tiers.';

  @override
  String get aboutLegalComplianceTitle => 'Conformité et audits';

  @override
  String get aboutLegalComplianceValue =>
      'Certifié SOC-2 Type II · Mesures de sécurité HIPAA · Vérifié 2025';

  @override
  String get aboutDone => 'Terminé';

  @override
  String get upgradeTitle => 'Mettre à niveau';

  @override
  String get upgradePlanStatus => 'Forfait gratuit • Prêt à évoluer';

  @override
  String get upgradeProGated => 'Réservé Pro';

  @override
  String get upgradeHeroTitle => 'Débloquez toute la puissance de MedRemind';

  @override
  String get upgradeHeroSubtitle =>
      'Interactions, renouvellements, rapports et partage familial';

  @override
  String get upgradeUnlockHeader => 'Ce que vous débloquerez';

  @override
  String get upgradeUnlockInteractions =>
      'Vérification des interactions et allergies';

  @override
  String get upgradeUnlockRefills =>
      'Suivi des stocks et alertes de renouvellement';

  @override
  String get upgradeUnlockReports => 'Rapports PDF/CSV pour votre médecin';

  @override
  String get upgradeUnlockFamily => 'Liaison familiale — jusqu\'à 5 profils';

  @override
  String get upgradeSeeComparison => 'Voir la comparaison complète';

  @override
  String get upgradeChoosePlan => 'Choisissez votre forfait';

  @override
  String get upgradeFreeTrial => 'Essai gratuit de 7 jours';

  @override
  String get upgradeMonthly => 'Mensuel';

  @override
  String get upgradeAnnual => 'Annuel';

  @override
  String get upgradeSaveBadge => 'Économisez 52 %';

  @override
  String get upgradePlanSoloName => 'Solo Pro';

  @override
  String get upgradePlanSoloSubtitle => 'Tout pour une personne';

  @override
  String get upgradePlanFamilyName => 'Family Pro';

  @override
  String get upgradePlanFamilySubtitle =>
      'Jusqu\'à 5 profils liés + alertes aux aidants';

  @override
  String get upgradePopular => 'Populaire';

  @override
  String get upgradeSelected => 'Sélectionné';

  @override
  String upgradePriceAnnual(String price) {
    return '$price/an';
  }

  @override
  String upgradePriceMonthly(String price) {
    return '$price/mois';
  }

  @override
  String upgradeWasPrice(String price) {
    return 'avant $price';
  }

  @override
  String get upgradeStartTrial => 'Commencer l\'essai gratuit de 7 jours';

  @override
  String get upgradeNothingDue =>
      'Rien à payer aujourd\'hui. Rappel le 5e jour.';

  @override
  String get upgradeCompareAll => 'Comparer toutes les fonctions et forfaits';

  @override
  String get upgradeRestorePurchase => 'Restaurer l\'achat';

  @override
  String get upgradeLegalNote =>
      'Annulez à tout moment dans les réglages de l\'App Store au moins 24 heures avant la fin de l\'essai. Le forfait se renouvelle automatiquement jusqu\'à annulation.';

  @override
  String get upgradeComparisonTitle => 'Comparaison complète des forfaits';

  @override
  String get upgradeComparisonContinue =>
      'Continuer avec le forfait sélectionné';

  @override
  String get upgradeFeatureReminders => 'Rappels de médicaments';

  @override
  String get upgradeFeatureRemindersValue => 'Gratuit et Pro (Illimité)';

  @override
  String get upgradeFeatureInteractions => 'Vérificateur d\'interactions';

  @override
  String get upgradeFeatureRefills => 'Alertes intelligentes de renouvellement';

  @override
  String get upgradeFeatureReports => 'Exportations santé PDF pour le médecin';

  @override
  String get upgradeFeatureFamily => 'Synchronisation famille et aidants';

  @override
  String get upgradeValuePro => 'Exclusivité Pro';

  @override
  String get upgradeValueFamily => 'Family Pro uniquement';

  @override
  String get upgradeRestoreToast =>
      'Restauration des achats... Aucun abonnement antérieur trouvé.';

  @override
  String upgradeTrialToast(String plan, String cadence) {
    return 'Démarrage de l\'essai de 7 jours pour $plan ($cadence)';
  }

  @override
  String get compareTitle => 'Comparer les forfaits';

  @override
  String get compareGuarantee => 'Garantie satisfait ou remboursé 30 jours';

  @override
  String get compareAnnualSave => 'Économisez 40 % par an';

  @override
  String get compareColFeatures => 'Fonctions';

  @override
  String get compareColFree => 'Gratuit';

  @override
  String get compareFreeSubtitle => 'Débutant';

  @override
  String get compareColSolo => 'Solo';

  @override
  String get compareSoloSubtitle => 'Le plus aimé';

  @override
  String get compareColFamily => 'Famille';

  @override
  String get compareFamilySubtitle => 'Soins complets';

  @override
  String get comparePriceLabel => 'Prix';

  @override
  String get compareBilledYearly => 'Facturé annuellement';

  @override
  String get compareForever => 'pour toujours';

  @override
  String get comparePerYear => '/an';

  @override
  String get compareGroupDaily => 'Outils quotidiens de médicaments';

  @override
  String get compareGroupClinical => 'Sécurité clinique et suivi';

  @override
  String get compareGroupFamily => 'Cercle famille et aidants';

  @override
  String get compareFeatUnlimitedMeds => 'Médicaments et rappels illimités';

  @override
  String get compareFeatAdherence => 'Calendrier d\'observance et séries';

  @override
  String get compareFeatInteractions =>
      'Vérification des interactions et allergies';

  @override
  String get compareFeatInventory => 'Stock et alertes de renouvellement';

  @override
  String get compareFeatDoctorTools => 'Outils médecin et rendez-vous';

  @override
  String get compareFeatReports => 'Rapports santé PDF/CSV';

  @override
  String get compareFeatHealthSync => 'Synchro Apple Health et Fit';

  @override
  String get compareFeatFamilyLinking => 'Liaison familiale (jusqu\'à 5)';

  @override
  String get compareFeatMissedDose => 'Alerte aidant en cas de dose manquée';

  @override
  String get compareFeatFamilyDashboard => 'Tableau de bord familial combiné';

  @override
  String get compareQuote =>
      '« Les alertes aux aidants m\'ont offert une tranquillité d\'esprit totale pour maman. »';

  @override
  String get compareQuoteAuthor => '— Sarah M., abonnée Family Pro';

  @override
  String get compareChooseSolo => 'Choisir Solo Pro';

  @override
  String get compareChooseFamily => 'Choisir Family Pro';

  @override
  String get compareContinueFree => 'Continuer avec le forfait Gratuit de base';

  @override
  String get compareFreeSelected => 'Forfait Gratuit de base sélectionné';

  @override
  String get compareFinePrint =>
      'Prix affichés pour la facturation annuelle. Les forfaits mensuels sont aussi disponibles au paiement. Annulez à tout moment sans souci.';

  @override
  String get compareEncrypted => 'Chiffré 256 bits';

  @override
  String get compareAutoSync => 'Synchro auto';

  @override
  String get compareHipaaReady => 'Compatible HIPAA';

  @override
  String get paymentTitle => 'Paiement réussi';

  @override
  String get paymentProNowTitle => 'Vous êtes maintenant Pro !';

  @override
  String paymentWelcome(String plan, String name) {
    return 'Bienvenue dans $plan, $name. Toutes les fonctions Pro sont débloquées.';
  }

  @override
  String get paymentPlanActive => 'Forfait actif • Synchro de soins illimitée';

  @override
  String get paymentOrderSummary => 'Récapitulatif de commande';

  @override
  String get paymentTrialActive => 'Essai actif';

  @override
  String get paymentPlanLabel => 'Forfait';

  @override
  String get paymentFreeTrialLabel => 'Essai gratuit';

  @override
  String paymentFreeTrialValue(String price) {
    return '7 jours — puis $price';
  }

  @override
  String get paymentNextBillingLabel => 'Prochaine date de facturation';

  @override
  String get paymentReceipt => 'Reçu';

  @override
  String get paymentOrderIdLabel => 'N° de commande';

  @override
  String get paymentPaymentMethodLabel => 'Moyen de paiement';

  @override
  String get paymentReceiptSentLabel => 'Reçu envoyé à';

  @override
  String get paymentViewFullReceipt => 'Voir le reçu complet';

  @override
  String get paymentStartPro => 'Commencer à utiliser Pro';

  @override
  String get paymentUnlockNote =>
      'Les vérifications d\'interactions, alertes de renouvellement et rapports sont désormais actifs';
}
