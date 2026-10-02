import 'inventory_data.dart';

/// ============================================================
/// PHARMACY INFO DATA
///
/// Pharmacy Details screen ka data/presentation layer.
///
/// IMPORTANT:
/// UI pharmacy name, phone, address, timings aur linked medicine
/// values manually hardcode nahi karti.
///
/// Abhi deterministic dummy data use ho raha hai.
///
/// TODO Backend:
/// Current authenticated user / selected family member ke linked
/// pharmacy document ko Firestore repository se load karna hai.
///
/// Suggested pharmacy fields:
/// • pharmacyId
/// • name
/// • phone
/// • address
/// • latitude / longitude
/// • isPrimary
/// • medicationIds
/// • openingHours
/// ============================================================

class PharmacyOpeningHours {
  const PharmacyOpeningHours({
    required this.label,
    required this.openTime,
    required this.closeTime,
    this.isClosed = false,
  });

  final String label;
  final String openTime;
  final String closeTime;
  final bool isClosed;

  String get hoursLabel {
    if (isClosed) {
      return 'Closed';
    }

    return '$openTime – $closeTime';
  }
}

class PharmacyInfoData {
  const PharmacyInfoData({
    required this.id,
    required this.name,
    required this.phone,
    this.address,
    this.distanceLabel,
    this.landmark,
    required this.isPrimary,
    required this.openingHours,
    required this.linkedMedicationIds,
  });

  final String id;
  final String name;
  final String phone;

  /// Address optional requirement hai.
  final String? address;

  final String? distanceLabel;
  final String? landmark;

  final bool isPrimary;

  final List<PharmacyOpeningHours> openingHours;

  final List<String> linkedMedicationIds;

  // ============================================================
  // LINKED MEDICATIONS
  // ============================================================

  List<InventoryItem> linkedInventoryItems(List<InventoryItem> inventoryItems) {
    return inventoryItems.where((item) {
      return linkedMedicationIds.contains(item.medicationId);
    }).toList();
  }

  int linkedPrescriptionCount(List<InventoryItem> inventoryItems) {
    return linkedInventoryItems(inventoryItems).length;
  }

  // ============================================================
  // OPEN / CLOSED
  //
  // Current dummy implementation display schedule se status
  // calculate karti hai.
  //
  // TODO Backend:
  // Pharmacy timezone + holiday/special opening hours ko support
  // karna hai.
  // ============================================================

  bool isOpenAt(DateTime dateTime) {
    final schedule = _scheduleForDate(dateTime);

    if (schedule == null || schedule.isClosed) {
      return false;
    }

    final openMinutes = _timeToMinutes(schedule.openTime);

    final closeMinutes = _timeToMinutes(schedule.closeTime);

    if (openMinutes == null || closeMinutes == null) {
      return false;
    }

    final currentMinutes = (dateTime.hour * 60) + dateTime.minute;

    return currentMinutes >= openMinutes && currentMinutes < closeMinutes;
  }

  String openStatus(DateTime dateTime) {
    if (isOpenAt(dateTime)) {
      final today = _scheduleForDate(dateTime);

      if (today != null) {
        return 'Open until ${today.closeTime}';
      }

      return 'Open now';
    }

    return 'Closed';
  }

  PharmacyOpeningHours? _scheduleForDate(DateTime date) {
    switch (date.weekday) {
      case DateTime.monday:
      case DateTime.tuesday:
      case DateTime.wednesday:
      case DateTime.thursday:
      case DateTime.friday:
        return _findSchedule('Mon–Fri');

      case DateTime.saturday:
        return _findSchedule('Saturday');

      case DateTime.sunday:
        return _findSchedule('Sunday');

      default:
        return null;
    }
  }

  PharmacyOpeningHours? _findSchedule(String label) {
    for (final schedule in openingHours) {
      if (schedule.label == label) {
        return schedule;
      }
    }

    return null;
  }

  int? _timeToMinutes(String source) {
    final normalized = source.trim().toUpperCase().replaceAll(' ', '');

    final match = RegExp(r'^(\d{1,2}):(\d{2})(AM|PM)$').firstMatch(normalized);

    if (match == null) {
      return null;
    }

    var hour = int.tryParse(match.group(1) ?? '');

    final minute = int.tryParse(match.group(2) ?? '');

    final period = match.group(3);

    if (hour == null || minute == null) {
      return null;
    }

    if (period == 'PM' && hour != 12) {
      hour += 12;
    }

    if (period == 'AM' && hour == 12) {
      hour = 0;
    }

    return (hour * 60) + minute;
  }

  // ============================================================
  // CURRENT DUMMY PHARMACY
  // ============================================================

  static PharmacyInfoData current() {
    return const PharmacyInfoData(
      id: 'pharmacy_green_cross',
      name: 'Green Cross Pharmacy',
      phone: '+1 (555) 234-8890',
      address: '124 Maple Street, Springfield',
      distanceLabel: '0.8 miles away',
      landmark: 'Springfield Medical Plaza',
      isPrimary: true,

      // TODO Backend:
      // Stable medication document IDs Firestore relation se
      // load karne hain.
      linkedMedicationIds: ['med_0', 'med_1'],

      openingHours: [
        PharmacyOpeningHours(
          label: 'Mon–Fri',
          openTime: '8:00 AM',
          closeTime: '9:00 PM',
        ),
        PharmacyOpeningHours(
          label: 'Saturday',
          openTime: '9:00 AM',
          closeTime: '6:00 PM',
        ),
        PharmacyOpeningHours(
          label: 'Sunday',
          openTime: '',
          closeTime: '',
          isClosed: true,
        ),
      ],
    );
  }
}
