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

  @override
  String get doctorsTitle => 'Médicos';

  @override
  String get doctorsAdd => 'Agregar médico';

  @override
  String get doctorsAdded => 'Médico agregado correctamente';

  @override
  String doctorsCountOnFile(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count médicos registrados',
      one: '1 médico registrado',
    );
    return '$_temp0';
  }

  @override
  String get doctorsEmptyTitle => 'No hay médicos registrados';

  @override
  String get doctorsEmptySubtitle => 'Agrega un médico para vincular recetas';

  @override
  String get doctorsUpcomingVisits => 'Próximas visitas';

  @override
  String doctorsAppointmentsScheduled(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count citas programadas',
      one: '1 cita programada',
    );
    return '$_temp0';
  }

  @override
  String get doctorsView => 'Ver →';

  @override
  String get doctorsHint => 'Toca un médico para ver detalles o editar';

  @override
  String doctorsMedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count medicamentos',
      one: '1 medicamento',
    );
    return '$_temp0';
  }

  @override
  String get doctorsDetailsSection => 'DATOS DEL MÉDICO';

  @override
  String get doctorsFieldFullName => 'Nombre completo *';

  @override
  String get doctorsHintFullName => 'Ingresa el nombre completo';

  @override
  String get doctorsFieldSpecialty => 'Especialidad';

  @override
  String get doctorsHintSpecialty => 'Ingresa la especialidad';

  @override
  String get doctorsFieldPhone => 'Número de teléfono';

  @override
  String get doctorsHintPhone => 'Ingresa el número de teléfono';

  @override
  String get doctorsFieldClinic => 'Clínica / Dirección (opcional)';

  @override
  String get doctorsHintClinic => 'Ingresa la clínica o dirección';

  @override
  String get doctorsLinkMedications => 'VINCULAR MEDICAMENTOS';

  @override
  String get doctorsLinkPrompt => '¿Qué medicamentos receta este médico?';

  @override
  String get doctorsSave => 'Guardar médico';

  @override
  String get doctorsNameRequired => 'Ingresa el nombre completo del médico.';

  @override
  String get medsTitle => 'Medicamentos';

  @override
  String medsMemberMedications(String name) {
    return 'Medicamentos de $name';
  }

  @override
  String medsActiveCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count medicamentos activos',
      one: '1 medicamento activo',
    );
    return '$_temp0';
  }

  @override
  String get medsManageHeader => 'GESTIONAR';

  @override
  String get medsQuickTools => 'Herramientas rápidas';

  @override
  String get medsInventory => 'Inventario';

  @override
  String medsLowBadge(int count) {
    return '$count BAJO';
  }

  @override
  String get medsAllergies => 'Alergias';

  @override
  String get medsSideEffects => 'Efectos secundarios';

  @override
  String get medsPharmacy => 'Farmacia';

  @override
  String get medsSearchHint => 'Buscar medicamentos...';

  @override
  String medsTabActive(int count) {
    return 'Activos ($count)';
  }

  @override
  String medsTabArchived(int count) {
    return 'Archivados ($count)';
  }

  @override
  String get medsEmptyArchived => 'No hay medicamentos archivados';

  @override
  String get medsEmpty => 'No se encontraron medicamentos';

  @override
  String medsMovedToArchived(String name) {
    return '$name movido a Archivados';
  }

  @override
  String get medsDiscontinueError =>
      'No se pudo suspender el medicamento. Inténtalo de nuevo.';

  @override
  String get medsDiscontinueBarrierLabel => 'Cerrar suspender medicamento';

  @override
  String get medsDiscontinue => 'Suspender';

  @override
  String get medsLowStock => 'STOCK BAJO';

  @override
  String get medsBadgeActive => 'ACTIVO';

  @override
  String get medsScheduleNotSet => 'Horario no definido';

  @override
  String get medsFrequencyAsNeeded => 'Según necesidad';

  @override
  String medsFrequencySelectedDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '${count}x en días seleccionados',
      one: '1x en días seleccionados',
    );
    return '$_temp0';
  }

  @override
  String medsFrequencyCyclical(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '${count}x cíclico',
      one: '1x cíclico',
    );
    return '$_temp0';
  }

  @override
  String get medsFrequencyTapering => 'Pauta descendente';

  @override
  String medsFrequencyDaily(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '${count}x al día',
      one: '1x al día',
    );
    return '$_temp0';
  }

  @override
  String medsNextDoseTomorrow(String time) {
    return 'Mañana $time';
  }

  @override
  String medsNextDoseWeekday(String day, String time) {
    return '$day $time';
  }

  @override
  String medsEnds(String date) {
    return 'Termina el $date';
  }

  @override
  String medsNext(String time) {
    return 'Próxima: $time';
  }

  @override
  String get medsWeekdayMon => 'lun';

  @override
  String get medsWeekdayTue => 'mar';

  @override
  String get medsWeekdayWed => 'mié';

  @override
  String get medsWeekdayThu => 'jue';

  @override
  String get medsWeekdayFri => 'vie';

  @override
  String get medsWeekdaySat => 'sáb';

  @override
  String get medsWeekdaySun => 'dom';

  @override
  String get medsFormCapsule => 'Cápsula';

  @override
  String get medsFormDrops => 'Gotas';

  @override
  String get medsFormInjection => 'Inyección';

  @override
  String medsDayOf(int day, int total) {
    return 'Día $day de $total';
  }

  @override
  String medsDaysLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'quedan $count días',
      one: 'queda 1 día',
    );
    return '$_temp0';
  }

  @override
  String medsUnitTablet(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'comprimidos',
      one: 'comprimido',
    );
    return '$_temp0';
  }

  @override
  String medsUnitCapsule(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'cápsulas',
      one: 'cápsula',
    );
    return '$_temp0';
  }

  @override
  String medsUnitBottle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'frascos',
      one: 'frasco',
    );
    return '$_temp0';
  }

  @override
  String medsUnitDose(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'dosis',
      one: 'dosis',
    );
    return '$_temp0';
  }

  @override
  String get inventoryTitle => 'Inventario';

  @override
  String inventoryMedicationsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count medicamentos',
      one: '1 medicamento',
    );
    return '$_temp0';
  }

  @override
  String get inventoryTrackedSupply => 'Suministro registrado';

  @override
  String inventoryLowStockCount(int count) {
    return '$count STOCK BAJO';
  }

  @override
  String get inventoryFilterAll => 'Todos';

  @override
  String get inventoryFilterLow => 'Stock bajo';

  @override
  String get inventoryFilterOk => 'OK';

  @override
  String get inventoryEmptyFilter => 'No hay medicamentos en este filtro';

  @override
  String get inventoryStatusLow => 'BAJO';

  @override
  String get inventoryStatusOk => 'OK';

  @override
  String get inventoryRunningLow => 'Por agotarse — pide reabastecimiento';

  @override
  String get inventoryRefill => 'Recargar →';

  @override
  String get inventoryAdjustCount => 'Ajustar cantidad';

  @override
  String get inventorySufficient => 'Suministro suficiente';

  @override
  String get inventorySufficientNext =>
      'Suficiente hasta el próximo reabastecimiento';

  @override
  String get inventoryEdit => 'Editar';

  @override
  String get inventoryAutoSyncTitle =>
      'Sincronización automática con la farmacia';

  @override
  String get inventoryAutoSyncSubtitle =>
      'Conecta tu farmacia para actualizaciones automáticas de reabastecimiento';

  @override
  String get inventoryAutoSyncPending =>
      'Integración de sincronización con farmacia pendiente';

  @override
  String inventoryCountUpdated(String name, int count) {
    return '$name actualizado a $count';
  }

  @override
  String inventorySupplyDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '~$count días',
      one: '~1 día',
    );
    return '$_temp0';
  }

  @override
  String get inventoryAdjustReasonLabel => 'Motivo del ajuste (opcional)';

  @override
  String get inventoryAdjustReasonHint => 'Motivo del ajuste (opcional)...';

  @override
  String get inventoryAdjustSave => 'Guardar cantidad';

  @override
  String inventoryCurrentOnHand(int quantity, String unit) {
    return 'Disponible actual: $quantity $unit';
  }

  @override
  String inventoryAfterRefill(int quantity) {
    return 'Tras reabastecer: $quantity';
  }

  @override
  String inventoryFullBottle(int quantity) {
    return 'Frasco completo: $quantity';
  }

  @override
  String inventoryHalfPack(int quantity) {
    return 'Medio paquete: $quantity';
  }

  @override
  String get medFormExtendedRelease => 'Liberación prolongada';

  @override
  String get medRouteOral => 'Oral';

  @override
  String get medRouteSubcutaneous => 'Subcutánea';

  @override
  String get medConditionDiabetes => 'Diabetes';

  @override
  String get medConditionType2Diabetes => 'Diabetes tipo 2';

  @override
  String get medConditionHighBloodPressure => 'Presión arterial alta';

  @override
  String get medConditionHypertension => 'Hipertensión';

  @override
  String get medConditionHeartHealth => 'Salud cardíaca';

  @override
  String get medConditionHighCholesterol => 'Colesterol alto';

  @override
  String get medConditionBacterialInfection => 'Infección bacteriana';

  @override
  String get medConditionPainInflammation => 'Dolor e inflamación';

  @override
  String get medConditionBoneHealth => 'Salud ósea';

  @override
  String get medConditionAcidReflux => 'Reflujo ácido';

  @override
  String get addMedDailyDose => 'Dosis diaria';

  @override
  String addMedCommonFor(String condition) {
    return 'Común para: $condition';
  }

  @override
  String get addManualColorWhite => 'Blanco';

  @override
  String get addManualColorYellow => 'Amarillo';

  @override
  String get addManualColorPink => 'Rosa';

  @override
  String get addManualColorBlue => 'Azul';

  @override
  String get addManualColorOrange => 'Naranja';

  @override
  String get addManualColorPeach => 'Durazno';

  @override
  String get addManualColorGreen => 'Verde';

  @override
  String get addManualDraftSaved => 'Borrador guardado: ¡complétalo más tarde!';

  @override
  String get addMedTitle => 'Agregar medicamento';

  @override
  String get addManualRxVerified => 'RX VERIFICADA';

  @override
  String get medsMedicationDetails => 'DETALLES DEL MEDICAMENTO';

  @override
  String get medsFieldName => 'Nombre del medicamento';

  @override
  String get medsFieldStrength => 'Concentración';

  @override
  String get medsFieldForm => 'Forma del medicamento';

  @override
  String get addManualSelectForm => 'Seleccionar forma';

  @override
  String get addManualColorOptional => 'Color (opcional)';

  @override
  String get medsFieldInstructions => 'Instrucciones especiales';

  @override
  String get addManualOptional => 'Opcional';

  @override
  String get addManualInstructionsHint =>
      'p. ej. Tomar con comida después del desayuno, evitar toronja...';

  @override
  String get addManualContinueToSchedule => 'Continuar al horario →';

  @override
  String get addManualSaveDraft => 'Guardar como borrador';

  @override
  String get addManualNameHint => 'Ingresa el nombre del medicamento';

  @override
  String get addManualMatchesIndex => 'Coincide con el índice clínico';

  @override
  String get addManualStrengthHint => 'p. ej. 500';

  @override
  String get addManualFormOther => 'Otra';

  @override
  String get addManualFormOtherSubtitle => 'Ingresa otra forma de medicamento';

  @override
  String get addManualCustomForm => 'Forma personalizada';

  @override
  String get addManualCustomFormHint =>
      'p. ej. Crema, Inhalador, Parche, Aerosol...';

  @override
  String get addManualCustomFormRequired => 'Ingresa la forma del medicamento';

  @override
  String get addManualInteractionTitle =>
      'Verificaciones automáticas de interacción';

  @override
  String get addManualInteractionBody =>
      'Compararemos esta dosis con tus medicamentos ya registrados en el siguiente paso.';

  @override
  String addMedSelected(String name, String strength) {
    return '$name $strength seleccionado: ¡detalles a continuación!';
  }

  @override
  String get addMedPrivateNote => 'Privado y cifrado en este dispositivo';

  @override
  String get addMedScanLabel => 'Escanear etiqueta';

  @override
  String get addMedSearch => 'Buscar';

  @override
  String get addMedManualEntry => 'Entrada manual';

  @override
  String addMedMatchingCount(int count) {
    return 'Medicamentos coincidentes ($count)';
  }

  @override
  String get addMedFdaApproved => 'Aprobado por la FDA';

  @override
  String get addMedTipTitle => 'Consejo: busca el grabado';

  @override
  String get addMedTipBody =>
      'La mayoría de las tabletas de metformina tienen números como \'500\' o \'M\' grabados al frente para garantizar la dosis exacta.';

  @override
  String get addMedCantFind => '¿No encuentras tu medicamento?';

  @override
  String get addMedAddManually => 'Agregar manualmente';

  @override
  String get addMedEmptyTitle => 'Busca un medicamento';

  @override
  String get addMedEmptySubtitle =>
      'Escribe el nombre arriba o escanea su etiqueta';

  @override
  String get addMedNoResultsTitle => 'No se encontraron medicamentos';

  @override
  String addMedNoResultsFor(String query) {
    return 'Sin resultados para \"$query\"';
  }

  @override
  String get addMedSelectAction => 'Seleccionar ›';

  @override
  String get reviewScanNameRequired => 'Ingresa el nombre del medicamento.';

  @override
  String get reviewScanStrengthRequired =>
      'Ingresa la concentración del medicamento.';

  @override
  String get reviewScanTitle => 'Revisar escaneo';

  @override
  String get scanCaptureFailed => 'Captura fallida, inténtalo de nuevo.';

  @override
  String get scanCaptureError =>
      'No se pudo capturar la imagen. Inténtalo de nuevo.';

  @override
  String get scanGalleryError =>
      'No se pudo abrir la imagen. Inténtalo de nuevo.';

  @override
  String scanDetectedOne(String name) {
    return '✓ Detectado: $name';
  }

  @override
  String scanDetectedCount(int count) {
    return '✓ $count medicamentos detectados';
  }

  @override
  String get scanTextNoMedicine =>
      'Se detectó texto, pero no se pudieron identificar los detalles del medicamento.';

  @override
  String get scanNoText =>
      'No se detectó texto. Mantén el documento claro, plano y bien iluminado.';

  @override
  String get scanReadError => 'No se pudo leer la imagen. Inténtalo de nuevo.';

  @override
  String get scanRescanAgain => 'Escanea el medicamento de nuevo.';

  @override
  String get scanFitFrameHint =>
      'Coloca la etiqueta del medicamento o la receta completa dentro del marco';

  @override
  String get scanEnterManually => 'Ingresar medicamento manualmente';

  @override
  String get scanRetakePhoto => 'Tomar foto de nuevo';

  @override
  String get scanReadingPrescription => 'Leyendo receta...';

  @override
  String get scanStatusReading => 'LEYENDO';

  @override
  String get scanStatusFound => 'ENCONTRADO';

  @override
  String get scanStatusInFrame => 'EN MARCO';

  @override
  String get scanStatusReady => 'LISTO';

  @override
  String get scanCameraUnavailable => 'Cámara no disponible';

  @override
  String get scanStartingCamera => 'Iniciando cámara...';

  @override
  String get scanCapturingDocument => 'Capturando documento...';

  @override
  String get scanReadingMedicineText => 'Leyendo texto del medicamento...';

  @override
  String get scanMedicineDetected => 'Medicamento detectado';

  @override
  String scanMedicinesDetected(int count) {
    return '$count medicamentos detectados';
  }

  @override
  String get scanImageCaptured => 'Imagen capturada';

  @override
  String get scanMedicineOrRxDetected => 'Medicamento o receta detectados';

  @override
  String get scanPointCameraHint => 'Apunta la cámara al medicamento o receta';

  @override
  String get scanFlash => 'Flash';

  @override
  String get scanShutter => 'Escanear';

  @override
  String get scanGallery => 'Galería';

  @override
  String get scanTryAgain => 'Reintentar';

  @override
  String scanMedicineBadgeNumber(int index) {
    return 'MEDICAMENTO $index DETECTADO';
  }

  @override
  String get scanMedicineBadgeSingular => 'MEDICAMENTO DETECTADO';

  @override
  String get scanFieldStrength => 'Concentración';

  @override
  String get scanFieldForm => 'Forma';

  @override
  String get scanFieldFrequency => 'Frecuencia';

  @override
  String get medsFieldInstructionsShort => 'Instrucciones';

  @override
  String get scanReviewAdd => 'Revisar y agregar medicamento';

  @override
  String get stepSchedule => 'Horario';

  @override
  String get reviewScanScanned => 'ESCANEADO';

  @override
  String get reviewScanReadSuccess =>
      'Hemos leído estos datos de tu etiqueta: ¡revisa y corrige si es necesario!';

  @override
  String get reviewScanInstructionsHint =>
      'Ingresa las instrucciones del medicamento';

  @override
  String get reviewScanStrengthUnclear =>
      'El campo de concentración no fue claro en la foto: verifícalo manualmente.';

  @override
  String get reviewScanRequired => 'OBLIGATORIO';

  @override
  String get reviewScanStrengthHint => 'Ingresa la concentración, p. ej. 500mg';

  @override
  String get reviewScanConfirmContinue => 'Confirmar y continuar →';
}
