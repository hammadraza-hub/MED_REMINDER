// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String comingSoon(String title) {
    return '$title — próximamente';
  }

  @override
  String get cancel => 'Cancelar';

  @override
  String get navHome => 'Inicio';

  @override
  String get navMeds => 'Medicamentos';

  @override
  String get navCalendar => 'Calendario';

  @override
  String get navReports => 'Informes';

  @override
  String get navSettings => 'Ajustes';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get settingsGroupPreferences => 'Preferencias';

  @override
  String get settingsGroupAccountPlan => 'Cuenta y plan';

  @override
  String get settingsGroupSupportLegal => 'Soporte y legal';

  @override
  String get settingsNotifications => 'Notificaciones';

  @override
  String get settingsNotificationsTrailing => 'Sonido y vibración';

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String get settingsLanguageTrailing => 'Español';

  @override
  String get settingsAccessibility => 'Accesibilidad';

  @override
  String get settingsPrivacySecurity => 'Privacidad y seguridad';

  @override
  String get settingsSubscription => 'Suscripción';

  @override
  String get settingsDataExport => 'Exportar datos';

  @override
  String get settingsDataExportTrailing => 'CSV y PDF';

  @override
  String get settingsHelpSupport => 'Ayuda y soporte';

  @override
  String get settingsAbout => 'Acerca de';

  @override
  String get settingsAboutTrailing => 'v1.2.0';

  @override
  String get settingsPro => 'PRO';

  @override
  String get settingsCaregiverSync => 'Sincronización activa';

  @override
  String get settingsLogoutTitle => '¿Cerrar sesión?';

  @override
  String get settingsLogoutMessage =>
      'Deberás iniciar sesión de nuevo para acceder a tu plan de cuidados.';

  @override
  String get settingsLogOut => 'Cerrar sesión';

  @override
  String get settingsLogoutComingSoon => 'Cerrar sesión — próximamente';

  @override
  String get settingsFooterVersion =>
      'MedRemind Care Health Suite • v1.2.0 (Compilación 412)';

  @override
  String get settingsHipaa => 'Compatible con HIPAA y cifrado';

  @override
  String get languageTitle => 'Idioma';

  @override
  String get languageNote =>
      'La aplicación se actualiza al instante tras seleccionar un idioma.';

  @override
  String get languageDeviceDefault =>
      'Predeterminado del dispositivo: idioma del sistema (English - US)';

  @override
  String get homeGreetingMorning => 'Buenos días';

  @override
  String get homeGreetingAfternoon => 'Buenas tardes';

  @override
  String get homeGreetingEvening => 'Buenas noches';

  @override
  String homeGreetingWithName(String greeting, String name) {
    return '$greeting, $name 👋';
  }

  @override
  String homeDayStreak(int days) {
    return 'Racha de $days días';
  }

  @override
  String get homeAdd => 'Añadir';

  @override
  String get homeTodaySchedule => 'Horario de hoy';

  @override
  String get homeFilterAll => 'Todos';

  @override
  String get homeFilterPending => 'Pendientes';

  @override
  String get homeFilterTaken => 'Tomadas';

  @override
  String get homeDaily => 'Diario';

  @override
  String homeStatTaken(int count) {
    return '$count Tomadas';
  }

  @override
  String homeStatPending(int count) {
    return '$count Pendientes';
  }

  @override
  String homeStatMissed(int count) {
    return '$count Perdidas';
  }

  @override
  String get homeQuickAccess => 'ACCESO RÁPIDO';

  @override
  String get homeShortcuts => 'Atajos';

  @override
  String get homeQuickVitals => 'Signos';

  @override
  String get homeQuickDoctors => 'Médicos';

  @override
  String get homeQuickAI => 'IA Asist';

  @override
  String get homeQuickFamily => 'Familia';

  @override
  String homeScreenComingSoon(String name) {
    return 'La pantalla de $name estará disponible pronto.';
  }

  @override
  String homeMarkedTaken(String name) {
    return '$name marcada como tomada ✓';
  }

  @override
  String homeMarkedUntaken(String name) {
    return '$name marcada como no tomada 🔄';
  }

  @override
  String homeSkipped(String name) {
    return '$name omitida';
  }

  @override
  String homeSkippedReason(String name, String reason) {
    return '$name omitida — $reason';
  }

  @override
  String homeSnoozed(String name, int minutes) {
    return '$name pospuesta — recordatorio de nuevo en $minutes min';
  }

  @override
  String homeSwitchedMember(String name) {
    return 'Cambiado a los medicamentos de $name';
  }

  @override
  String get homeActionTaken => 'Tomada';

  @override
  String get homeActionSkip => 'Omitir';

  @override
  String get homeActionSnooze => 'Posponer';

  @override
  String get homeStatusPending => 'PENDIENTE';

  @override
  String get homeStatusTaken => 'TOMADA';

  @override
  String get homeStatusUpcoming => 'PRÓXIMA';

  @override
  String get homeStatusSkipped => 'OMITIDA';

  @override
  String homeRunningLow(String name, int days) {
    return '$name por agotarse · quedan $days días';
  }

  @override
  String get homeRefill => 'Recargar →';

  @override
  String get homeSkippedNote => 'Omitida — el recordatorio volverá mañana';

  @override
  String get doseFormTablet => 'Comprimido';

  @override
  String get doseFormLiquid => 'Líquido';

  @override
  String get doseScheduleDaily => '1 vez al día';

  @override
  String get doseScheduleBeforeBreakfast => 'Antes del desayuno';

  @override
  String get doseScheduleAfterBreakfast => 'Después del desayuno';

  @override
  String get doseScheduleWithDinner => 'Con la cena';

  @override
  String doseDueSoon(String time) {
    return '$time · Pronto';
  }

  @override
  String get doseMarkTaken => 'Marcar como tomada';

  @override
  String get doseMarkUntaken => 'Marcar como no tomada';

  @override
  String get doseHideReason => 'Ocultar motivo';

  @override
  String get doseSkipDose => 'Omitir dosis';

  @override
  String get doseSnoozeFor => 'POSPONER POR';

  @override
  String get doseReasonLabel => 'Motivo (opcional)';

  @override
  String get doseReasonHint => 'p. ej., Náuseas';

  @override
  String get doseConfirmSkip => 'Confirmar omisión';

  @override
  String get dataExportTitle => 'Exportar datos';

  @override
  String get dataExportHeroTitle => 'Exportar todos mis datos';

  @override
  String get dataExportHeroSubtitle =>
      'Obtén una copia completa de todo lo guardado en tu cuenta.';

  @override
  String get dataExportBadge => 'Exportación cifrada estándar GDPR y HIPAA';

  @override
  String get dataExportIncludedTitle => 'Qué se incluye';

  @override
  String get dataExportModules => '4 módulos';

  @override
  String get dataExportIncludedProfiles => 'Todos los perfiles y medicamentos';

  @override
  String get dataExportIncludedDoses =>
      'Historial completo de dosis y adherencia';

  @override
  String get dataExportIncludedVitals => 'Signos vitales, síntomas y notas';

  @override
  String get dataExportIncludedPrescribers => 'Médicos, citas y farmacias';

  @override
  String dataExportFormatNote(String formats) {
    return 'Recibirás un archivo ZIP ($formats) por correo en un plazo de 24 horas.';
  }

  @override
  String get dataExportFormats => 'JSON + CSV';

  @override
  String dataExportSentTo(String email) {
    return 'Enviado directamente a $email';
  }

  @override
  String get dataExportRequest => 'Solicitar exportación';

  @override
  String get dataExportGenerating => 'Generando paquete...';

  @override
  String get dataExportSubmitted => 'Solicitud enviada';

  @override
  String get dataExportSuccessTitle => '¡Exportación solicitada!';

  @override
  String get dataExportSuccessMessage =>
      'Estamos preparando tu archivo de datos sin procesar. Recibirás un enlace directo cuando finalice la compilación.';

  @override
  String get dataExportQueued => 'En cola en el lote del servidor';

  @override
  String get dataExportLastExportNever => 'Última exportación: Nunca';

  @override
  String dataExportLastExportNow(String timestamp) {
    return 'Última exportación: Ahora mismo ($timestamp)';
  }

  @override
  String dataExportRetentionId(String id) {
    return 'ID de retención de registros de la cuenta: $id';
  }

  @override
  String get helpSupportTitle => 'Ayuda y soporte';

  @override
  String get helpSupportSearchHint => 'Buscar en preguntas...';

  @override
  String get helpSupportNoResults => 'No hay artículos coincidentes.';

  @override
  String get helpSupportBannerTitle => 'Atención a cuidadores y pacientes';

  @override
  String get helpSupportBannerSubtitle =>
      'Estamos aquí para mantener tus rutinas a tiempo.';

  @override
  String get helpSupportFaqHeader => 'Preguntas frecuentes';

  @override
  String helpSupportFaqCount(int count) {
    return '$count artículos';
  }

  @override
  String get helpSupportStillNeedHelp => '¿Aún necesitas ayuda?';

  @override
  String get helpSupportLiveOnline => 'Equipo en línea';

  @override
  String get helpSupportEmailSupport => 'Soporte por correo';

  @override
  String get helpSupportEmailAction => 'Correo';

  @override
  String get helpSupportSubmitRequest => 'Enviar una solicitud';

  @override
  String get helpSupportResponseTime => 'Respuesta media en menos de 2 horas';

  @override
  String get helpSupportHelpful => '¿Te resultó útil esta página?';

  @override
  String get helpSupportYes => 'Sí';

  @override
  String get helpSupportNo => 'No';

  @override
  String get helpSupportFeedbackThanks => '¡Gracias por tu opinión!';

  @override
  String get helpSupportVersion => 'MedRemind v1.2.0 (compilación 245)';

  @override
  String get helpSupportCompliance =>
      'Red de cuidadores cifrada • Compatible con HIPAA';

  @override
  String helpSupportEmailClipped(String email) {
    return 'Escríbenos a $email';
  }

  @override
  String get faqQ1 => '¿Cómo cambio la hora de una dosis?';

  @override
  String get faqA1 =>
      'Abre tu pestaña de Horario o Medicamentos, toca la tarjeta del medicamento, selecciona Editar horario y ajusta tus alertas. Los cambios se sincronizan al instante entre los dispositivos de cuidadores.';

  @override
  String get faqQ2 => '¿Por qué no recibí un recordatorio?';

  @override
  String get faqA2 =>
      'Asegúrate de que la optimización de batería esté desactivada para MedRemind en los Ajustes del teléfono. Verifica también que las Alertas críticas y los permisos de notificación estén concedidos en los ajustes de tu sistema operativo.';

  @override
  String get faqQ3 => '¿Cómo funcionan las alertas de cuidadores?';

  @override
  String get faqA3 =>
      'Los cuidadores reciben confirmaciones silenciosas cuando se registran los medicamentos. Si se omite una dosis crucial durante más de 30 minutos, se envía una notificación escalada al cuidador principal.';

  @override
  String get faqQ4 => '¿Cómo añado un familiar?';

  @override
  String get faqA4 =>
      'Ve a Perfiles, toca Añadir y envía una invitación por correo o teléfono. Ellos aceptan el enlace para conectarse.';

  @override
  String get aboutTitle => 'Acerca de';

  @override
  String get aboutAppName => 'MedRemind';

  @override
  String get aboutVersion => 'Versión 1.2.0 (compilación 245)';

  @override
  String get aboutUpToDate => 'ACTUALIZADO ✓';

  @override
  String get aboutTerms => 'Términos de servicio';

  @override
  String get aboutPrivacy => 'Política de privacidad';

  @override
  String get aboutLicenses => 'Licencias de código abierto';

  @override
  String get aboutCredits => 'Créditos';

  @override
  String get aboutCreditsDesign => 'Diseño';

  @override
  String get aboutCreditsDesignValue => 'Equipo de MedRemind';

  @override
  String get aboutCreditsDrugData => 'Datos de medicamentos';

  @override
  String get aboutCreditsDrugDataValue => 'RxNorm · OpenFDA';

  @override
  String get aboutCreditsIcons => 'Iconos';

  @override
  String get aboutCreditsIconsValue => 'Conjuntos de código abierto';

  @override
  String get aboutFooter =>
      'Hecho con cariño para familias que gestionan su salud juntas.';

  @override
  String get aboutLegalBody1 =>
      'MedRemind está comprometido con una alta precisión clínica y un diseño compasivo. Nuestras fuentes de datos cumplen estrictamente con los estándares publicados por la Biblioteca Nacional de Medicina (RxNorm) y la base regulatoria de la FDA.';

  @override
  String get aboutLegalBody2 =>
      'Todas las heurísticas de reconocimiento de pastillas, las alertas a cuidadores y los registros de dosis permanecen cifrados y vinculados a tu caja familiar designada. Los parámetros de salud no se monetizan ni se comparten con anunciantes externos.';

  @override
  String get aboutLegalComplianceTitle => 'Cumplimiento y auditorías';

  @override
  String get aboutLegalComplianceValue =>
      'Certificado SOC-2 Tipo II · Salvaguardas de seguridad HIPAA · Verificado 2025';

  @override
  String get aboutDone => 'Listo';

  @override
  String get upgradeTitle => 'Mejorar';

  @override
  String get upgradePlanStatus => 'Plan Gratis • Listo para ampliar';

  @override
  String get upgradeProGated => 'Requiere Pro';

  @override
  String get upgradeHeroTitle => 'Desbloquea todo el poder de MedRemind';

  @override
  String get upgradeHeroSubtitle =>
      'Interacciones, reabastecimientos, informes y uso familiar';

  @override
  String get upgradeUnlockHeader => 'Lo que desbloquearás';

  @override
  String get upgradeUnlockInteractions =>
      'Verificación de interacciones y alergias';

  @override
  String get upgradeUnlockRefills =>
      'Control de inventario y alertas de reabastecimiento';

  @override
  String get upgradeUnlockReports => 'Informes PDF/CSV para tu médico';

  @override
  String get upgradeUnlockFamily => 'Vinculación familiar — hasta 5 perfiles';

  @override
  String get upgradeSeeComparison => 'Ver comparación completa';

  @override
  String get upgradeChoosePlan => 'Elige tu plan';

  @override
  String get upgradeFreeTrial => 'Prueba gratis de 7 días';

  @override
  String get upgradeMonthly => 'Mensual';

  @override
  String get upgradeAnnual => 'Anual';

  @override
  String get upgradeSaveBadge => 'Ahorra 52%';

  @override
  String get upgradePlanSoloName => 'Solo Pro';

  @override
  String get upgradePlanSoloSubtitle => 'Todo para una persona';

  @override
  String get upgradePlanFamilyName => 'Family Pro';

  @override
  String get upgradePlanFamilySubtitle =>
      'Hasta 5 perfiles vinculados + alertas de cuidadores';

  @override
  String get upgradePopular => 'Popular';

  @override
  String get upgradeSelected => 'Seleccionado';

  @override
  String upgradePriceAnnual(String price) {
    return '$price/año';
  }

  @override
  String upgradePriceMonthly(String price) {
    return '$price/mes';
  }

  @override
  String upgradeWasPrice(String price) {
    return 'antes $price';
  }

  @override
  String get upgradeStartTrial => 'Comenzar prueba gratis de 7 días';

  @override
  String get upgradeNothingDue => 'Nada que pagar hoy. Recordatorio el día 5.';

  @override
  String get upgradeCompareAll => 'Comparar todas las funciones y planes';

  @override
  String get upgradeRestorePurchase => 'Restaurar compra';

  @override
  String get upgradeLegalNote =>
      'Cancela cuando quieras en los ajustes de la App Store al menos 24 horas antes de que termine la prueba. El plan se renueva automáticamente hasta cancelarlo.';

  @override
  String get upgradeComparisonTitle => 'Comparación completa de planes';

  @override
  String get upgradeComparisonContinue => 'Continuar con el plan seleccionado';

  @override
  String get upgradeFeatureReminders => 'Recordatorios de medicación';

  @override
  String get upgradeFeatureRemindersValue => 'Gratis y Pro (Ilimitado)';

  @override
  String get upgradeFeatureInteractions => 'Verificador de interacciones';

  @override
  String get upgradeFeatureRefills =>
      'Alertas inteligentes de reabastecimiento';

  @override
  String get upgradeFeatureReports =>
      'Exportaciones de salud PDF para el médico';

  @override
  String get upgradeFeatureFamily => 'Sincronización familiar y de cuidadores';

  @override
  String get upgradeValuePro => 'Exclusivo Pro';

  @override
  String get upgradeValueFamily => 'Solo Family Pro';

  @override
  String get upgradeRestoreToast =>
      'Restaurando compras... No se encontraron suscripciones previas.';

  @override
  String upgradeTrialToast(String plan, String cadence) {
    return 'Comenzando prueba de 7 días para $plan ($cadence)';
  }

  @override
  String get compareTitle => 'Comparar planes';

  @override
  String get compareGuarantee => 'Garantía de reembolso de 30 días';

  @override
  String get compareAnnualSave => 'Ahorra 40% anual';

  @override
  String get compareColFeatures => 'Funciones';

  @override
  String get compareColFree => 'Gratis';

  @override
  String get compareFreeSubtitle => 'Básico';

  @override
  String get compareColSolo => 'Solo';

  @override
  String get compareSoloSubtitle => 'El más querido';

  @override
  String get compareColFamily => 'Familia';

  @override
  String get compareFamilySubtitle => 'Cuidado total';

  @override
  String get comparePriceLabel => 'Precio';

  @override
  String get compareBilledYearly => 'Facturado anualmente';

  @override
  String get compareForever => 'para siempre';

  @override
  String get comparePerYear => '/año';

  @override
  String get compareGroupDaily => 'Herramientas diarias de medicación';

  @override
  String get compareGroupClinical => 'Seguridad clínica y seguimiento';

  @override
  String get compareGroupFamily => 'Círculo familiar y de cuidadores';

  @override
  String get compareFeatUnlimitedMeds =>
      'Medicamentos y recordatorios ilimitados';

  @override
  String get compareFeatAdherence => 'Calendario de adherencia y rachas';

  @override
  String get compareFeatInteractions =>
      'Comprobación de interacciones y alergias';

  @override
  String get compareFeatInventory => 'Inventario y alertas de reabastecimiento';

  @override
  String get compareFeatDoctorTools => 'Herramientas de médico y citas';

  @override
  String get compareFeatReports => 'Informes de salud PDF/CSV';

  @override
  String get compareFeatHealthSync => 'Sincronización con Apple Health y Fit';

  @override
  String get compareFeatFamilyLinking => 'Vinculación familiar (hasta 5)';

  @override
  String get compareFeatMissedDose => 'Alerta de cuidador por dosis omitida';

  @override
  String get compareFeatFamilyDashboard => 'Panel familiar combinado';

  @override
  String get compareQuote =>
      '“Las alertas para cuidadores me dieron total tranquilidad con mamá.”';

  @override
  String get compareQuoteAuthor => '— Sarah M., suscriptora de Family Pro';

  @override
  String get compareChooseSolo => 'Elegir Solo Pro';

  @override
  String get compareChooseFamily => 'Elegir Family Pro';

  @override
  String get compareContinueFree => 'Continuar con el plan Gratis básico';

  @override
  String get compareFreeSelected => 'Plan Gratis básico seleccionado';

  @override
  String get compareFinePrint =>
      'Precios mostrados para facturación anual. Los planes mensuales también están disponibles al pagar. Cancela cuando quieras sin complicaciones.';

  @override
  String get compareEncrypted => 'Cifrado de 256 bits';

  @override
  String get compareAutoSync => 'Sincronización automática';

  @override
  String get compareHipaaReady => 'Compatible con HIPAA';

  @override
  String get paymentTitle => 'Pago exitoso';

  @override
  String get paymentProNowTitle => '¡Ahora eres Pro!';

  @override
  String paymentWelcome(String plan, String name) {
    return 'Bienvenido a $plan, $name. Todas las funciones Pro están desbloqueadas.';
  }

  @override
  String get paymentPlanActive =>
      'Plan activo • Sincronización de cuidado ilimitada';

  @override
  String get paymentOrderSummary => 'Resumen del pedido';

  @override
  String get paymentTrialActive => 'Prueba activa';

  @override
  String get paymentPlanLabel => 'Plan';

  @override
  String get paymentFreeTrialLabel => 'Prueba gratis';

  @override
  String paymentFreeTrialValue(String price) {
    return '7 días — luego $price';
  }

  @override
  String get paymentNextBillingLabel => 'Próxima fecha de cobro';

  @override
  String get paymentReceipt => 'Recibo';

  @override
  String get paymentOrderIdLabel => 'ID de pedido';

  @override
  String get paymentPaymentMethodLabel => 'Método de pago';

  @override
  String get paymentReceiptSentLabel => 'Recibo enviado a';

  @override
  String get paymentViewFullReceipt => 'Ver recibo completo';

  @override
  String get paymentStartPro => 'Comenzar a usar Pro';

  @override
  String get paymentUnlockNote =>
      'Las verificaciones de interacciones, alertas de reabastecimiento e informes ya están activos';
}
