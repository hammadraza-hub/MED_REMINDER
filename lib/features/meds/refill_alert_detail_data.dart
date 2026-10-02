import 'inventory_data.dart';

/// ============================================================
/// REFILL ALERT DETAIL DATA
///
/// Refill Alert Detail screen ke liye presentation/data layer.
///
/// IMPORTANT:
/// Medication ki inventory information InventoryItem se aati hai.
/// UI medicine name, remaining stock, days, progress ya run-out
/// date manually hardcode nahi karti.
///
/// Abhi pharmacy information deterministic dummy data hai.
///
/// TODO Backend:
/// Current authenticated user / selected family member ke:
/// • medication inventory document
/// • linked pharmacy document
/// • refill preferences
///
/// Firestore/repository se load karne hain.
/// ============================================================

class RefillPharmacyInfo {
  const RefillPharmacyInfo({
    required this.id,
    required this.name,
    required this.openStatus,
    this.phoneNumber,
  });

  final String id;
  final String name;
  final String openStatus;
  final String? phoneNumber;
}

class RefillAlertDetailData {
  const RefillAlertDetailData({
    required this.inventoryItem,
    required this.pharmacy,
    required this.referenceDate,
  });

  final InventoryItem inventoryItem;
  final RefillPharmacyInfo pharmacy;

  /// Dummy/frontend phase mein screen open hone ki date.
  ///
  /// TODO Backend:
  /// Server/client normalized current date ya inventory snapshot
  /// timestamp use karna hai.
  final DateTime referenceDate;

  // ============================================================
  // MEDICATION
  // ============================================================

  String get medicineDisplayName {
    return inventoryItem.displayName;
  }

  String get remainingCount {
    return '${inventoryItem.remainingQuantity}';
  }

  String get remainingUnit {
    return _pluralizedUnit(
      inventoryItem.remainingQuantity,
      inventoryItem.unitLabel,
    );
  }

  int get estimatedDaysRemaining {
    return inventoryItem.estimatedDaysRemaining;
  }

  double get supplyProgress {
    return inventoryItem.supplyProgress;
  }

  bool get isLowStock {
    return inventoryItem.isLowStock;
  }

  String get supplyStatusLabel {
    if (isLowStock) {
      return 'Running low on supply';
    }

    return 'Supply available';
  }

  String? get medicineImageAsset {
    return inventoryItem.medicineImageAsset;
  }

  // ============================================================
  // RUN-OUT DATE
  // ============================================================

  DateTime get estimatedRunOutDate {
    return DateTime(
      referenceDate.year,
      referenceDate.month,
      referenceDate.day,
    ).add(Duration(days: estimatedDaysRemaining));
  }

  String get estimatedRunOutDateLabel {
    final date = estimatedRunOutDate;

    return '${_weekdayName(date.weekday)}, '
        '${date.day} ${_monthName(date.month)} ${date.year}';
  }

  // ============================================================
  // HELPERS
  // ============================================================

  String _pluralizedUnit(int quantity, String source) {
    if (quantity == 1) {
      return source;
    }

    switch (source.toLowerCase()) {
      case 'tablet':
        return 'tablets';

      case 'capsule':
        return 'capsules';

      case 'bottle':
        return 'bottles';

      case 'dose':
        return 'doses';

      default:
        return '${source}s';
    }
  }

  String _weekdayName(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Mon';

      case DateTime.tuesday:
        return 'Tue';

      case DateTime.wednesday:
        return 'Wed';

      case DateTime.thursday:
        return 'Thu';

      case DateTime.friday:
        return 'Fri';

      case DateTime.saturday:
        return 'Sat';

      case DateTime.sunday:
        return 'Sun';

      default:
        return '';
    }
  }

  String _monthName(int month) {
    switch (month) {
      case DateTime.january:
        return 'January';

      case DateTime.february:
        return 'February';

      case DateTime.march:
        return 'March';

      case DateTime.april:
        return 'April';

      case DateTime.may:
        return 'May';

      case DateTime.june:
        return 'June';

      case DateTime.july:
        return 'July';

      case DateTime.august:
        return 'August';

      case DateTime.september:
        return 'September';

      case DateTime.october:
        return 'October';

      case DateTime.november:
        return 'November';

      case DateTime.december:
        return 'December';

      default:
        return '';
    }
  }

  // ============================================================
  // FACTORY
  // ============================================================

  factory RefillAlertDetailData.fromInventoryItem(InventoryItem item) {
    return RefillAlertDetailData(
      inventoryItem: item,

      // TODO Backend:
      // User ki linked/default pharmacy repository se resolve
      // karni hai. Medicine-specific pharmacy ho to usko priority.
      pharmacy: const RefillPharmacyInfo(
        id: 'pharmacy_green_cross',
        name: 'Green Cross Pharmacy',
        openStatus: 'Open until 9 PM',
        phoneNumber: null,
      ),

      referenceDate: DateTime.now(),
    );
  }
}
