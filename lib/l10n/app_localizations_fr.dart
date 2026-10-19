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

  @override
  String get doctorsTitle => 'Médecins';

  @override
  String get doctorsAdd => 'Ajouter un médecin';

  @override
  String get doctorsAdded => 'Médecin ajouté avec succès';

  @override
  String doctorsCountOnFile(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count médecins enregistrés',
      one: '1 médecin enregistré',
    );
    return '$_temp0';
  }

  @override
  String get doctorsEmptyTitle => 'Aucun médecin enregistré';

  @override
  String get doctorsEmptySubtitle =>
      'Ajoutez un médecin pour lier des ordonnances';

  @override
  String get doctorsUpcomingVisits => 'Rendez-vous à venir';

  @override
  String doctorsAppointmentsScheduled(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count rendez-vous prévus',
      one: '1 rendez-vous prévu',
    );
    return '$_temp0';
  }

  @override
  String get doctorsView => 'Voir →';

  @override
  String get doctorsHint =>
      'Touchez un médecin pour voir les détails ou modifier';

  @override
  String doctorsMedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count médicaments',
      one: '1 médicament',
    );
    return '$_temp0';
  }

  @override
  String get doctorsDetailsSection => 'INFORMATIONS DU MÉDECIN';

  @override
  String get doctorsFieldFullName => 'Nom complet *';

  @override
  String get doctorsHintFullName => 'Entrez le nom complet';

  @override
  String get doctorsFieldSpecialty => 'Spécialité';

  @override
  String get doctorsHintSpecialty => 'Entrez la spécialité';

  @override
  String get doctorsFieldPhone => 'Numéro de téléphone';

  @override
  String get doctorsHintPhone => 'Entrez le numéro de téléphone';

  @override
  String get doctorsFieldClinic => 'Clinique / Adresse (facultatif)';

  @override
  String get doctorsHintClinic => 'Entrez la clinique ou l\'adresse';

  @override
  String get doctorsLinkMedications => 'LIER AUX MÉDICAMENTS';

  @override
  String get doctorsLinkPrompt => 'Quels médicaments ce médecin prescrit-il ?';

  @override
  String get doctorsSave => 'Enregistrer le médecin';

  @override
  String get doctorsNameRequired =>
      'Veuillez saisir le nom complet du médecin.';

  @override
  String get medsTitle => 'Médicaments';

  @override
  String medsMemberMedications(String name) {
    return 'Médicaments de $name';
  }

  @override
  String medsActiveCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count médicaments actifs',
      one: '1 médicament actif',
    );
    return '$_temp0';
  }

  @override
  String get medsManageHeader => 'GÉRER';

  @override
  String get medsQuickTools => 'Outils rapides';

  @override
  String get medsInventory => 'Inventaire';

  @override
  String medsLowBadge(int count) {
    return '$count FAIBLE';
  }

  @override
  String get medsAllergies => 'Allergies';

  @override
  String get medsSideEffects => 'Effets secondaires';

  @override
  String get medsPharmacy => 'Pharmacie';

  @override
  String get medsSearchHint => 'Rechercher des médicaments...';

  @override
  String medsTabActive(int count) {
    return 'Actifs ($count)';
  }

  @override
  String medsTabArchived(int count) {
    return 'Archivés ($count)';
  }

  @override
  String get medsEmptyArchived => 'Aucun médicament archivé';

  @override
  String get medsEmpty => 'Aucun médicament trouvé';

  @override
  String medsMovedToArchived(String name) {
    return '$name déplacé vers Archivés';
  }

  @override
  String get medsDiscontinueError =>
      'Impossible d\'arrêter le médicament. Veuillez réessayer.';

  @override
  String get medsDiscontinueBarrierLabel => 'Fermer arrêter le médicament';

  @override
  String get medsDiscontinue => 'Arrêter';

  @override
  String get medsLowStock => 'STOCK FAIBLE';

  @override
  String get medsBadgeActive => 'ACTIF';

  @override
  String get medsScheduleNotSet => 'Horaire non défini';

  @override
  String get medsFrequencyAsNeeded => 'Au besoin';

  @override
  String medsFrequencySelectedDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '${count}x les jours sélectionnés',
      one: '1x les jours sélectionnés',
    );
    return '$_temp0';
  }

  @override
  String medsFrequencyCyclical(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '${count}x cyclique',
      one: '1x cyclique',
    );
    return '$_temp0';
  }

  @override
  String get medsFrequencyTapering => 'Schéma dégressif';

  @override
  String medsFrequencyDaily(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '${count}x par jour',
      one: '1x par jour',
    );
    return '$_temp0';
  }

  @override
  String medsNextDoseTomorrow(String time) {
    return 'Demain $time';
  }

  @override
  String medsNextDoseWeekday(String day, String time) {
    return '$day $time';
  }

  @override
  String medsEnds(String date) {
    return 'Se termine le $date';
  }

  @override
  String medsNext(String time) {
    return 'Suivant : $time';
  }

  @override
  String get medsWeekdayMon => 'lun';

  @override
  String get medsWeekdayTue => 'mar';

  @override
  String get medsWeekdayWed => 'mer';

  @override
  String get medsWeekdayThu => 'jeu';

  @override
  String get medsWeekdayFri => 'ven';

  @override
  String get medsWeekdaySat => 'sam';

  @override
  String get medsWeekdaySun => 'dim';

  @override
  String get medsFormCapsule => 'Gélule';

  @override
  String get medsFormDrops => 'Gouttes';

  @override
  String get medsFormInjection => 'Injection';

  @override
  String medsDayOf(int day, int total) {
    return 'Jour $day sur $total';
  }

  @override
  String medsDaysLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jours restants',
      one: '1 jour restant',
    );
    return '$_temp0';
  }

  @override
  String medsUnitTablet(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'comprimés',
      one: 'comprimé',
    );
    return '$_temp0';
  }

  @override
  String medsUnitCapsule(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'gélules',
      one: 'gélule',
    );
    return '$_temp0';
  }

  @override
  String medsUnitBottle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'flacons',
      one: 'flacon',
    );
    return '$_temp0';
  }

  @override
  String medsUnitDose(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'doses',
      one: 'dose',
    );
    return '$_temp0';
  }

  @override
  String get inventoryTitle => 'Inventaire';

  @override
  String inventoryMedicationsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count médicaments',
      one: '1 médicament',
    );
    return '$_temp0';
  }

  @override
  String get inventoryTrackedSupply => 'Stock suivi';

  @override
  String inventoryLowStockCount(int count) {
    return '$count STOCK FAIBLE';
  }

  @override
  String get inventoryFilterAll => 'Tous';

  @override
  String get inventoryFilterLow => 'Stock faible';

  @override
  String get inventoryFilterOk => 'OK';

  @override
  String get inventoryEmptyFilter => 'Aucun médicament dans ce filtre';

  @override
  String get inventoryStatusLow => 'FAIBLE';

  @override
  String get inventoryStatusOk => 'OK';

  @override
  String get inventoryRunningLow =>
      'Stock faible — commandez un renouvellement';

  @override
  String get inventoryRefill => 'Renouveler →';

  @override
  String get inventoryAdjustCount => 'Ajuster la quantité';

  @override
  String get inventorySufficient => 'Stock suffisant';

  @override
  String get inventorySufficientNext =>
      'Suffisant jusqu\'au prochain renouvellement';

  @override
  String get inventoryEdit => 'Modifier';

  @override
  String get inventoryAutoSyncTitle => 'Synchronisation auto pharmacie';

  @override
  String get inventoryAutoSyncSubtitle =>
      'Connectez votre pharmacie pour des mises à jour automatiques de renouvellement';

  @override
  String get inventoryAutoSyncPending =>
      'Intégration de la synchronisation auto pharmacie en attente';

  @override
  String inventoryCountUpdated(String name, int count) {
    return '$name mis à jour à $count';
  }

  @override
  String inventorySupplyDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '~$count jours',
      one: '~1 jour',
    );
    return '$_temp0';
  }

  @override
  String get inventoryAdjustReasonLabel =>
      'Motif de l\'ajustement (facultatif)';

  @override
  String get inventoryAdjustReasonHint =>
      'Motif de l\'ajustement (facultatif)...';

  @override
  String get inventoryAdjustSave => 'Enregistrer la quantité';

  @override
  String inventoryCurrentOnHand(int quantity, String unit) {
    return 'Disponible actuel : $quantity $unit';
  }

  @override
  String inventoryAfterRefill(int quantity) {
    return 'Après renouvellement : $quantity';
  }

  @override
  String inventoryFullBottle(int quantity) {
    return 'Flacon complet : $quantity';
  }

  @override
  String inventoryHalfPack(int quantity) {
    return 'Demi-pack : $quantity';
  }

  @override
  String get medFormExtendedRelease => 'Libération prolongée';

  @override
  String get medRouteOral => 'Orale';

  @override
  String get medRouteSubcutaneous => 'Sous-cutanée';

  @override
  String get medConditionDiabetes => 'Diabète';

  @override
  String get medConditionType2Diabetes => 'Diabète de type 2';

  @override
  String get medConditionHighBloodPressure => 'Hypertension artérielle';

  @override
  String get medConditionHypertension => 'Hypertension';

  @override
  String get medConditionHeartHealth => 'Santé cardiaque';

  @override
  String get medConditionHighCholesterol => 'Cholestérol élevé';

  @override
  String get medConditionBacterialInfection => 'Infection bactérienne';

  @override
  String get medConditionPainInflammation => 'Douleur et inflammation';

  @override
  String get medConditionBoneHealth => 'Santé osseuse';

  @override
  String get medConditionAcidReflux => 'Reflux acide';

  @override
  String get addMedDailyDose => 'Dose quotidienne';

  @override
  String addMedCommonFor(String condition) {
    return 'Courant pour : $condition';
  }

  @override
  String get addManualColorWhite => 'Blanc';

  @override
  String get addManualColorYellow => 'Jaune';

  @override
  String get addManualColorPink => 'Rose';

  @override
  String get addManualColorBlue => 'Bleu';

  @override
  String get addManualColorOrange => 'Orange';

  @override
  String get addManualColorPeach => 'Pêche';

  @override
  String get addManualColorGreen => 'Vert';

  @override
  String get addManualDraftSaved =>
      'Brouillon enregistré : complétez-le plus tard !';

  @override
  String get addMedTitle => 'Ajouter un médicament';

  @override
  String get addManualRxVerified => 'RX VÉRIFIÉ';

  @override
  String get medsMedicationDetails => 'DÉTAILS DU MÉDICAMENT';

  @override
  String get medsFieldName => 'Nom du médicament';

  @override
  String get medsFieldStrength => 'Dosage';

  @override
  String get medsFieldForm => 'Forme du médicament';

  @override
  String get addManualSelectForm => 'Sélectionner la forme';

  @override
  String get addManualColorOptional => 'Couleur (facultatif)';

  @override
  String get medsFieldInstructions => 'Instructions spéciales';

  @override
  String get addManualOptional => 'Facultatif';

  @override
  String get addManualInstructionsHint =>
      'ex. Prendre avec de la nourriture après le petit-déjeuner, éviter le pamplemousse...';

  @override
  String get addManualContinueToSchedule => 'Continuer vers le planning →';

  @override
  String get addManualSaveDraft => 'Enregistrer comme brouillon';

  @override
  String get addManualNameHint => 'Entrez le nom du médicament';

  @override
  String get addManualMatchesIndex => 'Correspond à l\'index clinique';

  @override
  String get addManualStrengthHint => 'ex. 500';

  @override
  String get addManualFormOther => 'Autre';

  @override
  String get addManualFormOtherSubtitle =>
      'Entrez une autre forme de médicament';

  @override
  String get addManualCustomForm => 'Forme personnalisée';

  @override
  String get addManualCustomFormHint =>
      'ex. Crème, Inhalateur, Patch, Spray...';

  @override
  String get addManualCustomFormRequired =>
      'Veuillez entrer la forme du médicament';

  @override
  String get addManualInteractionTitle =>
      'Vérifications automatiques des interactions';

  @override
  String get addManualInteractionBody =>
      'Nous comparerons ce dosage avec vos médicaments déjà enregistrés à l\'étape suivante.';

  @override
  String addMedSelected(String name, String strength) {
    return '$name $strength sélectionné : détails à suivre !';
  }

  @override
  String get addMedPrivateNote => 'Privé et chiffré sur cet appareil';

  @override
  String get addMedScanLabel => 'Scanner l\'étiquette';

  @override
  String get addMedSearch => 'Rechercher';

  @override
  String get addMedManualEntry => 'Saisie manuelle';

  @override
  String addMedMatchingCount(int count) {
    return 'Médicaments correspondants ($count)';
  }

  @override
  String get addMedFdaApproved => 'Approuvé par la FDA';

  @override
  String get addMedTipTitle => 'Astuce : cherchez l\'inscription';

  @override
  String get addMedTipBody =>
      'La plupart des comprimés de metformine portent des chiffres comme « 500 » ou « M » imprimés au recto pour garantir le dosage exact.';

  @override
  String get addMedCantFind => 'Vous ne trouvez pas votre médicament ?';

  @override
  String get addMedAddManually => 'Ajouter manuellement';

  @override
  String get addMedEmptyTitle => 'Rechercher un médicament';

  @override
  String get addMedEmptySubtitle =>
      'Entrez un nom de médicament ci-dessus ou scannez son étiquette';

  @override
  String get addMedNoResultsTitle => 'Aucun médicament trouvé';

  @override
  String addMedNoResultsFor(String query) {
    return 'Aucun résultat pour « $query »';
  }

  @override
  String get addMedSelectAction => 'Sélectionner ›';

  @override
  String get reviewScanNameRequired => 'Veuillez entrer le nom du médicament.';

  @override
  String get reviewScanStrengthRequired =>
      'Veuillez entrer le dosage du médicament.';

  @override
  String get reviewScanTitle => 'Vérifier le scan';

  @override
  String get scanCaptureFailed => 'Échec de la capture : réessayez.';

  @override
  String get scanCaptureError => 'Impossible de capturer l\'image. Réessayez.';

  @override
  String get scanGalleryError => 'Impossible d\'ouvrir l\'image. Réessayez.';

  @override
  String scanDetectedOne(String name) {
    return '✓ Détecté : $name';
  }

  @override
  String scanDetectedCount(int count) {
    return '✓ $count médicaments détectés';
  }

  @override
  String get scanTextNoMedicine =>
      'Du texte a été détecté, mais les détails du médicament n\'ont pas pu être identifiés.';

  @override
  String get scanNoText =>
      'Aucun texte détecté. Gardez le document clair, plat et bien éclairé.';

  @override
  String get scanReadError => 'Impossible de lire l\'image. Réessayez.';

  @override
  String get scanRescanAgain => 'Veuillez scanner le médicament à nouveau.';

  @override
  String get scanFitFrameHint =>
      'Placez l\'étiquette du médicament ou l\'ordonnance complète dans le cadre';

  @override
  String get scanEnterManually => 'Saisir le médicament manuellement';

  @override
  String get scanRetakePhoto => 'Reprendre la photo';

  @override
  String get scanReadingPrescription => 'Lecture de l\'ordonnance...';

  @override
  String get scanStatusReading => 'LECTURE';

  @override
  String get scanStatusFound => 'TROUVÉ';

  @override
  String get scanStatusInFrame => 'DANS LE CADRE';

  @override
  String get scanStatusReady => 'PRÊT';

  @override
  String get scanCameraUnavailable => 'Caméra indisponible';

  @override
  String get scanStartingCamera => 'Démarrage de la caméra...';

  @override
  String get scanCapturingDocument => 'Capture du document...';

  @override
  String get scanReadingMedicineText => 'Lecture du texte du médicament...';

  @override
  String get scanMedicineDetected => 'Médicament détecté';

  @override
  String scanMedicinesDetected(int count) {
    return '$count médicaments détectés';
  }

  @override
  String get scanImageCaptured => 'Image capturée';

  @override
  String get scanMedicineOrRxDetected => 'Médicament ou ordonnance détecté';

  @override
  String get scanPointCameraHint =>
      'Pointez la caméra vers le médicament ou l\'ordonnance';

  @override
  String get scanFlash => 'Flash';

  @override
  String get scanShutter => 'Scanner';

  @override
  String get scanGallery => 'Galerie';

  @override
  String get scanTryAgain => 'Réessayer';

  @override
  String scanMedicineBadgeNumber(int index) {
    return 'MÉDICAMENT $index DÉTECTÉ';
  }

  @override
  String get scanMedicineBadgeSingular => 'MÉDICAMENT DÉTECTÉ';

  @override
  String get scanFieldStrength => 'Dosage';

  @override
  String get scanFieldForm => 'Forme';

  @override
  String get scanFieldFrequency => 'Fréquence';

  @override
  String get medsFieldInstructionsShort => 'Instructions';

  @override
  String get scanReviewAdd => 'Vérifier et ajouter le médicament';

  @override
  String get stepSchedule => 'Planning';

  @override
  String get reviewScanScanned => 'SCANNÉ';

  @override
  String get reviewScanReadSuccess =>
      'Nous avons lu ces détails sur votre étiquette : vérifiez et corrigez si nécessaire !';

  @override
  String get reviewScanInstructionsHint =>
      'Entrez les instructions du médicament';

  @override
  String get reviewScanStrengthUnclear =>
      'Le champ du dosage était flou sur la photo : veuillez vérifier manuellement.';

  @override
  String get reviewScanRequired => 'OBLIGATOIRE';

  @override
  String get reviewScanStrengthHint => 'Entrez le dosage, ex. 500mg';

  @override
  String get reviewScanConfirmContinue => 'Confirmer et continuer →';
}
